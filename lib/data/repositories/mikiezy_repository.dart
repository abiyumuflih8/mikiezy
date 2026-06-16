import 'package:flutter/foundation.dart';

import '../../core/database/app_database.dart';
import '../../models/mikiezy_models.dart';
import '../local/mikiezy_local_data_source.dart';
import '../local/mikiezy_snapshot.dart';

export '../local/mikiezy_snapshot.dart';

abstract class MikiezyRepository {
  factory MikiezyRepository.open({bool persistent = true}) {
    if (!persistent || kIsWeb) return MemoryMikiezyRepository();
    return DriftMikiezyRepository(MikiezyLocalDataSource(AppDatabase()));
  }

  Future<MikiezySnapshot> loadOrSeed(MikiezySnapshot seed);
  Future<List<Product>> loadProducts();
  Future<List<String>> loadProductCategories();
  Future<List<Wallet>> loadWallets();
  Future<List<LedgerCategory>> loadTransactionCategories();
  Future<List<TransactionRecord>> loadTransactions();
  Future<TransactionRecord?> loadTransactionById(String id);
  Future<void> saveSnapshot(MikiezySnapshot snapshot);
  Future<void> saveProduct(Product product);
  Future<void> saveProductCategory(String name, int position);
  Future<void> deleteProduct(String id);
  Future<void> saveWallet(Wallet wallet);
  Future<void> deleteWallet(String id);
  Future<void> saveTransactionCategory(LedgerCategory category);
  Future<void> deleteTransactionCategory(String id);
  Future<void> saveTransaction(TransactionRecord transaction);
  Future<void> close();
}

class MemoryMikiezyRepository implements MikiezyRepository {
  MikiezySnapshot? _snapshot;

  @override
  Future<MikiezySnapshot> loadOrSeed(MikiezySnapshot seed) async {
    _snapshot ??= seed.copy();
    return _snapshot!.copy();
  }

  @override
  Future<void> saveSnapshot(MikiezySnapshot snapshot) async {
    _snapshot = snapshot.copy();
  }

  @override
  Future<List<Product>> loadProducts() async {
    return List.of(_snapshot?.products ?? const []);
  }

  @override
  Future<List<String>> loadProductCategories() async {
    return List.of(_snapshot?.productCategories ?? const []);
  }

  @override
  Future<List<Wallet>> loadWallets() async {
    return List.of(_snapshot?.wallets ?? const []);
  }

  @override
  Future<List<LedgerCategory>> loadTransactionCategories() async {
    return List.of(_snapshot?.categories ?? const []);
  }

  @override
  Future<List<TransactionRecord>> loadTransactions() async {
    final transactions = [...?_snapshot?.transactions];
    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return transactions;
  }

  @override
  Future<TransactionRecord?> loadTransactionById(String id) async {
    for (final transaction in _snapshot?.transactions ?? const []) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  @override
  Future<void> saveProduct(Product product) async {
    final current = _snapshot;
    if (current == null) return;
    final products = [...current.products];
    final index = products.indexWhere((item) => item.id == product.id);
    if (index == -1) {
      products.add(product);
    } else {
      products[index] = product;
    }
    _snapshot = _copyWithProducts(current, products);
  }

  @override
  Future<void> saveProductCategory(String name, int position) async {
    final current = _snapshot;
    if (current == null) return;
    final categories = [...current.productCategories];
    final exists = categories.any(
      (category) => category.toLowerCase() == name.toLowerCase(),
    );
    if (!exists) {
      categories.insert(position.clamp(0, categories.length).toInt(), name);
    }
    _snapshot = _copyWithProductCategories(current, categories);
  }

  @override
  Future<void> deleteProduct(String id) async {
    final current = _snapshot;
    if (current == null) return;
    _snapshot = _copyWithProducts(
      current,
      current.products.where((product) => product.id != id).toList(),
    );
  }

  @override
  Future<void> saveWallet(Wallet wallet) async {
    final current = _snapshot;
    if (current == null) return;
    final wallets = [...current.wallets];
    final index = wallets.indexWhere((item) => item.id == wallet.id);
    if (index == -1) {
      wallets.add(wallet);
    } else {
      wallets[index] = wallet;
    }
    _snapshot = _copyWithWallets(current, wallets);
  }

  @override
  Future<void> deleteWallet(String id) async {
    final current = _snapshot;
    if (current == null) return;
    _snapshot = _copyWithWallets(
      current,
      current.wallets.where((wallet) => wallet.id != id).toList(),
    );
  }

  @override
  Future<void> saveTransactionCategory(LedgerCategory category) async {
    final current = _snapshot;
    if (current == null) return;
    final categories = [...current.categories];
    final index = categories.indexWhere((item) => item.id == category.id);
    if (index == -1) {
      categories.add(category);
    } else {
      categories[index] = category;
    }
    _snapshot = _copyWithCategories(current, categories);
  }

  @override
  Future<void> deleteTransactionCategory(String id) async {
    final current = _snapshot;
    if (current == null) return;
    _snapshot = _copyWithCategories(
      current,
      current.categories.where((category) => category.id != id).toList(),
    );
  }

  @override
  Future<void> saveTransaction(TransactionRecord transaction) async {
    final current = _snapshot;
    if (current == null) return;
    final transactions = [...current.transactions];
    final index = transactions.indexWhere((item) => item.id == transaction.id);
    if (index == -1) {
      transactions.add(transaction);
    } else {
      transactions[index] = transaction;
    }
    _snapshot = _copyWithTransactions(current, transactions);
  }

  @override
  Future<void> close() async {}
}

class DriftMikiezyRepository implements MikiezyRepository {
  const DriftMikiezyRepository(this._localDataSource);

  final MikiezyLocalDataSource _localDataSource;

  @override
  Future<MikiezySnapshot> loadOrSeed(MikiezySnapshot seed) {
    return _localDataSource.loadOrSeed(seed);
  }

  @override
  Future<List<Product>> loadProducts() {
    return _localDataSource.readProducts();
  }

  @override
  Future<List<String>> loadProductCategories() {
    return _localDataSource.readProductCategories();
  }

  @override
  Future<List<Wallet>> loadWallets() {
    return _localDataSource.readWallets();
  }

  @override
  Future<List<LedgerCategory>> loadTransactionCategories() {
    return _localDataSource.readTransactionCategories();
  }

  @override
  Future<List<TransactionRecord>> loadTransactions() {
    return _localDataSource.readTransactions();
  }

  @override
  Future<TransactionRecord?> loadTransactionById(String id) {
    return _localDataSource.readTransactionById(id);
  }

  @override
  Future<void> saveSnapshot(MikiezySnapshot snapshot) {
    return _localDataSource.replaceSnapshot(snapshot);
  }

  @override
  Future<void> saveProduct(Product product) {
    return _localDataSource.upsertProduct(product);
  }

  @override
  Future<void> saveProductCategory(String name, int position) {
    return _localDataSource.upsertProductCategory(name, position);
  }

  @override
  Future<void> deleteProduct(String id) {
    return _localDataSource.softDeleteProduct(id);
  }

  @override
  Future<void> saveWallet(Wallet wallet) {
    return _localDataSource.upsertWallet(wallet);
  }

  @override
  Future<void> deleteWallet(String id) {
    return _localDataSource.softDeleteWallet(id);
  }

  @override
  Future<void> saveTransactionCategory(LedgerCategory category) {
    return _localDataSource.upsertTransactionCategory(category);
  }

  @override
  Future<void> deleteTransactionCategory(String id) {
    return _localDataSource.softDeleteTransactionCategory(id);
  }

  @override
  Future<void> saveTransaction(TransactionRecord transaction) {
    return _localDataSource.upsertTransaction(transaction);
  }

  @override
  Future<void> close() {
    return _localDataSource.close();
  }
}

MikiezySnapshot _copyWithProducts(
  MikiezySnapshot snapshot,
  List<Product> products,
) {
  return MikiezySnapshot(
    products: products,
    productCategories: snapshot.productCategories,
    wallets: snapshot.wallets,
    categories: snapshot.categories,
    transactions: snapshot.transactions,
    pinEnabled: snapshot.pinEnabled,
    biometricEnabled: snapshot.biometricEnabled,
    cloudSyncEnabled: snapshot.cloudSyncEnabled,
    supabaseUrl: snapshot.supabaseUrl,
    queuedSyncCount: snapshot.queuedSyncCount,
    language: snapshot.language,
    voiceSensitivity: snapshot.voiceSensitivity,
    handsfreeWakeWordEnabled: snapshot.handsfreeWakeWordEnabled,
    silentTimeoutSeconds: snapshot.silentTimeoutSeconds,
    ownerName: snapshot.ownerName,
    email: snapshot.email,
    phone: snapshot.phone,
    businessName: snapshot.businessName,
    businessCategory: snapshot.businessCategory,
    businessLocation: snapshot.businessLocation,
    memberSince: snapshot.memberSince,
  );
}

MikiezySnapshot _copyWithProductCategories(
  MikiezySnapshot snapshot,
  List<String> productCategories,
) {
  return MikiezySnapshot(
    products: snapshot.products,
    productCategories: productCategories,
    wallets: snapshot.wallets,
    categories: snapshot.categories,
    transactions: snapshot.transactions,
    pinEnabled: snapshot.pinEnabled,
    biometricEnabled: snapshot.biometricEnabled,
    cloudSyncEnabled: snapshot.cloudSyncEnabled,
    supabaseUrl: snapshot.supabaseUrl,
    queuedSyncCount: snapshot.queuedSyncCount,
    language: snapshot.language,
    voiceSensitivity: snapshot.voiceSensitivity,
    handsfreeWakeWordEnabled: snapshot.handsfreeWakeWordEnabled,
    silentTimeoutSeconds: snapshot.silentTimeoutSeconds,
    ownerName: snapshot.ownerName,
    email: snapshot.email,
    phone: snapshot.phone,
    businessName: snapshot.businessName,
    businessCategory: snapshot.businessCategory,
    businessLocation: snapshot.businessLocation,
    memberSince: snapshot.memberSince,
  );
}

MikiezySnapshot _copyWithWallets(
  MikiezySnapshot snapshot,
  List<Wallet> wallets,
) {
  return MikiezySnapshot(
    products: snapshot.products,
    productCategories: snapshot.productCategories,
    wallets: wallets,
    categories: snapshot.categories,
    transactions: snapshot.transactions,
    pinEnabled: snapshot.pinEnabled,
    biometricEnabled: snapshot.biometricEnabled,
    cloudSyncEnabled: snapshot.cloudSyncEnabled,
    supabaseUrl: snapshot.supabaseUrl,
    queuedSyncCount: snapshot.queuedSyncCount,
    language: snapshot.language,
    voiceSensitivity: snapshot.voiceSensitivity,
    handsfreeWakeWordEnabled: snapshot.handsfreeWakeWordEnabled,
    silentTimeoutSeconds: snapshot.silentTimeoutSeconds,
    ownerName: snapshot.ownerName,
    email: snapshot.email,
    phone: snapshot.phone,
    businessName: snapshot.businessName,
    businessCategory: snapshot.businessCategory,
    businessLocation: snapshot.businessLocation,
    memberSince: snapshot.memberSince,
  );
}

MikiezySnapshot _copyWithCategories(
  MikiezySnapshot snapshot,
  List<LedgerCategory> categories,
) {
  return MikiezySnapshot(
    products: snapshot.products,
    productCategories: snapshot.productCategories,
    wallets: snapshot.wallets,
    categories: categories,
    transactions: snapshot.transactions,
    pinEnabled: snapshot.pinEnabled,
    biometricEnabled: snapshot.biometricEnabled,
    cloudSyncEnabled: snapshot.cloudSyncEnabled,
    supabaseUrl: snapshot.supabaseUrl,
    queuedSyncCount: snapshot.queuedSyncCount,
    language: snapshot.language,
    voiceSensitivity: snapshot.voiceSensitivity,
    handsfreeWakeWordEnabled: snapshot.handsfreeWakeWordEnabled,
    silentTimeoutSeconds: snapshot.silentTimeoutSeconds,
    ownerName: snapshot.ownerName,
    email: snapshot.email,
    phone: snapshot.phone,
    businessName: snapshot.businessName,
    businessCategory: snapshot.businessCategory,
    businessLocation: snapshot.businessLocation,
    memberSince: snapshot.memberSince,
  );
}

MikiezySnapshot _copyWithTransactions(
  MikiezySnapshot snapshot,
  List<TransactionRecord> transactions,
) {
  return MikiezySnapshot(
    products: snapshot.products,
    productCategories: snapshot.productCategories,
    wallets: snapshot.wallets,
    categories: snapshot.categories,
    transactions: transactions,
    pinEnabled: snapshot.pinEnabled,
    biometricEnabled: snapshot.biometricEnabled,
    cloudSyncEnabled: snapshot.cloudSyncEnabled,
    supabaseUrl: snapshot.supabaseUrl,
    queuedSyncCount: snapshot.queuedSyncCount,
    language: snapshot.language,
    voiceSensitivity: snapshot.voiceSensitivity,
    handsfreeWakeWordEnabled: snapshot.handsfreeWakeWordEnabled,
    silentTimeoutSeconds: snapshot.silentTimeoutSeconds,
    ownerName: snapshot.ownerName,
    email: snapshot.email,
    phone: snapshot.phone,
    businessName: snapshot.businessName,
    businessCategory: snapshot.businessCategory,
    businessLocation: snapshot.businessLocation,
    memberSince: snapshot.memberSince,
  );
}
