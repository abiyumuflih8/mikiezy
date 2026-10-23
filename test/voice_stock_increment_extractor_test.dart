import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';
import 'package:mikiezy/services/voice/voice_stock_increment_entity_extractor.dart';

void main() {
  const extractor = VoiceStockIncrementEntityExtractor();
  const router = VoiceCommandRouter();

  test('extracts product, integer quantity, and unit', () {
    final entities = extractor.extract('tambah stok kopi susu 10 gelas');

    expect(entities.productName, 'kopi susu');
    expect(entities.quantity, 10);
    expect(entities.unit, SaleUnit.gelas.name);
  });

  test('extracts a product positioned before the stock phrase', () {
    final entities = extractor.extract('kopi susu ditambah stoknya 10 gelas');
    expect(entities.productName, 'kopi susu');
    expect(entities.quantity, 10);
  });

  test('extracts a product positioned after quantity and unit', () {
    final entities = extractor.extract('masukkan 10 gelas ke stok kopi susu');
    expect(entities.productName, 'kopi susu');
    expect(entities.quantity, 10);
    expect(entities.unit, SaleUnit.gelas.name);
  });

  test('parses comma decimal quantity', () {
    final entities = extractor.extract('restok beras 2,5 kilo');
    expect(entities.productName, 'beras');
    expect(entities.quantity, 2.5);
  });

  test('parses setengah and seperempat', () {
    expect(extractor.extract('tambah stok gula setengah kilo').quantity, 0.5);
    expect(
      extractor.extract('tambah stok gula seperempat kilo').quantity,
      0.25,
    );
  });

  test('parses satu setengah and dua setengah', () {
    expect(
      extractor.extract('tambah stok sirup satu setengah liter').quantity,
      1.5,
    );
    expect(
      extractor.extract('tambah stok sirup dua setengah liter').quantity,
      2.5,
    );
  });

  for (final entry in const {
    'tambah stok beras 2 kg': SaleUnit.kilo,
    'tambah stok tepung 500 gram': SaleUnit.gram,
    'tambah stok sirup 2 liter': SaleUnit.liter,
    'tambah stok sirup 500 ml': SaleUnit.ml,
    'tambah kopi sachet 3 pack': SaleUnit.pack,
    'tambah stok aqua 2 karton': SaleUnit.carton,
  }.entries) {
    test('normalizes ${entry.value.name} unit', () {
      expect(extractor.extract(entry.key).unit, entry.value.name);
    });
  }

  test('keeps measurement tokens inside a numbered product name', () {
    final entities = extractor.extract('tambah stok aqua 600 ml 2 karton');
    expect(entities.productName, 'aqua 600 ml');
    expect(entities.quantity, 2);
    expect(entities.unit, SaleUnit.carton.name);
  });

  test('keeps unknown unit explicit instead of assuming pcs', () {
    final entities = extractor.extract('tambah stok kopi 10 lusin');
    expect(entities.productName, 'kopi');
    expect(entities.quantity, 10);
    expect(entities.unit, 'lusin');
  });

  test('sale command remains a sale intent', () {
    expect(
      router.route('jual kopi susu 10 gelas').intent,
      VoiceCommandIntent.createSale,
    );
  });

  test('absolute stock command remains unsupported update intent', () {
    expect(
      router.route('ubah stok kopi susu menjadi 10').intent,
      VoiceCommandIntent.updateProduct,
    );
  });

  test('stock reduction remains unsupported update intent', () {
    expect(
      router.route('kurangi stok kopi susu 10 gelas').intent,
      VoiceCommandIntent.updateProduct,
    );
  });

  test('create product command remains create-product intent', () {
    expect(
      router.route('tambah produk kopi susu').intent,
      VoiceCommandIntent.createProduct,
    );
  });

  for (final command in const [
    'Tambah stok kopi susu 10 gelas',
    'Tambahkan stok kopi susu 10 gelas',
    'Restok kopi susu 10 gelas',
    'Masukkan 10 gelas ke stok kopi susu',
    'Stok kopi susu tambah 10 gelas',
    'Kopi susu ditambah stoknya 10 gelas',
    'Tambah beras 5 kilo ke stok',
    'Tambah Aqua dua karton',
  ]) {
    test('routes supported increment command: $command', () {
      expect(
        router.route(command).intent,
        VoiceCommandIntent.incrementProductStock,
      );
    });
  }
}
