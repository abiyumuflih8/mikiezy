import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/models/business_query_result.dart';
import 'package:mikiezy/domain/services/business_metrics_service.dart';
import 'package:mikiezy/domain/services/report_period_resolver.dart';
import 'package:mikiezy/models/mikiezy_models.dart';

void main() {
  const service = BusinessMetricsService();
  final now = DateTime(2026, 7, 13, 18);

  group('sales, income, expense, and count metrics', () {
    final transactions = [
      _transaction(
        id: 'sale-today',
        kind: TransactionKind.sale,
        createdAt: DateTime(2026, 7, 13, 9),
        amount: 30000,
      ),
      _transaction(
        id: 'income-today',
        kind: TransactionKind.income,
        createdAt: DateTime(2026, 7, 13, 10),
        amount: 100000,
      ),
      _transaction(
        id: 'expense-today',
        kind: TransactionKind.expense,
        createdAt: DateTime(2026, 7, 13, 11),
        amount: 12000,
      ),
      _transaction(
        id: 'sale-yesterday',
        kind: TransactionKind.sale,
        createdAt: DateTime(2026, 7, 12, 10),
        amount: 50000,
      ),
    ];

    test('revenue includes only saved sales in the requested period', () {
      final result = service.revenue(
        transactions: transactions,
        period: ReportPeriodType.today,
        now: now,
      );

      expect(result.status, BusinessQueryStatus.success);
      expect(result.moneyValue, 30000);
      expect(result.saleCount, 1);
    });

    test('income and expense use their own transaction kinds', () {
      final income = service.income(
        transactions: transactions,
        period: ReportPeriodType.today,
        now: now,
      );
      final expense = service.expense(
        transactions: transactions,
        period: ReportPeriodType.today,
        now: now,
      );

      expect(income.moneyValue, 100000);
      expect(income.incomeCount, 1);
      expect(expense.moneyValue, 12000);
      expect(expense.expenseCount, 1);
    });

    test('transaction count supports all and type-specific filters', () {
      final all = service.transactionCount(
        transactions: transactions,
        period: ReportPeriodType.today,
        now: now,
      );
      final sales = service.transactionCount(
        transactions: transactions,
        period: ReportPeriodType.today,
        now: now,
        filter: BusinessTransactionFilter.sale,
      );
      final expenses = service.transactionCount(
        transactions: transactions,
        period: ReportPeriodType.today,
        now: now,
        filter: BusinessTransactionFilter.expense,
      );

      expect(all.countValue, 3);
      expect(all.saleCount, 1);
      expect(all.incomeCount, 1);
      expect(all.expenseCount, 1);
      expect(sales.countValue, 1);
      expect(expenses.countValue, 1);
    });

    test(
      'returns an explicit empty status rather than a fabricated result',
      () {
        final result = service.revenue(
          transactions: transactions,
          period: ReportPeriodType.lastMonth,
          now: now,
        );

        expect(result.status, BusinessQueryStatus.empty);
        expect(result.moneyValue, isNull);
      },
    );

    test('largest expense keeps the historical category snapshot', () {
      final result = service.expense(
        transactions: [
          _transaction(
            id: 'small',
            kind: TransactionKind.expense,
            createdAt: DateTime(2026, 7, 13, 8),
            amount: 10000,
            categoryName: 'Transportasi',
          ),
          _transaction(
            id: 'large',
            kind: TransactionKind.expense,
            createdAt: DateTime(2026, 7, 13, 9),
            amount: 250000,
            categoryName: 'Bahan baku',
          ),
        ],
        period: ReportPeriodType.today,
        now: now,
        largestOnly: true,
      );

      expect(result.moneyValue, 250000);
      expect(result.categoryName, 'Bahan baku');
    });

    test('transaction breakdown includes balance adjustments explicitly', () {
      final result = service.transactionCount(
        transactions: [
          _transaction(
            id: 'adjustment',
            kind: TransactionKind.adjustment,
            createdAt: DateTime(2026, 7, 13, 12),
            amount: 5000,
          ),
        ],
        period: ReportPeriodType.today,
        now: now,
      );

      expect(result.countValue, 1);
      expect(result.adjustmentCount, 1);
    });

    test('expense category aggregation follows the requested period', () {
      final categories = service.expenseByCategory(
        transactions: [
          _transaction(
            id: 'today',
            kind: TransactionKind.expense,
            createdAt: DateTime(2026, 7, 13, 12),
            amount: 20000,
            categoryName: 'Bahan baku',
          ),
          _transaction(
            id: 'yesterday',
            kind: TransactionKind.expense,
            createdAt: DateTime(2026, 7, 12, 12),
            amount: 100000,
            categoryName: 'Listrik',
          ),
        ],
        period: ReportPeriodType.today,
        now: now,
      );

      expect(categories, hasLength(1));
      expect(categories.single.name, 'Bahan baku');
      expect(categories.single.moneyValue, 20000);
    });
  });

  group('profit metric', () {
    test('uses historical line cost including fractions, pack, and carton', () {
      final sale = _transaction(
        id: 'snapshot-sale',
        kind: TransactionKind.sale,
        createdAt: DateTime(2026, 7, 13, 12),
        amount: 364000,
        lines: const [
          TransactionLine(
            productId: 'rice',
            productName: 'Beras',
            quantity: 0.5,
            unit: SaleUnit.kilo,
            unitPrice: 8000,
            costPrice: 3000,
            segment: PriceSegment.retail,
          ),
          TransactionLine(
            productId: 'pack',
            productName: 'Kopi Pack',
            quantity: 1,
            unit: SaleUnit.pack,
            unitPrice: 120000,
            costPrice: 8000,
            segment: PriceSegment.wholesale,
            unitMultiplier: 10,
          ),
          TransactionLine(
            productId: 'carton',
            productName: 'Air Karton',
            quantity: 1,
            unit: SaleUnit.carton,
            unitPrice: 240000,
            costPrice: 7000,
            segment: PriceSegment.wholesale,
            unitMultiplier: 24,
          ),
        ],
      );
      final result = service.profit(
        transactions: [
          sale,
          _transaction(
            id: 'income',
            kind: TransactionKind.income,
            createdAt: DateTime(2026, 7, 13, 13),
            amount: 20000,
          ),
          _transaction(
            id: 'expense',
            kind: TransactionKind.expense,
            createdAt: DateTime(2026, 7, 13, 14),
            amount: 10000,
          ),
          _transaction(
            id: 'adjustment',
            kind: TransactionKind.adjustment,
            createdAt: DateTime(2026, 7, 13, 15),
            amount: 999999,
          ),
        ],
        period: ReportPeriodType.today,
        now: now,
      );

      // Cost: (0.5 x 3,000) + (1 x 10 x 8,000) + (1 x 24 x 7,000).
      expect(result.costValue, 249500);
      expect(result.revenueValue, 364000);
      expect(result.moneyValue, 124500);
      expect(result.isEstimate, isFalse);
    });

    test('marks profit as estimated when a sold line has no cost snapshot', () {
      final result = service.profit(
        transactions: [
          _transaction(
            id: 'missing-cost',
            kind: TransactionKind.sale,
            createdAt: DateTime(2026, 7, 13, 12),
            amount: 15000,
            lines: const [
              TransactionLine(
                productId: 'adhoc',
                productName: 'Produk Lama',
                quantity: 1,
                unit: SaleUnit.pcs,
                unitPrice: 15000,
                costPrice: 0,
                segment: PriceSegment.retail,
              ),
            ],
          ),
        ],
        period: ReportPeriodType.today,
        now: now,
      );

      expect(result.moneyValue, 15000);
      expect(result.isEstimate, isTrue);
    });
  });

  group('top products', () {
    test('ranks sale lines by converted base quantity', () {
      final result = service.topProducts(
        transactions: [
          _transaction(
            id: 'pack-sale',
            kind: TransactionKind.sale,
            createdAt: DateTime(2026, 7, 13, 9),
            amount: 100000,
            lines: const [
              TransactionLine(
                productId: 'coffee',
                productName: 'Kopi Sachet',
                quantity: 1,
                unit: SaleUnit.pack,
                unitPrice: 100000,
                costPrice: 5000,
                segment: PriceSegment.wholesale,
                unitMultiplier: 10,
              ),
            ],
          ),
          _transaction(
            id: 'single-sale',
            kind: TransactionKind.sale,
            createdAt: DateTime(2026, 7, 13, 10),
            amount: 20000,
            lines: const [
              TransactionLine(
                productId: 'coffee',
                productName: 'Kopi Sachet',
                quantity: 2,
                unit: SaleUnit.sachet,
                unitPrice: 10000,
                costPrice: 5000,
                segment: PriceSegment.retail,
              ),
            ],
          ),
          _transaction(
            id: 'other-sale',
            kind: TransactionKind.sale,
            createdAt: DateTime(2026, 7, 13, 11),
            amount: 75000,
            lines: const [
              TransactionLine(
                productId: '',
                productName: 'Es Teh Ad Hoc',
                quantity: 5,
                unit: SaleUnit.gelas,
                unitPrice: 15000,
                costPrice: 5000,
                segment: PriceSegment.retail,
              ),
            ],
          ),
        ],
        period: ReportPeriodType.today,
        now: now,
        limit: 2,
      );

      expect(result.items, hasLength(2));
      expect(result.items.first.name, 'Kopi Sachet');
      expect(result.items.first.quantity, 12);
      expect(result.items.first.unitLabel, 'satuan dasar');
      expect(result.items[1].name, 'Es Teh Ad Hoc');
    });

    test('uses a deterministic name tie-break', () {
      final result = service.topProducts(
        transactions: [
          _saleWithLine('z', 'Zebra', 2, DateTime(2026, 7, 13, 9)),
          _saleWithLine('a', 'Apel', 2, DateTime(2026, 7, 13, 10)),
        ],
        period: ReportPeriodType.today,
        now: now,
      );

      expect(result.productName, 'Apel');
    });

    test('adds fractional sales using their converted base quantity', () {
      final result = service.topProducts(
        transactions: [
          _transaction(
            id: 'weight-sale',
            kind: TransactionKind.sale,
            createdAt: DateTime(2026, 7, 13, 9),
            amount: 12000,
            lines: const [
              TransactionLine(
                productId: 'rice',
                productName: 'Beras',
                quantity: 0.5,
                unit: SaleUnit.kilo,
                unitPrice: 16000,
                costPrice: 10,
                segment: PriceSegment.retail,
                unitMultiplier: 1000,
              ),
              TransactionLine(
                productId: 'rice',
                productName: 'Beras',
                quantity: 250,
                unit: SaleUnit.gram,
                unitPrice: 16,
                costPrice: 10,
                segment: PriceSegment.retail,
              ),
            ],
          ),
        ],
        period: ReportPeriodType.today,
        now: now,
      );

      expect(result.productName, 'Beras');
      expect(result.quantity, 750);
      expect(result.unitLabel, 'satuan dasar');
    });
  });

  group('stock, wallet, and latest transaction', () {
    const products = [
      Product(
        id: 'zero',
        name: 'Stok Nol',
        category: 'Umum',
        costPrice: 0,
        retailPrice: 0,
        wholesalePrice: 0,
        packSize: 0,
        cartonSize: 0,
        stockPcs: 0,
      ),
      Product(
        id: 'low',
        name: 'Stok Lima',
        category: 'Umum',
        costPrice: 0,
        retailPrice: 0,
        wholesalePrice: 0,
        packSize: 0,
        cartonSize: 0,
        stockPcs: 5,
      ),
      Product(
        id: 'high',
        name: 'Stok Enam',
        category: 'Umum',
        costPrice: 0,
        retailPrice: 0,
        wholesalePrice: 0,
        packSize: 0,
        cartonSize: 0,
        stockPcs: 6,
      ),
    ];

    test(
      'low-stock policy includes tracked zero and per-product threshold',
      () {
        final result = service.lowStock(products);

        expect(result.countValue, 2);
        expect(result.items.map((item) => item.name), [
          'Stok Nol',
          'Stok Lima',
        ]);
        expect(result.items.first.stockStatus, ProductStockStatus.outOfStock);
      },
    );

    test('tracked zero is explicitly out of stock', () {
      final result = service.productStock(products.first);

      expect(result.quantity, 0);
      expect(result.stockTrackingUnknown, isFalse);
      expect(result.stockStatus, ProductStockStatus.outOfStock);
    });

    test('untracked zero is distinct from out of stock', () {
      final result = service.productStock(
        products.first.copyWith(trackStock: false),
      );

      expect(result.stockTrackingUnknown, isTrue);
      expect(result.stockStatus, ProductStockStatus.notTracked);
    });

    test(
      'low stock uses each product minimum and excludes untracked items',
      () {
        final result = service.lowStock([
          products.last.copyWith(stockPcs: 6, minStock: 10),
          products[1].copyWith(stockPcs: 4, minStock: 3),
          products.first.copyWith(stockPcs: 1, minStock: 5, trackStock: false),
        ]);

        expect(result.items, hasLength(1));
        expect(result.items.single.name, 'Stok Enam');
      },
    );

    test('wallet total includes supported negative balances', () {
      final result = service.walletBalance(
        wallets: const [
          Wallet(id: 'cash', name: 'Tunai', balance: 100000, isPrimary: true),
          Wallet(id: 'bank', name: 'Bank', balance: -25000, isPrimary: false),
        ],
        allWallets: true,
      );

      expect(result.moneyValue, 75000);
      expect(result.countValue, 2);
    });

    test('latest transaction supports a kind filter', () {
      final result = service.latestTransaction(
        transactions: [
          _transaction(
            id: 'sale',
            kind: TransactionKind.sale,
            createdAt: DateTime(2026, 7, 13, 9),
            amount: 10000,
          ),
          _transaction(
            id: 'expense',
            kind: TransactionKind.expense,
            createdAt: DateTime(2026, 7, 13, 12),
            amount: 5000,
            categoryName: 'Listrik',
          ),
        ],
        filter: BusinessTransactionFilter.sale,
      );

      expect(result.transactionKind, TransactionKind.sale);
      expect(result.occurredAt, DateTime(2026, 7, 13, 9));
    });
  });
}

TransactionRecord _saleWithLine(
  String id,
  String name,
  double quantity,
  DateTime createdAt,
) {
  return _transaction(
    id: id,
    kind: TransactionKind.sale,
    createdAt: createdAt,
    amount: (quantity * 10000).round(),
    lines: [
      TransactionLine(
        productId: id,
        productName: name,
        quantity: quantity,
        unit: SaleUnit.pcs,
        unitPrice: 10000,
        costPrice: 5000,
        segment: PriceSegment.retail,
      ),
    ],
  );
}

TransactionRecord _transaction({
  required String id,
  required TransactionKind kind,
  required DateTime createdAt,
  required int amount,
  String categoryName = 'Penjualan',
  List<TransactionLine> lines = const [],
}) {
  return TransactionRecord(
    id: id,
    kind: kind,
    createdAt: createdAt,
    walletId: 'wallet',
    walletName: 'Dompet Utama',
    categoryId: 'category',
    categoryName: categoryName,
    lines: lines,
    amount: amount,
    discount: 0,
    note: '',
    evidencePath: null,
    ocrSource: null,
    syncStatus: SyncStatus.localOnly,
  );
}
