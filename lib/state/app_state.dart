import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories/mikiezy_repository.dart';
import '../models/mikiezy_models.dart';

class MikiezyScope extends InheritedNotifier<MikiezyState> {
  const MikiezyScope({
    super.key,
    required MikiezyState super.notifier,
    required super.child,
  });

  static MikiezyState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MikiezyScope>();
    assert(scope != null, 'MikiezyScope is missing above this widget.');
    return scope!.notifier!;
  }
}

class MikiezyState extends ChangeNotifier {
  MikiezyState({
    required List<Product> products,
    required List<String> productCategories,
    required List<Wallet> wallets,
    required List<LedgerCategory> categories,
    required List<TransactionRecord> transactions,
    this.repository,
  }) : _products = List.of(products),
       _productCategories = List.of(productCategories),
       _wallets = List.of(wallets),
       _categories = List.of(categories),
       _transactions = List.of(transactions);

  final List<Product> _products;
  final List<String> _productCategories;
  final List<Wallet> _wallets;
  final List<LedgerCategory> _categories;
  final List<TransactionRecord> _transactions;
  final MikiezyRepository? repository;

  bool pinEnabled = true;
  bool biometricEnabled = true;
  bool cloudSyncEnabled = false;
  String supabaseUrl = 'Belum dikonfigurasi';
  int queuedSyncCount = 8;
  AppLanguage language = AppLanguage.id;
  int voiceSensitivity = 75;
  bool handsfreeWakeWordEnabled = true;
  int silentTimeoutSeconds = 5;
  String ownerName = 'Muhammad Abiyu Muflih';
  String email = 'abiyu@tokomajujaya.com';
  String phone = '+62 812 4523 2101';
  String businessName = 'Toko Maju Jaya';
  String businessCategory = 'Food & Beverage';
  String businessLocation = 'Jakarta, ID';
  String memberSince = 'Mei 2026';
  bool localStorageReady = false;
  String? localStorageError;
  bool transactionInputsLoading = false;
  String? transactionInputsError;
  bool transactionsLoading = false;
  String? transactionsError;
  String? lastTransactionSuccess;
  bool productsLoading = false;
  String? productsError;
  String? lastProductSuccess;
  bool financeLoading = false;
  String? financeError;
  String? lastFinanceSuccess;

  List<Product> get products => List.unmodifiable(_products);
  List<String> get productCategories => List.unmodifiable(_productCategories);
  List<Wallet> get wallets => List.unmodifiable(_wallets);
  List<LedgerCategory> get categories => List.unmodifiable(_categories);
  List<TransactionRecord> get transactions => List.unmodifiable(_transactions);

  int get salesToday {
    return _transactions
        .where(
          (tx) => _isToday(tx.createdAt) && tx.kind == TransactionKind.sale,
        )
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  int get expensesToday {
    return _transactions
        .where(
          (tx) => _isToday(tx.createdAt) && tx.kind == TransactionKind.expense,
        )
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  int get incomeTotal {
    return _transactions
        .where(
          (tx) =>
              tx.kind == TransactionKind.sale ||
              tx.kind == TransactionKind.income,
        )
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  int get expenseTotal {
    return _transactions
        .where((tx) => tx.kind == TransactionKind.expense)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  int get grossProfit {
    return _transactions.fold(0, (sum, tx) => sum + tx.profitContribution);
  }

  int get walletTotal =>
      _wallets.fold(0, (sum, wallet) => sum + wallet.balance);

  List<TransactionRecord> get recentTransactions {
    final sorted = [..._transactions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(6).toList();
  }

  int get monthlyTransactions => _transactions.length;

  int get voiceRecordings {
    return _transactions.where((tx) => tx.note.trim().isNotEmpty).length + 309;
  }

  int get daysActive => 47;

  Future<void> hydrateFromLocal() async {
    final localRepository = repository;
    if (localRepository == null) {
      localStorageReady = true;
      notifyListeners();
      return;
    }

    try {
      final snapshot = await localRepository.loadOrSeed(_snapshot());
      _applySnapshot(snapshot);
      localStorageReady = true;
      localStorageError = null;
    } catch (error) {
      localStorageReady = true;
      localStorageError = error.toString();
    }
    notifyListeners();
  }

  Future<void> refreshTransactionInputs() async {
    final localRepository = repository;
    if (localRepository == null) return;

    transactionInputsLoading = true;
    transactionInputsError = null;
    notifyListeners();
    try {
      await _ensureLocalReady(localRepository);
      final wallets = await localRepository.loadWallets();
      final categories = await localRepository.loadTransactionCategories();
      if (wallets.isNotEmpty) {
        _wallets
          ..clear()
          ..addAll(wallets);
      }
      if (categories.isNotEmpty) {
        _categories
          ..clear()
          ..addAll(categories);
      }
    } catch (error) {
      transactionInputsError = error.toString();
    } finally {
      transactionInputsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTransactions({bool showLoading = true}) async {
    final localRepository = repository;
    if (localRepository == null) return;

    if (showLoading) transactionsLoading = true;
    transactionsError = null;
    notifyListeners();
    try {
      await _ensureLocalReady(localRepository);
      final transactions = await localRepository.loadTransactions();
      _transactions
        ..clear()
        ..addAll(transactions);
    } catch (error) {
      transactionsError = error.toString();
    } finally {
      transactionsLoading = false;
      notifyListeners();
    }
  }

  Future<TransactionRecord?> loadTransactionDetail(String id) async {
    final localRepository = repository;
    if (localRepository == null) return _findTransactionById(id);

    try {
      await _ensureLocalReady(localRepository);
      final transaction = await localRepository.loadTransactionById(id);
      if (transaction != null) _upsertTransactionInMemory(transaction);
      return transaction;
    } catch (error) {
      transactionsError = error.toString();
      notifyListeners();
      return _findTransactionById(id);
    }
  }

  Future<void> refreshProducts({bool showLoading = true}) async {
    final localRepository = repository;
    if (localRepository == null) return;

    if (showLoading) productsLoading = true;
    productsError = null;
    notifyListeners();
    try {
      await _ensureLocalReady(localRepository);
      final categories = await localRepository.loadProductCategories();
      final products = await localRepository.loadProducts();
      _productCategories
        ..clear()
        ..addAll(categories);
      _products
        ..clear()
        ..addAll(products);
      _ensureCategoriesForProducts();
    } catch (error) {
      productsError = error.toString();
    } finally {
      productsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFinance({bool showLoading = true}) async {
    final localRepository = repository;
    if (localRepository == null) return;

    if (showLoading) financeLoading = true;
    financeError = null;
    notifyListeners();
    try {
      await _ensureLocalReady(localRepository);
      final wallets = await localRepository.loadWallets();
      final categories = await localRepository.loadTransactionCategories();
      _wallets
        ..clear()
        ..addAll(wallets);
      _categories
        ..clear()
        ..addAll(categories);
      _ensureFinanceDefaults();
    } catch (error) {
      financeError = error.toString();
    } finally {
      financeLoading = false;
      notifyListeners();
    }
  }

  Future<TransactionRecord> saveDraft(TransactionDraft draft) async {
    final wallet = _findOrCreateWallet(draft.walletName);
    final category = _findCategoryByName(draft.categoryName, draft.kind);
    final productsToSave = <Product>[];
    final lines = <TransactionLine>[];
    if (draft.lines.isNotEmpty) {
      for (final draftLine in draft.lines) {
        final product = draft.kind == TransactionKind.sale
            ? _findOrCreateProductFromLine(draftLine)
            : _findProductForLine(draftLine);
        if (product != null &&
            !productsToSave.any((item) => item.id == product.id)) {
          productsToSave.add(product);
        }
        lines.add(
          TransactionLine(
            productId: product?.id ?? draftLine.productId ?? '',
            productName: draftLine.productName.trim(),
            quantity: draftLine.quantity.clamp(1, 999999),
            unit: draftLine.unit,
            unitPrice: draftLine.unitPrice,
            costPrice: product?.costPrice ?? 0,
            segment: draftLine.segment,
          ),
        );
      }
    } else if (draft.kind == TransactionKind.sale) {
      final product = _findOrCreateProduct(draft);
      productsToSave.add(product);
      lines.add(
        TransactionLine(
          productId: product.id,
          productName: draft.productName,
          quantity: draft.quantity,
          unit: draft.unit,
          unitPrice: draft.unitPrice,
          costPrice: product.costPrice,
          segment: draft.segment,
        ),
      );
    }
    final tx = TransactionRecord(
      id: _nextId('tx'),
      kind: draft.kind,
      createdAt: DateTime.now(),
      walletId: wallet.id,
      walletName: wallet.name,
      categoryId: category.id,
      categoryName: category.name,
      lines: lines,
      amount: draft.amount,
      discount: draft.discount,
      note: draft.note,
      evidencePath: draft.evidencePath,
      ocrSource: draft.ocrSource,
      syncStatus: SyncStatus.queued,
    );
    _transactions.add(tx);
    final updatedWallet = _updateWalletBalance(wallet.id, _walletDelta(tx));
    queuedSyncCount += 1;

    try {
      await _saveTransactionGraph(
        transaction: tx,
        wallet: updatedWallet ?? wallet,
        category: category,
        products: productsToSave,
      );
      await refreshTransactions(showLoading: false);
      lastTransactionSuccess = 'Transaksi berhasil disimpan.';
      transactionsError = null;
      notifyListeners();
      return tx;
    } catch (error) {
      _transactions.removeWhere((transaction) => transaction.id == tx.id);
      _replaceWallet(wallet);
      transactionsError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Product> addProduct(Product product) async {
    final savedProduct = product.copyWith(
      id: product.id.trim().isEmpty || product.id == 'new'
          ? _nextId('prd')
          : product.id,
      category: product.category.trim().isEmpty
          ? 'Lain-lain'
          : product.category.trim(),
    );
    _ensureProductCategory(savedProduct.category);
    _products.add(savedProduct);
    queuedSyncCount += 1;
    notifyListeners();

    try {
      await _saveProductGraph(savedProduct);
      lastProductSuccess = 'Barang berhasil disimpan.';
      productsError = null;
      notifyListeners();
      return savedProduct;
    } catch (error) {
      _products.removeWhere((item) => item.id == savedProduct.id);
      productsError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addProductCategory(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    final existed = _productCategories.any(
      (category) => category.toLowerCase() == cleaned.toLowerCase(),
    );
    _ensureProductCategory(cleaned);
    queuedSyncCount += 1;
    notifyListeners();

    try {
      final localRepository = repository;
      if (localRepository != null) {
        final position = _productCategories.indexWhere(
          (category) => category.toLowerCase() == cleaned.toLowerCase(),
        );
        await localRepository.saveProductCategory(
          cleaned,
          position == -1 ? _productCategories.length : position,
        );
      }
      lastProductSuccess = 'Kategori barang berhasil disimpan.';
      productsError = null;
      notifyListeners();
    } catch (error) {
      if (!existed) {
        _productCategories.removeWhere(
          (category) => category.toLowerCase() == cleaned.toLowerCase(),
        );
      }
      productsError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Product> updateProduct(Product product) async {
    final cleanedProduct = product.copyWith(
      category: product.category.trim().isEmpty
          ? 'Lain-lain'
          : product.category.trim(),
    );
    final index = _products.indexWhere((item) => item.id == cleanedProduct.id);
    if (index == -1) return addProduct(cleanedProduct);

    final previous = _products[index];
    _ensureProductCategory(cleanedProduct.category);
    _products[index] = cleanedProduct;
    queuedSyncCount += 1;
    notifyListeners();

    try {
      await _saveProductGraph(cleanedProduct);
      lastProductSuccess = 'Barang berhasil diperbarui.';
      productsError = null;
      notifyListeners();
      return cleanedProduct;
    } catch (error) {
      _products[index] = previous;
      productsError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    final index = _products.indexWhere((product) => product.id == id);
    if (index == -1) return;

    final removed = _products.removeAt(index);
    queuedSyncCount += 1;
    notifyListeners();

    try {
      final localRepository = repository;
      if (localRepository != null) {
        await localRepository.deleteProduct(id);
      }
      lastProductSuccess = 'Barang berhasil dihapus.';
      productsError = null;
      notifyListeners();
    } catch (error) {
      _products.insert(index, removed);
      productsError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Wallet> addWallet(String name, int balance) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Nama dompet wajib diisi.');
    }
    final wallet = Wallet(
      id: _nextId('wal'),
      name: cleaned,
      balance: balance,
      isPrimary: _wallets.isEmpty,
    );
    _wallets.add(wallet);
    queuedSyncCount += 1;
    notifyListeners();

    try {
      final localRepository = repository;
      if (localRepository != null) await localRepository.saveWallet(wallet);
      lastFinanceSuccess = 'Dompet berhasil disimpan.';
      financeError = null;
      notifyListeners();
      return wallet;
    } catch (error) {
      _wallets.removeWhere((item) => item.id == wallet.id);
      financeError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Wallet> updateWallet(Wallet wallet) async {
    final cleanedWallet = wallet.copyWith(
      name: wallet.name.trim().isEmpty ? 'Dompet' : wallet.name.trim(),
    );
    final index = _wallets.indexWhere((item) => item.id == cleanedWallet.id);
    if (index == -1) {
      return addWallet(cleanedWallet.name, cleanedWallet.balance);
    }

    final previous = _wallets[index];
    _wallets[index] = cleanedWallet;
    queuedSyncCount += 1;
    notifyListeners();

    try {
      final localRepository = repository;
      if (localRepository != null) {
        await localRepository.saveWallet(cleanedWallet);
      }
      lastFinanceSuccess = 'Dompet berhasil diperbarui.';
      financeError = null;
      notifyListeners();
      return cleanedWallet;
    } catch (error) {
      _wallets[index] = previous;
      financeError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteWallet(String id) async {
    final index = _wallets.indexWhere((wallet) => wallet.id == id);
    if (index == -1) return;
    if (_wallets.length <= 1) {
      throw StateError('Minimal harus ada satu dompet.');
    }

    final removed = _wallets.removeAt(index);
    if (removed.isPrimary && _wallets.isNotEmpty) {
      _wallets[0] = _wallets[0].copyWith(isPrimary: true);
    }
    queuedSyncCount += 1;
    notifyListeners();

    try {
      final localRepository = repository;
      if (localRepository != null) {
        await localRepository.deleteWallet(id);
        if (removed.isPrimary && _wallets.isNotEmpty) {
          await localRepository.saveWallet(_wallets[0]);
        }
      }
      lastFinanceSuccess = 'Dompet berhasil dihapus.';
      financeError = null;
      notifyListeners();
    } catch (error) {
      _wallets.insert(index, removed);
      financeError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<LedgerCategory> addCategory(
    String name,
    MoneyDirection direction,
  ) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Nama kategori wajib diisi.');
    }
    final category = LedgerCategory(
      id: _nextId('cat'),
      name: cleaned,
      direction: direction,
    );
    _categories.add(category);
    queuedSyncCount += 1;
    notifyListeners();

    try {
      final localRepository = repository;
      if (localRepository != null) {
        await localRepository.saveTransactionCategory(category);
      }
      lastFinanceSuccess = 'Kategori berhasil disimpan.';
      financeError = null;
      notifyListeners();
      return category;
    } catch (error) {
      _categories.removeWhere((item) => item.id == category.id);
      financeError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<LedgerCategory> updateCategory(LedgerCategory category) async {
    final cleanedCategory = LedgerCategory(
      id: category.id,
      name: category.name.trim().isEmpty ? 'Kategori' : category.name.trim(),
      direction: category.direction,
      isSystem: category.isSystem,
    );
    final index = _categories.indexWhere((item) => item.id == category.id);
    if (index == -1) {
      return addCategory(cleanedCategory.name, cleanedCategory.direction);
    }

    final previous = _categories[index];
    _categories[index] = cleanedCategory;
    queuedSyncCount += 1;
    notifyListeners();

    try {
      final localRepository = repository;
      if (localRepository != null) {
        await localRepository.saveTransactionCategory(cleanedCategory);
      }
      lastFinanceSuccess = 'Kategori berhasil diperbarui.';
      financeError = null;
      notifyListeners();
      return cleanedCategory;
    } catch (error) {
      _categories[index] = previous;
      financeError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    final index = _categories.indexWhere((category) => category.id == id);
    if (index == -1) return;
    final removed = _categories[index];
    if (removed.isSystem) {
      throw StateError('Kategori sistem tidak bisa dihapus.');
    }

    _categories.removeAt(index);
    queuedSyncCount += 1;
    notifyListeners();

    try {
      final localRepository = repository;
      if (localRepository != null) {
        await localRepository.deleteTransactionCategory(id);
      }
      lastFinanceSuccess = 'Kategori berhasil dihapus.';
      financeError = null;
      notifyListeners();
    } catch (error) {
      _categories.insert(index, removed);
      financeError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  void togglePin(bool value) {
    pinEnabled = value;
    _persist();
    notifyListeners();
  }

  void toggleBiometric(bool value) {
    biometricEnabled = value;
    _persist();
    notifyListeners();
  }

  void toggleCloudSync(bool value) {
    cloudSyncEnabled = value;
    _persist();
    notifyListeners();
  }

  void setLanguage(AppLanguage value) {
    language = value;
    _persist();
    notifyListeners();
  }

  void setVoiceSensitivity(int value) {
    voiceSensitivity = value.clamp(0, 100);
    _persist();
    notifyListeners();
  }

  void toggleHandsfreeWakeWord(bool value) {
    handsfreeWakeWordEnabled = value;
    _persist();
    notifyListeners();
  }

  void setSilentTimeoutSeconds(int value) {
    silentTimeoutSeconds = value.clamp(3, 10);
    _persist();
    notifyListeners();
  }

  void updateProfile({
    required String ownerName,
    required String email,
    required String phone,
    required String businessName,
    required String businessCategory,
    required String businessLocation,
  }) {
    this.ownerName = ownerName;
    this.email = email;
    this.phone = phone;
    this.businessName = businessName;
    this.businessCategory = businessCategory;
    this.businessLocation = businessLocation;
    queuedSyncCount += 1;
    _persist();
    notifyListeners();
  }

  Product _findOrCreateProduct(TransactionDraft draft) {
    return _findOrCreateProductFromLine(
      TransactionDraftLine(
        tempId: 'legacy-line-1',
        productName: draft.productName,
        quantity: draft.quantity,
        unit: draft.unit,
        unitPrice: draft.unitPrice,
        segment: draft.segment,
      ),
    );
  }

  Product? _findProductForLine(TransactionDraftLine line) {
    final productId = line.productId;
    if (productId != null && productId.trim().isNotEmpty) {
      final byId = _products.where((product) => product.id == productId);
      if (byId.isNotEmpty) return byId.first;
    }
    final productName = line.productName.trim();
    if (productName.isEmpty) return null;
    final byName = _products.where(
      (product) => product.name.toLowerCase() == productName.toLowerCase(),
    );
    return byName.isEmpty ? null : byName.first;
  }

  Product _findOrCreateProductFromLine(TransactionDraftLine line) {
    final matched = _findProductForLine(line);
    if (matched != null) return matched;

    final productName = line.productName.trim().isEmpty
        ? 'Item transaksi'
        : line.productName.trim();
    final existing = _products.where(
      (product) => product.name.toLowerCase() == productName.toLowerCase(),
    );
    if (existing.isNotEmpty) return existing.first;

    final product = Product(
      id: _nextId('prd'),
      name: productName,
      category: 'Belum dikategorikan',
      costPrice: (line.unitPrice * 0.65).round(),
      retailPrice: line.unitPrice,
      wholesalePrice: (line.unitPrice * 0.9).round(),
      packSize: 12,
      cartonSize: 48,
      stockPcs: 0,
    );
    _products.add(product);
    _ensureProductCategory(product.category);
    return product;
  }

  void _ensureProductCategory(String name) {
    final cleaned = name.trim().isEmpty ? 'Lain-lain' : name.trim();
    final exists = _productCategories.any(
      (category) => category.toLowerCase() == cleaned.toLowerCase(),
    );
    if (!exists) _productCategories.add(cleaned);
  }

  void _ensureCategoriesForProducts() {
    for (final product in _products) {
      _ensureProductCategory(product.category);
    }
    if (_productCategories.isEmpty) _productCategories.add('Lain-lain');
  }

  LedgerCategory _findCategoryByName(String name, TransactionKind kind) {
    final direction = kind == TransactionKind.expense
        ? MoneyDirection.expense
        : MoneyDirection.income;
    final cleaned = name.trim().isEmpty
        ? (direction == MoneyDirection.expense ? 'Lain-lain' : 'Penjualan')
        : name.trim();
    final existing = _categories.where((category) {
      return category.direction == direction &&
          category.name.toLowerCase() == cleaned.toLowerCase();
    });
    if (existing.isNotEmpty) return existing.first;

    final category = LedgerCategory(
      id: _nextId('cat'),
      name: cleaned,
      direction: direction,
    );
    _categories.add(category);
    return category;
  }

  Wallet? _findWalletByName(String name) {
    for (final wallet in _wallets) {
      if (wallet.name.toLowerCase() == name.toLowerCase()) return wallet;
    }
    return null;
  }

  Wallet? _updateWalletBalance(String walletId, int delta) {
    final index = _wallets.indexWhere((wallet) => wallet.id == walletId);
    if (index == -1) return null;
    final wallet = _wallets[index];
    _wallets[index] = wallet.copyWith(balance: wallet.balance + delta);
    return _wallets[index];
  }

  int _walletDelta(TransactionRecord tx) {
    switch (tx.kind) {
      case TransactionKind.sale:
      case TransactionKind.income:
        return tx.amount;
      case TransactionKind.expense:
        return -tx.amount;
      case TransactionKind.adjustment:
        return tx.amount;
    }
  }

  String _nextId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_transactions.length + _products.length}';
  }

  Wallet _findOrCreateWallet(String name) {
    final cleaned = name.trim().isEmpty ? 'Dompet Utama' : name.trim();
    final existing = _findWalletByName(cleaned);
    if (existing != null) return existing;

    final wallet = Wallet(
      id: _nextId('wal'),
      name: cleaned,
      balance: 0,
      isPrimary: _wallets.isEmpty,
    );
    _wallets.add(wallet);
    return wallet;
  }

  TransactionRecord? _findTransactionById(String id) {
    for (final transaction in _transactions) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  void _upsertTransactionInMemory(TransactionRecord transaction) {
    final index = _transactions.indexWhere((item) => item.id == transaction.id);
    if (index == -1) {
      _transactions.add(transaction);
    } else {
      _transactions[index] = transaction;
    }
    notifyListeners();
  }

  void _replaceWallet(Wallet wallet) {
    final index = _wallets.indexWhere((item) => item.id == wallet.id);
    if (index == -1) {
      _wallets.add(wallet);
    } else {
      _wallets[index] = wallet;
    }
  }

  void _ensureFinanceDefaults() {
    if (_wallets.isEmpty) {
      _wallets.add(
        const Wallet(
          id: 'wal-main',
          name: 'Dompet Utama',
          balance: 0,
          isPrimary: true,
        ),
      );
    }
    if (_categories.isEmpty) {
      _categories.addAll(const [
        LedgerCategory(
          id: 'cat-sales',
          name: 'Penjualan',
          direction: MoneyDirection.income,
          isSystem: true,
        ),
        LedgerCategory(
          id: 'cat-other',
          name: 'Lain-lain',
          direction: MoneyDirection.expense,
          isSystem: true,
        ),
      ]);
    }
  }

  Future<void> _saveTransactionGraph({
    required TransactionRecord transaction,
    required Wallet wallet,
    required LedgerCategory category,
    List<Product> products = const [],
  }) async {
    final localRepository = repository;
    if (localRepository == null) return;

    for (final product in products) {
      final position = _productCategories.indexWhere(
        (item) => item.toLowerCase() == product.category.toLowerCase(),
      );
      await localRepository.saveProductCategory(
        product.category,
        position == -1 ? _productCategories.length : position,
      );
      await localRepository.saveProduct(product);
    }
    await localRepository.saveTransactionCategory(category);
    await localRepository.saveWallet(wallet);
    await localRepository.saveTransaction(transaction);
  }

  Future<void> _saveProductGraph(Product product) async {
    final localRepository = repository;
    if (localRepository == null) return;

    final position = _productCategories.indexWhere(
      (item) => item.toLowerCase() == product.category.toLowerCase(),
    );
    await localRepository.saveProductCategory(
      product.category,
      position == -1 ? _productCategories.length : position,
    );
    await localRepository.saveProduct(product);
  }

  Future<void> _ensureLocalReady(MikiezyRepository localRepository) async {
    if (localStorageReady) return;
    final snapshot = await localRepository.loadOrSeed(_snapshot());
    _applySnapshot(snapshot);
    localStorageReady = true;
    localStorageError = null;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  MikiezySnapshot _snapshot() {
    return MikiezySnapshot(
      products: products,
      productCategories: productCategories,
      wallets: wallets,
      categories: categories,
      transactions: transactions,
      pinEnabled: pinEnabled,
      biometricEnabled: biometricEnabled,
      cloudSyncEnabled: cloudSyncEnabled,
      supabaseUrl: supabaseUrl,
      queuedSyncCount: queuedSyncCount,
      language: language,
      voiceSensitivity: voiceSensitivity,
      handsfreeWakeWordEnabled: handsfreeWakeWordEnabled,
      silentTimeoutSeconds: silentTimeoutSeconds,
      ownerName: ownerName,
      email: email,
      phone: phone,
      businessName: businessName,
      businessCategory: businessCategory,
      businessLocation: businessLocation,
      memberSince: memberSince,
    );
  }

  void _applySnapshot(MikiezySnapshot snapshot) {
    _products
      ..clear()
      ..addAll(snapshot.products);
    _productCategories
      ..clear()
      ..addAll(snapshot.productCategories);
    _wallets
      ..clear()
      ..addAll(snapshot.wallets);
    _categories
      ..clear()
      ..addAll(snapshot.categories);
    _transactions
      ..clear()
      ..addAll(snapshot.transactions);
    pinEnabled = snapshot.pinEnabled;
    biometricEnabled = snapshot.biometricEnabled;
    cloudSyncEnabled = snapshot.cloudSyncEnabled;
    supabaseUrl = snapshot.supabaseUrl;
    queuedSyncCount = snapshot.queuedSyncCount;
    language = snapshot.language;
    voiceSensitivity = snapshot.voiceSensitivity;
    handsfreeWakeWordEnabled = snapshot.handsfreeWakeWordEnabled;
    silentTimeoutSeconds = snapshot.silentTimeoutSeconds;
    ownerName = snapshot.ownerName;
    email = snapshot.email;
    phone = snapshot.phone;
    businessName = snapshot.businessName;
    businessCategory = snapshot.businessCategory;
    businessLocation = snapshot.businessLocation;
    memberSince = snapshot.memberSince;
  }

  void _persist() {
    final localRepository = repository;
    if (localRepository == null) return;
    unawaited(
      localRepository.saveSnapshot(_snapshot()).catchError((Object error) {
        localStorageError = error.toString();
        notifyListeners();
      }),
    );
  }

  static MikiezyState seeded({MikiezyRepository? repository}) {
    final now = DateTime.now();
    final products = <Product>[
      const Product(
        id: 'prd-nasi',
        name: 'Nasi Goreng',
        category: 'Makanan',
        costPrice: 9000,
        retailPrice: 15000,
        wholesalePrice: 13000,
        packSize: 10,
        cartonSize: 40,
        stockPcs: 82,
      ),
      const Product(
        id: 'prd-es-teh',
        name: 'Es Teh Manis',
        category: 'Minuman',
        costPrice: 2500,
        retailPrice: 5000,
        wholesalePrice: 4200,
        packSize: 12,
        cartonSize: 48,
        stockPcs: 180,
      ),
      const Product(
        id: 'prd-kopi',
        name: 'Kopi Susu Botol',
        category: 'Minuman',
        costPrice: 6500,
        retailPrice: 12000,
        wholesalePrice: 10000,
        packSize: 12,
        cartonSize: 24,
        stockPcs: 64,
      ),
    ];

    const productCategories = <String>[
      'Makanan',
      'Minuman',
      'Sembako',
      'Snack',
      'Lain-lain',
    ];

    const wallets = <Wallet>[
      Wallet(
        id: 'wal-main',
        name: 'Dompet Utama',
        balance: 1625000,
        isPrimary: true,
      ),
      Wallet(
        id: 'wal-bank',
        name: 'Rekening BCA',
        balance: 4200000,
        isPrimary: false,
      ),
      Wallet(
        id: 'wal-cash',
        name: 'Kas Toko',
        balance: 850000,
        isPrimary: false,
      ),
    ];

    const categories = <LedgerCategory>[
      LedgerCategory(
        id: 'cat-sales',
        name: 'Penjualan',
        direction: MoneyDirection.income,
        isSystem: true,
      ),
      LedgerCategory(
        id: 'cat-capital',
        name: 'Modal masuk',
        direction: MoneyDirection.income,
        isSystem: true,
      ),
      LedgerCategory(
        id: 'cat-adjustment',
        name: 'Penyesuaian saldo',
        direction: MoneyDirection.income,
        isSystem: true,
      ),
      LedgerCategory(
        id: 'cat-material',
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
        id: 'cat-service',
        name: 'Jasa',
        direction: MoneyDirection.expense,
        isSystem: true,
      ),
      LedgerCategory(
        id: 'cat-bill',
        name: 'Tagihan',
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
        id: 'cat-social',
        name: 'Sosial',
        direction: MoneyDirection.expense,
        isSystem: true,
      ),
      LedgerCategory(
        id: 'cat-other',
        name: 'Lain-lain',
        direction: MoneyDirection.expense,
        isSystem: true,
      ),
    ];

    final transactions = <TransactionRecord>[
      TransactionRecord(
        id: 'tx-001',
        kind: TransactionKind.sale,
        createdAt: now.subtract(const Duration(minutes: 18)),
        walletId: 'wal-main',
        walletName: 'Dompet Utama',
        categoryId: 'cat-sales',
        categoryName: 'Penjualan',
        lines: const [
          TransactionLine(
            productId: 'prd-nasi',
            productName: 'Nasi Goreng',
            quantity: 3,
            unit: SaleUnit.pcs,
            unitPrice: 15000,
            costPrice: 9000,
            segment: PriceSegment.retail,
          ),
        ],
        amount: 45000,
        discount: 0,
        note:
            'Miki, jual nasi goreng tiga porsi harga lima belas ribu per porsi',
        evidencePath: null,
        ocrSource: null,
        syncStatus: SyncStatus.queued,
      ),
      TransactionRecord(
        id: 'tx-002',
        kind: TransactionKind.sale,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 5)),
        walletId: 'wal-main',
        walletName: 'Dompet Utama',
        categoryId: 'cat-sales',
        categoryName: 'Penjualan',
        lines: const [
          TransactionLine(
            productId: 'prd-es-teh',
            productName: 'Es Teh Manis',
            quantity: 5,
            unit: SaleUnit.pcs,
            unitPrice: 5000,
            costPrice: 2500,
            segment: PriceSegment.retail,
          ),
        ],
        amount: 23000,
        discount: 2000,
        note: 'Diskon pelanggan tetap',
        evidencePath: 'bukti://foto-penjualan-002',
        ocrSource: null,
        syncStatus: SyncStatus.localOnly,
      ),
      TransactionRecord(
        id: 'tx-003',
        kind: TransactionKind.expense,
        createdAt: now.subtract(const Duration(hours: 3)),
        walletId: 'wal-cash',
        walletName: 'Kas Toko',
        categoryId: 'cat-material',
        categoryName: 'Bahan baku',
        lines: const [],
        amount: 180000,
        discount: 0,
        note: 'Belanja beras, minyak, dan bumbu',
        evidencePath: 'bukti://nota-bahan-baku',
        ocrSource: 'OCR nota supplier masih perlu dicek',
        syncStatus: SyncStatus.queued,
      ),
    ];

    return MikiezyState(
      products: products,
      productCategories: productCategories,
      wallets: [...wallets],
      categories: [...categories],
      transactions: transactions,
      repository: repository,
    );
  }
}
