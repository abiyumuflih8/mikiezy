enum MoneyDirection { income, expense }

enum TransactionKind { sale, income, expense, adjustment }

enum SyncStatus { localOnly, queued, synced, conflict }

enum SaleUnit {
  pcs,
  buah,
  biji,
  bungkus,
  potong,
  porsi,
  gelas,
  botol,
  cup,
  tusuk,
  kotak,
  sachet,
  kilo,
  gram,
  ons,
  liter,
  ml,
  meter,
  centimeter,
  carton,
  pack,
  renteng,
  ikat,
  ekor,
  lembar,
  plastik,
  mangkok,
  piring,
}

enum PriceSegment { retail, wholesale }

enum TransactionDraftPriceSource {
  manual,
  spoken,
  catalogRetail,
  catalogWholesale,
  catalogPack,
  catalogCarton,
  unavailable,
}

enum TransactionDraftProductStatus {
  unresolved,
  matched,
  ambiguous,
  notFound,
  adHoc,
}

enum AppLanguage { id, en }

enum ProductStockStatus { notTracked, outOfStock, low, safe }

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.packSize,
    required this.cartonSize,
    required this.stockPcs,
    this.trackStock = true,
    this.baseUnit = SaleUnit.pcs,
    this.minStock = 5,
  });

  final String id;
  final String name;
  final String category;
  final int costPrice;
  final int retailPrice;
  final int wholesalePrice;
  final int packSize;
  final int cartonSize;
  final double stockPcs;
  final bool trackStock;
  final SaleUnit baseUnit;
  final double minStock;

  Product copyWith({
    String? id,
    String? name,
    String? category,
    int? costPrice,
    int? retailPrice,
    int? wholesalePrice,
    int? packSize,
    int? cartonSize,
    double? stockPcs,
    bool? trackStock,
    SaleUnit? baseUnit,
    double? minStock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      packSize: packSize ?? this.packSize,
      cartonSize: cartonSize ?? this.cartonSize,
      stockPcs: stockPcs ?? this.stockPcs,
      trackStock: trackStock ?? this.trackStock,
      baseUnit: baseUnit ?? this.baseUnit,
      minStock: minStock ?? this.minStock,
    );
  }
}

extension ProductStockStatusX on Product {
  ProductStockStatus get stockStatus {
    if (!trackStock) return ProductStockStatus.notTracked;
    if (stockPcs <= 0) return ProductStockStatus.outOfStock;
    if (stockPcs <= minStock) return ProductStockStatus.low;
    return ProductStockStatus.safe;
  }
}

class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.balance,
    required this.isPrimary,
  });

  final String id;
  final String name;
  final int balance;
  final bool isPrimary;

  Wallet copyWith({String? id, String? name, int? balance, bool? isPrimary}) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

class LedgerCategory {
  const LedgerCategory({
    required this.id,
    required this.name,
    required this.direction,
    this.isSystem = false,
  });

  final String id;
  final String name;
  final MoneyDirection direction;
  final bool isSystem;
}

class TransactionLine {
  const TransactionLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.costPrice,
    required this.segment,
    this.unitMultiplier = 1,
  });

  final String productId;
  final String productName;
  final double quantity;
  final SaleUnit unit;
  final int unitPrice;
  final int costPrice;
  final PriceSegment segment;
  final double unitMultiplier;

  int get total => (quantity * unitPrice).round();
  int get estimatedCost => (quantity * unitMultiplier * costPrice).round();
}

class TransactionDraftLine {
  const TransactionDraftLine({
    required this.tempId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.discount = 0,
    required this.segment,
    this.categoryId,
    this.categoryName,
    this.note = '',
    this.warnings = const [],
    this.needsReview = false,
    this.priceSource = TransactionDraftPriceSource.manual,
    this.productStatus = TransactionDraftProductStatus.unresolved,
    this.productCandidates = const [],
  });

  final String tempId;
  final String? productId;
  final String productName;
  final double quantity;
  final SaleUnit unit;
  final int unitPrice;
  final int discount;
  final PriceSegment segment;
  final String? categoryId;
  final String? categoryName;
  final String note;
  final List<String> warnings;
  final bool needsReview;
  final TransactionDraftPriceSource priceSource;
  final TransactionDraftProductStatus productStatus;
  final List<String> productCandidates;

  int get grossTotal => (quantity * unitPrice).round();
  int get lineTotal => (grossTotal - discount).clamp(0, 1 << 31).toInt();

  TransactionDraftLine copyWith({
    String? tempId,
    String? productId,
    String? productName,
    double? quantity,
    SaleUnit? unit,
    int? unitPrice,
    int? discount,
    PriceSegment? segment,
    String? categoryId,
    String? categoryName,
    String? note,
    List<String>? warnings,
    bool? needsReview,
    TransactionDraftPriceSource? priceSource,
    TransactionDraftProductStatus? productStatus,
    List<String>? productCandidates,
  }) {
    return TransactionDraftLine(
      tempId: tempId ?? this.tempId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      segment: segment ?? this.segment,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      note: note ?? this.note,
      warnings: warnings ?? this.warnings,
      needsReview: needsReview ?? this.needsReview,
      priceSource: priceSource ?? this.priceSource,
      productStatus: productStatus ?? this.productStatus,
      productCandidates: productCandidates ?? this.productCandidates,
    );
  }
}

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.walletId,
    required this.walletName,
    required this.categoryId,
    required this.categoryName,
    required this.lines,
    required this.amount,
    required this.discount,
    required this.note,
    required this.evidencePath,
    required this.ocrSource,
    required this.syncStatus,
  });

  final String id;
  final TransactionKind kind;
  final DateTime createdAt;
  final String walletId;
  final String walletName;
  final String categoryId;
  final String categoryName;
  final List<TransactionLine> lines;
  final int amount;
  final int discount;
  final String note;
  final String? evidencePath;
  final String? ocrSource;
  final SyncStatus syncStatus;

  int get grossAmount => lines.fold(0, (sum, line) => sum + line.total);
  int get totalCost => lines.fold(0, (sum, line) => sum + line.estimatedCost);
  int get profitContribution {
    if (kind != TransactionKind.sale) {
      return kind == TransactionKind.expense ? -amount : amount;
    }
    return amount - totalCost;
  }

  TransactionRecord copyWith({
    String? id,
    TransactionKind? kind,
    DateTime? createdAt,
    String? walletId,
    String? walletName,
    String? categoryId,
    String? categoryName,
    List<TransactionLine>? lines,
    int? amount,
    int? discount,
    String? note,
    String? evidencePath,
    String? ocrSource,
    SyncStatus? syncStatus,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      walletId: walletId ?? this.walletId,
      walletName: walletName ?? this.walletName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      lines: lines ?? this.lines,
      amount: amount ?? this.amount,
      discount: discount ?? this.discount,
      note: note ?? this.note,
      evidencePath: evidencePath ?? this.evidencePath,
      ocrSource: ocrSource ?? this.ocrSource,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class TransactionDraft {
  const TransactionDraft({
    required this.kind,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.discount,
    required this.categoryName,
    required this.walletName,
    required this.segment,
    required this.note,
    required this.rawText,
    this.lines = const [],
    this.evidencePath,
    this.ocrSource,
  });

  final TransactionKind kind;
  final String productName;
  final double quantity;
  final SaleUnit unit;
  final int unitPrice;
  final int discount;
  final String categoryName;
  final String walletName;
  final PriceSegment segment;
  final String note;
  final String rawText;
  final List<TransactionDraftLine> lines;
  final String? evidencePath;
  final String? ocrSource;

  List<TransactionDraftLine> get effectiveLines {
    if (lines.isNotEmpty) return lines;
    final fallbackName = productName.trim().isEmpty
        ? (kind == TransactionKind.sale ? 'Item transaksi' : categoryName)
        : productName.trim();
    return [
      TransactionDraftLine(
        tempId: 'legacy-line-1',
        productName: fallbackName,
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
        discount: 0,
        segment: segment,
      ),
    ];
  }

  int get lineSubtotal =>
      effectiveLines.fold(0, (sum, line) => sum + line.lineTotal);

  int get amount {
    if (lines.isNotEmpty) {
      final value = kind == TransactionKind.sale
          ? lineSubtotal - discount
          : lineSubtotal;
      return value.clamp(0, 1 << 31).toInt();
    }
    return kind == TransactionKind.sale
        ? (quantity * unitPrice - discount).round().clamp(0, 1 << 31).toInt()
        : unitPrice;
  }

  TransactionDraft copyWith({
    TransactionKind? kind,
    String? productName,
    double? quantity,
    SaleUnit? unit,
    int? unitPrice,
    int? discount,
    String? categoryName,
    String? walletName,
    PriceSegment? segment,
    String? note,
    String? rawText,
    List<TransactionDraftLine>? lines,
    String? evidencePath,
    String? ocrSource,
  }) {
    return TransactionDraft(
      kind: kind ?? this.kind,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      categoryName: categoryName ?? this.categoryName,
      walletName: walletName ?? this.walletName,
      segment: segment ?? this.segment,
      note: note ?? this.note,
      rawText: rawText ?? this.rawText,
      lines: lines ?? this.lines,
      evidencePath: evidencePath ?? this.evidencePath,
      ocrSource: ocrSource ?? this.ocrSource,
    );
  }
}

class VoiceProductAlias {
  const VoiceProductAlias({
    required this.id,
    required this.aliasText,
    required this.normalizedAlias,
    this.productId,
    required this.canonicalProductName,
    this.hitCount = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String aliasText;
  final String normalizedAlias;
  final String? productId;
  final String canonicalProductName;
  final int hitCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  VoiceProductAlias copyWith({
    String? id,
    String? aliasText,
    String? normalizedAlias,
    String? productId,
    String? canonicalProductName,
    int? hitCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VoiceProductAlias(
      id: id ?? this.id,
      aliasText: aliasText ?? this.aliasText,
      normalizedAlias: normalizedAlias ?? this.normalizedAlias,
      productId: productId ?? this.productId,
      canonicalProductName: canonicalProductName ?? this.canonicalProductName,
      hitCount: hitCount ?? this.hitCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VoiceUnitAlias {
  const VoiceUnitAlias({
    required this.id,
    required this.aliasText,
    required this.normalizedAlias,
    required this.canonicalUnit,
    this.hitCount = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String aliasText;
  final String normalizedAlias;
  final String canonicalUnit;
  final int hitCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  VoiceUnitAlias copyWith({
    String? id,
    String? aliasText,
    String? normalizedAlias,
    String? canonicalUnit,
    int? hitCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VoiceUnitAlias(
      id: id ?? this.id,
      aliasText: aliasText ?? this.aliasText,
      normalizedAlias: normalizedAlias ?? this.normalizedAlias,
      canonicalUnit: canonicalUnit ?? this.canonicalUnit,
      hitCount: hitCount ?? this.hitCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VoiceCorrection {
  const VoiceCorrection({
    required this.id,
    required this.rawText,
    this.parsedProductName,
    required this.correctedProductName,
    this.parsedUnit,
    required this.correctedUnit,
    this.parsedQuantity,
    required this.correctedQuantity,
    required this.createdAt,
  });

  final String id;
  final String rawText;
  final String? parsedProductName;
  final String correctedProductName;
  final String? parsedUnit;
  final String correctedUnit;
  final double? parsedQuantity;
  final double correctedQuantity;
  final DateTime createdAt;
}

extension TransactionKindLabel on TransactionKind {
  String get label {
    switch (this) {
      case TransactionKind.sale:
        return 'Penjualan';
      case TransactionKind.income:
        return 'Pemasukan';
      case TransactionKind.expense:
        return 'Pengeluaran';
      case TransactionKind.adjustment:
        return 'Penyesuaian';
    }
  }
}

extension SaleUnitLabel on SaleUnit {
  String get label {
    switch (this) {
      case SaleUnit.pcs:
        return 'pcs';
      case SaleUnit.buah:
        return 'buah';
      case SaleUnit.biji:
        return 'biji';
      case SaleUnit.bungkus:
        return 'bungkus';
      case SaleUnit.potong:
        return 'potong';
      case SaleUnit.porsi:
        return 'porsi';
      case SaleUnit.gelas:
        return 'gelas';
      case SaleUnit.botol:
        return 'botol';
      case SaleUnit.cup:
        return 'cup';
      case SaleUnit.tusuk:
        return 'tusuk';
      case SaleUnit.kotak:
        return 'kotak';
      case SaleUnit.sachet:
        return 'sachet';
      case SaleUnit.kilo:
        return 'kilo';
      case SaleUnit.gram:
        return 'gram';
      case SaleUnit.ons:
        return 'ons';
      case SaleUnit.liter:
        return 'liter';
      case SaleUnit.ml:
        return 'ml';
      case SaleUnit.meter:
        return 'meter';
      case SaleUnit.centimeter:
        return 'cm';
      case SaleUnit.carton:
        return 'karton';
      case SaleUnit.pack:
        return 'pack';
      case SaleUnit.renteng:
        return 'renteng';
      case SaleUnit.ikat:
        return 'ikat';
      case SaleUnit.ekor:
        return 'ekor';
      case SaleUnit.lembar:
        return 'lembar';
      case SaleUnit.plastik:
        return 'plastik';
      case SaleUnit.mangkok:
        return 'mangkok';
      case SaleUnit.piring:
        return 'piring';
    }
  }
}

extension PriceSegmentLabel on PriceSegment {
  String get label {
    switch (this) {
      case PriceSegment.retail:
        return 'Retail/warung';
      case PriceSegment.wholesale:
        return 'Grosir';
    }
  }
}

extension TransactionDraftPriceSourceLabel on TransactionDraftPriceSource {
  String get label {
    switch (this) {
      case TransactionDraftPriceSource.manual:
        return 'Harga manual';
      case TransactionDraftPriceSource.spoken:
        return 'Harga dari ucapan';
      case TransactionDraftPriceSource.catalogRetail:
        return 'Harga dari katalog';
      case TransactionDraftPriceSource.catalogWholesale:
        return 'Harga grosir';
      case TransactionDraftPriceSource.catalogPack:
        return 'Harga pack';
      case TransactionDraftPriceSource.catalogCarton:
        return 'Harga karton';
      case TransactionDraftPriceSource.unavailable:
        return 'Harga belum tersedia';
    }
  }
}

extension TransactionDraftProductStatusLabel on TransactionDraftProductStatus {
  String? get warningLabel {
    switch (this) {
      case TransactionDraftProductStatus.ambiguous:
        return 'Perlu pilih produk';
      case TransactionDraftProductStatus.notFound:
        return 'Produk belum ditemukan';
      case TransactionDraftProductStatus.adHoc:
        return 'Produk belum terhubung';
      case TransactionDraftProductStatus.unresolved:
      case TransactionDraftProductStatus.matched:
        return null;
    }
  }
}
