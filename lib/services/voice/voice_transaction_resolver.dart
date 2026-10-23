import '../../models/mikiezy_models.dart';
import 'parsed_transaction_item.dart';
import 'voice_parse_context.dart';
import 'voice_parse_result.dart';
import 'voice_product_price_resolver.dart';
import 'voice_product_resolver.dart';

class VoiceResolvedTransactionItem {
  const VoiceResolvedTransactionItem({
    required this.item,
    required this.productMatch,
    required this.price,
  });

  final ParsedTransactionItem item;
  final VoiceProductMatchResult productMatch;
  final VoicePriceResolution price;
}

class VoiceTransactionResolution {
  const VoiceTransactionResolution({required this.result, required this.items});

  final VoiceParseResult result;
  final List<VoiceResolvedTransactionItem> items;
}

class VoiceTransactionResolver {
  const VoiceTransactionResolver({
    this.productResolver = const VoiceProductResolver(),
    this.priceResolver = const VoiceProductPriceResolver(),
  });

  final VoiceProductResolver productResolver;
  final VoiceProductPriceResolver priceResolver;

  VoiceTransactionResolution resolve(
    VoiceParseResult result,
    VoiceParseContext context,
  ) {
    final resolvedItems = <VoiceResolvedTransactionItem>[];
    for (final item in result.items) {
      final spokenName = (item.productName ?? item.rawText).trim();
      final productMatch = productResolver.resolve(
        spokenName: spokenName,
        products: context.products,
        aliases: context.productAliases,
        matchedProductId: item.matchedProductId,
        spokenUnit: item.unit,
      );
      final price = priceResolver.resolve(
        item: item,
        productMatch: productMatch,
        allowCatalogPrice: result.kind == TransactionKind.sale,
      );
      final resolvedItem = _resolvedItem(
        item,
        productMatch,
        price,
        isSale: result.kind == TransactionKind.sale,
      );
      resolvedItems.add(
        VoiceResolvedTransactionItem(
          item: resolvedItem,
          productMatch: productMatch,
          price: price,
        ),
      );
    }

    return VoiceTransactionResolution(
      result: result.copyWith(
        items: resolvedItems.map((resolved) => resolved.item).toList(),
      ),
      items: resolvedItems,
    );
  }

  ParsedTransactionItem _resolvedItem(
    ParsedTransactionItem item,
    VoiceProductMatchResult productMatch,
    VoicePriceResolution price, {
    required bool isSale,
  }) {
    final warnings = item.warnings.where((warning) {
      if (warning.startsWith('Harga atau nominal item')) {
        return !price.isAvailable;
      }
      if (isSale && warning.startsWith('Barang "')) return false;
      return true;
    }).toList();
    final product = productMatch.product;

    if (isSale && productMatch.type == VoiceProductMatchType.ambiguous) {
      final candidates = productMatch.candidates
          .map((candidate) => candidate.product.name)
          .join(', ');
      warnings.add(
        'Produk "$spokenProductName(item)" ambigu. Pilih salah satu: $candidates.',
      );
    } else if (isSale && !productMatch.isMatched) {
      if (price.source == VoicePriceSource.spoken) {
        warnings.add(
          'Produk "$spokenProductName(item)" belum cocok dengan katalog. Stok katalog tidak akan berubah.',
        );
      } else {
        warnings.add(
          'Produk "$spokenProductName(item)" belum ditemukan. Harga belum disebutkan.',
        );
      }
    }

    if (price.message != null && productMatch.isMatched && isSale) {
      warnings.add(price.message!);
    }
    final stockWarning = isSale ? _stockWarning(item, product, price) : null;
    if (stockWarning != null) warnings.add(stockWarning);

    return ParsedTransactionItem(
      rawText: item.rawText,
      productName: product?.name ?? item.productName,
      matchedProductId: product?.id,
      quantity: price.quantity ?? item.quantity,
      unit: price.unit.label,
      unitPrice: price.unitPrice,
      lineTotal: price.source == VoicePriceSource.spoken
          ? item.lineTotal
          : null,
      priceMode: price.isAvailable
          ? (price.source == VoicePriceSource.spoken
                ? item.priceMode
                : ParsedPriceMode.unitPrice)
          : item.priceMode,
      confidence: item.confidence,
      warnings: warnings,
      needsReview: warnings.isNotEmpty,
    );
  }

  String spokenProductName(ParsedTransactionItem item) {
    final value = item.productName?.trim();
    return value == null || value.isEmpty ? item.rawText.trim() : value;
  }

  String? _stockWarning(
    ParsedTransactionItem item,
    Product? product,
    VoicePriceResolution price,
  ) {
    if (product == null || !product.trackStock) return null;
    final quantity = price.quantity ?? item.quantity ?? 1;
    final requiredStock = quantity * price.unitMultiplier;
    if (requiredStock <= product.stockPcs) return null;
    return 'Stok ${product.name} tidak cukup: perlu ${_quantityLabel(requiredStock)} ${product.baseUnit.label}, tersedia ${_quantityLabel(product.stockPcs)} ${product.baseUnit.label}.';
  }

  String _quantityLabel(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+\$'), '')
        .replaceFirst(RegExp(r'\.\$'), '');
  }
}
