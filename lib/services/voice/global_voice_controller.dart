import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../models/mikiezy_models.dart';
import '../diagnostics/safe_diagnostics.dart';
import '../voice_assistant_controller.dart';
import 'global_voice_engine.dart';
import 'voice_command.dart';
import 'voice_parse_context.dart';

enum GlobalVoiceSessionState {
  idle,
  listening,
  processing,
  waitingClarification,
  waitingConfirmation,
  speaking,
  completed,
  error,
  stopped,
}

typedef GlobalVoicePreviewCallback =
    Future<void> Function(TransactionDraft draft);

class GlobalVoiceController extends ChangeNotifier {
  GlobalVoiceController({
    required GlobalVoiceEngine sessionEngine,
    required VoiceParseContext Function() buildParseContext,
    required GlobalVoicePreviewCallback previewCallback,
    required Future<void> Function() pauseWakeWordSession,
    required Future<void> Function() resumeWakeWordSession,
    Duration Function()? silenceTimeoutProvider,
    bool Function()? isAppLocked,
    this.conversationRelistenDelay = const Duration(milliseconds: 450),
    this.nativeStopGracePeriod = const Duration(milliseconds: 350),
  }) : _engine = sessionEngine,
       _parseContextProvider = buildParseContext,
       _onPreviewRequested = previewCallback,
       _pauseWakeWord = pauseWakeWordSession,
       _resumeWakeWord = resumeWakeWordSession,
       _silenceTimeoutProvider =
           silenceTimeoutProvider ?? _defaultSilenceTimeout,
       _isAppLocked = isAppLocked ?? _alwaysUnlocked {
    _engine.addListener(_handleEngineChanged);
  }

  final GlobalVoiceEngine _engine;
  final VoiceParseContext Function() _parseContextProvider;
  final GlobalVoicePreviewCallback _onPreviewRequested;
  final Future<void> Function() _pauseWakeWord;
  final Future<void> Function() _resumeWakeWord;
  final Duration Function() _silenceTimeoutProvider;
  final bool Function() _isAppLocked;
  final Duration conversationRelistenDelay;
  final Duration nativeStopGracePeriod;

  GlobalVoiceSessionState sessionState = GlobalVoiceSessionState.idle;
  String transcript = '';
  String feedback = 'Miki siap.';
  bool isOpen = false;
  bool conversationMode = false;

  bool _appForeground = true;
  bool _sensitiveSurfaceVisible = false;
  bool _wakeWordPaused = false;
  bool _processing = false;
  bool _disposed = false;
  int _generation = 0;
  GlobalVoiceSessionState? _lastLoggedSessionState;
  String _lastObservedTranscript = '';
  Timer? _silenceTimer;
  Timer? _nativeStopTimer;
  Timer? _conversationTimer;

  bool get isListening => sessionState == GlobalVoiceSessionState.listening;

  bool get isBusy => switch (sessionState) {
    GlobalVoiceSessionState.processing ||
    GlobalVoiceSessionState.speaking => true,
    _ => false,
  };

  @visibleForTesting
  Object get engineIdentity => _engine;

  Future<void> startPushToTalk() => _startSession();

  Future<void> startFromWakeWord(String? initialTranscript) {
    return _startSession(
      initialTranscript: initialTranscript,
      wakeWordAlreadyDetected: true,
    );
  }

  Future<void> _startSession({
    String? initialTranscript,
    bool wakeWordAlreadyDetected = false,
  }) async {
    if (_disposed || _processing || _engine.nativeListening) return;
    if (!_appForeground) {
      _showBlocked('Mikrofon hanya dapat digunakan saat aplikasi terbuka.');
      return;
    }
    if (_isAppLocked()) {
      _showBlocked('Aplikasi masih terkunci. Buka kunci terlebih dahulu.');
      return;
    }
    if (_sensitiveSurfaceVisible) {
      _showBlocked('Tutup dialog atau form sensitif sebelum memakai voice.');
      return;
    }

    final generation = ++_generation;
    SafeDiagnostics.voiceEvent(
      'global_voice_session_start',
      generation: generation,
      state: sessionState.name,
      status: wakeWordAlreadyDetected ? 'wake_word' : 'push_to_talk',
    );
    _cancelTimers();
    isOpen = true;
    sessionState = GlobalVoiceSessionState.processing;
    feedback = 'Menyiapkan mikrofon...';
    transcript = initialTranscript?.trim() ?? '';
    _notify();

    try {
      await _ensureWakeWordPaused();
      if (_disposed || generation != _generation) return;
      _engine.clearTranscript();
      await _engine.startListening(
        initialTranscript: initialTranscript,
        wakeWordAlreadyDetected: wakeWordAlreadyDetected,
      );
      if (_disposed || generation != _generation) return;
      _syncFromEngine();
      SafeDiagnostics.voiceEvent(
        'global_voice_microphone_started',
        generation: generation,
        state: sessionState.name,
      );
    } catch (error, stackTrace) {
      _log('Global voice start failed', error, stackTrace);
      _setError('Mikrofon belum dapat dimulai. Coba lagi.');
    }
  }

  Future<void> processCurrentSession() async {
    if (_disposed || _processing || !isOpen) return;
    if (_isAppLocked() || !_appForeground || _sensitiveSurfaceVisible) {
      await stop(reason: 'Sesi voice dihentikan demi keamanan.');
      return;
    }

    final generation = _generation;
    final stopwatch = Stopwatch()..start();
    _processing = true;
    _cancelTimers();
    sessionState = GlobalVoiceSessionState.processing;
    feedback = 'Miki sedang memproses ucapan...';
    _notify();
    try {
      final result = await _engine.stopAndProcess(
        parseContext: _parseContextProvider(),
        speakResult: false,
      );
      if (_disposed || generation != _generation) return;
      transcript = _engine.transcript;
      feedback = _engine.feedback;

      if (result != null) {
        await _speakSafely(result.feedback, generation);
        if (_disposed || generation != _generation) return;
        final previewCompletion = _onPreviewRequested(result.draft);
        _finishForPreview();
        unawaited(
          previewCompletion.whenComplete(() async {
            if (_disposed) return;
            await _resumeWakeWordIfNeeded();
          }),
        );
        return;
      }

      final execution = _engine.latestCommandExecution;
      if (execution != null) {
        final response = execution.response;
        feedback = response.displayText;
        await _speakSafely(response.spokenText, generation);
        if (_disposed || generation != _generation) return;
        if (_engine.isAwaitingClarification) {
          sessionState = GlobalVoiceSessionState.waitingClarification;
          if (conversationMode) _scheduleConversationRelisten();
        } else if (response.kind == VoiceResponseKind.confirmation) {
          sessionState = GlobalVoiceSessionState.waitingConfirmation;
          if (conversationMode) _scheduleConversationRelisten();
        } else {
          sessionState = GlobalVoiceSessionState.completed;
        }
        _notify();
        return;
      }

      if (_engine.phase == VoiceAssistantPhase.unclear ||
          _engine.phase == VoiceAssistantPhase.permissionDenied) {
        _setError(_engine.feedback);
      } else {
        sessionState = GlobalVoiceSessionState.completed;
        _notify();
      }
    } catch (error, stackTrace) {
      _log('Global voice processing failed', error, stackTrace);
      _setError('Ucapan belum dapat diproses. Coba lagi.');
    } finally {
      stopwatch.stop();
      SafeDiagnostics.voiceEvent(
        'global_voice_processing_finished',
        generation: generation,
        state: sessionState.name,
        durationMilliseconds: stopwatch.elapsedMilliseconds,
      );
      _processing = false;
    }
  }

  Future<void> stop({String reason = 'Sesi voice dihentikan.'}) async {
    if (_disposed) return;
    _generation += 1;
    _processing = false;
    _cancelTimers();
    try {
      await _engine.cancelListening();
      await _engine.stopSpeaking();
      await _engine.cancelPendingMutation(errorCode: 'voice_session_stopped');
    } catch (error, stackTrace) {
      _log('Global voice stop failed', error, stackTrace);
    }
    sessionState = GlobalVoiceSessionState.stopped;
    feedback = reason;
    _notify();
  }

  Future<void> close() async {
    await stop();
    if (_disposed) return;
    isOpen = false;
    sessionState = GlobalVoiceSessionState.idle;
    transcript = '';
    feedback = 'Miki siap.';
    _engine.clearTranscript();
    _notify();
    await _resumeWakeWordIfNeeded();
  }

  void setConversationMode(bool value) {
    if (conversationMode == value) return;
    conversationMode = value;
    if (!value) _conversationTimer?.cancel();
    _notify();
  }

  void handleLifecycleState(AppLifecycleState state) {
    _appForeground = state == AppLifecycleState.resumed;
    SafeDiagnostics.voiceEvent(
      'global_voice_lifecycle',
      generation: _generation,
      state: sessionState.name,
      status: state.name,
    );
    if (_appForeground) {
      unawaited(_resumeWakeWordIfNeeded());
      return;
    }
    if (!_appForeground &&
        (isOpen || isBusy || _engine.nativeListening || _engine.isStarting)) {
      unawaited(_stopForLifecycle());
    }
  }

  void setAppLocked(bool value) {
    if (value && (isOpen || isBusy || _engine.nativeListening || _engine.isStarting)) {
      unawaited(_stopForLock());
    } else if (!value) {
      unawaited(_resumeWakeWordIfNeeded());
    }
  }

  void setSensitiveSurfaceVisible(bool value) {
    if (_sensitiveSurfaceVisible == value) return;
    _sensitiveSurfaceVisible = value;
    if (value && (isOpen || isBusy || _engine.nativeListening || _engine.isStarting)) {
      unawaited(
        stop(reason: 'Sesi voice dijeda saat dialog sensitif terbuka.'),
      );
    }
  }

  Future<void> _stopForLifecycle() async {
    await stop(reason: 'Sesi voice berhenti saat aplikasi di latar belakang.');
    if (_disposed) return;
    isOpen = false;
    _notify();
    await _resumeWakeWordIfNeeded();
  }

  Future<void> _stopForLock() async {
    await stop(reason: 'Sesi voice berhenti karena aplikasi terkunci.');
    if (_disposed) return;
    isOpen = false;
    _notify();
  }

  Future<void> _speakSafely(String text, int generation) async {
    if (text.trim().isEmpty || generation != _generation) return;
    await _engine.cancelListening();
    if (_disposed || generation != _generation) return;
    sessionState = GlobalVoiceSessionState.speaking;
    _notify();
    await _engine.speak(text);
  }

  void _scheduleConversationRelisten() {
    _conversationTimer?.cancel();
    _conversationTimer = Timer(conversationRelistenDelay, () async {
      if (_disposed ||
          !conversationMode ||
          !isOpen ||
          !_appForeground ||
          _isAppLocked() ||
          _sensitiveSurfaceVisible) {
        return;
      }
      if (_engine.isAwaitingClarification) {
        _engine.prepareForClarification();
      } else {
        _engine.clearTranscript();
      }
      try {
        await _engine.startListening(wakeWordAlreadyDetected: true);
        if (!_disposed) _syncFromEngine();
      } catch (error, stackTrace) {
        _log('Conversation relisten failed', error, stackTrace);
        _setError('Mode percakapan belum dapat melanjutkan mikrofon.');
      }
    });
  }

  void _handleEngineChanged() {
    if (_disposed) return;
    _syncFromEngine();
  }

  void _syncFromEngine() {
    transcript = _engine.transcript;
    feedback = _engine.feedback;
    if (_engine.phase == VoiceAssistantPhase.permissionDenied ||
        _engine.phase == VoiceAssistantPhase.unclear) {
      sessionState = GlobalVoiceSessionState.error;
      _cancelTimers();
      _notify();
      return;
    }
    if (_engine.nativeListening || _engine.isStarting) {
      if (!_processing) sessionState = GlobalVoiceSessionState.listening;
      if (transcript.trim().isNotEmpty &&
          transcript != _lastObservedTranscript) {
        _lastObservedTranscript = transcript;
        _scheduleSilenceProcessing();
      }
      _nativeStopTimer?.cancel();
    } else if (sessionState == GlobalVoiceSessionState.listening &&
        transcript.trim().isNotEmpty &&
        !_processing) {
      _nativeStopTimer?.cancel();
      _nativeStopTimer = Timer(
        nativeStopGracePeriod,
        () => unawaited(processCurrentSession()),
      );
    }
    _notify();
  }

  void _scheduleSilenceProcessing() {
    _silenceTimer?.cancel();
    final timeout = _silenceTimeoutProvider();
    _silenceTimer = Timer(timeout, () {
      if (_disposed || sessionState != GlobalVoiceSessionState.listening) {
        return;
      }
      unawaited(processCurrentSession());
    });
  }

  Future<void> _ensureWakeWordPaused() async {
    if (_wakeWordPaused) return;
    await _pauseWakeWord();
    _wakeWordPaused = true;
  }

  Future<void> _resumeWakeWordIfNeeded() async {
    if (!_wakeWordPaused || !_appForeground || _isAppLocked()) return;
    _wakeWordPaused = false;
    await _resumeWakeWord();
  }

  void _finishForPreview() {
    _generation += 1;
    _cancelTimers();
    isOpen = false;
    sessionState = GlobalVoiceSessionState.idle;
    _notify();
  }

  void _showBlocked(String message) {
    isOpen = true;
    SafeDiagnostics.voiceEvent(
      'global_voice_blocked',
      generation: _generation,
      state: sessionState.name,
    );
    _setError(message);
  }

  void _setError(String message) {
    sessionState = GlobalVoiceSessionState.error;
    feedback = message;
    _notify();
  }

  void _cancelTimers() {
    _silenceTimer?.cancel();
    _nativeStopTimer?.cancel();
    _conversationTimer?.cancel();
    _silenceTimer = null;
    _nativeStopTimer = null;
    _conversationTimer = null;
  }

  void _log(String label, Object error, StackTrace stackTrace) {
    SafeDiagnostics.failure(
      label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
      error,
      stackTrace,
    );
  }

  void _notify() {
    if (_lastLoggedSessionState != sessionState) {
      _lastLoggedSessionState = sessionState;
      SafeDiagnostics.voiceEvent(
        'global_voice_state_changed',
        generation: _generation,
        state: sessionState.name,
      );
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation += 1;
    _cancelTimers();
    _engine.removeListener(_handleEngineChanged);
    unawaited(_engine.cancelListening());
    _engine.dispose();
    if (_wakeWordPaused) unawaited(_resumeWakeWord());
    super.dispose();
  }
}

Duration _defaultSilenceTimeout() => const Duration(seconds: 5);

bool _alwaysUnlocked() => false;
