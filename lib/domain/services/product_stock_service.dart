import '../../models/mikiezy_models.dart';
import 'quantity_formatter.dart';
import 'unit_conversion_service.dart';

class ProductStockService {
  const ProductStockService({
    this.unitConversionService = const UnitConversionService(),
  });

  final UnitConversionService unitConversionService;

  void validateProduct(Product product) {
    if (product.stockPcs < 0) {
      throw ArgumentError.value(
        product.stockPcs,
        'stockPcs',
        'Stok tidak boleh negatif.',
      );
    }
    if (product.minStock < 0) {
      throw ArgumentError.value(
        product.minStock,
        'minStock',
        'Batas stok minimum tidak boleh negatif.',
      );
    }
  }

  double unitMultiplierFor(Product? product, SaleUnit unit) {
    if (product == null) return 1;
    final result = unitConversionService.multiplier(
      from: unit,
      to: product.baseUnit,
      product: product,
    );
    if (!result.isSuccess) throw UnitConversionException(result);
    return result.quantity!.multiplier;
  }

  double stockDelta(TransactionLine line) {
    return QuantityFormatter.normalize(line.quantity * line.unitMultiplier);
  }

  List<Product> applySaleStockChanges({
    required List<TransactionLine> lines,
    required Map<String, Product> productsById,
  }) {
    for (final product in productsById.values) {
      validateProduct(product);
    }
    final remainingStock = <String, double>{
      for (final entry in productsById.entries) entry.key: entry.value.stockPcs,
    };

    for (final line in lines) {
      final product = productsById[line.productId];
      if (product == null || !product.trackStock) continue;

      final delta = stockDelta(line);
      final available = remainingStock[product.id] ?? product.stockPcs;
      if (delta > available + 0.000001) {
        throw StockNotEnoughException(
          productName: product.name,
          available: available,
          requested: delta,
          unit: product.baseUnit,
        );
      }
      remainingStock[product.id] = QuantityFormatter.normalize(
        (available - delta).clamp(0, 1 << 31),
      );
    }

    final updates = <Product>[];
    for (final entry in remainingStock.entries) {
      final product = productsById[entry.key];
      if (product == null || product.stockPcs == entry.value) continue;
      updates.add(product.copyWith(stockPcs: entry.value));
    }
    return updates;
  }

}

class StockNotEnoughException implements Exception {
  const StockNotEnoughException({
    required this.productName,
    required this.available,
    required this.requested,
    this.unit = SaleUnit.pcs,
  });

  final String productName;
  final double available;
  final double requested;
  final SaleUnit unit;

  @override
  String toString() {
    return 'Stok $productName tidak cukup. Tersedia ${_quantityLabel(available)} ${unit.label}, butuh ${_quantityLabel(requested)} ${unit.label}.';
  }

  String _quantityLabel(num value) {
    if (value % 1 == 0) return value.round().toString();
    final fixed = value.toStringAsFixed(3);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
