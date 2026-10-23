import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/global_voice_controller.dart';
import 'package:mikiezy/services/voice/global_voice_engine.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';
import 'package:mikiezy/services/voice/voice_parse_context.dart';
import 'package:mikiezy/services/voice/voice_parse_result.dart';
import 'package:mikiezy/services/voice_assistant_controller.dart';

void main() {
  test(
    'one global controller keeps one engine and start/stop lifecycle',
    () async {
      final fixture = _fixture();
      addTearDown(fixture.controller.dispose);

      expect(fixture.controller.engineIdentity, same(fixture.engine));
      await fixture.controller.startPushToTalk();
      await fixture.controller.startPushToTalk();

      expect(fixture.pauseCalls, 1);
      expect(fixture.engine.startCalls, 1);
      expect(
        fixture.controller.sessionState,
        GlobalVoiceSessionState.listening,
      );

      await fixture.controller.stop();
      expect(fixture.engine.cancelCalls, greaterThan(0));
      expect(fixture.controller.sessionState, GlobalVoiceSessionState.stopped);

      await fixture.controller.close();
      expect(fixture.resumeCalls, 1);
      expect(fixture.controller.isOpen, isFalse);
    },
  );

  test(
    'background stops listening and foreground does not restart push-to-talk',
    () async {
      final fixture = _fixture();
      addTearDown(fixture.controller.dispose);
      await fixture.controller.startPushToTalk();

      fixture.controller.handleLifecycleState(AppLifecycleState.paused);
      await _flushAsync();
      expect(fixture.engine.nativeListening, isFalse);
      expect(fixture.controller.isOpen, isFalse);

      final starts = fixture.engine.startCalls;
      fixture.controller.handleLifecycleState(AppLifecycleState.resumed);
      await _flushAsync();
      expect(fixture.engine.startCalls, starts);
      expect(fixture.resumeCalls, 1);
    },
  );

  test('sensitive route stops an active session', () async {
    final fixture = _fixture();
    addTearDown(fixture.controller.dispose);
    await fixture.controller.startPushToTalk();

    fixture.controller.setSensitiveSurfaceVisible(true);
    await _flushAsync();

    expect(fixture.engine.nativeListening, isFalse);
    expect(fixture.controller.sessionState, GlobalVoiceSessionState.stopped);
    expect(fixture.controller.feedback, contains('dialog sensitif'));
  });

  test('locked app refuses microphone and sensitive business work', () async {
    var locked = true;
    final fixture = _fixture(isLocked: () => locked);
    addTearDown(fixture.controller.dispose);

    await fixture.controller.startPushToTalk();
    expect(fixture.engine.startCalls, 0);
    expect(fixture.controller.sessionState, GlobalVoiceSessionState.error);
    expect(fixture.controller.feedback, contains('terkunci'));

    locked = false;
    await fixture.controller.startPushToTalk();
    expect(fixture.engine.startCalls, 1);
  });

  test('STT is stopped before TTS to prevent feedback loop', () async {
    final fixture = _fixture();
    addTearDown(fixture.controller.dispose);
    fixture.engine.nextExecution = _execution(
      'berapa omzet hari ini',
      const VoiceCommandResponse(
        displayText: 'Omzet hari ini Rp100.000.',
        spokenText: 'Omzet hari ini seratus ribu rupiah.',
      ),
    );
    await fixture.controller.startPushToTalk();

    await fixture.controller.processCurrentSession();

    final cancelIndex = fixture.engine.events.lastIndexOf('cancel');
    final speakIndex = fixture.engine.events.lastIndexOf('speak');
    expect(cancelIndex, greaterThanOrEqualTo(0));
    expect(speakIndex, greaterThan(cancelIndex));
    expect(fixture.engine.nativeListening, isFalse);
    expect(fixture.controller.sessionState, GlobalVoiceSessionState.completed);
  });

  test(
    'conversation mode relistens only after clarification speech finishes',
    () async {
      final fixture = _fixture(
        conversationDelay: const Duration(milliseconds: 5),
      );
      addTearDown(fixture.controller.dispose);
      fixture.engine
        ..awaitingClarification = true
        ..nextExecution = _execution(
          'stok aqua berapa',
          const VoiceCommandResponse(
            displayText: 'Aqua yang mana?',
            kind: VoiceResponseKind.question,
          ),
        );
      fixture.controller.setConversationMode(true);
      await fixture.controller.startPushToTalk();

      await fixture.controller.processCurrentSession();
      expect(
        fixture.controller.sessionState,
        GlobalVoiceSessionState.waitingClarification,
      );
      final speakIndex = fixture.engine.events.lastIndexOf('speak');

      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(fixture.engine.startCalls, 2);
      expect(
        fixture.engine.events.lastIndexOf('start'),
        greaterThan(speakIndex),
      );
    },
  );

  test(
    'price preview waits for confirmation and background cancels the mutation',
    () async {
      final fixture = _fixture(
        conversationDelay: const Duration(milliseconds: 5),
      );
      addTearDown(fixture.controller.dispose);
      fixture.engine.nextExecution = _execution(
        'ubah harga kopi susu menjadi dua belas ribu',
        const VoiceCommandResponse(
          displayText: 'Harga jual Kopi Susu akan diubah menjadi Rp12.000.',
          spokenText:
              'Harga jual Kopi Susu akan diubah menjadi dua belas ribu rupiah.',
          kind: VoiceResponseKind.confirmation,
        ),
      );
      fixture.controller.setConversationMode(true);
      await fixture.controller.startPushToTalk();

      await fixture.controller.processCurrentSession();

      expect(
        fixture.controller.sessionState,
        GlobalVoiceSessionState.waitingConfirmation,
      );
      final speakIndex = fixture.engine.events.lastIndexOf('speak');
      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(
        fixture.engine.events.lastIndexOf('start'),
        greaterThan(speakIndex),
      );

      fixture.controller.handleLifecycleState(AppLifecycleState.paused);
      await _flushAsync();

      expect(fixture.engine.cancelPendingMutationCalls, 1);
      expect(fixture.controller.isOpen, isFalse);
      expect(fixture.engine.nativeListening, isFalse);
    },
  );

  test(
    'business query and navigation responses stay in the global overlay',
    () async {
      for (final scenario in [
        (
          transcript: 'berapa omzet hari ini',
          response: const VoiceCommandResponse(displayText: 'Omzet tersedia.'),
        ),
        (
          transcript: 'buka produk',
          response: const VoiceCommandResponse(displayText: 'Membuka produk.'),
        ),
      ]) {
        final fixture = _fixture();
        fixture.engine.nextExecution = _execution(
          scenario.transcript,
          scenario.response,
        );
        await fixture.controller.startPushToTalk();
        await fixture.controller.processCurrentSession();

        expect(fixture.controller.feedback, scenario.response.displayText);
        expect(fixture.controller.isOpen, isTrue);
        expect(fixture.previewedDrafts, isEmpty);
        fixture.controller.dispose();
      }
    },
  );

  test(
    'transaction opens preview and keeps wake word paused until preview closes',
    () async {
      final previewCompleter = Completer<void>();
      final fixture = _fixture(previewCompleter: previewCompleter);
      addTearDown(fixture.controller.dispose);
      fixture.engine.nextResult = _transactionResult();
      await fixture.controller.startPushToTalk();

      await fixture.controller.processCurrentSession();

      expect(fixture.previewedDrafts, hasLength(1));
      expect(fixture.controller.isOpen, isFalse);
      expect(fixture.resumeCalls, 0);

      previewCompleter.complete();
      await _flushAsync();
      expect(fixture.resumeCalls, 1);
    },
  );

  test('permission denial becomes visible error', () async {
    final fixture = _fixture();
    addTearDown(fixture.controller.dispose);
    fixture.engine.permissionDeniedOnStart = true;

    await fixture.controller.startPushToTalk();

    expect(fixture.controller.sessionState, GlobalVoiceSessionState.error);
    expect(fixture.controller.feedback, contains('Izin mikrofon'));
  });

  test('dispose cancels engine and pending timers', () async {
    final fixture = _fixture(silenceTimeout: const Duration(milliseconds: 5));
    await fixture.controller.startPushToTalk();
    fixture.engine.emitTranscript('jual kopi satu gelas');

    fixture.controller.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 15));

    expect(fixture.engine.disposeCalled, isTrue);
    expect(fixture.engine.processCalls, 0);
  });
}

_GlobalVoiceFixture _fixture({
  bool Function()? isLocked,
  Duration conversationDelay = const Duration(milliseconds: 20),
  Duration silenceTimeout = const Duration(seconds: 30),
  Completer<void>? previewCompleter,
}) {
  final engine = _FakeGlobalVoiceEngine();
  late _GlobalVoiceFixture fixture;
  final controller = GlobalVoiceController(
    sessionEngine: engine,
    buildParseContext: () => const VoiceParseContext(),
    previewCallback: (draft) {
      fixture.previewedDrafts.add(draft);
      return previewCompleter?.future ?? Future.value();
    },
    pauseWakeWordSession: () async => fixture.pauseCalls += 1,
    resumeWakeWordSession: () async => fixture.resumeCalls += 1,
    silenceTimeoutProvider: () => silenceTimeout,
    isAppLocked: isLocked,
    conversationRelistenDelay: conversationDelay,
    nativeStopGracePeriod: const Duration(milliseconds: 5),
  );
  fixture = _GlobalVoiceFixture(controller, engine);
  return fixture;
}

class _GlobalVoiceFixture {
  _GlobalVoiceFixture(this.controller, this.engine);

  final GlobalVoiceController controller;
  final _FakeGlobalVoiceEngine engine;
  final List<TransactionDraft> previewedDrafts = [];
  int pauseCalls = 0;
  int resumeCalls = 0;
}

class _FakeGlobalVoiceEngine extends ChangeNotifier
    implements GlobalVoiceEngine {
  @override
  VoiceAssistantPhase phase = VoiceAssistantPhase.listening;
  @override
  String transcript = '';
  @override
  String feedback = 'Miki siap.';
  @override
  bool nativeListening = false;
  @override
  bool isStarting = false;
  bool awaitingClarification = false;
  bool permissionDeniedOnStart = false;
  bool disposeCalled = false;
  int startCalls = 0;
  int cancelCalls = 0;
  int cancelPendingMutationCalls = 0;
  int processCalls = 0;
  VoiceAssistantResult? nextResult;
  VoiceCommandExecutionResult? nextExecution;
  final List<String> events = [];

  @override
  bool get isAwaitingClarification => awaitingClarification;

  @override
  VoiceAssistantResult? get latestResult => nextResult;

  @override
  VoiceCommandExecutionResult? get latestCommandExecution => nextExecution;

  @override
  Future<void> startListening({
    String? initialTranscript,
    bool wakeWordAlreadyDetected = false,
  }) async {
    startCalls += 1;
    events.add('start');
    transcript = initialTranscript ?? transcript;
    if (permissionDeniedOnStart) {
      nativeListening = false;
      phase = VoiceAssistantPhase.permissionDenied;
      feedback = 'Izin mikrofon belum aktif.';
    } else {
      nativeListening = true;
      phase = VoiceAssistantPhase.listening;
      feedback = 'Silakan bicara.';
    }
    notifyListeners();
  }

  @override
  Future<void> cancelListening() async {
    cancelCalls += 1;
    events.add('cancel');
    nativeListening = false;
    notifyListeners();
  }

  @override
  Future<void> cancelPendingMutation({required String errorCode}) async {
    cancelPendingMutationCalls += 1;
    events.add('cancel-mutation:$errorCode');
  }

  @override
  Future<VoiceAssistantResult?> stopAndProcess({
    required VoiceParseContext parseContext,
    required bool speakResult,
  }) async {
    processCalls += 1;
    events.add('process');
    nativeListening = false;
    phase = VoiceAssistantPhase.completed;
    if (nextExecution != null) feedback = nextExecution!.response.displayText;
    notifyListeners();
    return nextResult;
  }

  @override
  Future<void> speak(String text) async {
    events.add('speak');
  }

  @override
  void clearTranscript() {
    transcript = '';
  }

  @override
  void prepareForClarification() {
    transcript = '';
    phase = VoiceAssistantPhase.listening;
  }

  void emitTranscript(String value) {
    transcript = value;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeCalled = true;
    super.dispose();
  }
}

VoiceCommandExecutionResult _execution(
  String transcript,
  VoiceCommandResponse response,
) {
  return VoiceCommandExecutionResult(
    command: const VoiceCommandRouter().route(transcript),
    response: response,
    handled: true,
  );
}

VoiceAssistantResult _transactionResult() {
  const draft = TransactionDraft(
    kind: TransactionKind.sale,
    productName: 'Kopi',
    quantity: 1,
    unit: SaleUnit.gelas,
    unitPrice: 10000,
    discount: 0,
    categoryName: 'Penjualan',
    walletName: 'Tunai',
    segment: PriceSegment.retail,
    note: '',
    rawText: 'jual kopi satu gelas',
  );
  const parseResult = VoiceParseResult(
    rawText: 'jual kopi satu gelas',
    normalizedText: 'jual kopi satu gelas',
    kind: TransactionKind.sale,
    items: [],
    draft: draft,
  );
  return const VoiceAssistantResult(
    draft: draft,
    transcript: 'jual kopi satu gelas',
    feedback: 'Transaksi siap direview.',
    confidence: 0.9,
    parseResult: parseResult,
  );
}

Future<void> _flushAsync() => Future<void>.delayed(Duration.zero);
