import '../../models/mikiezy_models.dart';
import '../services/report_period_resolver.dart';

enum BusinessMetricType {
  revenue,
  sales,
  profit,
  income,
  expense,
  transactionCount,
  topProduct,
  productStock,
  lowStock,
  walletBalance,
  latestTransaction,
}

enum BusinessQueryStatus {
  success,
  empty,
  notFound,
  ambiguous,
  invalidPeriod,
  unsupported,
  failure,
}

enum BusinessTransactionFilter { all, sale, income, expense }

enum BusinessTopProductRanking { quantity, revenue }

class BusinessQueryItem {
  const BusinessQueryItem({
    required this.name,
    this.id,
    this.moneyValue,
    this.quantity,
    this.unitLabel,
    this.stockStatus,
  });

  final String? id;
  final String name;
  final int? moneyValue;
  final double? quantity;
  final String? unitLabel;
  final ProductStockStatus? stockStatus;
}

class BusinessQueryResult {
  const BusinessQueryResult({
    required this.metric,
    required this.status,
    this.period,
    this.moneyValue,
    this.revenueValue,
    this.costValue,
    this.countValue,
    this.saleCount,
    this.incomeCount,
    this.expenseCount,
    this.adjustmentCount,
    this.productName,
    this.quantity,
    this.unitLabel,
    this.walletName,
    this.items = const [],
    this.transactionKind,
    this.occurredAt,
    this.categoryName,
    this.note,
    this.itemCount,
    this.message,
    this.isEstimate = false,
    this.stockTrackingUnknown = false,
    this.isAggregate = false,
    this.isLargest = false,
    this.stockStatus,
    this.transactionFilter = BusinessTransactionFilter.all,
    this.topProductRanking = BusinessTopProductRanking.quantity,
  });

  final BusinessMetricType metric;
  final BusinessQueryStatus status;
  final ReportPeriodType? period;
  final int? moneyValue;
  final int? revenueValue;
  final int? costValue;
  final int? countValue;
  final int? saleCount;
  final int? incomeCount;
  final int? expenseCount;
  final int? adjustmentCount;
  final String? productName;
  final double? quantity;
  final String? unitLabel;
  final String? walletName;
  final List<BusinessQueryItem> items;
  final TransactionKind? transactionKind;
  final DateTime? occurredAt;
  final String? categoryName;
  final String? note;
  final int? itemCount;
  final String? message;
  final bool isEstimate;
  final bool stockTrackingUnknown;
  final bool isAggregate;
  final bool isLargest;
  final ProductStockStatus? stockStatus;
  final BusinessTransactionFilter transactionFilter;
  final BusinessTopProductRanking topProductRanking;

  bool get hasData => status == BusinessQueryStatus.success;
}
