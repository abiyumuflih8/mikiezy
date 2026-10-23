import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/models/business_query_data.dart';
import 'package:mikiezy/domain/models/business_query_result.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_command_executor.dart';
import 'package:mikiezy/services/voice/voice_conversation_context.dart';
import 'package:mikiezy/services/voice_assistant_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 7, 13, 18);

  test(
    'business query returns no transaction draft or preview result',
    () async {
      final controller = VoiceAssistantController(
        businessDataProvider: _data,
        clock: () => now,
      );
      addTearDown(controller.dispose);
      controller.setTranscript('Berapa omzet hari ini?');

      final result = await controller.processCurrentTranscript(
        speakResult: false,
      );

      expect(result, isNull);
      expect(controller.latestResult, isNull);
      expect(controller.latestCommandExecution?.handled, isTrue);
      expect(
        controller.latestCommandResponse?.businessResult?.metric,
        BusinessMetricType.revenue,
      );
      expect(controller.phase, VoiceAssistantPhase.completed);
    },
  );

  test(
    'same transcript is executed only once across duplicate callbacks',
    () async {
      var providerCalls = 0;
      final controller = VoiceAssistantController(
        businessDataProvider: () {
          providerCalls += 1;
          return _data();
        },
        clock: () => now,
      );
      addTearDown(controller.dispose);
      controller.setTranscript('Berapa keuntungan hari ini?');

      await controller.processCurrentTranscript(speakResult: false);
      await controller.processCurrentTranscript(speakResult: false);

      expect(providerCalls, 1);
      expect(controller.phase, VoiceAssistantPhase.completed);
      expect(controller.latestCommandResponse, isNotNull);
    },
  );

  test('TTS speaks the business response when enabled', () async {
    final spoken = <String>[];
    final controller = VoiceAssistantController(
      businessDataProvider: _data,
      clock: () => now,
      speakOverride: (text) async => spoken.add(text),
    );
    addTearDown(controller.dispose);
    controller.setTranscript('Berapa omzet hari ini?');

    await controller.processCurrentTranscript(speakResult: true);

    expect(spoken, hasLength(1));
    expect(spoken.single, contains('lima puluh ribu rupiah'));
  });

  test('TTS stays silent when disabled', () async {
    var speakCalls = 0;
    final controller = VoiceAssistantController(
      businessDataProvider: _data,
      clock: () => now,
      speakOverride: (text) async => speakCalls += 1,
    );
    addTearDown(controller.dispose);
    controller.ttsEnabled = false;
    controller.setTranscript('Berapa omzet hari ini?');

    await controller.processCurrentTranscript(speakResult: true);

    expect(speakCalls, 0);
    expect(controller.latestCommandResponse, isNotNull);
  });

  test('TTS failure does not discard a successful query response', () async {
    final controller = VoiceAssistantController(
      businessDataProvider: _data,
      clock: () => now,
      speakOverride: (text) async => throw StateError('tts unavailable'),
    );
    addTearDown(controller.dispose);
    controller.setTranscript('Berapa omzet hari ini?');

    await controller.processCurrentTranscript(speakResult: true);

    expect(
      controller.latestCommandResponse?.businessResult?.status,
      BusinessQueryStatus.success,
    );
    expect(controller.lastError, contains('tts unavailable'));
  });

  test('async response is ignored after controller is disposed', () async {
    final executor = _DelayedExecutor();
    final controller = VoiceAssistantController(
      commandExecutor: executor,
      businessDataProvider: _data,
      clock: () => now,
    );
    controller.setTranscript('Berapa omzet hari ini?');

    final processing = controller.processCurrentTranscript(speakResult: false);
    await executor.started.future;
    controller.dispose();
    executor.release.complete();
    await processing;

    expect(controller.latestCommandExecution, isNull);
  });

  test('clarification answer resumes the pending stock query', () async {
    final controller = VoiceAssistantController(
      businessDataProvider: _ambiguousData,
      clock: () => now,
    );
    addTearDown(controller.dispose);
    controller.setTranscript('Stok Aqua berapa?');

    await controller.processCurrentTranscript(speakResult: false);
    expect(controller.isAwaitingClarification, isTrue);
    expect(
      controller.latestCommandResponse?.businessResult?.status,
      BusinessQueryStatus.ambiguous,
    );

    controller.setTranscript('Yang 600 ml');
    final result = await controller.processCurrentTranscript(
      speakResult: false,
    );

    expect(result, isNull);
    expect(controller.latestResult, isNull);
    expect(controller.isAwaitingClarification, isFalse);
    expect(
      controller.latestCommandResponse?.businessResult?.productName,
      'Aqua 600 ml',
    );
  });

  test(
    'explicit new command replaces an active clarification context',
    () async {
      final controller = VoiceAssistantController(
        businessDataProvider: _ambiguousData,
        clock: () => now,
      );
      addTearDown(controller.dispose);
      controller.setTranscript('Stok Aqua berapa?');
      await controller.processCurrentTranscript(speakResult: false);

      controller.setTranscript('Berapa omzet hari ini?');
      await controller.processCurrentTranscript(speakResult: false);

      expect(controller.isAwaitingClarification, isFalse);
      expect(
        controller.latestCommandResponse?.businessResult?.metric,
        BusinessMetricType.revenue,
      );
    },
  );
}

class _DelayedExecutor extends VoiceCommandExecutor {
  final Completer<void> started = Completer<void>();
  final Completer<void> release = Completer<void>();

  @override
  Future<VoiceCommandExecutionResult> execute(
    VoiceCommand command, {
    VoiceConversationContext? context,
    bool confirmed = false,
    Map<VoiceCommandIntent, VoiceCommandHandler> runtimeHandlers = const {},
  }) async {
    started.complete();
    await release.future;
    return super.execute(
      command,
      context: context,
      confirmed: confirmed,
      runtimeHandlers: runtimeHandlers,
    );
  }
}

BusinessQueryData _data() {
  return BusinessQueryData(
    transactions: [
      TransactionRecord(
        id: 'sale',
        kind: TransactionKind.sale,
        createdAt: DateTime(2026, 7, 13, 9),
        walletId: 'wallet',
        walletName: 'Dompet Utama',
        categoryId: 'sales',
        categoryName: 'Penjualan',
        lines: const [
          TransactionLine(
            productId: 'coffee',
            productName: 'Kopi Susu',
            quantity: 2,
            unit: SaleUnit.gelas,
            unitPrice: 25000,
            costPrice: 10000,
            segment: PriceSegment.retail,
          ),
        ],
        amount: 50000,
        discount: 0,
        note: '',
        evidencePath: null,
        ocrSource: null,
        syncStatus: SyncStatus.localOnly,
      ),
    ],
  );
}

BusinessQueryData _ambiguousData() {
  final base = _data();
  return BusinessQueryData(
    transactions: base.transactions,
    products: const [
      Product(
        id: 'aqua-600',
        name: 'Aqua 600 ml',
        category: 'Minuman',
        costPrice: 2000,
        retailPrice: 4000,
        wholesalePrice: 3500,
        packSize: 12,
        cartonSize: 24,
        stockPcs: 24,
        baseUnit: SaleUnit.botol,
      ),
      Product(
        id: 'aqua-1500',
        name: 'Aqua 1,5 liter',
        category: 'Minuman',
        costPrice: 4000,
        retailPrice: 7000,
        wholesalePrice: 6500,
        packSize: 6,
        cartonSize: 12,
        stockPcs: 12,
        baseUnit: SaleUnit.botol,
      ),
    ],
  );
}
