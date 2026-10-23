import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/services/product_validator.dart';
import 'package:mikiezy/models/mikiezy_models.dart';

import 'support/phase6a_fixtures.dart';

void main() {
  const validator = ProductValidator();

  test('accepts a valid tracked product with canonical unit', () {
    final result = validator.validate(phase6aProduct());

    expect(result.isValid, isTrue);
  });

  test('rejects empty and symbol-only names', () {
    final empty = validator.validate(phase6aProduct(name: '   '));
    final symbols = validator.validate(phase6aProduct(name: '--- !!!'));

    expect(
      empty.issues.map((issue) => issue.code),
      contains(ProductValidationCode.emptyName),
    );
    expect(
      symbols.issues.map((issue) => issue.code),
      contains(ProductValidationCode.invalidName),
    );
  });

  test('retail price policy requires a value greater than zero', () {
    for (final price in [0, -1]) {
      final result = validator.validate(phase6aProduct(retailPrice: price));
      expect(
        result.issues.map((issue) => issue.code),
        contains(ProductValidationCode.invalidRetailPrice),
      );
    }
  });

  test('rejects negative cost and wholesale prices', () {
    final result = validator.validate(
      phase6aProduct(costPrice: -1, wholesalePrice: -2),
    );

    expect(
      result.issues.map((issue) => issue.code),
      containsAll([
        ProductValidationCode.invalidCostPrice,
        ProductValidationCode.invalidWholesalePrice,
      ]),
    );
  });

  test('rejects negative stock and minimum stock', () {
    final result = validator.validate(
      phase6aProduct(stock: -0.5, minStock: -1),
    );

    expect(
      result.issues.map((issue) => issue.code),
      containsAll([
        ProductValidationCode.invalidStock,
        ProductValidationCode.invalidMinimumStock,
      ]),
    );
  });

  test('rejects zero pack and carton sizes', () {
    final result = validator.validate(
      phase6aProduct(packSize: 0, cartonSize: 0),
    );

    expect(
      result.issues.map((issue) => issue.code),
      containsAll([
        ProductValidationCode.invalidPackSize,
        ProductValidationCode.invalidCartonSize,
      ]),
    );
  });

  test('untracked products require zero stock metadata', () {
    final invalid = validator.validate(
      phase6aProduct(trackStock: false, stock: 5, minStock: 1),
    );
    final valid = validator.validate(
      phase6aProduct(
        trackStock: false,
        stock: 0,
        minStock: 0,
        baseUnit: SaleUnit.pcs,
      ),
    );

    expect(
      invalid.issues.map((issue) => issue.code),
      contains(ProductValidationCode.inconsistentStockTracking),
    );
    expect(valid.isValid, isTrue);
  });

  test('rejects an empty category', () {
    final result = validator.validate(phase6aProduct(category: ' '));

    expect(
      result.issues.map((issue) => issue.code),
      contains(ProductValidationCode.emptyCategory),
    );
  });

  test('exact duplicate normalization is shared and conservative', () {
    final existing = phase6aProduct(name: 'Kopi Susu');

    for (final name in ['kopi susu', 'Kopi   Susu', 'Kopi-Susu']) {
      final result = validator.validate(
        phase6aProduct(id: 'new', name: name),
        existingProducts: [existing],
      );
      expect(
        result.issues.map((issue) => issue.code),
        contains(ProductValidationCode.duplicateName),
        reason: name,
      );
    }
  });

  test('editing excludes the current product from duplicate validation', () {
    final product = phase6aProduct();
    final result = validator.validate(
      product,
      existingProducts: [product],
      excludingProductId: product.id,
    );

    expect(result.isValid, isTrue);
  });
}
