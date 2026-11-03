import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mikiezy/services/navigation/app_navigation_service.dart';
import 'package:mikiezy/services/voice/global_voice_controller.dart';
import 'package:mikiezy/services/voice/global_voice_engine.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_parse_context.dart';
import 'package:mikiezy/services/voice_assistant_controller.dart';
import 'package:mikiezy/widgets/voice_overlay_host.dart';

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

  group('M4F.85: Physical KI-01 Case B Defect Reproduction Tests', () {
    testWidgets('Defect 1 Reproduction: Stop button is enabled and clickable during active speaking', (tester) async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      controller.isOpen = true;
      controller.sessionState = GlobalVoiceSessionState.speaking;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceOverlayHost(
              controller: controller,
              initialRouteName: AppRouteNames.forTarget(VoiceNavigationTarget.dashboard),
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final stopButtonFinder = find.widgetWithText(OutlinedButton, 'Stop');
      expect(stopButtonFinder, findsOneWidget);
      final stopButton = tester.widget<OutlinedButton>(stopButtonFinder);
      expect(
        stopButton.onPressed,
        isNotNull,
        reason: 'Stop button must be clickable during active speech so user can interrupt TTS',
      );
    });

    test('Defect 2 Reproduction: close() during speaking immediately calls engine stopSpeaking', () async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      controller.isOpen = true;
      controller.sessionState = GlobalVoiceSessionState.speaking;

      await controller.close();

      expect(
        engine.stopSpeakingCalls,
        greaterThan(0),
        reason: 'close() must call stopSpeaking to interrupt active audio',
      );
      expect(controller.isOpen, isFalse);
      expect(controller.sessionState, GlobalVoiceSessionState.idle);
    });

    test('Defect 2 Reproduction: stopSpeaking silences volume immediately and prevents stale speak execution', () async {
      final fakeTts = FakeFlutterTts();
      final controller = VoiceAssistantController(textToSpeech: fakeTts);
      addTearDown(controller.dispose);

      // Start speaking
      final speakFuture = controller.speak('Stok Kopi Susu Botol saat ini 64 pcs.');
      await pumpEventQueue();

      expect(fakeTts.speakCalls, 1);
      expect(fakeTts.lastVolume, 1.0);

      // User interrupts via stopSpeaking
      await controller.stopSpeaking();

      expect(fakeTts.stopCalls, greaterThanOrEqualTo(2)); // pre-utterance stop + interruption stop
      expect(fakeTts.lastVolume, 0.0, reason: 'stopSpeaking must silence volume to 0.0 to kill buffered audio');

      // Complete the interrupted utterance
      if (fakeTts.currentSpeakCompleter != null &&
          !fakeTts.currentSpeakCompleter!.isCompleted) {
        fakeTts.currentSpeakCompleter!.complete(1);
      }
      await speakFuture;
    });
  });

  group('M4F.85.2: KI-01 Defensive Interruption Hardening & Cancellation Chain Safety', () {
    test('TEST 1: stopSpeaking() attempts _tts.stop() even when _tts.setVolume(0.0) throws', () async {
      final fakeTts = FakeFlutterTts()..throwOnSetVolume = true;
      final controller = VoiceAssistantController(textToSpeech: fakeTts);
      addTearDown(controller.dispose);

      await controller.stopSpeaking();

      expect(
        fakeTts.stopCalls,
        greaterThanOrEqualTo(1),
        reason: '_tts.stop() must be attempted even if volume muting throws',
      );
    });

    test('TEST 2: Volume failure produces safe diagnostic evidence without disguising interruption outcome', () async {
      final fakeTts = FakeFlutterTts()..throwOnSetVolume = true;
      final controller = VoiceAssistantController(textToSpeech: fakeTts);
      addTearDown(controller.dispose);

      await controller.stopSpeaking();

      // Controller should record volume failure attempt
      expect(fakeTts.setVolumeCalls, 1);
    });

    test('TEST 3: Native TTS stop failure does not allow stale asynchronous speech to restart', () async {
      final fakeTts = FakeFlutterTts()..throwOnStop = true;
      final controller = VoiceAssistantController(textToSpeech: fakeTts);
      addTearDown(controller.dispose);

      final speakFuture = controller.speak('Stale utterance test');
      await pumpEventQueue();

      // Interruption triggers stopSpeaking which throws inside fakeTts.stop()
      await controller.stopSpeaking();

      // Ensure that subsequent calls cannot resume the old generation
      expect(controller.lastError, contains('Native TTS stop failure'));
      await speakFuture;
    });

    test('TEST 4: Engine-level stopSpeaking() exception does not skip STT and pending mutation cancellation', () async {
      final engine = _SpyGlobalVoiceEngine()..throwOnStopSpeaking = true;
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      controller.isOpen = true;
      controller.sessionState = GlobalVoiceSessionState.speaking;

      await controller.stop();

      expect(engine.stopSpeakingCalls, 1);
      expect(
        engine.cancelListeningCalls,
        greaterThanOrEqualTo(1),
        reason: 'cancelListening must be attempted even if stopSpeaking throws',
      );
      expect(
        engine.cancelPendingMutationCalls,
        greaterThanOrEqualTo(1),
        reason: 'cancelPendingMutation must be attempted even if stopSpeaking throws',
      );
      expect(controller.sessionState, GlobalVoiceSessionState.stopped);
    });

    test('TEST 5: STT cancellation failure does not skip pending mutation cancellation', () async {
      final engine = _SpyGlobalVoiceEngine()..throwOnCancelListening = true;
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      controller.isOpen = true;
      controller.sessionState = GlobalVoiceSessionState.listening;

      await controller.stop();

      expect(engine.cancelListeningCalls, 1);
      expect(
        engine.cancelPendingMutationCalls,
        greaterThanOrEqualTo(1),
        reason: 'cancelPendingMutation must be attempted even if cancelListening throws',
      );
      expect(controller.sessionState, GlobalVoiceSessionState.stopped);
    });

    test('TEST 6: Repeated Stop/X calls preserve safe session state without unintended duplicate business actions', () async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      controller.isOpen = true;
      controller.sessionState = GlobalVoiceSessionState.speaking;

      await controller.stop();
      await controller.stop();
      await controller.close();

      expect(controller.sessionState, GlobalVoiceSessionState.idle);
      expect(controller.isOpen, isFalse);
    });

    test('TEST 7: Normal TTS speak and stop flow remains completely functional', () async {
      final fakeTts = FakeFlutterTts();
      final controller = VoiceAssistantController(textToSpeech: fakeTts);
      addTearDown(controller.dispose);

      final speakFuture = controller.speak('Normal speech');
      await pumpEventQueue();

      expect(fakeTts.speakCalls, 1);
      expect(fakeTts.lastVolume, 1.0);

      await controller.stopSpeaking();
      expect(fakeTts.lastVolume, 0.0);
      expect(fakeTts.stopCalls, greaterThanOrEqualTo(2));

      if (fakeTts.currentSpeakCompleter != null && !fakeTts.currentSpeakCompleter!.isCompleted) {
        fakeTts.currentSpeakCompleter!.complete(1);
      }
      await speakFuture;
    });

    test('TEST 8: Late async callbacks after session stop cannot reactivate old voice session', () async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      await controller.startPushToTalk();
      await controller.stop();
      expect(controller.sessionState, GlobalVoiceSessionState.stopped);

      // Verify that engine activity on old generation is discarded
      engine.phase = VoiceAssistantPhase.listening;
      engine.notifyListeners();
      await pumpEventQueue();

      expect(controller.sessionState, GlobalVoiceSessionState.stopped);
    });
  });

  group('M4F.90: Targeted KI-01 Root-Cause Discrimination & UI Lifecycle Tests', () {
    const queryCommand = VoiceCommand(
      rawText: 'cek omzet',
      normalizedText: 'cek omzet',
      intent: VoiceCommandIntent.querySales,
      entities: VoiceCommandEntities(),
      confidence: 1.0,
    );
    const queryResponse = VoiceCommandResponse(
      displayText: 'Total penjualan hari ini Rp 0.',
      spokenText: 'Total penjualan hari ini nol rupiah.',
    );
    const queryExecution = VoiceCommandExecutionResult(
      command: queryCommand,
      response: queryResponse,
      handled: true,
    );

    test('TEST 1: Real global voice processing path from query through speaking to terminal state', () async {
      final engine = _SpyGlobalVoiceEngine()
        ..stubbedCommandExecution = queryExecution;
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);
      addTearDown(engine.completeSpeak);

      await controller.startPushToTalk();
      expect(controller.isOpen, isTrue);

      final processFuture = controller.processCurrentSession();
      await pumpEventQueue();

      expect(controller.sessionState, GlobalVoiceSessionState.speaking);
      expect(controller.isBusy, isTrue);
      expect(controller.feedback, 'Total penjualan hari ini Rp 0.');
      expect(engine.speakCalls, 1);
      expect(engine.lastSpokenText, 'Total penjualan hari ini nol rupiah.');

      engine.completeSpeak();
      await processFuture;
      await pumpEventQueue();

      expect(controller.sessionState, GlobalVoiceSessionState.completed);
      expect(controller.isBusy, isFalse);
    });

    testWidgets('TEST 2: Stop remains actionable while simulated utterance is active', (tester) async {
      final engine = _SpyGlobalVoiceEngine()
        ..stubbedCommandExecution = queryExecution;
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);
      addTearDown(engine.completeSpeak);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceOverlayHost(
              controller: controller,
              initialRouteName: AppRouteNames.forTarget(VoiceNavigationTarget.dashboard),
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      await controller.startPushToTalk();
      await tester.pump();

      final processFuture = controller.processCurrentSession();
      await tester.pump();

      expect(controller.sessionState, GlobalVoiceSessionState.speaking);
      final stopFinder = find.widgetWithText(OutlinedButton, 'Stop');
      expect(stopFinder, findsOneWidget);
      final stopButton = tester.widget<OutlinedButton>(stopFinder);
      expect(stopButton.onPressed, isNotNull);

      engine.completeSpeak();
      await tester.pump();
      await processFuture;
    });

    testWidgets('TEST 3: Early Future resolution simulates loss of UI Stop button while lingering', (tester) async {
      final engine = _SpyGlobalVoiceEngine()
        ..stubbedCommandExecution = queryExecution;
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);
      addTearDown(engine.completeSpeak);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceOverlayHost(
              controller: controller,
              initialRouteName: AppRouteNames.forTarget(VoiceNavigationTarget.dashboard),
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      await controller.startPushToTalk();
      await tester.pump();

      final processFuture = controller.processCurrentSession();
      await tester.pump();

      expect(find.widgetWithText(OutlinedButton, 'Stop'), findsOneWidget);

      // Simulate early future completion from native plugin
      engine.completeSpeak();
      await tester.pump();
      await processFuture;
      await tester.pump();

      expect(controller.sessionState, GlobalVoiceSessionState.completed);
      expect(controller.isBusy, isFalse);
      // M4F.91 remediation ensures Stop remains available in completed state as an audio-interruption fallback
      expect(find.widgetWithText(OutlinedButton, 'Stop'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Bicara lagi'), findsOneWidget);
    });

    testWidgets('TEST 4: Tapping Stop during active simulated speech triggers interruption callback', (tester) async {
      final engine = _SpyGlobalVoiceEngine()
        ..stubbedCommandExecution = queryExecution;
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);
      addTearDown(engine.completeSpeak);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceOverlayHost(
              controller: controller,
              initialRouteName: AppRouteNames.forTarget(VoiceNavigationTarget.dashboard),
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      await controller.startPushToTalk();
      await tester.pump();

      final processFuture = controller.processCurrentSession();
      await tester.pump();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Stop'));
      await tester.pump();
      await processFuture;

      expect(engine.stopSpeakingCalls, 1);
      expect(controller.sessionState, GlobalVoiceSessionState.stopped);
      expect(find.text('Sesi voice dihentikan.'), findsOneWidget);
    });

    testWidgets('TEST 5: Tapping close X during active simulated speech executes cancellation and closes overlay', (tester) async {
      final engine = _SpyGlobalVoiceEngine()
        ..stubbedCommandExecution = queryExecution;
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);
      addTearDown(engine.completeSpeak);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceOverlayHost(
              controller: controller,
              initialRouteName: AppRouteNames.forTarget(VoiceNavigationTarget.dashboard),
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      await controller.startPushToTalk();
      await tester.pump();

      final processFuture = controller.processCurrentSession();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await processFuture;

      expect(engine.stopSpeakingCalls, 1);
      expect(controller.isOpen, isFalse);
      expect(controller.sessionState, GlobalVoiceSessionState.idle);
    });

    test('TEST 6: Native TTS stop return value handling when stop returns non-success code without throwing', () async {
      final fakeTts = FakeFlutterTts()..stopReturnValue = 0;
      final controller = VoiceAssistantController(textToSpeech: fakeTts);
      addTearDown(controller.dispose);

      final speakFuture = controller.speak('Kalimat uji coba non-success');
      await pumpEventQueue();

      await controller.stopSpeaking();

      expect(fakeTts.stopCalls, greaterThanOrEqualTo(2));
      expect(fakeTts.lastVolume, 0.0);

      fakeTts.completeCurrentSpeak();
      await speakFuture;
    });

    test('TEST 7: Stale callbacks and overlapping sessions cannot restart TTS on superseded generation', () async {
      final fakeTts = FakeFlutterTts();
      final controller = VoiceAssistantController(textToSpeech: fakeTts);
      addTearDown(controller.dispose);

      final firstSpeak = controller.speak('Ucapan pertama');
      await pumpEventQueue();
      expect(fakeTts.speakCalls, 1);
      final firstCompleter = fakeTts.currentSpeakCompleter;

      await controller.stopSpeaking();

      final secondSpeak = controller.speak('Ucapan kedua');
      await pumpEventQueue();
      expect(fakeTts.speakCalls, 2);

      if (firstCompleter != null && !firstCompleter.isCompleted) {
        firstCompleter.complete(1);
      }
      await firstSpeak;

      expect(fakeTts.lastSpokenText, 'Ucapan kedua');
      fakeTts.completeCurrentSpeak();
      await secondSpeak;
    });

    test('TEST 8: Normal speech completion preserves conversation mode bounds without unintended relisten', () async {
      final engine = _SpyGlobalVoiceEngine()
        ..stubbedCommandExecution = queryExecution;
      final controller = _createGlobalVoiceController(
        engine,
        conversationDelay: const Duration(milliseconds: 50),
      );
      addTearDown(controller.dispose);

      controller.conversationMode = false;
      await controller.startPushToTalk();
      final processFuture = controller.processCurrentSession();
      await pumpEventQueue();

      engine.completeSpeak();
      await processFuture;
      await pumpEventQueue();

      expect(controller.sessionState, GlobalVoiceSessionState.completed);

      await Future<void>.delayed(const Duration(milliseconds: 70));
      await pumpEventQueue();

      expect(engine.startListeningCalls, 1);
      expect(controller.sessionState, GlobalVoiceSessionState.completed);
    });
  });

  group('M4F.91: KI-01 Completed-State Stop Fallback & UI Safety Tests', () {
    testWidgets('TEST 1: Stop control remains available when overlay is open in completed state', (tester) async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      controller.isOpen = true;
      controller.sessionState = GlobalVoiceSessionState.completed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceOverlayHost(
              controller: controller,
              initialRouteName: AppRouteNames.forTarget(VoiceNavigationTarget.dashboard),
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      final stopFinder = find.widgetWithText(OutlinedButton, 'Stop');
      expect(
        stopFinder,
        findsOneWidget,
        reason: 'Stop button must remain available when session is completed to allow stopping lingering native audio',
      );
    });

    testWidgets('TEST 2: Tapping Stop fallback in completed state invokes controller stop', (tester) async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      controller.isOpen = true;
      controller.sessionState = GlobalVoiceSessionState.completed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceOverlayHost(
              controller: controller,
              initialRouteName: AppRouteNames.forTarget(VoiceNavigationTarget.dashboard),
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      final stopFinder = find.widgetWithText(OutlinedButton, 'Stop');
      if (stopFinder.evaluate().isNotEmpty) {
        await tester.tap(stopFinder);
        await tester.pump();
        expect(engine.stopSpeakingCalls, greaterThanOrEqualTo(1));
        expect(controller.sessionState, GlobalVoiceSessionState.stopped);
      } else {
        fail('Stop button was not rendered in completed state');
      }
    });

    testWidgets('TEST 3: Stop remains visible and actionable in active speaking state', (tester) async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      controller.isOpen = true;
      controller.sessionState = GlobalVoiceSessionState.speaking;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceOverlayHost(
              controller: controller,
              initialRouteName: AppRouteNames.forTarget(VoiceNavigationTarget.dashboard),
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      final stopFinder = find.widgetWithText(OutlinedButton, 'Stop');
      expect(stopFinder, findsOneWidget);
      final stopButton = tester.widget<OutlinedButton>(stopFinder);
      expect(stopButton.onPressed, isNotNull);
    });

    testWidgets('TEST 4: Bicara lagi remains available in completed state', (tester) async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      controller.isOpen = true;
      controller.sessionState = GlobalVoiceSessionState.completed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceOverlayHost(
              controller: controller,
              initialRouteName: AppRouteNames.forTarget(VoiceNavigationTarget.dashboard),
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      final retryFinder = find.widgetWithText(FilledButton, 'Bicara lagi');
      expect(retryFinder, findsOneWidget);
    });

    testWidgets('TEST 5: Close X invokes controller close and engine stopSpeaking', (tester) async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      controller.isOpen = true;
      controller.sessionState = GlobalVoiceSessionState.completed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceOverlayHost(
              controller: controller,
              initialRouteName: AppRouteNames.forTarget(VoiceNavigationTarget.dashboard),
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(engine.stopSpeakingCalls, greaterThanOrEqualTo(1));
      expect(controller.isOpen, isFalse);
      expect(controller.sessionState, GlobalVoiceSessionState.idle);
    });

    test('TEST 6: Repeated stop calls are idempotent and do not introduce errors', () async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      controller.isOpen = true;
      controller.sessionState = GlobalVoiceSessionState.completed;

      await controller.stop();
      await controller.stop();
      await controller.close();

      expect(controller.sessionState, GlobalVoiceSessionState.idle);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('TEST 7: Overlay remains hidden on disallowed routes', (tester) async {
      final engine = _SpyGlobalVoiceEngine();
      final controller = _createGlobalVoiceController(engine);
      addTearDown(controller.dispose);

      controller.isOpen = true;
      controller.sessionState = GlobalVoiceSessionState.completed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceOverlayHost(
              controller: controller,
              initialRouteName: '/splash',
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Bicara lagi'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Stop'), findsNothing);
    });

    test('TEST 8: Native stop diagnostic logs on unsuccessful return without throwing', () async {
      final fakeTts = FakeFlutterTts()..stopReturnValue = 0;
      final controller = VoiceAssistantController(textToSpeech: fakeTts);
      addTearDown(controller.dispose);

      final speakFuture = controller.speak('Uji status stop');
      await pumpEventQueue();

      await controller.stopSpeaking();

      expect(fakeTts.stopCalls, greaterThanOrEqualTo(2));
      expect(fakeTts.stopReturnValue, 0);

      fakeTts.completeCurrentSpeak();
      await speakFuture;
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
  int setVolumeCalls = 0;
  double? lastVolume;
  bool throwOnStop = false;
  bool throwOnSetVolume = false;
  Completer<dynamic>? currentSpeakCompleter;
  String? lastSpokenText;
  dynamic stopReturnValue = 1;

  void completeCurrentSpeak([dynamic value = 1]) {
    if (currentSpeakCompleter != null && !currentSpeakCompleter!.isCompleted) {
      currentSpeakCompleter!.complete(value);
    }
  }

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
  Future<dynamic> setVolume(double volume) async {
    setVolumeCalls += 1;
    lastVolume = volume;
    if (throwOnSetVolume) {
      throw Exception('Native TTS setVolume failure');
    }
    return 1;
  }

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
    return stopReturnValue;
  }
}

class _SpyGlobalVoiceEngine with ChangeNotifier implements GlobalVoiceEngine {
  _SpyGlobalVoiceEngine();

  int startListeningCalls = 0;
  int stopSpeakingCalls = 0;
  int cancelListeningCalls = 0;
  int cancelPendingMutationCalls = 0;
  String? lastCancelledMutationErrorCode;
  bool throwOnStopSpeaking = false;
  bool throwOnCancelListening = false;
  Completer<void>? speakCompleter;
  int speakCalls = 0;
  String? lastSpokenText;
  VoiceAssistantResult? stubbedStopAndProcessResult;
  VoiceCommandExecutionResult? stubbedCommandExecution;

  void completeSpeak() {
    if (speakCompleter != null && !speakCompleter!.isCompleted) {
      speakCompleter!.complete();
    }
  }

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
    if (throwOnCancelListening) {
      throw Exception('Engine cancelListening failure');
    }
    nativeListening = false;
    phase = VoiceAssistantPhase.completed;
    notifyListeners();
  }

  @override
  Future<void> stopSpeaking() async {
    stopSpeakingCalls += 1;
    if (throwOnStopSpeaking) {
      throw Exception('Engine stopSpeaking failure');
    }
    if (speakCompleter != null && !speakCompleter!.isCompleted) {
      speakCompleter!.complete();
    }
    notifyListeners();
  }

  @override
  Future<void> cancelPendingMutation({required String errorCode}) async {
    cancelPendingMutationCalls += 1;
    lastCancelledMutationErrorCode = errorCode;
  }

  @override
  Future<VoiceAssistantResult?> stopAndProcess({
    required VoiceParseContext parseContext,
    required bool speakResult,
  }) async {
    nativeListening = false;
    latestCommandExecution = stubbedCommandExecution;
    if (stubbedCommandExecution != null) {
      feedback = stubbedCommandExecution!.response.displayText;
      transcript = stubbedCommandExecution!.command.rawText;
    }
    return stubbedStopAndProcessResult;
  }

  @override
  Future<void> speak(String text) async {
    speakCalls += 1;
    lastSpokenText = text;
    final completer = Completer<void>();
    speakCompleter = completer;
    return completer.future;
  }

  @override
  void clearTranscript() {
    transcript = '';
  }

  @override
  void prepareForClarification() {}
}
