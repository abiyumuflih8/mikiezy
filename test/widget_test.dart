import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mikiezy/main.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/screens/dashboard_screen.dart';
import 'package:mikiezy/screens/preview_transaction_screen.dart';
import 'package:mikiezy/screens/products_screen.dart';
import 'package:mikiezy/screens/reports_screen.dart';

void main() {
  testWidgets('First install flow opens onboarding and auth', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MikiezyApp(usePersistentStorage: false));

    expect(find.text('Mikiezy'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Record sales using\nyour voice'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.text('Register').first);
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('BUSINESS NAME'), findsOneWidget);

    await Scrollable.ensureVisible(
      tester.element(find.text('Create Account')),
      alignment: 0.72,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Toko Maju Jaya'), findsOneWidget);
  });

  testWidgets('Mikiezy dashboard renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MikiezyApp(
        initialHome: DashboardScreen(),
        usePersistentStorage: false,
      ),
    );

    expect(find.text('Toko Maju Jaya'), findsOneWidget);
    expect(find.text('PENJUALAN HARI INI'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('global-voice-microphone')),
      findsOneWidget,
    );
  });

  testWidgets('Global mic opens the voice overlay in place', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MikiezyApp(
        initialHome: DashboardScreen(),
        usePersistentStorage: false,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('global-voice-microphone')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Percakapan'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('Settings language toggle switches labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MikiezyApp(
        initialHome: DashboardScreen(),
        usePersistentStorage: false,
      ),
    );
    await tester.tap(find.text('Setelan'));
    await tester.pumpAndSettle();

    await Scrollable.ensureVisible(
      tester.element(find.text('English')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'English'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Transactions'), findsOneWidget);
  });

  testWidgets('Transactions tab opens sales history', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MikiezyApp(
        initialHome: DashboardScreen(),
        usePersistentStorage: false,
      ),
    );
    await tester.tap(find.text('Transaksi').first);
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Transaksi'), findsOneWidget);
    expect(find.text('Harian'), findsOneWidget);
  });

  testWidgets('Product category filter groups items', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MikiezyApp(
        initialHome: ProductsScreen(),
        usePersistentStorage: false,
      ),
    );

    expect(find.text('MAKANAN'), findsOneWidget);
    expect(find.text('MINUMAN'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Minuman'));
    await tester.pumpAndSettle();

    expect(find.text('Es Teh Manis'), findsOneWidget);
    expect(find.text('Kopi Susu Botol'), findsOneWidget);
    expect(find.text('Nasi Goreng'), findsNothing);
  });

  testWidgets('Analytics renders on compact mobile without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MikiezyApp(
        initialHome: ReportsScreen(),
        usePersistentStorage: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Mingguan'), findsOneWidget);
    expect(find.text('Bulanan'), findsOneWidget);
  });

  testWidgets('Analytics chart bars can be selected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MikiezyApp(
        initialHome: ReportsScreen(),
        usePersistentStorage: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('analytics-chart-bar-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('analytics-chart-bar-0')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('analytics-chart-selected-summary')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Preview transaction resets product from new initial draft', (
    WidgetTester tester,
  ) async {
    final firstDraft = _previewDraft('Ayam Bakar', 18000);
    final secondDraft = _previewDraft('Tumpeng', 350000);

    await tester.pumpWidget(
      MikiezyApp(
        initialHome: PreviewTransactionScreen(initialDraft: firstDraft),
        usePersistentStorage: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ayam Bakar'), findsOneWidget);

    await tester.pumpWidget(
      MikiezyApp(
        initialHome: PreviewTransactionScreen(initialDraft: secondDraft),
        usePersistentStorage: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tumpeng'), findsOneWidget);
    expect(find.text('Ayam Bakar'), findsNothing);
  });

  testWidgets('Preview transaction supports editable multi-item draft', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MikiezyApp(
        initialHome: PreviewTransactionScreen(initialDraft: _multiItemDraft()),
        usePersistentStorage: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daftar Barang'), findsOneWidget);
    expect(find.text('Ayam Bakar'), findsOneWidget);
    expect(find.text('Nasi Goreng'), findsOneWidget);
    expect(find.text('Es Teh'), findsOneWidget);
    expect(find.text('Rp 200.000'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('preview-line-toggle-nasi')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('preview-line-price-nasi')),
      '14000',
    );
    await tester.pumpAndSettle();
    expect(find.text('Rp 205.000'), findsOneWidget);

    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('preview-line-delete-nasi'))),
      alignment: 0.7,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preview-line-delete-nasi')));
    await tester.pumpAndSettle();
    expect(find.text('Nasi Goreng'), findsNothing);
    expect(find.text('Rp 135.000'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 900));
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('preview-add-line'))),
      alignment: 0.2,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preview-add-line')));
    await tester.pumpAndSettle();
    expect(find.text('Item baru'), findsOneWidget);

    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('preview-line-name-line-4'))),
      alignment: 0.45,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('preview-line-name-line-4')),
      'Kerupuk',
    );
    await tester.enterText(
      find.byKey(const ValueKey('preview-line-quantity-line-4')),
      '2',
    );
    await tester.enterText(
      find.byKey(const ValueKey('preview-line-price-line-4')),
      '2000',
    );
    await tester.pumpAndSettle();
    expect(find.text('Rp 139.000'), findsOneWidget);
  });
}

TransactionDraft _previewDraft(String productName, int unitPrice) {
  return TransactionDraft(
    kind: TransactionKind.sale,
    productName: productName,
    quantity: 1,
    unit: SaleUnit.pcs,
    unitPrice: unitPrice,
    discount: 0,
    categoryName: 'Penjualan',
    walletName: 'Dompet Utama',
    segment: PriceSegment.retail,
    note: 'voice preview test',
    rawText: 'jual $productName harga $unitPrice',
  );
}

TransactionDraft _multiItemDraft() {
  return const TransactionDraft(
    kind: TransactionKind.sale,
    productName: 'Ayam Bakar',
    quantity: 10,
    unit: SaleUnit.bungkus,
    unitPrice: 12000,
    discount: 0,
    categoryName: 'Penjualan',
    walletName: 'Dompet Utama',
    segment: PriceSegment.retail,
    note: 'multi item voice preview',
    rawText:
        'catat penjualan ayam bakar 10 bungkus Rp12.000 terus nasi goreng 5 bungkus Rp13.000 terus es teh 3 gelas Rp5.000',
    lines: [
      TransactionDraftLine(
        tempId: 'ayam',
        productName: 'Ayam Bakar',
        quantity: 10,
        unit: SaleUnit.bungkus,
        unitPrice: 12000,
        segment: PriceSegment.retail,
      ),
      TransactionDraftLine(
        tempId: 'nasi',
        productName: 'Nasi Goreng',
        quantity: 5,
        unit: SaleUnit.porsi,
        unitPrice: 13000,
        segment: PriceSegment.retail,
      ),
      TransactionDraftLine(
        tempId: 'teh',
        productName: 'Es Teh',
        quantity: 3,
        unit: SaleUnit.gelas,
        unitPrice: 5000,
        segment: PriceSegment.retail,
      ),
    ],
  );
}
