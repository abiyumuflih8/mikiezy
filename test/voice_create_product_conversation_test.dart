import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';
import 'package:mikiezy/services/voice/voice_create_product_conversation.dart';

import 'support/phase6a_fixtures.dart';

void main() {
  const router = VoiceCommandRouter();
  final now = DateTime(2030, 1, 1, 10);

  test('clarifies price, stock tracking, then stock and unit', () {
    final conversation = VoiceCreateProductConversation();
    final first = conversation.start(
      command: router.route('Tambah produk kopi susu'),
      products: const [],
      now: now,
    );
    expect(first.response?.displayText, contains('harga jual'));

    final second = conversation.answer(
      transcript: 'sepuluh ribu',
      products: const [],
      now: now,
    );
    expect(second.response?.displayText, contains('perlu dilacak'));

    final third = conversation.answer(
      transcript: 'ya',
      products: const [],
      now: now,
    );
    expect(third.response?.displayText, contains('stok awal'));

    final completed = conversation.answer(
      transcript: 'dua puluh gelas',
      products: const [],
      now: now,
    );
    expect(completed.readyCommand?.entities.productName, 'kopi susu');
    expect(completed.readyCommand?.entities.salePrice, 10000);
    expect(completed.readyCommand?.entities.trackStock, isTrue);
    expect(completed.readyCommand?.entities.stock, 20);
    expect(completed.readyCommand?.entities.unit, SaleUnit.gelas.name);
    expect(conversation.hasPending, isFalse);
  });

  test('does not force stock fields when tracking is disabled', () {
    final conversation = VoiceCreateProductConversation();
    final first = conversation.start(
      command: router.route('Tambah produk jasa antar harga 5000'),
      products: const [],
      now: now,
    );
    expect(first.response?.displayText, contains('perlu dilacak'));

    final completed = conversation.answer(
      transcript: 'tidak perlu lacak stok',
      products: const [],
      now: now,
    );
    expect(completed.readyCommand?.entities.trackStock, isFalse);
    expect(completed.readyCommand?.entities.stock, isNull);
    expect(conversation.hasPending, isFalse);
  });

  test('full command reaches preview without extra clarification', () {
    final conversation = VoiceCreateProductConversation();
    final turn = conversation.start(
      command: router.route('Tambah produk teh tarik harga 9000 stok 12 gelas'),
      products: const [],
      now: now,
    );

    expect(turn.readyCommand, isNotNull);
    expect(conversation.hasPending, isFalse);
  });

  test('unknown unit keeps the context on stock clarification', () {
    final conversation = VoiceCreateProductConversation();
    conversation.start(
      command: router.route('Tambah produk teh tarik harga 9000 lacak stok'),
      products: const [],
      now: now,
    );

    final invalid = conversation.answer(
      transcript: 'dua puluh wadahajaib',
      products: const [],
      now: now,
    );

    expect(invalid.readyCommand, isNull);
    expect(invalid.response?.displayText, contains('beserta satuannya'));
    expect(conversation.hasPending, isTrue);
  });

  test('learned unit alias is accepted during clarification', () {
    final alias = VoiceUnitAlias(
      id: 'unit-sloki',
      aliasText: 'sloki',
      normalizedAlias: 'sloki',
      canonicalUnit: SaleUnit.gelas.name,
      createdAt: now,
      updatedAt: now,
    );
    final conversation = VoiceCreateProductConversation();
    conversation.start(
      command: router.route('Tambah produk es buah harga 8000 lacak stok'),
      products: const [],
      unitAliases: [alias],
      now: now,
    );

    final completed = conversation.answer(
      transcript: 'setengah sloki',
      products: const [],
      unitAliases: [alias],
      now: now,
    );

    expect(completed.readyCommand?.entities.stock, 0.5);
    expect(completed.readyCommand?.entities.unit, SaleUnit.gelas.name);
  });

  test('cancel clears pending context', () {
    final conversation = VoiceCreateProductConversation();
    conversation.start(
      command: router.route('Tambah produk kopi susu'),
      products: const [],
      now: now,
    );

    final cancelled = conversation.answer(
      transcript: 'batal',
      products: const [],
      now: now,
    );

    expect(cancelled.response?.displayText, contains('dibatalkan'));
    expect(conversation.hasPending, isFalse);
  });

  test('expired context is rejected and cleared', () {
    final conversation = VoiceCreateProductConversation(
      expiration: const Duration(seconds: 30),
    );
    conversation.start(
      command: router.route('Tambah produk kopi susu'),
      products: const [],
      now: now,
    );

    final expired = conversation.answer(
      transcript: 'sepuluh ribu',
      products: const [],
      now: now.add(const Duration(seconds: 30)),
    );

    expect(expired.response?.displayText, contains('kedaluwarsa'));
    expect(conversation.hasPending, isFalse);
  });

  test('maximum invalid attempts cancels the unsafe draft', () {
    final conversation = VoiceCreateProductConversation(
      maximumInvalidAttempts: 2,
    );
    conversation.start(
      command: router.route('Tambah produk kopi susu'),
      products: const [],
      now: now,
    );

    conversation.answer(transcript: 'tidak tahu', products: const [], now: now);
    final terminal = conversation.answer(
      transcript: 'entahlah',
      products: const [],
      now: now,
    );

    expect(terminal.response?.displayText, contains('dibatalkan'));
    expect(conversation.hasPending, isFalse);
  });

  test('a new command cancels the old context without consuming it', () {
    final conversation = VoiceCreateProductConversation();
    conversation.start(
      command: router.route('Tambah produk kopi susu'),
      products: const [],
      now: now,
    );

    final turn = conversation.answer(
      transcript: 'buka laporan',
      products: const [],
      now: now,
      looksLikeNewCommand: true,
    );

    expect(turn.routeAsNewCommand, isTrue);
    expect(conversation.hasPending, isFalse);
  });

  test('repeat and edit controls target only the requested field', () {
    final conversation = VoiceCreateProductConversation();
    conversation.start(
      command: router.route('Tambah produk kopi susu'),
      products: const [],
      now: now,
    );

    final repeated = conversation.answer(
      transcript: 'ulangi',
      products: const [],
      now: now,
    );
    expect(repeated.response?.displayText, contains('harga jual'));

    final editPrice = conversation.answer(
      transcript: 'ubah harga',
      products: const [],
      now: now,
      looksLikeNewCommand: true,
    );
    expect(editPrice.response?.displayText, contains('harga jual yang baru'));
  });

  test('exact duplicate is blocked without changing the existing product', () {
    final existing = phase6aProduct();
    final conversation = VoiceCreateProductConversation();
    final turn = conversation.start(
      command: router.route('Tambah produk kopi susu harga 10000 tanpa stok'),
      products: [existing],
      now: now,
    );

    expect(turn.readyCommand, isNull);
    expect(turn.rejectedCommand, isNotNull);
    expect(turn.response?.displayText, contains('sudah tersedia'));
    expect(existing.retailPrice, 10000);
    expect(conversation.hasPending, isFalse);
  });

  test('similar product requires an explicit extra confirmation', () {
    final conversation = VoiceCreateProductConversation();
    final turn = conversation.start(
      command: router.route('Tambah produk kopi susu harga 10000 tanpa stok'),
      products: [phase6aProduct(name: 'Kopi Susu Original')],
      now: now,
    );
    expect(turn.response?.displayText, contains('mirip'));

    final completed = conversation.answer(
      transcript: 'ya tetap buat',
      products: [phase6aProduct(name: 'Kopi Susu Original')],
      now: now,
    );

    expect(completed.readyCommand?.entities.similarProductConfirmed, isTrue);
    expect(
      completed.readyCommand?.entities.similarProductName,
      'Kopi Susu Original',
    );
    expect(conversation.hasPending, isFalse);
  });
}
