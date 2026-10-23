import '../../models/mikiezy_models.dart';
import '../models/product_unit.dart';

class UnitNormalizer {
  const UnitNormalizer();

  static const Map<String, SaleUnit> builtInAliases = {
    'pcs': SaleUnit.pcs,
    'pc': SaleUnit.pcs,
    'piece': SaleUnit.pcs,
    'pieces': SaleUnit.pcs,
    'buah': SaleUnit.buah,
    'biji': SaleUnit.biji,
    'bungkus': SaleUnit.bungkus,
    'bks': SaleUnit.bungkus,
    'potong': SaleUnit.potong,
    'ptg': SaleUnit.potong,
    'porsi': SaleUnit.porsi,
    'gelas': SaleUnit.gelas,
    'botol': SaleUnit.botol,
    'btl': SaleUnit.botol,
    'cup': SaleUnit.cup,
    'cups': SaleUnit.cup,
    'tusuk': SaleUnit.tusuk,
    'kotak': SaleUnit.kotak,
    'box': SaleUnit.carton,
    'sachet': SaleUnit.sachet,
    'saset': SaleUnit.sachet,
    'sac': SaleUnit.sachet,
    'kilo': SaleUnit.kilo,
    'kg': SaleUnit.kilo,
    'kilogram': SaleUnit.kilo,
    'gram': SaleUnit.gram,
    'gr': SaleUnit.gram,
    'g': SaleUnit.gram,
    'ons': SaleUnit.ons,
    'liter': SaleUnit.liter,
    'ltr': SaleUnit.liter,
    'lt': SaleUnit.liter,
    'l': SaleUnit.liter,
    'ml': SaleUnit.ml,
    'mili': SaleUnit.ml,
    'mililiter': SaleUnit.ml,
    'milliliter': SaleUnit.ml,
    'meter': SaleUnit.meter,
    'm': SaleUnit.meter,
    'sentimeter': SaleUnit.centimeter,
    'centimeter': SaleUnit.centimeter,
    'cm': SaleUnit.centimeter,
    'karton': SaleUnit.carton,
    'carton': SaleUnit.carton,
    'dus': SaleUnit.carton,
    'kardus': SaleUnit.carton,
    'pack': SaleUnit.pack,
    'pak': SaleUnit.pack,
    'renteng': SaleUnit.renteng,
    'ikat': SaleUnit.ikat,
    'ekor': SaleUnit.ekor,
    'lembar': SaleUnit.lembar,
    'plastik': SaleUnit.plastik,
    'mangkok': SaleUnit.mangkok,
    'mangkuk': SaleUnit.mangkok,
    'piring': SaleUnit.piring,
  };

  UnitNormalizationResult normalize(
    String? value, {
    List<VoiceUnitAlias> learnedAliases = const [],
  }) {
    final raw = value?.trim() ?? '';
    final normalized = normalizeText(raw);
    if (normalized.isEmpty) return UnitNormalizationResult.unknown(raw);

    VoiceUnitAlias? bestLearnedAlias;
    for (final alias in learnedAliases) {
      if (normalizeText(alias.normalizedAlias) != normalized) continue;
      if (bestLearnedAlias == null ||
          alias.hitCount > bestLearnedAlias.hitCount) {
        bestLearnedAlias = alias;
      }
    }
    if (bestLearnedAlias != null) {
      final learnedUnit = unitFromCanonical(bestLearnedAlias.canonicalUnit);
      if (learnedUnit != null) {
        return UnitNormalizationResult.recognized(
          rawValue: raw,
          unit: learnedUnit,
          matchedAlias: bestLearnedAlias.aliasText,
        );
      }
    }

    final builtIn = builtInAliases[normalized] ?? unitFromCanonical(normalized);
    if (builtIn == null) return UnitNormalizationResult.unknown(raw);
    return UnitNormalizationResult.recognized(
      rawValue: raw,
      unit: builtIn,
      matchedAlias: normalized,
    );
  }

  SaleUnit? unitFromCanonical(String? value) {
    final normalized = normalizeText(value ?? '');
    final alias = builtInAliases[normalized];
    if (alias != null) return alias;
    for (final unit in SaleUnit.values) {
      if (unit.name == normalized || normalizeText(unit.label) == normalized) {
        return unit;
      }
    }
    return null;
  }

  static String normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
