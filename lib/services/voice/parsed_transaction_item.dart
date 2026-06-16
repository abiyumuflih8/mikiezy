enum ParsedPriceMode { unitPrice, lineTotal, unknown }

class ParsedTransactionItem {
  const ParsedTransactionItem({
    required this.rawText,
    this.productName,
    this.matchedProductId,
    this.quantity,
    this.unit,
    this.unitPrice,
    this.lineTotal,
    this.priceMode = ParsedPriceMode.unknown,
    this.confidence = 0,
    this.warnings = const [],
    this.needsReview = false,
  });

  final String rawText;
  final String? productName;
  final String? matchedProductId;
  final double? quantity;
  final String? unit;
  final int? unitPrice;
  final int? lineTotal;
  final ParsedPriceMode priceMode;
  final double confidence;
  final List<String> warnings;
  final bool needsReview;

  int? get computedLineTotal {
    if (lineTotal != null) return lineTotal;
    final itemQuantity = quantity;
    final itemUnitPrice = unitPrice;
    if (itemQuantity == null || itemUnitPrice == null) return null;
    return (itemQuantity * itemUnitPrice).round();
  }

  ParsedTransactionItem copyWith({
    String? rawText,
    String? productName,
    String? matchedProductId,
    double? quantity,
    String? unit,
    int? unitPrice,
    int? lineTotal,
    ParsedPriceMode? priceMode,
    double? confidence,
    List<String>? warnings,
    bool? needsReview,
  }) {
    return ParsedTransactionItem(
      rawText: rawText ?? this.rawText,
      productName: productName ?? this.productName,
      matchedProductId: matchedProductId ?? this.matchedProductId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
      priceMode: priceMode ?? this.priceMode,
      confidence: confidence ?? this.confidence,
      warnings: warnings ?? this.warnings,
      needsReview: needsReview ?? this.needsReview,
    );
  }
}
