enum MoneyDirection { income, expense }

enum TransactionKind { sale, income, expense, adjustment }

enum SyncStatus { localOnly, queued, synced, conflict }

enum SaleUnit { pcs, pack, carton, bungkus, porsi, gelas, kilo, botol, buah }

enum PriceSegment { retail, wholesale }

enum AppLanguage { id, en }

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
  });

  final String id;
  final String name;
  final String category;
  final int costPrice;
  final int retailPrice;
  final int wholesalePrice;
  final int packSize;
  final int cartonSize;
  final int stockPcs;

  Product copyWith({
    String? id,
    String? name,
    String? category,
    int? costPrice,
    int? retailPrice,
    int? wholesalePrice,
    int? packSize,
    int? cartonSize,
    int? stockPcs,
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
    );
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
  });

  final String productId;
  final String productName;
  final int quantity;
  final SaleUnit unit;
  final int unitPrice;
  final int costPrice;
  final PriceSegment segment;

  int get unitMultiplier {
    switch (unit) {
      case SaleUnit.pcs:
      case SaleUnit.bungkus:
      case SaleUnit.porsi:
      case SaleUnit.gelas:
      case SaleUnit.kilo:
      case SaleUnit.botol:
      case SaleUnit.buah:
        return 1;
      case SaleUnit.pack:
        return 12;
      case SaleUnit.carton:
        return 48;
    }
  }

  int get total => quantity * unitPrice;
  int get estimatedCost => quantity * unitMultiplier * costPrice;
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
  });

  final String tempId;
  final String? productId;
  final String productName;
  final int quantity;
  final SaleUnit unit;
  final int unitPrice;
  final int discount;
  final PriceSegment segment;
  final String? categoryId;
  final String? categoryName;
  final String note;
  final List<String> warnings;
  final bool needsReview;

  int get grossTotal => quantity * unitPrice;
  int get lineTotal => (grossTotal - discount).clamp(0, 1 << 31);

  TransactionDraftLine copyWith({
    String? tempId,
    String? productId,
    String? productName,
    int? quantity,
    SaleUnit? unit,
    int? unitPrice,
    int? discount,
    PriceSegment? segment,
    String? categoryId,
    String? categoryName,
    String? note,
    List<String>? warnings,
    bool? needsReview,
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
  final int quantity;
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
      return value.clamp(0, 1 << 31);
    }
    return kind == TransactionKind.sale
        ? (quantity * unitPrice - discount).clamp(0, 1 << 31)
        : unitPrice;
  }

  TransactionDraft copyWith({
    TransactionKind? kind,
    String? productName,
    int? quantity,
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
      case SaleUnit.pack:
        return 'pack';
      case SaleUnit.carton:
        return 'karton';
      case SaleUnit.bungkus:
        return 'bungkus';
      case SaleUnit.porsi:
        return 'porsi';
      case SaleUnit.gelas:
        return 'gelas';
      case SaleUnit.kilo:
        return 'kilo';
      case SaleUnit.botol:
        return 'botol';
      case SaleUnit.buah:
        return 'buah';
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
