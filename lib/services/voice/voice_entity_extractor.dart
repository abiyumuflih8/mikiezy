import 'voice_command.dart';

class VoiceEntityExtractor {
  const VoiceEntityExtractor();

  VoiceCommandEntities extract({
    required String normalizedText,
    required VoiceCommandIntent intent,
  }) {
    return VoiceCommandEntities(
      productName: _productName(normalizedText, intent),
      walletName: _walletName(normalizedText, intent),
      period: _period(normalizedText),
      transactionFilter: _transactionFilter(normalizedText, intent),
      resultLimit: _resultLimit(normalizedText, intent),
      topProductRanking: _topProductRanking(normalizedText, intent),
      allWallets:
          intent == VoiceCommandIntent.queryWalletBalance &&
          RegExp(r'\b(semua|seluruh)\s+dompet\b').hasMatch(normalizedText),
      largestWallet:
          intent == VoiceCommandIntent.queryWalletBalance &&
          RegExp(
            r'\b(paling besar|terbesar|tertinggi)\b',
          ).hasMatch(normalizedText),
      largestExpense:
          intent == VoiceCommandIntent.queryExpense &&
          RegExp(
            r'\b(terbesar|paling besar|tertinggi)\b',
          ).hasMatch(normalizedText),
      navigationTarget: _navigationTarget(intent),
    );
  }

  VoiceCommandPeriod? _period(String text) {
    if (RegExp(
      r'\b(semua waktu|sepanjang waktu|selama ini|keseluruhan)\b',
    ).hasMatch(text)) {
      return VoiceCommandPeriod.allTime;
    }
    if (text.contains('bulan lalu')) return VoiceCommandPeriod.lastMonth;
    if (text.contains('bulan ini')) return VoiceCommandPeriod.thisMonth;
    if (text.contains('minggu lalu')) return VoiceCommandPeriod.lastWeek;
    if (text.contains('minggu ini')) return VoiceCommandPeriod.thisWeek;
    if (text.contains('kemarin')) return VoiceCommandPeriod.yesterday;
    if (text.contains('hari ini') || text.contains('sekarang')) {
      return VoiceCommandPeriod.today;
    }
    return null;
  }

  VoiceTransactionFilter? _transactionFilter(
    String text,
    VoiceCommandIntent intent,
  ) {
    if (intent != VoiceCommandIntent.queryTransactionCount &&
        intent != VoiceCommandIntent.queryLatestTransaction) {
      return null;
    }
    if (text.contains('pengeluaran')) return VoiceTransactionFilter.expense;
    if (text.contains('pemasukan')) return VoiceTransactionFilter.income;
    if (text.contains('penjualan')) return VoiceTransactionFilter.sale;
    return VoiceTransactionFilter.all;
  }

  int? _resultLimit(String text, VoiceCommandIntent intent) {
    if (intent != VoiceCommandIntent.queryTopProduct) return null;
    final digitMatch = RegExp(
      r'\b([1-5])\s+(?:produk|barang)\b',
    ).firstMatch(text);
    if (digitMatch != null) return int.parse(digitMatch.group(1)!);
    const wordValues = {'satu': 1, 'dua': 2, 'tiga': 3, 'empat': 4, 'lima': 5};
    for (final entry in wordValues.entries) {
      if (RegExp('\\b${entry.key}\\s+(?:produk|barang)\\b').hasMatch(text)) {
        return entry.value;
      }
    }
    return null;
  }

  VoiceTopProductRanking? _topProductRanking(
    String text,
    VoiceCommandIntent intent,
  ) {
    if (intent != VoiceCommandIntent.queryTopProduct) return null;
    return RegExp(r'\b(omzet|omset|pendapatan)\b').hasMatch(text)
        ? VoiceTopProductRanking.revenue
        : VoiceTopProductRanking.quantity;
  }

  VoiceNavigationTarget? _navigationTarget(VoiceCommandIntent intent) {
    return switch (intent) {
      VoiceCommandIntent.navigateDashboard => VoiceNavigationTarget.dashboard,
      VoiceCommandIntent.navigateTransactions =>
        VoiceNavigationTarget.transactions,
      VoiceCommandIntent.navigateProducts => VoiceNavigationTarget.products,
      VoiceCommandIntent.navigateReports => VoiceNavigationTarget.reports,
      VoiceCommandIntent.navigateAnalytics => VoiceNavigationTarget.analytics,
      VoiceCommandIntent.navigateWallets => VoiceNavigationTarget.wallets,
      VoiceCommandIntent.navigateCategories => VoiceNavigationTarget.categories,
      VoiceCommandIntent.navigateSettings => VoiceNavigationTarget.settings,
      VoiceCommandIntent.navigateEditProfile =>
        VoiceNavigationTarget.editProfile,
      VoiceCommandIntent.navigateVoiceEntry => VoiceNavigationTarget.voiceEntry,
      VoiceCommandIntent.goBack => VoiceNavigationTarget.back,
      _ => null,
    };
  }

  String? _productName(String text, VoiceCommandIntent intent) {
    var candidate = text;
    switch (intent) {
      case VoiceCommandIntent.queryProductStock:
        candidate = candidate
            .replaceAll(
              RegExp(
                r'\b(berapa|cek|tolong|apakah|stok(?:nya)?|stock|produk|barang|tinggal|tersisa|sisa|sekarang|masih|ada)\b',
              ),
              ' ',
            )
            .replaceAll(
              RegExp(
                r'\b(hari ini|kemarin|minggu ini|minggu lalu|bulan ini|bulan lalu|semua waktu)\b',
              ),
              ' ',
            );
        break;
      case VoiceCommandIntent.createProduct:
        candidate = candidate.replaceFirst(
          RegExp(
            r'^(?:tolong\s+)?(?:tambah(?:kan)?|buat|masukkan)\s+(?:(?:produk|barang)(?:\s+baru)?\s+)?',
          ),
          '',
        );
        candidate = candidate
            .split(
              RegExp(
                r'\b(harga jual|harga beli|harga modal|harga grosir|harga|modal|stok minimum|stok|kategori|grosir|isi pack|ukuran pack|isi karton|ukuran karton|pack|karton)\b',
              ),
            )
            .first;
        break;
      case VoiceCommandIntent.updateProduct:
        candidate = candidate
            .replaceFirst(RegExp(r'^.*?\b(harga|stok)\b'), '')
            .split(RegExp(r'\b(menjadi|jadi|sebesar|tambah|kurangi)\b'))
            .first;
        break;
      default:
        return null;
    }
    return _cleanName(candidate);
  }

  String? _walletName(String text, VoiceCommandIntent intent) {
    if (intent != VoiceCommandIntent.queryWalletBalance) return null;
    if (RegExp(r'\b(semua|seluruh)\s+dompet\b').hasMatch(text) ||
        RegExp(r'\b(paling besar|terbesar|tertinggi)\b').hasMatch(text)) {
      return null;
    }
    final candidate = text.replaceAll(
      RegExp(
        r'\b(berapa|total|saldo(?:nya)?|dompet|wallet|sekarang|saat ini)\b',
      ),
      ' ',
    );
    return _cleanName(candidate);
  }

  String? _cleanName(String value) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}
