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
        expect(result.draft?.lines.single.quantity, 0.5);
        expect(result.draft?.amount, 8000);
      },
    );
  });

  group('VoiceTransactionParserV2 adaptive dictionary', () {
    test('parses UAS demo voice examples without dropping items', () {
      final cases = [
        (
          text: 'ayam goreng 5 potong 12000 es teh 3 gelas 5000',
          names: ['Ayam Goreng', 'Es Teh'],
          units: ['potong', 'gelas'],
          quantities: [5.0, 3.0],
        ),
        (
          text: 'sate ayam 10 tusuk 2000 aqua 2 botol 4000',
          names: ['Sate Ayam', 'Aqua'],
          units: ['tusuk', 'botol'],
          quantities: [10.0, 2.0],
        ),
        (
          text: 'nasi goreng 3 porsi 15000 kerupuk 2 plastik 1000',
          names: ['Nasi Goreng', 'Kerupuk'],
          units: ['porsi', 'plastik'],
          quantities: [3.0, 2.0],
        ),
        (
          text:
              'ayam bakar 10 bungkus 12000 nasi goreng 5 porsi 13000 es teh 3 gelas 5000',
          names: ['Ayam Bakar', 'Nasi Goreng', 'Es Teh'],
          units: ['bungkus', 'porsi', 'gelas'],
          quantities: [10.0, 5.0, 3.0],
        ),
      ];

      for (final sample in cases) {
        final result = parser.parse(sample.text, context: context);

        expect(
          result.items.map((item) => item.productName).toList(),
          sample.names,
          reason: sample.text,
        );
        expect(
          result.items.map((item) => item.unit).toList(),
          sample.units,
          reason: sample.text,
        );
        expect(
          result.items.map((item) => item.quantity).toList(),
          sample.quantities,
          reason: sample.text,
        );
        expect(result.draft?.lines, hasLength(sample.names.length));
      }
    });

    test('filters conversational filler from captured demo transcripts', () {
      final cases = [
        (
          text:
              'oke oke catat ikan bakar 15.000 3 bungkus harganya Rp15.000 tadi udah bener habis itu ada ayam goreng 3 bungkus Rp20.000 terus ada perkedel 20 biji Rp5.000 harganya satu',
          names: ['Ikan Bakar', 'Ayam Goreng', 'Perkedel'],
          units: ['bungkus', 'bungkus', 'biji'],
          quantities: [3.0, 3.0, 20.0],
          unitPrices: [15000, 20000, 5000],
        ),
        (
          text:
              'catat perkedel tahu 3 biji harganya Rp7.000 habis itu ada ikan nila bakar harganya Rp15.000 3 bungkus habis itu ayam suwir Rp15.000 7 bungkus harga iya itulah',
          names: ['Perkedel Tahu', 'Ikan Nila Bakar', 'Ayam Suwir'],
          units: ['biji', 'bungkus', 'bungkus'],
          quantities: [3.0, 3.0, 7.0],
          unitPrices: [7000, 15000, 15000],
        ),
        (
          text:
              'oke oke catat perkedel tahu 3 bungkus harganya Rp15.000 habis itu ada ayam goreng 3 bungkus Rp20.000 habis itu ayam suwir ada 7 bungkus harganya Rp15.000',
          names: ['Perkedel Tahu', 'Ayam Goreng', 'Ayam Suwir'],
          units: ['bungkus', 'bungkus', 'bungkus'],
          quantities: [3.0, 3.0, 7.0],
          unitPrices: [15000, 20000, 15000],
        ),
      ];

      for (final sample in cases) {
        final result = parser.parse(sample.text, context: context);

        expect(
          result.items.map((item) => item.productName).toList(),
          sample.names,
          reason: sample.text,
        );
        expect(
          result.items.map((item) => item.unit).toList(),
          sample.units,
          reason: sample.text,
        );
        expect(
          result.items.map((item) => item.quantity).toList(),
          sample.quantities,
          reason: sample.text,
        );
        expect(
          result.items.map((item) => item.unitPrice).toList(),
          sample.unitPrices,
          reason: sample.text,
        );
        expect(result.draft?.lines, hasLength(sample.names.length));
      }
    });

    test('splits price-first quantity-later transcript without separators', () {
      final result = parser.parse(
        'nike zakat penjualan ikan bakar harganya Rp15.000 3 bungkus ayam suwir 7 bungkus Rp20.000 es tong-tong harganya Rp15.000 3 gelas',
        context: context,
      );

      expect(result.items.map((item) => item.productName), [
        'Ikan Bakar',
        'Ayam Suwir',
        'Es Tong Tong',
      ]);
      expect(result.items.map((item) => item.quantity), [3, 7, 3]);
      expect(result.items.map((item) => item.unit), [
        'bungkus',
        'bungkus',
        'gelas',
      ]);
      expect(result.items.map((item) => item.unitPrice), [15000, 20000, 15000]);
      expect(result.draft?.lines, hasLength(3));
    });

    test('recognizes expanded default unit aliases', () {
      final result = parser.parse(
        'jual minyak 1 liter harga 20000, sirup 250 ml harga 7000, sate 5 tusuk harga 3000',
        context: context,
      );

      expect(result.items, hasLength(3));
      expect(result.items[0].productName, 'Minyak');
      expect(result.items[0].unit, 'liter');
      expect(result.draft?.lines[0].unit, SaleUnit.liter);
      expect(result.items[1].productName, 'Sirup');
      expect(result.items[1].unit, 'ml');
      expect(result.draft?.lines[1].unit, SaleUnit.ml);
      expect(result.items[2].productName, 'Sate');
      expect(result.items[2].unit, 'tusuk');
      expect(result.draft?.lines[2].unit, SaleUnit.tusuk);
    });

    test('uses learned product aliases before fallback product extraction', () {
      final now = DateTime(2026);
      final aliasContext = VoiceParseContext(
        products: const [
          Product(
            id: 'prd-air-mineral',
            name: 'Air Mineral',
            category: 'Minuman',
            costPrice: 2500,
            retailPrice: 5000,
            wholesalePrice: 4500,
            packSize: 12,
            cartonSize: 48,
            stockPcs: 100,
          ),
        ],
        productAliases: [
          VoiceProductAlias(
            id: 'vpa-aqua',
            aliasText: 'aqua',
            normalizedAlias: 'aqua',
            productId: 'prd-air-mineral',
            canonicalProductName: 'Air Mineral',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        wallets: context.wallets,
        categories: context.categories,
        defaultWalletName: context.defaultWalletName,
      );

      final result = parser.parse(
        'jual aqua 2 botol harga 5000',
        context: aliasContext,
      );

      expect(result.items.single.productName, 'Air Mineral');
      expect(result.items.single.matchedProductId, 'prd-air-mineral');
      expect(result.draft?.lines.single.productId, 'prd-air-mineral');
      expect(result.draft?.lines.single.productName, 'Air Mineral');
    });

    test('does not force ambiguous product aliases', () {
      final now = DateTime(2026);
      final aliasContext = VoiceParseContext(
        products: const [
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
            id: 'prd-ayam-goreng',
            name: 'Ayam Goreng',
            category: 'Makanan',
            costPrice: 10000,
            retailPrice: 17000,
            wholesalePrice: 15000,
            packSize: 10,
            cartonSize: 40,
            stockPcs: 25,
          ),
        ],
        productAliases: [
          VoiceProductAlias(
            id: 'vpa-ayam-bakar',
            aliasText: 'ayam',
            normalizedAlias: 'ayam',
            productId: 'prd-ayam-bakar',
            canonicalProductName: 'Ayam Bakar',
            createdAt: now,
            updatedAt: now,
          ),
          VoiceProductAlias(
            id: 'vpa-ayam-goreng',
            aliasText: 'ayam',
            normalizedAlias: 'ayam',
            productId: 'prd-ayam-goreng',
            canonicalProductName: 'Ayam Goreng',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        wallets: context.wallets,
        categories: context.categories,
        defaultWalletName: context.defaultWalletName,
      );

      final generic = parser.parse(
        'jual ayam 2 potong 12000',
        context: aliasContext,
      );
      final bakar = parser.parse(
        'jual ayam bakar 2 potong 12000',
        context: aliasContext,
      );
      final goreng = parser.parse(
        'jual ayam goreng 2 potong 12000',
        context: aliasContext,
      );

      expect(generic.items.single.productName, 'Ayam');
      expect(generic.items.single.matchedProductId, isNull);
      expect(bakar.items.single.productName, 'Ayam Bakar');
      expect(bakar.items.single.matchedProductId, 'prd-ayam-bakar');
      expect(goreng.items.single.productName, 'Ayam Goreng');
      expect(goreng.items.single.matchedProductId, 'prd-ayam-goreng');
    });

    test('uses learned unit aliases for quantity and draft unit', () {
      final now = DateTime(2026);
      final aliasContext = VoiceParseContext(
        unitAliases: [
          VoiceUnitAlias(
            id: 'vua-slop',
            aliasText: 'slop',
            normalizedAlias: 'slop',
            canonicalUnit: SaleUnit.pack.name,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        wallets: context.wallets,
        categories: context.categories,
        defaultWalletName: context.defaultWalletName,
      );

      final result = parser.parse(
        'jual rokok 1 slop harga 250000',
        context: aliasContext,
      );

      expect(result.items.single.quantity, 1);
      expect(result.items.single.unit, 'pack');
      expect(result.draft?.lines.single.unit, SaleUnit.pack);
    });
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

    test('parses more than thirty items', () {
      final transcript = List.generate(
        35,
        (index) => 'menu${index + 1} 1 pcs ${1000 + index}',
      ).join(', ');
      final result = parser.parse('jual $transcript', context: context);

      expect(result.items, hasLength(35));
      expect(result.draft?.lines, hasLength(35));
      expect(result.items.last.productName, 'Menu35');
      expect(
        result.warnings.any((warning) => warning.contains('item pertama')),
        isFalse,
      );
    });

    test('splits sequential items when speech transcript has no separators', () {
      final result = parser.parse(
        'catat penjualan ayam bakar 10 bungkus 12000 nasi goreng 5 bungkus 13000 es teh 3 gelas 5000',
        context: context,
      );

      expect(result.items, hasLength(3));
      expect(result.draft?.lines, hasLength(3));
      expect(result.items.map((item) => item.productName), [
        'Ayam Bakar',
        'Nasi Goreng',
        'Es Teh',
      ]);
      expect(result.items.map((item) => item.quantity), [10, 5, 3]);
      expect(result.items.map((item) => item.unit), [
        'bungkus',
        'bungkus',
        'gelas',
      ]);
      expect(result.items.map((item) => item.unitPrice), [12000, 13000, 5000]);
    });

    test('parses demo three-item sale without separators', () {
      final result = parser.parse(
        'ayam bakar 10 bungkus 12000 nasi goreng 5 bungkus 13000 es teh 3 gelas 5000',
        context: context,
      );

      expect(result.items, hasLength(3));
      expect(result.draft?.lines, hasLength(3));
      expect(result.items.map((item) => item.productName), [
        'Ayam Bakar',
        'Nasi Goreng',
        'Es Teh',
      ]);
      expect(result.items.map((item) => item.quantity), [10, 5, 3]);
      expect(result.items.map((item) => item.unit), [
        'bungkus',
        'bungkus',
        'gelas',
      ]);
      expect(result.items.map((item) => item.unitPrice), [12000, 13000, 5000]);
    });

    test('splits sequential product and price pairs without separators', () {
      final result = parser.parse(
        'jual ayam bakar 12000 nasi goreng 13000 es teh 5000',
        context: context,
      );

      expect(result.items, hasLength(3));
      expect(result.draft?.lines, hasLength(3));
      expect(result.items.map((item) => item.productName), [
        'Ayam Bakar',
        'Nasi Goreng',
        'Es Teh',
      ]);
      expect(result.items.map((item) => item.unitPrice), [12000, 13000, 5000]);
    });

    test('truncates only extremely long transcripts with warning', () {
      final transcript = List.generate(
        101,
        (index) => 'menu${index + 1} 1 pcs ${1000 + index}',
      ).join(', ');
      final result = parser.parse('jual $transcript', context: context);

      expect(result.items, hasLength(100));
      expect(result.items.last.productName, 'Menu100');
      expect(
        result.warnings.any((warning) => warning.contains('100 item pertama')),
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
