import '../../models/mikiezy_models.dart';
import '../models/product_unit.dart';
import 'quantity_formatter.dart';
import 'unit_conversion_service.dart';

enum StockIncrementCalculationStatus {
  success,
  invalidQuantity,
  incompatibleUnit,
  missingPackSize,
  missingCartonSize,
  trackingConfirmationRequired,
}

class StockIncrementCalculation {
  const StockIncrementCalculation._({
    required this.status,
    this.requestedQuantity,
    this.requestedUnit,
    this.normalizedQuantity,
    this.baseUnit,
    this.stockBefore,
    this.stockAfter,
    this.multiplier,
    this.enableTracking = false,
    this.risk = VoiceStockIncrementRisk.medium,
    this.message,
  });

  const StockIncrementCalculation.success({
    required double requestedQuantity,
    required SaleUnit requestedUnit,
    required double normalizedQuantity,
    required SaleUnit baseUnit,
    required double stockBefore,
    required double stockAfter,
    required double multiplier,
    required bool enableTracking,
    required VoiceStockIncrementRisk risk,
  }) : this._(
         status: StockIncrementCalculationStatus.success,
         requestedQuantity: requestedQuantity,
         requestedUnit: requestedUnit,
         normalizedQuantity: normalizedQuantity,
         baseUnit: baseUnit,
         stockBefore: stockBefore,
         stockAfter: stockAfter,
         multiplier: multiplier,
         enableTracking: enableTracking,
         risk: risk,
       );

  const StockIncrementCalculation.failure(
    StockIncrementCalculationStatus status,
    String message,
  ) : this._(status: status, message: message);

  final StockIncrementCalculationStatus status;
  final double? requestedQuantity;
  final SaleUnit? requestedUnit;
  final double? normalizedQuantity;
  final SaleUnit? baseUnit;
  final double? stockBefore;
  final double? stockAfter;
  final double? multiplier;
  final bool enableTracking;
  final VoiceStockIncrementRisk risk;
  final String? message;

  bool get isSuccess => status == StockIncrementCalculationStatus.success;
}

enum VoiceStockIncrementRisk { medium, high }

class StockIncrementPolicy {
  const StockIncrementPolicy({
    this.largeIncrementThreshold = 100000,
    this.largePackagingIncrementThreshold = 10000,
  });

  final double largeIncrementThreshold;
  final double largePackagingIncrementThreshold;

  VoiceStockIncrementRisk riskFor({
    required Product product,
    required SaleUnit requestedUnit,
    required double normalizedIncrement,
    required bool enableTracking,
  }) {
    final sensitiveFraction =
        product.baseUnit.isDiscreteCount &&
        product.stockPcs != product.stockPcs.roundToDouble();
    final largePackaging =
        requestedUnit.isPackaging &&
        normalizedIncrement >= largePackagingIncrementThreshold;
    if (enableTracking ||
        sensitiveFraction ||
        largePackaging ||
        normalizedIncrement >= largeIncrementThreshold) {
      return VoiceStockIncrementRisk.high;
    }
    return VoiceStockIncrementRisk.medium;
  }
}

class StockIncrementCalculator {
  const StockIncrementCalculator({
    this.conversionService = const UnitConversionService(),
    this.policy = const StockIncrementPolicy(),
  });

  final UnitConversionService conversionService;
  final StockIncrementPolicy policy;

  StockIncrementCalculation calculate({
    required Product product,
    required double requestedQuantity,
    required SaleUnit requestedUnit,
    required bool trackingEnableConfirmed,
  }) {
    if (!requestedQuantity.isFinite || requestedQuantity <= 0) {
      return const StockIncrementCalculation.failure(
        StockIncrementCalculationStatus.invalidQuantity,
        'Jumlah stok harus lebih besar dari nol.',
      );
    }

    final enableTracking = !product.trackStock && trackingEnableConfirmed;
    final targetBaseUnit = _targetBaseUnit(
      product: product,
      requestedUnit: requestedUnit,
      enableTracking: enableTracking,
    );
    final conversionProduct = targetBaseUnit == product.baseUnit
        ? product
        : product.copyWith(baseUnit: targetBaseUnit);
    final conversion = conversionService.convert(
      quantity: requestedQuantity,
      from: requestedUnit,
      to: targetBaseUnit,
      product: conversionProduct,
    );
    if (!conversion.isSuccess) {
      return _conversionFailure(
        conversion,
        requestedUnit: requestedUnit,
        product: product,
      );
    }
    if (!product.trackStock && !trackingEnableConfirmed) {
      return StockIncrementCalculation.failure(
        StockIncrementCalculationStatus.trackingConfirmationRequired,
        'Stok ${product.name} saat ini tidak dilacak.',
      );
    }

    final normalizedIncrement = QuantityFormatter.normalize(
      conversion.quantity!.baseQuantity,
    );
    if (!normalizedIncrement.isFinite || normalizedIncrement <= 0) {
      return const StockIncrementCalculation.failure(
        StockIncrementCalculationStatus.invalidQuantity,
        'Jumlah stok setelah konversi tidak valid.',
      );
    }
    final stockBefore = QuantityFormatter.normalize(product.stockPcs);
    final stockAfter = QuantityFormatter.normalize(
      stockBefore + normalizedIncrement,
    );
    if (!stockAfter.isFinite || stockAfter < stockBefore) {
      return const StockIncrementCalculation.failure(
        StockIncrementCalculationStatus.invalidQuantity,
        'Jumlah stok terlalu besar untuk diproses dengan aman.',
      );
    }

    return StockIncrementCalculation.success(
      requestedQuantity: QuantityFormatter.normalize(requestedQuantity),
      requestedUnit: requestedUnit,
      normalizedQuantity: normalizedIncrement,
      baseUnit: targetBaseUnit,
      stockBefore: stockBefore,
      stockAfter: stockAfter,
      multiplier: conversion.quantity!.multiplier,
      enableTracking: enableTracking,
      risk: policy.riskFor(
        product: product,
        requestedUnit: requestedUnit,
        normalizedIncrement: normalizedIncrement,
        enableTracking: enableTracking,
      ),
    );
  }

  SaleUnit _targetBaseUnit({
    required Product product,
    required SaleUnit requestedUnit,
    required bool enableTracking,
  }) {
    final canAdoptRequestedUnit =
        enableTracking &&
        product.stockPcs == 0 &&
        product.baseUnit == SaleUnit.pcs &&
        !requestedUnit.isPackaging;
    return canAdoptRequestedUnit ? requestedUnit : product.baseUnit;
  }

  StockIncrementCalculation _conversionFailure(
    UnitConversionResult result, {
    required SaleUnit requestedUnit,
    required Product product,
  }) {
    if (result.status == UnitConversionStatus.packagingSizeMissing) {
      final missingPack = requestedUnit == SaleUnit.pack;
      return StockIncrementCalculation.failure(
        missingPack
            ? StockIncrementCalculationStatus.missingPackSize
            : StockIncrementCalculationStatus.missingCartonSize,
        result.message ??
            'Ukuran ${missingPack ? 'pack' : 'karton'} belum diatur.',
      );
    }
    return StockIncrementCalculation.failure(
      StockIncrementCalculationStatus.incompatibleUnit,
      result.message ??
          'Satuan ${requestedUnit.label} tidak kompatibel dengan ${product.baseUnit.label}.',
    );
  }
}

String stockMutationProductFingerprintSource(Product product) {
  return [
    product.id,
    product.name,
    product.category,
    product.costPrice,
    product.retailPrice,
    product.wholesalePrice,
    product.packSize,
    product.cartonSize,
    QuantityFormatter.label(product.stockPcs),
    product.trackStock,
    product.baseUnit.name,
    QuantityFormatter.label(product.minStock),
  ].join(':');
}
