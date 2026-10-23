import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/screens/products_screen.dart';
import 'package:mikiezy/state/app_state.dart';

void main() {
  testWidgets('product form rejects a negative minimum stock', (tester) async {
    final state = MikiezyState.seeded();
    addTearDown(state.dispose);
    final initialCount = state.products.length;
    await tester.pumpWidget(
      MikiezyScope(
        notifier: state,
        child: const MaterialApp(home: ProductsScreen()),
      ),
    );

    await tester.tap(find.byTooltip('Tambah barang'));
    await tester.pumpAndSettle();
    final minStockField = find.widgetWithText(
      TextFormField,
      'Batas stok minimum',
    );
    await tester.scrollUntilVisible(
      minStockField,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.enterText(minStockField, '-1');
    await tester.ensureVisible(find.text('Simpan barang'));
    await tester.tap(find.text('Simpan barang'));
    await tester.pump();

    expect(
      find.text('Batas stok minimum tidak boleh negatif.'),
      findsOneWidget,
    );
    expect(state.products, hasLength(initialCount));
  });

  testWidgets('manual form rejects a normalized duplicate product name', (
    tester,
  ) async {
    final state = MikiezyState.seeded();
    addTearDown(state.dispose);
    final existing = state.products.first;
    final initialCount = state.products.length;
    await tester.pumpWidget(
      MikiezyScope(
        notifier: state,
        child: const MaterialApp(home: ProductsScreen()),
      ),
    );

    await tester.tap(find.byTooltip('Tambah barang'));
    await tester.pumpAndSettle();
    final nameField = find.widgetWithText(TextFormField, 'Nama barang');
    await tester.enterText(nameField, existing.name.toLowerCase());
    await tester.ensureVisible(find.text('Simpan barang'));
    await tester.tap(find.text('Simpan barang'));
    await tester.pump();

    expect(find.textContaining('sudah ada di katalog'), findsOneWidget);
    expect(state.products, hasLength(initialCount));
  });

  testWidgets('manual form stores zero metadata when stock tracking is off', (
    tester,
  ) async {
    final state = MikiezyState.seeded();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MikiezyScope(
        notifier: state,
        child: const MaterialApp(home: ProductsScreen()),
      ),
    );

    await tester.tap(find.byTooltip('Tambah barang'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama barang'),
      'Produk Tanpa Stok Test',
    );
    final trackingSwitch = find.widgetWithText(
      SwitchListTile,
      'Lacak stok produk',
    );
    await tester.scrollUntilVisible(
      trackingSwitch,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(trackingSwitch);
    await tester.ensureVisible(find.text('Simpan barang'));
    await tester.tap(find.text('Simpan barang'));
    await tester.pumpAndSettle();

    final product = state.products.singleWhere(
      (item) => item.name == 'Produk Tanpa Stok Test',
    );
    expect(product.trackStock, isFalse);
    expect(product.stockPcs, 0);
    expect(product.minStock, 0);
  });
}
