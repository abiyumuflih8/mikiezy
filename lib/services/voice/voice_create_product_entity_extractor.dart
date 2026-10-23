import '../../domain/services/unit_normalizer.dart';
import '../../models/mikiezy_models.dart';
import 'indonesian_number_parser.dart';
import 'money_parser.dart';
import 'voice_command.dart';

class VoiceCreateProductEntityExtractor {
  const VoiceCreateProductEntityExtractor({
    this.moneyParser = const MoneyParser(),
    this.numberParser = const IndonesianNumberParser(),
    this.unitNormalizer = const UnitNormalizer(),
  });

  final MoneyParser moneyParser;
  final IndonesianNumberParser numberParser;
  final UnitNormalizer unitNormalizer;

  VoiceCommandEntities extract(
    String normalizedText, {
    List<VoiceUnitAlias> unitAliases = const [],
  }) {
    final stockSegment = _segmentAfter(
      normalizedText,
      RegExp(r'\bstok(?:\s+awal)?\b(?!\s+minimum)'),
    );
    final stockValue = _firstNumber(stockSegment);
    final stockUnit = _unitAfterNumber(stockSegment, unitAliases: unitAliases);
    return VoiceCommandEntities(
      salePrice: _moneyAfter(
        normalizedText,
        RegExp(r'\bharga(?:\s+(?:jual|retail))?\b(?!\s+(?:modal|beli|grosir))'),
      ),
      costPrice: _moneyAfter(
        normalizedText,
        RegExp(r'\b(?:harga\s+(?:modal|beli)|modal)\b'),
      ),
      wholesalePrice: _moneyAfter(
        normalizedText,
        RegExp(r'\b(?:harga\s+grosir|grosir)\b'),
      ),
      stock: stockValue,
      unit: stockUnit,
      trackStock: _trackStock(normalizedText, stockValue),
      minStock: _numberAfter(
        normalizedText,
        RegExp(r'\b(?:stok\s+minimum|minimal\s+stok|min\s+stok)\b'),
      ),
      categoryName: _textAfter(normalizedText, RegExp(r'\bkategori\b')),
      packSize: _wholeNumberAfter(
        normalizedText,
        RegExp(r'\b(?:isi|ukuran)\s+pack\b|\bpack\s+size\b'),
      ),
      cartonSize: _wholeNumberAfter(
        normalizedText,
        RegExp(r'\b(?:isi|ukuran)\s+(?:karton|kardus)\b|\bcarton\s+size\b'),
      ),
    );
  }

  bool? _trackStock(String text, double? stock) {
    if (RegExp(
      r'\b(?:tanpa\s+stok|stok\s+tidak\s+dilacak|jangan\s+lacak\s+stok|tidak\s+perlu\s+(?:lacak|melacak)\s+stok)\b',
    ).hasMatch(text)) {
      return false;
    }
    if (stock != null ||
        RegExp(r'\b(?:lacak\s+stok|pakai\s+stok)\b').hasMatch(text)) {
      return true;
    }
    return null;
  }

  int? _moneyAfter(String text, RegExp marker) {
    final segment = _segmentAfter(text, marker);
    if (segment == null) return null;
    final candidates = moneyParser.parseAll(segment);
    return candidates.isEmpty ? null : candidates.first.amount;
  }

  double? _numberAfter(String text, RegExp marker) {
    return _firstNumber(_segmentAfter(text, marker));
  }

  int? _wholeNumberAfter(String text, RegExp marker) {
    final value = _numberAfter(text, marker);
    if (value == null || value % 1 != 0) return null;
    return value.toInt();
  }

  String? _textAfter(String text, RegExp marker) {
    final segment = _segmentAfter(text, marker);
    if (segment == null) return null;
    final cleaned = segment
        .replaceAll(RegExp(r'^(?:adalah|yaitu)\s+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  double? _firstNumber(String? segment) {
    if (segment == null) return null;
    final tokens = _tokens(segment);
    for (var index = 0; index < tokens.length; index++) {
      final parsed = numberParser.parseAt(tokens, index);
      if (parsed != null) return parsed.value;
    }
    return null;
  }

  String? _unitAfterNumber(
    String? segment, {
    required List<VoiceUnitAlias> unitAliases,
  }) {
    if (segment == null) return null;
    final tokens = _tokens(segment);
    for (var index = 0; index < tokens.length; index++) {
      final parsed = numberParser.parseAt(tokens, index);
      if (parsed == null) continue;
      final unitIndex = index + parsed.consumedTokens;
      if (unitIndex >= tokens.length) return null;
      final normalized = unitNormalizer.normalize(
        tokens[unitIndex],
        learnedAliases: unitAliases,
      );
      return normalized.isRecognized ? normalized.unit!.name : null;
    }
    return null;
  }

  String? _segmentAfter(String text, RegExp marker) {
    final match = marker.firstMatch(text);
    if (match == null) return null;
    final tail = text.substring(match.end).trim();
    if (tail.isEmpty) return null;
    final next = _fieldMarker.firstMatch(tail);
    return (next == null ? tail : tail.substring(0, next.start)).trim();
  }

  List<String> _tokens(String text) {
    return text
        .replaceAll(RegExp(r'[^a-z0-9.,\s-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  static final RegExp _fieldMarker = RegExp(
    r'\b(?:harga\s+(?:jual|retail|modal|beli|grosir)|harga|modal|grosir|stok\s+minimum|minimal\s+stok|min\s+stok|stok\s+awal|stok|kategori|(?:isi|ukuran)\s+pack|pack\s+size|(?:isi|ukuran)\s+(?:karton|kardus)|carton\s+size|tanpa\s+stok)\b',
  );
}
