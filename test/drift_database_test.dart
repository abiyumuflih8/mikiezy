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
    final tableRows = await database
        .customSelect(
          "select name from sqlite_master where type = 'table'",
          readsFrom: {
            database.voiceProductAliases,
            database.voiceUnitAliases,
            database.voiceCorrections,
          },
        )
        .get();
    final tableNames = tableRows.map((row) => row.read<String>('name'));
    expect(tableNames, contains('voice_product_aliases'));
    expect(tableNames, contains('voice_unit_aliases'));
    expect(tableNames, contains('voice_corrections'));

    await dataSource.upsertProductCategory('Frozen Food', 99);

    final restoredSnapshot = await dataSource.loadOrSeed(seed);
    expect(restoredSnapshot.productCategories, contains('Frozen Food'));
  });

  test('schema v3 database migrates to voice learning tables', () async {
    final database = AppDatabase(
      NativeDatabase.memory(setup: _createSchemaVersion3),
    );
    final dataSource = MikiezyLocalDataSource(database);
    addTearDown(dataSource.close);

    final seed = _snapshotFromState(MikiezyState.seeded());
    final snapshot = await dataSource.readSnapshot(seed);
    expect(snapshot.voiceProductAliases, isEmpty);
    expect(snapshot.voiceUnitAliases, isEmpty);
    expect(snapshot.voiceCorrections, isEmpty);

    await dataSource.recordVoiceLearning(
      productAliases: [
        VoiceProductAlias(
          id: 'vpa-demo',
          aliasText: 'aqua',
          normalizedAlias: 'aqua',
          productId: null,
          canonicalProductName: 'Air Mineral',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ],
    );

    final restored = await dataSource.readSnapshot(seed);
    expect(restored.voiceProductAliases.single.normalizedAlias, 'aqua');
  });

  test('schema v2 upgrades quantity types and stock metadata to v6', () async {
    final database = AppDatabase(
      NativeDatabase.memory(setup: _createSchemaVersion2WithProduct),
    );
    final dataSource = MikiezyLocalDataSource(database);
    addTearDown(dataSource.close);

    final products = await dataSource.readProducts();
    final product = products.single;

    expect(product.stockPcs, 7);
    expect(product.trackStock, isTrue);
    expect(product.baseUnit, SaleUnit.pcs);
    expect(product.minStock, 5);
  });

  test(
    'schema v4 migrates product stock metadata without losing data',
    () async {
      final database = AppDatabase(
        NativeDatabase.memory(setup: _createSchemaVersion4WithProducts),
      );
      final dataSource = MikiezyLocalDataSource(database);
      addTearDown(dataSource.close);

      final products = await dataSource.readProducts();
      final tracked = products.singleWhere(
        (product) => product.id == 'tracked',
      );
      final legacyZero = products.singleWhere(
        (product) => product.id == 'legacy-zero',
      );

      expect(tracked.stockPcs, 12.5);
      expect(tracked.trackStock, isTrue);
      expect(legacyZero.trackStock, isFalse);
      expect(tracked.baseUnit, SaleUnit.pcs);
      expect(tracked.minStock, 5);

      await dataSource.upsertProduct(
        tracked.copyWith(baseUnit: SaleUnit.gelas, minStock: 2.5),
      );
      final restored = await dataSource.readProducts();
      final updated = restored.singleWhere(
        (product) => product.id == 'tracked',
      );
      expect(updated.baseUnit, SaleUnit.gelas);
      expect(updated.minStock, 2.5);
    },
  );

  test(
    'schema v5 migrates unit multiplier to real and creates voice audit',
    () async {
      final database = AppDatabase(
        NativeDatabase.memory(setup: _createSchemaVersion5WithTransaction),
      );
      addTearDown(database.close);

      final line = await (database.select(
        database.transactionLines,
      )..where((row) => row.id.equals('line-v5'))).getSingle();
      expect(line.quantity, 0.5);
      expect(line.unitMultiplier, 24.0);

      final storageType = await database
          .customSelect(
            "SELECT typeof(unit_multiplier) AS storage_type "
            "FROM transaction_lines WHERE id = 'line-v5'",
          )
          .getSingle();
      expect(storageType.read<String>('storage_type'), 'real');

      await database
          .into(database.voiceActionAudits)
          .insert(
            VoiceActionAuditsCompanion.insert(
              id: 'audit-v6',
              actionId: 'action-v6',
              actionType: 'updateProductPrice',
              source: 'voice',
              status: 'previewed',
              commandFingerprint: 'redacted-fingerprint',
            ),
          );
      final audit = await database
          .select(database.voiceActionAudits)
          .getSingle();
      expect(audit.actionId, 'action-v6');
      expect(audit.status, 'previewed');
    },
  );

  test('schema v1 fresh local database upgrades directly to v6', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA user_version = 1'),
      ),
    );
    final dataSource = MikiezyLocalDataSource(database);
    addTearDown(dataSource.close);

    final snapshot = await dataSource.loadOrSeed(
      _snapshotFromState(MikiezyState.seeded()),
    );

    expect(snapshot.products, isNotEmpty);
    expect(snapshot.products.every((product) => product.minStock >= 0), isTrue);
    expect(database.schemaVersion, 6);
  });

  test('voice financial privacy settings persist locally', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final dataSource = MikiezyLocalDataSource(database);
    addTearDown(dataSource.close);
    final state = MikiezyState.seeded()
      ..toggleVoiceFinancialPrivacy(true)
      ..toggleMaskVoiceFinancialValues(true);
    final seed = _snapshotFromState(state);

    await dataSource.loadOrSeed(seed);
    final restored = await dataSource.readSnapshot(
      _snapshotFromState(MikiezyState.seeded()),
    );

    expect(restored.voiceFinancialPrivacyEnabled, isTrue);
    expect(restored.maskVoiceFinancialValues, isTrue);
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
    'voice transaction learning persists product and unit aliases',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final dataSource = MikiezyLocalDataSource(database);
      final repository = DriftMikiezyRepository(dataSource);
      addTearDown(repository.close);

      final state = MikiezyState.seeded(repository: repository);
      await state.hydrateFromLocal();

      await state.saveDraft(
        const TransactionDraft(
          kind: TransactionKind.sale,
          productName: 'Es Kopi Susu',
          quantity: 1,
          unit: SaleUnit.cup,
          unitPrice: 18000,
          discount: 0,
          categoryName: 'Penjualan',
          walletName: 'Dompet Utama',
          segment: PriceSegment.retail,
          note: 'voice learning',
          rawText: 'jual eskopsu 1 cup harga 18000',
          lines: [
            TransactionDraftLine(
              tempId: 'voice-line-1',
              productName: 'Es Kopi Susu',
              quantity: 1,
              unit: SaleUnit.cup,
              unitPrice: 18000,
              segment: PriceSegment.retail,
              note: 'jual eskopsu 1 cup harga 18000',
              warnings: ['Produk dikoreksi di preview.'],
              needsReview: true,
            ),
          ],
        ),
      );

      expect(
        state.voiceProductAliases.map((alias) => alias.normalizedAlias),
        contains('eskopsu'),
      );
      expect(
        state.voiceUnitAliases
            .where((alias) => alias.normalizedAlias == 'cup')
            .single
            .canonicalUnit,
        SaleUnit.cup.name,
      );

      final restoredState = MikiezyState.seeded(repository: repository);
      await restoredState.hydrateFromLocal();

      expect(
        restoredState.voiceProductAliases.map((alias) => alias.normalizedAlias),
        contains('eskopsu'),
      );
      expect(
        restoredState.voiceCorrections.map((item) => item.rawText),
        contains('jual eskopsu 1 cup harga 18000'),
      );

      restoredState.toggleVoiceLearning(false);
      final transaction = await restoredState.saveDraft(
        const TransactionDraft(
          kind: TransactionKind.sale,
          productName: 'Kopi Miring',
          quantity: 1,
          unit: SaleUnit.cup,
          unitPrice: 12000,
          discount: 0,
          categoryName: 'Penjualan',
          walletName: 'Dompet Utama',
          segment: PriceSegment.retail,
          note: 'voice learning disabled',
          rawText: 'jual kopmir 1 cup harga 12000',
          lines: [
            TransactionDraftLine(
              tempId: 'voice-line-1',
              productName: 'Kopi Miring',
              quantity: 1,
              unit: SaleUnit.cup,
              unitPrice: 12000,
              segment: PriceSegment.retail,
              note: 'jual kopmir 1 cup harga 12000',
              warnings: ['Produk dikoreksi di preview.'],
              needsReview: true,
            ),
          ],
        ),
      );

      expect(transaction.amount, 12000);
      expect(
        restoredState.voiceProductAliases.map((alias) => alias.normalizedAlias),
        contains('eskopsu'),
      );
      expect(
        restoredState.voiceProductAliases.map((alias) => alias.normalizedAlias),
        isNot(contains('kopmir')),
      );

      final disabledSnapshotState = MikiezyState.seeded(repository: repository);
      await disabledSnapshotState.hydrateFromLocal();

      expect(disabledSnapshotState.enableVoiceLearning, isFalse);
      expect(
        disabledSnapshotState.voiceProductAliases.map(
          (alias) => alias.normalizedAlias,
        ),
        contains('eskopsu'),
      );
      expect(
        disabledSnapshotState.voiceProductAliases.map(
          (alias) => alias.normalizedAlias,
        ),
        isNot(contains('kopmir')),
      );
    },
  );

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
    'fractional quantity transaction is persisted without rounding',
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
          productName: 'Beras',
          quantity: 0.5,
          unit: SaleUnit.kilo,
          unitPrice: 16000,
          discount: 0,
          categoryName: 'Penjualan',
          walletName: 'Dompet Utama',
          segment: PriceSegment.retail,
          note: 'jual beras setengah kilo 8000',
          rawText: 'jual beras setengah kilo 8000',
          lines: [
            TransactionDraftLine(
              tempId: 'beras-half-kilo',
              productName: 'Beras',
              quantity: 0.5,
              unit: SaleUnit.kilo,
              unitPrice: 16000,
              segment: PriceSegment.retail,
            ),
          ],
        ),
      );

      expect(transaction.amount, 8000);
      expect(transaction.lines.single.quantity, 0.5);

      final fromDatabase = await repository.loadTransactionById(transaction.id);
      expect(fromDatabase, isNotNull);
      expect(fromDatabase!.amount, 8000);
      expect(fromDatabase.lines.single.quantity, 0.5);
    },
  );

  test('sale uses product pack and carton sizes for cost and stock', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final dataSource = MikiezyLocalDataSource(database);
    final repository = DriftMikiezyRepository(dataSource);
    addTearDown(repository.close);

    final state = MikiezyState.seeded(repository: repository);
    await state.hydrateFromLocal();

    final product = await state.addProduct(
      const Product(
        id: 'new',
        name: 'Keripik Uji',
        category: 'Snack',
        costPrice: 1000,
        retailPrice: 1500,
        wholesalePrice: 12000,
        packSize: 10,
        cartonSize: 24,
        stockPcs: 100,
      ),
    );

    final packTransaction = await state.saveDraft(
      TransactionDraft(
        kind: TransactionKind.sale,
        productName: product.name,
        quantity: 2,
        unit: SaleUnit.pack,
        unitPrice: 15000,
        discount: 0,
        categoryName: 'Penjualan',
        walletName: 'Dompet Utama',
        segment: PriceSegment.retail,
        note: 'jual dua pack keripik',
        rawText: 'jual dua pack keripik',
      ),
    );

    expect(packTransaction.lines.single.unitMultiplier, 10);
    expect(packTransaction.lines.single.estimatedCost, 20000);
    expect(packTransaction.profitContribution, 10000);

    var savedProduct = (await repository.loadProducts()).singleWhere(
      (item) => item.id == product.id,
    );
    expect(savedProduct.stockPcs, 80);

    final cartonTransaction = await state.saveDraft(
      TransactionDraft(
        kind: TransactionKind.sale,
        productName: product.name,
        quantity: 1,
        unit: SaleUnit.carton,
        unitPrice: 36000,
        discount: 0,
        categoryName: 'Penjualan',
        walletName: 'Dompet Utama',
        segment: PriceSegment.retail,
        note: 'jual satu karton keripik',
        rawText: 'jual satu karton keripik',
      ),
    );

    expect(cartonTransaction.lines.single.unitMultiplier, 24);
    expect(cartonTransaction.lines.single.estimatedCost, 24000);

    savedProduct = (await repository.loadProducts()).singleWhere(
      (item) => item.id == product.id,
    );
    expect(savedProduct.stockPcs, 56);
  });

  test('sale with insufficient tracked stock is blocked safely', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final dataSource = MikiezyLocalDataSource(database);
    final repository = DriftMikiezyRepository(dataSource);
    addTearDown(repository.close);

    final state = MikiezyState.seeded(repository: repository);
    await state.hydrateFromLocal();

    final product = await state.addProduct(
      const Product(
        id: 'new',
        name: 'Stok Terbatas',
        category: 'Snack',
        costPrice: 1000,
        retailPrice: 2000,
        wholesalePrice: 1800,
        packSize: 10,
        cartonSize: 24,
        stockPcs: 5,
      ),
    );

    await expectLater(
      state.saveDraft(
        TransactionDraft(
          kind: TransactionKind.sale,
          productName: product.name,
          quantity: 1,
          unit: SaleUnit.pack,
          unitPrice: 20000,
          discount: 0,
          categoryName: 'Penjualan',
          walletName: 'Dompet Utama',
          segment: PriceSegment.retail,
          note: 'stok tidak cukup',
          rawText: 'jual satu pack stok terbatas',
        ),
      ),
      throwsException,
    );

    final savedProduct = (await repository.loadProducts()).singleWhere(
      (item) => item.id == product.id,
    );
    expect(savedProduct.stockPcs, 5);
  });

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
    voiceProductAliases: state.voiceProductAliases,
    voiceUnitAliases: state.voiceUnitAliases,
    voiceCorrections: state.voiceCorrections,
    pinEnabled: state.pinEnabled,
    biometricEnabled: state.biometricEnabled,
    cloudSyncEnabled: state.cloudSyncEnabled,
    supabaseUrl: state.supabaseUrl,
    queuedSyncCount: state.queuedSyncCount,
    language: state.language,
    voiceSensitivity: state.voiceSensitivity,
    handsfreeWakeWordEnabled: state.handsfreeWakeWordEnabled,
    silentTimeoutSeconds: state.silentTimeoutSeconds,
    enableVoiceLearning: state.enableVoiceLearning,
    voiceFinancialPrivacyEnabled: state.voiceFinancialPrivacyEnabled,
    maskVoiceFinancialValues: state.maskVoiceFinancialValues,
    ownerName: state.ownerName,
    email: state.email,
    phone: state.phone,
    businessName: state.businessName,
    businessCategory: state.businessCategory,
    businessLocation: state.businessLocation,
    memberSince: state.memberSince,
  );
}

void _createSchemaVersion3(dynamic database) {
  for (final statement in _schemaVersion3Statements) {
    database.execute(statement);
  }
  database.execute('PRAGMA user_version = 3');
}

void _createSchemaVersion2WithProduct(dynamic database) {
  for (final statement in _schemaVersion3Statements) {
    database.execute(
      statement
          .replaceFirst(
            'stock_pcs REAL NOT NULL DEFAULT 0.0',
            'stock_pcs INTEGER NOT NULL DEFAULT 0',
          )
          .replaceFirst(
            'quantity REAL NOT NULL DEFAULT 1.0',
            'quantity INTEGER NOT NULL DEFAULT 1',
          ),
    );
  }
  database.execute(
    "INSERT INTO products (id, name, stock_pcs) VALUES ('legacy-v2', 'Legacy V2', 7)",
  );
  database.execute('PRAGMA user_version = 2');
}

void _createSchemaVersion4WithProducts(dynamic database) {
  for (final statement in _schemaVersion3Statements) {
    database.execute(statement);
  }
  for (final statement in _voiceLearningSchemaStatements) {
    database.execute(statement);
  }
  database.execute(
    "INSERT INTO products (id, name, stock_pcs) VALUES ('tracked', 'Tracked', 12.5)",
  );
  database.execute(
    "INSERT INTO products (id, name, stock_pcs) VALUES ('legacy-zero', 'Legacy Zero', 0)",
  );
  database.execute('PRAGMA user_version = 4');
}

void _createSchemaVersion5WithTransaction(dynamic database) {
  for (final statement in _schemaVersion3Statements) {
    database.execute(statement);
  }
  for (final statement in _voiceLearningSchemaStatements) {
    database.execute(statement);
  }
  database.execute(
    'ALTER TABLE products ADD COLUMN track_stock INTEGER NOT NULL DEFAULT 1',
  );
  database.execute(
    "ALTER TABLE products ADD COLUMN base_unit TEXT NOT NULL DEFAULT 'pcs'",
  );
  database.execute(
    'ALTER TABLE products ADD COLUMN min_stock REAL NOT NULL DEFAULT 5.0',
  );
  database.execute(
    "INSERT INTO products (id, name, stock_pcs, track_stock, base_unit) "
    "VALUES ('product-v5', 'Produk V5', 100, 1, 'pcs')",
  );
  database.execute(
    "INSERT INTO wallets (id, name) VALUES ('wallet-v5', 'Tunai')",
  );
  database.execute(
    "INSERT INTO transaction_categories (id, name, direction) "
    "VALUES ('category-v5', 'Penjualan', 'income')",
  );
  database.execute(
    "INSERT INTO transactions ("
    "id, kind, wallet_id, wallet_name_snapshot, category_id, "
    "category_name_snapshot, occurred_at"
    ") VALUES ("
    "'transaction-v5', 'sale', 'wallet-v5', 'Tunai', 'category-v5', "
    "'Penjualan', 0"
    ")",
  );
  database.execute(
    "INSERT INTO transaction_lines ("
    "id, transaction_id, product_id, product_name_snapshot, quantity, "
    "unit, unit_price, cost_price, segment, unit_multiplier"
    ") VALUES ("
    "'line-v5', 'transaction-v5', 'product-v5', 'Produk V5', 0.5, "
    "'carton', 24000, 1000, 'retail', 24"
    ")",
  );
  database.execute('PRAGMA user_version = 5');
}

const _voiceLearningSchemaStatements = [
  '''
CREATE TABLE voice_product_aliases (
  id TEXT NOT NULL PRIMARY KEY,
  alias_text TEXT NOT NULL,
  normalized_alias TEXT NOT NULL UNIQUE,
  product_id TEXT NULL,
  canonical_product_name TEXT NOT NULL,
  hit_count INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT 0
)
''',
  '''
CREATE TABLE voice_unit_aliases (
  id TEXT NOT NULL PRIMARY KEY,
  alias_text TEXT NOT NULL,
  normalized_alias TEXT NOT NULL UNIQUE,
  canonical_unit TEXT NOT NULL,
  hit_count INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT 0
)
''',
  '''
CREATE TABLE voice_corrections (
  id TEXT NOT NULL PRIMARY KEY,
  raw_text TEXT NOT NULL,
  parsed_product_name TEXT NULL,
  corrected_product_name TEXT NOT NULL,
  parsed_unit TEXT NULL,
  corrected_unit TEXT NOT NULL,
  parsed_quantity REAL NULL,
  corrected_quantity REAL NOT NULL,
  created_at INTEGER NOT NULL DEFAULT 0
)
''',
];

const _schemaVersion3Statements = [
  '''
CREATE TABLE product_categories (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  position INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT 0,
  deleted_at INTEGER NULL,
  sync_status TEXT NOT NULL DEFAULT 'localOnly'
)
''',
  '''
CREATE TABLE products (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  category_id TEXT NULL,
  category_name_snapshot TEXT NOT NULL DEFAULT 'Lain-lain',
  cost_price INTEGER NOT NULL DEFAULT 0,
  retail_price INTEGER NOT NULL DEFAULT 0,
  wholesale_price INTEGER NOT NULL DEFAULT 0,
  pack_size INTEGER NOT NULL DEFAULT 1,
  carton_size INTEGER NOT NULL DEFAULT 1,
  stock_pcs REAL NOT NULL DEFAULT 0.0,
  created_at INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT 0,
  deleted_at INTEGER NULL,
  sync_status TEXT NOT NULL DEFAULT 'localOnly'
)
''',
  '''
CREATE TABLE wallets (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  balance INTEGER NOT NULL DEFAULT 0,
  is_primary INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT 0,
  deleted_at INTEGER NULL,
  sync_status TEXT NOT NULL DEFAULT 'localOnly'
)
''',
  '''
CREATE TABLE transaction_categories (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  direction TEXT NOT NULL,
  is_system INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT 0,
  deleted_at INTEGER NULL,
  sync_status TEXT NOT NULL DEFAULT 'localOnly'
)
''',
  '''
CREATE TABLE transactions (
  id TEXT NOT NULL PRIMARY KEY,
  kind TEXT NOT NULL,
  wallet_id TEXT NOT NULL,
  wallet_name_snapshot TEXT NOT NULL,
  category_id TEXT NULL,
  category_name_snapshot TEXT NOT NULL,
  amount INTEGER NOT NULL DEFAULT 0,
  discount INTEGER NOT NULL DEFAULT 0,
  note TEXT NOT NULL DEFAULT '',
  evidence_path TEXT NULL,
  ocr_source TEXT NULL,
  raw_voice_text TEXT NULL,
  occurred_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT 0,
  deleted_at INTEGER NULL,
  sync_status TEXT NOT NULL DEFAULT 'localOnly'
)
''',
  '''
CREATE TABLE transaction_lines (
  id TEXT NOT NULL PRIMARY KEY,
  transaction_id TEXT NOT NULL,
  product_id TEXT NULL,
  product_name_snapshot TEXT NOT NULL,
  position INTEGER NOT NULL DEFAULT 0,
  quantity REAL NOT NULL DEFAULT 1.0,
  unit TEXT NOT NULL,
  unit_price INTEGER NOT NULL DEFAULT 0,
  cost_price INTEGER NOT NULL DEFAULT 0,
  segment TEXT NOT NULL,
  unit_multiplier INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL DEFAULT 0
)
''',
  '''
CREATE TABLE business_profiles (
  id TEXT NOT NULL PRIMARY KEY,
  owner_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  business_name TEXT NOT NULL,
  business_category TEXT NOT NULL,
  business_location TEXT NOT NULL,
  member_since TEXT NOT NULL,
  created_at INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT 0
)
''',
  '''
CREATE TABLE app_settings (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL DEFAULT 0
)
''',
];
