import '../../models/mikiezy_models.dart';
import 'parsed_transaction_item.dart';
import 'voice_parse_context.dart';
import 'voice_parse_result.dart';
import 'voice_product_price_resolver.dart';
import 'voice_product_resolver.dart';
import 'voice_transaction_resolver.dart';
import 'voice_unit_dictionary.dart';

class VoiceDraftAdapter {
  const VoiceDraftAdapter();

  TransactionDraft? toTransactionDraft(
    VoiceParseResult result,
    VoiceParseContext context, {
    List<VoiceResolvedTransactionItem> resolvedItems = const [],
  }) {
    if (result.items.isEmpty) return null;
    final lines = result.items
        .asMap()
        .entries
        .map(
          (entry) => _draftLine(
            entry.key,
            entry.value,
            entry.key < resolvedItems.length ? resolvedItems[entry.key] : null,
          ),
        )
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
      segment: first.segment,
      note: _draftNote(result),
      rawText: result.rawText,
      lines: lines,
    );
  }

  TransactionDraftLine _draftLine(
    int index,
    ParsedTransactionItem item,
    VoiceResolvedTransactionItem? resolution,
  ) {
    final quantity = _draftQuantity(item);
    final price = resolution?.price;
    return TransactionDraftLine(
      tempId: 'voice-line-${index + 1}',
      productId: item.matchedProductId,
      productName: item.productName ?? item.rawText.trim(),
      quantity: quantity,
      unit: price?.unit ?? _draftUnit(item.unit),
      unitPrice: _draftUnitPrice(item, quantity),
      discount: 0,
      segment: price?.segment ?? PriceSegment.retail,
      note: item.rawText,
      warnings: item.warnings,
      needsReview: item.needsReview,
      priceSource: _draftPriceSource(price?.source),
      productStatus: _draftProductStatus(resolution),
      productCandidates:
          resolution?.productMatch.type == VoiceProductMatchType.ambiguous
          ? resolution!.productMatch.candidates
                .map((candidate) => candidate.product.name)
                .toList()
          : const [],
    );
  }

  double _draftQuantity(ParsedTransactionItem item) {
    final quantity = item.quantity;
    if (quantity == null || quantity <= 0) return 1;
    return quantity.clamp(0.001, 999999).toDouble();
  }

  int _draftUnitPrice(ParsedTransactionItem item, double quantity) {
    if (item.unitPrice != null) return item.unitPrice!;
    if (item.lineTotal != null && quantity > 0) {
      return (item.lineTotal! / quantity).round();
    }
    return 0;
  }

  SaleUnit _draftUnit(String? unit) {
    return VoiceUnitDictionary.saleUnitFor(unit) ?? SaleUnit.pcs;
  }

  TransactionDraftPriceSource _draftPriceSource(VoicePriceSource? source) {
    return switch (source) {
      VoicePriceSource.spoken => TransactionDraftPriceSource.spoken,
      VoicePriceSource.catalogRetail =>
        TransactionDraftPriceSource.catalogRetail,
      VoicePriceSource.catalogWholesale =>
        TransactionDraftPriceSource.catalogWholesale,
      VoicePriceSource.catalogPack => TransactionDraftPriceSource.catalogPack,
      VoicePriceSource.catalogCarton =>
        TransactionDraftPriceSource.catalogCarton,
      VoicePriceSource.unavailable => TransactionDraftPriceSource.unavailable,
      null => TransactionDraftPriceSource.manual,
    };
  }

  TransactionDraftProductStatus _draftProductStatus(
    VoiceResolvedTransactionItem? resolution,
  ) {
    if (resolution == null) return TransactionDraftProductStatus.unresolved;
    final matchType = resolution.productMatch.type;
    if (resolution.productMatch.isMatched) {
      return TransactionDraftProductStatus.matched;
    }
    if (matchType == VoiceProductMatchType.ambiguous) {
      return TransactionDraftProductStatus.ambiguous;
    }
    if (resolution.price.source == VoicePriceSource.spoken) {
      return TransactionDraftProductStatus.adHoc;
    }
    return TransactionDraftProductStatus.notFound;
  }

  String _draftNote(VoiceParseResult result) {
    if (result.warnings.isEmpty) return result.normalizedText;
    return '${result.normalizedText}\n\nCatatan Miki:\n${result.warnings.join('\n')}';
  }
}
