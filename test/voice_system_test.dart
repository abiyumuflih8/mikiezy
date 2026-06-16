import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/voice_parse_context.dart';
import 'package:mikiezy/services/voice_assistant_controller.dart';
import 'package:mikiezy/services/voice_transaction_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const voiceContext = VoiceParseContext(
    wallets: [
      Wallet(id: 'wal-main', name: 'Dompet Utama', balance: 0, isPrimary: true),
    ],
    categories: [
      LedgerCategory(
        id: 'cat-sales',
        name: 'Penjualan',
        direction: MoneyDirection.income,
        isSystem: true,
      ),
    ],
    defaultWalletName: 'Dompet Utama',
  );

  test('voice parser understands Indonesian expense amount words', () {
    final draft = VoiceTransactionParser().parse(
      'Catat pengeluaran bahan baku sebesar seratus delapan puluh ribu',
    );

    expect(draft.kind, TransactionKind.expense);
    expect(draft.categoryName, 'Bahan baku');
    expect(draft.unitPrice, 180000);
  });

  test('voice parser extracts sale quantity price and discount', () {
    final draft = VoiceTransactionParser().parse(
      'Miki, jual kopi susu 2 pcs harga dua belas ribu diskon dua ribu',
    );

    expect(draft.kind, TransactionKind.sale);
    expect(draft.productName, 'Kopi Susu');
    expect(draft.quantity, 2);
    expect(draft.unitPrice, 12000);
    expect(draft.discount, 2000);
    expect(draft.amount, 22000);
  });

  test('voice assistant creates feedback from current transcript', () async {
    final controller = VoiceAssistantController();
    addTearDown(controller.dispose);

    controller.setTranscript('Jual es teh 5 pcs harga lima ribu');
    final result = await controller.processCurrentTranscript(
      parseContext: voiceContext,
      speakResult: false,
    );

    expect(result, isNotNull);
    expect(result!.draft.productName, 'Es Teh');
    expect(result.draft.amount, 25000);
    expect(result.feedback, contains('Es Teh'));
  });

  test('voice assistant strips wake word before parsing', () async {
    final controller = VoiceAssistantController();
    addTearDown(controller.dispose);

    controller.setTranscript('Hai Miki, jual es teh 2 pcs harga lima ribu');
    final result = await controller.processCurrentTranscript(
      parseContext: voiceContext,
      speakResult: false,
    );

    expect(controller.wakeWordDetected, isTrue);
    expect(result, isNotNull);
    expect(result!.draft.productName, 'Es Teh');
    expect(result.draft.amount, 10000);
  });

  test('voice assistant keeps multi-item parser result in draft lines', () async {
    final controller = VoiceAssistantController();
    addTearDown(controller.dispose);

    controller.setTranscript(
      'Miki catat penjualan ayam bakar 10 bungkus Rp12.000 terus nasi goreng 5 bungkus Rp13.000 terus es teh 3 gelas Rp5.000',
    );
    final result = await controller.processCurrentTranscript(
      parseContext: voiceContext,
      speakResult: false,
    );

    expect(result, isNotNull);
    expect(result!.draft.lines, hasLength(3));
    expect(result.draft.lines.map((line) => line.productName), [
      'Ayam Bakar',
      'Nasi Goreng',
      'Es Teh',
    ]);
    expect(result.draft.amount, 200000);
  });
}
