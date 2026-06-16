import '../../models/mikiezy_models.dart';
import 'parsed_transaction_item.dart';

class VoiceParseResult {
  const VoiceParseResult({
    required this.rawText,
    required this.normalizedText,
    required this.kind,
    required this.items,
    this.walletName,
    this.walletId,
    this.categoryName,
    this.categoryId,
    this.discount = 0,
    this.totalAmount,
    this.confidence = 0,
    this.fieldConfidences = const {},
    this.warnings = const [],
    this.needsReview = false,
    this.draft,
  });

  final String rawText;
  final String normalizedText;
  final TransactionKind kind;
  final List<ParsedTransactionItem> items;
  final String? walletName;
  final String? walletId;
  final String? categoryName;
  final String? categoryId;
  final int discount;
  final int? totalAmount;
  final double confidence;
  final Map<String, double> fieldConfidences;
  final List<String> warnings;
  final bool needsReview;
  final TransactionDraft? draft;

  VoiceParseResult copyWith({
    String? rawText,
    String? normalizedText,
    TransactionKind? kind,
    List<ParsedTransactionItem>? items,
    String? walletName,
    String? walletId,
    String? categoryName,
    String? categoryId,
    int? discount,
    int? totalAmount,
    double? confidence,
    Map<String, double>? fieldConfidences,
    List<String>? warnings,
    bool? needsReview,
    TransactionDraft? draft,
  }) {
    return VoiceParseResult(
      rawText: rawText ?? this.rawText,
      normalizedText: normalizedText ?? this.normalizedText,
      kind: kind ?? this.kind,
      items: items ?? this.items,
      walletName: walletName ?? this.walletName,
      walletId: walletId ?? this.walletId,
      categoryName: categoryName ?? this.categoryName,
      categoryId: categoryId ?? this.categoryId,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      confidence: confidence ?? this.confidence,
      fieldConfidences: fieldConfidences ?? this.fieldConfidences,
      warnings: warnings ?? this.warnings,
      needsReview: needsReview ?? this.needsReview,
      draft: draft ?? this.draft,
    );
  }
}
