import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/models/business_query_data.dart';
import 'package:mikiezy/domain/models/business_query_result.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/voice_business_conversation_handler.dart';
import 'package:mikiezy/services/voice/voice_business_query_handler.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';
import 'package:mikiezy/services/voice/voice_conversation_context.dart';

void main() {
  const router = VoiceCommandRouter();
  final now = DateTime(2026, 7, 13, 12);

  VoiceBusinessConversationHandler startProductQuery() {
    final handler = VoiceBusinessConversationHandler();
    final turn = handler.handleCommand(
      command: router.route('Stok Aqua berapa?'),
      data: _data(),
      now: now,
    );
    expect(turn.awaitingClarification, isTrue);
    expect(turn.response?.kind, VoiceResponseKind.question);
    return handler;
  }

  test('ambiguous product creates a type-safe temporary context', () {
    final handler = startProductQuery();
    final context = handler.session.current(now: now);

    expect(context?.clarificationType, VoiceClarificationType.productSelection);
    expect(context?.initialIntent, VoiceCommandIntent.queryProductStock);
    expect(context?.candidates, hasLength(3));
    expect(context?.isWaitingForAnswer, isTrue);
  });

  test('selects product by unique size without repeating the query', () {
    final handler = startProductQuery();
    final turn = handler.handleAnswer(
      transcript: 'Yang 600 ml',
      data: _data(),
      now: now.add(const Duration(seconds: 1)),
    );

    expect(turn.response?.businessResult?.productName, 'Aqua 600 ml');
    expect(turn.response?.businessResult?.quantity, 24);
    expect(handler.session.hasPending, isFalse);
  });

  test('selects spoken decimal size by candidate name', () {
    final handler = startProductQuery();
    final turn = handler.handleAnswer(
      transcript: 'Aqua satu setengah liter',
      data: _data(),
      now: now,
    );

    expect(turn.response?.businessResult?.productName, 'Aqua 1,5 liter');
  });

  test('supports first, number two, and last ordinal answers', () {
    final first = startProductQuery().handleAnswer(
      transcript: 'Yang pertama',
      data: _data(),
      now: now,
    );
    final second = startProductQuery().handleAnswer(
      transcript: 'Nomor dua',
      data: _data(),
      now: now,
    );
    final last = startProductQuery().handleAnswer(
      transcript: 'Yang terakhir',
      data: _data(),
      now: now,
    );

    expect(first.response?.businessResult?.productName, 'Aqua 600 ml');
    expect(second.response?.businessResult?.productName, 'Aqua 1,5 liter');
    expect(last.response?.businessResult?.productName, 'Aqua gelas');
  });

  test('invalid answers stop after the configured attempt limit', () {
    final handler = startProductQuery();

    for (var attempt = 0; attempt < 2; attempt++) {
      final turn = handler.handleAnswer(
        transcript: 'Entahlah',
        data: _data(),
        now: now.add(Duration(seconds: attempt)),
      );
      expect(turn.awaitingClarification, isTrue);
    }
    final last = handler.handleAnswer(
      transcript: 'Masih tidak tahu',
      data: _data(),
      now: now.add(const Duration(seconds: 2)),
    );

    expect(last.response?.kind, VoiceResponseKind.error);
    expect(handler.session.hasPending, isFalse);
  });

  test('expired context asks for the original command again', () {
    final handler = VoiceBusinessConversationHandler(
      session: VoiceConversationSession(timeout: const Duration(seconds: 1)),
    );
    handler.handleCommand(
      command: router.route('Stok Aqua berapa?'),
      data: _data(),
      now: now,
    );

    final turn = handler.handleAnswer(
      transcript: 'Yang pertama',
      data: _data(),
      now: now.add(const Duration(seconds: 2)),
    );

    expect(turn.response?.displayText, contains('kedaluwarsa'));
    expect(handler.session.hasPending, isFalse);
  });

  test('cancel clears context and repeat keeps it active', () {
    final repeatHandler = startProductQuery();
    final repeat = repeatHandler.handleAnswer(
      transcript: 'Ulangi pilihannya',
      data: _data(),
      now: now,
    );
    expect(repeat.awaitingClarification, isTrue);
    expect(repeat.response?.displayText, contains('1. Aqua 600 ml'));

    final cancel = repeatHandler.handleAnswer(
      transcript: 'Batal',
      data: _data(),
      now: now,
    );
    expect(cancel.response?.displayText, contains('dibatalkan'));
    expect(repeatHandler.session.hasPending, isFalse);
  });

  test('explicit new command cancels old context before routing', () {
    final handler = startProductQuery();
    final turn = handler.handleAnswer(
      transcript: 'Buka produk',
      data: _data(),
      now: now,
    );

    expect(turn.routeAsNewCommand, isTrue);
    expect(handler.session.hasPending, isFalse);
  });

  test('ambiguous wallet uses the same selection mechanism', () {
    final handler = VoiceBusinessConversationHandler();
    final initial = handler.handleCommand(
      command: router.route('Berapa saldo BCA?'),
      data: _data(),
      now: now,
    );
    expect(initial.awaitingClarification, isTrue);
    expect(
      handler.session.current(now: now)?.clarificationType,
      VoiceClarificationType.walletSelection,
    );

    final selected = handler.handleAnswer(
      transcript: 'BCA Operasional',
      data: _data(),
      now: now,
    );
    expect(selected.response?.businessResult?.walletName, 'BCA Operasional');
    expect(selected.response?.businessResult?.moneyValue, 250000);
  });

  test('initial query is evaluated once before clarification', () {
    final queryHandler = _CountingQueryHandler();
    final handler = VoiceBusinessConversationHandler(
      queryHandler: queryHandler,
    );
    handler.handleCommand(
      command: router.route('Stok Aqua berapa?'),
      data: _data(),
      now: now,
    );
    expect(queryHandler.queryCalls, 1);

    handler.handleAnswer(transcript: 'Yang pertama', data: _data(), now: now);
    expect(queryHandler.queryCalls, 2);
    expect(handler.session.hasPending, isFalse);
  });
}

class _CountingQueryHandler extends VoiceBusinessQueryHandler {
  int queryCalls = 0;

  @override
  BusinessQueryResult query({
    required VoiceCommand command,
    required BusinessQueryData data,
    required DateTime now,
  }) {
    queryCalls += 1;
    return super.query(command: command, data: data, now: now);
  }
}

BusinessQueryData _data() {
  return BusinessQueryData(
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
      Product(
        id: 'aqua-cup',
        name: 'Aqua gelas',
        category: 'Minuman',
        costPrice: 500,
        retailPrice: 1000,
        wholesalePrice: 800,
        packSize: 48,
        cartonSize: 48,
        stockPcs: 48,
        baseUnit: SaleUnit.gelas,
      ),
    ],
    wallets: const [
      Wallet(
        id: 'bca-main',
        name: 'BCA Utama',
        balance: 500000,
        isPrimary: true,
      ),
      Wallet(
        id: 'bca-ops',
        name: 'BCA Operasional',
        balance: 250000,
        isPrimary: false,
      ),
    ],
  );
}
