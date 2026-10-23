import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/models/product_price.dart';
import 'package:mikiezy/domain/services/product_price_update_validator.dart';

import 'support/phase6c_fixtures.dart';

void main() {
  const validator = ProductPriceUpdateValidator();

  test('retail price update is valid', () {
    final result = validator.validate(
      product: phase6cProduct(),
      type: ProductPriceType.retail,
      newPrice: 12000,
    );

    expect(result.isSuccess, isTrue);
    expect(result.oldPrice, 10000);
    expect(result.newPrice, 12000);
    expect(result.difference, 2000);
    expect(result.percentageChange, closeTo(20, 0.000001));
    expect(result.risk, ProductPriceUpdateRisk.medium);
    expect(result.warnings, isEmpty);
  });

  test('wholesale price update is valid', () {
    final result = validator.validate(
      product: phase6cProduct(),
      type: ProductPriceType.wholesale,
      newPrice: 9500,
    );

    expect(result.isSuccess, isTrue);
    expect(result.oldPrice, 9000);
  });

  test('cost price update is valid', () {
    final result = validator.validate(
      product: phase6cProduct(),
      type: ProductPriceType.cost,
      newPrice: 7000,
    );

    expect(result.isSuccess, isTrue);
    expect(result.oldPrice, 6000);
  });

  test('negative price is rejected', () {
    final result = validator.validate(
      product: phase6cProduct(),
      type: ProductPriceType.retail,
      newPrice: -1,
    );

    expect(result.status, ProductPriceValidationStatus.invalidPrice);
    expect(result.message, contains('negatif'));
  });

  test('zero retail and wholesale prices are rejected', () {
    for (final type in [ProductPriceType.retail, ProductPriceType.wholesale]) {
      final result = validator.validate(
        product: phase6cProduct(),
        type: type,
        newPrice: 0,
      );
      expect(result.status, ProductPriceValidationStatus.invalidPrice);
      expect(result.message, contains('lebih dari nol'));
    }
  });

  test('zero cost is allowed only with high-risk warnings', () {
    final result = validator.validate(
      product: phase6cProduct(),
      type: ProductPriceType.cost,
      newPrice: 0,
    );

    expect(result.isSuccess, isTrue);
    expect(result.risk, ProductPriceUpdateRisk.high);
    expect(result.warnings, contains(ProductPriceWarning.zeroPrice));
    expect(result.warnings, contains(ProductPriceWarning.extremeDecrease));
    expect(result.requiresAdditionalConfirmation, isTrue);
  });

  test('NaN, infinity, fractional, and oversized values are rejected', () {
    for (final value in <num>[
      double.nan,
      double.infinity,
      12000.5,
      9007199254740992,
    ]) {
      final result = validator.validate(
        product: phase6cProduct(),
        type: ProductPriceType.retail,
        newPrice: value,
      );
      expect(
        result.status,
        ProductPriceValidationStatus.invalidPrice,
        reason: '$value must be rejected',
      );
    }
  });

  test('same price is a typed no-op rejection', () {
    final result = validator.validate(
      product: phase6cProduct(),
      type: ProductPriceType.retail,
      newPrice: 10000,
    );

    expect(result.status, ProductPriceValidationStatus.samePrice);
    expect(result.message, contains('sama'));
  });

  test('two-times increase is extreme and needs second confirmation', () {
    final result = validator.validate(
      product: phase6cProduct(),
      type: ProductPriceType.retail,
      newPrice: 20000,
    );

    expect(result.warnings, contains(ProductPriceWarning.extremeIncrease));
    expect(result.requiresAdditionalConfirmation, isTrue);
  });

  test('half-price decrease is extreme and needs second confirmation', () {
    final result = validator.validate(
      product: phase6cProduct(),
      type: ProductPriceType.retail,
      newPrice: 5000,
    );

    expect(result.warnings, contains(ProductPriceWarning.extremeDecrease));
    expect(result.requiresAdditionalConfirmation, isTrue);
  });

  test('cost above retail is warning rather than silent rejection', () {
    final result = validator.validate(
      product: phase6cProduct(),
      type: ProductPriceType.cost,
      newPrice: 11000,
    );

    expect(result.isSuccess, isTrue);
    expect(result.warnings, contains(ProductPriceWarning.costAboveRetail));
    expect(result.requiresAdditionalConfirmation, isTrue);
  });

  test('wholesale above retail is warning rather than retail mutation', () {
    final product = phase6cProduct();
    final result = validator.validate(
      product: product,
      type: ProductPriceType.wholesale,
      newPrice: 11000,
    );

    expect(result.isSuccess, isTrue);
    expect(result.warnings, contains(ProductPriceWarning.wholesaleAboveRetail));
    expect(
      ProductPriceType.wholesale.applyTo(product, 11000).retailPrice,
      10000,
    );
  });

  test('large nominal uses the central high-risk threshold', () {
    final result = validator.validate(
      product: phase6cProduct(),
      type: ProductPriceType.retail,
      newPrice: 1000000000,
    );

    expect(result.warnings, contains(ProductPriceWarning.largeNominal));
    expect(result.risk, ProductPriceUpdateRisk.high);
  });

  test('zero existing wholesale has no percentage and can be added safely', () {
    final result = validator.validate(
      product: phase6cProduct(wholesalePrice: 0),
      type: ProductPriceType.wholesale,
      newPrice: 1500,
    );

    expect(result.isSuccess, isTrue);
    expect(result.oldPrice, 0);
    expect(result.percentageChange, isNull);
  });
}
