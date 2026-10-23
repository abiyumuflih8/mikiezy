import '../../domain/models/product_price.dart';
import 'indonesian_number_parser.dart';
import 'money_parser.dart';
import 'voice_command.dart';

class VoicePriceUpdateEntityExtractor {
  const VoicePriceUpdateEntityExtractor({
    this.moneyParser = const MoneyParser(),
    this.numberParser = const IndonesianNumberParser(),
  });

  final MoneyParser moneyParser;
  final IndonesianNumberParser numberParser;

  VoiceCommandEntities extract(String normalizedText) {
    return VoiceCommandEntities(
      productName: extractProductName(normalizedText),
      productPriceType: extractPriceType(normalizedText),
      newProductPrice: extractNewPrice(normalizedText),
      bulkPriceUpdateRequested: isBulkRequest(normalizedText),
    );
  }

  ProductPriceType? extractPriceType(String text) {
    if (RegExp(
      r'\b(?:harga\s+(?:grosir|kulakan)|grosir|kulakan)\b',
    ).hasMatch(text)) {
      return ProductPriceType.wholesale;
    }
    if (RegExp(r'\b(?:harga\s+(?:modal|beli)|modal)\b').hasMatch(text)) {
      return ProductPriceType.cost;
    }
    if (RegExp(
      r'\b(?:harga\s+(?:jual|retail)|harga\s+jualnya|retail)\b',
    ).hasMatch(text)) {
      return ProductPriceType.retail;
    }
    if (RegExp(r'\bharga\b').hasMatch(text)) {
      return ProductPriceType.retail;
    }
    return null;
  }

  int? extractNewPrice(String text) {
    final transitionMatches = _priceTransition.allMatches(text).toList();
    String segment;
    if (transitionMatches.isNotEmpty) {
      segment = text.substring(transitionMatches.last.end).trim();
    } else {
      final marker = _priceMarker.firstMatch(text);
      segment = marker == null ? text : text.substring(marker.end).trim();
    }
    return parsePrice(segment);
  }

  int? parsePrice(String text) {
    final normalized = text.toLowerCase().trim();
    if (normalized.isEmpty) return null;
    final negative = RegExp(
      r'(?:^|\s)(?:minus|negatif)\s+|(?:^|\s)-\s*\d',
    ).hasMatch(normalized);
    final positiveText = normalized
        .replaceFirst(RegExp(r'^(?:minus|negatif)\s+'), '')
        .replaceFirst(RegExp(r'^-\s*'), '');

    final moneyCandidates = moneyParser.parseAll(positiveText);
    if (moneyCandidates.isNotEmpty) {
      final value = moneyCandidates.last.amount;
      return negative ? -value : value;
    }

    final tokens = _tokens(positiveText);
    ParsedNumber? last;
    for (var index = 0; index < tokens.length; index++) {
      final parsed = numberParser.parseAt(tokens, index);
      if (parsed == null) continue;
      final nextIndex = index + parsed.consumedTokens;
      if (nextIndex < tokens.length &&
          _measurementUnits.contains(tokens[nextIndex])) {
        index = nextIndex;
        continue;
      }
      last = parsed;
      index += parsed.consumedTokens - 1;
    }
    if (last == null || !last.value.isFinite || last.value % 1 != 0) {
      return null;
    }
    final value = last.value.toInt();
    return negative ? -value : value;
  }

  String? extractProductName(String text) {
    var head = text.toLowerCase().trim();
    final transition = _priceTransition.firstMatch(head);
    if (transition != null) head = head.substring(0, transition.start).trim();

    final marker = _priceMarker.firstMatch(head);
    if (marker == null) return _cleanProductName(head);

    final beforeMarker = _cleanProductName(head.substring(0, marker.start));
    if (beforeMarker != null && !_onlyCommandWords(beforeMarker)) {
      return beforeMarker;
    }

    var candidate = head.substring(marker.end).trim();
    candidate = candidate
        .replaceFirst(RegExp(r'^(?:produk|barang)\s+'), '')
        .replaceAll(RegExp(r'\b(?:ubah|ganti|update|setel|sekarang)\b.*$'), ' ')
        .replaceAll(
          RegExp(
            r'\b(?:dari|harga\s+lama)\s+(?:minus\s+|-\s*)?(?:\d[\d.,]*|nol|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|sepuluh|sebelas|seratus|seribu).*$',
          ),
          ' ',
        );
    return _cleanProductName(candidate);
  }

  bool isBulkRequest(String text) {
    if (RegExp(
      r'\b(?:semua|seluruh|banyak|setiap|tiap)\s+(?:harga|produk|barang|minuman|makanan)\b|\b(?:harga|produk|barang)\s+(?:semua|seluruh)\b|\bmassal\b|\bbulk\b',
    ).hasMatch(text)) {
      return true;
    }
    if (_priceTransition.allMatches(text).length > 1) return true;

    final requestedTypes = <ProductPriceType>{
      if (RegExp(
        r'\b(?:harga\s+(?:jual|retail)|harga\s+jualnya|retail)\b',
      ).hasMatch(text))
        ProductPriceType.retail,
      if (RegExp(
        r'\b(?:harga\s+(?:grosir|kulakan)|grosir|kulakan)\b',
      ).hasMatch(text))
        ProductPriceType.wholesale,
      if (RegExp(r'\b(?:harga\s+(?:modal|beli)|modal)\b').hasMatch(text))
        ProductPriceType.cost,
    };
    return requestedTypes.length > 1;
  }

  bool _onlyCommandWords(String value) {
    final cleaned = value
        .replaceAll(
          RegExp(r'\b(?:tolong|ubah|ganti|update|setel|harga|produk|barang)\b'),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty;
  }

  String? _cleanProductName(String value) {
    final cleaned = value
        .replaceAll(
          RegExp(r'^(?:tolong\s+)?(?:ubah|ganti|update|setel)\s+'),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  List<String> _tokens(String text) {
    return text
        .replaceAll(RegExp(r'[^a-z0-9.,\s-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  static final RegExp _priceMarker = RegExp(
    r'\b(?:harga\s+jualnya|harga\s+(?:jual|retail|grosir|kulakan|modal|beli)|harga|retail|grosir|kulakan|modal)\b',
  );

  static final RegExp _priceTransition = RegExp(
    r'\b(?:ubah\s+)?(?:menjadi|jadi|ke|sebesar|sekarang)\b',
  );

  static const _measurementUnits = {
    'ml',
    'liter',
    'kg',
    'kilo',
    'kilogram',
    'gram',
    'ons',
    'meter',
    'cm',
    'centimeter',
    'pcs',
    'buah',
    'botol',
    'gelas',
    'pack',
    'karton',
  };
}
