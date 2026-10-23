import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';
import 'package:mikiezy/services/voice/voice_create_product_entity_extractor.dart';

void main() {
  const router = VoiceCommandRouter();
  const extractor = VoiceCreateProductEntityExtractor();

  test('routes supported create-product phrases and extracts the name', () {
    for (final phrase in [
      'Tambah produk kopi susu',
      'Tambahkan barang kopi susu',
      'Buat produk baru kopi susu',
      'Masukkan produk kopi susu',
      'Tambah kopi susu harga 10000',
    ]) {
      final command = router.route(phrase);
      expect(command.intent, VoiceCommandIntent.createProduct, reason: phrase);
      expect(command.entities.productName, 'kopi susu', reason: phrase);
    }
  });

  test('extracts name and Indonesian sale price', () {
    final command = router.route(
      'Tambah produk kopi susu harga jual lima belas ribu',
    );

    expect(command.entities.productName, 'kopi susu');
    expect(command.entities.salePrice, 15000);
  });

  test('extracts cost and wholesale prices independently', () {
    final command = router.route(
      'Tambah produk kopi susu harga 15000 harga modal 8000 harga grosir 12000',
    );

    expect(command.entities.salePrice, 15000);
    expect(command.entities.costPrice, 8000);
    expect(command.entities.wholesalePrice, 12000);
  });

  test('extracts fractional stock and canonical unit', () {
    final command = router.route(
      'Tambah produk beras harga 15000 stok setengah kilo',
    );

    expect(command.entities.stock, 0.5);
    expect(command.entities.unit, SaleUnit.kilo.name);
    expect(command.entities.trackStock, isTrue);
  });

  test('extracts category, minimum stock, pack, and carton metadata', () {
    final command = router.route(
      'Tambah produk kopi susu harga lima belas ribu '
      'stok dua puluh gelas kategori minuman stok minimum dua '
      'isi pack enam isi karton dua puluh empat',
    );

    expect(command.entities.categoryName, 'minuman');
    expect(command.entities.minStock, 2);
    expect(command.entities.packSize, 6);
    expect(command.entities.cartonSize, 24);
  });

  test('explicit no-stock phrase disables stock tracking', () {
    final command = router.route(
      'Tambah produk jasa antar harga 5000 tanpa stok',
    );

    expect(command.entities.trackStock, isFalse);
    expect(command.entities.stock, isNull);
  });

  test('learned unit aliases normalize to a canonical unit', () {
    final alias = VoiceUnitAlias(
      id: 'unit-sloki',
      aliasText: 'sloki',
      normalizedAlias: 'sloki',
      canonicalUnit: SaleUnit.gelas.name,
      createdAt: DateTime(2030),
      updatedAt: DateTime(2030),
    );

    final entities = extractor.extract(
      'stok dua puluh sloki',
      unitAliases: [alias],
    );

    expect(entities.stock, 20);
    expect(entities.unit, SaleUnit.gelas.name);
  });

  test('keeps numbers that are part of the product name', () {
    final command = router.route(
      'Tambah produk kopi 2 in 1 harga 12000 tanpa stok',
    );

    expect(command.entities.productName, 'kopi 2 in 1');
    expect(command.entities.salePrice, 12000);
  });

  test('does not invent a canonical unit for unknown speech', () {
    final entities = extractor.extract('stok sepuluh wadahajaib');

    expect(entities.stock, 10);
    expect(entities.unit, isNull);
  });
}
