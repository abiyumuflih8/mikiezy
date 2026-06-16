import '../../models/mikiezy_models.dart';
import 'parsed_transaction_item.dart';
import 'voice_parse_context.dart';
import 'voice_parse_result.dart';

class VoiceDraftAdapter {
  const VoiceDraftAdapter();

  TransactionDraft? toTransactionDraft(
    VoiceParseResult result,
    VoiceParseContext context,
  ) {
    if (result.items.isEmpty) return null;
    final lines = result.items
        .asMap()
        .entries
        .map((entry) => _draftLine(entry.key, entry.value))
        .toList();
    final first = lines.first;
    return TransactionDraft(
      kind: result.kind,
      productName: first.productName,
      quantity: first.quantity,
      unit: first.unit,
      unitPrice: first.unitPrice,
      discount: result.kind == TransactionKind.sale ? result.discount : 0,
      categoryName: result.categoryName ?? context.defaultCategoryName ?? '',
      walletName: result.walletName ?? context.defaultWalletName ?? '',
      segment: PriceSegment.retail,
      note: _draftNote(result),
      rawText: result.rawText,
      lines: lines,
    );
  }

  TransactionDraftLine _draftLine(int index, ParsedTransactionItem item) {
    final quantity = _draftQuantity(item);
    return TransactionDraftLine(
      tempId: 'voice-line-${index + 1}',
      productId: item.matchedProductId,
      productName: item.productName ?? item.rawText.trim(),
      quantity: quantity,
      unit: _draftUnit(item.unit),
      unitPrice: _draftUnitPrice(item, quantity),
      discount: 0,
      segment: PriceSegment.retail,
      note: item.rawText,
      warnings: item.warnings,
      needsReview: item.needsReview,
    );
  }

  int _draftQuantity(ParsedTransactionItem item) {
    final quantity = item.quantity;
    if (quantity == null || quantity <= 0) return 1;
    return quantity.round().clamp(1, 999999);
  }

  int _draftUnitPrice(ParsedTransactionItem item, int quantity) {
    if (item.unitPrice != null) return item.unitPrice!;
    if (item.lineTotal != null && quantity > 0) {
      return (item.lineTotal! / quantity).round();
    }
    return 0;
  }

  SaleUnit _draftUnit(String? unit) {
    switch (unit) {
      case 'pack':
        return SaleUnit.pack;
      case 'karton':
        return SaleUnit.carton;
      case 'bungkus':
        return SaleUnit.bungkus;
      case 'porsi':
        return SaleUnit.porsi;
      case 'gelas':
        return SaleUnit.gelas;
      case 'kilo':
        return SaleUnit.kilo;
      case 'botol':
        return SaleUnit.botol;
      case 'buah':
        return SaleUnit.buah;
      default:
        return SaleUnit.pcs;
    }
  }

  String _draftNote(VoiceParseResult result) {
    if (result.warnings.isEmpty) return result.normalizedText;
    return '${result.normalizedText}\n\nCatatan Miki:\n${result.warnings.join('\n')}';
  }
}
