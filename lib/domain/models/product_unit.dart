import '../../models/mikiezy_models.dart';

enum UnitDimension { count, weight, volume, length, packaging, custom }

enum UnitNormalizationStatus { recognized, unknown }

class UnitNormalizationResult {
  const UnitNormalizationResult._({
    required this.status,
    required this.rawValue,
    this.unit,
    this.matchedAlias,
  });

  const UnitNormalizationResult.recognized({
    required String rawValue,
    required SaleUnit unit,
    required String matchedAlias,
  }) : this._(
         status: UnitNormalizationStatus.recognized,
         rawValue: rawValue,
         unit: unit,
         matchedAlias: matchedAlias,
       );

  const UnitNormalizationResult.unknown(String rawValue)
    : this._(status: UnitNormalizationStatus.unknown, rawValue: rawValue);

  final UnitNormalizationStatus status;
  final String rawValue;
  final SaleUnit? unit;
  final String? matchedAlias;

  bool get isRecognized => status == UnitNormalizationStatus.recognized;
}

enum UnitConversionStatus {
  success,
  invalidQuantity,
  incompatibleDimension,
  packagingSizeMissing,
}

class NormalizedQuantity {
  const NormalizedQuantity({
    required this.originalQuantity,
    required this.originalUnit,
    required this.baseQuantity,
    required this.baseUnit,
    required this.multiplier,
  });

  final double originalQuantity;
  final SaleUnit originalUnit;
  final double baseQuantity;
  final SaleUnit baseUnit;
  final double multiplier;
}

class UnitConversionResult {
  const UnitConversionResult._({
    required this.status,
    this.quantity,
    this.message,
  });

  const UnitConversionResult.success(NormalizedQuantity quantity)
    : this._(status: UnitConversionStatus.success, quantity: quantity);

  const UnitConversionResult.failure(
    UnitConversionStatus status,
    String message,
  ) : this._(status: status, message: message);

  final UnitConversionStatus status;
  final NormalizedQuantity? quantity;
  final String? message;

  bool get isSuccess => status == UnitConversionStatus.success;
}

extension SaleUnitDomainX on SaleUnit {
  UnitDimension get dimension => switch (this) {
    SaleUnit.kilo || SaleUnit.gram || SaleUnit.ons => UnitDimension.weight,
    SaleUnit.liter || SaleUnit.ml => UnitDimension.volume,
    SaleUnit.meter || SaleUnit.centimeter => UnitDimension.length,
    SaleUnit.pack || SaleUnit.carton => UnitDimension.packaging,
    SaleUnit.pcs || SaleUnit.buah || SaleUnit.biji => UnitDimension.count,
    _ => UnitDimension.custom,
  };

  bool get isPackaging => dimension == UnitDimension.packaging;

  bool get isGenericCount =>
      this == SaleUnit.pcs || this == SaleUnit.buah || this == SaleUnit.biji;

  bool get isDiscreteCount => switch (this) {
    SaleUnit.pcs ||
    SaleUnit.buah ||
    SaleUnit.biji ||
    SaleUnit.bungkus ||
    SaleUnit.potong ||
    SaleUnit.porsi ||
    SaleUnit.gelas ||
    SaleUnit.botol ||
    SaleUnit.cup ||
    SaleUnit.tusuk ||
    SaleUnit.kotak ||
    SaleUnit.sachet ||
    SaleUnit.ekor ||
    SaleUnit.lembar ||
    SaleUnit.plastik ||
    SaleUnit.mangkok ||
    SaleUnit.piring => true,
    _ => false,
  };
}
