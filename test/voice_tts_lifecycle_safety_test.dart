import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mikiezy/services/voice/global_voice_controller.dart';
import 'package:mikiezy/services/voice/global_voice_engine.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_parse_context.dart';
import 'package:mikiezy/services/voice_assistant_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KI-01: VoiceAssistantController TTS Interruption Tests', () {
    test('Case A: Normal TTS completes without premature interruption', () async {
      final fakeTts = FakeFlutterTts();
      final controller = VoiceAssistantController(textToSpeech: fakeTts);
      addTearDown(controller.dispose);

      final speakFuture = controller.speak('Halo selamat datang');
      await pumpEventQueue();

      expect(fakeTts.speakCalls, 1);
      expect(fakeTts.stopCalls, 1); // Pre-utterance reset

      // Complete native utterance
      if (fakeTts.currentSpeakCompleter != null &&
          !fakeTts.currentSpeakCompleter!.isCompleted) {
        fakeTts.currentSpeakCompleter!.complete(1);
      }
      await speakFuture;

      expect(controller.lastError, isNull);
    });

    test('Case B: Controller cancelListening interrupts active TTS', () async {
      final fakeTts = FakeFlutterTts();
      final controller = VoiceAssistantController(textToSpeech: fakeTts);
      addTearDown(controller.dispose);

      final speakFuture = controller.speak('Sedang berbicara kalimat panjang');
      await pumpEventQueue();

      expect(fakeTts.speakCalls, 1);
      final initialStops = fakeTts.stopCalls; // 1 (pre-utterance reset)

      // When listening/session is cancelled while TTS is still speaking
      await controller.cancelListening();

      // Active TTS playback must be explicitly stopped upon cancel/interruption
      expect(
        fakeTts.stopCalls,
        greaterThan(initialStops),
        reason: 'cancelListening must call stopSpeaking to interrupt active TTS',
      );

      if (fakeTts.currentSpeakCompleter != null &&
          !fakeTts.currentSpeakCompleter!.isCompleted) {
        fakeTts.currentSpeakCompleter!.complete(1);
      }
      await speakFuture;
    });

    test('Case I: Native TTS stop error is caught gracefully without crash', () async {
      final fakeTts = FakeFlutterTts()..throwOnStop = true;
      final controller = VoiceAssistantController(textToSpeech: fakeTts);
      addTearDown(controller.dispose);

      // speak() attempts _tts.stop() internally; error must be caught in try-catch
      await controller.speak('Test throwing stop');
      expect(controller.lastError, contains('Native TTS stop failure'));
    });

    test('Case J: Dispose during active speech cleans up safely', () async {
      final fakeTts = FakeFlutterTts();
      final controller = VoiceAssistantController(textToSpeech: fakeTts);

      final speakFuture = controller.speak('Speech during dispose');
      await pumpEventQueue();
      controller.dispose();

      if (fakeTts.currentSpeakCompleter != null &&
          !fakeTts.currentSpeakCompleter!.isCompleted) {
        fakeTts.currentSpeakCompleter!.complete(1);
      }
      await speakFuture;
      // Expect no unhandled exception
    });
  });

  group('KI-01: GlobalVoiceController Lifecycle & Audio Interruption Tests', () {
    test('Case B2: stop() during active session requests engine stopSpeaking', () async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      await controller.startPushToTalk();
      expect(controller.sessionState, GlobalVoiceSessionState.listening);

      await controller.stop(reason: 'Dibatalkan pengguna');

      expect(engine.stopSpeakingCalls, greaterThan(0));
      expect(controller.sessionState, GlobalVoiceSessionState.stopped);
    });

    test('Case C: close() during active session stops TTS and stays idle', () async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      await controller.startPushToTalk();
      await controller.close();

      expect(engine.stopSpeakingCalls, greaterThan(0));
      expect(controller.isOpen, isFalse);
      expect(controller.sessionState, GlobalVoiceSessionState.idle);
    });

    test('Case D: AppLock activation during active session stops TTS', () async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      await controller.startPushToTalk();

      controller.setAppLocked(true);
      await pumpEventQueue();

      expect(engine.stopSpeakingCalls, greaterThan(0));
      expect(controller.sessionState, GlobalVoiceSessionState.stopped);
    });

    test('Case E: Background transition during active session stops TTS', () async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      await controller.startPushToTalk();

      controller.handleLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();

      expect(engine.stopSpeakingCalls, greaterThan(0));
      expect(controller.sessionState, GlobalVoiceSessionState.stopped);
    });

    test('Case F: Sensitive surface visibility stops TTS', () async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      await controller.startPushToTalk();

      controller.setSensitiveSurfaceVisible(true);
      await pumpEventQueue();

      expect(engine.stopSpeakingCalls, greaterThan(0));
      expect(controller.sessionState, GlobalVoiceSessionState.stopped);
    });

    test('Case G: Async speech cancellation generation guard prevents late callback leakage', () async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      await controller.startPushToTalk();
      expect(controller.sessionState, GlobalVoiceSessionState.listening);

      await controller.stop(reason: 'Stopped');
      expect(controller.sessionState, GlobalVoiceSessionState.stopped);

      engine.notifyListeners();
      expect(controller.sessionState, GlobalVoiceSessionState.stopped);
    });

    test('Case H: Cancelled session in conversation mode does not trigger relisten', () async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(
        engine,
        conversationDelay: const Duration(milliseconds: 20),
      );
      addTearDown(controller.dispose);

      controller.setConversationMode(true);
      await controller.startPushToTalk();
      expect(engine.startListeningCalls, 1);

      await controller.stop(reason: 'Stop before relisten');

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(engine.startListeningCalls, 1, reason: 'Cancelled session must not trigger conversation relisten');
    });

    test('Case K: Rapid stop and restart increments generation safely', () async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      await controller.startPushToTalk();
      await controller.stop();
      await controller.startPushToTalk();
      expect(controller.sessionState, GlobalVoiceSessionState.listening);
      await controller.stop();
      expect(controller.sessionState, GlobalVoiceSessionState.stopped);
    });
  });
}

GlobalVoiceController _createGlobalVoiceController(
  GlobalVoiceEngine engine, {
  Duration conversationDelay = const Duration(milliseconds: 450),
}) {
  return GlobalVoiceController(
    sessionEngine: engine,
    buildParseContext: () => const VoiceParseContext(),
    previewCallback: (_) async {},
    pauseWakeWordSession: () async {},
    resumeWakeWordSession: () async {},
    conversationRelistenDelay: conversationDelay,
    nativeStopGracePeriod: const Duration(milliseconds: 5),
  );
}

class FakeFlutterTts extends Fake implements FlutterTts {
  int speakCalls = 0;
  int stopCalls = 0;
  int awaitSpeakCompletionCalls = 0;
  bool throwOnStop = false;
  Completer<dynamic>? currentSpeakCompleter;
  String? lastSpokenText;

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async {
    awaitSpeakCompletionCalls += 1;
    return 1;
  }

  @override
  Future<dynamic> setLanguage(String language) async => 1;

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> setVolume(double volume) async => 1;

  @override
  Future<dynamic> setPitch(double pitch) async => 1;

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    speakCalls += 1;
    lastSpokenText = text;
    final completer = Completer<dynamic>();
    currentSpeakCompleter = completer;
    return completer.future;
  }

  @override
  Future<dynamic> stop() async {
    stopCalls += 1;
    if (throwOnStop) {
      throw Exception('Native TTS stop failure');
    }
    if (currentSpeakCompleter != null && !currentSpeakCompleter!.isCompleted) {
      currentSpeakCompleter!.complete(1);
    }
    return 1;
  }
}

class _SpyGlobalVoiceEngine with ChangeNotifier implements GlobalVoiceEngine {
  _SpyGlobalVoiceEngine();

  int startListeningCalls = 0;
  int stopSpeakingCalls = 0;
  int cancelListeningCalls = 0;

  @override
  VoiceAssistantPhase phase = VoiceAssistantPhase.completed;
  @override
  String transcript = '';
  @override
  String feedback = 'Miki siap.';
  @override
  bool nativeListening = false;
  @override
  bool isStarting = false;
  @override
  bool isAwaitingClarification = false;
  @override
  VoiceAssistantResult? latestResult;
  @override
  VoiceCommandExecutionResult? latestCommandExecution;

  @override
  Future<void> startListening({
    String? initialTranscript,
    bool wakeWordAlreadyDetected = false,
  }) async {
    startListeningCalls += 1;
    nativeListening = true;
    phase = VoiceAssistantPhase.listening;
    notifyListeners();
  }

  @override
  Future<void> cancelListening() async {
    cancelListeningCalls += 1;
    nativeListening = false;
    phase = VoiceAssistantPhase.completed;
    notifyListeners();
  }

  @override
  Future<void> stopSpeaking() async {
    stopSpeakingCalls += 1;
    notifyListeners();
  }

  @override
  Future<void> cancelPendingMutation({required String errorCode}) async {}

  @override
  Future<VoiceAssistantResult?> stopAndProcess({
    required VoiceParseContext parseContext,
    required bool speakResult,
  }) async {
    nativeListening = false;
    return null;
  }

  @override
  Future<void> speak(String text) async {}

  @override
  void clearTranscript() {
    transcript = '';
  }

  @override
  void prepareForClarification() {}
}
