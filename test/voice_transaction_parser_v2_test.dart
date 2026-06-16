import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/parsed_transaction_item.dart';
import 'package:mikiezy/services/voice/voice_parse_context.dart';
import 'package:mikiezy/services/voice/voice_transaction_parser_v2.dart';

void main() {
  const parser = VoiceTransactionParserV2();
  const context = VoiceParseContext(
    wallets: [
      Wallet(id: 'wallet-cash', name: 'Tunai', balance: 0, isPrimary: true),
      Wallet(id: 'wallet-bca', name: 'BCA', balance: 0, isPrimary: false),
      Wallet(id: 'wallet-qris', name: 'QRIS', balance: 0, isPrimary: false),
    ],
    categories: [
      LedgerCategory(
        id: 'cat-sales',
        name: 'Penjualan',
        direction: MoneyDirection.income,
        isSystem: true,
      ),
      LedgerCategory(
        id: 'cat-raw',
        name: 'Bahan baku',
        direction: MoneyDirection.expense,
        isSystem: true,
      ),
      LedgerCategory(
        id: 'cat-stock',
        name: 'Belanja barang',
        direction: MoneyDirection.expense,
        isSystem: true,
      ),
      LedgerCategory(
        id: 'cat-transport',
        name: 'Transport',
        direction: MoneyDirection.expense,
        isSystem: true,
      ),
      LedgerCategory(
        id: 'cat-income',
        name: 'Pemasukan',
        direction: MoneyDirection.income,
        isSystem: true,
      ),
    ],
    defaultWalletName: 'Dompet Utama',
  );
  const catalogContext = VoiceParseContext(
    products: [
      Product(
        id: 'prd-ayam-bakar',
        name: 'Ayam Bakar',
        category: 'Makanan',
        costPrice: 10000,
        retailPrice: 18000,
        wholesalePrice: 16000,
        packSize: 10,
        cartonSize: 40,
        stockPcs: 25,
      ),
      Product(
        id: 'prd-nasi-goreng',
        name: 'Nasi Goreng',
        category: 'Makanan',
        costPrice: 9000,
        retailPrice: 15000,
        wholesalePrice: 13000,
        packSize: 10,
        cartonSize: 40,
        stockPcs: 80,
      ),
    ],
    wallets: [
      Wallet(id: 'wallet-cash', name: 'Tunai', balance: 0, isPrimary: true),
    ],
    categories: [
      LedgerCategory(
        id: 'cat-sales',
        name: 'Penjualan',
        direction: MoneyDirection.income,
        isSystem: true,
      ),
    ],
    defaultWalletName: 'Dompet Utama',
  );

  group('VoiceTransactionParserV2 mandatory transcripts', () {
    test('parses sale with quantity, unit, and explicit unit price', () {
      final result = parser.parse(
        'jual nasi goreng 3 porsi harga 15000',
        context: context,
      );

      expect(result.kind, TransactionKind.sale);
      expect(result.items, hasLength(1));
      expect(result.items.first.productName, 'Nasi Goreng');
      expect(result.items.first.quantity, 3);
      expect(result.items.first.unit, 'porsi');
      expect(result.items.first.unitPrice, 15000);
      expect(result.items.first.priceMode, ParsedPriceMode.unitPrice);
      expect(result.draft?.amount, 45000);
    });

    test('parses expense with two purchased items', () {
      final result = parser.parse(
        'beli gula 1 kilo 17000 dan kopi 2 bungkus 5000',
        context: context,
      );

      expect(result.kind, TransactionKind.expense);
      expect(result.items, hasLength(2));
      expect(result.items[0].productName, 'Gula');
      expect(result.items[0].quantity, 1);
      expect(result.items[0].unit, 'kilo');
      expect(result.items[0].unitPrice, 17000);
      expect(result.items[1].productName, 'Kopi');
      expect(result.items[1].quantity, 2);
      expect(result.items[1].unit, 'bungkus');
      expect(result.items[1].unitPrice, 5000);
    });

    test('parses expense category and wallet', () {
      final result = parser.parse(
        'pengeluaran beli bensin 50000 pakai tunai',
        context: context,
      );

      expect(result.kind, TransactionKind.expense);
      expect(result.walletName, 'Tunai');
      expect(result.walletId, 'wallet-cash');
      expect(result.categoryName, 'Transport');
      expect(result.items.single.productName, 'Bensin');
      expect(result.items.single.unitPrice, 50000);
    });

    test('uses total as line total for a single sale item', () {
      final result = parser.parse(
        'jual es teh 10 gelas total 50000',
        context: context,
      );

      expect(result.kind, TransactionKind.sale);
      expect(result.totalAmount, 50000);
      expect(result.items.single.productName, 'Es Teh');
      expect(result.items.single.quantity, 10);
      expect(result.items.single.unit, 'gelas');
      expect(result.items.single.lineTotal, 50000);
      expect(result.items.single.unitPrice, 5000);
      expect(result.items.single.priceMode, ParsedPriceMode.lineTotal);
      expect(result.draft?.amount, 50000);
    });

    test('parses per-unit price wording', () {
      final result = parser.parse(
        'beli telur 2 kilo harga 28000 per kilo',
        context: context,
      );

      expect(result.kind, TransactionKind.expense);
      expect(result.items.single.productName, 'Telur');
      expect(result.items.single.quantity, 2);
      expect(result.items.single.unit, 'kilo');
      expect(result.items.single.unitPrice, 28000);
      expect(result.items.single.priceMode, ParsedPriceMode.unitPrice);
    });

    test('parses income with target wallet', () {
      final result = parser.parse(
        'pemasukan servis laptop 150000 masuk ke dompet bca',
        context: context,
      );

      expect(result.kind, TransactionKind.income);
      expect(result.walletName, 'BCA');
      expect(result.walletId, 'wallet-bca');
      expect(result.categoryName, 'Pemasukan');
      expect(result.items.single.productName, 'Servis Laptop');
      expect(result.items.single.unitPrice, 150000);
    });

    test('parses comma-separated and keyword-priced expense items', () {
      final result = parser.parse(
        'beli kopi 2 bungkus harga 5000, gula 1 kilo harga 17000',
        context: context,
      );

      expect(result.kind, TransactionKind.expense);
      expect(result.items, hasLength(2));
      expect(result.items[0].productName, 'Kopi');
      expect(result.items[0].quantity, 2);
      expect(result.items[0].unitPrice, 5000);
      expect(result.items[0].priceMode, ParsedPriceMode.unitPrice);
      expect(result.items[1].productName, 'Gula');
      expect(result.items[1].quantity, 1);
      expect(result.items[1].unitPrice, 17000);
    });

    test('parses masing-masing as unit price and detects QRIS wallet', () {
      final result = parser.parse(
        'penjualan ayam geprek 5 porsi masing-masing 12000 pakai qris',
        context: context,
      );

      expect(result.kind, TransactionKind.sale);
      expect(result.walletName, 'QRIS');
      expect(result.items.single.productName, 'Ayam Geprek');
      expect(result.items.single.quantity, 5);
      expect(result.items.single.unitPrice, 12000);
      expect(result.items.single.priceMode, ParsedPriceMode.unitPrice);
    });

    test('parses Indonesian number words for quantity and money', () {
      final result = parser.parse(
        'jual roti tiga pcs lima ribu',
        context: context,
      );

      expect(result.kind, TransactionKind.sale);
      expect(result.items.single.productName, 'Roti');
      expect(result.items.single.quantity, 3);
      expect(result.items.single.unit, 'pcs');
      expect(result.items.single.unitPrice, 5000);
      expect(result.items.single.priceMode, ParsedPriceMode.unknown);
    });

    test(
      'parses fractional quantity and treats trailing money as line total',
      () {
        final result = parser.parse(
          'beli gula setengah kilo delapan ribu',
          context: context,
        );

        expect(result.kind, TransactionKind.expense);
        expect(result.items.single.productName, 'Gula');
        expect(result.items.single.quantity, 0.5);
        expect(result.items.single.unit, 'kilo');
        expect(result.items.single.lineTotal, 8000);
        expect(result.items.single.unitPrice, 16000);
        expect(result.items.single.priceMode, ParsedPriceMode.lineTotal);
      },
    );
  });

  group('VoiceTransactionParserV2 multi-item parsing', () {
    test('parses two items separated by terus', () {
      final result = parser.parse(
        'catat penjualan ayam bakar 10 bungkus Rp12.000 terus nasi goreng 5 bungkus Rp13.000',
        context: context,
      );

      expect(result.kind, TransactionKind.sale);
      expect(result.items, hasLength(2));
      expect(result.items[0].productName, 'Ayam Bakar');
      expect(result.items[0].quantity, 10);
      expect(result.items[0].unit, 'bungkus');
      expect(result.items[0].unitPrice, 12000);
      expect(result.items[1].productName, 'Nasi Goreng');
      expect(result.items[1].quantity, 5);
      expect(result.items[1].unit, 'bungkus');
      expect(result.items[1].unitPrice, 13000);
      expect(result.draft?.lines, hasLength(2));
      expect(result.draft?.lines[0].unit, SaleUnit.bungkus);
      expect(result.draft?.lines[1].productName, 'Nasi Goreng');
    });

    test('parses five comma-separated items with bare quantities', () {
      final result = parser.parse(
        'catat 2 kopi susu 12000, 1 es teh 5000, 3 roti bakar 15000, 4 pisang goreng 3000, 5 donat 6000',
        context: context,
      );

      expect(result.items, hasLength(5));
      expect(result.items.map((item) => item.productName), [
        'Kopi Susu',
        'Es Teh',
        'Roti Bakar',
        'Pisang Goreng',
        'Donat',
      ]);
      expect(result.items.map((item) => item.quantity), [2, 1, 3, 4, 5]);
      expect(result.items.map((item) => item.unit), [
        'pcs',
        'pcs',
        'pcs',
        'pcs',
        'pcs',
      ]);
      expect(result.items.map((item) => item.unitPrice), [
        12000,
        5000,
        15000,
        3000,
        6000,
      ]);
    });

    test('parses up to thirty items', () {
      final transcript = List.generate(
        30,
        (index) => 'menu${index + 1} 1 pcs ${1000 + index}',
      ).join(', ');
      final result = parser.parse('jual $transcript', context: context);

      expect(result.items, hasLength(30));
      expect(result.draft?.lines, hasLength(30));
      expect(result.items.first.productName, 'Menu1');
      expect(result.items.last.productName, 'Menu30');
      expect(result.items.last.unitPrice, 1029);
      expect(
        result.warnings.any((warning) => warning.contains('30 item pertama')),
        isFalse,
      );
    });

    test('truncates more than thirty items with warning', () {
      final transcript = List.generate(
        31,
        (index) => 'menu${index + 1} 1 pcs ${1000 + index}',
      ).join(', ');
      final result = parser.parse('jual $transcript', context: context);

      expect(result.items, hasLength(30));
      expect(result.items.last.productName, 'Menu30');
      expect(
        result.warnings.any((warning) => warning.contains('30 item pertama')),
        isTrue,
      );
    });

    test('parses price before quantity', () {
      final result = parser.parse(
        'ayam bakar Rp12.000 10 bungkus terus nasi goreng Rp13.000 5 bungkus',
        context: context,
      );

      expect(result.items, hasLength(2));
      expect(result.items[0].productName, 'Ayam Bakar');
      expect(result.items[0].quantity, 10);
      expect(result.items[0].unitPrice, 12000);
      expect(result.items[1].productName, 'Nasi Goreng');
      expect(result.items[1].quantity, 5);
      expect(result.items[1].unitPrice, 13000);
    });

    test('parses quantity and unit before product name', () {
      final result = parser.parse(
        '10 bungkus ayam bakar Rp12.000, 5 bungkus nasi goreng Rp13.000',
        context: context,
      );

      expect(result.items, hasLength(2));
      expect(result.items[0].productName, 'Ayam Bakar');
      expect(result.items[0].quantity, 10);
      expect(result.items[0].unit, 'bungkus');
      expect(result.items[1].productName, 'Nasi Goreng');
      expect(result.items[1].quantity, 5);
      expect(result.items[1].unit, 'bungkus');
    });

    test('uses dan as separator when both sides look like items', () {
      final result = parser.parse(
        'nasi goreng 5 porsi masing-masing 13000 dan ayam geprek 7 porsi masing-masing 15000 pakai qris',
        context: context,
      );

      expect(result.walletName, 'QRIS');
      expect(result.items, hasLength(2));
      expect(result.items[0].productName, 'Nasi Goreng');
      expect(result.items[0].unitPrice, 13000);
      expect(result.items[1].productName, 'Ayam Geprek');
      expect(result.items[1].quantity, 7);
      expect(result.items[1].unitPrice, 15000);
    });

    test('keeps dan inside product name when left side is incomplete', () {
      final result = parser.parse(
        'jual roti dan selai 2 pcs harga 10000',
        context: context,
      );

      expect(result.items, hasLength(1));
      expect(result.items.single.productName, 'Roti Dan Selai');
      expect(result.items.single.quantity, 2);
      expect(result.items.single.unitPrice, 10000);
    });

    test('total mismatch across multiple items creates warning', () {
      final result = parser.parse(
        'jual teh 2 gelas harga 5000 dan roti 1 pcs harga 10000 total 30000',
        context: context,
      );

      expect(result.items, hasLength(2));
      expect(result.needsReview, isTrue);
      expect(
        result.warnings.any((warning) => warning.contains('Total transcript')),
        isTrue,
      );
    });

    test('item without price is kept and marked review', () {
      final result = parser.parse(
        'jual roti 2 pcs terus es teh 1 gelas harga 5000',
        context: context,
      );

      expect(result.items, hasLength(2));
      expect(result.items[0].productName, 'Roti');
      expect(result.items[0].unitPrice, isNull);
      expect(result.items[0].needsReview, isTrue);
      expect(result.items[1].productName, 'Es Teh');
      expect(result.items[1].unitPrice, 5000);
      expect(result.needsReview, isTrue);
    });

    test('parses expense multi-item with terus separators', () {
      final result = parser.parse(
        'beli gula 1 kilo 17000 terus kopi 2 bungkus 5000 terus telur 2 kilo 28000',
        context: context,
      );

      expect(result.kind, TransactionKind.expense);
      expect(result.items, hasLength(3));
      expect(result.items.map((item) => item.productName), [
        'Gula',
        'Kopi',
        'Telur',
      ]);
      expect(result.items.map((item) => item.quantity), [1, 2, 2]);
      expect(result.items.map((item) => item.unitPrice), [17000, 5000, 28000]);
    });
  });

  group('VoiceTransactionParserV2 safety behavior', () {
    test('does not treat first number as quantity unless followed by unit', () {
      final result = parser.parse(
        'jual roti harga 5000 2 pcs',
        context: context,
      );

      expect(result.items.single.productName, 'Roti');
      expect(result.items.single.quantity, 2);
      expect(result.items.single.unitPrice, 5000);
    });

    test(
      'missing price is review-only and does not use fake 15000 fallback',
      () {
        final result = parser.parse('jual roti 2 pcs', context: context);

        expect(result.needsReview, isTrue);
        expect(result.items.single.productName, 'Roti');
        expect(result.items.single.unitPrice, isNull);
        expect(result.draft?.unitPrice, 0);
        expect(result.draft?.productName, isNot('Produk baru'));
        expect(result.warnings.join(' '), contains('Harga'));
      },
    );

    test(
      'unclear product is marked for review without fake product fallback',
      () {
        final result = parser.parse('jual 2 pcs harga 5000', context: context);

        expect(result.needsReview, isTrue);
        expect(result.items.single.productName, isNull);
        expect(result.items.single.warnings.join(' '), contains('Nama barang'));
        expect(result.draft?.productName, isNot('Produk baru'));
      },
    );

    test('mismatched transcript total creates warning', () {
      final result = parser.parse(
        'jual teh 2 gelas harga 5000 total 15000',
        context: context,
      );

      expect(result.needsReview, isTrue);
      expect(
        result.warnings.any((warning) => warning.contains('Total transcript')),
        isTrue,
      );
    });

    test(
      'unknown product from filler phrase keeps transcript product name',
      () {
        final result = parser.parse(
          'catat penjualan itu apa namanya tumpeng harganya 350.000',
          context: catalogContext,
        );

        expect(result.kind, TransactionKind.sale);
        expect(result.items.single.productName, 'Tumpeng');
        expect(result.items.single.matchedProductId, isNull);
        expect(result.items.single.quantity, 1);
        expect(result.items.single.unit, 'pcs');
        expect(result.items.single.unitPrice, 350000);
        expect(result.draft?.productName, 'Tumpeng');
        expect(result.draft?.unitPrice, 350000);
        expect(result.needsReview, isTrue);
        expect(result.warnings.join(' '), contains('belum cocok'));
      },
    );

    test('unknown product is not replaced by catalog product', () {
      final result = parser.parse(
        'jual tumpeng harga 350000',
        context: catalogContext,
      );

      expect(result.items.single.productName, 'Tumpeng');
      expect(result.items.single.matchedProductId, isNull);
      expect(result.draft?.productName, 'Tumpeng');
    });

    test('new product wording is cleaned from product name', () {
      final result = parser.parse(
        'jual produk baru namanya bakso mercon harga 15000',
        context: catalogContext,
      );

      expect(result.items.single.productName, 'Bakso Mercon');
      expect(result.items.single.matchedProductId, isNull);
      expect(result.items.single.unitPrice, 15000);
    });

    test('low-confidence catalog overlap does not create product match', () {
      final result = parser.parse(
        'jual bakar madu harga 20000',
        context: catalogContext,
      );

      expect(result.items.single.productName, 'Bakar Madu');
      expect(result.items.single.matchedProductId, isNull);
      expect(result.draft?.productName, isNot('Ayam Bakar'));
    });
  });
}
