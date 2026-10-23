import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/models/business_query_data.dart';
import 'package:mikiezy/domain/models/business_query_result.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/voice_business_query_handler.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';

void main() {
  const router = VoiceCommandRouter();
  const handler = VoiceBusinessQueryHandler();
  final now = DateTime(2026, 7, 13, 18);
  final data = _businessData();

  VoiceCommandResponse ask(String text, {BusinessQueryData? source}) {
    return handler.handle(
      command: router.route(text),
      data: source ?? data,
      now: now,
    );
  }

  group('financial and transaction queries', () {
    test('answers revenue from sales only with a natural TTS amount', () {
      final response = ask('Berapa omzet hari ini?');

      expect(response.businessResult?.metric, BusinessMetricType.revenue);
      expect(response.businessResult?.moneyValue, 50000);
      expect(response.displayText, contains('Rp 50.000'));
      expect(response.spokenText, contains('lima puluh ribu rupiah'));
      expect(response.spokenText, isNot(contains('Rp')));
    });

    test('separates sales and non-sale income', () {
      final sales = ask('Berapa total penjualan hari ini?');
      final income = ask('Berapa pemasukan hari ini?');

      expect(sales.businessResult?.metric, BusinessMetricType.sales);
      expect(sales.businessResult?.moneyValue, 50000);
      expect(income.businessResult?.metric, BusinessMetricType.income);
      expect(income.businessResult?.moneyValue, 100000);
    });

    test('answers net profit using historical cost and expenses', () {
      final response = ask('Berapa keuntungan hari ini?');

      // 50,000 sales - 20,000 cost + 100,000 income - 15,000 expense.
      expect(response.businessResult?.moneyValue, 115000);
      expect(response.businessResult?.revenueValue, 50000);
    });

    test('supports expense period and largest expense', () {
      final total = ask('Berapa pengeluaran bulan ini?');
      final largest = ask('Apa pengeluaran terbesar bulan ini?');

      expect(total.businessResult?.moneyValue, 15000);
      expect(largest.businessResult?.isLargest, isTrue);
      expect(largest.displayText, contains('Bahan baku'));
    });

    test('counts all transactions and filters sales explicitly', () {
      final all = ask('Ada berapa transaksi hari ini?');
      final sales = ask('Berapa transaksi penjualan hari ini?');

      expect(all.businessResult?.countValue, 3);
      expect(all.businessResult?.saleCount, 1);
      expect(all.businessResult?.incomeCount, 1);
      expect(all.businessResult?.expenseCount, 1);
      expect(sales.businessResult?.countValue, 1);
      expect(
        sales.businessResult?.transactionFilter,
        BusinessTransactionFilter.sale,
      );
    });

    test('returns empty status without presenting a zero value', () {
      final response = ask('Berapa omzet bulan lalu?');

      expect(response.businessResult?.status, BusinessQueryStatus.empty);
      expect(response.businessResult?.moneyValue, isNull);
      expect(response.displayText, 'Belum ada transaksi penjualan bulan lalu.');
    });

    test('answers latest transaction and kind-specific latest transaction', () {
      final latest = ask('Apa transaksi terakhir saya?');
      final latestSale = ask('Penjualan terakhir apa?');

      expect(latest.businessResult?.transactionKind, TransactionKind.expense);
      expect(latest.displayText, contains('Bahan baku'));
      expect(latestSale.businessResult?.transactionKind, TransactionKind.sale);
      expect(latestSale.displayText, contains('2 item'));
    });
  });

  group('product queries', () {
    test('returns top N products using the requested period', () {
      final response = ask('Sebutkan 3 produk terlaris bulan ini');

      expect(response.businessResult?.items, hasLength(2));
      expect(response.businessResult?.items.first.name, 'Kopi Susu');
      expect(response.businessResult?.items.first.quantity, 2);
    });

    test('resolves stock by exact name and learned alias', () {
      final exact = ask('Stok kopi susu tinggal berapa?');
      final alias = ask('Cek stok kopi dingin');

      expect(exact.businessResult?.productName, 'Kopi Susu');
      expect(exact.businessResult?.quantity, 8);
      expect(alias.businessResult?.productName, 'Kopi Susu');
    });

    test('does not choose an ambiguous product automatically', () {
      final response = ask('Stok Aqua tinggal berapa?');

      expect(response.businessResult?.status, BusinessQueryStatus.ambiguous);
      expect(response.businessResult?.items, hasLength(2));
      expect(response.kind, VoiceResponseKind.question);
    });

    test('returns not found for an unknown product', () {
      final response = ask('Stok kopi pandan tinggal berapa?');

      expect(response.businessResult?.status, BusinessQueryStatus.notFound);
      expect(response.displayText, contains('belum ditemukan'));
    });

    test('reports tracked zero stock as out of stock', () {
      final response = ask('Apakah stok gula masih ada?');

      expect(response.businessResult?.quantity, 0);
      expect(response.displayText, contains('habis'));
    });

    test('low stock includes tracked empty and per-product threshold', () {
      final response = ask('Barang apa yang stoknya hampir habis?');

      expect(response.businessResult?.items, hasLength(2));
      expect(
        response.businessResult?.items.map((item) => item.name),
        containsAll(['Gula', 'Teh Celup']),
      );
      expect(response.displayText, contains('Gula habis'));
    });
  });

  group('wallet and source-state queries', () {
    test('answers exact wallet and aggregate balance', () {
      final exact = ask('Berapa saldo dompet BCA Utama sekarang?');
      final all = ask('Berapa total saldo semua dompet?');

      expect(exact.businessResult?.walletName, 'BCA Utama');
      expect(exact.businessResult?.moneyValue, 500000);
      expect(all.businessResult?.isAggregate, isTrue);
      expect(all.businessResult?.moneyValue, 625000);
    });

    test('does not choose an ambiguous wallet automatically', () {
      final response = ask('Berapa saldo BCA?');

      expect(response.businessResult?.status, BusinessQueryStatus.ambiguous);
      expect(response.businessResult?.items, hasLength(2));
    });

    test('answers the largest wallet deterministically', () {
      final response = ask('Dompet mana yang saldonya paling besar?');

      expect(response.businessResult?.isLargest, isTrue);
      expect(response.businessResult?.walletName, 'BCA Utama');
    });

    test('returns a failure while repository-backed data is not ready', () {
      final response = ask(
        'Berapa omzet hari ini?',
        source: BusinessQueryData(isReady: false),
      );

      expect(response.businessResult?.status, BusinessQueryStatus.failure);
      expect(response.businessResult?.moneyValue, isNull);
      expect(response.displayText, contains('masih dimuat'));
    });
  });
}

BusinessQueryData _businessData() {
  final now = DateTime(2026, 7, 13);
  return BusinessQueryData(
    transactions: [
      _transaction(
        id: 'sale',
        kind: TransactionKind.sale,
        createdAt: now.add(const Duration(hours: 9)),
        amount: 50000,
        lines: const [
          TransactionLine(
            productId: 'coffee',
            productName: 'Kopi Susu',
            quantity: 2,
            unit: SaleUnit.gelas,
            unitPrice: 20000,
            costPrice: 8000,
            segment: PriceSegment.retail,
          ),
          TransactionLine(
            productId: 'tea',
            productName: 'Teh Celup',
            quantity: 1,
            unit: SaleUnit.pcs,
            unitPrice: 10000,
            costPrice: 4000,
            segment: PriceSegment.retail,
          ),
        ],
      ),
      _transaction(
        id: 'income',
        kind: TransactionKind.income,
        createdAt: now.add(const Duration(hours: 10)),
        amount: 100000,
        categoryName: 'Modal masuk',
      ),
      _transaction(
        id: 'expense',
        kind: TransactionKind.expense,
        createdAt: now.add(const Duration(hours: 11)),
        amount: 15000,
        categoryName: 'Bahan baku',
      ),
    ],
    products: const [
      Product(
        id: 'coffee',
        name: 'Kopi Susu',
        category: 'Minuman',
        costPrice: 8000,
        retailPrice: 20000,
        wholesalePrice: 18000,
        packSize: 0,
        cartonSize: 0,
        stockPcs: 8,
      ),
      Product(
        id: 'tea',
        name: 'Teh Celup',
        category: 'Minuman',
        costPrice: 4000,
        retailPrice: 10000,
        wholesalePrice: 9000,
        packSize: 0,
        cartonSize: 0,
        stockPcs: 5,
      ),
      Product(
        id: 'sugar',
        name: 'Gula',
        category: 'Sembako',
        costPrice: 10000,
        retailPrice: 15000,
        wholesalePrice: 14000,
        packSize: 0,
        cartonSize: 0,
        stockPcs: 0,
      ),
      Product(
        id: 'aqua-small',
        name: 'Aqua 600 ml',
        category: 'Minuman',
        costPrice: 3000,
        retailPrice: 5000,
        wholesalePrice: 4500,
        packSize: 0,
        cartonSize: 24,
        stockPcs: 10,
      ),
      Product(
        id: 'aqua-large',
        name: 'Aqua 1.5 liter',
        category: 'Minuman',
        costPrice: 5000,
        retailPrice: 8000,
        wholesalePrice: 7500,
        packSize: 0,
        cartonSize: 12,
        stockPcs: 10,
      ),
    ],
    wallets: const [
      Wallet(
        id: 'bca-main',
        name: 'BCA Utama',
        balance: 500000,
        isPrimary: true,
      ),
      Wallet(
        id: 'bca-saving',
        name: 'BCA Tabungan',
        balance: 100000,
        isPrimary: false,
      ),
      Wallet(id: 'cash', name: 'Kas Toko', balance: 25000, isPrimary: false),
    ],
    productAliases: [
      VoiceProductAlias(
        id: 'alias-coffee',
        aliasText: 'kopi dingin',
        normalizedAlias: 'kopi dingin',
        productId: 'coffee',
        canonicalProductName: 'Kopi Susu',
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}

TransactionRecord _transaction({
  required String id,
  required TransactionKind kind,
  required DateTime createdAt,
  required int amount,
  String categoryName = 'Penjualan',
  List<TransactionLine> lines = const [],
}) {
  return TransactionRecord(
    id: id,
    kind: kind,
    createdAt: createdAt,
    walletId: 'wallet',
    walletName: 'Dompet Utama',
    categoryId: 'category',
    categoryName: categoryName,
    lines: lines,
    amount: amount,
    discount: 0,
    note: '',
    evidencePath: null,
    ocrSource: null,
    syncStatus: SyncStatus.localOnly,
  );
}
