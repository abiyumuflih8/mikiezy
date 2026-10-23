import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as speech;

import '../../models/mikiezy_models.dart';
import '../../state/app_state.dart';
import '../diagnostics/safe_diagnostics.dart';
import 'microphone_permission_service.dart';
import 'silence_detector.dart';
import 'voice_business_query_handler.dart';
import 'voice_command.dart';
import 'voice_command_executor.dart';
import 'voice_command_router.dart';
import 'voice_entry_launch_source.dart';
import 'voice_navigation_handler.dart';
import 'voice_parse_context.dart';
import 'voice_parse_result.dart';
import 'voice_transaction_parser_v2.dart';
import 'wake_word_detector.dart';

typedef VoicePreviewRequested = void Function(TransactionDraft draft);
typedef VoiceEntryRequested =
    void Function(
      VoiceEntryLaunchSource launchSource, {
      String? initialTranscript,
    });

enum VoiceAssistantStatus {
  disabled,
  idle,
  wakeWordListening,
  wakeWordDetected,
  listeningCommand,
  processing,
  openingPreview,
  error,
}

enum _ListeningMode { none, wakeWord, command }

class VoiceAssistantScope extends InheritedNotifier<VoiceAssistantManager> {
  const VoiceAssistantScope({
    super.key,
    required VoiceAssistantManager super.notifier,
    required super.child,
  });

  static VoiceAssistantManager of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<VoiceAssistantScope>();
    assert(scope != null, 'VoiceAssistantScope is missing above this widget.');
    return scope!.notifier!;
  }

  static VoiceAssistantManager? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<VoiceAssistantScope>()
        ?.notifier;
  }
}

class VoiceAssistantManager extends ChangeNotifier {
  static const _wakeWordListenFor = Duration(seconds: 55);
  static const _wakeWordPauseFor = Duration(seconds: 20);
  static const _wakeWordRestartDelay = Duration(milliseconds: 700);
  static const _wakeWordHealthCheckInterval = Duration(seconds: 8);
  static const _wakeWordMaxSessionAge = Duration(seconds: 70);

  VoiceAssistantManager({
    required this.state,
    required this.onPreviewRequested,
    this.onVoiceEntryRequested,
    VoiceTransactionParserV2? parser,
    bool Function()? isAppLocked,
    WakeWordDetector? wakeWordDetector,
    speech.SpeechToText? speechToText,
    VoiceCommandRouter? commandRouter,
    VoiceCommandExecutor? commandExecutor,
    VoiceBusinessQueryHandler? businessQueryHandler,
    MicrophonePermissionService? microphonePermissionService,
    this.navigationHandler,
  }) : _parser = parser ?? const VoiceTransactionParserV2(),
       _isAppLocked = isAppLocked ?? _alwaysUnlocked,
       _wakeWordDetector = wakeWordDetector ?? const WakeWordDetector(),
       _speech = speechToText ?? speech.SpeechToText(),
       _commandRouter = commandRouter ?? const VoiceCommandRouter(),
       _commandExecutor = commandExecutor ?? VoiceCommandExecutor(),
       _businessQueryHandler =
           businessQueryHandler ?? const VoiceBusinessQueryHandler(),
       _microphonePermissionService =
           microphonePermissionService ??
           const PermissionHandlerMicrophonePermissionService(),
       _silenceDetector = SilenceDetector(
         timeout: Duration(seconds: state.silentTimeoutSeconds),
       ) {
    state.addListener(_handleStateChanged);
  }

  final MikiezyState state;
  final VoicePreviewRequested onPreviewRequested;
  final VoiceEntryRequested? onVoiceEntryRequested;
  final VoiceTransactionParserV2 _parser;
  final bool Function() _isAppLocked;
  final WakeWordDetector _wakeWordDetector;
  final speech.SpeechToText _speech;
  final VoiceCommandRouter _commandRouter;
  final VoiceCommandExecutor _commandExecutor;
  final VoiceBusinessQueryHandler _businessQueryHandler;
  final MicrophonePermissionService _microphonePermissionService;
  final VoiceNavigationHandler? navigationHandler;
  final SilenceDetector _silenceDetector;

  VoiceAssistantStatus status = VoiceAssistantStatus.idle;
  String feedback = 'Miki siap.';
  String wakeTranscript = '';
  String commandTranscript = '';
  VoiceParseResult? latestParseResult;
  TransactionDraft? latestDraft;
  VoiceCommandExecutionResult? latestCommandExecution;
  double soundLevel = 0;

  bool _initialized = false;
  bool _speechAvailable = false;
  bool _speechActive = false;
  bool _appForeground = true;
  bool _manualSessionPaused = false;
  bool _appSecurityLocked = false;
  bool _isStarting = false;
  bool _isStopping = false;
  bool _isProcessing = false;
  bool _isOpeningPreview = false;
  bool _isOpeningVoiceEntry = false;
  bool _disposed = false;
  int _foregroundAttachmentCount = 0;
  int _currentSessionId = 0;
  Timer? _restartTimer;
  Timer? _wakeWordWatchdogTimer;
  DateTime? _wakeWordSessionStartedAt;
  _ListeningMode _mode = _ListeningMode.none;

  bool get isListeningForWakeWord =>
      status == VoiceAssistantStatus.wakeWordListening;
  bool get isListeningCommand =>
      status == VoiceAssistantStatus.listeningCommand ||
      status == VoiceAssistantStatus.wakeWordDetected;
  bool get isBusy =>
      _isStarting ||
      _isStopping ||
      _isProcessing ||
      _isOpeningPreview ||
      _isOpeningVoiceEntry;
  bool get isMicActive =>
      isListeningForWakeWord || isListeningCommand || _speechActive;

  String statusLabel({required bool en}) {
    return switch (status) {
      VoiceAssistantStatus.disabled =>
        en ? 'Wake word off' : 'Wake word nonaktif',
      VoiceAssistantStatus.idle => en ? 'Miki is ready' : 'Miki siap mendengar',
      VoiceAssistantStatus.wakeWordListening =>
        en ? 'Listening for "Miki"' : 'Mendengarkan kata "Miki"',
      VoiceAssistantStatus.wakeWordDetected =>
        en ? 'Wake word detected' : 'Wake word terdeteksi',
      VoiceAssistantStatus.listeningCommand =>
        en ? 'Miki is listening' : 'Miki siap mendengar',
      VoiceAssistantStatus.processing => en ? 'Processing' : 'Memproses',
      VoiceAssistantStatus.openingPreview =>
        en ? 'Opening preview' : 'Membuka preview',
      VoiceAssistantStatus.error => en ? 'Voice error' : 'Voice error',
    };
  }

  String helperText({required bool en}) {
    return switch (status) {
      VoiceAssistantStatus.disabled =>
        en
            ? 'Turn on handsfree wake word in Settings.'
            : 'Aktifkan handsfree wake word di Setelan.',
      VoiceAssistantStatus.listeningCommand =>
        en
            ? 'Speak the transaction, then pause for ${state.silentTimeoutSeconds} seconds.'
            : 'Ucapkan transaksi, lalu diam ${state.silentTimeoutSeconds} detik.',
      VoiceAssistantStatus.processing =>
        en
            ? 'Miki is preparing your preview.'
            : 'Miki sedang menyiapkan preview.',
      VoiceAssistantStatus.openingPreview =>
        en
            ? 'Review the transaction before saving.'
            : 'Cek preview sebelum menyimpan.',
      VoiceAssistantStatus.error => feedback,
      _ =>
        en
            ? 'Say "Miki" while this app is open.'
            : 'Ucapkan "Miki" saat aplikasi terbuka.',
    };
  }

  void attachForeground() {
    _foregroundAttachmentCount += 1;
    unawaited(startForeground());
  }

  Future<void> detachForeground() async {
    _foregroundAttachmentCount = (_foregroundAttachmentCount - 1)
        .clamp(0, 999)
        .toInt();
    if (_foregroundAttachmentCount == 0) {
      await _cancelListening();
      _setStatus(VoiceAssistantStatus.idle, 'Miki siap.');
    }
  }

  void setAppForeground(bool value) {
    _appForeground = value;
    if (value) {
      unawaited(startForeground());
    } else {
      unawaited(_cancelListening());
    }
  }

  void setAppSecurityLocked(bool value) {
    if (_appSecurityLocked == value) return;
    _appSecurityLocked = value;
    if (value) {
      unawaited(_cancelListening());
      _setStatus(
        VoiceAssistantStatus.idle,
        'Aplikasi terkunci. Voice assistant dijeda.',
      );
    } else {
      unawaited(_restartWakeWordDebounced());
    }
  }

  Future<void> pauseForManualSession() async {
    _manualSessionPaused = true;
    await _cancelListening();
    _setStatus(VoiceAssistantStatus.idle, 'Mode tap-to-talk aktif.');
  }

  Future<void> resumeAfterManualSession() async {
    _manualSessionPaused = false;
    await _restartWakeWordDebounced();
  }

  Future<void> stopHandsfree() async {
    await _cancelListening();
    _setStatus(VoiceAssistantStatus.disabled, 'Wake word nonaktif.');
  }

  Future<void> startForeground() async {
    if (!_canStartListening) return;
    if (!_shouldRunHandsfree) {
      _setStatus(
        state.handsfreeWakeWordEnabled
            ? VoiceAssistantStatus.idle
            : VoiceAssistantStatus.disabled,
        'Miki siap.',
      );
      return;
    }
    if (_speechActive && _mode == _ListeningMode.wakeWord) return;

    final permission = await _microphonePermissionService.check();
    if (_disposed) return;
    SafeDiagnostics.voiceEvent(
      'wake_word_permission_check',
      state: status.name,
      permission: permission.name,
    );
    if (!permission.canListen) {
      await _cancelListening();
      _setStatus(VoiceAssistantStatus.error, permission.userMessage);
      return;
    }

    final ready = await _ensureSpeechReady();
    if (_disposed) return;
    if (!ready) {
      _setStatus(
        VoiceAssistantStatus.error,
        'Speech recognition belum tersedia di perangkat ini.',
      );
      return;
    }

    _ensureWakeWordWatchdog();
    await _startWakeWordListening();
  }

  Future<void> startManualCommand() async {
    await _openVoiceEntry(
      VoiceEntryLaunchSource.manualTap,
      initialTranscript: null,
    );
  }

  Future<void> _openVoiceEntry(
    VoiceEntryLaunchSource launchSource, {
    String? initialTranscript,
  }) async {
    if (_disposed || _isOpeningVoiceEntry || _isProcessing) return;
    _isOpeningVoiceEntry = true;
    _manualSessionPaused = true;
    _restartTimer?.cancel();
    _silenceDetector.stop();
    await _cancelListening();

    if (_disposed) {
      _isOpeningVoiceEntry = false;
      return;
    }

    final isWakeWord = launchSource == VoiceEntryLaunchSource.wakeWord;
    _setStatus(
      isWakeWord
          ? VoiceAssistantStatus.wakeWordDetected
          : VoiceAssistantStatus.idle,
      isWakeWord
          ? 'Wake word Miki terdeteksi. Membuka recording.'
          : 'Mode tap-to-talk aktif.',
    );

    final opener = onVoiceEntryRequested;
    if (opener == null) {
      _isOpeningVoiceEntry = false;
      _setStatus(
        VoiceAssistantStatus.error,
        'Voice recording screen belum tersedia.',
      );
      return;
    }

    opener(
      launchSource,
      initialTranscript:
          initialTranscript == null || initialTranscript.trim().isEmpty
          ? null
          : initialTranscript.trim(),
    );
    _isOpeningVoiceEntry = false;
  }

  Future<void> _startWakeWordListening() async {
    if (!_canStartListening || !_shouldRunHandsfree) return;
    if (_speechActive && _mode == _ListeningMode.wakeWord) return;
    if (_speechActive) await _stopListening();

    final sessionId = _nextSession();
    _restartTimer?.cancel();
    _mode = _ListeningMode.wakeWord;
    wakeTranscript = '';
    commandTranscript = '';
    latestParseResult = null;
    latestDraft = null;
    latestCommandExecution = null;
    _wakeWordSessionStartedAt = DateTime.now();
    _ensureWakeWordWatchdog();
    _setStatus(
      VoiceAssistantStatus.wakeWordListening,
      'Mendengarkan kata Miki.',
    );

    await _listen(
      sessionId: sessionId,
      mode: _ListeningMode.wakeWord,
      listenFor: _wakeWordListenFor,
      pauseFor: _wakeWordPauseFor,
    );
  }

  Future<void> _listen({
    required int sessionId,
    required _ListeningMode mode,
    required Duration listenFor,
    required Duration pauseFor,
  }) async {
    if (_isStarting || _disposed) return;
    _isStarting = true;
    try {
      _speechActive = true;
      await _speech.listen(
        onResult: (result) => _handleSpeechResult(result, sessionId),
        onSoundLevelChange: _handleSoundLevel,
        listenOptions: speech.SpeechListenOptions(
          localeId: 'id_ID',
          listenFor: listenFor,
          pauseFor: pauseFor,
          partialResults: true,
          cancelOnError: false,
          listenMode: speech.ListenMode.dictation,
        ),
      );
    } catch (error) {
      if (sessionId == _currentSessionId) {
        _speechActive = false;
        _mode = _ListeningMode.none;
        _wakeWordSessionStartedAt = null;
        _setStatus(VoiceAssistantStatus.error, error.toString());
        if (mode == _ListeningMode.wakeWord && _shouldRunHandsfree) {
          unawaited(
            _restartWakeWordDebounced(delay: const Duration(seconds: 2)),
          );
        }
      }
    } finally {
      if (sessionId == _currentSessionId) _isStarting = false;
    }
  }

  void _handleSpeechResult(SpeechRecognitionResult result, int sessionId) {
    if (_disposed) return;
    if (sessionId != _currentSessionId || _isProcessing || _isOpeningPreview) {
      return;
    }
    final words = result.recognizedWords.trim();
    if (words.isEmpty) return;

    if (_mode == _ListeningMode.wakeWord) {
      wakeTranscript = words;
      if (!_wakeWordDetector.containsWakeWord(words)) {
        _notify();
        return;
      }

      commandTranscript = _wakeWordDetector.stripWakeWord(words);
      _mode = _ListeningMode.none;
      _setStatus(
        VoiceAssistantStatus.wakeWordDetected,
        'Wake word Miki terdeteksi.',
      );
      unawaited(
        _openVoiceEntry(
          VoiceEntryLaunchSource.wakeWord,
          initialTranscript: commandTranscript,
        ),
      );
      return;
    }

    if (_mode == _ListeningMode.command) {
      final command = _wakeWordDetector.containsWakeWord(words)
          ? _wakeWordDetector.stripWakeWord(words)
          : words;
      if (command.trim().isNotEmpty) commandTranscript = command.trim();
      _touchCommandActivity();
      _setStatus(
        VoiceAssistantStatus.listeningCommand,
        'Miki siap mendengar transaksi.',
      );
    }
  }

  void _touchCommandActivity() {
    if (_mode != _ListeningMode.command || _isProcessing || _isOpeningPreview) {
      return;
    }
    _silenceDetector.timeout = Duration(seconds: state.silentTimeoutSeconds);
    _silenceDetector.reset(() {
      unawaited(_processCommandTranscript());
    });
  }

  void _handleSoundLevel(double level) {
    if (_disposed) return;
    soundLevel = level;
    _notify();
  }

  void _handleSpeechStatus(String statusText) {
    if (_disposed) return;
    if (statusText != 'done' && statusText != 'notListening') return;
    if (_isProcessing || _isOpeningPreview || _isOpeningVoiceEntry) {
      return;
    }

    final modeAtDone = _mode;
    _speechActive = false;
    _wakeWordSessionStartedAt = null;
    if (_isStarting || _isStopping) {
      if (modeAtDone == _ListeningMode.wakeWord) {
        _mode = _ListeningMode.none;
        if (_shouldRunHandsfree) {
          unawaited(_restartWakeWordDebounced());
        }
      }
      return;
    }

    if (modeAtDone == _ListeningMode.command) {
      _mode = _ListeningMode.none;
      _setStatus(VoiceAssistantStatus.idle, 'Miki siap.');
      unawaited(_restartWakeWordDebounced());
      return;
    }
    if (modeAtDone == _ListeningMode.wakeWord) {
      _mode = _ListeningMode.none;
      if (status == VoiceAssistantStatus.wakeWordListening &&
          _shouldRunHandsfree) {
        unawaited(_restartWakeWordDebounced());
      }
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (_disposed) return;
    _speechActive = false;
    _mode = _ListeningMode.none;
    _wakeWordSessionStartedAt = null;
    if (_manualSessionPaused) return;
    final permissionError =
        error.errorMsg.contains('permission') ||
        error.errorMsg.contains('not_allowed');
    _setStatus(
      VoiceAssistantStatus.error,
      permissionError
          ? 'Izin mikrofon belum aktif.'
          : 'Suara belum jelas, Miki mencoba mendengarkan lagi.',
    );
    if (!permissionError &&
        _shouldRunHandsfree &&
        !_isProcessing &&
        !_isOpeningVoiceEntry) {
      unawaited(_restartWakeWordDebounced());
    }
  }

  Future<void> _processCommandTranscript() async {
    if (_isProcessing || _isOpeningPreview) return;
    _isProcessing = true;
    _silenceDetector.stop();
    await _stopListening();

    final text = _wakeWordDetector.stripWakeWord(commandTranscript).trim();
    if (text.isEmpty) {
      _mode = _ListeningMode.none;
      _isProcessing = false;
      _setStatus(
        VoiceAssistantStatus.error,
        'Wake word terdeteksi, tapi transaksi belum terdengar jelas.',
      );
      await _restartWakeWordDebounced();
      return;
    }

    _setStatus(VoiceAssistantStatus.processing, 'Miki sedang memahami suara.');
    final command = _commandRouter.route(text);
    if (command.intent.isBusinessQuery) {
      final data = state.businessQueryDataFor(isAppLocked: _isAppLocked());
      final runtimeHandlers = <VoiceCommandIntent, VoiceCommandHandler>{
        for (final intent in VoiceCommandIntent.values)
          if (_businessQueryHandler.supports(intent))
            intent: (routedCommand, context) => _businessQueryHandler.handle(
              command: routedCommand,
              data: data,
              now: DateTime.now(),
            ),
      };
      final execution = await _commandExecutor.execute(
        command,
        runtimeHandlers: runtimeHandlers,
      );
      if (_disposed) return;
      latestCommandExecution = execution;
      latestParseResult = null;
      latestDraft = null;
      _mode = _ListeningMode.none;
      _isProcessing = false;
      _setStatus(VoiceAssistantStatus.idle, execution.response.displayText);
      await _restartWakeWordDebounced();
      return;
    }
    if (command.intent.isNavigation) {
      final handler = navigationHandler;
      final execution = await _commandExecutor.execute(
        command,
        runtimeHandlers: {
          if (handler != null && handler.supports(command.intent))
            command.intent: (routedCommand, context) =>
                handler.handle(routedCommand),
        },
      );
      if (_disposed) return;
      latestCommandExecution = execution;
      _mode = _ListeningMode.none;
      _isProcessing = false;
      _setStatus(VoiceAssistantStatus.idle, execution.response.displayText);
      await _restartWakeWordDebounced();
      return;
    }
    if (!command.intent.isTransaction &&
        command.intent != VoiceCommandIntent.unknown) {
      final execution = await _commandExecutor.execute(command);
      if (_disposed) return;
      latestCommandExecution = execution;
      latestParseResult = null;
      latestDraft = null;
      _mode = _ListeningMode.none;
      _isProcessing = false;
      _setStatus(VoiceAssistantStatus.idle, execution.response.displayText);
      await _restartWakeWordDebounced();
      return;
    }

    final parsed = _parser.parse(text, context: _voiceParseContext());
    final draft = parsed.draft ?? _bestEffortDraft(text, parsed);
    final result = parsed.draft == null
        ? parsed.copyWith(draft: draft, needsReview: true)
        : parsed;
    latestParseResult = result;
    latestDraft = draft;
    _mode = _ListeningMode.none;
    _isProcessing = false;
    _isOpeningPreview = true;
    _setStatus(
      VoiceAssistantStatus.openingPreview,
      result.needsReview
          ? 'Ada detail yang perlu dicek di preview.'
          : 'Transaksi siap direview.',
    );

    onPreviewRequested(draft);
    _isOpeningPreview = false;
    _setStatus(VoiceAssistantStatus.idle, 'Miki siap.');
    await _restartWakeWordDebounced();
  }

  Future<void> _restartWakeWordDebounced({
    Duration delay = _wakeWordRestartDelay,
  }) async {
    if (!_shouldRunHandsfree || _disposed) return;
    if (_restartTimer?.isActive ?? false) return;
    _ensureWakeWordWatchdog();
    _restartTimer = Timer(delay, () {
      _restartTimer = null;
      if (!_shouldRunHandsfree || _disposed) return;
      if (_canStartListening && !_speechActive) {
        unawaited(startForeground());
      } else if (!_speechActive) {
        unawaited(_restartWakeWordDebounced());
      }
    });
  }

  void _ensureWakeWordWatchdog() {
    if (_wakeWordWatchdogTimer?.isActive ?? false) return;
    _wakeWordWatchdogTimer = Timer.periodic(
      _wakeWordHealthCheckInterval,
      (_) => _checkWakeWordHealth(),
    );
  }

  void _stopWakeWordWatchdog() {
    _wakeWordWatchdogTimer?.cancel();
    _wakeWordWatchdogTimer = null;
  }

  void _checkWakeWordHealth() {
    if (_disposed) {
      _stopWakeWordWatchdog();
      return;
    }
    if (!_shouldRunHandsfree) {
      _stopWakeWordWatchdog();
      return;
    }
    if (_isStarting ||
        _isStopping ||
        _isProcessing ||
        _isOpeningPreview ||
        _isOpeningVoiceEntry) {
      return;
    }

    final wakeModeActive = _mode == _ListeningMode.wakeWord;
    final nativeListening = _speech.isListening;
    if (wakeModeActive && _speechActive && !nativeListening) {
      SafeDiagnostics.voiceEvent(
        'wake_word_native_listener_stopped',
        generation: _currentSessionId,
        state: status.name,
      );
      _speechActive = false;
      _mode = _ListeningMode.none;
      _wakeWordSessionStartedAt = null;
      _setStatus(VoiceAssistantStatus.idle, 'Miki siap.');
      unawaited(_restartWakeWordDebounced());
      return;
    }

    final startedAt = _wakeWordSessionStartedAt;
    if (wakeModeActive &&
        _speechActive &&
        startedAt != null &&
        DateTime.now().difference(startedAt) > _wakeWordMaxSessionAge) {
      SafeDiagnostics.voiceEvent(
        'wake_word_standby_refresh',
        generation: _currentSessionId,
        state: status.name,
      );
      unawaited(_refreshWakeWordSession());
      return;
    }

    if (!_speechActive &&
        (status == VoiceAssistantStatus.idle ||
            status == VoiceAssistantStatus.error ||
            status == VoiceAssistantStatus.wakeWordListening)) {
      unawaited(_restartWakeWordDebounced());
    }
  }

  Future<void> _refreshWakeWordSession() async {
    if (_isStopping || _disposed || !_shouldRunHandsfree) return;
    await _stopListening();
    _mode = _ListeningMode.none;
    await _restartWakeWordDebounced();
  }

  @visibleForTesting
  void handleSpeechStatusForTest(String statusText) {
    _handleSpeechStatus(statusText);
  }

  @visibleForTesting
  void simulateWakeWordListeningForTest({bool isStarting = false}) {
    _mode = _ListeningMode.wakeWord;
    _speechActive = true;
    _isStarting = isStarting;
    _wakeWordSessionStartedAt = DateTime.now();
    status = VoiceAssistantStatus.wakeWordListening;
  }

  @visibleForTesting
  bool get debugSpeechActive => _speechActive;

  @visibleForTesting
  bool get debugIsStarting => _isStarting;

  VoiceParseContext _voiceParseContext() {
    return VoiceParseContext(
      products: state.products,
      wallets: state.wallets,
      categories: state.categories,
      productAliases: state.voiceProductAliases,
      unitAliases: state.voiceUnitAliases,
      defaultWalletName: _defaultWalletName(),
    );
  }

  String? _defaultWalletName() {
    for (final wallet in state.wallets) {
      if (wallet.isPrimary) return wallet.name;
    }
    return state.wallets.isEmpty ? null : state.wallets.first.name;
  }

  TransactionDraft _bestEffortDraft(String text, VoiceParseResult result) {
    return TransactionDraft(
      kind: result.kind,
      productName: '',
      quantity: 1,
      unit: SaleUnit.pcs,
      unitPrice: 0,
      discount: 0,
      categoryName: result.categoryName ?? _fallbackCategory(result.kind),
      walletName: result.walletName ?? _defaultWalletName() ?? '',
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

  bool get _canStartListening {
    return !_disposed &&
        !_speechActive &&
        !_isStarting &&
        !_isStopping &&
        !_isProcessing &&
        !_isOpeningPreview &&
        !_isOpeningVoiceEntry;
  }

  int _nextSession() {
    _currentSessionId += 1;
    return _currentSessionId;
  }

  Future<bool> _ensureSpeechReady() async {
    if (_initialized) return _speechAvailable;
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: _handleSpeechStatus,
        onError: _handleSpeechError,
        debugLogging: false,
      );
    } catch (error) {
      _speechAvailable = false;
      _setStatus(VoiceAssistantStatus.error, error.toString());
    } finally {
      _initialized = true;
    }
    return _speechAvailable;
  }

  Future<void> _stopListening() async {
    _silenceDetector.stop();
    if (_isStopping || (!_speechActive && _mode == _ListeningMode.none)) {
      return;
    }
    _isStopping = true;
    _nextSession();
    _speechActive = false;
    try {
      await _speech.stop();
    } catch (error, stackTrace) {
      SafeDiagnostics.failure(
        'wake_word_speech_stop_failed',
        error,
        stackTrace,
      );
    } finally {
      _isStopping = false;
    }
  }

  Future<void> _cancelListening() async {
    _silenceDetector.stop();
    _restartTimer?.cancel();
    _restartTimer = null;
    _stopWakeWordWatchdog();
    if (_isStopping) return;
    _isStopping = true;
    _nextSession();
    _mode = _ListeningMode.none;
    _speechActive = false;
    _isStarting = false;
    _wakeWordSessionStartedAt = null;
    try {
      await _speech.cancel();
    } catch (error, stackTrace) {
      SafeDiagnostics.failure(
        'wake_word_speech_cancel_failed',
        error,
        stackTrace,
      );
    } finally {
      _isStopping = false;
    }
  }

  bool get _shouldRunHandsfree {
    return state.handsfreeWakeWordEnabled &&
        _appForeground &&
        !_appSecurityLocked &&
        !_manualSessionPaused &&
        _foregroundAttachmentCount > 0;
  }

  void _handleStateChanged() {
    if (!state.handsfreeWakeWordEnabled) {
      unawaited(_cancelListening());
      _setStatus(VoiceAssistantStatus.disabled, 'Wake word nonaktif.');
      return;
    }
    if (_shouldRunHandsfree &&
        (status == VoiceAssistantStatus.disabled ||
            status == VoiceAssistantStatus.idle ||
            status == VoiceAssistantStatus.error)) {
      unawaited(startForeground());
    }
  }

  void _setStatus(VoiceAssistantStatus value, String message) {
    status = value;
    feedback = message;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    state.removeListener(_handleStateChanged);
    _silenceDetector.dispose();
    _restartTimer?.cancel();
    _stopWakeWordWatchdog();
    try {
      unawaited(
        _speech.cancel().catchError(
          (error, stackTrace) => SafeDiagnostics.failure(
            'wake_word_dispose_cancel_failed',
            error,
            stackTrace,
          ),
        ),
      );
    } catch (error, stackTrace) {
      SafeDiagnostics.failure(
        'wake_word_dispose_speech_unavailable',
        error,
        stackTrace,
      );
    }
    super.dispose();
  }
}

bool _alwaysUnlocked() => false;
