import '../../domain/services/unit_normalizer.dart';
import '../../models/mikiezy_models.dart';
import 'indonesian_number_parser.dart';
import 'voice_command.dart';

class VoiceStockIncrementEntityExtractor {
  const VoiceStockIncrementEntityExtractor({
    this.numberParser = const IndonesianNumberParser(),
    this.unitNormalizer = const UnitNormalizer(),
  });

  final IndonesianNumberParser numberParser;
  final UnitNormalizer unitNormalizer;

  VoiceCommandEntities extract(
    String normalizedText, {
    List<VoiceUnitAlias> unitAliases = const [],
  }) {
    final tokens = _tokens(normalizedText);
    final spoken = _findQuantityAndUnit(tokens, unitAliases);
    final productName = _productName(tokens, spoken);
    return VoiceCommandEntities(
      productName: productName,
      quantity: spoken?.quantity,
      unit: spoken?.canonicalUnit?.name ?? spoken?.rawUnit,
    );
  }

  double? parseQuantity(String value) {
    final tokens = _tokens(value);
    final match = _findLastQuantity(tokens);
    return match?.quantity;
  }

  SaleUnit? parseUnit(
    String value, {
    List<VoiceUnitAlias> unitAliases = const [],
  }) {
    final tokens = _tokens(value);
    final match = _findLastUnit(tokens, unitAliases);
    return match?.canonicalUnit;
  }

  _SpokenStockValue? _findQuantityAndUnit(
    List<String> tokens,
    List<VoiceUnitAlias> aliases,
  ) {
    final unitMatch = _findLastUnit(tokens, aliases);
    if (unitMatch != null) {
      final quantityMatch = _quantityEndingAt(tokens, unitMatch.start);
      return _SpokenStockValue(
        quantity: quantityMatch?.quantity,
        canonicalUnit: unitMatch.canonicalUnit,
        rawUnit: unitMatch.rawUnit,
        start: quantityMatch?.start ?? unitMatch.start,
        end: unitMatch.end,
      );
    }

    final quantityMatch = _findLastQuantity(tokens);
    if (quantityMatch == null) return null;
    final possibleUnitIndex = quantityMatch.end;
    final hasUnknownUnit =
        possibleUnitIndex < tokens.length &&
        !_isStructuralToken(tokens[possibleUnitIndex]);
    return _SpokenStockValue(
      quantity: quantityMatch.quantity,
      rawUnit: hasUnknownUnit ? tokens[possibleUnitIndex] : null,
      start: quantityMatch.start,
      end: hasUnknownUnit ? possibleUnitIndex + 1 : quantityMatch.end,
    );
  }

  _UnitTokenMatch? _findLastUnit(
    List<String> tokens,
    List<VoiceUnitAlias> aliases,
  ) {
    _UnitTokenMatch? latest;
    for (var start = 0; start < tokens.length; start++) {
      for (var length = 3; length >= 1; length--) {
        final end = start + length;
        if (end > tokens.length) continue;
        final raw = tokens.sublist(start, end).join(' ');
        final normalized = unitNormalizer.normalize(
          raw,
          learnedAliases: aliases,
        );
        if (!normalized.isRecognized) continue;
        final candidate = _UnitTokenMatch(
          canonicalUnit: normalized.unit!,
          rawUnit: raw,
          start: start,
          end: end,
        );
        if (latest == null ||
            candidate.end > latest.end ||
            (candidate.end == latest.end && candidate.start < latest.start)) {
          latest = candidate;
        }
        break;
      }
    }
    return latest;
  }

  _QuantityTokenMatch? _quantityEndingAt(List<String> tokens, int end) {
    _QuantityTokenMatch? best;
    final minimum = (end - 8).clamp(0, end);
    for (var start = minimum; start < end; start++) {
      final quantity = _parseQuantityPhrase(tokens.sublist(start, end));
      if (quantity == null) continue;
      best = _QuantityTokenMatch(quantity: quantity, start: start, end: end);
      break;
    }
    return best;
  }

  _QuantityTokenMatch? _findLastQuantity(List<String> tokens) {
    _QuantityTokenMatch? latest;
    for (var end = 1; end <= tokens.length; end++) {
      final minimum = (end - 8).clamp(0, end);
      for (var start = minimum; start < end; start++) {
        final quantity = _parseQuantityPhrase(tokens.sublist(start, end));
        if (quantity == null) continue;
        latest = _QuantityTokenMatch(
          quantity: quantity,
          start: start,
          end: end,
        );
        break;
      }
    }
    return latest;
  }

  double? _parseQuantityPhrase(List<String> phrase) {
    if (phrase.isEmpty) return null;
    if (phrase.length == 1) {
      if (phrase.single == 'seperempat') return 0.25;
      final parsed = numberParser.parseAt(phrase, 0);
      if (parsed != null && parsed.consumedTokens == 1) return parsed.value;
      return null;
    }
    final fractionToken = phrase.last;
    if (fractionToken == 'setengah' || fractionToken == 'seperempat') {
      final wholePhrase = phrase.sublist(0, phrase.length - 1);
      final whole = numberParser.parseAt(wholePhrase, 0);
      if (whole != null && whole.consumedTokens == wholePhrase.length) {
        return whole.value + (fractionToken == 'setengah' ? 0.5 : 0.25);
      }
    }
    final parsed = numberParser.parseAt(phrase, 0);
    if (parsed != null && parsed.consumedTokens == phrase.length) {
      return parsed.value;
    }
    return null;
  }

  String? _productName(List<String> tokens, _SpokenStockValue? spoken) {
    final retained = <String>[];
    for (var index = 0; index < tokens.length; index++) {
      final belongsToValue =
          spoken != null && index >= spoken.start && index < spoken.end;
      if (!belongsToValue) retained.add(tokens[index]);
    }
    var candidate = retained.join(' ');
    candidate = candidate
        .replaceAll(
          RegExp(
            r'^(?:tolong\s+)?(?:tambah(?:kan)?|restok|re[\s-]?stok|masukkan)\b',
          ),
          ' ',
        )
        .replaceAll(RegExp(r'^stok(?:nya)?\b'), ' ')
        .replaceAll(
          RegExp(
            r'\b(?:di)?tambah(?:kan)?\s+stok(?:nya)?\b|\bstok(?:nya)?\s+(?:di)?tambah(?:kan)?\b',
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\b(?:ke|dalam)\s+stok\b|\bstok(?:nya)?\b'), ' ')
        .replaceAll(RegExp(r'\b(?:ditambah|tambahkan|tambah|masukkan)\b'), ' ')
        .replaceAll(RegExp(r'\b(?:ke|dalam)\b$'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return candidate.isEmpty ? null : candidate;
  }

  List<String> _tokens(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9.,\s-]+'), ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  bool _isStructuralToken(String token) {
    return const {
      'ke',
      'dalam',
      'stok',
      'stock',
      'ditambah',
      'tambahkan',
      'tambah',
    }.contains(token);
  }
}

class _SpokenStockValue {
  const _SpokenStockValue({
    this.quantity,
    this.canonicalUnit,
    this.rawUnit,
    required this.start,
    required this.end,
  });

  final double? quantity;
  final SaleUnit? canonicalUnit;
  final String? rawUnit;
  final int start;
  final int end;
}

class _UnitTokenMatch {
  const _UnitTokenMatch({
    required this.canonicalUnit,
    required this.rawUnit,
    required this.start,
    required this.end,
  });

  final SaleUnit canonicalUnit;
  final String rawUnit;
  final int start;
  final int end;
}

class _QuantityTokenMatch {
  const _QuantityTokenMatch({
    required this.quantity,
    required this.start,
    required this.end,
  });

  final double quantity;
  final int start;
  final int end;
}
