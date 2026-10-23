import '../../domain/models/business_query_result.dart';
import '../../domain/models/product_price.dart';

enum VoiceCommandIntent {
  createSale,
  createIncome,
  createExpense,
  createProduct,
  incrementProductStock,
  updateProduct,
  queryProfit,
  queryRevenue,
  querySales,
  queryIncome,
  queryExpense,
  queryTransactionCount,
  queryTopProduct,
  queryProductStock,
  queryLowStock,
  queryWalletBalance,
  queryLatestTransaction,
  navigateDashboard,
  navigateTransactions,
  navigateProducts,
  navigateReports,
  navigateAnalytics,
  navigateWallets,
  navigateCategories,
  navigateSettings,
  navigateEditProfile,
  navigateVoiceEntry,
  goBack,
  unknown,
}

extension VoiceCommandIntentX on VoiceCommandIntent {
  bool get isTransaction => switch (this) {
    VoiceCommandIntent.createSale ||
    VoiceCommandIntent.createIncome ||
    VoiceCommandIntent.createExpense => true,
    _ => false,
  };

  bool get isNavigation => switch (this) {
    VoiceCommandIntent.navigateDashboard ||
    VoiceCommandIntent.navigateTransactions ||
    VoiceCommandIntent.navigateProducts ||
    VoiceCommandIntent.navigateReports ||
    VoiceCommandIntent.navigateAnalytics ||
    VoiceCommandIntent.navigateWallets ||
    VoiceCommandIntent.navigateCategories ||
    VoiceCommandIntent.navigateSettings ||
    VoiceCommandIntent.navigateEditProfile ||
    VoiceCommandIntent.navigateVoiceEntry ||
    VoiceCommandIntent.goBack => true,
    _ => false,
  };

  bool get isBusinessQuery => switch (this) {
    VoiceCommandIntent.queryProfit ||
    VoiceCommandIntent.queryRevenue ||
    VoiceCommandIntent.querySales ||
    VoiceCommandIntent.queryIncome ||
    VoiceCommandIntent.queryExpense ||
    VoiceCommandIntent.queryTransactionCount ||
    VoiceCommandIntent.queryTopProduct ||
    VoiceCommandIntent.queryProductStock ||
    VoiceCommandIntent.queryLowStock ||
    VoiceCommandIntent.queryWalletBalance ||
    VoiceCommandIntent.queryLatestTransaction => true,
    _ => false,
  };

  bool get isMutation => switch (this) {
    VoiceCommandIntent.createProduct ||
    VoiceCommandIntent.incrementProductStock ||
    VoiceCommandIntent.updateProduct => true,
    _ => false,
  };

  bool get requiresConfirmation => switch (this) {
    VoiceCommandIntent.createSale ||
    VoiceCommandIntent.createIncome ||
    VoiceCommandIntent.createExpense ||
    VoiceCommandIntent.createProduct ||
    VoiceCommandIntent.incrementProductStock ||
    VoiceCommandIntent.updateProduct => true,
    _ => false,
  };
}

enum VoiceCommandPeriod {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  allTime,
}

enum VoiceTransactionFilter { all, sale, income, expense }

enum VoiceTopProductRanking { quantity, revenue }

enum VoiceNavigationTarget {
  dashboard,
  transactions,
  products,
  reports,
  analytics,
  wallets,
  categories,
  settings,
  editProfile,
  voiceEntry,
  back,
}

class VoiceIntentClassification {
  const VoiceIntentClassification({
    required this.intent,
    required this.confidence,
  });

  final VoiceCommandIntent intent;
  final double confidence;
}

class VoiceCommandEntities {
  const VoiceCommandEntities({
    this.productId,
    this.productName,
    this.quantity,
    this.unit,
    this.salePrice,
    this.costPrice,
    this.wholesalePrice,
    this.stock,
    this.trackStock,
    this.minStock,
    this.packSize,
    this.cartonSize,
    this.similarProductConfirmed,
    this.similarProductName,
    this.trackingEnableConfirmed,
    this.productPriceType,
    this.newProductPrice,
    this.bulkPriceUpdateRequested,
    this.clarificationOccurred,
    this.categoryName,
    this.walletName,
    this.period,
    this.transactionFilter,
    this.resultLimit,
    this.topProductRanking,
    this.allWallets,
    this.largestWallet,
    this.largestExpense,
    this.navigationTarget,
  });

  final String? productId;
  final String? productName;
  final double? quantity;
  final String? unit;
  final int? salePrice;
  final int? costPrice;
  final int? wholesalePrice;
  final double? stock;
  final bool? trackStock;
  final double? minStock;
  final int? packSize;
  final int? cartonSize;
  final bool? similarProductConfirmed;
  final String? similarProductName;
  final bool? trackingEnableConfirmed;
  final ProductPriceType? productPriceType;
  final int? newProductPrice;
  final bool? bulkPriceUpdateRequested;
  final bool? clarificationOccurred;
  final String? categoryName;
  final String? walletName;
  final VoiceCommandPeriod? period;
  final VoiceTransactionFilter? transactionFilter;
  final int? resultLimit;
  final VoiceTopProductRanking? topProductRanking;
  final bool? allWallets;
  final bool? largestWallet;
  final bool? largestExpense;
  final VoiceNavigationTarget? navigationTarget;

  VoiceCommandEntities merge(VoiceCommandEntities newer) {
    return VoiceCommandEntities(
      productId: newer.productId ?? productId,
      productName: newer.productName ?? productName,
      quantity: newer.quantity ?? quantity,
      unit: newer.unit ?? unit,
      salePrice: newer.salePrice ?? salePrice,
      costPrice: newer.costPrice ?? costPrice,
      wholesalePrice: newer.wholesalePrice ?? wholesalePrice,
      stock: newer.stock ?? stock,
      trackStock: newer.trackStock ?? trackStock,
      minStock: newer.minStock ?? minStock,
      packSize: newer.packSize ?? packSize,
      cartonSize: newer.cartonSize ?? cartonSize,
      similarProductConfirmed:
          newer.similarProductConfirmed ?? similarProductConfirmed,
      similarProductName: newer.similarProductName ?? similarProductName,
      trackingEnableConfirmed:
          newer.trackingEnableConfirmed ?? trackingEnableConfirmed,
      productPriceType: newer.productPriceType ?? productPriceType,
      newProductPrice: newer.newProductPrice ?? newProductPrice,
      bulkPriceUpdateRequested:
          newer.bulkPriceUpdateRequested ?? bulkPriceUpdateRequested,
      clarificationOccurred:
          newer.clarificationOccurred ?? clarificationOccurred,
      categoryName: newer.categoryName ?? categoryName,
      walletName: newer.walletName ?? walletName,
      period: newer.period ?? period,
      transactionFilter: newer.transactionFilter ?? transactionFilter,
      resultLimit: newer.resultLimit ?? resultLimit,
      topProductRanking: newer.topProductRanking ?? topProductRanking,
      allWallets: newer.allWallets ?? allWallets,
      largestWallet: newer.largestWallet ?? largestWallet,
      largestExpense: newer.largestExpense ?? largestExpense,
      navigationTarget: newer.navigationTarget ?? navigationTarget,
    );
  }
}

class VoiceCommand {
  const VoiceCommand({
    required this.rawText,
    required this.normalizedText,
    required this.intent,
    required this.entities,
    required this.confidence,
    this.hasMultipleIntents = false,
  });

  final String rawText;
  final String normalizedText;
  final VoiceCommandIntent intent;
  final VoiceCommandEntities entities;
  final double confidence;
  final bool hasMultipleIntents;
}

enum VoiceResponseKind { information, question, confirmation, error }

class VoiceCommandResponse {
  const VoiceCommandResponse({
    required this.displayText,
    String? spokenText,
    this.kind = VoiceResponseKind.information,
    this.title,
    this.businessResult,
    this.suggestedAction,
  }) : spokenText = spokenText ?? displayText;

  final String displayText;
  final String spokenText;
  final VoiceResponseKind kind;
  final String? title;
  final BusinessQueryResult? businessResult;
  final String? suggestedAction;
}

class VoiceCommandExecutionResult {
  const VoiceCommandExecutionResult({
    required this.command,
    required this.response,
    required this.handled,
  });

  final VoiceCommand command;
  final VoiceCommandResponse response;
  final bool handled;
}
