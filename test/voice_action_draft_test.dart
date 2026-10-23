import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/voice_action_draft_factory.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 7, 13, 10);
  const router = VoiceCommandRouter();

  test(
    'creates a medium-risk product draft without changing catalog',
    () async {
      final products = [_product()];
      final factory = VoiceActionDraftFactory();

      final draft = await factory.create(
        command: router.route(
          'Tambah produk teh tarik harga jual 9000 tanpa stok',
        ),
        products: products,
        now: now,
      );

      expect(draft.type, VoiceActionType.createProduct);
      expect(draft.risk, VoiceActionRisk.medium);
      expect(draft.before, isNull);
      expect(draft.proposed.fields['nama'], 'Teh Tarik');
      expect(draft.proposed.fields['hargaJual'], contains('9000'));
      expect(draft.isValid, isTrue);
      expect(draft.isReversible, isFalse);
      expect(products, hasLength(1));
    },
  );

  test(
    'price draft contains immutable before and proposed snapshots',
    () async {
      final product = _product();
      final factory = VoiceActionDraftFactory();

      final draft = await factory.create(
        command: router.route('Ubah harga kopi susu menjadi dua belas ribu'),
        products: [product],
        now: now,
      );

      expect(draft.type, VoiceActionType.updateProductPrice);
      expect(draft.before?.entityId, product.id);
      expect(draft.before?.fields['hargaJual'], contains('10000'));
      expect(draft.proposed.fields['hargaJual'], contains('12000'));
      expect(draft.changes.single.before, 'Rp 10.000');
      expect(draft.changes.single.after, 'Rp 12.000');
      expect(product.retailPrice, 10000);
    },
  );

  test('stock reduction stays blocked and cannot become executable', () async {
    final factory = VoiceActionDraftFactory();
    final draft = await factory.create(
      command: _stockCommand('kurangi stok kopi susu 5 gelas'),
      products: [_product()],
      now: now,
    );

    expect(draft.type, VoiceActionType.adjustStock);
    expect(draft.risk, VoiceActionRisk.high);
    expect(draft.requiresAuthentication, isTrue);
    expect(draft.before?.fields['stok'], '20 gelas');
    expect(draft.isValid, isFalse);
    expect(draft.validationErrors.join(' '), contains('pengurangan stok'));
  });

  test(
    'invalid product and unsupported stock reduction are rejected',
    () async {
      final factory = VoiceActionDraftFactory();
      final missing = await factory.create(
        command: router.route('Ubah harga produk asing menjadi 15000'),
        products: [_product()],
        now: now,
      );
      final negative = await factory.create(
        command: _stockCommand('kurangi stok kopi susu 25 gelas'),
        products: [_product()],
        now: now,
      );

      expect(missing.isValid, isFalse);
      expect(missing.validationErrors.join(' '), contains('belum ditemukan'));
      expect(negative.isValid, isFalse);
      expect(negative.validationErrors.join(' '), contains('pengurangan stok'));
    },
  );

  test(
    'each draft gets a unique action ID even for duplicate callbacks',
    () async {
      final factory = VoiceActionDraftFactory();
      final command = router.route('Ubah harga kopi susu menjadi 12000');

      final first = await factory.create(
        command: command,
        products: [_product()],
        now: now,
      );
      final second = await factory.create(
        command: command,
        products: [_product()],
        now: now,
      );

      expect(first.actionId, isNot(second.actionId));
      expect(first.commandFingerprint, second.commandFingerprint);
    },
  );
}

VoiceCommand _stockCommand(String text) {
  return VoiceCommand(
    rawText: text,
    normalizedText: text,
    intent: VoiceCommandIntent.updateProduct,
    entities: const VoiceCommandEntities(productName: 'kopi susu'),
    confidence: 0.96,
  );
}

Product _product() {
  return const Product(
    id: 'product-coffee',
    name: 'Kopi Susu',
    category: 'Minuman',
    costPrice: 6000,
    retailPrice: 10000,
    wholesalePrice: 9000,
    packSize: 10,
    cartonSize: 24,
    stockPcs: 20,
    baseUnit: SaleUnit.gelas,
  );
}
