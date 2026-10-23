import 'voice_command.dart';

class VoiceIntentClassifier {
  const VoiceIntentClassifier();

  VoiceIntentClassification classify(String normalizedText) {
    final text = normalizedText.trim();
    if (text.isEmpty) return _result(VoiceCommandIntent.unknown, 0);

    if (_containsAny(text, const [
      'kembali ke beranda',
      'kembali ke dashboard',
      'kembali ke halaman utama',
      'kembali ke home',
    ])) {
      return _result(VoiceCommandIntent.navigateDashboard, 0.98);
    }

    if (_containsAny(text, const [
      'kembali ke halaman sebelumnya',
      'kembali sebelumnya',
      'halaman sebelumnya',
      'balik ke halaman sebelumnya',
      'tutup halaman ini',
      'kembali',
    ])) {
      return _result(VoiceCommandIntent.goBack, 0.98);
    }

    if (_containsAny(text, const [
      'tambah produk',
      'tambahkan produk',
      'buat produk',
      'buat barang baru',
      'tambah barang',
      'tambahkan barang',
      'masukkan produk',
      'masukkan barang',
    ])) {
      return _result(VoiceCommandIntent.createProduct, 0.98);
    }

    if (RegExp(
      r'^(?:tolong\s+)?(?:tambah(?:kan)?|masukkan)\s+(?!stok\b).+\bharga(?:\s+jual)?\b',
    ).hasMatch(text)) {
      return _result(VoiceCommandIntent.createProduct, 0.94);
    }

    if (_isUnsupportedStockMutation(text)) {
      return _result(VoiceCommandIntent.updateProduct, 0.98);
    }

    if (_isStockIncrement(text)) {
      return _result(VoiceCommandIntent.incrementProductStock, 0.98);
    }

    if (_isPriceUpdate(text)) {
      return _result(VoiceCommandIntent.updateProduct, 0.96);
    }

    final queryIntent = _queryIntent(text);
    if (queryIntent != null) return _result(queryIntent, 0.94);

    if (_hasNavigationVerb(text)) {
      final navigationIntent = _navigationIntent(text);
      if (navigationIntent != null) return _result(navigationIntent, 0.97);
    }

    if (_containsAny(text, const [
      'pengeluaran',
      'catat pengeluaran',
      'beli',
      'belanja',
      'bayar',
      'kulakan',
    ])) {
      return _result(VoiceCommandIntent.createExpense, 0.92);
    }
    if (_containsAny(text, const [
      'pemasukan',
      'catat pemasukan',
      'terima uang',
      'modal masuk',
      'setor',
    ])) {
      return _result(VoiceCommandIntent.createIncome, 0.92);
    }
    if (_containsAny(text, const [
      'jual',
      'penjualan',
      'catat penjualan',
      'terjual',
      'laku',
    ])) {
      return _result(VoiceCommandIntent.createSale, 0.92);
    }

    return _result(VoiceCommandIntent.unknown, 0.25);
  }

  VoiceCommandIntent? _navigationIntent(String text) {
    if (_containsAny(text, const ['edit profil', 'ubah profil'])) {
      return VoiceCommandIntent.navigateEditProfile;
    }
    if (_containsAny(text, const [
      'input suara',
      'pencatatan suara',
      'voice entry',
    ])) {
      return VoiceCommandIntent.navigateVoiceEntry;
    }
    if (_containsAny(text, const ['analitik', 'analytics', 'analisis'])) {
      return VoiceCommandIntent.navigateAnalytics;
    }
    if (_containsAny(text, const ['laporan', 'report'])) {
      return VoiceCommandIntent.navigateReports;
    }
    if (_containsAny(text, const ['transaksi', 'riwayat'])) {
      return VoiceCommandIntent.navigateTransactions;
    }
    if (_containsAny(text, const ['produk', 'barang'])) {
      return VoiceCommandIntent.navigateProducts;
    }
    if (_containsAny(text, const ['dompet', 'wallet'])) {
      return VoiceCommandIntent.navigateWallets;
    }
    if (_containsAny(text, const ['kategori'])) {
      return VoiceCommandIntent.navigateCategories;
    }
    if (_containsAny(text, const ['pengaturan', 'setelan', 'setting'])) {
      return VoiceCommandIntent.navigateSettings;
    }
    if (_containsAny(text, const [
      'dashboard',
      'beranda',
      'halaman utama',
      'home',
    ])) {
      return VoiceCommandIntent.navigateDashboard;
    }
    return null;
  }

  VoiceCommandIntent? _queryIntent(String text) {
    if (_containsAny(text, const [
      'transaksi terakhir',
      'transaksi terbaru',
      'penjualan terakhir',
      'penjualan terbaru',
      'pemasukan terakhir',
      'pemasukan terbaru',
      'pengeluaran terakhir',
      'pengeluaran terbaru',
    ])) {
      return VoiceCommandIntent.queryLatestTransaction;
    }
    if (_containsAny(text, const [
      'stok hampir habis',
      'stoknya hampir habis',
      'stok yang hampir habis',
      'stok menipis',
      'stok sedikit',
      'barang hampir habis',
      'produk hampir habis',
      'barang yang mau habis',
      'produk yang mau habis',
      'ada barang yang mau habis',
    ])) {
      return VoiceCommandIntent.queryLowStock;
    }
    if (_containsAny(text, const [
      'produk paling laku',
      'produk apa yang paling laku',
      'barang paling laku',
      'barang apa yang paling laku',
      'produk terlaris',
      'barang terlaris',
      'top produk',
      'top barang',
      'omzet produk tertinggi',
    ])) {
      return VoiceCommandIntent.queryTopProduct;
    }
    if (_containsAny(text, const [
      'saldo dompet',
      'saldo tunai',
      'saldo kas',
      'berapa saldo',
      'total saldo',
      'saldo bank',
      'saldonya paling besar',
    ])) {
      return VoiceCommandIntent.queryWalletBalance;
    }
    if (_containsAny(text, const ['stok', 'stock']) &&
        _containsAny(text, const [
          'berapa',
          'tinggal',
          'sisa',
          'cek stok',
          'cek stock',
          'apakah',
          'masih ada',
        ])) {
      return VoiceCommandIntent.queryProductStock;
    }
    if (_containsAny(text, const [
      'keuntungan',
      'laba bersih',
      'berapa laba',
      'laba hari',
      'laba minggu',
      'laba bulan',
      'berapa profit',
      'profit hari',
      'profit minggu',
      'profit bulan',
    ])) {
      return VoiceCommandIntent.queryProfit;
    }
    if (_containsAny(text, const ['omzet', 'omset'])) {
      return VoiceCommandIntent.queryRevenue;
    }
    if (_containsAny(text, const [
      'total penjualan',
      'berapa penjualan',
      'hasil penjualan',
      'jualan berapa',
      'penjualan hari ini berapa',
      'penjualan minggu ini berapa',
      'penjualan bulan ini berapa',
    ])) {
      return VoiceCommandIntent.querySales;
    }
    if (_containsAny(text, const [
      'total pemasukan',
      'berapa pemasukan',
      'pemasukan hari ini',
      'pemasukan kemarin',
      'pemasukan minggu ini',
      'pemasukan minggu lalu',
      'pemasukan bulan ini',
      'pemasukan bulan lalu',
      'pendapatan non penjualan',
    ])) {
      return VoiceCommandIntent.queryIncome;
    }
    if (_containsAny(text, const [
      'berapa pengeluaran',
      'total pengeluaran',
      'pengeluaran terbesar',
    ])) {
      return VoiceCommandIntent.queryExpense;
    }
    if (_containsAny(text, const [
      'berapa transaksi',
      'jumlah transaksi',
      'banyak transaksi',
    ])) {
      return VoiceCommandIntent.queryTransactionCount;
    }
    return null;
  }

  bool _hasNavigationVerb(String text) {
    return RegExp(
      r'\b(buka|tampilkan|lihat|menuju|pergi|masuk|tutup)\b|saya mau lihat',
    ).hasMatch(text);
  }

  bool _isUnsupportedStockMutation(String text) {
    return RegExp(
      r'\b(?:kurangi|kurangkan|dikurangi|keluarkan)\b.*\bstok\b|\bstok\b.*\b(?:kurangi|kurangkan|dikurangi|keluarkan)\b|\b(?:ubah|ganti|set|setel)\s+stok\b|\bstok\b.*\b(?:menjadi|jadi)\b',
    ).hasMatch(text);
  }

  bool _isStockIncrement(String text) {
    if (RegExp(
      r'\b(?:restok|re\s+stok)\b|\btambah(?:kan)?\s+stok\b|\bmasukkan\b.*\bstok\b|\bke\s+stok\b|\bstok(?:nya)?\b.*\b(?:ditambah|tambah(?:kan)?)\b|\bditambah\s+stok(?:nya)?\b',
    ).hasMatch(text)) {
      return true;
    }
    return RegExp(
      r'^(?:tolong\s+)?tambah(?:kan)?\s+(?!produk\b|barang\b|stok\b).+\b(?:\d+(?:[.,]\d+)?|nol|satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|setengah|seperempat)\b.*\b(?:pcs|buah|biji|bungkus|potong|porsi|gelas|botol|cup|tusuk|kotak|sachet|saset|kilo|kg|kilogram|gram|ons|liter|ml|meter|cm|karton|dus|pack|pak|renteng|ikat|ekor|lembar|plastik|mangkok|mangkuk|piring)\b',
    ).hasMatch(text);
  }

  bool _isPriceUpdate(String text) {
    return RegExp(
      r'\b(?:ubah|ganti|update|setel|naikkan|turunkan)\b.*\b(?:harga|retail|grosir|kulakan|modal)\b|\b(?:harga(?:\s+(?:jual|retail|grosir|kulakan|modal|beli))?|harga\s+jualnya|retail|grosir|modal)\b.*\b(?:ubah|ganti|update|setel|naikkan|turunkan|menjadi|jadi|sekarang)\b',
    ).hasMatch(text);
  }

  bool _containsAny(String text, List<String> values) {
    return values.any(text.contains);
  }

  VoiceIntentClassification _result(
    VoiceCommandIntent intent,
    double confidence,
  ) {
    return VoiceIntentClassification(intent: intent, confidence: confidence);
  }
}
