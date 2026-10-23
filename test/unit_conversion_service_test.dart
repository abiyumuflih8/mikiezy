import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/core/formatters.dart';
import 'package:mikiezy/domain/models/product_unit.dart';
import 'package:mikiezy/domain/services/product_stock_service.dart';
import 'package:mikiezy/domain/services/quantity_formatter.dart';
import 'package:mikiezy/domain/services/unit_conversion_service.dart';
import 'package:mikiezy/domain/services/unit_normalizer.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/state/app_state.dart';

void main() {
  const converter = UnitConversionService();
  const normalizer = UnitNormalizer();

  group('unit normalization', () {
    test('recognizes canonical Indonesian aliases', () {
      expect(normalizer.normalize('kg').unit, SaleUnit.kilo);
      expect(normalizer.normalize('gr').unit, SaleUnit.gram);
      expect(normalizer.normalize('mili').unit, SaleUnit.ml);
      expect(normalizer.normalize('dus').unit, SaleUnit.carton);
      expect(normalizer.normalize('sentimeter').unit, SaleUnit.centimeter);
    });

    test('learned alias has priority over the built-in dictionary', () {
      final result = normalizer.normalize(
        'bks',
        learnedAliases: [
          VoiceUnitAlias(
            id: 'alias-1',
            aliasText: 'bks',
            normalizedAlias: 'bks',
            canonicalUnit: 'pack',
            hitCount: 4,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ],
      );

      expect(result.unit, SaleUnit.pack);
      expect(result.matchedAlias, 'bks');
    });

    test('unknown unit stays explicit', () {
      final result = normalizer.normalize('karung-besar');

      expect(result.status, UnitNormalizationStatus.unknown);
      expect(result.unit, isNull);
    });
  });

  group('unit conversion', () {
    test('converts weight in both directions', () {
      expect(_value(converter, 1, SaleUnit.kilo, SaleUnit.gram), 1000);
      expect(_value(converter, 250, SaleUnit.gram, SaleUnit.kilo), 0.25);
      expect(_value(converter, 1, SaleUnit.ons, SaleUnit.gram), 100);
      expect(_value(converter, 0.5, SaleUnit.kilo, SaleUnit.gram), 500);
    });

    test('converts volume in both directions', () {
      expect(_value(converter, 1, SaleUnit.liter, SaleUnit.ml), 1000);
      expect(_value(converter, 250, SaleUnit.ml, SaleUnit.liter), 0.25);
      expect(_value(converter, 1.25, SaleUnit.liter, SaleUnit.ml), 1250);
    });

    test('converts length without crossing dimensions', () {
      expect(_value(converter, 1, SaleUnit.meter, SaleUnit.centimeter), 100);

      final invalid = converter.convert(
        quantity: 1,
        from: SaleUnit.botol,
        to: SaleUnit.kilo,
      );
      expect(invalid.status, UnitConversionStatus.incompatibleDimension);
    });

    test('uses product metadata for pack and carton', () {
      final product = _product(packSize: 10, cartonSize: 24);

      expect(
        converter
            .convert(
              quantity: 2,
              from: SaleUnit.pack,
              to: SaleUnit.pcs,
              product: product,
            )
            .quantity!
            .baseQuantity,
        20,
      );
      expect(
        converter
            .convert(
              quantity: 1.5,
              from: SaleUnit.carton,
              to: SaleUnit.pcs,
              product: product,
            )
            .quantity!
            .baseQuantity,
        36,
      );
    });

    test('blocks pack and carton when their metadata is invalid', () {
      final product = _product(packSize: 0, cartonSize: 0);

      expect(
        converter
            .convert(
              quantity: 1,
              from: SaleUnit.pack,
              to: SaleUnit.pcs,
              product: product,
            )
            .status,
        UnitConversionStatus.packagingSizeMissing,
      );
      expect(
        converter
            .convert(
              quantity: 1,
              from: SaleUnit.carton,
              to: SaleUnit.pcs,
              product: product,
            )
            .status,
        UnitConversionStatus.packagingSizeMissing,
      );
    });

    test('normalizes floating-point artifacts', () {
      final result = converter.convert(
        quantity: 0.1 + 0.2,
        from: SaleUnit.kilo,
        to: SaleUnit.gram,
      );

      expect(result.quantity!.baseQuantity, 300);
      expect(QuantityFormatter.label(499.9999999997), '500');
    });

    test('accepts Indonesian decimal comma from form input', () {
      final controller = TextEditingController(text: '2,75');
      addTearDown(controller.dispose);

      expect(quantityFromController(controller), 2.75);
    });
  });

  group('stock integration', () {
    const stockService = ProductStockService();

    test('reduces gram stock from a fractional kilogram sale', () {
      final product = _product(
        stock: 1000,
        baseUnit: SaleUnit.gram,
        trackStock: true,
      );
      final multiplier = stockService.unitMultiplierFor(product, SaleUnit.kilo);
      final updates = stockService.applySaleStockChanges(
        lines: [
          _line(quantity: 0.5, unit: SaleUnit.kilo, multiplier: multiplier),
        ],
        productsById: {product.id: product},
      );

      expect(updates.single.stockPcs, 500);
    });

    test('blocks insufficient stock after conversion', () {
      final product = _product(
        stock: 400,
        baseUnit: SaleUnit.gram,
        trackStock: true,
      );
      final multiplier = stockService.unitMultiplierFor(product, SaleUnit.kilo);

      expect(
        () => stockService.applySaleStockChanges(
          lines: [
            _line(quantity: 0.5, unit: SaleUnit.kilo, multiplier: multiplier),
          ],
          productsById: {product.id: product},
        ),
        throwsA(isA<StockNotEnoughException>()),
      );
    });

    test('does not block or reduce an untracked product', () {
      final product = _product(
        stock: 0,
        baseUnit: SaleUnit.ml,
        trackStock: false,
      );
      final updates = stockService.applySaleStockChanges(
        lines: [_line(quantity: 2, unit: SaleUnit.liter, multiplier: 1000)],
        productsById: {product.id: product},
      );

      expect(updates, isEmpty);
    });

    test(
      'saveDraft converts weight and volume to each product base unit',
      () async {
        final rice = _product(
          id: 'rice',
          name: 'Beras',
          stock: 10000,
          baseUnit: SaleUnit.gram,
        );
        final syrup = _product(
          id: 'syrup',
          name: 'Sirup',
          stock: 5000,
          baseUnit: SaleUnit.ml,
        );
        final state = _stateWithProducts([rice, syrup]);
        addTearDown(state.dispose);

        final transaction = await state.saveDraft(
          TransactionDraft(
            kind: TransactionKind.sale,
            productName: 'Beras',
            quantity: 0.5,
            unit: SaleUnit.kilo,
            unitPrice: 16000,
            discount: 0,
            categoryName: 'Penjualan',
            walletName: 'Tunai',
            segment: PriceSegment.retail,
            note: '',
            rawText: 'jual beras setengah kilo dan sirup satu setengah liter',
            lines: const [
              TransactionDraftLine(
                tempId: 'rice-line',
                productId: 'rice',
                productName: 'Beras',
                quantity: 0.5,
                unit: SaleUnit.kilo,
                unitPrice: 16000,
                segment: PriceSegment.retail,
                productStatus: TransactionDraftProductStatus.matched,
              ),
              TransactionDraftLine(
                tempId: 'syrup-line',
                productId: 'syrup',
                productName: 'Sirup',
                quantity: 1.5,
                unit: SaleUnit.liter,
                unitPrice: 10000,
                segment: PriceSegment.retail,
                productStatus: TransactionDraftProductStatus.matched,
              ),
            ],
          ),
        );

        expect(transaction.amount, 23000);
        expect(transaction.lines[0].unitMultiplier, 1000);
        expect(transaction.lines[1].unitMultiplier, 1000);
        expect(
          state.products.singleWhere((item) => item.id == 'rice').stockPcs,
          9500,
        );
        expect(
          state.products.singleWhere((item) => item.id == 'syrup').stockPcs,
          3500,
        );
      },
    );

    test(
      'saveDraft rejects an incompatible unit without changing stock',
      () async {
        final bottledDrink = _product(
          id: 'drink',
          name: 'Minuman Botol',
          stock: 10,
          baseUnit: SaleUnit.botol,
        );
        final state = _stateWithProducts([bottledDrink]);
        addTearDown(state.dispose);

        final draft = TransactionDraft(
          kind: TransactionKind.sale,
          productName: 'Minuman Botol',
          quantity: 1,
          unit: SaleUnit.kilo,
          unitPrice: 10000,
          discount: 0,
          categoryName: 'Penjualan',
          walletName: 'Tunai',
          segment: PriceSegment.retail,
          note: '',
          rawText: 'jual minuman botol satu kilo',
          lines: const [
            TransactionDraftLine(
              tempId: 'drink-line',
              productId: 'drink',
              productName: 'Minuman Botol',
              quantity: 1,
              unit: SaleUnit.kilo,
              unitPrice: 10000,
              segment: PriceSegment.retail,
              productStatus: TransactionDraftProductStatus.matched,
            ),
          ],
        );

        await expectLater(
          state.saveDraft(draft),
          throwsA(isA<UnitConversionException>()),
        );
        expect(state.products.single.stockPcs, 10);
        expect(state.transactions, isEmpty);
      },
    );
  });
}

double _value(
  UnitConversionService converter,
  double quantity,
  SaleUnit from,
  SaleUnit to,
) {
  return converter
      .convert(quantity: quantity, from: from, to: to)
      .quantity!
      .baseQuantity;
}

Product _product({
  String id = 'product-1',
  String name = 'Produk Test',
  int packSize = 10,
  int cartonSize = 24,
  double stock = 100,
  bool trackStock = true,
  SaleUnit baseUnit = SaleUnit.pcs,
}) {
  return Product(
    id: id,
    name: name,
    category: 'Test',
    costPrice: 1000,
    retailPrice: 1500,
    wholesalePrice: 1200,
    packSize: packSize,
    cartonSize: cartonSize,
    stockPcs: stock,
    trackStock: trackStock,
    baseUnit: baseUnit,
  );
}

MikiezyState _stateWithProducts(List<Product> products) {
  return MikiezyState(
    products: products,
    productCategories: const ['Test'],
    wallets: const [
      Wallet(id: 'wallet', name: 'Tunai', balance: 0, isPrimary: true),
    ],
    categories: const [
      LedgerCategory(
        id: 'sale-category',
        name: 'Penjualan',
        direction: MoneyDirection.income,
      ),
    ],
    transactions: const [],
  );
}

TransactionLine _line({
  required double quantity,
  required SaleUnit unit,
  required double multiplier,
}) {
  return TransactionLine(
    productId: 'product-1',
    productName: 'Produk Test',
    quantity: quantity,
    unit: unit,
    unitPrice: 1000,
    costPrice: 500,
    segment: PriceSegment.retail,
    unitMultiplier: multiplier,
  );
}
