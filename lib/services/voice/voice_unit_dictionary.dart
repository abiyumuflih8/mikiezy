import '../../domain/services/unit_normalizer.dart';
import '../../models/mikiezy_models.dart';

class VoiceUnitDictionary {
  const VoiceUnitDictionary._();

  static const UnitNormalizer _normalizer = UnitNormalizer();

  static final Map<String, String> defaultAliases = Map.unmodifiable({
    for (final entry in UnitNormalizer.builtInAliases.entries)
      entry.key: entry.value.label,
  });

  static String? canonicalUnit(
    String value, {
    List<VoiceUnitAlias> aliases = const [],
  }) {
    final result = _normalizer.normalize(value, learnedAliases: aliases);
    return result.unit?.label;
  }

  static SaleUnit? saleUnitFor(String? value) {
    return _normalizer.normalize(value).unit;
  }

  static String normalize(String value) => UnitNormalizer.normalizeText(value);
}
