import 'indonesian_number_parser.dart';

class MoneyCandidate {
  const MoneyCandidate({
    required this.amount,
    required this.rawText,
    required this.startToken,
    required this.endToken,
  });

  final int amount;
  final String rawText;
  final int startToken;
  final int endToken;
}

class MoneyParser {
  const MoneyParser({this.numberParser = const IndonesianNumberParser()});

  final IndonesianNumberParser numberParser;

  List<MoneyCandidate> parseAll(String text) {
    final tokens = _tokens(text);
    final candidates = <MoneyCandidate>[];
    var index = 0;
    while (index < tokens.length) {
      final parsed = numberParser.parseAt(tokens, index);
      if (parsed == null) {
        index += 1;
        continue;
      }

      var consumed = parsed.consumedTokens;
      var amount = parsed.value;
      final next = index + consumed < tokens.length
          ? tokens[index + consumed]
          : null;
      if (_isScale(next)) {
        amount *= _scale(next);
        consumed += 1;
      }

      final hasScaleInRaw = parsed.rawText.split(' ').any(_isScale);
      final followedByUnit =
          index + consumed < tokens.length &&
          _isQuantityUnit(tokens[index + consumed]);
      final looksLikeMoney = amount >= 1000 || hasScaleInRaw || _isScale(next);
      if (looksLikeMoney && !followedByUnit) {
        candidates.add(
          MoneyCandidate(
            amount: amount.round(),
            rawText: tokens.sublist(index, index + consumed).join(' '),
            startToken: index,
            endToken: index + consumed,
          ),
        );
      }
      index += consumed;
    }
    return candidates;
  }

  MoneyCandidate? firstAfterKeyword(String text, List<String> keywords) {
    final normalized = text.toLowerCase();
    for (final keyword in keywords) {
      final index = normalized.indexOf(keyword);
      if (index == -1) continue;
      final after = normalized.substring(index + keyword.length).trim();
      final candidates = parseAll(after);
      if (candidates.isNotEmpty) return candidates.first;
    }
    return null;
  }

  int? amountAfterKeyword(String text, List<String> keywords) {
    return firstAfterKeyword(text, keywords)?.amount;
  }

  List<String> _tokens(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9.,\s-]+'), ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  bool _isScale(String? token) {
    return const {'ribu', 'rb', 'juta', 'jt'}.contains(token);
  }

  int _scale(String? token) {
    return const {
          'ribu': 1000,
          'rb': 1000,
          'juta': 1000000,
          'jt': 1000000,
        }[token] ??
        1;
  }

  bool _isQuantityUnit(String token) {
    return const {
      'pcs',
      'pc',
      'buah',
      'porsi',
      'gelas',
      'kilo',
      'kg',
      'bungkus',
      'pack',
      'pak',
      'karton',
      'dus',
      'box',
      'botol',
    }.contains(token);
  }
}
