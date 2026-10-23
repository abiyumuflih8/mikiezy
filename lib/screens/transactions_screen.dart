import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_dimensions.dart';
import '../core/formatters.dart';
import '../models/mikiezy_models.dart';
import '../shared/widgets/mikiezy_components.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/mikiezy_card.dart';
import 'receipt_screen.dart';

enum TransactionPeriod { daily, weekly, monthly }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionPeriod period = TransactionPeriod.daily;
  String search = '';
  bool requestedRefresh = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (requestedRefresh) return;
    requestedRefresh = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(MikiezyScope.of(context).refreshTransactions());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = MikiezyScope.of(context);
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final en = state.language == AppLanguage.en;
        final transactions = _filteredTransactions(state.transactions);
        return AppShell(
          title: en ? 'Transactions' : 'Transaksi',
          currentIndex: 1,
          showAppBar: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            children: [
              _Header(en: en, totalTransactions: state.transactions.length),
              const SizedBox(height: AppSpacing.sm),
              _SearchField(
                en: en,
                value: search,
                onChanged: (value) => setState(() => search = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PeriodTabs(
                en: en,
                period: period,
                onChanged: (value) => setState(() => period = value),
              ),
              const SizedBox(height: AppSpacing.md),
              _SummaryStrip(en: en, transactions: transactions),
              const SizedBox(height: AppSpacing.md),
              if (state.transactionsError != null) ...[
                _StateNotice(
                  icon: Icons.warning_amber_rounded,
                  title: en ? 'Could not refresh data' : 'Data belum termuat',
                  message: en
                      ? 'Showing the last local transaction cache.'
                      : 'Menampilkan cache transaksi lokal terakhir.',
                  color: AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AnimatedSwitcher(
                duration: AppDurations.normal,
                switchInCurve: Curves.easeOutCubic,
                child: state.transactionsLoading && state.transactions.isEmpty
                    ? _LoadingState(key: const ValueKey('loading'), en: en)
                    : transactions.isEmpty
                    ? _EmptyState(key: const ValueKey('empty'), en: en)
                    : _TransactionGroups(
                        key: ValueKey('${period.name}-$search'),
                        transactions: transactions,
                        en: en,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<TransactionRecord> _filteredTransactions(
    List<TransactionRecord> transactions,
  ) {
    final now = DateTime.now();
    final query = search.toLowerCase().trim();
    final filtered = transactions.where((tx) {
      final matchesPeriod = switch (period) {
        TransactionPeriod.daily => DateUtils.isSameDay(tx.createdAt, now),
        TransactionPeriod.weekly => now.difference(tx.createdAt).inDays < 7,
        TransactionPeriod.monthly =>
          tx.createdAt.year == now.year && tx.createdAt.month == now.month,
      };
      if (!matchesPeriod) return false;
      if (query.isEmpty) return true;
      final primaryName = tx.kind == TransactionKind.sale && tx.lines.isNotEmpty
          ? tx.lines.first.productName
          : tx.categoryName;
      return primaryName.toLowerCase().contains(query) ||
          tx.walletName.toLowerCase().contains(query) ||
          tx.categoryName.toLowerCase().contains(query);
    }).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.en, required this.totalTransactions});

  final bool en;
  final int totalTransactions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  en ? 'Sales History' : 'Riwayat Transaksi',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  en
                      ? '$totalTransactions transactions total'
                      : '$totalTransactions transaksi tersimpan',
                  style: const TextStyle(color: AppColors.faint, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: en ? 'Filter' : 'Filter',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  en
                      ? 'Advanced filters are coming soon.'
                      : 'Filter lanjutan segera hadir.',
                ),
              ),
            ),
            icon: const Icon(Icons.filter_list_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.en,
    required this.value,
    required this.onChanged,
  });

  final bool en;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: en ? 'Search transactions...' : 'Cari transaksi...',
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({
    required this.en,
    required this.period,
    required this.onChanged,
  });

  final bool en;
  final TransactionPeriod period;
  final ValueChanged<TransactionPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return MikiezySegmentedControl<TransactionPeriod>(
      values: TransactionPeriod.values,
      selected: period,
      labelBuilder: (value) => switch (value) {
        TransactionPeriod.daily => en ? 'Daily' : 'Harian',
        TransactionPeriod.weekly => en ? 'Weekly' : 'Mingguan',
        TransactionPeriod.monthly => en ? 'Monthly' : 'Bulanan',
      },
      onChanged: onChanged,
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.en, required this.transactions});

  final bool en;
  final List<TransactionRecord> transactions;

  @override
  Widget build(BuildContext context) {
    final revenue = transactions
        .where(
          (tx) =>
              tx.kind == TransactionKind.sale ||
              tx.kind == TransactionKind.income,
        )
        .fold(0, (sum, tx) => sum + tx.amount);
    final avg = transactions.isEmpty ? 0 : (revenue / transactions.length);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1117), Color(0xFF1C1E2E)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          _SummaryMetric(
            label: en ? 'Revenue' : 'Pemasukan',
            value: compactRupiah(revenue),
          ),
          _Divider(),
          _SummaryMetric(
            label: en ? 'Transactions' : 'Transaksi',
            value: '${transactions.length}',
          ),
          _Divider(),
          _SummaryMetric(
            label: en ? 'Avg / Tx' : 'Rata-rata',
            value: compactRupiah(avg.round()),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionGroups extends StatelessWidget {
  const _TransactionGroups({
    super.key,
    required this.transactions,
    required this.en,
  });

  final List<TransactionRecord> transactions;
  final bool en;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<TransactionRecord>>{};
    for (final tx in transactions) {
      final label = _groupLabel(tx.createdAt);
      grouped.putIfAbsent(label, () => []).add(tx);
    }

    return Column(
      children: [
        for (final entry in grouped.entries) ...[
          _DateSectionLabel(label: entry.key),
          MikiezyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < entry.value.length; i++) ...[
                  _TransactionTile(transaction: entry.value[i], en: en),
                  if (i < entry.value.length - 1)
                    const Divider(height: 1, color: AppColors.border),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  String _groupLabel(DateTime date) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(date, now)) return en ? 'Today' : 'Hari ini';
    if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return en ? 'Yesterday' : 'Kemarin';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _DateSectionLabel extends StatelessWidget {
  const _DateSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.faint,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 9),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.en});

  final TransactionRecord transaction;
  final bool en;

  @override
  Widget build(BuildContext context) {
    final isSale = transaction.kind == TransactionKind.sale;
    final isExpense = transaction.kind == TransactionKind.expense;
    final title = isSale && transaction.lines.isNotEmpty
        ? transaction.lines.first.productName
        : transaction.categoryName;
    final qty = transaction.lines.isNotEmpty
        ? '${en ? 'Qty' : 'Jumlah'}: ${quantityLabel(transaction.lines.first.quantity)} - ${timeLabel(transaction.createdAt)}'
        : '${transaction.kind.label} - ${timeLabel(transaction.createdAt)}';
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            transaction: transaction,
            transactionId: transaction.id,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSale
                    ? Icons.shopping_bag_outlined
                    : isExpense
                    ? Icons.receipt_long_outlined
                    : Icons.account_balance_wallet_outlined,
                color: isSale
                    ? AppColors.success
                    : isExpense
                    ? AppColors.danger
                    : AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          qty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.faint,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (transaction.note.trim().isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mic_rounded,
                                size: 9,
                                color: AppColors.accent,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'AI',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rupiah(transaction.amount),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.faint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({super.key, required this.en});

  final bool en;

  @override
  Widget build(BuildContext context) {
    return MikiezyCard(
      child: Column(
        children: [
          const SizedBox(height: 4),
          const CircularProgressIndicator(strokeWidth: 2.4),
          const SizedBox(height: 14),
          Text(
            en ? 'Loading local transactions...' : 'Memuat transaksi lokal...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateNotice extends StatelessWidget {
  const _StateNotice({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MikiezyCard(
      padding: const EdgeInsets.all(14),
      radius: AppRadius.sm,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.10),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key, required this.en});

  final bool en;

  @override
  Widget build(BuildContext context) {
    return MikiezyEmptyState(
      icon: Icons.shopping_bag_outlined,
      title: en ? 'No transactions yet' : 'Belum ada transaksi',
      message: en
          ? 'Start by recording or entering your first sale.'
          : 'Mulai dengan mencatat transaksi lewat suara atau input manual.',
    );
  }
}
