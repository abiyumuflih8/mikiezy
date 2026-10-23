import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/models/product_price.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';
import 'package:mikiezy/services/voice/voice_price_update_conversation.dart';

import 'support/phase6c_fixtures.dart';

void main() {
  const router = VoiceCommandRouter();
  final now = DateTime(2030, 1, 1, 10);
  final coffee = phase6cProduct();

  test('complete command becomes ready and clears context', () {
    final conversation = VoicePriceUpdateConversation();
    final turn = conversation.start(
      command: router.route('Ubah harga kopi susu menjadi dua belas ribu'),
      products: [coffee],
      now: now,
    );

    expect(turn.readyCommand, isNotNull);
    expect(
      turn.readyCommand!.entities.productPriceType,
      ProductPriceType.retail,
    );
    expect(turn.readyCommand!.entities.newProductPrice, 12000);
    expect(conversation.hasPending, isFalse);
  });

  test('asks for a missing product', () {
    final conversation = VoicePriceUpdateConversation();
    final turn = conversation.start(
      command: router.route('Ubah harga menjadi 12000'),
      products: [coffee],
      now: now,
    );

    expect(turn.response?.displayText, contains('Produk mana'));
    expect(conversation.hasPending, isTrue);
  });

  test('asks for a missing new price without using model number', () {
    final aqua = phase6cProduct(name: 'Aqua 600 ml');
    final conversation = VoicePriceUpdateConversation();
    final turn = conversation.start(
      command: router.route('Ubah harga Aqua 600 ml'),
      products: [aqua],
      now: now,
    );

    expect(turn.response?.displayText, contains('Berapa harga jual baru'));
    expect(conversation.hasPending, isTrue);
  });

  test('asks for price type when no safe default was extracted', () {
    final conversation = VoicePriceUpdateConversation();
    final turn = conversation.start(
      command: _command(
        productName: coffee.name,
        productId: coffee.id,
        newPrice: 12000,
      ),
      products: [coffee],
      now: now,
    );

    expect(turn.response?.displayText, contains('harga jual'));
    expect(turn.response?.displayText, contains('harga grosir'));
    expect(turn.response?.displayText, contains('harga modal'));
  });

  test('ambiguous product asks candidate selection', () {
    final conversation = VoicePriceUpdateConversation();
    final products = [
      phase6cProduct(id: 'aqua-600', name: 'Aqua 600 ml'),
      phase6cProduct(id: 'aqua-1500', name: 'Aqua 1,5 liter'),
    ];

    final turn = conversation.start(
      command: router.route('Ubah harga Aqua menjadi 5000'),
      products: products,
      now: now,
    );

    expect(turn.response?.displayText, contains('Aqua 600 ml'));
    expect(turn.response?.displayText, contains('Aqua 1,5 liter'));
    expect(conversation.hasPending, isTrue);
  });

  test('candidate selection resumes the original command', () {
    final conversation = VoicePriceUpdateConversation();
    final products = [
      phase6cProduct(id: 'aqua-600', name: 'Aqua 600 ml'),
      phase6cProduct(id: 'aqua-1500', name: 'Aqua 1,5 liter'),
    ];
    conversation.start(
      command: router.route('Ubah harga Aqua menjadi 5000'),
      products: products,
      now: now,
    );

    final turn = conversation.answer(
      transcript: 'Yang 600 ml',
      products: products,
      now: now.add(const Duration(seconds: 5)),
    );

    expect(turn.readyCommand?.entities.productId, 'aqua-600');
    expect(turn.readyCommand?.entities.newProductPrice, 5000);
    expect(turn.readyCommand?.entities.clarificationOccurred, isTrue);
    expect(conversation.hasPending, isFalse);
  });

  test('learned alias resolves only its linked product', () {
    final conversation = VoicePriceUpdateConversation();
    final products = [coffee, phase6cProduct(id: 'tea', name: 'Teh Tarik')];
    final alias = VoiceProductAlias(
      id: 'alias-1',
      aliasText: 'kopisusu',
      normalizedAlias: 'kopisusu',
      productId: coffee.id,
      canonicalProductName: coffee.name,
      createdAt: now,
      updatedAt: now,
    );

    final turn = conversation.start(
      command: router.route('Ubah harga kopisusu menjadi 12000'),
      products: products,
      aliases: [alias],
      now: now,
    );

    expect(turn.readyCommand?.entities.productId, coffee.id);
  });

  test('not-found product never creates a product automatically', () {
    final conversation = VoicePriceUpdateConversation();
    final turn = conversation.start(
      command: router.route('Ubah harga kopi pandan menjadi 12000'),
      products: [coffee],
      now: now,
    );

    expect(turn.readyCommand, isNull);
    expect(turn.response?.displayText, contains('belum ditemukan'));
    expect(conversation.hasPending, isFalse);
  });

  test('bulk and multi-price actions are rejected before preview', () {
    for (final command in [
      'Naikkan semua harga 10 persen',
      'Ubah harga jual dan harga modal kopi susu menjadi 12000',
    ]) {
      final conversation = VoicePriceUpdateConversation();
      final turn = conversation.start(
        command: router.route(command),
        products: [coffee],
        now: now,
      );

      expect(turn.readyCommand, isNull);
      expect(turn.response?.displayText, contains('belum didukung'));
      expect(conversation.hasPending, isFalse);
    }
  });

  test('cancel clears a pending clarification', () {
    final conversation = VoicePriceUpdateConversation();
    conversation.start(
      command: router.route('Ubah harga kopi susu'),
      products: [coffee],
      now: now,
    );

    final turn = conversation.answer(
      transcript: 'batal',
      products: [coffee],
      now: now.add(const Duration(seconds: 1)),
    );

    expect(turn.response?.displayText, contains('dibatalkan'));
    expect(conversation.hasPending, isFalse);
  });

  test('repeat keeps the current clarification active', () {
    final conversation = VoicePriceUpdateConversation();
    conversation.start(
      command: router.route('Ubah harga kopi susu'),
      products: [coffee],
      now: now,
    );

    final turn = conversation.answer(
      transcript: 'ulangi',
      products: [coffee],
      now: now.add(const Duration(seconds: 1)),
    );

    expect(turn.response?.displayText, contains('Berapa'));
    expect(conversation.hasPending, isTrue);
  });

  test('edit nominal replaces only the requested new price', () {
    final conversation = VoicePriceUpdateConversation();
    conversation.start(
      command: router.route('Ubah harga kopi susu'),
      products: [coffee],
      now: now,
    );

    final turn = conversation.answer(
      transcript: 'ubah nominal menjadi 13000',
      products: [coffee],
      now: now.add(const Duration(seconds: 1)),
    );

    expect(turn.readyCommand?.entities.productId, coffee.id);
    expect(
      turn.readyCommand?.entities.productPriceType,
      ProductPriceType.retail,
    );
    expect(turn.readyCommand?.entities.newProductPrice, 13000);
  });

  test('edit price type preserves product and nominal', () {
    final conversation = VoicePriceUpdateConversation();
    conversation.start(
      command: _command(
        productName: coffee.name,
        productId: coffee.id,
        newPrice: 7000,
      ),
      products: [coffee],
      now: now,
    );

    final turn = conversation.answer(
      transcript: 'ubah jenis harga modal',
      products: [coffee],
      now: now.add(const Duration(seconds: 1)),
    );

    expect(turn.readyCommand?.entities.productId, coffee.id);
    expect(turn.readyCommand?.entities.productPriceType, ProductPriceType.cost);
    expect(turn.readyCommand?.entities.newProductPrice, 7000);
  });

  test('edit product resolves the replacement product', () {
    final tea = phase6cProduct(id: 'tea', name: 'Teh Tarik');
    final conversation = VoicePriceUpdateConversation();
    conversation.start(
      command: router.route('Ubah harga kopi susu'),
      products: [coffee, tea],
      now: now,
    );

    final turn = conversation.answer(
      transcript: 'ubah produk teh tarik',
      products: [coffee, tea],
      now: now.add(const Duration(seconds: 1)),
    );

    expect(turn.response?.displayText, contains('Teh Tarik'));
    final completed = conversation.answer(
      transcript: '12000',
      products: [coffee, tea],
      now: now.add(const Duration(seconds: 2)),
    );
    expect(completed.readyCommand?.entities.productId, tea.id);
  });

  test('an explicit new command exits clarification routing', () {
    final conversation = VoicePriceUpdateConversation();
    conversation.start(
      command: router.route('Ubah harga kopi susu'),
      products: [coffee],
      now: now,
    );

    final turn = conversation.answer(
      transcript: 'berapa omzet hari ini',
      products: [coffee],
      now: now.add(const Duration(seconds: 1)),
      looksLikeNewCommand: true,
    );

    expect(turn.routeAsNewCommand, isTrue);
    expect(conversation.hasPending, isFalse);
  });

  test('clarification expires without creating a draft', () {
    final conversation = VoicePriceUpdateConversation(
      expiration: const Duration(seconds: 10),
    );
    conversation.start(
      command: router.route('Ubah harga kopi susu'),
      products: [coffee],
      now: now,
    );

    final turn = conversation.answer(
      transcript: '12000',
      products: [coffee],
      now: now.add(const Duration(seconds: 10)),
    );

    expect(turn.readyCommand, isNull);
    expect(turn.response?.displayText, contains('kedaluwarsa'));
    expect(conversation.hasPending, isFalse);
  });

  test('maximum invalid attempts cancels conservatively', () {
    final conversation = VoicePriceUpdateConversation(
      maximumInvalidAttempts: 2,
    );
    conversation.start(
      command: router.route('Ubah harga kopi susu'),
      products: [coffee],
      now: now,
    );

    conversation.answer(
      transcript: 'tidak tahu',
      products: [coffee],
      now: now.add(const Duration(seconds: 1)),
    );
    final turn = conversation.answer(
      transcript: 'masih tidak tahu',
      products: [coffee],
      now: now.add(const Duration(seconds: 2)),
    );

    expect(turn.response?.displayText, contains('dibatalkan'));
    expect(conversation.hasPending, isFalse);
  });
}

VoiceCommand _command({
  String? productId,
  String? productName,
  ProductPriceType? priceType,
  int? newPrice,
}) {
  return VoiceCommand(
    rawText: 'typed test command',
    normalizedText: 'typed test command',
    intent: VoiceCommandIntent.updateProduct,
    entities: VoiceCommandEntities(
      productId: productId,
      productName: productName,
      productPriceType: priceType,
      newProductPrice: newPrice,
    ),
    confidence: 1,
  );
}
