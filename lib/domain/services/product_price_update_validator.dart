import '../../models/mikiezy_models.dart';
import '../models/product_price.dart';
import 'product_validator.dart';

enum ProductPriceValidationStatus { success, invalidPrice, samePrice }

class ProductPriceValidationResult {
  ProductPriceValidationResult._({
    required this.status,
    this.oldPrice,
    this.newPrice,
    this.difference,
    this.percentageChange,
    this.risk = ProductPriceUpdateRisk.medium,
    List<ProductPriceWarning> warnings = const [],
    this.message,
  }) : warnings = List.unmodifiable(warnings);

  ProductPriceValidationResult.success({
    required int oldPrice,
    required int newPrice,
    required int difference,
    required double? percentageChange,
    required ProductPriceUpdateRisk risk,
    required List<ProductPriceWarning> warnings,
  }) : this._(
         status: ProductPriceValidationStatus.success,
         oldPrice: oldPrice,
         newPrice: newPrice,
         difference: difference,
         percentageChange: percentageChange,
         risk: risk,
         warnings: warnings,
       );

  ProductPriceValidationResult.failure(
    ProductPriceValidationStatus status,
    String message,
  ) : this._(status: status, message: message);

  final ProductPriceValidationStatus status;
  final int? oldPrice;
  final int? newPrice;
  final int? difference;
  final double? percentageChange;
  final ProductPriceUpdateRisk risk;
  final List<ProductPriceWarning> warnings;
  final String? message;

  bool get isSuccess => status == ProductPriceValidationStatus.success;
  bool get requiresAdditionalConfirmation => warnings.isNotEmpty;
}

class ProductPriceUpdatePolicy {
  const ProductPriceUpdatePolicy({
    this.extremeIncreaseFactor = 2,
    this.extremeDecreaseFactor = 0.5,
    this.largeNominalThreshold = 1000000000,
    this.maximumPrice = 9007199254740991,
  });

  final double extremeIncreaseFactor;
  final double extremeDecreaseFactor;
  final int largeNominalThreshold;
  final int maximumPrice;

  List<ProductPriceWarning> warningsFor({
    required Product product,
    required ProductPriceType type,
    required int oldPrice,
    required int newPrice,
  }) {
    final warnings = <ProductPriceWarning>[];
    if (oldPrice > 0 && newPrice >= oldPrice * extremeIncreaseFactor) {
      warnings.add(ProductPriceWarning.extremeIncrease);
    }
    if (oldPrice > 0 && newPrice <= oldPrice * extremeDecreaseFactor) {
      warnings.add(ProductPriceWarning.extremeDecrease);
    }
    if (newPrice == 0) warnings.add(ProductPriceWarning.zeroPrice);
    if (newPrice >= largeNominalThreshold) {
      warnings.add(ProductPriceWarning.largeNominal);
    }
    if (type == ProductPriceType.cost && newPrice > product.retailPrice) {
      warnings.add(ProductPriceWarning.costAboveRetail);
    }
    if (type == ProductPriceType.wholesale && newPrice > product.retailPrice) {
      warnings.add(ProductPriceWarning.wholesaleAboveRetail);
    }
    return warnings;
  }
}

class ProductPriceUpdateValidator {
  const ProductPriceUpdateValidator({
    this.productValidator = const ProductValidator(),
    this.policy = const ProductPriceUpdatePolicy(),
  });

  final ProductValidator productValidator;
  final ProductPriceUpdatePolicy policy;

  ProductPriceValidationResult validate({
    required Product product,
    required ProductPriceType type,
    required num? newPrice,
  }) {
    if (newPrice == null ||
        newPrice is double && !newPrice.isFinite ||
        newPrice % 1 != 0 ||
        newPrice > policy.maximumPrice) {
      return ProductPriceValidationResult.failure(
        ProductPriceValidationStatus.invalidPrice,
        'Harga baru harus berupa angka bulat yang valid.',
      );
    }
    final value = newPrice.toInt();
    if (value < 0) {
      return ProductPriceValidationResult.failure(
        ProductPriceValidationStatus.invalidPrice,
        'Harga tidak boleh negatif.',
      );
    }
    if (type != ProductPriceType.cost && value == 0) {
      return ProductPriceValidationResult.failure(
        ProductPriceValidationStatus.invalidPrice,
        '${type.label.substring(0, 1).toUpperCase()}${type.label.substring(1)} harus lebih dari nol.',
      );
    }

    final oldPrice = type.valueOf(product);
    if (value == oldPrice) {
      return ProductPriceValidationResult.failure(
        ProductPriceValidationStatus.samePrice,
        'Harga baru sama dengan harga saat ini. Tidak ada perubahan yang dilakukan.',
      );
    }

    final updated = type.applyTo(product, value);
    final relevantCode = switch (type) {
      ProductPriceType.retail => ProductValidationCode.invalidRetailPrice,
      ProductPriceType.wholesale => ProductValidationCode.invalidWholesalePrice,
      ProductPriceType.cost => ProductValidationCode.invalidCostPrice,
    };
    ProductValidationIssue? relevantIssue;
    for (final issue in productValidator.validate(updated).issues) {
      if (issue.code == relevantCode) {
        relevantIssue = issue;
        break;
      }
    }
    if (relevantIssue != null) {
      return ProductPriceValidationResult.failure(
        ProductPriceValidationStatus.invalidPrice,
        relevantIssue.message,
      );
    }

    final warnings = policy.warningsFor(
      product: product,
      type: type,
      oldPrice: oldPrice,
      newPrice: value,
    );
    final difference = value - oldPrice;
    return ProductPriceValidationResult.success(
      oldPrice: oldPrice,
      newPrice: value,
      difference: difference,
      percentageChange: oldPrice == 0 ? null : (difference / oldPrice) * 100,
      risk: warnings.isEmpty
          ? ProductPriceUpdateRisk.medium
          : ProductPriceUpdateRisk.high,
      warnings: warnings,
    );
  }
}

String priceMutationProductFingerprintSource(Product product) {
  return [
    product.id,
    product.name,
    product.retailPrice,
    product.wholesalePrice,
    product.costPrice,
  ].join(':');
}
