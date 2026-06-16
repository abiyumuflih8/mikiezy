class ParsedNumber {
  const ParsedNumber({
    required this.value,
    required this.consumedTokens,
    required this.rawText,
  });

  final double value;
  final int consumedTokens;
  final String rawText;
}

class IndonesianNumberParser {
  const IndonesianNumberParser();

  static const _single = <String, int>{
    'nol': 0,
    'satu': 1,
    'se': 1,
    'sebuah': 1,
    'dua': 2,
    'tiga': 3,
    'empat': 4,
    'lima': 5,
    'enam': 6,
    'tujuh': 7,
    'delapan': 8,
    'sembilan': 9,
    'sepuluh': 10,
    'sebelas': 11,
  };

  ParsedNumber? parseAt(List<String> tokens, int start) {
    if (start >= tokens.length) return null;
    final token = tokens[start];
    final numeric = _parseNumericToken(token);
    if (numeric != null) {
      return ParsedNumber(value: numeric, consumedTokens: 1, rawText: token);
    }
    if (token == 'setengah' || token == 'separo') {
      return ParsedNumber(value: 0.5, consumedTokens: 1, rawText: token);
    }

    var bestValue = 0.0;
    var bestConsumed = 0;
    for (var end = start + 1; end <= tokens.length && end <= start + 8; end++) {
      final phrase = tokens.sublist(start, end);
      final parsed = parseWords(phrase);
      if (parsed != null) {
        bestValue = parsed;
        bestConsumed = end - start;
      }
    }
    if (bestConsumed == 0) return null;
    return ParsedNumber(
      value: bestValue,
      consumedTokens: bestConsumed,
      rawText: tokens.sublist(start, start + bestConsumed).join(' '),
    );
  }

  double? parseWords(List<String> words) {
    if (words.isEmpty) return null;
    final normalized = <String>[];
    for (final word in words) {
      switch (word) {
        case 'seratus':
          normalized.addAll(['se', 'ratus']);
        case 'seribu':
          normalized.addAll(['se', 'ribu']);
        case 'sebelas':
          normalized.addAll(['se', 'belas']);
        default:
          normalized.add(word);
      }
    }

    var total = 0.0;
    var group = 0.0;
    var current = 0.0;
    var consumedMeaningful = false;

    for (final word in normalized) {
      final single = _single[word];
      if (single != null) {
        current = single.toDouble();
        consumedMeaningful = true;
        continue;
      }
      switch (word) {
        case 'setengah':
        case 'separo':
          current = 0.5;
          consumedMeaningful = true;
        case 'belas':
          group += (current == 0 ? 1 : current) + 10;
          current = 0;
          consumedMeaningful = true;
        case 'puluh':
          group += (current == 0 ? 1 : current) * 10;
          current = 0;
          consumedMeaningful = true;
        case 'ratus':
          group += (current == 0 ? 1 : current) * 100;
          current = 0;
          consumedMeaningful = true;
        case 'ribu':
        case 'rb':
          total += (group + current == 0 ? 1 : group + current) * 1000;
          group = 0;
          current = 0;
          consumedMeaningful = true;
        case 'juta':
        case 'jt':
          total += (group + current == 0 ? 1 : group + current) * 1000000;
          group = 0;
          current = 0;
          consumedMeaningful = true;
        default:
          return null;
      }
    }

    if (!consumedMeaningful) return null;
    return total + group + current;
  }

  bool isNumberToken(String token) {
    return _parseNumericToken(token) != null ||
        _single.containsKey(token) ||
        const {
          'setengah',
          'separo',
          'belas',
          'puluh',
          'ratus',
          'ribu',
          'rb',
          'juta',
          'jt',
          'seratus',
          'seribu',
        }.contains(token);
  }

  double? _parseNumericToken(String token) {
    final cleaned = token.replaceAll('.', '').replaceAll(',', '.');
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(cleaned)) {
      return double.tryParse(cleaned);
    }
    return null;
  }
}
