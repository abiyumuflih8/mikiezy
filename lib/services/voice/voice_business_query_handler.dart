import 'package:flutter/foundation.dart';

import '../../domain/models/business_query_data.dart';
import '../../domain/models/business_query_result.dart';
import '../../domain/services/business_metrics_service.dart';
import '../../domain/services/report_period_resolver.dart';
import '../../models/mikiezy_models.dart';
import 'voice_command.dart';
import 'voice_product_resolver.dart';
import 'voice_privacy_guard.dart';
import 'voice_response_builder.dart';

class VoiceBusinessQueryHandler {
  const VoiceBusinessQueryHandler({
    this.metrics = const BusinessMetricsService(),
    this.productResolver = const VoiceProductResolver(),
    this.responseBuilder = const VoiceResponseBuilder(),
    this.privacyGuard = const VoicePrivacyGuard(),
  });

  final BusinessMetricsService metrics;
  final VoiceProductResolver productResolver;
  final VoiceResponseBuilder responseBuilder;
  final VoicePrivacyGuard privacyGuard;

  bool supports(VoiceCommandIntent intent) => intent.isBusinessQuery;

  VoiceCommandResponse handle({
    required VoiceCommand command,
    required BusinessQueryData data,
    required DateTime now,
  }) {
    if (data.privacyPolicy.isAppLocked) {
      return const VoiceCommandResponse(
        displayText:
            'Aplikasi masih terkunci. Buka kunci terlebih dahulu untuk melihat data bisnis.',
        spokenText:
            'Aplikasi masih terkunci. Buka kunci terlebih dahulu untuk melihat data bisnis.',
        kind: VoiceResponseKind.error,
        title: 'Aplikasi terkunci',
      );
    }
    try {
      final result = query(command: command, data: data, now: now);
      return responseFor(result: result, data: data);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Voice business query failed: $error\n$stackTrace');
      }
      return privacyGuard.protect(
        responseBuilder.business(
          BusinessQueryResult(
            metric: _metricFor(command.intent),
            status: BusinessQueryStatus.failure,
            message: 'Data belum dapat dibaca. Silakan coba lagi.',
          ),
        ),
        data.privacyPolicy,
      );
    }
  }

  VoiceCommandResponse responseFor({
    required BusinessQueryResult result,
    required BusinessQueryData data,
  }) {
    return privacyGuard.protect(
      responseBuilder.business(result),
      data.privacyPolicy,
    );
  }

  BusinessQueryResult query({
    required VoiceCommand command,
    required BusinessQueryData data,
    required DateTime now,
  }) {
    final metric = _metricFor(command.intent);
    if (!command.intent.isBusinessQuery) {
      return BusinessQueryResult(
        metric: metric,
        status: BusinessQueryStatus.unsupported,
        message: 'Pertanyaan tersebut belum didukung.',
      );
    }
    if (!data.isReady) {
      return BusinessQueryResult(
        metric: metric,
        status: BusinessQueryStatus.failure,
        message: 'Data bisnis masih dimuat. Silakan coba sebentar lagi.',
      );
    }
    if (data.sourceError != null) {
      if (kDebugMode) {
        debugPrint('Business data source error: ${data.sourceError}');
      }
      return BusinessQueryResult(
        metric: metric,
        status: BusinessQueryStatus.failure,
        message: 'Data belum dapat dibaca. Silakan coba lagi.',
      );
    }

    final period = _period(command.entities.period);
    return switch (command.intent) {
      VoiceCommandIntent.queryRevenue => metrics.revenue(
        transactions: data.transactions,
        period: period,
        now: now,
      ),
      VoiceCommandIntent.querySales => metrics.sales(
        transactions: data.transactions,
        period: period,
        now: now,
      ),
      VoiceCommandIntent.queryProfit => metrics.profit(
        transactions: data.transactions,
        period: period,
        now: now,
      ),
      VoiceCommandIntent.queryIncome => metrics.income(
        transactions: data.transactions,
        period: period,
        now: now,
      ),
      VoiceCommandIntent.queryExpense => metrics.expense(
        transactions: data.transactions,
        period: period,
        now: now,
        largestOnly: command.entities.largestExpense == true,
      ),
      VoiceCommandIntent.queryTransactionCount => metrics.transactionCount(
        transactions: data.transactions,
        period: period,
        now: now,
        filter: _transactionFilter(command.entities.transactionFilter),
      ),
      VoiceCommandIntent.queryTopProduct => metrics.topProducts(
        transactions: data.transactions,
        period: period,
        now: now,
        limit: command.entities.resultLimit ?? 1,
        ranking: _topProductRanking(command.entities.topProductRanking),
      ),
      VoiceCommandIntent.queryProductStock => _productStock(command, data),
      VoiceCommandIntent.queryLowStock => metrics.lowStock(data.products),
      VoiceCommandIntent.queryWalletBalance => _walletBalance(command, data),
      VoiceCommandIntent.queryLatestTransaction => metrics.latestTransaction(
        transactions: data.transactions,
        filter: _transactionFilter(command.entities.transactionFilter),
      ),
      _ => BusinessQueryResult(
        metric: metric,
        status: BusinessQueryStatus.unsupported,
      ),
    };
  }

  BusinessQueryResult _productStock(
    VoiceCommand command,
    BusinessQueryData data,
  ) {
    final spokenName = command.entities.productName?.trim() ?? '';
    if (spokenName.isEmpty) {
      return const BusinessQueryResult(
        metric: BusinessMetricType.productStock,
        status: BusinessQueryStatus.notFound,
        message: 'Nama produk belum disebutkan dengan jelas.',
      );
    }
    final match = productResolver.resolve(
      spokenName: spokenName,
      products: data.products,
      aliases: data.productAliases,
    );
    if (match.isMatched && match.product != null) {
      return metrics.productStock(match.product!);
    }
    final candidates = match.candidates
        .take(5)
        .map(
          (candidate) => BusinessQueryItem(
            id: candidate.product.id,
            name: candidate.product.name,
          ),
        )
        .toList(growable: false);
    if (match.type == VoiceProductMatchType.ambiguous) {
      final names = candidates.map((candidate) => candidate.name).toList();
      return BusinessQueryResult(
        metric: BusinessMetricType.productStock,
        status: BusinessQueryStatus.ambiguous,
        items: candidates,
        message: names.isEmpty
            ? 'Saya menemukan beberapa produk yang mirip. Sebutkan nama atau ukuran lebih lengkap.'
            : 'Saya menemukan ${_joinNatural(names)}. Sebutkan nama atau ukuran produk lebih lengkap.',
      );
    }
    return BusinessQueryResult(
      metric: BusinessMetricType.productStock,
      status: BusinessQueryStatus.notFound,
      items: candidates,
      message: 'Produk $spokenName belum ditemukan.',
    );
  }

  BusinessQueryResult _walletBalance(
    VoiceCommand command,
    BusinessQueryData data,
  ) {
    if (command.entities.allWallets == true) {
      return metrics.walletBalance(wallets: data.wallets, allWallets: true);
    }
    if (data.wallets.isEmpty) {
      return metrics.walletBalance(wallets: data.wallets);
    }
    if (command.entities.largestWallet == true) {
      final wallets = [...data.wallets]
        ..sort((left, right) {
          final balanceOrder = right.balance.compareTo(left.balance);
          return balanceOrder != 0
              ? balanceOrder
              : left.name.toLowerCase().compareTo(right.name.toLowerCase());
        });
      return metrics.walletBalance(
        wallets: data.wallets,
        wallet: wallets.first,
        largest: true,
      );
    }

    final spokenName = command.entities.walletName?.trim() ?? '';
    if (spokenName.isEmpty) {
      if (data.wallets.length == 1) {
        return metrics.walletBalance(
          wallets: data.wallets,
          wallet: data.wallets.single,
        );
      }
      return BusinessQueryResult(
        metric: BusinessMetricType.walletBalance,
        status: BusinessQueryStatus.ambiguous,
        items: data.wallets
            .take(5)
            .map(
              (wallet) => BusinessQueryItem(id: wallet.id, name: wallet.name),
            )
            .toList(growable: false),
        message: 'Sebutkan nama dompet, atau katakan saldo semua dompet.',
      );
    }
    final matches = _walletMatches(spokenName, data.wallets);
    if (matches.length == 1) {
      return metrics.walletBalance(
        wallets: data.wallets,
        wallet: matches.single,
      );
    }
    if (matches.length > 1) {
      final names = matches.map((wallet) => wallet.name).toList();
      return BusinessQueryResult(
        metric: BusinessMetricType.walletBalance,
        status: BusinessQueryStatus.ambiguous,
        items: matches
            .take(5)
            .map(
              (wallet) => BusinessQueryItem(id: wallet.id, name: wallet.name),
            )
            .toList(growable: false),
        message:
            'Saya menemukan ${_joinNatural(names.take(5).toList())}. Sebutkan nama dompet lebih lengkap.',
      );
    }
    return BusinessQueryResult(
      metric: BusinessMetricType.walletBalance,
      status: BusinessQueryStatus.notFound,
      message: 'Dompet $spokenName belum ditemukan.',
    );
  }

  List<Wallet> _walletMatches(String spokenName, List<Wallet> wallets) {
    final query = _normalize(spokenName);
    if (query.isEmpty) return const [];
    final exact = wallets
        .where((wallet) => _normalize(wallet.name) == query)
        .toList(growable: false);
    if (exact.isNotEmpty) return exact;

    final queryTokens = query.split(' ').where((token) => token.isNotEmpty);
    return wallets
        .where((wallet) {
          final walletName = _normalize(wallet.name);
          final walletTokens = walletName.split(' ').toSet();
          return walletName.contains(query) ||
              queryTokens.every(walletTokens.contains);
        })
        .toList(growable: false);
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  ReportPeriodType _period(VoiceCommandPeriod? period) {
    return switch (period) {
      VoiceCommandPeriod.today || null => ReportPeriodType.today,
      VoiceCommandPeriod.yesterday => ReportPeriodType.yesterday,
      VoiceCommandPeriod.thisWeek => ReportPeriodType.thisWeek,
      VoiceCommandPeriod.lastWeek => ReportPeriodType.lastWeek,
      VoiceCommandPeriod.thisMonth => ReportPeriodType.thisMonth,
      VoiceCommandPeriod.lastMonth => ReportPeriodType.lastMonth,
      VoiceCommandPeriod.allTime => ReportPeriodType.allTime,
    };
  }

  BusinessTransactionFilter _transactionFilter(VoiceTransactionFilter? filter) {
    return switch (filter) {
      VoiceTransactionFilter.sale => BusinessTransactionFilter.sale,
      VoiceTransactionFilter.income => BusinessTransactionFilter.income,
      VoiceTransactionFilter.expense => BusinessTransactionFilter.expense,
      VoiceTransactionFilter.all || null => BusinessTransactionFilter.all,
    };
  }

  BusinessTopProductRanking _topProductRanking(
    VoiceTopProductRanking? ranking,
  ) {
    return switch (ranking) {
      VoiceTopProductRanking.revenue => BusinessTopProductRanking.revenue,
      VoiceTopProductRanking.quantity ||
      null => BusinessTopProductRanking.quantity,
    };
  }

  BusinessMetricType _metricFor(VoiceCommandIntent intent) {
    return switch (intent) {
      VoiceCommandIntent.queryRevenue => BusinessMetricType.revenue,
      VoiceCommandIntent.querySales => BusinessMetricType.sales,
      VoiceCommandIntent.queryProfit => BusinessMetricType.profit,
      VoiceCommandIntent.queryIncome => BusinessMetricType.income,
      VoiceCommandIntent.queryExpense => BusinessMetricType.expense,
      VoiceCommandIntent.queryTransactionCount =>
        BusinessMetricType.transactionCount,
      VoiceCommandIntent.queryTopProduct => BusinessMetricType.topProduct,
      VoiceCommandIntent.queryProductStock => BusinessMetricType.productStock,
      VoiceCommandIntent.queryLowStock => BusinessMetricType.lowStock,
      VoiceCommandIntent.queryWalletBalance => BusinessMetricType.walletBalance,
      VoiceCommandIntent.queryLatestTransaction =>
        BusinessMetricType.latestTransaction,
      _ => BusinessMetricType.transactionCount,
    };
  }

  String _joinNatural(List<String> values) {
    if (values.isEmpty) return '';
    if (values.length == 1) return values.first;
    if (values.length == 2) return '${values.first} dan ${values.last}';
    return '${values.take(values.length - 1).join(', ')}, dan ${values.last}';
  }
}
