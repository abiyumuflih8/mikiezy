import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/models/product_price.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';
import 'package:mikiezy/services/voice/voice_price_update_entity_extractor.dart';

void main() {
  const extractor = VoicePriceUpdateEntityExtractor();
  const router = VoiceCommandRouter();

  group('typed price extraction', () {
    final cases =
        <({String command, String product, ProductPriceType type, int price})>[
          (
            command: 'Ubah harga kopi susu menjadi 12000',
            product: 'kopi susu',
            type: ProductPriceType.retail,
            price: 12000,
          ),
          (
            command: 'Ganti harga jual kopi susu jadi dua belas ribu',
            product: 'kopi susu',
            type: ProductPriceType.retail,
            price: 12000,
          ),
          (
            command: 'Harga retail mie goreng sekarang lima belas ribu',
            product: 'mie goreng',
            type: ProductPriceType.retail,
            price: 15000,
          ),
          (
            command: 'Kopi susu harga jualnya ubah ke dua belas ribu',
            product: 'kopi susu',
            type: ProductPriceType.retail,
            price: 12000,
          ),
          (
            command: 'Ubah harga grosir kopi sachet menjadi 1500',
            product: 'kopi sachet',
            type: ProductPriceType.wholesale,
            price: 1500,
          ),
          (
            command: 'Harga kulakan kopi sachet jadi seribu lima ratus',
            product: 'kopi sachet',
            type: ProductPriceType.wholesale,
            price: 1500,
          ),
          (
            command: 'Ubah harga modal gula menjadi 14000',
            product: 'gula',
            type: ProductPriceType.cost,
            price: 14000,
          ),
          (
            command: 'Modal kopi susu ganti menjadi tujuh ribu',
            product: 'kopi susu',
            type: ProductPriceType.cost,
            price: 7000,
          ),
          (
            command: 'Harga beli air mineral jadi 2500',
            product: 'air mineral',
            type: ProductPriceType.cost,
            price: 2500,
          ),
        ];

    for (final value in cases) {
      test(value.command, () {
        final routed = router.route(value.command);

        expect(routed.intent, VoiceCommandIntent.updateProduct);
        expect(routed.entities.productName, value.product);
        expect(routed.entities.productPriceType, value.type);
        expect(routed.entities.newProductPrice, value.price);
        expect(routed.entities.bulkPriceUpdateRequested, isFalse);
      });
    }
  });

  test('generic harga is an explicit retail default', () {
    final entities = extractor.extract(
      'ubah harga kopi susu menjadi dua belas ribu',
    );

    expect(entities.productPriceType, ProductPriceType.retail);
  });

  test('keeps model number and measurement in Aqua 600 ml product name', () {
    final routed = router.route('Ubah harga Aqua 600 ml menjadi 5000');

    expect(routed.entities.productName, 'aqua 600 ml');
    expect(routed.entities.newProductPrice, 5000);
  });

  test('measurement without a new nominal is not treated as price', () {
    final routed = router.route('Ubah harga Aqua 600 ml');

    expect(routed.entities.productName, 'aqua 600 ml');
    expect(routed.entities.newProductPrice, isNull);
  });

  test('explicit old price is not confused with the new price', () {
    final routed = router.route(
      'Ubah harga kopi susu dari 10000 menjadi 12000',
    );

    expect(routed.entities.productName, 'kopi susu');
    expect(routed.entities.newProductPrice, 12000);
  });

  test('negative price remains negative for domain validation', () {
    expect(extractor.parsePrice('minus lima ribu'), -5000);
    expect(extractor.parsePrice('-5000'), -5000);
  });

  test('bulk all-products command is routed only to safe rejection', () {
    final routed = router.route('Naikkan semua harga 10 persen');

    expect(routed.intent, VoiceCommandIntent.updateProduct);
    expect(routed.entities.bulkPriceUpdateRequested, isTrue);
  });

  test('multiple products with two new prices are rejected as bulk', () {
    final routed = router.route(
      'Ubah harga kopi menjadi 12000 dan teh menjadi 8000',
    );

    expect(routed.intent, VoiceCommandIntent.updateProduct);
    expect(routed.entities.bulkPriceUpdateRequested, isTrue);
  });

  test('multiple price types in one action are rejected', () {
    final routed = router.route(
      'Ubah harga jual dan harga modal kopi susu menjadi 12000',
    );

    expect(routed.entities.bulkPriceUpdateRequested, isTrue);
  });

  group('intent isolation', () {
    test('sale remains transaction intent', () {
      expect(
        router.route('Jual kopi susu dua gelas dua belas ribu').intent,
        VoiceCommandIntent.createSale,
      );
    });

    test('create product remains create intent', () {
      expect(
        router.route('Tambah produk kopi susu harga dua belas ribu').intent,
        VoiceCommandIntent.createProduct,
      );
    });

    test('stock increment remains stock intent', () {
      expect(
        router.route('Tambah stok kopi susu dua belas gelas').intent,
        VoiceCommandIntent.incrementProductStock,
      );
    });

    test('price query never creates mutation intent', () {
      expect(
        router.route('Berapa harga kopi susu?').intent,
        isNot(VoiceCommandIntent.updateProduct),
      );
    });

    test('discount command never creates catalog price mutation', () {
      expect(
        router.route('Kasih diskon kopi susu').intent,
        isNot(VoiceCommandIntent.updateProduct),
      );
    });
  });
}
