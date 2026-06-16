import '../../models/mikiezy_models.dart';

class VoiceParseContext {
  const VoiceParseContext({
    this.products = const [],
    this.wallets = const [],
    this.categories = const [],
    this.defaultWalletName,
    this.defaultCategoryName,
  });

  final List<Product> products;
  final List<Wallet> wallets;
  final List<LedgerCategory> categories;
  final String? defaultWalletName;
  final String? defaultCategoryName;

  bool get hasProductCatalog => products.isNotEmpty;

  Product? matchProduct(String text) {
    if (products.isEmpty || text.trim().isEmpty) return null;
    final normalizedText = normalizeForMatch(text);
    Product? best;
    var bestLength = 0;
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
