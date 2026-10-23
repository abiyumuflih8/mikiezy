import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';
import 'package:mikiezy/services/voice/voice_stock_increment_conversation.dart';

void main() {
  const router = VoiceCommandRouter();
  final now = DateTime(2030, 1, 1, 10);

  test('asks for a missing product name', () {
    final conversation = VoiceStockIncrementConversation();
    final turn = conversation.start(
      command: router.route('tambah stok 10 gelas'),
      products: [_product()],
      now: now,
    );
    expect(turn.response?.displayText, contains('Produk mana'));
    expect(conversation.hasPending, isTrue);
  });

  test('asks for a missing quantity', () {
    final conversation = VoiceStockIncrementConversation();
    final turn = conversation.start(
      command: router.route('tambah stok kopi susu'),
      products: [_product()],
      now: now,
    );
    expect(turn.response?.displayText, contains('Berapa jumlah'));
  });

  test('asks for a missing or unknown unit', () {
    final conversation = VoiceStockIncrementConversation();
    final missing = conversation.start(
      command: router.route('tambah stok kopi susu 10'),
      products: [_product()],
      now: now,
    );
    expect(missing.response?.displayText, contains('satuan apa'));

    conversation.clear();
    final unknown = conversation.start(
      command: router.route('tambah stok kopi susu 10 lusin'),
      products: [_product()],
      now: now,
    );
    expect(unknown.response?.displayText, contains('satuan apa'));
  });

  test('ambiguous product selection resumes the original command', () {
    final conversation = VoiceStockIncrementConversation();
    final products = [
      _product(id: 'aqua-600', name: 'Aqua 600 ml'),
      _product(id: 'aqua-1500', name: 'Aqua 1,5 liter'),
    ];
    final ambiguous = conversation.start(
      command: router.route('tambah stok aqua 2 karton'),
      products: products,
      now: now,
    );
    expect(ambiguous.response?.displayText, contains('Aqua 600 ml'));
    expect(ambiguous.response?.displayText, contains('Aqua 1,5 liter'));

    final selected = conversation.answer(
      transcript: 'yang 600 ml',
      products: products,
      now: now,
    );
    expect(selected.readyCommand?.entities.productId, 'aqua-600');
    expect(selected.readyCommand?.entities.quantity, 2);
    expect(selected.readyCommand?.entities.unit, SaleUnit.carton.name);
    expect(conversation.hasPending, isFalse);
  });

  test('tracked product reaches preview without extra clarification', () {
    final conversation = VoiceStockIncrementConversation();
    final turn = conversation.start(
      command: router.route('tambah stok kopi susu 10 gelas'),
      products: [_product()],
      now: now,
    );
    expect(turn.readyCommand, isNotNull);
    expect(turn.readyCommand?.entities.productId, 'coffee');
    expect(turn.readyCommand?.entities.clarificationOccurred, isFalse);
    expect(conversation.hasPending, isFalse);
  });

  test('untracked product requires explicit tracking confirmation', () {
    final conversation = VoiceStockIncrementConversation();
    final product = _product(
      trackStock: false,
      stock: 0,
      baseUnit: SaleUnit.pcs,
    );
    final question = conversation.start(
      command: router.route('tambah stok kopi susu 10 gelas'),
      products: [product],
      now: now,
    );
    expect(question.response?.displayText, contains('tidak dilacak'));
    expect(question.response?.displayText, contains('Satuan dasar'));

    final accepted = conversation.answer(
      transcript: 'ya aktifkan',
      products: [product],
      now: now,
    );
    expect(accepted.readyCommand?.entities.trackingEnableConfirmed, isTrue);
    expect(accepted.readyCommand?.entities.clarificationOccurred, isTrue);
  });

  test('rejecting tracking activation cancels without a draft', () {
    final conversation = VoiceStockIncrementConversation();
    final product = _product(trackStock: false, stock: 0);
    conversation.start(
      command: router.route('tambah stok kopi susu 10 gelas'),
      products: [product],
      now: now,
    );
    final rejected = conversation.answer(
      transcript: 'tidak',
      products: [product],
      now: now,
    );
    expect(rejected.readyCommand, isNull);
    expect(rejected.response?.displayText, contains('Tidak ada data'));
    expect(conversation.hasPending, isFalse);
  });

  test('cancel clears pending context', () {
    final conversation = VoiceStockIncrementConversation();
    conversation.start(
      command: router.route('tambah stok kopi susu'),
      products: [_product()],
      now: now,
    );
    final cancelled = conversation.answer(
      transcript: 'batal',
      products: [_product()],
      now: now,
    );
    expect(cancelled.response?.displayText, contains('dibatalkan'));
    expect(conversation.hasPending, isFalse);
  });

  test('repeat keeps the current clarification field', () {
    final conversation = VoiceStockIncrementConversation();
    conversation.start(
      command: router.route('tambah stok kopi susu'),
      products: [_product()],
      now: now,
    );
    final repeated = conversation.answer(
      transcript: 'ulangi',
      products: [_product()],
      now: now,
    );
    expect(repeated.response?.displayText, contains('Berapa jumlah'));
  });

  test('new command cancels old context without consuming it', () {
    final conversation = VoiceStockIncrementConversation();
    conversation.start(
      command: router.route('tambah stok kopi susu'),
      products: [_product()],
      now: now,
    );
    final replaced = conversation.answer(
      transcript: 'buka laporan',
      products: [_product()],
      now: now,
      looksLikeNewCommand: true,
    );
    expect(replaced.routeAsNewCommand, isTrue);
    expect(conversation.hasPending, isFalse);
  });

  test('expired context is cleared safely', () {
    final conversation = VoiceStockIncrementConversation(
      expiration: const Duration(seconds: 5),
    );
    conversation.start(
      command: router.route('tambah stok kopi susu'),
      products: [_product()],
      now: now,
    );
    final expired = conversation.answer(
      transcript: '10',
      products: [_product()],
      now: now.add(const Duration(seconds: 6)),
    );
    expect(expired.response?.displayText, contains('kedaluwarsa'));
    expect(conversation.hasPending, isFalse);
  });

  test('maximum invalid attempts cancels unsafe context', () {
    final conversation = VoiceStockIncrementConversation(
      maximumInvalidAttempts: 2,
    );
    conversation.start(
      command: router.route('tambah stok kopi susu 10'),
      products: [_product()],
      now: now,
    );
    conversation.answer(
      transcript: 'entahlah',
      products: [_product()],
      now: now,
    );
    final stopped = conversation.answer(
      transcript: 'masih entahlah',
      products: [_product()],
      now: now,
    );
    expect(stopped.response?.displayText, contains('dibatalkan'));
    expect(conversation.hasPending, isFalse);
  });

  test('product not found never creates a new product automatically', () {
    final conversation = VoiceStockIncrementConversation();
    final turn = conversation.start(
      command: router.route('tambah stok kopi pandan 10 gelas'),
      products: [_product()],
      now: now,
    );
    expect(turn.readyCommand, isNull);
    expect(turn.response?.displayText, contains('belum ditemukan'));
    expect(conversation.hasPending, isFalse);
  });
}

Product _product({
  String id = 'coffee',
  String name = 'Kopi Susu',
  double stock = 20,
  bool trackStock = true,
  SaleUnit baseUnit = SaleUnit.gelas,
}) {
  return Product(
    id: id,
    name: name,
    category: 'Minuman',
    costPrice: 5000,
    retailPrice: 10000,
    wholesalePrice: 9000,
    packSize: 12,
    cartonSize: 48,
    stockPcs: stock,
    trackStock: trackStock,
    baseUnit: baseUnit,
    minStock: 5,
  );
}
