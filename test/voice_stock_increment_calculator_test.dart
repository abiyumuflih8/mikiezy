import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/services/quantity_formatter.dart';
import 'package:mikiezy/domain/services/stock_increment_calculator.dart';
import 'package:mikiezy/models/mikiezy_models.dart';

void main() {
  const calculator = StockIncrementCalculator();

  test('increments an integer in the same base unit', () {
    final result = calculator.calculate(
      product: _product(stock: 20, baseUnit: SaleUnit.gelas),
      requestedQuantity: 10,
      requestedUnit: SaleUnit.gelas,
      trackingEnableConfirmed: false,
    );
    expect(result.isSuccess, isTrue);
    expect(result.normalizedQuantity, 10);
    expect(result.stockAfter, 30);
  });

  test('converts kilograms to grams and preserves decimal precision', () {
    final result = calculator.calculate(
      product: _product(stock: 10000, baseUnit: SaleUnit.gram),
      requestedQuantity: 2.5,
      requestedUnit: SaleUnit.kilo,
      trackingEnableConfirmed: false,
    );
    expect(result.normalizedQuantity, 2500);
    expect(result.stockAfter, 12500);
  });

  test('converts grams to kilograms and ons to grams', () {
    final gramsToKg = calculator.calculate(
      product: _product(stock: 1, baseUnit: SaleUnit.kilo),
      requestedQuantity: 250,
      requestedUnit: SaleUnit.gram,
      trackingEnableConfirmed: false,
    );
    final onsToGram = calculator.calculate(
      product: _product(stock: 100, baseUnit: SaleUnit.gram),
      requestedQuantity: 2,
      requestedUnit: SaleUnit.ons,
      trackingEnableConfirmed: false,
    );
    expect(gramsToKg.normalizedQuantity, 0.25);
    expect(gramsToKg.stockAfter, 1.25);
    expect(onsToGram.normalizedQuantity, 200);
  });

  test('converts liters and milliliters in both directions', () {
    final liters = calculator.calculate(
      product: _product(stock: 500, baseUnit: SaleUnit.ml),
      requestedQuantity: 1.5,
      requestedUnit: SaleUnit.liter,
      trackingEnableConfirmed: false,
    );
    final milliliters = calculator.calculate(
      product: _product(stock: 1, baseUnit: SaleUnit.liter),
      requestedQuantity: 250,
      requestedUnit: SaleUnit.ml,
      trackingEnableConfirmed: false,
    );
    expect(liters.stockAfter, 2000);
    expect(milliliters.stockAfter, 1.25);
  });

  test('converts meters to centimeters', () {
    final result = calculator.calculate(
      product: _product(stock: 50, baseUnit: SaleUnit.centimeter),
      requestedQuantity: 1.25,
      requestedUnit: SaleUnit.meter,
      trackingEnableConfirmed: false,
    );
    expect(result.normalizedQuantity, 125);
    expect(result.stockAfter, 175);
  });

  test('uses product pack and carton sizes without hardcoded multipliers', () {
    final product = _product(
      stock: 100,
      baseUnit: SaleUnit.sachet,
      packSize: 12,
      cartonSize: 30,
    );
    final pack = calculator.calculate(
      product: product,
      requestedQuantity: 3,
      requestedUnit: SaleUnit.pack,
      trackingEnableConfirmed: false,
    );
    final carton = calculator.calculate(
      product: product,
      requestedQuantity: 2,
      requestedUnit: SaleUnit.carton,
      trackingEnableConfirmed: false,
    );
    expect(pack.normalizedQuantity, 36);
    expect(pack.stockAfter, 136);
    expect(carton.normalizedQuantity, 60);
  });

  test('reports missing pack and carton metadata separately', () {
    final product = _product(packSize: 0, cartonSize: 0);
    final pack = calculator.calculate(
      product: product,
      requestedQuantity: 1,
      requestedUnit: SaleUnit.pack,
      trackingEnableConfirmed: false,
    );
    final carton = calculator.calculate(
      product: product,
      requestedQuantity: 1,
      requestedUnit: SaleUnit.carton,
      trackingEnableConfirmed: false,
    );
    expect(pack.status, StockIncrementCalculationStatus.missingPackSize);
    expect(carton.status, StockIncrementCalculationStatus.missingCartonSize);
  });

  test('rejects incompatible dimensions', () {
    final result = calculator.calculate(
      product: _product(stock: 10, baseUnit: SaleUnit.botol),
      requestedQuantity: 1,
      requestedUnit: SaleUnit.kilo,
      trackingEnableConfirmed: false,
    );
    expect(result.status, StockIncrementCalculationStatus.incompatibleUnit);
  });

  for (final quantity in [0.0, -1.0, double.nan, double.infinity]) {
    test('rejects invalid quantity $quantity', () {
      final result = calculator.calculate(
        product: _product(),
        requestedQuantity: quantity,
        requestedUnit: SaleUnit.pcs,
        trackingEnableConfirmed: false,
      );
      expect(result.status, StockIncrementCalculationStatus.invalidQuantity);
    });
  }

  test('normalizes floating point artifacts', () {
    final result = calculator.calculate(
      product: _product(stock: 0.1, baseUnit: SaleUnit.liter),
      requestedQuantity: 0.1 + 0.2,
      requestedUnit: SaleUnit.liter,
      trackingEnableConfirmed: false,
    );
    expect(QuantityFormatter.label(result.stockAfter!), '0.4');
  });

  test('untracked product requires confirmation before mutation', () {
    final result = calculator.calculate(
      product: _product(stock: 0, trackStock: false),
      requestedQuantity: 10,
      requestedUnit: SaleUnit.pcs,
      trackingEnableConfirmed: false,
    );
    expect(
      result.status,
      StockIncrementCalculationStatus.trackingConfirmationRequired,
    );
  });

  test(
    'confirmed tracking activation can adopt a safe requested base unit',
    () {
      final result = calculator.calculate(
        product: _product(stock: 0, trackStock: false, baseUnit: SaleUnit.pcs),
        requestedQuantity: 1.5,
        requestedUnit: SaleUnit.liter,
        trackingEnableConfirmed: true,
      );
      expect(result.isSuccess, isTrue);
      expect(result.enableTracking, isTrue);
      expect(result.baseUnit, SaleUnit.liter);
      expect(result.stockAfter, 1.5);
      expect(result.risk, VoiceStockIncrementRisk.high);
    },
  );
}

Product _product({
  double stock = 20,
  bool trackStock = true,
  SaleUnit baseUnit = SaleUnit.pcs,
  int packSize = 10,
  int cartonSize = 24,
}) {
  return Product(
    id: 'product',
    name: 'Produk Test',
    category: 'Test',
    costPrice: 1000,
    retailPrice: 2000,
    wholesalePrice: 1500,
    packSize: packSize,
    cartonSize: cartonSize,
    stockPcs: stock,
    trackStock: trackStock,
    baseUnit: baseUnit,
    minStock: 5,
  );
}
