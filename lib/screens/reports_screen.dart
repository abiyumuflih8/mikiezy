import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_dimensions.dart';
import '../core/formatters.dart';
import '../domain/models/business_query_result.dart';
import '../domain/services/report_period_resolver.dart';
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
  int? selectedChartIndex;

  @override
  Widget build(BuildContext context) {
    final state = MikiezyScope.of(context);
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final en = state.language == AppLanguage.en;
        final chartData = _chartData(state, period, en: en);
        final selectedIndex = _selectedIndex(chartData);
        final now = DateTime.now();
        final metricsPeriod = period == AnalyticsPeriod.weekly
            ? ReportPeriodType.thisWeek
            : ReportPeriodType.thisMonth;
        final revenue = state.salesMetric(metricsPeriod, now: now);
        final income = state.incomeMetric(metricsPeriod, now: now);
        final expense = state.expenseMetric(metricsPeriod, now: now);
        final profit = state.profitMetric(metricsPeriod, now: now);
        final transactionCount = state.transactionCountMetric(
          metricsPeriod,
          now: now,
        );
        final topProducts = state
            .topProductsMetric(metricsPeriod, now: now)
            .items
            .map((item) => _TopProduct(item.name, item.quantity ?? 0))
            .toList(growable: false);
        final expenseCategories = state.expenseByCategoryMetric(
          metricsPeriod,
          now: now,
        );
        final periodLabel = period == AnalyticsPeriod.weekly
            ? (en ? 'This week' : 'Minggu ini')
            : (en ? 'This month' : 'Bulan ini');
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
                onChanged: (value) => setState(() {
                  period = value;
                  selectedChartIndex = null;
                }),
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
                  selectedIndex: selectedIndex,
                  onPointSelected: (index) =>
                      setState(() => selectedChartIndex = index),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _MetricWrap(
                children: [
                  MetricTile(
                    label: en ? 'Sales Revenue' : 'Omzet penjualan',
                    value: compactRupiah(revenue.moneyValue ?? 0),
                    icon: Icons.bar_chart_rounded,
                    color: AppColors.accent,
                    subLabel: periodLabel,
                  ),
                  MetricTile(
                    label: en ? 'Transactions' : 'Transaksi',
                    value: '${transactionCount.countValue ?? 0}',
                    icon: Icons.shopping_cart_outlined,
                    color: AppColors.success,
                    subLabel: periodLabel,
                  ),
                  MetricTile(
                    label: en ? 'Expenses' : 'Pengeluaran',
                    value: compactRupiah(expense.moneyValue ?? 0),
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.danger,
                    subLabel: periodLabel,
                  ),
                  MetricTile(
                    label: en ? 'Net Profit' : 'Laba bersih',
                    value: compactRupiah(profit.moneyValue ?? 0),
                    icon: Icons.insights_rounded,
                    color: (profit.moneyValue ?? 0) >= 0
                        ? AppColors.success
                        : AppColors.danger,
                    subLabel: profit.isEstimate
                        ? (en ? 'Estimated' : 'Estimasi')
                        : periodLabel,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _TopProductsCard(products: topProducts, en: en),
              const SizedBox(height: AppSpacing.lg),
              _ProfitLossCard(
                salesAndIncome:
                    (revenue.moneyValue ?? 0) + (income.moneyValue ?? 0),
                costOfGoods: profit.costValue ?? 0,
                expense: expense.moneyValue ?? 0,
                profit: profit.moneyValue ?? 0,
                en: en,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ExpenseCategoryCard(categories: expenseCategories, en: en),
              const SizedBox(height: AppSpacing.lg),
              _AiInsightCard(
                en: en,
                periodLabel: periodLabel.toLowerCase(),
                revenue: revenue.moneyValue ?? 0,
                profit: profit.moneyValue ?? 0,
                topProductName: topProducts.isEmpty
                    ? null
                    : topProducts.first.name,
              ),
            ],
          ),
        );
      },
    );
  }

  int _selectedIndex(List<_ChartPoint> data) {
    if (data.isEmpty) return 0;
    final requested = selectedChartIndex;
    if (requested != null && requested >= 0 && requested < data.length) {
      return requested;
    }

    var peakIndex = 0;
    for (var i = 1; i < data.length; i++) {
      if (data[i].value >= data[peakIndex].value) {
        peakIndex = i;
      }
    }
    return peakIndex;
  }

  List<_ChartPoint> _chartData(
    MikiezyState state,
    AnalyticsPeriod period, {
    required bool en,
  }) {
    switch (period) {
      case AnalyticsPeriod.weekly:
        final start = _startOfWeek(DateTime.now());
        return List.generate(7, (index) {
          final day = start.add(Duration(days: index));
          final sales = _salesInRange(
            state.transactions,
            day,
            day.add(const Duration(days: 1)),
          );
          return _ChartPoint(
            _weekdayLabel(day, en: en),
            _salesTotal(sales),
            transactionCount: sales.length,
          );
        });
      case AnalyticsPeriod.monthly:
        final now = DateTime.now();
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        return List.generate(4, (index) {
          final startDay = index * 7 + 1;
          final endDay = index == 3
              ? lastDay + 1
              : math.min(startDay + 7, lastDay + 1);
          final start = DateTime(now.year, now.month, startDay);
          final end = DateTime(now.year, now.month, endDay);
          final sales = _salesInRange(state.transactions, start, end);
          return _ChartPoint(
            en ? 'W${index + 1}' : 'M${index + 1}',
            _salesTotal(sales),
            transactionCount: sales.length,
          );
        });
    }
  }

  DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  List<TransactionRecord> _salesInRange(
    List<TransactionRecord> transactions,
    DateTime start,
    DateTime end,
  ) {
    return transactions
        .where(
          (tx) =>
              tx.kind == TransactionKind.sale &&
              !tx.createdAt.isBefore(start) &&
              tx.createdAt.isBefore(end),
        )
        .toList(growable: false);
  }

  int _salesTotal(List<TransactionRecord> transactions) {
    return transactions.fold(0, (sum, tx) => sum + tx.amount);
  }

  String _weekdayLabel(DateTime date, {required bool en}) {
    const english = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const indonesian = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final labels = en ? english : indonesian;
    return labels[date.weekday - DateTime.monday];
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
    required this.selectedIndex,
    required this.onPointSelected,
  });

  final bool en;
  final AnalyticsPeriod period;
  final List<_ChartPoint> data;
  final int total;
  final int selectedIndex;
  final ValueChanged<int> onPointSelected;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final safeSelectedIndex = selectedIndex.clamp(0, data.length - 1).toInt();
    final selectedPoint = data[safeSelectedIndex];
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
              MikiezyStatusPill(
                label: en ? 'Live data' : 'Data aktif',
                icon: Icons.sync_rounded,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 184,
            child: Stack(
              children: [
                CustomPaint(
                  painter: _BarChartPainter(
                    data,
                    selectedIndex: selectedIndex,
                    accent: context.colors.primary,
                    mutedBar: context.colors.primary.withValues(alpha: .18),
                    grid: context.subtleBorder,
                  ),
                  child: const SizedBox.expand(),
                ),
                Positioned.fill(
                  child: Row(
                    children: [
                      for (var i = 0; i < data.length; i++)
                        Expanded(
                          child: GestureDetector(
                            key: ValueKey('analytics-chart-bar-$i'),
                            behavior: HitTestBehavior.translucent,
                            onTap: () => onPointSelected(i),
                            child: const SizedBox.expand(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            key: const ValueKey('analytics-chart-selected-summary'),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer.withValues(alpha: .42),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: context.colors.primary.withValues(alpha: .26),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 18,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    en
                        ? '${selectedPoint.label}: ${rupiah(selectedPoint.value)} - ${selectedPoint.transactionCount} transactions'
                        : '${selectedPoint.label}: ${rupiah(selectedPoint.value)} - ${selectedPoint.transactionCount} transaksi',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
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
                  ? 'Tap a bar to inspect sales for that period before deciding stock plans.'
                  : 'Ketuk bar untuk melihat penjualan periode itu sebelum menentukan rencana stok.',
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
  const _TopProductsCard({required this.products, required this.en});

  final List<_TopProduct> products;
  final bool en;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(text: en ? 'TOP PRODUCTS' : 'PRODUK TERLARIS'),
        if (products.isEmpty)
          MikiezyEmptyState(
            icon: Icons.inventory_2_outlined,
            title: en ? 'No products sold yet' : 'Belum ada produk terjual',
            message: en
                ? 'Top products will appear after a sale is recorded.'
                : 'Peringkat produk muncul setelah penjualan tercatat.',
          )
        else
          MikiezyCard(
            radius: AppRadius.xl,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < products.length; i++) ...[
                  _TopProductRow(
                    item: products[i],
                    rank: i + 1,
                    maxSold: products.first.sold,
                    en: en,
                  ),
                  if (i < products.length - 1)
                    const Divider(height: 1, color: AppColors.border),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({
    required this.item,
    required this.rank,
    required this.maxSold,
    required this.en,
  });

  final _TopProduct item;
  final int rank;
  final double maxSold;
  final bool en;

  @override
  Widget build(BuildContext context) {
    final pct = maxSold <= 0 ? 0.0 : math.min(1.0, item.sold / maxSold);
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
                en
                    ? '${quantityLabel(item.sold)} sold'
                    : '${quantityLabel(item.sold)} terjual',
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
  const _ProfitLossCard({
    required this.salesAndIncome,
    required this.costOfGoods,
    required this.expense,
    required this.profit,
    required this.en,
  });

  final int salesAndIncome;
  final int costOfGoods;
  final int expense;
  final int profit;
  final bool en;

  @override
  Widget build(BuildContext context) {
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
                value: salesAndIncome,
                color: AppColors.success,
              ),
              _ReportRow(
                label: en ? 'Cost of goods sold' : 'Harga modal penjualan',
                value: costOfGoods,
                color: AppColors.warning,
              ),
              _ReportRow(
                label: en ? 'Operational expense' : 'Pengeluaran operasional',
                value: expense,
                color: AppColors.danger,
              ),
              const Divider(height: 24),
              _ReportRow(
                label: en ? 'Net profit/loss' : 'Laba/rugi bersih',
                value: profit,
                color: profit >= 0 ? AppColors.success : AppColors.danger,
                strong: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpenseCategoryCard extends StatelessWidget {
  const _ExpenseCategoryCard({required this.categories, required this.en});

  final List<BusinessQueryItem> categories;
  final bool en;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          text: en ? 'EXPENSE BY CATEGORY' : 'PENGELUARAN PER KATEGORI',
        ),
        if (categories.isEmpty)
          MikiezyEmptyState(
            icon: Icons.receipt_long_outlined,
            title: en ? 'No expenses yet' : 'Belum ada pengeluaran',
            message: en
                ? 'Expense insights will appear after you record operational costs.'
                : 'Insight pengeluaran akan muncul setelah biaya operasional dicatat.',
          )
        else
          ...categories.map(
            (category) => Padding(
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
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      rupiah(category.moneyValue ?? 0),
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
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({
    required this.en,
    required this.periodLabel,
    required this.revenue,
    required this.profit,
    required this.topProductName,
  });

  final bool en;
  final String periodLabel;
  final int revenue;
  final int profit;
  final String? topProductName;

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
            _insightText(),
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

  String _insightText() {
    if (revenue == 0) {
      return en
          ? 'No sales have been recorded $periodLabel. Record a sale to generate a business summary.'
          : 'Belum ada penjualan tercatat $periodLabel. Catat penjualan untuk menghasilkan ringkasan bisnis.';
    }
    final topProduct = topProductName;
    final topSummary = topProduct == null
        ? ''
        : (en
              ? ' The top-selling product is $topProduct.'
              : ' Produk terlaris adalah $topProduct.');
    return en
        ? 'Sales revenue $periodLabel is ${rupiah(revenue)}, with net profit of ${rupiah(profit)}.$topSummary'
        : 'Omzet $periodLabel adalah ${rupiah(revenue)}, dengan laba bersih ${rupiah(profit)}.$topSummary';
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
    required this.selectedIndex,
    required this.accent,
    required this.mutedBar,
    required this.grid,
  });

  final List<_ChartPoint> data;
  final int selectedIndex;
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
    final maxValue = math
        .max(1, data.map((p) => p.value).fold<int>(0, math.max))
        .toDouble();

    for (var i = 0; i < 4; i++) {
      final y = 8 + (chartHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    canvas.drawLine(Offset(0, bottom), Offset(size.width, bottom), axisPaint);

    final gap = data.length <= 4 ? 22.0 : 12.0;
    final barWidth = (size.width - gap * (data.length + 1)) / data.length;
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
          colors: i == selectedIndex
              ? [accent, AppColors.teal]
              : [mutedBar.withValues(alpha: .92), mutedBar],
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);

      textPainter.text = TextSpan(
        text: point.label,
        style: TextStyle(
          color: i == selectedIndex ? accent : AppColors.faint,
          fontSize: 10,
          fontWeight: i == selectedIndex ? FontWeight.w900 : FontWeight.w700,
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
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.accent != accent ||
        oldDelegate.mutedBar != mutedBar ||
        oldDelegate.grid != grid;
  }
}

class _ChartPoint {
  const _ChartPoint(this.label, this.value, {this.transactionCount = 0});

  final String label;
  final int value;
  final int transactionCount;
}

class _TopProduct {
  const _TopProduct(this.name, this.sold);

  final String name;
  final double sold;
}
