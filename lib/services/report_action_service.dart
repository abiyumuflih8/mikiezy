import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/formatters.dart';
import '../state/app_state.dart';

class ReportActionService {
  static Future<void> shareReportToWhatsApp(
    BuildContext context,
    MikiezyState state,
    bool en,
  ) async {
    final message = _whatsAppReport(state, en);
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, stackTrace) {
      debugPrint('Gagal membuka WhatsApp untuk laporan: $error\n$stackTrace');
    }
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!opened) {
      var copied = false;
      try {
        await Clipboard.setData(ClipboardData(text: message));
        copied = true;
      } catch (error, stackTrace) {
        debugPrint('Gagal menyalin laporan ke clipboard: $error\n$stackTrace');
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            en
                ? copied
                      ? 'WhatsApp could not be opened. Report copied instead.'
                      : 'WhatsApp and clipboard are not available on this device.'
                : copied
                ? 'WhatsApp belum bisa dibuka. Laporan disalin sebagai gantinya.'
                : 'WhatsApp dan clipboard belum tersedia di perangkat ini.',
          ),
        ),
      );
    }
  }

  static Future<void> exportDataToClipboard(
    BuildContext context,
    MikiezyState state,
    bool en,
  ) async {
    final export = _exportBundle(state);
    try {
      await Clipboard.setData(ClipboardData(text: export));
    } catch (error, stackTrace) {
      debugPrint('Gagal menyalin export data: $error\n$stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            en
                ? 'CSV export could not be copied on this device.'
                : 'Export CSV belum bisa disalin di perangkat ini.',
          ),
        ),
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          en
              ? 'CSV export copied to clipboard.'
              : 'Export CSV sudah disalin ke clipboard.',
        ),
      ),
    );
  }

  static String _whatsAppReport(MikiezyState state, bool en) {
    final lines = [
      en ? '*Mikiezy Sales Report*' : '*Laporan Penjualan Mikiezy*',
      state.businessName,
      '',
      '${en ? 'Revenue' : 'Pemasukan'}: ${rupiah(state.incomeTotal)}',
      '${en ? 'Expenses' : 'Pengeluaran'}: ${rupiah(state.expenseTotal)}',
      '${en ? 'Net profit/loss' : 'Laba/rugi'}: ${rupiah(state.grossProfit)}',
      '${en ? 'Transactions' : 'Transaksi'}: ${state.transactions.length}',
      '${en ? 'Queued sync' : 'Antrean sync'}: ${state.queuedSyncCount}',
    ];
    return lines.join('\n');
  }

  static String _exportBundle(MikiezyState state) {
    return [
      '# Mikiezy Export',
      '# Business,${_csv(state.businessName)}',
      '',
      'Transactions',
      'id,date,type,category,wallet,amount,discount,note,sync_status',
      ...state.transactions.map(
        (tx) => [
          tx.id,
          tx.createdAt.toIso8601String(),
          tx.kind.name,
          tx.categoryName,
          tx.walletName,
          tx.amount.toString(),
          tx.discount.toString(),
          tx.note,
          tx.syncStatus.name,
        ].map(_csv).join(','),
      ),
      '',
      'Products',
      'id,name,category,cost_price,retail_price,wholesale_price,stock_quantity,track_stock,base_unit,min_stock,pack_size,carton_size',
      ...state.products.map(
        (product) => [
          product.id,
          product.name,
          product.category,
          product.costPrice.toString(),
          product.retailPrice.toString(),
          product.wholesalePrice.toString(),
          quantityLabel(product.stockPcs),
          product.trackStock.toString(),
          product.baseUnit.name,
          quantityLabel(product.minStock),
          product.packSize.toString(),
          product.cartonSize.toString(),
        ].map(_csv).join(','),
      ),
      '',
      'Wallets',
      'id,name,balance,is_primary',
      ...state.wallets.map(
        (wallet) => [
          wallet.id,
          wallet.name,
          wallet.balance.toString(),
          wallet.isPrimary.toString(),
        ].map(_csv).join(','),
      ),
      '',
      'Categories',
      'name,type',
      ...state.productCategories.map((category) => '${_csv(category)},product'),
      ...state.categories.map(
        (category) =>
            [category.name, category.direction.name].map(_csv).join(','),
      ),
    ].join('\n');
  }

  static String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
