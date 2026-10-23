import '../../models/mikiezy_models.dart';
import '../models/product_unit.dart';
import 'quantity_formatter.dart';

class UnitConversionService {
  const UnitConversionService();

  UnitConversionResult convert({
    required double quantity,
    required SaleUnit from,
    required SaleUnit to,
    Product? product,
  }) {
    if (!quantity.isFinite || quantity <= 0) {
      return const UnitConversionResult.failure(
        UnitConversionStatus.invalidQuantity,
        'Jumlah harus lebih besar dari nol.',
      );
    }

    final multiplierResult = multiplier(from: from, to: to, product: product);
    if (!multiplierResult.isSuccess) return multiplierResult;
    final multiplierValue = multiplierResult.quantity!.multiplier;
    return UnitConversionResult.success(
      NormalizedQuantity(
        originalQuantity: QuantityFormatter.normalize(quantity),
        originalUnit: from,
        baseQuantity: QuantityFormatter.normalize(quantity * multiplierValue),
        baseUnit: to,
        multiplier: multiplierValue,
      ),
    );
  }

  UnitConversionResult multiplier({
    required SaleUnit from,
    required SaleUnit to,
    Product? product,
  }) {
    if (from == to) return _success(from, to, 1);

    if (from.isPackaging || to.isPackaging) {
      return _packagingMultiplier(from: from, to: to, product: product);
    }

    if ((from.isGenericCount && to.isDiscreteCount) ||
        (to.isGenericCount && from.isDiscreteCount)) {
      return _success(from, to, 1);
    }

    if (from.dimension != to.dimension) {
      return UnitConversionResult.failure(
        UnitConversionStatus.incompatibleDimension,
        'Satuan ${from.label} tidak kompatibel dengan ${to.label}.',
      );
    }

    final fromFactor = _factorToSmallestUnit(from);
    final toFactor = _factorToSmallestUnit(to);
    if (fromFactor == null || toFactor == null) {
      return UnitConversionResult.failure(
        UnitConversionStatus.incompatibleDimension,
        'Satuan ${from.label} hanya dapat digunakan dengan satuan dasar yang sama.',
      );
    }
    return _success(from, to, fromFactor / toFactor);
  }

  UnitConversionResult _packagingMultiplier({
    required SaleUnit from,
    required SaleUnit to,
    required Product? product,
  }) {
    if (product == null || (to != product.baseUnit && from != product.baseUnit)) {
      return UnitConversionResult.failure(
        UnitConversionStatus.incompatibleDimension,
        'Konversi kemasan membutuhkan satuan dasar produk.',
      );
    }

    final packagingUnit = from.isPackaging ? from : to;
    final size = switch (packagingUnit) {
      SaleUnit.pack => product.packSize,
      SaleUnit.carton => product.cartonSize,
      _ => 0,
    };
    if (size <= 0) {
      final label = packagingUnit == SaleUnit.pack ? 'pack' : 'karton';
      return UnitConversionResult.failure(
        UnitConversionStatus.packagingSizeMissing,
        'Ukuran $label ${product.name} belum diatur. Perbarui data produk sebelum menjual dalam satuan $label.',
      );
    }

    final multiplier = from.isPackaging ? size.toDouble() : 1 / size;
    return _success(from, to, multiplier);
  }

  double? _factorToSmallestUnit(SaleUnit unit) {
    return switch (unit) {
      SaleUnit.kilo => 1000,
      SaleUnit.gram => 1,
      SaleUnit.ons => 100,
      SaleUnit.liter => 1000,
      SaleUnit.ml => 1,
      SaleUnit.meter => 100,
      SaleUnit.centimeter => 1,
      _ => null,
    };
  }

  UnitConversionResult _success(
    SaleUnit from,
    SaleUnit to,
    double multiplier,
  ) {
    final normalizedMultiplier = QuantityFormatter.normalize(multiplier);
    return UnitConversionResult.success(
      NormalizedQuantity(
        originalQuantity: 1,
        originalUnit: from,
        baseQuantity: normalizedMultiplier,
        baseUnit: to,
        multiplier: normalizedMultiplier,
      ),
    );
  }
}

class UnitConversionException implements Exception {
  const UnitConversionException(this.result);

  final UnitConversionResult result;

  @override
  String toString() => result.message ?? 'Konversi satuan gagal.';
}
