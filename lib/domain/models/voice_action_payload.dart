import '../../models/mikiezy_models.dart';
import 'product_price.dart';

sealed class VoiceActionPayload {
  const VoiceActionPayload();
}

final class CreateProductVoiceActionPayload extends VoiceActionPayload {
  const CreateProductVoiceActionPayload({
    required this.product,
    this.similarProductName,
    this.similarProductConfirmed = false,
  });

  final Product product;
  final String? similarProductName;
  final bool similarProductConfirmed;
}

final class IncrementStockVoiceActionPayload extends VoiceActionPayload {
  IncrementStockVoiceActionPayload({
    required this.actionId,
    required this.commandFingerprint,
    required this.productId,
    required this.spokenProductName,
    required this.productName,
    required this.requestedQuantity,
    required this.requestedUnit,
    required this.normalizedQuantity,
    required this.baseUnitBefore,
    required this.baseUnit,
    required this.stockBefore,
    required this.stockAfter,
    required this.trackStockBefore,
    required this.enableTracking,
    required this.productFingerprint,
    required this.packSize,
    required this.cartonSize,
    required this.multiplier,
    required this.minStock,
    this.wasClarified = false,
    List<String> validationErrors = const [],
  }) : validationErrors = List.unmodifiable(validationErrors);

  final String actionId;
  final String commandFingerprint;
  final String productId;
  final String spokenProductName;
  final String productName;
  final double requestedQuantity;
  final SaleUnit requestedUnit;
  final double normalizedQuantity;
  final SaleUnit baseUnitBefore;
  final SaleUnit baseUnit;
  final double stockBefore;
  final double stockAfter;
  final bool trackStockBefore;
  final bool enableTracking;
  final String productFingerprint;
  final int packSize;
  final int cartonSize;
  final double multiplier;
  final double minStock;
  final bool wasClarified;
  final List<String> validationErrors;
}

final class UpdateProductPriceVoiceActionPayload extends VoiceActionPayload {
  UpdateProductPriceVoiceActionPayload({
    required this.actionId,
    required this.commandFingerprint,
    required this.productId,
    required this.spokenProductName,
    required this.productName,
    required this.priceType,
    required this.oldPrice,
    required this.newPrice,
    required this.difference,
    required this.percentageChange,
    required this.retailPriceBefore,
    required this.wholesalePriceBefore,
    required this.costPriceBefore,
    required this.productFingerprint,
    required this.expectedProductFingerprintAfter,
    required this.risk,
    required this.requiresAdditionalConfirmation,
    required this.expiresAt,
    this.wasClarified = false,
    List<ProductPriceWarning> warnings = const [],
    List<String> validationErrors = const [],
  }) : warnings = List.unmodifiable(warnings),
       validationErrors = List.unmodifiable(validationErrors);

  final String actionId;
  final String commandFingerprint;
  final String productId;
  final String spokenProductName;
  final String productName;
  final ProductPriceType priceType;
  final int oldPrice;
  final int newPrice;
  final int difference;
  final double? percentageChange;
  final int retailPriceBefore;
  final int wholesalePriceBefore;
  final int costPriceBefore;
  final String productFingerprint;
  final String expectedProductFingerprintAfter;
  final ProductPriceUpdateRisk risk;
  final bool requiresAdditionalConfirmation;
  final DateTime expiresAt;
  final bool wasClarified;
  final List<ProductPriceWarning> warnings;
  final List<String> validationErrors;
}
