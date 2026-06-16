import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_dimensions.dart';
import '../core/formatters.dart';
import '../models/mikiezy_models.dart';
import '../services/report_action_service.dart';
import '../shared/widgets/mikiezy_components.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/mikiezy_card.dart';

enum AnalyticsPeriod { weekly, monthly }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  AnalyticsPeriod period = AnalyticsPeriod.weekly;

  @override
  Widget build(BuildContext context) {
    final state = MikiezyScope.of(context);
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final en = state.language == AppLanguage.en;
        final chartData = _chartData(state, period);
        return AppShell(
          title: en ? 'Analytics' : 'Analitik',
          currentIndex: 2,
          actions: [
            IconButton(
              tooltip: en ? 'Share report' : 'Bagikan laporan',
              onPressed: () =>
                  ReportActionService.shareReportToWhatsApp(context, state, en),
              icon: const Icon(Icons.share_rounded),
            ),
          ],
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _PeriodSelector(
                period: period,
                en: en,
                onChanged: (value) => setState(() => period = value),
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: AppDurations.normal,
                switchInCurve: Curves.easeOutCubic,
                child: _ChartCard(
                  key: ValueKey(period),
                  en: en,
                  period: period,
                  data: chartData,
                  total: chartData.fold(0, (sum, point) => sum + point.value),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _MetricWrap(
                children: [
                  MetricTile(
                    label: en ? 'Total Revenue' : 'Total pemasukan',
                    value: compactRupiah(state.incomeTotal),
                    icon: Icons.bar_chart_rounded,
                    color: AppColors.accent,
                    subLabel: '+8.2%',
                  ),
                  MetricTile(
                    label: en ? 'Transactions' : 'Transaksi',
                    value: '${state.monthlyTransactions}',
                    icon: Icons.shopping_cart_outlined,
                    color: AppColors.success,
                    subLabel: en ? 'This month' : 'Bulan ini',
                  ),
                  MetricTile(
                    label: en ? 'Expenses' : 'Pengeluaran',
                    value: compactRupiah(state.expenseTotal),
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.danger,
                    subLabel: en ? 'Operational' : 'Operasional',
                  ),
                  MetricTile(
                    label: en ? 'Net Profit' : 'Laba bersih',
                    value: compactRupiah(state.grossProfit),
                    icon: Icons.insights_rounded,
                    color: state.grossProfit >= 0
                        ? AppColors.success
                        : AppColors.danger,
                    subLabel: en ? 'Estimated' : 'Estimasi',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _TopProductsCard(state: state, en: en),
              const SizedBox(height: AppSpacing.lg),
              _ProfitLossCard(state: state, en: en),
              const SizedBox(height: AppSpacing.lg),
              _ExpenseCategoryCard(state: state, en: en),
              const SizedBox(height: AppSpacing.lg),
              _AiInsightCard(en: en),
            ],
          ),
        );
      },
    );
  }

  List<_ChartPoint> _chartData(MikiezyState state, AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.weekly:
        return [
          const _ChartPoint('Mon', 820000),
          const _ChartPoint('Tue', 640000),
          const _ChartPoint('Wed', 950000),
          const _ChartPoint('Thu', 1100000),
          const _ChartPoint('Fri', 1250000),
          const _ChartPoint('Sat', 1480000),
          _ChartPoint('Sun', math.max(1200000, state.salesToday)),
        ];
      case AnalyticsPeriod.monthly:
        return [
          const _ChartPoint('W1', 4200000),
          const _ChartPoint('W2', 3800000),
          const _ChartPoint('W3', 5100000),
          _ChartPoint('W4', math.max(6200000, state.incomeTotal)),
        ];
    }
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.period,
    required this.en,
    required this.onChanged,
  });

  final AnalyticsPeriod period;
  final bool en;
  final ValueChanged<AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return MikiezySegmentedControl<AnalyticsPeriod>(
      values: AnalyticsPeriod.values,
      selected: period,
      labelBuilder: (value) => switch (value) {
        AnalyticsPeriod.weekly => en ? 'Weekly' : 'Mingguan',
        AnalyticsPeriod.monthly => en ? 'Monthly' : 'Bulanan',
      },
      onChanged: onChanged,
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    super.key,
    required this.en,
    required this.period,
    required this.data,
    required this.total,
  });

  final bool en;
  final AnalyticsPeriod period;
  final List<_ChartPoint> data;
  final int total;

  @override
  Widget build(BuildContext context) {
    return MikiezyCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      switch (period) {
                        AnalyticsPeriod.weekly =>
                          en ? 'This Week' : 'Minggu ini',
                        AnalyticsPeriod.monthly =>
                          en ? 'This Month' : 'Bulan ini',
                      },
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.mutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      compactRupiah(total),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                  ],
                ),
              ),
              const MikiezyStatusPill(
                label: '+12.4%',
                icon: Icons.trending_up_rounded,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 184,
            child: CustomPaint(
              painter: _BarChartPainter(
                data,
                accent: context.colors.primary,
                mutedBar: context.colors.primary.withValues(alpha: .18),
                grid: context.subtleBorder,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest.withValues(
                alpha: .72,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: context.subtleBorder),
            ),
            child: Text(
              en
                  ? 'Miki highlights the strongest period so restocking decisions feel easier.'
                  : 'Miki menandai periode terkuat agar keputusan stok lebih mudah.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricWrap extends StatelessWidget {
  const _MetricWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.sm;
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.state, required this.en});

  final MikiezyState state;
  final bool en;

  @override
  Widget build(BuildContext context) {
    final products = _topProducts(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(text: en ? 'TOP PRODUCTS' : 'PRODUK TERLARIS'),
        MikiezyCard(
          radius: AppRadius.xl,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < products.length; i++) ...[
                _TopProductRow(item: products[i], rank: i + 1, en: en),
                if (i < products.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<_TopProduct> _topProducts(MikiezyState state) {
    final totals = <String, int>{};
    for (final tx in state.transactions) {
      for (final line in tx.lines) {
        totals[line.productName] =
            (totals[line.productName] ?? 0) + line.quantity;
      }
    }
    final items =
        totals.entries
            .map((entry) => _TopProduct(entry.key, entry.value))
            .toList()
          ..sort((a, b) => b.sold.compareTo(a.sold));
    if (items.length >= 4) return items.take(4).toList();
    return [
      ...items,
      const _TopProduct('Kopi Susu Botol', 18),
      const _TopProduct('Ayam Bakar', 14),
      const _TopProduct('Mie Goreng', 9),
    ].take(4).toList();
  }
}

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({
    required this.item,
    required this.rank,
    required this.en,
  });

  final _TopProduct item;
  final int rank;
  final bool en;

  @override
  Widget build(BuildContext context) {
    final pct = math.min(1.0, item.sold / 24);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      en ? 'Rank #$rank' : 'Peringkat #$rank',
                      style: const TextStyle(
                        color: AppColors.faint,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                en ? '${item.sold} sold' : '${item.sold} terjual',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              color: rank == 1 ? AppColors.accent : AppColors.teal,
              backgroundColor: context.colors.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitLossCard extends StatelessWidget {
  const _ProfitLossCard({required this.state, required this.en});

  final MikiezyState state;
  final bool en;

  @override
  Widget build(BuildContext context) {
    final cost = _costOfGoods(state.transactions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(text: en ? 'PROFIT & LOSS' : 'LABA RUGI'),
        MikiezyCard(
          radius: AppRadius.xl,
          child: Column(
            children: [
              _ReportRow(
                label: en ? 'Sales and income' : 'Penjualan dan pemasukan',
                value: state.incomeTotal,
                color: AppColors.success,
              ),
              _ReportRow(
                label: en ? 'Cost of goods sold' : 'Harga modal penjualan',
                value: cost,
                color: AppColors.warning,
              ),
              _ReportRow(
                label: en ? 'Operational expense' : 'Pengeluaran operasional',
                value: state.expenseTotal,
                color: AppColors.danger,
              ),
              const Divider(height: 24),
              _ReportRow(
                label: en ? 'Net profit/loss' : 'Laba/rugi bersih',
                value: state.grossProfit,
                color: state.grossProfit >= 0
                    ? AppColors.success
                    : AppColors.danger,
                strong: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _costOfGoods(List<TransactionRecord> transactions) {
    return transactions
        .where((tx) => tx.kind == TransactionKind.sale)
        .fold(0, (sum, tx) => sum + tx.totalCost);
  }
}

class _ExpenseCategoryCard extends StatelessWidget {
  const _ExpenseCategoryCard({required this.state, required this.en});

  final MikiezyState state;
  final bool en;

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _expenseByCategory(state.transactions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          text: en ? 'EXPENSE BY CATEGORY' : 'PENGELUARAN PER KATEGORI',
        ),
        if (categoryTotals.isEmpty)
          MikiezyEmptyState(
            icon: Icons.receipt_long_outlined,
            title: en ? 'No expenses yet' : 'Belum ada pengeluaran',
            message: en
                ? 'Expense insights will appear after you record operational costs.'
                : 'Insight pengeluaran akan muncul setelah biaya operasional dicatat.',
          )
        else
          ...categoryTotals.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MikiezyCard(
                radius: AppRadius.lg,
                child: Row(
                  children: [
                    const Icon(
                      Icons.pie_chart_outline_rounded,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      rupiah(entry.value),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Map<String, int> _expenseByCategory(List<TransactionRecord> transactions) {
    final totals = <String, int>{};
    for (final tx in transactions.where(
      (tx) => tx.kind == TransactionKind.expense,
    )) {
      totals[tx.categoryName] = (totals[tx.categoryName] ?? 0) + tx.amount;
    }
    return totals;
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({required this.en});

  final bool en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: context.premiumGradient,
        boxShadow: context.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'MIKI Insight',
                style: TextStyle(
                  color: Color(0xFFA5B4FC),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            en
                ? 'Sales increased this week, mainly driven by Nasi Goreng. Consider stocking more ingredients before the weekend.'
                : 'Penjualan meningkat minggu ini, terutama dari Nasi Goreng. Pertimbangkan menambah stok bahan sebelum akhir pekan.',
            style: const TextStyle(
              color: Colors.white,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.label,
    required this.value,
    required this.color,
    this.strong = false,
  });

  final String label;
  final int value;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            rupiah(value),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color,
              fontSize: strong ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: context.mutedText,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter(
    this.data, {
    required this.accent,
    required this.mutedBar,
    required this.grid,
  });

  final List<_ChartPoint> data;
  final Color accent;
  final Color mutedBar;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = grid.withValues(alpha: 0.62)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final bottom = size.height - 24;
    final chartHeight = bottom - 8;
    final maxValue = data.map((p) => p.value).reduce(math.max).toDouble();

    for (var i = 0; i < 4; i++) {
      final y = 8 + (chartHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    canvas.drawLine(Offset(0, bottom), Offset(size.width, bottom), axisPaint);

    final gap = data.length <= 4 ? 22.0 : 12.0;
    final barWidth = (size.width - gap * (data.length + 1)) / data.length;
    final peak = data.map((p) => p.value).reduce(math.max);

    for (var i = 0; i < data.length; i++) {
      final point = data[i];
      final left = gap + i * (barWidth + gap);
      final ratio = point.value / maxValue;
      final barHeight = math.max(8.0, chartHeight * ratio);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, bottom - barHeight, barWidth, barHeight),
        const Radius.circular(10),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: point.value == peak
              ? [accent, AppColors.teal]
              : [mutedBar.withValues(alpha: .92), mutedBar],
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);

      textPainter.text = TextSpan(
        text: point.label,
        style: TextStyle(
          color: point.value == peak ? accent : AppColors.faint,
          fontSize: 10,
          fontWeight: point.value == peak ? FontWeight.w900 : FontWeight.w700,
        ),
      );
      textPainter.layout(maxWidth: barWidth + 8);
      textPainter.paint(
        canvas,
        Offset(left + (barWidth - textPainter.width) / 2, bottom + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.accent != accent ||
        oldDelegate.mutedBar != mutedBar ||
        oldDelegate.grid != grid;
  }
}

class _ChartPoint {
  const _ChartPoint(this.label, this.value);

  final String label;
  final int value;
}

class _TopProduct {
  const _TopProduct(this.name, this.sold);

  final String name;
  final int sold;
}
