import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/services/product_stock_service.dart';
import 'package:mikiezy/models/mikiezy_models.dart';

void main() {
  const service = ProductStockService();

  test('stock status distinguishes untracked, empty, low, and safe', () {
    expect(
      _product(trackStock: false).stockStatus,
      ProductStockStatus.notTracked,
    );
    expect(_product(stock: 0).stockStatus, ProductStockStatus.outOfStock);
    expect(
      _product(stock: 2.5, minStock: 2.5).stockStatus,
      ProductStockStatus.low,
    );
    expect(
      _product(stock: 2.51, minStock: 2.5).stockStatus,
      ProductStockStatus.safe,
    );
  });

  test('fractional stock and minimum values are valid', () {
    final product = _product(
      stock: 0.75,
      minStock: 0.25,
      baseUnit: SaleUnit.kilo,
    );

    expect(() => service.validateProduct(product), returnsNormally);
    expect(product.baseUnit, SaleUnit.kilo);
  });

  test('negative stock metadata is rejected', () {
    expect(
      () => service.validateProduct(_product(stock: -1)),
      throwsArgumentError,
    );
    expect(
      () => service.validateProduct(_product(minStock: -0.1)),
      throwsArgumentError,
    );
  });

  test('untracked product is not reduced or blocked', () {
    final product = _product(stock: 0, trackStock: false);
    final updates = service.applySaleStockChanges(
      lines: [_line(quantity: 10)],
      productsById: {product.id: product},
    );

    expect(updates, isEmpty);
  });

  test('pack sale uses the product pack size', () {
    final product = _product(stock: 25, packSize: 10);
    final updates = service.applySaleStockChanges(
      lines: [
        _line(
          quantity: 2,
          unit: SaleUnit.pack,
          unitMultiplier: service.unitMultiplierFor(product, SaleUnit.pack),
        ),
      ],
      productsById: {product.id: product},
    );

    expect(updates.single.stockPcs, 5);
  });

  test('tracked empty product blocks a sale', () {
    final product = _product(stock: 0);

    expect(
      () => service.applySaleStockChanges(
        lines: [_line(quantity: 1)],
        productsById: {product.id: product},
      ),
      throwsA(isA<StockNotEnoughException>()),
    );
  });
}

Product _product({
  double stock = 10,
  double minStock = 5,
  bool trackStock = true,
  SaleUnit baseUnit = SaleUnit.pcs,
  int packSize = 12,
}) {
  return Product(
    id: 'product',
    name: 'Produk',
    category: 'Umum',
    costPrice: 1000,
    retailPrice: 2000,
    wholesalePrice: 1800,
    packSize: packSize,
    cartonSize: 48,
    stockPcs: stock,
    trackStock: trackStock,
    baseUnit: baseUnit,
    minStock: minStock,
  );
}

TransactionLine _line({
  required double quantity,
  SaleUnit unit = SaleUnit.pcs,
  double unitMultiplier = 1,
}) {
  return TransactionLine(
    productId: 'product',
    productName: 'Produk',
    quantity: quantity,
    unit: unit,
    unitPrice: 2000,
    costPrice: 1000,
    segment: PriceSegment.retail,
    unitMultiplier: unitMultiplier,
  );
}
