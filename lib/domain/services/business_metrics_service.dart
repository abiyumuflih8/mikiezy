import '../../models/mikiezy_models.dart';
import '../models/business_query_result.dart';
import 'report_period_resolver.dart';

class BusinessMetricsService {
  const BusinessMetricsService({
    this.periodResolver = const ReportPeriodResolver(),
  });

  final ReportPeriodResolver periodResolver;

  BusinessQueryResult revenue({
    required List<TransactionRecord> transactions,
    required ReportPeriodType period,
    required DateTime now,
    BusinessMetricType metric = BusinessMetricType.revenue,
  }) {
    final sales = _transactionsInPeriod(transactions, period, now)
        .where((transaction) => transaction.kind == TransactionKind.sale)
        .toList(growable: false);
    if (sales.isEmpty) {
      return BusinessQueryResult(
        metric: metric,
        status: BusinessQueryStatus.empty,
        period: period,
      );
    }
    return BusinessQueryResult(
      metric: metric,
      status: BusinessQueryStatus.success,
      period: period,
      moneyValue: _sumAmounts(sales),
      countValue: sales.length,
      saleCount: sales.length,
    );
  }

  BusinessQueryResult sales({
    required List<TransactionRecord> transactions,
    required ReportPeriodType period,
    required DateTime now,
  }) {
    return revenue(
      transactions: transactions,
      period: period,
      now: now,
      metric: BusinessMetricType.sales,
    );
  }

  BusinessQueryResult profit({
    required List<TransactionRecord> transactions,
    required ReportPeriodType period,
    required DateTime now,
  }) {
    final relevant = _transactionsInPeriod(transactions, period, now)
        .where(
          (transaction) =>
              transaction.kind == TransactionKind.sale ||
              transaction.kind == TransactionKind.income ||
              transaction.kind == TransactionKind.expense,
        )
        .toList(growable: false);
    if (relevant.isEmpty) {
      return BusinessQueryResult(
        metric: BusinessMetricType.profit,
        status: BusinessQueryStatus.empty,
        period: period,
      );
    }

    final sales = relevant
        .where((transaction) => transaction.kind == TransactionKind.sale)
        .toList(growable: false);
    final incomes = relevant
        .where((transaction) => transaction.kind == TransactionKind.income)
        .toList(growable: false);
    final expenses = relevant
        .where((transaction) => transaction.kind == TransactionKind.expense)
        .toList(growable: false);
    final revenue = _sumAmounts(sales);
    final cost = sales.fold<int>(
      0,
      (sum, transaction) => sum + transaction.totalCost,
    );
    final income = _sumAmounts(incomes);
    final expense = _sumAmounts(expenses);
    final hasIncompleteCost = sales.any(
      (transaction) => transaction.lines.any(
        (line) => line.unitPrice > 0 && line.costPrice <= 0,
      ),
    );

    return BusinessQueryResult(
      metric: BusinessMetricType.profit,
      status: BusinessQueryStatus.success,
      period: period,
      moneyValue: revenue - cost + income - expense,
      revenueValue: revenue,
      costValue: cost,
      countValue: relevant.length,
      saleCount: sales.length,
      incomeCount: incomes.length,
      expenseCount: expenses.length,
      isEstimate: hasIncompleteCost,
    );
  }

  BusinessQueryResult income({
    required List<TransactionRecord> transactions,
    required ReportPeriodType period,
    required DateTime now,
  }) {
    final incomes = _transactionsInPeriod(transactions, period, now)
        .where((transaction) => transaction.kind == TransactionKind.income)
        .toList(growable: false);
    if (incomes.isEmpty) {
      return BusinessQueryResult(
        metric: BusinessMetricType.income,
        status: BusinessQueryStatus.empty,
        period: period,
      );
    }
    return BusinessQueryResult(
      metric: BusinessMetricType.income,
      status: BusinessQueryStatus.success,
      period: period,
      moneyValue: _sumAmounts(incomes),
      countValue: incomes.length,
      incomeCount: incomes.length,
    );
  }

  BusinessQueryResult expense({
    required List<TransactionRecord> transactions,
    required ReportPeriodType period,
    required DateTime now,
    bool largestOnly = false,
  }) {
    final expenses = _transactionsInPeriod(transactions, period, now)
        .where((transaction) => transaction.kind == TransactionKind.expense)
        .toList(growable: false);
    if (expenses.isEmpty) {
      return BusinessQueryResult(
        metric: BusinessMetricType.expense,
        status: BusinessQueryStatus.empty,
        period: period,
      );
    }
    if (largestOnly) {
      expenses.sort((left, right) {
        final amountOrder = right.amount.compareTo(left.amount);
        return amountOrder != 0
            ? amountOrder
            : right.createdAt.compareTo(left.createdAt);
      });
      final largest = expenses.first;
      return BusinessQueryResult(
        metric: BusinessMetricType.expense,
        status: BusinessQueryStatus.success,
        period: period,
        moneyValue: largest.amount,
        countValue: expenses.length,
        expenseCount: expenses.length,
        categoryName: largest.categoryName,
        note: largest.note,
        occurredAt: largest.createdAt,
        isLargest: true,
      );
    }
    return BusinessQueryResult(
      metric: BusinessMetricType.expense,
      status: BusinessQueryStatus.success,
      period: period,
      moneyValue: _sumAmounts(expenses),
      countValue: expenses.length,
      expenseCount: expenses.length,
    );
  }

  BusinessQueryResult transactionCount({
    required List<TransactionRecord> transactions,
    required ReportPeriodType period,
    required DateTime now,
    BusinessTransactionFilter filter = BusinessTransactionFilter.all,
  }) {
    final filtered = _transactionsInPeriod(transactions, period, now)
        .where((transaction) => _matchesFilter(transaction, filter))
        .toList(growable: false);
    if (filtered.isEmpty) {
      return BusinessQueryResult(
        metric: BusinessMetricType.transactionCount,
        status: BusinessQueryStatus.empty,
        period: period,
        transactionFilter: filter,
      );
    }
    final sales = filtered
        .where((transaction) => transaction.kind == TransactionKind.sale)
        .length;
    final incomes = filtered
        .where((transaction) => transaction.kind == TransactionKind.income)
        .length;
    final expenses = filtered
        .where((transaction) => transaction.kind == TransactionKind.expense)
        .length;
    final adjustments = filtered
        .where((transaction) => transaction.kind == TransactionKind.adjustment)
        .length;
    return BusinessQueryResult(
      metric: BusinessMetricType.transactionCount,
      status: BusinessQueryStatus.success,
      period: period,
      countValue: filtered.length,
      saleCount: sales,
      incomeCount: incomes,
      expenseCount: expenses,
      adjustmentCount: adjustments,
      transactionFilter: filter,
    );
  }

  List<BusinessQueryItem> expenseByCategory({
    required List<TransactionRecord> transactions,
    required ReportPeriodType period,
    required DateTime now,
  }) {
    final totals = <String, int>{};
    for (final transaction in _transactionsInPeriod(
      transactions,
      period,
      now,
    ).where((item) => item.kind == TransactionKind.expense)) {
      final category = transaction.categoryName.trim().isEmpty
          ? 'Tanpa kategori'
          : transaction.categoryName.trim();
      totals[category] = (totals[category] ?? 0) + transaction.amount;
    }
    final items = totals.entries
        .map(
          (entry) =>
              BusinessQueryItem(name: entry.key, moneyValue: entry.value),
        )
        .toList(growable: false);
    items.sort((left, right) {
      final amountOrder = (right.moneyValue ?? 0).compareTo(
        left.moneyValue ?? 0,
      );
      return amountOrder != 0
          ? amountOrder
          : left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
    return items;
  }

  BusinessQueryResult topProducts({
    required List<TransactionRecord> transactions,
    required ReportPeriodType period,
    required DateTime now,
    int limit = 1,
    BusinessTopProductRanking ranking = BusinessTopProductRanking.quantity,
  }) {
    final sales =
        _transactionsInPeriod(transactions, period, now)
            .where((transaction) => transaction.kind == TransactionKind.sale)
            .toList(growable: false)
          ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    final totals = <String, _ProductTotal>{};
    for (final transaction in sales) {
      final gross = transaction.lines.fold<int>(
        0,
        (sum, line) => sum + line.total,
      );
      for (final line in transaction.lines) {
        if (line.quantity <= 0 || line.unitMultiplier <= 0) continue;
        final normalizedName = line.productName
            .toLowerCase()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (normalizedName.isEmpty) continue;
        final productId = line.productId.trim();
        final key = productId.isEmpty
            ? 'name:$normalizedName'
            : 'id:$productId';
        final allocatedRevenue = gross <= 0
            ? line.total
            : (line.total * transaction.amount / gross).round();
        final total = totals.putIfAbsent(
          key,
          () => _ProductTotal(
            id: productId.isEmpty ? null : productId,
            name: line.productName,
            latestAt: transaction.createdAt,
          ),
        );
        total.quantity += line.quantity * line.unitMultiplier;
        total.revenue += allocatedRevenue;
        total.units.add(line.unit);
        total.convertedToBaseUnit =
            total.convertedToBaseUnit || line.unitMultiplier != 1;
        if (!transaction.createdAt.isBefore(total.latestAt)) {
          total.name = line.productName;
          total.latestAt = transaction.createdAt;
        }
      }
    }

    final ranked = totals.values.toList()
      ..sort((left, right) {
        final rankOrder = ranking == BusinessTopProductRanking.revenue
            ? right.revenue.compareTo(left.revenue)
            : right.quantity.compareTo(left.quantity);
        if (rankOrder != 0) return rankOrder;
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });
    if (ranked.isEmpty) {
      return BusinessQueryResult(
        metric: BusinessMetricType.topProduct,
        status: BusinessQueryStatus.empty,
        period: period,
        topProductRanking: ranking,
      );
    }

    final safeLimit = limit.clamp(1, 5).toInt();
    final items = ranked
        .take(safeLimit)
        .map((total) {
          final hasComparableUnit =
              !total.convertedToBaseUnit && total.units.length == 1;
          return BusinessQueryItem(
            id: total.id,
            name: total.name,
            moneyValue: total.revenue,
            quantity: total.quantity,
            unitLabel: hasComparableUnit
                ? total.units.single.label
                : 'satuan dasar',
          );
        })
        .toList(growable: false);
    final first = items.first;
    return BusinessQueryResult(
      metric: BusinessMetricType.topProduct,
      status: BusinessQueryStatus.success,
      period: period,
      productName: first.name,
      quantity: first.quantity,
      unitLabel: first.unitLabel,
      moneyValue: first.moneyValue,
      countValue: sales.length,
      saleCount: sales.length,
      items: items,
      topProductRanking: ranking,
    );
  }

  BusinessQueryResult productStock(Product product) {
    return BusinessQueryResult(
      metric: BusinessMetricType.productStock,
      status: BusinessQueryStatus.success,
      productName: product.name,
      quantity: product.stockPcs,
      unitLabel: product.baseUnit.label,
      stockTrackingUnknown: !product.trackStock,
      stockStatus: product.stockStatus,
    );
  }

  BusinessQueryResult lowStock(List<Product> products) {
    final lowStock =
        products
            .where(
              (product) =>
                  product.stockStatus == ProductStockStatus.outOfStock ||
                  product.stockStatus == ProductStockStatus.low,
            )
            .toList(growable: false)
          ..sort((left, right) {
            final stockOrder = left.stockPcs.compareTo(right.stockPcs);
            return stockOrder != 0
                ? stockOrder
                : left.name.toLowerCase().compareTo(right.name.toLowerCase());
          });
    if (lowStock.isEmpty) {
      return const BusinessQueryResult(
        metric: BusinessMetricType.lowStock,
        status: BusinessQueryStatus.empty,
      );
    }
    final items = lowStock
        .map(
          (product) => BusinessQueryItem(
            id: product.id,
            name: product.name,
            quantity: product.stockPcs,
            unitLabel: product.baseUnit.label,
            stockStatus: product.stockStatus,
          ),
        )
        .toList(growable: false);
    return BusinessQueryResult(
      metric: BusinessMetricType.lowStock,
      status: BusinessQueryStatus.success,
      countValue: items.length,
      items: items,
    );
  }

  BusinessQueryResult walletBalance({
    required List<Wallet> wallets,
    Wallet? wallet,
    bool allWallets = false,
    bool largest = false,
  }) {
    if (wallets.isEmpty) {
      return const BusinessQueryResult(
        metric: BusinessMetricType.walletBalance,
        status: BusinessQueryStatus.empty,
      );
    }
    if (allWallets) {
      return BusinessQueryResult(
        metric: BusinessMetricType.walletBalance,
        status: BusinessQueryStatus.success,
        moneyValue: wallets.fold<int>(
          0,
          (sum, current) => sum + current.balance,
        ),
        countValue: wallets.length,
        items: wallets
            .map(
              (current) => BusinessQueryItem(
                id: current.id,
                name: current.name,
                moneyValue: current.balance,
              ),
            )
            .toList(growable: false),
        isAggregate: true,
      );
    }
    if (wallet == null) {
      return const BusinessQueryResult(
        metric: BusinessMetricType.walletBalance,
        status: BusinessQueryStatus.notFound,
      );
    }
    return BusinessQueryResult(
      metric: BusinessMetricType.walletBalance,
      status: BusinessQueryStatus.success,
      moneyValue: wallet.balance,
      walletName: wallet.name,
      isLargest: largest,
    );
  }

  BusinessQueryResult latestTransaction({
    required List<TransactionRecord> transactions,
    BusinessTransactionFilter filter = BusinessTransactionFilter.all,
  }) {
    final filtered =
        transactions
            .where(
              (transaction) =>
                  transaction.amount >= 0 &&
                  _matchesFilter(transaction, filter),
            )
            .toList(growable: false)
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    if (filtered.isEmpty) {
      return BusinessQueryResult(
        metric: BusinessMetricType.latestTransaction,
        status: BusinessQueryStatus.empty,
        transactionFilter: filter,
      );
    }
    final latest = filtered.first;
    return BusinessQueryResult(
      metric: BusinessMetricType.latestTransaction,
      status: BusinessQueryStatus.success,
      moneyValue: latest.amount,
      productName: latest.lines.isEmpty ? null : latest.lines.first.productName,
      quantity: latest.lines.length == 1 ? latest.lines.first.quantity : null,
      unitLabel: latest.lines.length == 1
          ? latest.lines.first.unit.label
          : null,
      transactionKind: latest.kind,
      occurredAt: latest.createdAt,
      categoryName: latest.categoryName,
      note: latest.note,
      itemCount: latest.lines.length,
      transactionFilter: filter,
    );
  }

  List<TransactionRecord> _transactionsInPeriod(
    List<TransactionRecord> transactions,
    ReportPeriodType period,
    DateTime now,
  ) {
    final range = periodResolver.resolve(period, now: now);
    return transactions
        .where(
          (transaction) =>
              transaction.amount >= 0 && range.contains(transaction.createdAt),
        )
        .toList(growable: false);
  }

  bool _matchesFilter(
    TransactionRecord transaction,
    BusinessTransactionFilter filter,
  ) {
    return switch (filter) {
      BusinessTransactionFilter.all => true,
      BusinessTransactionFilter.sale =>
        transaction.kind == TransactionKind.sale,
      BusinessTransactionFilter.income =>
        transaction.kind == TransactionKind.income,
      BusinessTransactionFilter.expense =>
        transaction.kind == TransactionKind.expense,
    };
  }

  int _sumAmounts(Iterable<TransactionRecord> transactions) {
    return transactions.fold<int>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
  }
}

class _ProductTotal {
  _ProductTotal({required this.id, required this.name, required this.latestAt});

  final String? id;
  String name;
  DateTime latestAt;
  double quantity = 0;
  int revenue = 0;
  bool convertedToBaseUnit = false;
  final Set<SaleUnit> units = {};
}
