import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/parsed_transaction_item.dart';
import 'package:mikiezy/services/voice/voice_parse_context.dart';
import 'package:mikiezy/services/voice/voice_product_name_normalizer.dart';
import 'package:mikiezy/services/voice/voice_product_price_resolver.dart';
import 'package:mikiezy/services/voice/voice_product_resolver.dart';
import 'package:mikiezy/services/voice/voice_transaction_parser_v2.dart';
import 'package:mikiezy/state/app_state.dart';

void main() {
  const normalizer = VoiceProductNameNormalizer();
  const resolver = VoiceProductResolver();
  const priceResolver = VoiceProductPriceResolver();
  const parser = VoiceTransactionParserV2();

  final kopiSusu = _product(
    id: 'kopi-susu',
    name: 'Kopi Susu',
    retailPrice: 10000,
    wholesalePrice: 9000,
    packSize: 10,
    cartonSize: 40,
  );
  final airMineral = _product(
    id: 'air-mineral',
    name: 'Air Mineral',
    retailPrice: 5000,
    wholesalePrice: 4000,
    packSize: 12,
    cartonSize: 24,
  );
  final mieGoreng = _product(
    id: 'mie-goreng',
    name: 'Mie Goreng',
    retailPrice: 3000,
    wholesalePrice: 2500,
    packSize: 10,
    cartonSize: 30,
  );

  group('VoiceProductNameNormalizer', () {
    test('normalizes capitalization, spaces, punctuation, and apostrophes', () {
      expect(normalizer.normalize('  Kopi   Susu  '), 'kopi susu');
      expect(normalizer.normalize('kopi-susu'), 'kopi susu');
      expect(normalizer.normalize("kopi'susu"), 'kopi susu');
    });

    test('keeps product size information and normalizes decimal comma', () {
      expect(normalizer.normalize('Aqua 600 ML'), 'aqua 600 ml');
      expect(normalizer.normalize('Aqua 1,5 liter'), 'aqua 1.5 liter');
      expect(
        normalizer.measurementSignature('Aqua 600 ML'),
        isNot(normalizer.measurementSignature('Aqua 1,5 liter')),
      );
    });

    test('can remove a trailing sales quantity without removing size', () {
      expect(
        normalizer.normalizeSpokenName(
          'Kopi Susu 3 gelas',
          spokenUnit: 'gelas',
        ),
        'kopi susu',
      );
      expect(
        normalizer.normalizeSpokenName('Aqua 600 ml', spokenUnit: 'ml'),
        'aqua 600 ml',
      );
    });
  });

  group('VoiceProductResolver exact and alias', () {
    test('exact match ignores case, extra spaces, and punctuation', () {
      for (final spokenName in const [
        'Kopi Susu',
        'KOPI SUSU',
        '  kopi   susu ',
        'kopi-susu',
      ]) {
        final result = resolver.resolve(
          spokenName: spokenName,
          products: [kopiSusu],
        );
        expect(result.type, VoiceProductMatchType.exact);
        expect(result.product?.id, kopiSusu.id);
      }
    });

    test('resolves a valid alias case-insensitively', () {
      final result = resolver.resolve(
        spokenName: 'KOPSU',
        products: [kopiSusu],
        aliases: [_alias('kopsu', kopiSusu)],
      );

      expect(result.type, VoiceProductMatchType.alias);
      expect(result.product?.id, kopiSusu.id);
    });

    test('ignores an unrelated or missing alias', () {
      final result = resolver.resolve(
        spokenName: 'kopi aren',
        products: [kopiSusu],
        aliases: [_alias('kopsu', kopiSusu)],
      );

      expect(result.type, VoiceProductMatchType.notFound);
      expect(result.product, isNull);
    });

    test('ignores an alias whose product was deleted', () {
      final dangling = VoiceProductAlias(
        id: 'alias-deleted',
        aliasText: 'kopsu',
        normalizedAlias: 'kopsu',
        productId: 'deleted-product',
        canonicalProductName: kopiSusu.name,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final result = resolver.resolve(
        spokenName: 'kopsu',
        products: [kopiSusu],
        aliases: [dangling],
      );

      expect(result.type, VoiceProductMatchType.notFound);
      expect(result.product, isNull);
    });

    test('returns ambiguous when one alias points to multiple products', () {
      final result = resolver.resolve(
        spokenName: 'mineral',
        products: [airMineral, kopiSusu],
        aliases: [
          _alias('mineral', airMineral, id: 'alias-mineral-air'),
          _alias('mineral', kopiSusu, id: 'alias-mineral-kopi'),
        ],
      );

      expect(result.type, VoiceProductMatchType.ambiguous);
      expect(result.product, isNull);
      expect(result.candidates, hasLength(2));
    });
  });

  group('VoiceProductResolver conservative fuzzy matching', () {
    test('accepts a light typo with high confidence', () {
      final result = resolver.resolve(
        spokenName: 'kopi susuu',
        products: [kopiSusu],
      );

      expect(result.type, VoiceProductMatchType.fuzzy);
      expect(result.product?.id, kopiSusu.id);
      expect(result.confidence, greaterThanOrEqualTo(0.88));
    });

    test('does not select a low-confidence candidate', () {
      final result = resolver.resolve(
        spokenName: 'minuman naga biru',
        products: [kopiSusu, airMineral],
      );

      expect(result.type, VoiceProductMatchType.notFound);
      expect(result.product, isNull);
    });

    test('returns ambiguous for close product variants', () {
      final aqua600 = _product(id: 'aqua-600', name: 'Aqua 600 ml');
      final aquaLarge = _product(id: 'aqua-1500', name: 'Aqua 1.5 liter');

      final result = resolver.resolve(
        spokenName: 'aqua',
        products: [aqua600, aquaLarge],
      );

      expect(result.type, VoiceProductMatchType.ambiguous);
      expect(result.candidates, hasLength(2));
    });

    test('never crosses a different measurement size during fuzzy match', () {
      final aqua600 = _product(id: 'aqua-600', name: 'Aqua 600 ml');
      final aquaLarge = _product(id: 'aqua-1500', name: 'Aqua 1.5 liter');

      final result = resolver.resolve(
        spokenName: 'aquaa 600 ml',
        products: [aquaLarge, aqua600],
      );

      expect(result.type, VoiceProductMatchType.fuzzy);
      expect(result.product?.id, aqua600.id);
    });
  });

  group('VoiceProductPriceResolver', () {
    test('spoken price always wins over catalog price', () {
      final result = priceResolver.resolve(
        item: _item(quantity: 3, unit: 'gelas', unitPrice: 12000),
        productMatch: _exactMatch(kopiSusu),
      );

      expect(result.source, VoicePriceSource.spoken);
      expect(result.unitPrice, 12000);
    });

    test('uses retail catalog price when speech has no price', () {
      final result = priceResolver.resolve(
        item: _item(quantity: 3, unit: 'gelas'),
        productMatch: _exactMatch(kopiSusu),
      );

      expect(result.source, VoicePriceSource.catalogRetail);
      expect(result.unitPrice, 10000);
    });

    test('uses wholesale catalog price when requested', () {
      final result = priceResolver.resolve(
        item: _item(
          rawText: 'kopi susu 20 gelas harga grosir',
          quantity: 20,
          unit: 'gelas',
        ),
        productMatch: _exactMatch(kopiSusu),
      );

      expect(result.source, VoicePriceSource.catalogWholesale);
      expect(result.segment, PriceSegment.wholesale);
      expect(result.unitPrice, 9000);
    });

    test('pack price uses product packSize', () {
      final result = priceResolver.resolve(
        item: _item(quantity: 2, unit: 'pack'),
        productMatch: _exactMatch(kopiSusu),
      );

      expect(result.source, VoicePriceSource.catalogPack);
      expect(result.unitMultiplier, 10);
      expect(result.unitPrice, 100000);
    });

    test('carton price uses product cartonSize', () {
      final result = priceResolver.resolve(
        item: _item(quantity: 1, unit: 'karton'),
        productMatch: _exactMatch(airMineral),
      );

      expect(result.source, VoicePriceSource.catalogCarton);
      expect(result.unitMultiplier, 24);
      expect(result.unitPrice, 120000);
    });

    test('does not invent a price when catalog price is unavailable', () {
      final noPrice = _product(
        id: 'no-price',
        name: 'Produk Tanpa Harga',
        retailPrice: 0,
        wholesalePrice: 0,
      );
      final result = priceResolver.resolve(
        item: _item(quantity: 1, unit: 'pcs'),
        productMatch: _exactMatch(noPrice),
      );

      expect(result.source, VoicePriceSource.unavailable);
      expect(result.unitPrice, isNull);
    });

    test('does not invent a multiplier when pack size is invalid', () {
      final invalidPack = _product(
        id: 'invalid-pack',
        name: 'Produk Pack',
        packSize: 0,
      );
      final result = priceResolver.resolve(
        item: _item(quantity: 1, unit: 'pack'),
        productMatch: _exactMatch(invalidPack),
      );

      expect(result.source, VoicePriceSource.unavailable);
      expect(result.unitPrice, isNull);
      expect(result.unitMultiplier, 1);
    });

    test('keeps fractional quantity without changing unit price', () {
      final beras = _product(
        id: 'beras-price',
        name: 'Beras',
        retailPrice: 10000,
        baseUnit: SaleUnit.kilo,
      );
      final result = priceResolver.resolve(
        item: _item(quantity: 1.25, unit: 'kilo'),
        productMatch: _exactMatch(beras),
      );

      expect(result.unitPrice, 10000);
      expect(1.25 * result.unitPrice!, 12500);
    });
  });

  group('Voice transaction product resolution', () {
    final context = VoiceParseContext(
      products: [kopiSusu, airMineral, mieGoreng],
      defaultWalletName: 'Tunai',
      defaultCategoryName: 'Penjualan',
    );

    test('fills catalog price for a sale without spoken price', () {
      final result = parser.parse('jual kopi susu 3 gelas', context: context);

      expect(result.items, hasLength(1));
      expect(result.items.single.matchedProductId, kopiSusu.id);
      expect(result.items.single.unitPrice, 10000);
      expect(
        result.draft?.lines.single.priceSource,
        TransactionDraftPriceSource.catalogRetail,
      );
      expect(result.draft?.amount, 30000);
    });

    test('resolves multiple catalog items without prices or separators', () {
      final result = parser.parse(
        'jual kopi susu 2 gelas air mineral 3 botol mie goreng 2 bungkus',
        context: context,
      );

      expect(result.items, hasLength(3));
      expect(result.items.map((item) => item.matchedProductId), [
        kopiSusu.id,
        airMineral.id,
        mieGoreng.id,
      ]);
      expect(result.items.map((item) => item.unitPrice), [10000, 5000, 3000]);
      expect(result.draft?.amount, 41000);
    });

    test('applies an explicit price only to its own item', () {
      final result = parser.parse(
        'jual kopi susu 2 gelas air mineral 3 botol harga 6000',
        context: context,
      );

      expect(result.items, hasLength(2));
      expect(result.items[0].unitPrice, 10000);
      expect(result.items[1].unitPrice, 6000);
      expect(result.draft?.lines.map((line) => line.priceSource), [
        TransactionDraftPriceSource.catalogRetail,
        TransactionDraftPriceSource.spoken,
      ]);
    });

    test('keeps one unknown item instead of dropping it', () {
      final result = parser.parse(
        'jual kopi susu 2 gelas terus minuman naga biru 1 botol',
        context: context,
      );

      expect(result.items, hasLength(2));
      expect(result.items[0].unitPrice, 10000);
      expect(result.items[1].productName, 'Minuman Naga Biru');
      expect(result.items[1].unitPrice, isNull);
      expect(
        result.draft?.lines[1].productStatus,
        TransactionDraftProductStatus.notFound,
      );
    });

    test('keeps ambiguous candidates and does not choose one', () {
      final aquaContext = VoiceParseContext(
        products: [
          _product(id: 'aqua-600', name: 'Aqua 600 ml'),
          _product(id: 'aqua-1500', name: 'Aqua 1.5 liter'),
        ],
        defaultWalletName: 'Tunai',
        defaultCategoryName: 'Penjualan',
      );
      final result = parser.parse('jual aqua 2 botol', context: aquaContext);

      expect(result.items.single.matchedProductId, isNull);
      expect(result.items.single.unitPrice, isNull);
      expect(
        result.draft?.lines.single.productStatus,
        TransactionDraftProductStatus.ambiguous,
      );
      expect(result.draft?.lines.single.productCandidates, hasLength(2));
    });

    test('keeps an unknown explicitly-priced item as ad-hoc', () {
      final result = parser.parse(
        'jual minuman naga biru 2 gelas harga 15000',
        context: context,
      );

      expect(result.items.single.matchedProductId, isNull);
      expect(result.items.single.unitPrice, 15000);
      expect(
        result.draft?.lines.single.productStatus,
        TransactionDraftProductStatus.adHoc,
      );
      expect(result.draft?.amount, 30000);
    });

    test('uses packSize and cartonSize in parser integration', () {
      final pack = parser.parse('jual kopi susu 2 pack', context: context);
      final carton = parser.parse(
        'jual air mineral 1 karton',
        context: context,
      );

      expect(pack.draft?.lines.single.unitPrice, 100000);
      expect(pack.draft?.amount, 200000);
      expect(carton.draft?.lines.single.unitPrice, 120000);
      expect(carton.draft?.amount, 120000);
    });

    test('supports fractional quantity with catalog price', () {
      final beras = _product(
        id: 'beras',
        name: 'Beras',
        retailPrice: 16000,
        baseUnit: SaleUnit.kilo,
      );
      final result = parser.parse(
        'jual beras setengah kilo',
        context: VoiceParseContext(
          products: [beras],
          defaultWalletName: 'Tunai',
          defaultCategoryName: 'Penjualan',
        ),
      );

      expect(result.items.single.quantity, 0.5);
      expect(result.items.single.unitPrice, 16000);
      expect(result.draft?.amount, 8000);
    });

    test('keeps more than 30 independently resolved items', () {
      final products = List.generate(35, (index) {
        return _product(
          id: 'bulk-$index',
          name: 'Barang ${_alphaLabel(index)}',
          retailPrice: 1000 + index,
        );
      });
      final transcript = products
          .map((product) => '${product.name} 1 pcs')
          .join(' terus ');
      final result = parser.parse(
        'jual $transcript',
        context: VoiceParseContext(
          products: products,
          defaultWalletName: 'Tunai',
          defaultCategoryName: 'Penjualan',
        ),
      );

      expect(result.items, hasLength(35));
      final unavailable = result.items
          .where((item) => item.unitPrice == null)
          .map((item) => '${item.productName}: ${item.warnings}')
          .toList();
      expect(
        result.items.every((item) => item.unitPrice != null),
        isTrue,
        reason: unavailable.join('\n'),
      );
      expect(result.draft?.lines, hasLength(35));
    });
  });

  test('saving an ad-hoc item does not add or change catalog stock', () async {
    final catalogProduct = _product(
      id: 'catalog-product',
      name: 'Produk Katalog',
      stockPcs: 20,
    );
    final state = MikiezyState(
      products: [catalogProduct],
      productCategories: const ['Umum'],
      wallets: const [
        Wallet(id: 'cash', name: 'Tunai', balance: 0, isPrimary: true),
      ],
      categories: const [
        LedgerCategory(
          id: 'sale',
          name: 'Penjualan',
          direction: MoneyDirection.income,
        ),
      ],
      transactions: const [],
    );
    final draft = TransactionDraft(
      kind: TransactionKind.sale,
      productName: 'Minuman Naga Biru',
      quantity: 2,
      unit: SaleUnit.gelas,
      unitPrice: 15000,
      discount: 0,
      categoryName: 'Penjualan',
      walletName: 'Tunai',
      segment: PriceSegment.retail,
      note: '',
      rawText: 'jual minuman naga biru 2 gelas harga 15000',
      lines: const [
        TransactionDraftLine(
          tempId: 'ad-hoc',
          productName: 'Minuman Naga Biru',
          quantity: 2,
          unit: SaleUnit.gelas,
          unitPrice: 15000,
          segment: PriceSegment.retail,
          priceSource: TransactionDraftPriceSource.spoken,
          productStatus: TransactionDraftProductStatus.adHoc,
        ),
      ],
    );

    final transaction = await state.saveDraft(draft);

    expect(state.products, hasLength(1));
    expect(state.products.single.id, catalogProduct.id);
    expect(state.products.single.stockPcs, 20);
    expect(transaction.lines.single.productId, isEmpty);
    expect(transaction.lines.single.costPrice, 0);

    final sameNameLine = draft.lines.single.copyWith(
      productName: catalogProduct.name,
    );
    final sameNameTransaction = await state.saveDraft(
      draft.copyWith(productName: catalogProduct.name, lines: [sameNameLine]),
    );
    expect(state.products.single.stockPcs, 20);
    expect(sameNameTransaction.lines.single.productId, isEmpty);
    state.dispose();
  });

  test('domain save guard rejects an ambiguous draft', () async {
    final state = MikiezyState(
      products: const [],
      productCategories: const [],
      wallets: const [
        Wallet(id: 'cash', name: 'Tunai', balance: 0, isPrimary: true),
      ],
      categories: const [
        LedgerCategory(
          id: 'sale',
          name: 'Penjualan',
          direction: MoneyDirection.income,
        ),
      ],
      transactions: const [],
    );
    final draft = TransactionDraft(
      kind: TransactionKind.sale,
      productName: 'Aqua',
      quantity: 2,
      unit: SaleUnit.botol,
      unitPrice: 5000,
      discount: 0,
      categoryName: 'Penjualan',
      walletName: 'Tunai',
      segment: PriceSegment.retail,
      note: '',
      rawText: 'jual aqua 2 botol',
      lines: const [
        TransactionDraftLine(
          tempId: 'ambiguous',
          productName: 'Aqua',
          quantity: 2,
          unit: SaleUnit.botol,
          unitPrice: 5000,
          segment: PriceSegment.retail,
          productStatus: TransactionDraftProductStatus.ambiguous,
          productCandidates: ['Aqua 600 ml', 'Aqua 1.5 liter'],
        ),
      ],
    );

    await expectLater(state.saveDraft(draft), throwsStateError);
    expect(state.transactions, isEmpty);
    state.dispose();
  });
}

Product _product({
  required String id,
  required String name,
  int retailPrice = 5000,
  int wholesalePrice = 4500,
  int packSize = 12,
  int cartonSize = 48,
  double stockPcs = 1000,
  SaleUnit baseUnit = SaleUnit.pcs,
}) {
  return Product(
    id: id,
    name: name,
    category: 'Umum',
    costPrice: 2000,
    retailPrice: retailPrice,
    wholesalePrice: wholesalePrice,
    packSize: packSize,
    cartonSize: cartonSize,
    stockPcs: stockPcs,
    baseUnit: baseUnit,
  );
}

VoiceProductAlias _alias(String aliasText, Product product, {String? id}) {
  return VoiceProductAlias(
    id: id ?? 'alias-${product.id}',
    aliasText: aliasText,
    normalizedAlias: aliasText.toLowerCase(),
    productId: product.id,
    canonicalProductName: product.name,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

ParsedTransactionItem _item({
  String rawText = 'kopi susu',
  double quantity = 1,
  String unit = 'pcs',
  int? unitPrice,
  int? lineTotal,
}) {
  return ParsedTransactionItem(
    rawText: rawText,
    productName: 'Kopi Susu',
    quantity: quantity,
    unit: unit,
    unitPrice: unitPrice,
    lineTotal: lineTotal,
  );
}

VoiceProductMatchResult _exactMatch(Product product) {
  return VoiceProductMatchResult(
    type: VoiceProductMatchType.exact,
    product: product,
    candidates: [VoiceProductCandidate(product: product, confidence: 1)],
    confidence: 1,
    spokenName: product.name,
    normalizedName: product.name.toLowerCase(),
  );
}

String _alphaLabel(int index) {
  var value = index;
  final output = StringBuffer();
  do {
    output.writeCharCode(97 + (value % 26));
    value = (value ~/ 26) - 1;
  } while (value >= 0);
  return output.toString();
}
