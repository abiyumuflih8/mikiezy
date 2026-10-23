class VoiceProductNameNormalizer {
  const VoiceProductNameNormalizer();

  String normalize(String value) {
    var normalized = value.toLowerCase();
    normalized = normalized.replaceAllMapped(
      RegExp(r'(\d)[,.](\d)'),
      (match) => '${match.group(1)}__decimal__${match.group(2)}',
    );
    normalized = normalized
        .replaceAll(RegExp(r"['`\u2018\u2019]"), ' ')
        .replaceAll(RegExp(r'[^a-z0-9_\s]+'), ' ')
        .replaceAll('__decimal__', '.')
        .replaceAll(RegExp(r'\b(mililiter|milliliter)\b'), 'ml')
        .replaceAll(RegExp(r'\b(ltr|lt)\b'), 'liter')
        .replaceAll(RegExp(r'\b(kilogram)\b'), 'kg')
        .replaceAll(RegExp(r'\b(gr)\b'), 'gram')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized;
  }

  String normalizeSpokenName(String value, {String? spokenUnit}) {
    var normalized = normalize(value);
    final unit = normalize(spokenUnit ?? '');
    if (unit.isEmpty || _measurementUnits.contains(unit)) return normalized;

    normalized = normalized
        .replaceFirst(
          RegExp('(?:^| )\\d+(?:\\.\\d+)?\\s+${RegExp.escape(unit)}\$'),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized;
  }

  String measurementSignature(String normalizedName) {
    final normalized = normalize(normalizedName);
    final matches = _measurementPattern.allMatches(normalized);
    return matches
        .map(
          (match) => '${match.group(1)} ${_canonicalMeasure(match.group(2)!)}',
        )
        .join('|');
  }

  String withoutMeasurementSize(String normalizedName) {
    return normalize(normalizedName)
        .replaceAll(_measurementPattern, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static final RegExp _measurementPattern = RegExp(
    r'\b(\d+(?:\.\d+)?)\s*(ml|liter|l|gram|g|kg|kilo)\b',
  );

  static const Set<String> _measurementUnits = {
    'ml',
    'liter',
    'l',
    'gram',
    'g',
    'kg',
    'kilo',
  };

  String _canonicalMeasure(String unit) {
    return switch (unit) {
      'l' => 'liter',
      'g' => 'gram',
      'kilo' => 'kg',
      _ => unit,
    };
  }
}
