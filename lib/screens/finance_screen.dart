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

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  bool requestedRefresh = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (requestedRefresh) return;
    requestedRefresh = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(MikiezyScope.of(context).refreshFinance());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = MikiezyScope.of(context);
    return AppShell(
      title: 'Dompet & Kategori',
      currentIndex: 3,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final incomeCategories = state.categories
              .where((c) => c.direction == MoneyDirection.income)
              .toList();
          final expenseCategories = state.categories
              .where((c) => c.direction == MoneyDirection.expense)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              SectionTitle(
                title: 'Dompet',
                action: TextButton.icon(
                  onPressed: () => _showWalletDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah'),
                ),
              ),
              const SizedBox(height: 10),
              if (state.financeLoading && state.wallets.isEmpty)
                const _FinanceLoadingState(label: 'Memuat dompet lokal...')
              else if (state.financeError != null)
                const _FinanceNotice(
                  icon: Icons.warning_amber_rounded,
                  title: 'Data lokal belum termuat',
                  message: 'Menampilkan cache dompet dan kategori terakhir.',
                  color: AppColors.danger,
                ),
              if (state.financeError != null) const SizedBox(height: 10),
              if (!state.financeLoading && state.wallets.isEmpty)
                const MikiezyEmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Belum ada dompet',
                  message:
                      'Tambahkan dompet agar transaksi bisa memilih sumber dana.',
                )
              else
                ...state.wallets.map(
                  (wallet) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _WalletTile(
                      wallet: wallet,
                      onEdit: () => _showWalletDialog(context, wallet),
                      onDelete: () => _confirmDeleteWallet(context, wallet),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              SectionTitle(
                title: 'Kategori pemasukan',
                action: TextButton.icon(
                  onPressed: () =>
                      _showCategoryDialog(context, MoneyDirection.income),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Custom'),
                ),
              ),
              const SizedBox(height: 10),
              _CategoryWrap(
                categories: incomeCategories,
                onEdit: (category) =>
                    _showCategoryDialog(context, category.direction, category),
                onDelete: (category) =>
                    _confirmDeleteCategory(context, category),
              ),
              const SizedBox(height: 18),
              SectionTitle(
                title: 'Kategori pengeluaran',
                action: TextButton.icon(
                  onPressed: () =>
                      _showCategoryDialog(context, MoneyDirection.expense),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Custom'),
                ),
              ),
              const SizedBox(height: 10),
              _CategoryWrap(
                categories: expenseCategories,
                onEdit: (category) =>
                    _showCategoryDialog(context, category.direction, category),
                onDelete: (category) =>
                    _confirmDeleteCategory(context, category),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showWalletDialog(BuildContext context, [Wallet? wallet]) {
    final editing = wallet != null;
    final name = TextEditingController(text: wallet?.name ?? 'Dompet Baru');
    final balance = TextEditingController(text: '${wallet?.balance ?? 0}');
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(editing ? 'Edit dompet' : 'Tambah dompet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nama dompet'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: balance,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Saldo awal'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final state = MikiezyScope.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final walletName = name.text.trim();
              if (walletName.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Nama dompet wajib diisi.')),
                );
                return;
              }
              try {
                if (editing) {
                  await state.updateWallet(
                    wallet.copyWith(
                      name: walletName,
                      balance: intFromController(balance),
                    ),
                  );
                } else {
                  await state.addWallet(walletName, intFromController(balance));
                }
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      editing
                          ? 'Dompet berhasil diperbarui.'
                          : 'Dompet berhasil ditambahkan.',
                    ),
                  ),
                );
                navigator.pop();
              } catch (_) {
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Dompet belum tersimpan.')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    MoneyDirection direction, [
    LedgerCategory? category,
  ]) {
    final editing = category != null;
    final name = TextEditingController(text: category?.name ?? '');
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          editing
              ? 'Edit kategori'
              : direction == MoneyDirection.income
              ? 'Kategori pemasukan'
              : 'Kategori pengeluaran',
        ),
        content: TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nama kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final state = MikiezyScope.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final categoryName = name.text.trim();
              if (categoryName.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Nama kategori wajib diisi.')),
                );
                return;
              }
              try {
                if (editing) {
                  await state.updateCategory(
                    LedgerCategory(
                      id: category.id,
                      name: categoryName,
                      direction: category.direction,
                      isSystem: category.isSystem,
                    ),
                  );
                } else {
                  await state.addCategory(categoryName, direction);
                }
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      editing
                          ? 'Kategori berhasil diperbarui.'
                          : 'Kategori berhasil ditambahkan.',
                    ),
                  ),
                );
                navigator.pop();
              } catch (_) {
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Kategori belum tersimpan.')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteWallet(BuildContext context, Wallet wallet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus dompet?'),
        content: Text(
          '${wallet.name} akan disembunyikan dari pilihan transaksi. Riwayat transaksi lama tetap aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await MikiezyScope.of(context).deleteWallet(wallet.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dompet berhasil dihapus.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyFinanceError(error))));
    }
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    LedgerCategory category,
  ) async {
    if (category.isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori sistem tidak bisa dihapus.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus kategori?'),
        content: Text(
          '${category.name} akan disembunyikan dari pilihan transaksi. Riwayat transaksi lama tetap aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await MikiezyScope.of(context).deleteCategory(category.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori berhasil dihapus.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyFinanceError(error))));
    }
  }

  String _friendlyFinanceError(Object error) {
    final message = error.toString();
    if (message.contains('Minimal harus ada satu dompet')) {
      return 'Minimal harus ada satu dompet.';
    }
    if (message.contains('Kategori sistem')) {
      return 'Kategori sistem tidak bisa dihapus.';
    }
    return 'Data belum bisa dihapus. Coba lagi.';
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.wallet,
    required this.onEdit,
    required this.onDelete,
  });

  final Wallet wallet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return MikiezyCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: wallet.isPrimary ? AppColors.accentSoft : AppColors.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              wallet.isPrimary
                  ? Icons.account_balance_wallet
                  : Icons.wallet_outlined,
              color: wallet.isPrimary ? AppColors.accent : AppColors.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  wallet.isPrimary ? 'Dompet utama' : 'Dompet custom',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            rupiah(wallet.balance),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<_FinanceAction>(
            tooltip: 'Aksi dompet',
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onSelected: (action) {
              switch (action) {
                case _FinanceAction.edit:
                  onEdit();
                case _FinanceAction.delete:
                  onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _FinanceAction.edit, child: Text('Edit')),
              PopupMenuItem(value: _FinanceAction.delete, child: Text('Hapus')),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryWrap extends StatelessWidget {
  const _CategoryWrap({
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  final List<LedgerCategory> categories;
  final ValueChanged<LedgerCategory> onEdit;
  final ValueChanged<LedgerCategory> onDelete;

  @override
  Widget build(BuildContext context) {
    return MikiezyCard(
      child: categories.isEmpty
          ? const Text(
              'Belum ada kategori.',
              style: TextStyle(color: AppColors.muted),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories
                  .map(
                    (category) => InputChip(
                      avatar: Icon(
                        category.isSystem
                            ? Icons.label_rounded
                            : Icons.sell_outlined,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      label: Text(category.name),
                      onPressed: category.isSystem
                          ? null
                          : () => onEdit(category),
                      onDeleted: category.isSystem
                          ? null
                          : () => onDelete(category),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _FinanceLoadingState extends StatelessWidget {
  const _FinanceLoadingState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return MikiezyCard(
      child: Column(
        children: [
          const SizedBox(height: 4),
          const CircularProgressIndicator(strokeWidth: 2.4),
          const SizedBox(height: 14),
          Text(
            label,
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

class _FinanceNotice extends StatelessWidget {
  const _FinanceNotice({
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

enum _FinanceAction { edit, delete }
