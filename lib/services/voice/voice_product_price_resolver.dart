import '../../models/mikiezy_models.dart';
import '../../domain/services/quantity_formatter.dart';
import '../../domain/services/unit_conversion_service.dart';
import '../../domain/services/unit_normalizer.dart';
import 'parsed_transaction_item.dart';
import 'voice_product_resolver.dart';

enum VoicePriceSource {
  spoken,
  catalogRetail,
  catalogWholesale,
  catalogPack,
  catalogCarton,
  unavailable,
}

class VoicePriceResolution {
  const VoicePriceResolution({
    required this.source,
    required this.segment,
    required this.unit,
    required this.unitMultiplier,
    this.quantity,
    this.unitPrice,
    this.message,
  });

  final VoicePriceSource source;
  final PriceSegment segment;
  final SaleUnit unit;
  final double unitMultiplier;
  final double? quantity;
  final int? unitPrice;
  final String? message;

  bool get isAvailable => unitPrice != null && unitPrice! > 0;
}

class VoiceProductPriceResolver {
  const VoiceProductPriceResolver({
    this.unitNormalizer = const UnitNormalizer(),
    this.unitConversionService = const UnitConversionService(),
  });

  final UnitNormalizer unitNormalizer;
  final UnitConversionService unitConversionService;

  VoicePriceResolution resolve({
    required ParsedTransactionItem item,
    required VoiceProductMatchResult productMatch,
    bool allowCatalogPrice = true,
  }) {
    final product = productMatch.product;
    final normalizedUnit = item.unit == null
        ? null
        : unitNormalizer.normalize(item.unit);
    final unit = normalizedUnit?.unit ?? product?.baseUnit ?? SaleUnit.pcs;
    final wholesaleRequested = RegExp(
      r'\b(grosir|harga grosir)\b',
    ).hasMatch(item.rawText.toLowerCase());
    final segment = wholesaleRequested
        ? PriceSegment.wholesale
        : PriceSegment.retail;
    if (item.unit != null && normalizedUnit?.isRecognized != true) {
      return VoicePriceResolution(
        source: VoicePriceSource.unavailable,
        segment: segment,
        unit: unit,
        unitMultiplier: 1,
        quantity: item.quantity,
        message: 'Satuan "${item.unit}" belum dikenal.',
      );
    }

    var effectiveUnit = unit;
    var effectiveQuantity = item.quantity;
    var unitMultiplier = 1.0;
    if (product != null) {
      final conversion = unitConversionService.multiplier(
        from: unit,
        to: product.baseUnit,
        product: product,
      );
      if (!conversion.isSuccess) {
        return VoicePriceResolution(
          source: VoicePriceSource.unavailable,
          segment: segment,
          unit: unit,
          unitMultiplier: 1,
          quantity: item.quantity,
          message: conversion.message,
        );
      }
      unitMultiplier = conversion.quantity!.multiplier;
      if (unitMultiplier < 1 && effectiveQuantity != null) {
        effectiveQuantity = QuantityFormatter.normalize(
          effectiveQuantity * unitMultiplier,
        );
        effectiveUnit = product.baseUnit;
      }
    }

    final normalizedToBase = effectiveUnit == product?.baseUnit && unit != effectiveUnit;
    final effectiveMultiplier = normalizedToBase ? 1.0 : unitMultiplier;
    final explicitPrice = _explicitUnitPrice(
      item,
      effectiveQuantity: effectiveQuantity,
      sourceToEffectiveMultiplier: normalizedToBase ? unitMultiplier : 1,
    );
    if (explicitPrice != null && explicitPrice > 0) {
      return VoicePriceResolution(
        source: VoicePriceSource.spoken,
        segment: segment,
        unit: effectiveUnit,
        unitMultiplier: effectiveMultiplier,
        quantity: effectiveQuantity,
        unitPrice: explicitPrice,
      );
    }

    if (!allowCatalogPrice || !productMatch.isMatched || product == null) {
      return VoicePriceResolution(
        source: VoicePriceSource.unavailable,
        segment: segment,
        unit: effectiveUnit,
        unitMultiplier: 1,
        quantity: effectiveQuantity,
        message: 'Harga belum disebutkan dan belum bisa diambil dari katalog.',
      );
    }

    var basePrice = product.retailPrice;
    String? message;
    if (wholesaleRequested) {
      if (product.wholesalePrice > 0) {
        basePrice = product.wholesalePrice;
      } else if (product.retailPrice > 0) {
        basePrice = product.retailPrice;
        message =
            'Harga grosir ${product.name} belum diatur. Menggunakan harga eceran.';
      }
    }
    if (basePrice <= 0) {
      return VoicePriceResolution(
        source: VoicePriceSource.unavailable,
        segment: segment,
        unit: effectiveUnit,
        unitMultiplier: effectiveMultiplier,
        quantity: effectiveQuantity,
        message: 'Harga jual ${product.name} belum diatur.',
      );
    }

    if (unit == SaleUnit.pack) {
      return VoicePriceResolution(
        source: VoicePriceSource.catalogPack,
        segment: segment,
        unit: unit,
        unitMultiplier: unitMultiplier,
        quantity: effectiveQuantity,
        unitPrice: (basePrice * unitMultiplier).round(),
        message: message,
      );
    }
    if (unit == SaleUnit.carton) {
      return VoicePriceResolution(
        source: VoicePriceSource.catalogCarton,
        segment: segment,
        unit: unit,
        unitMultiplier: unitMultiplier,
        quantity: effectiveQuantity,
        unitPrice: (basePrice * unitMultiplier).round(),
        message: message,
      );
    }

    return VoicePriceResolution(
      source: wholesaleRequested
          ? VoicePriceSource.catalogWholesale
          : VoicePriceSource.catalogRetail,
      segment: segment,
      unit: effectiveUnit,
      unitMultiplier: effectiveMultiplier,
      quantity: effectiveQuantity,
      unitPrice: normalizedToBase
          ? basePrice
          : (basePrice * unitMultiplier).round(),
      message: message,
    );
  }

  int? _explicitUnitPrice(
    ParsedTransactionItem item, {
    required double? effectiveQuantity,
    required double sourceToEffectiveMultiplier,
  }) {
    final lineTotal = item.lineTotal;
    if (lineTotal != null &&
        lineTotal > 0 &&
        effectiveQuantity != null &&
        effectiveQuantity > 0) {
      return (lineTotal / effectiveQuantity).round();
    }
    final unitPrice = item.unitPrice;
    if (unitPrice != null && unitPrice > 0) {
      return (unitPrice / sourceToEffectiveMultiplier).round();
    }
    return null;
  }
}
