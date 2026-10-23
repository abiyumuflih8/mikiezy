import '../../core/formatters.dart';
import '../../domain/models/business_query_result.dart';
import '../../domain/services/report_period_resolver.dart';
import '../../models/mikiezy_models.dart';
import 'voice_command.dart';

class VoiceResponseBuilder {
  const VoiceResponseBuilder();

  VoiceCommandResponse unknown() {
    return const VoiceCommandResponse(
      displayText:
          'Maaf, saya belum memahami perintah tersebut. Kamu bisa mengatakan jual produk, tambah produk, buka halaman, atau menanyakan laporan.',
      kind: VoiceResponseKind.error,
    );
  }

  VoiceCommandResponse unsupported(VoiceCommand command) {
    return VoiceCommandResponse(
      displayText:
          'Perintah ${_intentLabel(command.intent)} sudah dikenali, tetapi belum aktif.',
      kind: VoiceResponseKind.information,
    );
  }

  VoiceCommandResponse multipleCommands() {
    return const VoiceCommandResponse(
      displayText:
          'Saya mendengar lebih dari satu perintah. Sampaikan satu perintah terlebih dahulu agar aman.',
      kind: VoiceResponseKind.question,
    );
  }

  VoiceCommandResponse confirmationRequired() {
    return const VoiceCommandResponse(
      displayText:
          'Perintah ini akan mengubah data. Berikan konfirmasi yang jelas sebelum dilanjutkan.',
      kind: VoiceResponseKind.confirmation,
    );
  }

  VoiceCommandResponse information(String message, {String? spokenText}) {
    return VoiceCommandResponse(displayText: message, spokenText: spokenText);
  }

  VoiceCommandResponse question(String message, {String? spokenText}) {
    return VoiceCommandResponse(
      displayText: message,
      spokenText: spokenText,
      kind: VoiceResponseKind.question,
    );
  }

  VoiceCommandResponse confirmation(String message, {String? spokenText}) {
    return VoiceCommandResponse(
      displayText: message,
      spokenText: spokenText,
      kind: VoiceResponseKind.confirmation,
    );
  }

  VoiceCommandResponse error(String message, {String? spokenText}) {
    return VoiceCommandResponse(
      displayText: message,
      spokenText: spokenText,
      kind: VoiceResponseKind.error,
    );
  }

  VoiceCommandResponse business(BusinessQueryResult result) {
    if (result.status != BusinessQueryStatus.success) {
      return _businessStateResponse(result);
    }
    return switch (result.metric) {
      BusinessMetricType.revenue ||
      BusinessMetricType.sales => _salesResponse(result),
      BusinessMetricType.profit => _profitResponse(result),
      BusinessMetricType.income => _incomeResponse(result),
      BusinessMetricType.expense => _expenseResponse(result),
      BusinessMetricType.transactionCount => _transactionCountResponse(result),
      BusinessMetricType.topProduct => _topProductResponse(result),
      BusinessMetricType.productStock => _stockResponse(result),
      BusinessMetricType.lowStock => _lowStockResponse(result),
      BusinessMetricType.walletBalance => _walletResponse(result),
      BusinessMetricType.latestTransaction => _latestTransactionResponse(
        result,
      ),
    };
  }

  VoiceCommandResponse _businessStateResponse(BusinessQueryResult result) {
    final title = _metricTitle(result);
    final period = result.period?.label ?? 'saat ini';
    final message = switch (result.status) {
      BusinessQueryStatus.empty => switch (result.metric) {
        BusinessMetricType.revenue ||
        BusinessMetricType.sales => 'Belum ada transaksi penjualan $period.',
        BusinessMetricType.profit =>
          'Belum ada transaksi yang membentuk laba $period.',
        BusinessMetricType.income =>
          'Belum ada pemasukan non-penjualan $period.',
        BusinessMetricType.expense => 'Belum ada pengeluaran $period.',
        BusinessMetricType.transactionCount =>
          'Belum ada ${_filterLabel(result.transactionFilter)} $period.',
        BusinessMetricType.topProduct => 'Belum ada produk terjual $period.',
        BusinessMetricType.productStock => 'Data stok produk belum tersedia.',
        BusinessMetricType.lowStock =>
          'Tidak ada produk dengan stok menipis saat ini.',
        BusinessMetricType.walletBalance => 'Belum ada dompet yang tercatat.',
        BusinessMetricType.latestTransaction =>
          'Belum ada ${_filterLabel(result.transactionFilter)} yang tersimpan.',
      },
      BusinessQueryStatus.notFound =>
        result.message ?? 'Data yang diminta belum ditemukan.',
      BusinessQueryStatus.ambiguous =>
        result.message ??
            'Saya menemukan beberapa data yang mirip. Sebutkan nama lebih lengkap.',
      BusinessQueryStatus.invalidPeriod =>
        result.message ??
            'Saya belum memahami periodenya. Coba katakan hari ini, minggu ini, atau bulan ini.',
      BusinessQueryStatus.unsupported =>
        result.message ?? 'Pertanyaan tersebut belum didukung.',
      BusinessQueryStatus.failure =>
        result.message ?? 'Data belum dapat dibaca. Silakan coba lagi.',
      BusinessQueryStatus.success => '',
    };
    final kind = switch (result.status) {
      BusinessQueryStatus.ambiguous ||
      BusinessQueryStatus.invalidPeriod => VoiceResponseKind.question,
      BusinessQueryStatus.failure ||
      BusinessQueryStatus.notFound => VoiceResponseKind.error,
      _ => VoiceResponseKind.information,
    };
    return VoiceCommandResponse(
      title: title,
      displayText: message,
      spokenText: message,
      kind: kind,
      businessResult: result,
      suggestedAction: result.status == BusinessQueryStatus.ambiguous
          ? 'Ulangi dengan nama yang lebih lengkap.'
          : null,
    );
  }

  VoiceCommandResponse _salesResponse(BusinessQueryResult result) {
    final isRevenue = result.metric == BusinessMetricType.revenue;
    final label = isRevenue ? 'Omzet' : 'Total penjualan';
    final period = result.period?.label ?? 'hari ini';
    final amount = result.moneyValue ?? 0;
    final count = result.saleCount ?? result.countValue ?? 0;
    return _businessInformation(
      result,
      title: '$label ${_capitalize(period)}',
      displayText:
          '$label $period adalah ${rupiah(amount)} dari $count transaksi penjualan.',
      spokenText:
          '$label $period adalah ${_spokenRupiah(amount)} dari ${_numberWords(count)} transaksi penjualan.',
    );
  }

  VoiceCommandResponse _profitResponse(BusinessQueryResult result) {
    final period = result.period?.label ?? 'hari ini';
    final profit = result.moneyValue ?? 0;
    final revenue = result.revenueValue ?? 0;
    final estimate = result.isEstimate ? 'Estimasi ' : '';
    final detail = result.isEstimate
        ? ' Sebagian transaksi tidak memiliki snapshot modal lengkap.'
        : '';
    return _businessInformation(
      result,
      title: '${estimate}Keuntungan ${_capitalize(period)}',
      displayText:
          '${estimate}keuntungan $period adalah ${rupiah(profit)} dari omzet ${rupiah(revenue)}.$detail',
      spokenText:
          '${estimate}keuntungan $period adalah ${_spokenRupiah(profit)} dari omzet ${_spokenRupiah(revenue)}.${result.isEstimate ? ' Sebagian data modal belum lengkap.' : ''}',
    );
  }

  VoiceCommandResponse _incomeResponse(BusinessQueryResult result) {
    final period = result.period?.label ?? 'hari ini';
    final amount = result.moneyValue ?? 0;
    final count = result.incomeCount ?? result.countValue ?? 0;
    return _businessInformation(
      result,
      title: 'Pemasukan ${_capitalize(period)}',
      displayText:
          'Pemasukan non-penjualan $period adalah ${rupiah(amount)} dari $count transaksi.',
      spokenText:
          'Pemasukan non penjualan $period adalah ${_spokenRupiah(amount)} dari ${_numberWords(count)} transaksi.',
    );
  }

  VoiceCommandResponse _expenseResponse(BusinessQueryResult result) {
    final period = result.period?.label ?? 'hari ini';
    final amount = result.moneyValue ?? 0;
    if (result.isLargest) {
      final description = _firstNonEmpty([
        result.categoryName,
        result.note,
        'Tanpa kategori',
      ]);
      return _businessInformation(
        result,
        title: 'Pengeluaran Terbesar ${_capitalize(period)}',
        displayText:
            'Pengeluaran terbesar $period adalah $description sebesar ${rupiah(amount)}.',
        spokenText:
            'Pengeluaran terbesar $period adalah $description sebesar ${_spokenRupiah(amount)}.',
      );
    }
    final count = result.expenseCount ?? result.countValue ?? 0;
    return _businessInformation(
      result,
      title: 'Pengeluaran ${_capitalize(period)}',
      displayText:
          'Total pengeluaran $period adalah ${rupiah(amount)} dari $count transaksi.',
      spokenText:
          'Total pengeluaran $period adalah ${_spokenRupiah(amount)} dari ${_numberWords(count)} transaksi.',
    );
  }

  VoiceCommandResponse _transactionCountResponse(BusinessQueryResult result) {
    final period = result.period?.label ?? 'hari ini';
    final count = result.countValue ?? 0;
    final filter = result.transactionFilter;
    if (filter != BusinessTransactionFilter.all) {
      final label = _filterLabel(filter);
      return _businessInformation(
        result,
        title: 'Transaksi ${_capitalize(period)}',
        displayText: '$period ada $count $label.',
        spokenText: '$period ada ${_numberWords(count)} $label.',
      );
    }
    final parts = <String>[
      if ((result.saleCount ?? 0) > 0) '${result.saleCount} penjualan',
      if ((result.incomeCount ?? 0) > 0) '${result.incomeCount} pemasukan',
      if ((result.expenseCount ?? 0) > 0) '${result.expenseCount} pengeluaran',
      if ((result.adjustmentCount ?? 0) > 0)
        '${result.adjustmentCount} penyesuaian',
    ];
    final spokenParts = <String>[
      if ((result.saleCount ?? 0) > 0)
        '${_numberWords(result.saleCount!)} penjualan',
      if ((result.incomeCount ?? 0) > 0)
        '${_numberWords(result.incomeCount!)} pemasukan',
      if ((result.expenseCount ?? 0) > 0)
        '${_numberWords(result.expenseCount!)} pengeluaran',
      if ((result.adjustmentCount ?? 0) > 0)
        '${_numberWords(result.adjustmentCount!)} penyesuaian',
    ];
    return _businessInformation(
      result,
      title: 'Transaksi ${_capitalize(period)}',
      displayText:
          '$period ada $count transaksi${parts.isEmpty ? '.' : ', terdiri dari ${_joinNatural(parts)}.'}',
      spokenText:
          '$period ada ${_numberWords(count)} transaksi${spokenParts.isEmpty ? '.' : ', terdiri dari ${_joinNatural(spokenParts)}.'}',
    );
  }

  VoiceCommandResponse _topProductResponse(BusinessQueryResult result) {
    final period = result.period?.label ?? 'hari ini';
    final items = result.items;
    if (items.length == 1) {
      final item = items.first;
      final quantity = quantityLabel(item.quantity ?? 0);
      return _businessInformation(
        result,
        title: 'Produk Terlaris ${_capitalize(period)}',
        displayText:
            'Produk terlaris $period adalah ${item.name}, dengan total $quantity ${item.unitLabel ?? 'satuan'} terjual.',
        spokenText:
            'Produk terlaris $period adalah ${item.name}, dengan total ${_spokenNumber(item.quantity ?? 0)} ${item.unitLabel ?? 'satuan'} terjual.',
      );
    }
    final displayItems = items
        .map(
          (item) =>
              '${item.name} ${quantityLabel(item.quantity ?? 0)} ${item.unitLabel ?? 'satuan'}',
        )
        .toList(growable: false);
    final spokenItems = items
        .map(
          (item) =>
              '${item.name} ${_spokenNumber(item.quantity ?? 0)} ${item.unitLabel ?? 'satuan'}',
        )
        .toList(growable: false);
    return _businessInformation(
      result,
      title: 'Produk Terlaris ${_capitalize(period)}',
      displayText:
          '${items.length} produk terlaris $period adalah ${_joinNatural(displayItems)}.',
      spokenText:
          '${_numberWords(items.length)} produk terlaris $period adalah ${_joinNatural(spokenItems)}.',
    );
  }

  VoiceCommandResponse _stockResponse(BusinessQueryResult result) {
    final name = result.productName ?? 'Produk';
    final quantity = result.quantity ?? 0;
    if (result.stockStatus == ProductStockStatus.notTracked ||
        result.stockTrackingUnknown) {
      return _businessInformation(
        result,
        title: 'Stok $name',
        displayText: 'Stok $name tidak dilacak.',
        spokenText: 'Stok $name tidak dilacak.',
      );
    }
    if (result.stockStatus == ProductStockStatus.outOfStock || quantity <= 0) {
      return _businessInformation(
        result,
        title: 'Stok $name',
        displayText: 'Stok $name saat ini habis.',
        spokenText: 'Stok $name saat ini habis.',
      );
    }
    return _businessInformation(
      result,
      title: 'Stok $name',
      displayText:
          'Stok $name saat ini ${quantityLabel(quantity)} ${result.unitLabel ?? 'satuan'}.',
      spokenText:
          'Stok $name saat ini ${_spokenNumber(quantity)} ${result.unitLabel ?? 'satuan'}.',
    );
  }

  VoiceCommandResponse _lowStockResponse(BusinessQueryResult result) {
    final items = result.items.take(5).toList(growable: false);
    final displayItems = items
        .map(
          (item) => item.stockStatus == ProductStockStatus.outOfStock
              ? '${item.name} habis'
              : '${item.name} ${quantityLabel(item.quantity ?? 0)} ${item.unitLabel ?? 'satuan'}',
        )
        .toList(growable: false);
    final spokenItems = items
        .map(
          (item) => item.stockStatus == ProductStockStatus.outOfStock
              ? '${item.name} habis'
              : '${item.name} ${_spokenNumber(item.quantity ?? 0)} ${item.unitLabel ?? 'satuan'}',
        )
        .toList(growable: false);
    final total = result.countValue ?? result.items.length;
    final prefix = total > items.length
        ? 'Ada $total produk dengan stok menipis. Lima terendah adalah '
        : 'Ada $total produk dengan stok menipis: ';
    final spokenPrefix = total > items.length
        ? 'Ada ${_numberWords(total)} produk dengan stok menipis. Lima terendah adalah '
        : 'Ada ${_numberWords(total)} produk dengan stok menipis: ';
    return _businessInformation(
      result,
      title: 'Stok Menipis',
      displayText: '$prefix${_joinNatural(displayItems)}.',
      spokenText: '$spokenPrefix${_joinNatural(spokenItems)}.',
    );
  }

  VoiceCommandResponse _walletResponse(BusinessQueryResult result) {
    final amount = result.moneyValue ?? 0;
    if (result.isAggregate) {
      return _businessInformation(
        result,
        title: 'Total Saldo Dompet',
        displayText:
            'Total saldo seluruh dompet adalah ${rupiah(amount)} dari ${result.countValue ?? result.items.length} dompet.',
        spokenText:
            'Total saldo seluruh dompet adalah ${_spokenRupiah(amount)}.',
      );
    }
    final walletName = result.walletName ?? 'Dompet';
    final prefix = result.isLargest ? 'Saldo terbesar ada di' : 'Saldo';
    return _businessInformation(
      result,
      title: result.isLargest ? 'Saldo Dompet Terbesar' : 'Saldo $walletName',
      displayText: '$prefix $walletName sebesar ${rupiah(amount)}.',
      spokenText: '$prefix $walletName sebesar ${_spokenRupiah(amount)}.',
    );
  }

  VoiceCommandResponse _latestTransactionResponse(BusinessQueryResult result) {
    final kind = (result.transactionKind ?? TransactionKind.adjustment).label
        .toLowerCase();
    final amount = result.moneyValue ?? 0;
    final occurredAt = result.occurredAt;
    final time = occurredAt == null
        ? ''
        : ' pada pukul ${timeLabel(occurredAt)}';
    final spokenTime = occurredAt == null
        ? ''
        : ' pada ${_spokenTime(occurredAt)}';
    String subject;
    String spokenSubject;
    if (result.transactionKind == TransactionKind.sale) {
      if ((result.itemCount ?? 0) > 1) {
        subject = '$kind ${result.itemCount} item';
        spokenSubject = '$kind ${_numberWords(result.itemCount!)} item';
      } else {
        final product = result.productName ?? 'produk tanpa nama';
        final quantity = result.quantity;
        subject = quantity == null
            ? '$kind $product'
            : '$kind $product ${quantityLabel(quantity)} ${result.unitLabel ?? 'satuan'}';
        spokenSubject = quantity == null
            ? '$kind $product'
            : '$kind $product ${_spokenNumber(quantity)} ${result.unitLabel ?? 'satuan'}';
      }
    } else {
      final category = _firstNonEmpty([
        result.categoryName,
        result.note,
        'tanpa kategori',
      ]);
      subject = '$kind $category';
      spokenSubject = subject;
    }
    return _businessInformation(
      result,
      title: 'Transaksi Terakhir',
      displayText:
          'Transaksi terakhir adalah $subject sebesar ${rupiah(amount)}$time.',
      spokenText:
          'Transaksi terakhir adalah $spokenSubject sebesar ${_spokenRupiah(amount)}$spokenTime.',
    );
  }

  VoiceCommandResponse _businessInformation(
    BusinessQueryResult result, {
    required String title,
    required String displayText,
    required String spokenText,
  }) {
    return VoiceCommandResponse(
      title: title,
      displayText: displayText,
      spokenText: spokenText,
      businessResult: result,
    );
  }

  String _metricTitle(BusinessQueryResult result) {
    final period = result.period?.label;
    final label = switch (result.metric) {
      BusinessMetricType.revenue => 'Omzet',
      BusinessMetricType.sales => 'Penjualan',
      BusinessMetricType.profit => 'Keuntungan',
      BusinessMetricType.income => 'Pemasukan',
      BusinessMetricType.expense => 'Pengeluaran',
      BusinessMetricType.transactionCount => 'Jumlah Transaksi',
      BusinessMetricType.topProduct => 'Produk Terlaris',
      BusinessMetricType.productStock => 'Stok Produk',
      BusinessMetricType.lowStock => 'Stok Menipis',
      BusinessMetricType.walletBalance => 'Saldo Dompet',
      BusinessMetricType.latestTransaction => 'Transaksi Terakhir',
    };
    return period == null ? label : '$label ${_capitalize(period)}';
  }

  String _filterLabel(BusinessTransactionFilter filter) {
    return switch (filter) {
      BusinessTransactionFilter.all => 'transaksi',
      BusinessTransactionFilter.sale => 'transaksi penjualan',
      BusinessTransactionFilter.income => 'transaksi pemasukan',
      BusinessTransactionFilter.expense => 'transaksi pengeluaran',
    };
  }

  String _spokenRupiah(int value) {
    final prefix = value < 0 ? 'minus ' : '';
    return '$prefix${_numberWords(value.abs())} rupiah';
  }

  String _spokenTime(DateTime value) {
    final hour = _numberWords(value.hour);
    if (value.minute == 0) return 'pukul $hour tepat';
    return 'pukul $hour lewat ${_numberWords(value.minute)} menit';
  }

  String _spokenNumber(num value) {
    if (value % 1 == 0) return _numberWords(value.round());
    final raw = quantityLabel(value);
    final parts = raw.split('.');
    final decimals = parts.length == 1
        ? ''
        : parts[1]
              .split('')
              .map((digit) => _numberWords(int.parse(digit)))
              .join(' ');
    return '${_numberWords(int.parse(parts.first))} koma $decimals'.trim();
  }

  String _numberWords(int value) {
    if (value < 0) return 'minus ${_numberWords(value.abs())}';
    const small = [
      'nol',
      'satu',
      'dua',
      'tiga',
      'empat',
      'lima',
      'enam',
      'tujuh',
      'delapan',
      'sembilan',
      'sepuluh',
      'sebelas',
    ];
    if (value < 12) return small[value];
    if (value < 20) return '${_numberWords(value - 10)} belas';
    if (value < 100) {
      final remainder = value % 10;
      return '${_numberWords(value ~/ 10)} puluh${remainder == 0 ? '' : ' ${_numberWords(remainder)}'}';
    }
    if (value < 200) {
      return 'seratus${value == 100 ? '' : ' ${_numberWords(value - 100)}'}';
    }
    if (value < 1000) {
      final remainder = value % 100;
      return '${_numberWords(value ~/ 100)} ratus${remainder == 0 ? '' : ' ${_numberWords(remainder)}'}';
    }
    if (value < 2000) {
      return 'seribu${value == 1000 ? '' : ' ${_numberWords(value - 1000)}'}';
    }
    if (value < 1000000) {
      final remainder = value % 1000;
      return '${_numberWords(value ~/ 1000)} ribu${remainder == 0 ? '' : ' ${_numberWords(remainder)}'}';
    }
    if (value < 1000000000) {
      final remainder = value % 1000000;
      return '${_numberWords(value ~/ 1000000)} juta${remainder == 0 ? '' : ' ${_numberWords(remainder)}'}';
    }
    if (value < 1000000000000) {
      final remainder = value % 1000000000;
      return '${_numberWords(value ~/ 1000000000)} miliar${remainder == 0 ? '' : ' ${_numberWords(remainder)}'}';
    }
    final remainder = value % 1000000000000;
    return '${_numberWords(value ~/ 1000000000000)} triliun${remainder == 0 ? '' : ' ${_numberWords(remainder)}'}';
  }

  String _joinNatural(List<String> values) {
    if (values.isEmpty) return '';
    if (values.length == 1) return values.first;
    if (values.length == 2) return '${values.first} dan ${values.last}';
    return '${values.take(values.length - 1).join(', ')}, dan ${values.last}';
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _intentLabel(VoiceCommandIntent intent) {
    return switch (intent) {
      VoiceCommandIntent.createSale => 'catat penjualan',
      VoiceCommandIntent.createIncome => 'catat pemasukan',
      VoiceCommandIntent.createExpense => 'catat pengeluaran',
      VoiceCommandIntent.createProduct => 'tambah produk',
      VoiceCommandIntent.incrementProductStock => 'tambah stok produk',
      VoiceCommandIntent.updateProduct => 'ubah harga produk',
      VoiceCommandIntent.queryProfit => 'tanya keuntungan',
      VoiceCommandIntent.queryRevenue => 'tanya omzet',
      VoiceCommandIntent.querySales => 'tanya penjualan',
      VoiceCommandIntent.queryIncome => 'tanya pemasukan',
      VoiceCommandIntent.queryExpense => 'tanya pengeluaran',
      VoiceCommandIntent.queryTransactionCount => 'tanya jumlah transaksi',
      VoiceCommandIntent.queryTopProduct => 'tanya produk terlaris',
      VoiceCommandIntent.queryProductStock => 'tanya stok produk',
      VoiceCommandIntent.queryLowStock => 'tanya stok menipis',
      VoiceCommandIntent.queryWalletBalance => 'tanya saldo dompet',
      VoiceCommandIntent.queryLatestTransaction => 'tanya transaksi terakhir',
      VoiceCommandIntent.navigateDashboard => 'buka dashboard',
      VoiceCommandIntent.navigateTransactions => 'buka transaksi',
      VoiceCommandIntent.navigateProducts => 'buka produk',
      VoiceCommandIntent.navigateReports => 'buka laporan',
      VoiceCommandIntent.navigateAnalytics => 'buka analitik',
      VoiceCommandIntent.navigateWallets => 'buka dompet',
      VoiceCommandIntent.navigateCategories => 'buka kategori',
      VoiceCommandIntent.navigateSettings => 'buka pengaturan',
      VoiceCommandIntent.navigateEditProfile => 'buka edit profil',
      VoiceCommandIntent.navigateVoiceEntry => 'buka pencatatan suara',
      VoiceCommandIntent.goBack => 'kembali',
      VoiceCommandIntent.unknown => 'tidak dikenal',
    };
  }
}
