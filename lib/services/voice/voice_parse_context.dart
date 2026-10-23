import '../../models/mikiezy_models.dart';

class VoiceParseContext {
  const VoiceParseContext({
    this.products = const [],
    this.wallets = const [],
    this.categories = const [],
    this.productAliases = const [],
    this.unitAliases = const [],
    this.defaultWalletName,
    this.defaultCategoryName,
  });

  final List<Product> products;
  final List<Wallet> wallets;
  final List<LedgerCategory> categories;
  final List<VoiceProductAlias> productAliases;
  final List<VoiceUnitAlias> unitAliases;
  final String? defaultWalletName;
  final String? defaultCategoryName;

  bool get hasProductCatalog => products.isNotEmpty;

  Product? matchProduct(String text) {
    if (products.isEmpty || text.trim().isEmpty) return null;
    final normalizedText = normalizeForMatch(text);
    Product? best;
    var bestLength = 0;

    for (final alias in productAliases) {
      final normalizedAlias = alias.normalizedAlias.isEmpty
          ? normalizeForMatch(alias.aliasText)
          : alias.normalizedAlias;
      if (normalizedAlias.isEmpty) continue;
      if (!_containsWholePhrase(normalizedText, normalizedAlias)) continue;
      if (_isAmbiguousProductAlias(alias)) continue;
      final product = _productForAlias(alias);
      if (product == null) continue;
      if (normalizedAlias.length > bestLength) {
        best = product;
        bestLength = normalizedAlias.length;
      }
    }

    for (final product in products) {
      final normalizedLabel = normalizeForMatch(product.name);
      if (normalizedLabel.isEmpty) continue;
      if (!_containsWholePhrase(normalizedText, normalizedLabel)) continue;
      if (normalizedLabel.length > bestLength) {
        best = product;
        bestLength = normalizedLabel.length;
      }
    }
    return best;
  }

  String? matchProductAliasName(String text) {
    if (productAliases.isEmpty || text.trim().isEmpty) return null;
    final normalizedText = normalizeForMatch(text);
    VoiceProductAlias? best;
    var bestLength = 0;
    for (final alias in productAliases) {
      final normalizedAlias = alias.normalizedAlias.isEmpty
          ? normalizeForMatch(alias.aliasText)
          : alias.normalizedAlias;
      if (normalizedAlias.isEmpty) continue;
      if (!_containsWholePhrase(normalizedText, normalizedAlias)) continue;
      if (_isAmbiguousProductAlias(alias)) continue;
      if (normalizedAlias.length > bestLength) {
        best = alias;
        bestLength = normalizedAlias.length;
      }
    }
    return best?.canonicalProductName;
  }

  Wallet? matchWallet(String text) {
    return _bestMatch(wallets, text, (wallet) => wallet.name);
  }

  LedgerCategory? matchCategory(String text, TransactionKind kind) {
    final direction = kind == TransactionKind.expense
        ? MoneyDirection.expense
        : MoneyDirection.income;
    return _bestMatch(
      categories.where((category) => category.direction == direction).toList(),
      text,
      (category) => category.name,
    );
  }

  T? _bestMatch<T>(List<T> values, String text, String Function(T) label) {
    if (values.isEmpty || text.trim().isEmpty) return null;
    final normalizedText = normalizeForMatch(text);
    T? best;
    var bestScore = 0;
    for (final value in values) {
      final normalizedLabel = normalizeForMatch(label(value));
      if (normalizedLabel.isEmpty) continue;
      var score = 0;
      if (normalizedText.contains(normalizedLabel)) {
        score = normalizedLabel.length + 20;
      } else {
        final labelTokens = normalizedLabel.split(' ').toSet();
        final textTokens = normalizedText.split(' ').toSet();
        score = labelTokens.intersection(textTokens).length;
      }
      if (score > bestScore) {
        bestScore = score;
        best = value;
      }
    }
    return bestScore > 0 ? best : null;
  }

  bool _isAmbiguousProductAlias(VoiceProductAlias alias) {
    final normalizedAlias = alias.normalizedAlias.isEmpty
        ? normalizeForMatch(alias.aliasText)
        : alias.normalizedAlias;
    if (normalizedAlias.isEmpty) return false;

    String targetKey(VoiceProductAlias value) {
      final productId = value.productId?.trim();
      if (productId != null && productId.isNotEmpty) return 'id:$productId';
      return 'name:${normalizeForMatch(value.canonicalProductName)}';
    }

    final targets = <String>{};
    for (final candidate in productAliases) {
      final candidateAlias = candidate.normalizedAlias.isEmpty
          ? normalizeForMatch(candidate.aliasText)
          : candidate.normalizedAlias;
      if (candidateAlias != normalizedAlias) continue;
      targets.add(targetKey(candidate));
      if (targets.length > 1) return true;
    }
    return false;
  }

  Product? _productForAlias(VoiceProductAlias alias) {
    final productId = alias.productId?.trim();
    if (productId != null && productId.isNotEmpty) {
      for (final product in products) {
        if (product.id == productId) return product;
      }
    }

    final canonical = normalizeForMatch(alias.canonicalProductName);
    for (final product in products) {
      if (normalizeForMatch(product.name) == canonical) return product;
    }
    return null;
  }

  static String normalizeForMatch(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _containsWholePhrase(String text, String phrase) {
    return RegExp('(^| )${RegExp.escape(phrase)}( |\$)').hasMatch(text);
  }
}
