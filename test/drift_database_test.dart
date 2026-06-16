import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/core/database/app_database.dart';
import 'package:mikiezy/data/local/mikiezy_local_data_source.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/state/app_state.dart';

void main() {
  test('drift database seeds once and keeps local changes', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final dataSource = MikiezyLocalDataSource(database);
    addTearDown(dataSource.close);

    final seedState = MikiezyState.seeded();
    final seed = _snapshotFromState(seedState);

    final firstSnapshot = await dataSource.loadOrSeed(seed);
    expect(firstSnapshot.products, isNotEmpty);
    expect(firstSnapshot.wallets, isNotEmpty);
    expect(firstSnapshot.transactions, isNotEmpty);

    await dataSource.upsertProductCategory('Frozen Food', 99);

    final restoredSnapshot = await dataSource.loadOrSeed(seed);
    expect(restoredSnapshot.productCategories, contains('Frozen Food'));
  });

  test('manual transaction is saved granularly to drift database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final dataSource = MikiezyLocalDataSource(database);
    final repository = DriftMikiezyRepository(dataSource);
    addTearDown(repository.close);

    final state = MikiezyState.seeded(repository: repository);
    await state.hydrateFromLocal();

    final transaction = await state.saveDraft(
      const TransactionDraft(
        kind: TransactionKind.sale,
        productName: 'Roti Bakar',
        quantity: 2,
        unit: SaleUnit.pcs,
        unitPrice: 12000,
        discount: 1000,
        categoryName: 'Penjualan',
        walletName: 'Dompet Utama',
        segment: PriceSegment.retail,
        note: 'Test transaksi lokal',
        rawText: 'jual roti bakar dua pcs',
      ),
    );

    final fromDatabase = await repository.loadTransactionById(transaction.id);
    expect(fromDatabase, isNotNull);
    expect(fromDatabase!.amount, 23000);
    expect(fromDatabase.lines.single.productName, 'Roti Bakar');

    final restoredState = MikiezyState.seeded(repository: repository);
    await restoredState.hydrateFromLocal();

    expect(
      restoredState.transactions.map((item) => item.id),
      contains(transaction.id),
    );
  });

  test(
    'multi-line transaction draft saves every line to drift database',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final dataSource = MikiezyLocalDataSource(database);
      final repository = DriftMikiezyRepository(dataSource);
      addTearDown(repository.close);

      final state = MikiezyState.seeded(repository: repository);
      await state.hydrateFromLocal();

      final transaction = await state.saveDraft(
        const TransactionDraft(
          kind: TransactionKind.sale,
          productName: 'Ayam Bakar',
          quantity: 10,
          unit: SaleUnit.bungkus,
          unitPrice: 12000,
          discount: 0,
          categoryName: 'Penjualan',
          walletName: 'Dompet Utama',
          segment: PriceSegment.retail,
          note: 'multi item voice',
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
        ),
      );

      expect(transaction.amount, 200000);
      expect(transaction.lines, hasLength(3));
      expect(transaction.lines.map((line) => line.productName), [
        'Ayam Bakar',
        'Nasi Goreng',
        'Es Teh',
      ]);

      final fromDatabase = await repository.loadTransactionById(transaction.id);
      expect(fromDatabase, isNotNull);
      expect(fromDatabase!.lines, hasLength(3));
      expect(fromDatabase.lines[0].unit, SaleUnit.bungkus);
      expect(fromDatabase.lines[2].unit, SaleUnit.gelas);
      expect(fromDatabase.amount, 200000);
    },
  );

  test(
    'product crud is persisted locally without breaking old transactions',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final dataSource = MikiezyLocalDataSource(database);
      final repository = DriftMikiezyRepository(dataSource);
      addTearDown(repository.close);

      final state = MikiezyState.seeded(repository: repository);
      await state.hydrateFromLocal();

      await state.addProductCategory('Frozen Food');
      final created = await state.addProduct(
        const Product(
          id: 'new',
          name: 'Sosis Ayam',
          category: 'Frozen Food',
          costPrice: 18000,
          retailPrice: 25000,
          wholesalePrice: 22000,
          packSize: 12,
          cartonSize: 48,
          stockPcs: 36,
        ),
      );

      var products = await repository.loadProducts();
      expect(products.map((product) => product.name), contains('Sosis Ayam'));

      await state.updateProduct(created.copyWith(retailPrice: 27000));
      products = await repository.loadProducts();
      expect(
        products.singleWhere((product) => product.id == created.id).retailPrice,
        27000,
      );

      final transaction = await state.saveDraft(
        TransactionDraft(
          kind: TransactionKind.sale,
          productName: created.name,
          quantity: 1,
          unit: SaleUnit.pcs,
          unitPrice: 27000,
          discount: 0,
          categoryName: 'Penjualan',
          walletName: 'Dompet Utama',
          segment: PriceSegment.retail,
          note: '',
          rawText: 'jual sosis ayam',
        ),
      );

      await state.deleteProduct(created.id);
      products = await repository.loadProducts();
      expect(
        products.map((product) => product.id),
        isNot(contains(created.id)),
      );

      final storedTransaction = await repository.loadTransactionById(
        transaction.id,
      );
      expect(storedTransaction, isNotNull);
      expect(storedTransaction!.lines.single.productName, 'Sosis Ayam');
    },
  );

  test('wallet and transaction category crud persists locally', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final dataSource = MikiezyLocalDataSource(database);
    final repository = DriftMikiezyRepository(dataSource);
    addTearDown(repository.close);

    final state = MikiezyState.seeded(repository: repository);
    await state.hydrateFromLocal();

    final wallet = await state.addWallet('Kas Event', 150000);
    final updatedWallet = await state.updateWallet(
      wallet.copyWith(name: 'Kas Bazaar', balance: 175000),
    );
    final category = await state.addCategory(
      'Penjualan bazaar',
      MoneyDirection.income,
    );
    final updatedCategory = await state.updateCategory(
      LedgerCategory(
        id: category.id,
        name: 'Penjualan event',
        direction: category.direction,
      ),
    );

    var wallets = await repository.loadWallets();
    expect(wallets.map((item) => item.name), contains('Kas Bazaar'));

    var categories = await repository.loadTransactionCategories();
    expect(categories.map((item) => item.name), contains('Penjualan event'));

    final transaction = await state.saveDraft(
      TransactionDraft(
        kind: TransactionKind.income,
        productName: '',
        quantity: 1,
        unit: SaleUnit.pcs,
        unitPrice: 99000,
        discount: 0,
        categoryName: updatedCategory.name,
        walletName: updatedWallet.name,
        segment: PriceSegment.retail,
        note: 'Pemasukan event',
        rawText: 'pemasukan event',
      ),
    );

    await state.deleteCategory(updatedCategory.id);
    await state.deleteWallet(updatedWallet.id);

    wallets = await repository.loadWallets();
    categories = await repository.loadTransactionCategories();
    expect(wallets.map((item) => item.id), isNot(contains(updatedWallet.id)));
    expect(
      categories.map((item) => item.id),
      isNot(contains(updatedCategory.id)),
    );

    final storedTransaction = await repository.loadTransactionById(
      transaction.id,
    );
    expect(storedTransaction, isNotNull);
    expect(storedTransaction!.walletName, 'Kas Bazaar');
    expect(storedTransaction.categoryName, 'Penjualan event');
  });
}

MikiezySnapshot _snapshotFromState(MikiezyState state) {
  return MikiezySnapshot(
    products: state.products,
    productCategories: state.productCategories,
    wallets: state.wallets,
    categories: state.categories,
    transactions: state.transactions,
    pinEnabled: state.pinEnabled,
    biometricEnabled: state.biometricEnabled,
    cloudSyncEnabled: state.cloudSyncEnabled,
    supabaseUrl: state.supabaseUrl,
    queuedSyncCount: state.queuedSyncCount,
    language: state.language,
    voiceSensitivity: state.voiceSensitivity,
    handsfreeWakeWordEnabled: state.handsfreeWakeWordEnabled,
    silentTimeoutSeconds: state.silentTimeoutSeconds,
    ownerName: state.ownerName,
    email: state.email,
    phone: state.phone,
    businessName: state.businessName,
    businessCategory: state.businessCategory,
    businessLocation: state.businessLocation,
    memberSince: state.memberSince,
  );
}
