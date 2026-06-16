import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_seed_service.dart';
import '../../models/mikiezy_models.dart';
import 'mikiezy_snapshot.dart';

class MikiezyLocalDataSource {
  MikiezyLocalDataSource(this._database)
    : _seedService = DatabaseSeedService(_database);

  final AppDatabase _database;
  final DatabaseSeedService _seedService;

  Future<MikiezySnapshot> loadOrSeed(MikiezySnapshot seed) async {
    await _seedService.seedIfEmpty(() => replaceSnapshot(seed));
    return readSnapshot(seed);
  }

  Future<MikiezySnapshot> readSnapshot(MikiezySnapshot fallback) async {
    final productCategoryRows = await _readProductCategoryRows();
    final productRows = await _readProductRows();
    final walletRows = await _readWalletRows();
    final categoryRows = await _readTransactionCategoryRows();
    final transactions = await readTransactions();
    final profile = await _database
        .select(_database.businessProfiles)
        .getSingleOrNull();
    final settingRows = await _database.select(_database.appSettings).get();

    final settings = {for (final row in settingRows) row.key: row.value};

    return MikiezySnapshot(
      products: productRows.map(_productFromRow).toList(),
      productCategories: productCategoryRows.map((row) => row.name).toList(),
      wallets: walletRows.map(_walletFromRow).toList(),
      categories: categoryRows.map(_categoryFromRow).toList(),
      transactions: transactions,
      pinEnabled: _boolSetting(
        settings,
        _SettingKey.pinEnabled,
        fallback.pinEnabled,
      ),
      biometricEnabled: _boolSetting(
        settings,
        _SettingKey.biometricEnabled,
        fallback.biometricEnabled,
      ),
      cloudSyncEnabled: _boolSetting(
        settings,
        _SettingKey.cloudSyncEnabled,
        fallback.cloudSyncEnabled,
      ),
      supabaseUrl: settings[_SettingKey.supabaseUrl] ?? fallback.supabaseUrl,
      queuedSyncCount: _intSetting(
        settings,
        _SettingKey.queuedSyncCount,
        fallback.queuedSyncCount,
      ),
      language: _enumByName(
        AppLanguage.values,
        settings[_SettingKey.language],
        fallback.language,
      ),
      voiceSensitivity: _intSetting(
        settings,
        _SettingKey.voiceSensitivity,
        fallback.voiceSensitivity,
      ),
      handsfreeWakeWordEnabled: _boolSetting(
        settings,
        _SettingKey.handsfreeWakeWordEnabled,
        fallback.handsfreeWakeWordEnabled,
      ),
      silentTimeoutSeconds: _intSetting(
        settings,
        _SettingKey.silentTimeoutSeconds,
        fallback.silentTimeoutSeconds,
      ),
      ownerName: profile?.ownerName ?? fallback.ownerName,
      email: profile?.email ?? fallback.email,
      phone: profile?.phone ?? fallback.phone,
      businessName: profile?.businessName ?? fallback.businessName,
      businessCategory: profile?.businessCategory ?? fallback.businessCategory,
      businessLocation: profile?.businessLocation ?? fallback.businessLocation,
      memberSince: profile?.memberSince ?? fallback.memberSince,
    );
  }

  Future<List<Product>> readProducts() async {
    final rows = await _readProductRows();
    return rows.map(_productFromRow).toList();
  }

  Future<List<String>> readProductCategories() async {
    final rows = await _readProductCategoryRows();
    return rows.map((row) => row.name).toList();
  }

  Future<List<Wallet>> readWallets() async {
    final rows = await _readWalletRows();
    return rows.map(_walletFromRow).toList();
  }

  Future<List<LedgerCategory>> readTransactionCategories() async {
    final rows = await _readTransactionCategoryRows();
    return rows.map(_categoryFromRow).toList();
  }

  Future<List<TransactionRecord>> readTransactions() async {
    final rows =
        await (_database.select(_database.transactions)
              ..where((table) => table.deletedAt.isNull())
              ..orderBy([(table) => OrderingTerm.desc(table.occurredAt)]))
            .get();
    final linesByTransaction = await _readLinesByTransaction();
    return rows
        .map(
          (row) => _transactionFromRow(row, linesByTransaction[row.id] ?? []),
        )
        .toList();
  }

  Future<TransactionRecord?> readTransactionById(String id) async {
    final row =
        await (_database.select(_database.transactions)
              ..where((table) => table.id.equals(id) & table.deletedAt.isNull())
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;

    final lines =
        await (_database.select(_database.transactionLines)
              ..where((line) => line.transactionId.equals(id))
              ..orderBy([(line) => OrderingTerm.asc(line.position)]))
            .get();
    return _transactionFromRow(row, lines.map(_lineFromRow).toList());
  }

  Future<void> replaceSnapshot(MikiezySnapshot snapshot) async {
    final now = DateTime.now();
    final productCategories = _mergedProductCategories(snapshot);

    await _database.transaction(() async {
      await _database.delete(_database.transactionLines).go();
      await _database.delete(_database.transactions).go();
      await _database.delete(_database.products).go();
      await _database.delete(_database.productCategories).go();
      await _database.delete(_database.wallets).go();
      await _database.delete(_database.transactionCategories).go();
      await _database.delete(_database.businessProfiles).go();
      await _database.delete(_database.appSettings).go();

      await _database.batch((batch) {
        batch.insertAll(_database.productCategories, [
          for (var index = 0; index < productCategories.length; index++)
            ProductCategoriesCompanion.insert(
              id: _productCategoryId(productCategories[index]),
              name: productCategories[index],
              position: Value(index),
              updatedAt: Value(now),
              syncStatus: const Value('localOnly'),
            ),
        ]);
        batch.insertAll(
          _database.products,
          snapshot.products.map((product) => _productToCompanion(product, now)),
        );
        batch.insertAll(
          _database.wallets,
          snapshot.wallets.map((wallet) => _walletToCompanion(wallet, now)),
        );
        batch.insertAll(
          _database.transactionCategories,
          snapshot.categories.map(
            (category) => _transactionCategoryToCompanion(category, now),
          ),
        );
        batch.insertAll(
          _database.transactions,
          snapshot.transactions.map(
            (transaction) => _transactionToCompanion(transaction, now),
          ),
        );
        batch.insertAll(_database.transactionLines, [
          for (final transaction in snapshot.transactions)
            for (var index = 0; index < transaction.lines.length; index++)
              _lineToCompanion(transaction.id, transaction.lines[index], index),
        ]);
        batch.insert(
          _database.businessProfiles,
          _businessProfileToCompanion(snapshot, now),
        );
        batch.insertAll(_database.appSettings, _settingsToCompanions(snapshot));
      });
    });
  }

  Future<void> upsertProduct(Product product) {
    return _database
        .into(_database.products)
        .insertOnConflictUpdate(_productToCompanion(product, DateTime.now()));
  }

  Future<void> softDeleteProduct(String id) async {
    await (_database.update(
      _database.products,
    )..where((table) => table.id.equals(id) & table.deletedAt.isNull())).write(
      ProductsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('queued'),
      ),
    );
  }

  Future<void> upsertProductCategory(String name, int position) {
    final cleaned = _cleanName(name, fallback: 'Lain-lain');
    final now = DateTime.now();
    return _database
        .into(_database.productCategories)
        .insertOnConflictUpdate(
          ProductCategoriesCompanion.insert(
            id: _productCategoryId(cleaned),
            name: cleaned,
            position: Value(position),
            updatedAt: Value(now),
            syncStatus: const Value('queued'),
          ),
        );
  }

  Future<void> upsertWallet(Wallet wallet) {
    return _database
        .into(_database.wallets)
        .insertOnConflictUpdate(_walletToCompanion(wallet, DateTime.now()));
  }

  Future<void> softDeleteWallet(String id) async {
    await (_database.update(
      _database.wallets,
    )..where((table) => table.id.equals(id) & table.deletedAt.isNull())).write(
      WalletsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('queued'),
      ),
    );
  }

  Future<void> upsertTransactionCategory(LedgerCategory category) {
    return _database
        .into(_database.transactionCategories)
        .insertOnConflictUpdate(
          _transactionCategoryToCompanion(category, DateTime.now()),
        );
  }

  Future<void> softDeleteTransactionCategory(String id) async {
    await (_database.update(
      _database.transactionCategories,
    )..where((table) => table.id.equals(id) & table.deletedAt.isNull())).write(
      TransactionCategoriesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('queued'),
      ),
    );
  }

  Future<void> upsertTransaction(TransactionRecord transaction) async {
    final now = DateTime.now();
    await _database.transaction(() async {
      await _database
          .into(_database.transactions)
          .insertOnConflictUpdate(_transactionToCompanion(transaction, now));
      await (_database.delete(
        _database.transactionLines,
      )..where((line) => line.transactionId.equals(transaction.id))).go();
      await _database.batch((batch) {
        batch.insertAll(_database.transactionLines, [
          for (var index = 0; index < transaction.lines.length; index++)
            _lineToCompanion(transaction.id, transaction.lines[index], index),
        ]);
      });
    });
  }

  Future<void> close() {
    return _database.close();
  }

  Future<List<ProductCategoryRow>> _readProductCategoryRows() {
    return (_database.select(_database.productCategories)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([
            (table) => OrderingTerm.asc(table.position),
            (table) => OrderingTerm.asc(table.name),
          ]))
        .get();
  }

  Future<List<ProductRow>> _readProductRows() {
    return (_database.select(_database.products)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .get();
  }

  Future<List<WalletRow>> _readWalletRows() {
    return (_database.select(_database.wallets)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([
            (table) => OrderingTerm.desc(table.isPrimary),
            (table) => OrderingTerm.asc(table.name),
          ]))
        .get();
  }

  Future<List<TransactionCategoryRow>> _readTransactionCategoryRows() {
    return (_database.select(_database.transactionCategories)
          ..where((table) => table.deletedAt.isNull())
          ..orderBy([
            (table) => OrderingTerm.asc(table.direction),
            (table) => OrderingTerm.asc(table.name),
          ]))
        .get();
  }

  Future<Map<String, List<TransactionLine>>> _readLinesByTransaction() async {
    final rows =
        await (_database.select(_database.transactionLines)..orderBy([
              (table) => OrderingTerm.asc(table.transactionId),
              (table) => OrderingTerm.asc(table.position),
            ]))
            .get();
    final linesByTransaction = <String, List<TransactionLine>>{};
    for (final row in rows) {
      linesByTransaction
          .putIfAbsent(row.transactionId, () => [])
          .add(_lineFromRow(row));
    }
    return linesByTransaction;
  }

  ProductsCompanion _productToCompanion(Product product, DateTime now) {
    final categoryName = _cleanName(product.category, fallback: 'Lain-lain');
    return ProductsCompanion.insert(
      id: product.id,
      name: product.name,
      categoryId: Value(_productCategoryId(categoryName)),
      categoryNameSnapshot: Value(categoryName),
      costPrice: Value(product.costPrice),
      retailPrice: Value(product.retailPrice),
      wholesalePrice: Value(product.wholesalePrice),
      packSize: Value(product.packSize),
      cartonSize: Value(product.cartonSize),
      stockPcs: Value(product.stockPcs),
      updatedAt: Value(now),
      syncStatus: const Value('localOnly'),
    );
  }

  WalletsCompanion _walletToCompanion(Wallet wallet, DateTime now) {
    return WalletsCompanion.insert(
      id: wallet.id,
      name: wallet.name,
      balance: Value(wallet.balance),
      isPrimary: Value(wallet.isPrimary),
      updatedAt: Value(now),
      syncStatus: const Value('localOnly'),
    );
  }

  TransactionCategoriesCompanion _transactionCategoryToCompanion(
    LedgerCategory category,
    DateTime now,
  ) {
    return TransactionCategoriesCompanion.insert(
      id: category.id,
      name: category.name,
      direction: category.direction.name,
      isSystem: Value(category.isSystem),
      updatedAt: Value(now),
      syncStatus: const Value('localOnly'),
    );
  }

  TransactionsCompanion _transactionToCompanion(
    TransactionRecord transaction,
    DateTime now,
  ) {
    return TransactionsCompanion.insert(
      id: transaction.id,
      kind: transaction.kind.name,
      walletId: transaction.walletId,
      walletNameSnapshot: transaction.walletName,
      categoryId: Value(transaction.categoryId),
      categoryNameSnapshot: transaction.categoryName,
      amount: Value(transaction.amount),
      discount: Value(transaction.discount),
      note: Value(transaction.note),
      evidencePath: Value(transaction.evidencePath),
      ocrSource: Value(transaction.ocrSource),
      rawVoiceText: Value(transaction.note.isEmpty ? null : transaction.note),
      occurredAt: transaction.createdAt,
      updatedAt: Value(now),
      syncStatus: Value(transaction.syncStatus.name),
    );
  }

  TransactionLinesCompanion _lineToCompanion(
    String transactionId,
    TransactionLine line,
    int position,
  ) {
    return TransactionLinesCompanion.insert(
      id: '$transactionId-line-${position + 1}',
      transactionId: transactionId,
      productId: Value(line.productId.trim().isEmpty ? null : line.productId),
      productNameSnapshot: line.productName,
      position: Value(position),
      quantity: Value(line.quantity),
      unit: line.unit.name,
      unitPrice: Value(line.unitPrice),
      costPrice: Value(line.costPrice),
      segment: line.segment.name,
      unitMultiplier: Value(line.unitMultiplier),
    );
  }

  BusinessProfilesCompanion _businessProfileToCompanion(
    MikiezySnapshot snapshot,
    DateTime now,
  ) {
    return BusinessProfilesCompanion.insert(
      id: 'local',
      ownerName: snapshot.ownerName,
      email: snapshot.email,
      phone: snapshot.phone,
      businessName: snapshot.businessName,
      businessCategory: snapshot.businessCategory,
      businessLocation: snapshot.businessLocation,
      memberSince: snapshot.memberSince,
      updatedAt: Value(now),
    );
  }

  List<AppSettingsCompanion> _settingsToCompanions(MikiezySnapshot snapshot) {
    final values = <String, String>{
      _SettingKey.pinEnabled: snapshot.pinEnabled.toString(),
      _SettingKey.biometricEnabled: snapshot.biometricEnabled.toString(),
      _SettingKey.cloudSyncEnabled: snapshot.cloudSyncEnabled.toString(),
      _SettingKey.supabaseUrl: snapshot.supabaseUrl,
      _SettingKey.queuedSyncCount: snapshot.queuedSyncCount.toString(),
      _SettingKey.language: snapshot.language.name,
      _SettingKey.voiceSensitivity: snapshot.voiceSensitivity.toString(),
      _SettingKey.handsfreeWakeWordEnabled: snapshot.handsfreeWakeWordEnabled
          .toString(),
      _SettingKey.silentTimeoutSeconds: snapshot.silentTimeoutSeconds
          .toString(),
    };
    return values.entries
        .map(
          (entry) => AppSettingsCompanion.insert(
            key: entry.key,
            value: entry.value,
            updatedAt: Value(DateTime.now()),
          ),
        )
        .toList();
  }

  Product _productFromRow(ProductRow row) {
    return Product(
      id: row.id,
      name: row.name,
      category: row.categoryNameSnapshot,
      costPrice: row.costPrice,
      retailPrice: row.retailPrice,
      wholesalePrice: row.wholesalePrice,
      packSize: row.packSize,
      cartonSize: row.cartonSize,
      stockPcs: row.stockPcs,
    );
  }

  Wallet _walletFromRow(WalletRow row) {
    return Wallet(
      id: row.id,
      name: row.name,
      balance: row.balance,
      isPrimary: row.isPrimary,
    );
  }

  LedgerCategory _categoryFromRow(TransactionCategoryRow row) {
    return LedgerCategory(
      id: row.id,
      name: row.name,
      direction: _enumByName(
        MoneyDirection.values,
        row.direction,
        MoneyDirection.expense,
      ),
      isSystem: row.isSystem,
    );
  }

  TransactionLine _lineFromRow(TransactionLineRow row) {
    return TransactionLine(
      productId: row.productId ?? '',
      productName: row.productNameSnapshot,
      quantity: row.quantity,
      unit: _enumByName(SaleUnit.values, row.unit, SaleUnit.pcs),
      unitPrice: row.unitPrice,
      costPrice: row.costPrice,
      segment: _enumByName(
        PriceSegment.values,
        row.segment,
        PriceSegment.retail,
      ),
    );
  }

  TransactionRecord _transactionFromRow(
    TransactionRow row,
    List<TransactionLine> lines,
  ) {
    return TransactionRecord(
      id: row.id,
      kind: _enumByName(TransactionKind.values, row.kind, TransactionKind.sale),
      createdAt: row.occurredAt,
      walletId: row.walletId,
      walletName: row.walletNameSnapshot,
      categoryId: row.categoryId ?? '',
      categoryName: row.categoryNameSnapshot,
      lines: lines,
      amount: row.amount,
      discount: row.discount,
      note: row.note,
      evidencePath: row.evidencePath,
      ocrSource: row.ocrSource,
      syncStatus: _enumByName(
        SyncStatus.values,
        row.syncStatus,
        SyncStatus.localOnly,
      ),
    );
  }

  List<String> _mergedProductCategories(MikiezySnapshot snapshot) {
    final values = <String>[];
    for (final category in snapshot.productCategories) {
      _addUnique(values, _cleanName(category, fallback: 'Lain-lain'));
    }
    for (final product in snapshot.products) {
      _addUnique(values, _cleanName(product.category, fallback: 'Lain-lain'));
    }
    if (values.isEmpty) values.add('Lain-lain');
    return values;
  }

  void _addUnique(List<String> values, String value) {
    final exists = values.any(
      (existing) => existing.toLowerCase() == value.toLowerCase(),
    );
    if (!exists) values.add(value);
  }

  String _productCategoryId(String name) {
    return 'pcat-${_slug(name)}';
  }

  String _slug(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'default' : slug;
  }

  String _cleanName(String value, {required String fallback}) {
    final cleaned = value.trim();
    return cleaned.isEmpty ? fallback : cleaned;
  }

  bool _boolSetting(Map<String, String> values, String key, bool fallback) {
    return bool.tryParse(values[key] ?? '') ?? fallback;
  }

  int _intSetting(Map<String, String> values, String key, int fallback) {
    return int.tryParse(values[key] ?? '') ?? fallback;
  }

  T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}

abstract final class _SettingKey {
  static const pinEnabled = 'pin_enabled';
  static const biometricEnabled = 'biometric_enabled';
  static const cloudSyncEnabled = 'cloud_sync_enabled';
  static const supabaseUrl = 'supabase_url';
  static const queuedSyncCount = 'queued_sync_count';
  static const language = 'language';
  static const voiceSensitivity = 'voice_sensitivity';
  static const handsfreeWakeWordEnabled = 'handsfree_wake_word_enabled';
  static const silentTimeoutSeconds = 'silent_timeout_seconds';
}
