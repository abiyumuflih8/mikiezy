import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as speech;

import '../core/formatters.dart';
import '../domain/models/business_query_data.dart';
import '../models/mikiezy_models.dart';
import 'diagnostics/safe_diagnostics.dart';
import 'voice/microphone_permission_service.dart';
import 'voice/voice_business_query_handler.dart';
import 'voice/voice_business_conversation_handler.dart';
import 'voice/voice_command.dart';
import 'voice/voice_command_executor.dart';
import 'voice/voice_command_router.dart';
import 'voice/voice_parse_context.dart';
import 'voice/voice_parse_result.dart';
import 'voice/voice_navigation_handler.dart';
import 'voice/voice_mutation_preview_handler.dart';
import 'voice/voice_transaction_parser_v2.dart';
import 'voice/wake_word_detector.dart';

enum VoiceAssistantPhase {
  listening,
  processing,
  completed,
  unclear,
  permissionDenied,
}

class VoiceAssistantResult {
  const VoiceAssistantResult({
    required this.draft,
    required this.transcript,
    required this.feedback,
    required this.confidence,
    required this.parseResult,
  });

  final TransactionDraft draft;
  final String transcript;
  final String feedback;
  final double confidence;
  final VoiceParseResult parseResult;

  bool get needsReview => parseResult.needsReview;
  List<String> get warnings => parseResult.warnings;
}

class VoiceAssistantController extends ChangeNotifier {
  VoiceAssistantController({
    VoiceTransactionParserV2? parser,
    VoiceCommandRouter? commandRouter,
    WakeWordDetector? wakeWordDetector,
    speech.SpeechToText? speechToText,
    FlutterTts? textToSpeech,
    VoiceCommandExecutor? commandExecutor,
    VoiceBusinessQueryHandler? businessQueryHandler,
    VoiceBusinessConversationHandler? businessConversationHandler,
    this.mutationPreviewHandler,
    this.navigationHandler,
    this.businessDataProvider,
    DateTime Function()? clock,
    this.speakOverride,
    MicrophonePermissionService? microphonePermissionService,
  }) : _parser = parser ?? const VoiceTransactionParserV2(),
       _commandRouter = commandRouter ?? const VoiceCommandRouter(),
       _wakeWordDetector = wakeWordDetector ?? const WakeWordDetector(),
       _speech = speechToText ?? speech.SpeechToText(),
       _tts = textToSpeech ?? FlutterTts(),
       _commandExecutor = commandExecutor ?? VoiceCommandExecutor(),
       _businessQueryHandler =
           businessQueryHandler ?? const VoiceBusinessQueryHandler(),
       _businessConversationHandler =
           businessConversationHandler ??
           VoiceBusinessConversationHandler(
             queryHandler:
                 businessQueryHandler ?? const VoiceBusinessQueryHandler(),
           ),
       _microphonePermissionService =
           microphonePermissionService ??
           const PermissionHandlerMicrophonePermissionService(),
       _clock = clock ?? DateTime.now;

  final VoiceTransactionParserV2 _parser;
  final VoiceCommandRouter _commandRouter;
  final WakeWordDetector _wakeWordDetector;
  final speech.SpeechToText _speech;
  final FlutterTts _tts;
  final VoiceCommandExecutor _commandExecutor;
  final VoiceBusinessQueryHandler _businessQueryHandler;
  final VoiceBusinessConversationHandler _businessConversationHandler;
  final MicrophonePermissionService _microphonePermissionService;
  VoiceMutationPreviewHandler? mutationPreviewHandler;
  VoiceNavigationHandler? navigationHandler;
  BusinessQueryData Function()? businessDataProvider;
  final DateTime Function() _clock;
  final Future<void> Function(String text)? speakOverride;

  VoiceAssistantPhase phase = VoiceAssistantPhase.listening;
  String transcript = '';
  String feedback = 'Miki siap mendengarkan transaksi.';
  String? lastError;
  VoiceAssistantResult? latestResult;
  VoiceCommand? latestCommand;
  VoiceCommandExecutionResult? latestCommandExecution;
  double confidence = -1;
  double soundLevel = 0;
  bool wakeWordDetected = false;
  bool speechAvailable = false;
  bool nativeListening = false;
  bool ttsEnabled = true;
  MicrophonePermissionState microphonePermissionState =
      MicrophonePermissionState.denied;
  bool _initialized = false;
  bool _isStarting = false;
  bool _ttsConfigured = false;
  bool _isExecutingCommand = false;
  bool _disposed = false;
  int _executionGeneration = 0;
  int _listeningGeneration = 0;
  String? _activeCommandFingerprint;
  String? _completedCommandFingerprint;
  String _finalTranscriptBuffer = '';
  String _currentPartialTranscript = '';

  @visibleForTesting
  String get finalTranscriptBuffer => _finalTranscriptBuffer;

  @visibleForTesting
  String get currentPartialTranscript => _currentPartialTranscript;

  @visibleForTesting
  String get combinedTranscript => _combinedTranscript();

  bool get isListening => phase == VoiceAssistantPhase.listening;
  bool get isProcessing => phase == VoiceAssistantPhase.processing;
  bool get isStarting => _isStarting;
  bool get isError =>
      phase == VoiceAssistantPhase.unclear ||
      phase == VoiceAssistantPhase.permissionDenied;
  bool get hasTranscript => transcript.trim().isNotEmpty;
  VoiceCommandResponse? get latestCommandResponse =>
      latestCommandExecution?.response;
  bool get isAwaitingClarification =>
      _businessConversationHandler.isAwaitingClarification(now: _clock()) ||
      (mutationPreviewHandler?.hasPendingClarification ?? false);
  bool get isAwaitingMutationConfirmation =>
      mutationPreviewHandler?.hasPendingAction ?? false;

  void bindBusinessDataProvider(BusinessQueryData Function() provider) {
    businessDataProvider = provider;
  }

  void bindNavigationHandler(VoiceNavigationHandler handler) {
    navigationHandler = handler;
  }

  Future<void> cancelPendingMutation({
    String errorCode = 'session_closed',
  }) async {
    await mutationPreviewHandler?.cancelPending(errorCode: errorCode);
  }

  Future<bool> initialize() async {
    if (_disposed) return false;
    if (_initialized) return speechAvailable;
    await _configureTts();
    try {
      speechAvailable = await _speech.initialize(
        onStatus: _handleSpeechStatus,
        onError: _handleSpeechError,
        debugLogging: false,
      );
      _initialized = true;
      return speechAvailable;
    } catch (error) {
      _initialized = true;
      speechAvailable = false;
      lastError = error.toString();
      return false;
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> startListening({
    String localeId = 'id_ID',
    String? initialTranscript,
    bool wakeWordAlreadyDetected = false,
  }) async {
    if (_disposed || _isStarting || nativeListening) return;
    final generation = ++_listeningGeneration;
    _isStarting = true;
    phase = VoiceAssistantPhase.processing;
    feedback = 'Menyiapkan mikrofon...';
    lastError = null;
    notifyListeners();

    try {
      final permission = await _microphonePermissionService.request();
      if (!_isListeningGenerationActive(generation)) return;
      microphonePermissionState = permission;
      SafeDiagnostics.voiceEvent(
        'microphone_permission_result',
        state: phase.name,
        permission: permission.name,
      );
      if (!permission.canListen) {
        phase = VoiceAssistantPhase.permissionDenied;
        feedback = permission.userMessage;
        await speak(feedback);
        return;
      }

      final available = await initialize();
      if (!_isListeningGenerationActive(generation)) return;
      if (!available) {
        phase = VoiceAssistantPhase.permissionDenied;
        feedback =
            'Layanan pengenalan suara tidak tersedia pada perangkat ini.';
        await speak(feedback);
        return;
      }

      if (initialTranscript != null) {
        _setTranscriptBuffers(initialTranscript);
      }
      wakeWordDetected = wakeWordAlreadyDetected || _hasWakeWord(transcript);
      confidence = -1;
      soundLevel = 0;
      nativeListening = true;
      phase = VoiceAssistantPhase.listening;
      feedback = wakeWordDetected
          ? 'Wake word terdeteksi. Lanjutkan perintah transaksi.'
          : 'Silakan ucapkan transaksi.';
      notifyListeners();

      await _speech.listen(
        onResult: _handleSpeechResult,
        onSoundLevelChange: (level) {
          if (_disposed) return;
          soundLevel = level;
          notifyListeners();
        },
        listenOptions: speech.SpeechListenOptions(
          localeId: localeId,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 30),
          partialResults: true,
          cancelOnError: false,
          listenMode: speech.ListenMode.dictation,
        ),
      );
    } finally {
      if (generation == _listeningGeneration) {
        _isStarting = false;
        if (!_disposed) notifyListeners();
      }
    }
  }

  Future<VoiceAssistantResult?> stopAndProcess({
    VoiceParseContext parseContext = const VoiceParseContext(),
    bool speakResult = true,
  }) async {
    if (nativeListening) {
      nativeListening = false;
      await _speech.stop();
    }
    _commitCurrentPartialTranscript();
    return processCurrentTranscript(
      parseContext: parseContext,
      speakResult: speakResult,
    );
  }

  Future<VoiceAssistantResult?> processCurrentTranscript({
    VoiceParseContext parseContext = const VoiceParseContext(),
    bool speakResult = true,
  }) async {
    _commitCurrentPartialTranscript();
    final combined = _combinedTranscript();
    final text = _transcriptWithoutWakeWord(combined).trim();
    _debugTranscript('before-parse');
    if (text.isEmpty) {
      phase = VoiceAssistantPhase.unclear;
      feedback = wakeWordDetected
          ? 'Wake word terdeteksi, tapi transaksi belum terdengar jelas.'
          : 'Maaf, suara belum terbaca. Coba ulangi lebih jelas.';
      if (speakResult) await speak(feedback);
      notifyListeners();
      return null;
    }

    phase = VoiceAssistantPhase.processing;
    feedback = 'Miki sedang memahami transaksi...';
    notifyListeners();

    if (_businessConversationHandler.isAwaitingClarification(now: _clock())) {
      final clarificationHandled = await _executeClarification(
        transcriptText: text,
        speakResult: speakResult,
      );
      if (clarificationHandled) return null;
    }

    if (mutationPreviewHandler?.hasPendingClarification ?? false) {
      final clarificationHandled = await _executeMutationClarification(
        transcriptText: text,
        speakResult: speakResult,
      );
      if (clarificationHandled) return null;
    }

    if (mutationPreviewHandler?.hasPendingAction ?? false) {
      await _executeMutationConfirmation(
        transcriptText: text,
        speakResult: speakResult,
      );
      return null;
    }

    latestCommand = _commandRouter.route(text);
    if (latestCommand!.intent.isBusinessQuery) {
      return _executeBusinessQuery(
        command: latestCommand!,
        transcriptText: text,
        speakResult: speakResult,
      );
    }
    if (latestCommand!.intent.isNavigation) {
      return _executeNavigation(
        command: latestCommand!,
        transcriptText: text,
        speakResult: speakResult,
      );
    }
    if (latestCommand!.intent.isMutation) {
      return _executeMutationPreview(
        command: latestCommand!,
        speakResult: speakResult,
      );
    }
    if (!latestCommand!.intent.isTransaction &&
        latestCommand!.intent != VoiceCommandIntent.unknown) {
      return _rejectUnsupportedCommand(
        command: latestCommand!,
        speakResult: speakResult,
      );
    }
    latestCommandExecution = null;
    _completedCommandFingerprint = null;
    final parsed = _parser.parse(text, context: parseContext);
    final draft = parsed.draft ?? _bestEffortDraft(text, parsed, parseContext);
    final parseResult = parsed.draft == null
        ? parsed.copyWith(draft: draft, needsReview: true)
        : parsed;
    SafeDiagnostics.voiceEvent(
      'voice_parser_completed',
      state: phase.name,
      status:
          'items:${parseResult.items.length},lines:${draft.lines.length},review:${parseResult.needsReview}',
    );
    confidence = parseResult.confidence;
    final resultFeedback = _buildFeedback(draft, parseResult);
    feedback = resultFeedback;
    latestResult = VoiceAssistantResult(
      draft: draft,
      transcript: text,
      feedback: resultFeedback,
      confidence: parseResult.confidence,
      parseResult: parseResult,
    );
    phase = VoiceAssistantPhase.completed;
    notifyListeners();

    if (speakResult) await speak(resultFeedback);
    return latestResult;
  }

  Future<VoiceAssistantResult?> _executeBusinessQuery({
    required VoiceCommand command,
    required String transcriptText,
    required bool speakResult,
  }) async {
    final fingerprint =
        '${command.intent.name}:${_normalizeTranscript(transcriptText).toLowerCase()}';
    if (_isExecutingCommand && _activeCommandFingerprint == fingerprint) {
      return null;
    }
    if (_completedCommandFingerprint == fingerprint &&
        latestCommandExecution != null) {
      phase = VoiceAssistantPhase.completed;
      feedback = latestCommandExecution!.response.displayText;
      if (!_disposed) notifyListeners();
      return null;
    }

    _isExecutingCommand = true;
    _activeCommandFingerprint = fingerprint;
    final generation = ++_executionGeneration;
    BusinessQueryData data;
    try {
      data = businessDataProvider?.call() ?? BusinessQueryData(isReady: false);
    } catch (error, stackTrace) {
      SafeDiagnostics.failure(
        'business_data_provider_failed',
        error,
        stackTrace,
      );
      data = BusinessQueryData(sourceError: error.toString());
    }

    final runtimeHandlers = <VoiceCommandIntent, VoiceCommandHandler>{
      for (final intent in VoiceCommandIntent.values)
        if (_businessQueryHandler.supports(intent))
          intent: (routedCommand, context) {
            final turn = _businessConversationHandler.handleCommand(
              command: routedCommand,
              data: data,
              now: _clock(),
            );
            return turn.response!;
          },
    };

    try {
      final execution = await _commandExecutor.execute(
        command,
        runtimeHandlers: runtimeHandlers,
      );
      if (_disposed || generation != _executionGeneration) return null;

      latestResult = null;
      latestCommandExecution = execution;
      confidence = command.confidence;
      feedback = execution.response.displayText;
      phase = VoiceAssistantPhase.completed;
      _completedCommandFingerprint = fingerprint;
      notifyListeners();

      if (speakResult) await speak(execution.response.spokenText);
      return null;
    } finally {
      if (generation == _executionGeneration) {
        _isExecutingCommand = false;
        _activeCommandFingerprint = null;
      }
    }
  }

  Future<bool> _executeClarification({
    required String transcriptText,
    required bool speakResult,
  }) async {
    BusinessQueryData data;
    try {
      data = businessDataProvider?.call() ?? BusinessQueryData(isReady: false);
    } catch (error, stackTrace) {
      SafeDiagnostics.failure(
        'business_clarification_data_failed',
        error,
        stackTrace,
      );
      data = BusinessQueryData(sourceError: error.toString());
    }

    final turn = _businessConversationHandler.handleAnswer(
      transcript: transcriptText,
      data: data,
      now: _clock(),
    );
    if (turn.routeAsNewCommand) return false;
    final response = turn.response;
    if (response == null) return false;

    final command =
        turn.command ?? latestCommand ?? _commandRouter.route(transcriptText);
    latestCommand = command;
    latestResult = null;
    latestCommandExecution = VoiceCommandExecutionResult(
      command: command,
      response: response,
      handled: true,
    );
    confidence = command.confidence;
    feedback = response.displayText;
    phase = VoiceAssistantPhase.completed;
    notifyListeners();
    if (speakResult) await speak(response.spokenText);
    return true;
  }

  Future<VoiceAssistantResult?> _executeNavigation({
    required VoiceCommand command,
    required String transcriptText,
    required bool speakResult,
  }) async {
    final handler = navigationHandler;
    final fingerprint =
        '${command.intent.name}:${_normalizeTranscript(transcriptText).toLowerCase()}';
    if (_isExecutingCommand && _activeCommandFingerprint == fingerprint) {
      return null;
    }
    if (_completedCommandFingerprint == fingerprint &&
        latestCommandExecution != null) {
      return null;
    }

    _isExecutingCommand = true;
    _activeCommandFingerprint = fingerprint;
    final generation = ++_executionGeneration;
    final runtimeHandlers = <VoiceCommandIntent, VoiceCommandHandler>{
      if (handler != null && handler.supports(command.intent))
        command.intent: (routedCommand, context) =>
            handler.handle(routedCommand),
    };
    try {
      final execution = await _commandExecutor.execute(
        command,
        runtimeHandlers: runtimeHandlers,
      );
      if (_disposed || generation != _executionGeneration) return null;
      latestResult = null;
      latestCommandExecution = execution;
      confidence = command.confidence;
      feedback = execution.response.displayText;
      phase = VoiceAssistantPhase.completed;
      _completedCommandFingerprint = fingerprint;
      notifyListeners();
      if (speakResult) await speak(execution.response.spokenText);
      return null;
    } finally {
      if (generation == _executionGeneration) {
        _isExecutingCommand = false;
        _activeCommandFingerprint = null;
      }
    }
  }

  Future<VoiceAssistantResult?> _executeMutationPreview({
    required VoiceCommand command,
    required bool speakResult,
  }) async {
    final handler = mutationPreviewHandler;
    if (handler == null) {
      return _rejectUnsupportedCommand(
        command: command,
        speakResult: speakResult,
      );
    }
    final response = await handler.preview(command);
    if (_disposed) return null;
    _publishCommandResponse(command, response);
    if (speakResult) await speak(response.spokenText);
    return null;
  }

  Future<bool> _executeMutationClarification({
    required String transcriptText,
    required bool speakResult,
  }) async {
    final handler = mutationPreviewHandler;
    if (handler == null) return false;
    final response = await handler.handleClarificationAnswer(transcriptText);
    if (response == null) return false;
    if (_disposed) return true;
    final command = latestCommand ?? _commandRouter.route(transcriptText);
    _publishCommandResponse(command, response);
    if (speakResult) await speak(response.spokenText);
    return true;
  }

  Future<void> _executeMutationConfirmation({
    required String transcriptText,
    required bool speakResult,
  }) async {
    final handler = mutationPreviewHandler;
    if (handler == null) return;
    final response = await handler.handlePendingAnswer(transcriptText);
    if (_disposed) return;
    final command = latestCommand ?? _commandRouter.route(transcriptText);
    _publishCommandResponse(command, response);
    if (speakResult) await speak(response.spokenText);
  }

  void _publishCommandResponse(
    VoiceCommand command,
    VoiceCommandResponse response,
  ) {
    latestResult = null;
    latestCommand = command;
    latestCommandExecution = VoiceCommandExecutionResult(
      command: command,
      response: response,
      handled: true,
    );
    confidence = command.confidence;
    feedback = response.displayText;
    phase = VoiceAssistantPhase.completed;
    notifyListeners();
  }

  Future<VoiceAssistantResult?> _rejectUnsupportedCommand({
    required VoiceCommand command,
    required bool speakResult,
  }) async {
    final execution = await _commandExecutor.execute(command);
    if (_disposed) return null;
    latestResult = null;
    latestCommandExecution = execution;
    confidence = command.confidence;
    feedback = execution.response.displayText;
    phase = VoiceAssistantPhase.completed;
    notifyListeners();
    if (speakResult) await speak(execution.response.spokenText);
    return null;
  }

  Future<void> cancelListening() async {
    _listeningGeneration += 1;
    _isStarting = false;
    if (nativeListening) {
      nativeListening = false;
      await _speech.cancel();
    }
    if (!_disposed) notifyListeners();
  }

  void markSilenceTimeout(int seconds) {
    feedback =
        'Tidak ada suara selama $seconds detik. Miki memproses transcript...';
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (_disposed || !ttsEnabled || text.trim().isEmpty) return;
    try {
      final override = speakOverride;
      if (override != null) {
        await override(text);
        return;
      }
      await _configureTts();
      await _tts.stop();
      await _tts.speak(text);
    } catch (error, stackTrace) {
      SafeDiagnostics.failure('voice_tts_failed', error, stackTrace);
      if (_disposed) return;
      lastError = error.toString();
      notifyListeners();
    }
  }

  void setTranscript(String value) {
    _setTranscriptBuffers(value);
    wakeWordDetected = _hasWakeWord(value);
    latestResult = null;
    latestCommand = null;
    _resetCommandExecution();
    if (phase == VoiceAssistantPhase.unclear ||
        phase == VoiceAssistantPhase.permissionDenied ||
        phase == VoiceAssistantPhase.completed) {
      phase = VoiceAssistantPhase.listening;
    }
    notifyListeners();
  }

  void clearTranscript() {
    _setTranscriptBuffers('');
    wakeWordDetected = false;
    latestResult = null;
    latestCommand = null;
    _resetCommandExecution();
    confidence = -1;
    feedback = 'Miki siap mendengarkan transaksi.';
    if (phase == VoiceAssistantPhase.unclear ||
        phase == VoiceAssistantPhase.permissionDenied ||
        phase == VoiceAssistantPhase.completed) {
      phase = VoiceAssistantPhase.listening;
    }
    notifyListeners();
  }

  void prepareForClarification() {
    _setTranscriptBuffers('');
    latestResult = null;
    latestCommandExecution = null;
    confidence = -1;
    phase = VoiceAssistantPhase.listening;
    feedback = 'Silakan jawab pilihan yang disebutkan.';
    notifyListeners();
  }

  void primeFromWakeWord(String? commandTranscript) {
    _setTranscriptBuffers(commandTranscript ?? '');
    wakeWordDetected = true;
    latestResult = null;
    latestCommand = null;
    _resetCommandExecution();
    phase = VoiceAssistantPhase.listening;
    feedback = transcript.isEmpty
        ? 'Wake word Miki terdeteksi. Silakan ucapkan transaksi.'
        : 'Wake word Miki terdeteksi. Lanjutkan transaksi.';
    notifyListeners();
  }

  void previewPhase(VoiceAssistantPhase value) {
    phase = value;
    nativeListening = false;
    feedback = switch (value) {
      VoiceAssistantPhase.listening => 'Miki siap mendengarkan transaksi.',
      VoiceAssistantPhase.processing => 'Miki sedang memahami transaksi...',
      VoiceAssistantPhase.completed => feedback,
      VoiceAssistantPhase.unclear =>
        'Suara belum jelas. Coba ulangi lebih dekat ke mikrofon.',
      VoiceAssistantPhase.permissionDenied => 'Izin mikrofon belum aktif.',
    };
    notifyListeners();
  }

  Future<bool> openMicrophoneSettings() async {
    if (!microphonePermissionState.canOpenSettings) return false;
    final opened = await _microphonePermissionService.openSettings();
    SafeDiagnostics.voiceEvent(
      'microphone_settings_requested',
      permission: microphonePermissionState.name,
      status: opened ? 'opened' : 'failed',
    );
    return opened;
  }

  Future<void> _configureTts() async {
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    _ttsConfigured = true;
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    if (_disposed) return;
    _applySpeechTranscript(
      result.recognizedWords,
      isFinal: result.finalResult,
      confidence: result.confidence,
    );
    _debugTranscript(result.finalResult ? 'result-final' : 'result-partial');
    if (result.finalResult && transcript.trim().isEmpty) {
      phase = VoiceAssistantPhase.unclear;
      feedback = 'Suara belum terbaca.';
    } else {
      phase = VoiceAssistantPhase.listening;
      if (wakeWordDetected) {
        feedback = 'Wake word Miki terdeteksi. Lanjutkan perintah transaksi.';
      }
    }
    notifyListeners();
  }

  @visibleForTesting
  void applySpeechTranscriptForTest(
    String value, {
    required bool isFinal,
    double confidence = -1,
  }) {
    _applySpeechTranscript(value, isFinal: isFinal, confidence: confidence);
  }

  @visibleForTesting
  void handleSpeechStatusForTest(String status) {
    _handleSpeechStatus(status);
  }

  void _applySpeechTranscript(
    String value, {
    required bool isFinal,
    required double confidence,
  }) {
    final cleaned = _normalizeTranscript(value);
    if (cleaned.isEmpty) {
      this.confidence = confidence;
      return;
    }
    this.confidence = confidence;
    latestResult = null;
    latestCommand = null;
    _resetCommandExecution();
    if (isFinal) {
      _commitCurrentPartialTranscript();
      _finalTranscriptBuffer = _mergeTranscript(
        _finalTranscriptBuffer,
        cleaned,
      );
      _currentPartialTranscript = '';
    } else {
      _updateCurrentPartialTranscript(cleaned);
    }
    transcript = _combinedTranscript();
    wakeWordDetected = _hasWakeWord(transcript);
  }

  void _updateCurrentPartialTranscript(String cleaned) {
    final incoming = _partialWithoutFinalOverlap(
      _finalTranscriptBuffer,
      cleaned,
    );
    if (incoming.isEmpty) {
      _currentPartialTranscript = '';
      return;
    }

    final current = _normalizeTranscript(_currentPartialTranscript);
    if (current.isEmpty) {
      _currentPartialTranscript = incoming;
      return;
    }

    if (_isPartialContinuation(current, incoming)) {
      _currentPartialTranscript = _mergeTranscript(current, incoming);
      return;
    }

    _commitCurrentPartialTranscript();
    _currentPartialTranscript = _partialWithoutFinalOverlap(
      _finalTranscriptBuffer,
      cleaned,
    );
  }

  bool _commitCurrentPartialTranscript() {
    final partial = _normalizeTranscript(_currentPartialTranscript);
    if (partial.isEmpty) return false;
    _finalTranscriptBuffer = _mergeTranscript(_finalTranscriptBuffer, partial);
    _currentPartialTranscript = '';
    transcript = _combinedTranscript();
    wakeWordDetected = _hasWakeWord(transcript);
    latestResult = null;
    latestCommand = null;
    return true;
  }

  void _setTranscriptBuffers(String value) {
    final cleaned = _normalizeTranscript(value);
    _finalTranscriptBuffer = cleaned;
    _currentPartialTranscript = '';
    transcript = cleaned;
  }

  String _combinedTranscript() {
    return _mergeTranscript(_finalTranscriptBuffer, _currentPartialTranscript);
  }

  String _partialWithoutFinalOverlap(String finalText, String partialText) {
    final base = _normalizeTranscript(finalText);
    final partial = _normalizeTranscript(partialText);
    if (base.isEmpty || partial.isEmpty) return partial;
    if (base == partial || base.endsWith(partial) || base.contains(partial)) {
      return '';
    }
    if (partial.startsWith(base)) {
      return partial.substring(base.length).trim();
    }
    return partial;
  }

  bool _isPartialContinuation(String current, String incoming) {
    final normalizedCurrent = _normalizeTranscript(current);
    final normalizedIncoming = _normalizeTranscript(incoming);
    if (normalizedCurrent.isEmpty || normalizedIncoming.isEmpty) return true;
    if (normalizedCurrent == normalizedIncoming) return true;
    if (normalizedIncoming.startsWith(normalizedCurrent) ||
        normalizedCurrent.startsWith(normalizedIncoming)) {
      return true;
    }
    if (normalizedCurrent.contains(normalizedIncoming) ||
        normalizedIncoming.contains(normalizedCurrent)) {
      return true;
    }
    return _tokenOverlapLength(normalizedCurrent, normalizedIncoming) > 0;
  }

  int _tokenOverlapLength(String left, String right) {
    final leftTokens = _normalizeTranscript(left).split(' ');
    final rightTokens = _normalizeTranscript(right).split(' ');
    final maxOverlap = leftTokens.length < rightTokens.length
        ? leftTokens.length
        : rightTokens.length;
    for (var length = maxOverlap; length > 0; length--) {
      final leftTail = leftTokens.sublist(leftTokens.length - length).join(' ');
      final rightHead = rightTokens.sublist(0, length).join(' ');
      if (leftTail == rightHead) return length;
    }
    return 0;
  }

  String _mergeTranscript(String base, String addition) {
    final normalizedBase = _normalizeTranscript(base);
    final normalizedAddition = _normalizeTranscript(addition);
    if (normalizedBase.isEmpty) return normalizedAddition;
    if (normalizedAddition.isEmpty) return normalizedBase;
    if (normalizedBase == normalizedAddition) return normalizedBase;
    if (normalizedAddition.startsWith(normalizedBase)) {
      return normalizedAddition;
    }
    if (normalizedBase.endsWith(normalizedAddition) ||
        normalizedBase.contains(normalizedAddition)) {
      return normalizedBase;
    }

    final baseTokens = normalizedBase.split(' ');
    final additionTokens = normalizedAddition.split(' ');
    final maxOverlap = baseTokens.length < additionTokens.length
        ? baseTokens.length
        : additionTokens.length;
    for (var length = maxOverlap; length > 0; length--) {
      final baseTail = baseTokens.sublist(baseTokens.length - length).join(' ');
      final additionHead = additionTokens.sublist(0, length).join(' ');
      if (baseTail == additionHead) {
        return [...baseTokens, ...additionTokens.skip(length)].join(' ');
      }
    }
    return '$normalizedBase $normalizedAddition';
  }

  String _normalizeTranscript(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _resetCommandExecution() {
    latestCommandExecution = null;
    _completedCommandFingerprint = null;
    if (_isExecutingCommand) {
      _executionGeneration += 1;
      _isExecutingCommand = false;
      _activeCommandFingerprint = null;
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (_disposed) return;
    _commitCurrentPartialTranscript();
    nativeListening = false;
    lastError = error.errorMsg;
    final permissionError =
        error.errorMsg.contains('permission') ||
        error.errorMsg.contains('not_allowed');
    if (permissionError) {
      microphonePermissionState = MicrophonePermissionState.denied;
    }
    phase = permissionError
        ? VoiceAssistantPhase.permissionDenied
        : VoiceAssistantPhase.unclear;
    feedback = permissionError
        ? microphonePermissionState.userMessage
        : 'Suara belum jelas, coba rekam ulang.';
    SafeDiagnostics.voiceEvent(
      'speech_error',
      state: phase.name,
      permission: permissionError ? microphonePermissionState.name : null,
      status: error.permanent ? 'permanent' : 'recoverable',
    );
    notifyListeners();
  }

  void _handleSpeechStatus(String status) {
    if (_disposed) return;
    if (status == 'done' || status == 'notListening') {
      _commitCurrentPartialTranscript();
      nativeListening = false;
      _debugTranscript('speech-status-$status');
      notifyListeners();
    }
  }

  void _debugTranscript(String event) {
    SafeDiagnostics.voiceTranscript(
      event: event,
      finalText: _finalTranscriptBuffer,
      partialText: _currentPartialTranscript,
      combinedText: _combinedTranscript(),
    );
  }

  bool _isListeningGenerationActive(int generation) {
    return !_disposed && generation == _listeningGeneration;
  }

  TransactionDraft _bestEffortDraft(
    String text,
    VoiceParseResult result,
    VoiceParseContext context,
  ) {
    return TransactionDraft(
      kind: result.kind,
      productName: '',
      quantity: 1,
      unit: SaleUnit.pcs,
      unitPrice: 0,
      discount: 0,
      categoryName: result.categoryName ?? _fallbackCategory(result.kind),
      walletName: result.walletName ?? context.defaultWalletName ?? '',
      segment: PriceSegment.retail,
      note: result.normalizedText,
      rawText: text,
    );
  }

  String _fallbackCategory(TransactionKind kind) {
    return switch (kind) {
      TransactionKind.sale => 'Penjualan',
      TransactionKind.expense => 'Lain-lain',
      TransactionKind.income => 'Pemasukan',
      TransactionKind.adjustment => 'Penyesuaian',
    };
  }

  String _buildFeedback(TransactionDraft draft, VoiceParseResult parseResult) {
    final lines = draft.effectiveLines;
    for (final line in lines) {
      if (line.productStatus == TransactionDraftProductStatus.ambiguous) {
        final candidates = line.productCandidates.join(' atau ');
        return candidates.isEmpty
            ? 'Produk ${line.productName} masih ambigu. Pilih produk yang benar di preview.'
            : 'Saya menemukan $candidates. Pilih produk yang dimaksud di preview.';
      }
      if (line.productStatus == TransactionDraftProductStatus.notFound) {
        return 'Produk ${line.productName} belum ditemukan dan harganya belum disebutkan. Isi harga atau hapus item di preview.';
      }
    }

    if (parseResult.needsReview) {
      if (draft.kind == TransactionKind.sale && draft.amount > 0) {
        final itemSummary = lines.length == 1
            ? '${lines.first.productName} ${quantityLabel(lines.first.quantity)} ${lines.first.unit.label}'
            : '${lines.length} item';
        return 'Oke, penjualan $itemSummary senilai ${rupiah(draft.amount)} sudah ditangkap. Ada detail yang perlu dicek di preview.';
      }
      return 'Miki sudah menangkap sebagian transaksi. Ada detail yang perlu dicek, silakan koreksi di preview sebelum disimpan.';
    }

    final amount = rupiah(draft.amount);
    switch (draft.kind) {
      case TransactionKind.sale:
        return 'Oke, penjualan ${draft.productName} ${quantityLabel(draft.quantity)} ${draft.unit.label} senilai $amount. Silakan cek sebelum disimpan.';
      case TransactionKind.expense:
        return 'Oke, pengeluaran kategori ${draft.categoryName} sebesar $amount. Silakan cek detailnya.';
      case TransactionKind.income:
        return 'Oke, pemasukan kategori ${draft.categoryName} sebesar $amount sudah disiapkan.';
      case TransactionKind.adjustment:
        return 'Oke, penyesuaian saldo sebesar $amount sudah disiapkan.';
    }
  }

  bool _hasWakeWord(String value) {
    return _wakeWordDetector.containsWakeWord(value);
  }

  String _transcriptWithoutWakeWord(String value) {
    return _wakeWordDetector.stripWakeWord(value);
  }

  @override
  void dispose() {
    _disposed = true;
    _listeningGeneration += 1;
    _businessConversationHandler.clear();
    _executionGeneration += 1;
    _isExecutingCommand = false;
    _activeCommandFingerprint = null;
    if (nativeListening) {
      nativeListening = false;
      unawaited(
        _speech.cancel().catchError(
          (error, stackTrace) => SafeDiagnostics.failure(
            'voice_dispose_speech_cancel_failed',
            error,
            stackTrace,
          ),
        ),
      );
    }
    if (_ttsConfigured) {
      try {
        unawaited(
          _tts.stop().catchError(
            (error, stackTrace) => SafeDiagnostics.failure(
              'voice_dispose_tts_stop_failed',
              error,
              stackTrace,
            ),
          ),
        );
      } catch (error, stackTrace) {
        SafeDiagnostics.failure(
          'voice_dispose_tts_unavailable',
          error,
          stackTrace,
        );
      }
    }
    super.dispose();
  }
}
