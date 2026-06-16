import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/mikiezy_models.dart';
import '../shared/widgets/mikiezy_components.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/mikiezy_card.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key, this.transaction, this.transactionId})
    : assert(
        transaction != null || transactionId != null,
        'ReceiptScreen needs a transaction or transactionId.',
      );

  final TransactionRecord? transaction;
  final String? transactionId;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  TransactionRecord? transaction;
  bool loading = true;
  String? error;
  bool requestedLoad = false;

  @override
  void initState() {
    super.initState();
    transaction = widget.transaction;
    loading = widget.transactionId != null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (requestedLoad) return;
    requestedLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadTransaction();
    });
  }

  Future<void> _loadTransaction() async {
    final id = widget.transactionId ?? widget.transaction?.id;
    if (id == null) {
      setState(() {
        loading = false;
        error = 'Transaksi tidak ditemukan.';
      });
      return;
    }

    try {
      final loaded = await MikiezyScope.of(context).loadTransactionDetail(id);
      if (!mounted) return;
      setState(() {
        transaction = loaded ?? transaction;
        loading = false;
        error = loaded == null && transaction == null
            ? 'Transaksi tidak ditemukan di database lokal.'
            : null;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = exception.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    return Scaffold(
      appBar: AppBar(title: const Text('Struk Transaksi')),
      body: SafeArea(
        child: tx == null
            ? _ReceiptFallback(
                loading: loading,
                error: error,
                onRetry: _loadTransaction,
              )
            : _ReceiptContent(
                transaction: tx,
                loading: loading,
                error: error,
                onPrinterTap: () => _showTodo(
                  context,
                  'Koneksi printer Bluetooth thermal akan dipasang pada tahap integrasi hardware.',
                ),
                onShareTap: () => _showTodo(
                  context,
                  'Share WhatsApp akan memakai deep link atau package share_plus.',
                ),
              ),
      ),
    );
  }

  void _showTodo(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReceiptFallback extends StatelessWidget {
  const _ReceiptFallback({
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MikiezyEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Struk tidak ditemukan',
        message:
            error ??
            'Transaksi ini belum tersedia di database lokal perangkat.',
        action: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Coba lagi'),
        ),
      ),
    );
  }
}

class _ReceiptContent extends StatelessWidget {
  const _ReceiptContent({
    required this.transaction,
    required this.loading,
    required this.error,
    required this.onPrinterTap,
    required this.onShareTap,
  });

  final TransactionRecord transaction;
  final bool loading;
  final String? error;
  final VoidCallback onPrinterTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (loading) ...[
          const LinearProgressIndicator(minHeight: 3),
          const SizedBox(height: 12),
        ],
        if (error != null) ...[
          _ReceiptNotice(message: 'Detail lokal belum bisa dimuat ulang.'),
          const SizedBox(height: 12),
        ],
        MikiezyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'MIKIEZY POS',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Toko Maju Jaya',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const Divider(height: 28),
              _ReceiptRow(label: 'No', value: transaction.id),
              _ReceiptRow(
                label: 'Tanggal',
                value:
                    '${dateLabel(transaction.createdAt)} ${timeLabel(transaction.createdAt)}',
              ),
              _ReceiptRow(label: 'Dompet', value: transaction.walletName),
              _ReceiptRow(label: 'Kategori', value: transaction.categoryName),
              const Divider(height: 28),
              if (transaction.lines.isEmpty)
                _ReceiptRow(
                  label: transaction.kind.label,
                  value: rupiah(transaction.amount),
                )
              else
                ...transaction.lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.productName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${line.quantity} ${line.unit.label} x ${rupiah(line.unitPrice)}',
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            ),
                            Text(
                              rupiah(line.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (transaction.discount > 0)
                _ReceiptRow(
                  label: 'Diskon',
                  value: '-${rupiah(transaction.discount)}',
                ),
              const Divider(height: 28),
              _ReceiptRow(
                label: 'Total',
                value: rupiah(transaction.amount),
                strong: true,
              ),
              if (transaction.evidencePath != null)
                _ReceiptRow(label: 'Bukti', value: 'Terlampir'),
              if (transaction.ocrSource != null)
                _ReceiptRow(label: 'OCR', value: 'Dicek'),
              const SizedBox(height: 18),
              const Text(
                'Terima kasih. Struk ini bisa dicetak ulang dari detail transaksi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onPrinterTap,
          icon: const Icon(Icons.print_rounded),
          label: const Text('Cetak ke printer'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onShareTap,
          icon: const Icon(Icons.share_rounded),
          label: const Text('Bagikan laporan/struk'),
        ),
      ],
    );
  }
}

class _ReceiptNotice extends StatelessWidget {
  const _ReceiptNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MikiezyCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
      fontSize: strong ? 18 : 14,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value, textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}
