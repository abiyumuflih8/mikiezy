import '../../models/mikiezy_models.dart';
import 'voice_draft_adapter.dart';
import 'voice_intent_detector.dart';
import 'voice_parse_context.dart';
import 'voice_parse_result.dart';
import 'voice_parse_validator.dart';
import 'voice_slot_extractor.dart';
import 'voice_text_normalizer.dart';

class VoiceTransactionParserV2 {
  const VoiceTransactionParserV2({
    this.normalizer = const VoiceTextNormalizer(),
    this.intentDetector = const VoiceIntentDetector(),
    this.slotExtractor = const VoiceSlotExtractor(),
    this.validator = const VoiceParseValidator(),
    this.draftAdapter = const VoiceDraftAdapter(),
  });

  final VoiceTextNormalizer normalizer;
  final VoiceIntentDetector intentDetector;
  final VoiceSlotExtractor slotExtractor;
  final VoiceParseValidator validator;
  final VoiceDraftAdapter draftAdapter;

  VoiceParseResult parse(
    String input, {
    VoiceParseContext context = const VoiceParseContext(),
  }) {
    final normalized = normalizer.normalize(input);
    final kind = intentDetector.detect(normalized);
    final slots = slotExtractor.extract(
      rawText: input,
      normalizedText: normalized,
      kind: kind,
      context: context,
    );
    final result = VoiceParseResult(
      rawText: input,
      normalizedText: normalized,
      kind: kind,
      items: slots.items,
      walletName: slots.walletName ?? context.defaultWalletName,
      walletId: slots.walletId,
      categoryName: slots.categoryName ?? _defaultCategory(kind, context),
      categoryId: slots.categoryId,
      discount: slots.discount,
      totalAmount: slots.totalAmount,
      fieldConfidences: slots.fieldConfidences,
      warnings: slots.warnings,
    );
    final validated = validator.validate(result);
    return validated.copyWith(
      draft: draftAdapter.toTransactionDraft(validated, context),
    );
  }

  String? _defaultCategory(TransactionKind kind, VoiceParseContext context) {
    if (context.defaultCategoryName != null) return context.defaultCategoryName;
    return switch (kind) {
      TransactionKind.sale => 'Penjualan',
      TransactionKind.expense => 'Lain-lain',
      TransactionKind.income => 'Pemasukan',
      TransactionKind.adjustment => 'Penyesuaian',
    };
  }
}
