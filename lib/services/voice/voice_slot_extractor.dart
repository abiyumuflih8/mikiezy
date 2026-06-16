import '../../models/mikiezy_models.dart';
import 'indonesian_number_parser.dart';
import 'money_parser.dart';
import 'parsed_transaction_item.dart';
import 'voice_parse_context.dart';

class VoiceSlotExtraction {
  const VoiceSlotExtraction({
    required this.items,
    required this.fieldConfidences,
    this.walletName,
    this.walletId,
    this.categoryName,
    this.categoryId,
    this.discount = 0,
    this.totalAmount,
    this.warnings = const [],
  });

  final List<ParsedTransactionItem> items;
  final String? walletName;
  final String? walletId;
  final String? categoryName;
  final String? categoryId;
  final int discount;
  final int? totalAmount;
  final Map<String, double> fieldConfidences;
  final List<String> warnings;
}

class VoiceSlotExtractor {
  const VoiceSlotExtractor({
    this.moneyParser = const MoneyParser(),
    this.numberParser = const IndonesianNumberParser(),
  });

  static const maxItemsPerTransaction = 30;

  final MoneyParser moneyParser;
  final IndonesianNumberParser numberParser;

  VoiceSlotExtraction extract({
    required String rawText,
    required String normalizedText,
    required TransactionKind kind,
    required VoiceParseContext context,
  }) {
    final warnings = <String>[];
    final wallet = _detectWallet(normalizedText, context);
    final category = _detectCategory(normalizedText, kind, context);
    final totalAmount = moneyParser.amountAfterKeyword(normalizedText, const [
      'total',
      'senilai total',
    ]);
    final discount =
        moneyParser.amountAfterKeyword(normalizedText, const [
          'diskon',
          'potongan',
        ]) ??
        0;
    final itemSource = _removeGlobalClauses(normalizedText);
    final itemSegments = _splitItems(itemSource);
    final limitedSegments = itemSegments.take(maxItemsPerTransaction).toList();
    if (itemSegments.length > maxItemsPerTransaction) {
      warnings.add(
        'Transcript berisi ${itemSegments.length} item. Hanya $maxItemsPerTransaction item pertama yang diproses.',
      );
    }
    final parsedItems = limitedSegments
        .map((segment) => _extractItem(segment, kind, context))
        .where((item) => item.rawText.trim().isNotEmpty)
        .toList();
    final items = _applySingleItemTotal(parsedItems, totalAmount);

    if (items.isEmpty) {
      warnings.add('Tidak ada item yang bisa dibaca dari transcript.');
    }

    return VoiceSlotExtraction(
      items: items,
      walletName: wallet?.name ?? _walletPhrase(normalizedText),
      walletId: wallet?.id,
      categoryName:
          category?.name ??
          _fallbackCategoryName(normalizedText, kind, context),
      categoryId: category?.id,
      discount: discount,
      totalAmount: totalAmount,
      warnings: warnings,
      fieldConfidences: {
        'wallet': wallet != null ? 0.94 : 0.56,
        'category': category != null ? 0.9 : 0.62,
        'totalAmount': totalAmount != null ? 0.92 : 0.45,
        'discount': discount > 0 ? 0.9 : 0.5,
      },
    );
  }

  ParsedTransactionItem _extractItem(
    String segment,
    TransactionKind kind,
    VoiceParseContext context,
  ) {
    final cleanedSegment = _stripIntentWords(segment).trim();
    final warnings = <String>[];
    final quantity = _extractQuantity(cleanedSegment);
    final unit = _extractUnit(cleanedSegment);
    final price = _extractPrice(cleanedSegment, quantity?.value);
    final product = context.matchProduct(cleanedSegment);
    final productName =
        product?.name ?? _extractProductName(cleanedSegment, price, quantity);

    if (productName == null || productName.trim().isEmpty) {
      warnings.add('Nama barang belum terbaca jelas.');
    } else if (product == null && context.hasProductCatalog) {
      warnings.add(
        'Barang "${_titleCase(productName)}" belum cocok dengan data barang lokal.',
      );
    }
    if (price.unitPrice == null && price.lineTotal == null) {
      warnings.add('Harga atau nominal item belum ditemukan.');
    }
    if (price.priceMode == ParsedPriceMode.unknown &&
        (price.unitPrice != null || price.lineTotal != null)) {
      warnings.add(
        'Mode harga belum jelas, cek apakah nominal adalah harga satuan atau total.',
      );
    }

    final confidence = _itemConfidence(
      productName: productName,
      quantity: quantity?.value,
      price: price,
      matchedProduct: product != null,
    );

    return ParsedTransactionItem(
      rawText: segment.trim(),
      productName: productName == null ? null : _titleCase(productName),
      matchedProductId: product?.id,
      quantity: quantity?.value ?? (kind == TransactionKind.sale ? 1 : null),
      unit:
          unit ??
          quantity?.unit ??
          (kind == TransactionKind.sale ? 'pcs' : null),
      unitPrice: price.unitPrice,
      lineTotal: price.lineTotal,
      priceMode: price.priceMode,
      confidence: confidence,
      warnings: warnings,
      needsReview: warnings.isNotEmpty,
    );
  }

  _QuantitySlot? _extractQuantity(String segment) {
    final tokens = _tokens(segment);
    for (var i = 0; i < tokens.length; i++) {
      final parsed = numberParser.parseAt(tokens, i);
      if (parsed == null) continue;
      final unitIndex = i + parsed.consumedTokens;
      if (unitIndex >= tokens.length) continue;
      final unit = _canonicalUnit(tokens[unitIndex]);
      if (unit == null) continue;
      return _QuantitySlot(
        value: parsed.value,
        unit: unit,
        startToken: i,
        endToken: unitIndex + 1,
        hasExplicitUnit: true,
      );
    }

    if (tokens.length >= 2) {
      final parsed = numberParser.parseAt(tokens, 0);
      if (parsed != null && _isLikelyBareQuantity(parsed, tokens)) {
        return _QuantitySlot(
          value: parsed.value,
          unit: 'pcs',
          startToken: 0,
          endToken: parsed.consumedTokens,
          hasExplicitUnit: false,
        );
      }
    }
    return null;
  }

  String? _extractUnit(String segment) {
    for (final token in _tokens(segment)) {
      final unit = _canonicalUnit(token);
      if (unit != null) return unit;
    }
    return null;
  }

  _PriceSlot _extractPrice(String segment, double? quantity) {
    final totalCandidate = moneyParser.firstAfterKeyword(segment, const [
      'total',
      'senilai',
    ]);
    if (totalCandidate != null) {
      final total = totalCandidate.amount;
      final unitPrice = quantity != null && quantity > 0
          ? (total / quantity).round()
          : null;
      return _PriceSlot(
        unitPrice: unitPrice,
        lineTotal: total,
        priceMode: ParsedPriceMode.lineTotal,
      );
    }

    final unitCandidate = moneyParser.firstAfterKeyword(segment, const [
      'harganya',
      'harga',
      'seharga',
      'per',
      'satuan',
      'masing-masing',
      'masing masing',
    ]);
    if (unitCandidate != null) {
      return _PriceSlot(
        unitPrice: unitCandidate.amount,
        priceMode: ParsedPriceMode.unitPrice,
      );
    }

    final candidates = moneyParser.parseAll(segment);
    if (candidates.isEmpty) return const _PriceSlot();
    final candidate = candidates.last;
    if (quantity != null && quantity > 0 && quantity < 1) {
      final unitPrice = (candidate.amount / quantity).round();
      return _PriceSlot(
        unitPrice: unitPrice,
        lineTotal: candidate.amount,
        priceMode: ParsedPriceMode.lineTotal,
      );
    }
    return _PriceSlot(
      unitPrice: candidate.amount,
      priceMode: ParsedPriceMode.unknown,
    );
  }

  List<ParsedTransactionItem> _applySingleItemTotal(
    List<ParsedTransactionItem> items,
    int? totalAmount,
  ) {
    if (items.length != 1 || totalAmount == null) return items;
    final item = items.first;
    if (item.unitPrice != null || item.lineTotal != null) return items;
    final quantity = item.quantity;
    final unitPrice = quantity != null && quantity > 0
        ? (totalAmount / quantity).round()
        : null;
    final warnings = item.warnings
        .where((warning) => !warning.contains('Harga atau nominal item'))
        .toList();
    return [
      item.copyWith(
        unitPrice: unitPrice,
        lineTotal: totalAmount,
        priceMode: ParsedPriceMode.lineTotal,
        warnings: warnings,
        needsReview: warnings.isNotEmpty,
      ),
    ];
  }

  String? _extractProductName(
    String segment,
    _PriceSlot price,
    _QuantitySlot? quantity,
  ) {
    var cleaned = _stripIntentWords(segment);
    cleaned = _removeWalletClause(cleaned);
    cleaned = cleaned
        .replaceAll(
          RegExp(r'\b(itu apa namanya|apa namanya|namanya|produk baru)\b'),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'\b(total|harganya|harga|seharga|satuan|per|masing-masing|masing masing|senilai)\b',
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\b(diskon|potongan)\b.*$'), ' ');

    for (final candidate in moneyParser.parseAll(cleaned)) {
      cleaned = cleaned.replaceFirst(candidate.rawText, ' ');
    }
    final tokens = _tokens(cleaned);
    final output = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      if (quantity != null &&
          i >= quantity.startToken &&
          i < quantity.endToken) {
        i = quantity.endToken - 1;
        continue;
      }
      final parsed = numberParser.parseAt(tokens, i);
      if (parsed != null) {
        final unitIndex = i + parsed.consumedTokens;
        if (unitIndex < tokens.length &&
            _canonicalUnit(tokens[unitIndex]) != null) {
          i = unitIndex;
          continue;
        }
      }
      final unit = _canonicalUnit(tokens[i]);
      if (unit != null) continue;
      if (_noiseWords.contains(tokens[i])) continue;
      output.add(tokens[i]);
    }

    final value = output.join(' ').trim();
    return value.isEmpty ? null : value;
  }

  Wallet? _detectWallet(String text, VoiceParseContext context) {
    final phrase = _walletPhrase(text);
    if (phrase != null) {
      return context.matchWallet(phrase);
    }
    return context.matchWallet(text);
  }

  String? _walletPhrase(String text) {
    final match = RegExp(
      r'\b(pakai|via|menggunakan|masuk ke|dari dompet|ke dompet)\s+(dompet\s+)?([a-z0-9 ]+?)(?=$|,|\bdan\b|\blalu\b|\bkemudian\b)',
    ).firstMatch(text);
    final phrase = match?.group(3)?.trim();
    if (phrase == null || phrase.isEmpty) return null;
    return _titleCase(phrase);
  }

  LedgerCategory? _detectCategory(
    String text,
    TransactionKind kind,
    VoiceParseContext context,
  ) {
    final matched = context.matchCategory(text, kind);
    if (matched != null) return matched;
    return null;
  }

  String? _fallbackCategoryName(
    String text,
    TransactionKind kind,
    VoiceParseContext context,
  ) {
    if (context.defaultCategoryName != null) return context.defaultCategoryName;
    if (kind == TransactionKind.sale) return 'Penjualan';
    if (_containsAny(text, const ['bensin', 'parkir', 'ojek', 'transport'])) {
      return 'Transport';
    }
    if (_containsAny(text, const [
      'gula',
      'beras',
      'minyak',
      'tepung',
      'telur',
    ])) {
      return 'Bahan baku';
    }
    if (_containsAny(text, const ['beli', 'belanja', 'kulakan'])) {
      return 'Belanja barang';
    }
    if (kind == TransactionKind.income) return 'Pemasukan';
    return 'Lain-lain';
  }

  List<String> _splitItems(String source) {
    final normalized = source.replaceAll(
      RegExp(r'\b(terus|lalu|kemudian)\b'),
      ',',
    );
    return normalized
        .split(',')
        .expand(_splitOnAndWhenSafe)
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  List<String> _splitOnAndWhenSafe(String segment) {
    final pieces = segment
        .split(RegExp(r'\s+dan\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (pieces.length <= 1) return pieces;

    final result = <String>[pieces.first];
    for (final piece in pieces.skip(1)) {
      final previous = result.last;
      if (_shouldSplitAnd(previous, piece)) {
        result.add(piece);
      } else {
        result[result.length - 1] = '$previous dan $piece';
      }
    }
    return result;
  }

  bool _shouldSplitAnd(String left, String right) {
    return _looksCompleteEnoughForSeparator(left) && _looksItemLike(right);
  }

  bool _looksCompleteEnoughForSeparator(String segment) {
    return moneyParser.parseAll(segment).isNotEmpty ||
        _hasExplicitQuantity(segment);
  }

  bool _looksItemLike(String segment) {
    return moneyParser.parseAll(segment).isNotEmpty ||
        _hasExplicitQuantity(segment) ||
        _hasBareLeadingQuantity(segment);
  }

  bool _hasExplicitQuantity(String segment) {
    return _extractQuantity(segment)?.hasExplicitUnit ?? false;
  }

  bool _hasBareLeadingQuantity(String segment) {
    final tokens = _tokens(segment);
    if (tokens.length < 2) return false;
    final parsed = numberParser.parseAt(tokens, 0);
    return parsed != null && _isLikelyBareQuantity(parsed, tokens);
  }

  String _removeGlobalClauses(String text) {
    var cleaned = _removeWalletClause(text);
    cleaned = cleaned.replaceAll(RegExp(r'\b(total)\s+[^,]+$'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _removeWalletClause(String text) {
    return text.replaceAll(
      RegExp(
        r'\b(pakai|via|menggunakan|masuk ke|dari dompet|ke dompet)\s+(dompet\s+)?[a-z0-9 ]+?(?=$|,|\bdan\b|\blalu\b|\bkemudian\b)',
      ),
      ' ',
    );
  }

  String _stripIntentWords(String text) {
    return text
        .replaceAll(
          RegExp(
            r'\b(catat|tolong|jual|penjualan|beli|belanja|pengeluaran|pemasukan|terima uang|pendapatan|modal masuk)\b',
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _itemConfidence({
    required String? productName,
    required double? quantity,
    required _PriceSlot price,
    required bool matchedProduct,
  }) {
    var score = 0.35;
    if (productName != null && productName.trim().isNotEmpty) score += 0.2;
    if (quantity != null) score += 0.12;
    if (price.unitPrice != null || price.lineTotal != null) score += 0.22;
    if (price.priceMode != ParsedPriceMode.unknown) score += 0.06;
    if (matchedProduct) score += 0.05;
    return score.clamp(0, 1).toDouble();
  }

  List<String> _tokens(String text) {
    return text
        .replaceAll(RegExp(r'[^a-z0-9.,\s-]+'), ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
  }

  String? _canonicalUnit(String token) {
    return const {
      'pcs': 'pcs',
      'pc': 'pcs',
      'buah': 'buah',
      'porsi': 'porsi',
      'gelas': 'gelas',
      'kilo': 'kilo',
      'kg': 'kilo',
      'bungkus': 'bungkus',
      'pack': 'pack',
      'pak': 'pack',
      'karton': 'karton',
      'dus': 'karton',
      'box': 'karton',
      'botol': 'botol',
    }[token];
  }

  bool _isLikelyBareQuantity(ParsedNumber parsed, List<String> tokens) {
    if (parsed.value <= 0 || parsed.value >= 1000) return false;
    if (parsed.rawText.split(' ').any(_isMoneyScaleWord)) return false;
    final nextIndex = parsed.consumedTokens;
    if (nextIndex >= tokens.length) return false;
    final next = tokens[nextIndex];
    if (_canonicalUnit(next) != null) return false;
    if (_priceHintWords.contains(next)) return false;
    return true;
  }

  bool _isMoneyScaleWord(String token) {
    return const {'ribu', 'rb', 'juta', 'jt'}.contains(token);
  }

  bool _containsAny(String text, List<String> values) {
    return values.any(text.contains);
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static const _noiseWords = {
    'ke',
    'dari',
    'untuk',
    'dengan',
    'pakai',
    'via',
    'masuk',
    'dompet',
    'itu',
    'apa',
    'nama',
    'namanya',
  };

  static const _priceHintWords = {
    'total',
    'harganya',
    'harga',
    'seharga',
    'senilai',
    'per',
    'satuan',
    'masing-masing',
    'masing',
  };
}

class _QuantitySlot {
  const _QuantitySlot({
    required this.value,
    required this.unit,
    required this.startToken,
    required this.endToken,
    required this.hasExplicitUnit,
  });

  final double value;
  final String unit;
  final int startToken;
  final int endToken;
  final bool hasExplicitUnit;
}

class _PriceSlot {
  const _PriceSlot({
    this.unitPrice,
    this.lineTotal,
    this.priceMode = ParsedPriceMode.unknown,
  });

  final int? unitPrice;
  final int? lineTotal;
  final ParsedPriceMode priceMode;
}
