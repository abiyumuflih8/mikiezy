import 'package:flutter/material.dart';

import '../core/constants/app_dimensions.dart';
import '../core/formatters.dart';
import '../models/mikiezy_models.dart';
import '../services/voice/voice_entry_launch_source.dart';
import '../services/voice/voice_assistant_manager.dart';
import '../shared/widgets/mikiezy_components.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/mikiezy_card.dart';
import 'receipt_screen.dart';
import 'preview_transaction_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';
import 'voice_entry_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = MikiezyScope.of(context);
    return AppShell(
      title: 'Mikiezy',
      currentIndex: 0,
      showAppBar: false,
      showDefaultFab: false,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final en = state.language == AppLanguage.en;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(state: state),
              Transform.translate(
                offset: const Offset(0, -18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _StatsStrip(state: state),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _VoiceCard(state: state, en: en),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _QuickActions(en: en),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RecentTransactions(
                  transactions: state.recentTransactions,
                  en: en,
                ),
              ),
              const SizedBox(height: 92),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final MikiezyState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 44),
      decoration: BoxDecoration(
        gradient: context.premiumGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _todayLabel(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  state.businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIcon(icon: Icons.notifications_none_rounded, onTap: () {}),
          const SizedBox(width: 9),
          _HeaderIcon(
            icon: Icons.person_outline_rounded,
            active: true,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  String _todayLabel() {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day} ${_month(now.month)} ${now.year}';
  }

  String _month(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.09),
          border: Border.all(
            color: active
                ? AppColors.accent.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.12),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.82),
          size: 18,
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.state});

  final MikiezyState state;

  @override
  Widget build(BuildContext context) {
    final transactionsToday = state.transactions
        .where((tx) => DateUtils.isSameDay(tx.createdAt, DateTime.now()))
        .length;
    final bestSeller = state.transactions
        .where((tx) => tx.kind == TransactionKind.sale && tx.lines.isNotEmpty)
        .map((tx) => tx.lines.first.productName)
        .fold<Map<String, int>>({}, (map, name) {
          map[name] = (map[name] ?? 0) + 1;
          return map;
        });
    final best = bestSeller.entries.isEmpty
        ? 'Belum ada'
        : (bestSeller.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Penjualan hari ini',
            value: compactRupiah(state.salesToday),
            badge: '+ antrean sync',
            positive: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Transaksi',
            value: '$transactionsToday',
            badge: 'hari ini',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(label: 'Terlaris', value: best, badge: 'produk'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.badge,
    this.positive = false,
  });

  final String label;
  final String value;
  final String badge;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return MikiezyCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      radius: AppRadius.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.faint,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            badge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: positive ? AppColors.success : AppColors.faint,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceCard extends StatelessWidget {
  const _VoiceCard({required this.state, required this.en});

  final MikiezyState state;
  final bool en;

  @override
  Widget build(BuildContext context) {
    final voiceManager = VoiceAssistantScope.maybeOf(context);
    final label = voiceManager?.statusLabel(en: en) ?? 'Ready to listen';
    final helper =
        voiceManager?.helperText(en: en) ??
        (en
            ? 'Example: "Miki, sold 3 nasi goreng at 15 thousand"'
            : 'Contoh: "Miki, jual 3 nasi goreng harga 15 ribu"');
    final statusColor = _statusColor(voiceManager?.status);
    return MikiezyCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      radius: AppRadius.lg,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => _openVoiceEntry(context),
            child: Hero(
              tag: 'mikiezy-mic',
              child: AnimatedContainer(
                duration: AppDurations.normal,
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.accent, AppColors.teal],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.32),
                      blurRadius: 30,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (voiceManager?.status == VoiceAssistantStatus.error)
            Text(
              en
                  ? 'Tap mic to allow microphone access'
                  : 'Tap mic untuk mengaktifkan izin mikrofon',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                children: const [
                  TextSpan(text: 'Tap atau bilang '),
                  TextSpan(
                    text: '"Miki"',
                    style: TextStyle(color: AppColors.accent),
                  ),
                  TextSpan(text: ' untuk mulai'),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            helper,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.faint, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Color _statusColor(VoiceAssistantStatus? status) {
    return switch (status) {
      VoiceAssistantStatus.error => AppColors.danger,
      VoiceAssistantStatus.processing ||
      VoiceAssistantStatus.wakeWordDetected => AppColors.accent,
      VoiceAssistantStatus.openingPreview => AppColors.warning,
      VoiceAssistantStatus.disabled => AppColors.faint,
      _ => AppColors.success,
    };
  }

  Future<void> _openVoiceEntry(BuildContext context) async {
    final manager = VoiceAssistantScope.maybeOf(context);
    await manager?.pauseForManualSession();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const VoiceEntryScreen(
          autoStart: true,
          launchSource: VoiceEntryLaunchSource.manualTap,
        ),
      ),
    );
    if (!context.mounted) return;
    await manager?.resumeAfterManualSession();
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.en});

  final bool en;

  @override
  Widget build(BuildContext context) {
    final state = MikiezyScope.of(context);
    final actions = [
      _QuickAction(
        icon: Icons.add_rounded,
        label: en ? 'Add' : 'Tambah',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                PreviewTransactionScreen(initialDraft: _manualDraft(state)),
          ),
        ),
      ),
      _QuickAction(
        icon: Icons.receipt_long_outlined,
        label: en ? 'Transactions' : 'Transaksi',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const TransactionsScreen())),
      ),
      _QuickAction(
        icon: Icons.bar_chart_rounded,
        label: en ? 'Analytics' : 'Analitik',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            color: AppColors.faint,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              Expanded(child: actions[i]),
              if (i < actions.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }

  TransactionDraft _manualDraft(MikiezyState state) {
    final wallet = state.wallets.isEmpty
        ? 'Dompet Utama'
        : state.wallets.first.name;
    var category = 'Penjualan';
    for (final item in state.categories) {
      if (item.direction == MoneyDirection.income) {
        category = item.name;
        break;
      }
    }
    return TransactionDraft(
      kind: TransactionKind.sale,
      productName: '',
      quantity: 1,
      unit: SaleUnit.pcs,
      unitPrice: 0,
      discount: 0,
      categoryName: category,
      walletName: wallet,
      segment: PriceSegment.retail,
      note: '',
      rawText: en ? 'Manual transaction input' : 'Input transaksi manual',
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MikiezyCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      radius: AppRadius.md,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.transactions, required this.en});

  final List<TransactionRecord> transactions;
  final bool en;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                en ? 'RECENT TRANSACTIONS' : 'TRANSAKSI TERBARU',
                style: const TextStyle(
                  color: AppColors.faint,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TransactionsScreen()),
              ),
              child: Text(en ? 'See all' : 'Lihat semua'),
            ),
          ],
        ),
        if (transactions.isEmpty)
          MikiezyEmptyState(
            icon: Icons.receipt_long_outlined,
            title: en ? 'No activity yet' : 'Belum ada aktivitas',
            message: en
                ? 'Your recent transactions will appear here.'
                : 'Transaksi terbaru akan muncul di bagian ini.',
          )
        else
          MikiezyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < transactions.length; i++) ...[
                  _TransactionRow(transaction: transactions[i]),
                  if (i < transactions.length - 1)
                    const Divider(height: 1, color: AppColors.border),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final TransactionRecord transaction;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.kind == TransactionKind.expense;
    final name =
        transaction.kind == TransactionKind.sale && transaction.lines.isNotEmpty
        ? transaction.lines.first.productName
        : transaction.categoryName;
    final qty = transaction.lines.isNotEmpty
        ? 'Qty ${transaction.lines.first.quantity} - ${timeLabel(transaction.createdAt)}'
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isExpense
                    ? Icons.receipt_long_outlined
                    : Icons.shopping_bag_outlined,
                color: isExpense ? AppColors.danger : AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    qty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.faint,
                      fontSize: 10,
                    ),
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
