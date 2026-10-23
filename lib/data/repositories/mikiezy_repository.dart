import 'package:flutter/foundation.dart';

import '../../core/database/app_database.dart';
import '../../domain/models/voice_action.dart';
import '../../domain/models/voice_create_product_commit.dart';
import '../../domain/models/product_price.dart';
import '../../domain/models/voice_price_update_commit.dart';
import '../../domain/models/voice_price_update_undo.dart';
import '../../domain/models/voice_stock_increment_commit.dart';
import '../../domain/services/product_price_update_validator.dart';
import '../../domain/services/product_validator.dart';
import '../../domain/services/quantity_formatter.dart';
import '../../domain/services/stable_fingerprint_service.dart';
import '../../domain/services/stock_increment_calculator.dart';
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
  Future<void> saveTransactionGraph({
    required TransactionRecord transaction,
    required Wallet wallet,
    required LedgerCategory category,
    List<Product> products = const [],
    Map<String, int> productCategoryPositions = const {},
  });
  Future<void> recordVoiceLearning({
    List<VoiceProductAlias> productAliases = const [],
    List<VoiceUnitAlias> unitAliases = const [],
    List<VoiceCorrection> corrections = const [],
  });
  Future<void> recordVoiceActionAudit(VoiceActionAuditEvent event);
  Future<bool> hasSuccessfulVoiceAction({
    required String actionId,
    required String commandFingerprint,
  });
  Future<VoiceCreateProductCommitResult> createProductFromVoice(
    VoiceCreateProductCommitRequest request,
  );
  Future<VoiceStockIncrementCommitResult> incrementProductStockFromVoice(
    VoiceStockIncrementCommitRequest request,
  );
  Future<VoicePriceUpdateCommitResult> updateProductPriceFromVoice(
    VoicePriceUpdateCommitRequest request,
  );
  Future<VoicePriceUpdateUndoResult> undoProductPriceUpdate(
    VoicePriceUpdateUndoRequest request,
  );
  Future<List<VoiceActionAuditEvent>> loadVoiceActionAudits(String actionId);
  Future<void> close();
}

class MemoryMikiezyRepository implements MikiezyRepository {
  MikiezySnapshot? _snapshot;
  final List<VoiceActionAuditEvent> _voiceActionAudits = [];

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
  Future<void> saveTransactionGraph({
    required TransactionRecord transaction,
    required Wallet wallet,
    required LedgerCategory category,
    List<Product> products = const [],
    Map<String, int> productCategoryPositions = const {},
  }) async {
    for (final product in products) {
      await saveProductCategory(
        product.category,
        productCategoryPositions[product.category] ?? 0,
      );
      await saveProduct(product);
    }
    await saveTransactionCategory(category);
    await saveWallet(wallet);
    await saveTransaction(transaction);
  }

  @override
  Future<void> recordVoiceLearning({
    List<VoiceProductAlias> productAliases = const [],
    List<VoiceUnitAlias> unitAliases = const [],
    List<VoiceCorrection> corrections = const [],
  }) async {
    final current = _snapshot;
    if (current == null) return;
    _snapshot = MikiezySnapshot(
      products: current.products,
      productCategories: current.productCategories,
      wallets: current.wallets,
      categories: current.categories,
      transactions: current.transactions,
      voiceProductAliases: _mergeProductAliases(
        current.voiceProductAliases,
        productAliases,
      ),
      voiceUnitAliases: _mergeUnitAliases(
        current.voiceUnitAliases,
        unitAliases,
      ),
      voiceCorrections: [...current.voiceCorrections, ...corrections],
      pinEnabled: current.pinEnabled,
      biometricEnabled: current.biometricEnabled,
      cloudSyncEnabled: current.cloudSyncEnabled,
      supabaseUrl: current.supabaseUrl,
      queuedSyncCount: current.queuedSyncCount,
      language: current.language,
      voiceSensitivity: current.voiceSensitivity,
      handsfreeWakeWordEnabled: current.handsfreeWakeWordEnabled,
      silentTimeoutSeconds: current.silentTimeoutSeconds,
      enableVoiceLearning: current.enableVoiceLearning,
      voiceFinancialPrivacyEnabled: current.voiceFinancialPrivacyEnabled,
      maskVoiceFinancialValues: current.maskVoiceFinancialValues,
      ownerName: current.ownerName,
      email: current.email,
      phone: current.phone,
      businessName: current.businessName,
      businessCategory: current.businessCategory,
      businessLocation: current.businessLocation,
      memberSince: current.memberSince,
    );
  }

  @override
  Future<void> recordVoiceActionAudit(VoiceActionAuditEvent event) async {
    final duplicate = _voiceActionAudits.any(
      (item) => item.actionId == event.actionId && item.status == event.status,
    );
    if (!duplicate) _voiceActionAudits.add(event);
  }

  @override
  Future<bool> hasSuccessfulVoiceAction({
    required String actionId,
    required String commandFingerprint,
  }) async {
    return _voiceActionAudits.any(
      (event) =>
          event.status == VoiceActionStatus.succeeded &&
          (event.actionId == actionId ||
              event.commandFingerprint == commandFingerprint),
    );
  }

  @override
  Future<VoiceCreateProductCommitResult> createProductFromVoice(
    VoiceCreateProductCommitRequest request,
  ) async {
    final current = _snapshot;
    if (current == null) {
      throw StateError('Repository belum diinisialisasi.');
    }
    if (!request.confirmed) {
      return const VoiceCreateProductCommitResult(
        status: VoiceCreateProductCommitStatus.notConfirmed,
      );
    }
    if (!DateTime.now().isBefore(request.expiresAt)) {
      return const VoiceCreateProductCommitResult(
        status: VoiceCreateProductCommitStatus.expired,
      );
    }
    final product = request.payload.product;
    final alreadyExecuted = _voiceActionAudits.any(
      (event) =>
          event.status == VoiceActionStatus.succeeded &&
          (event.actionId == request.actionId ||
              event.commandFingerprint == request.commandFingerprint),
    );
    if (alreadyExecuted) {
      Product? existingProduct;
      for (final candidate in current.products) {
        if (candidate.id == product.id) {
          existingProduct = candidate;
          break;
        }
      }
      return VoiceCreateProductCommitResult(
        status: VoiceCreateProductCommitStatus.alreadyExecuted,
        product: existingProduct,
      );
    }

    Product? duplicate;
    final normalizedName = normalizeProductName(product.name);
    for (final candidate in current.products) {
      if (candidate.id == product.id &&
          normalizeProductName(candidate.name) == normalizedName) {
        return VoiceCreateProductCommitResult(
          status: VoiceCreateProductCommitStatus.alreadyExecuted,
          product: candidate,
        );
      }
      if (normalizeProductName(candidate.name) == normalizedName) {
        duplicate = candidate;
        break;
      }
    }
    if (duplicate != null) {
      await recordVoiceActionAudit(request.duplicateRejected);
      return VoiceCreateProductCommitResult(
        status: VoiceCreateProductCommitStatus.duplicateProduct,
        existingProduct: duplicate,
      );
    }

    final previousSnapshot = current.copy();
    final previousAudits = List<VoiceActionAuditEvent>.of(_voiceActionAudits);
    try {
      _voiceActionAudits.add(request.executionStarted);
      final products = [...current.products, product];
      final categories = [...current.productCategories];
      if (!categories.any(
        (category) => category.toLowerCase() == product.category.toLowerCase(),
      )) {
        categories.insert(
          request.categoryPosition.clamp(0, categories.length).toInt(),
          product.category,
        );
      }
      _snapshot = _copyWithProductCategories(
        _copyWithProducts(current, products),
        categories,
      );
      _voiceActionAudits.add(request.succeeded);
      return VoiceCreateProductCommitResult(
        status: VoiceCreateProductCommitStatus.created,
        product: product,
      );
    } catch (_) {
      _snapshot = previousSnapshot;
      _voiceActionAudits
        ..clear()
        ..addAll(previousAudits);
      rethrow;
    }
  }

  @override
  Future<VoiceStockIncrementCommitResult> incrementProductStockFromVoice(
    VoiceStockIncrementCommitRequest request,
  ) async {
    final current = _snapshot;
    if (current == null) {
      throw StateError('Repository belum diinisialisasi.');
    }
    if (!request.confirmed) {
      return const VoiceStockIncrementCommitResult(
        status: VoiceStockIncrementCommitStatus.notConfirmed,
      );
    }
    if (!DateTime.now().isBefore(request.expiresAt)) {
      return const VoiceStockIncrementCommitResult(
        status: VoiceStockIncrementCommitStatus.expired,
      );
    }
    final alreadyExecuted = _voiceActionAudits.any(
      (event) =>
          event.status == VoiceActionStatus.succeeded &&
          (event.actionId == request.actionId ||
              event.commandFingerprint == request.commandFingerprint),
    );
    if (alreadyExecuted) {
      Product? product;
      for (final candidate in current.products) {
        if (candidate.id == request.payload.productId) {
          product = candidate;
          break;
        }
      }
      return VoiceStockIncrementCommitResult(
        status: VoiceStockIncrementCommitStatus.alreadyExecuted,
        product: product,
      );
    }

    final productIndex = current.products.indexWhere(
      (product) => product.id == request.payload.productId,
    );
    if (productIndex == -1) {
      return const VoiceStockIncrementCommitResult(
        status: VoiceStockIncrementCommitStatus.productNotFound,
      );
    }
    final latest = current.products[productIndex];
    final latestFingerprint = await const StableFingerprintService().create(
      stockMutationProductFingerprintSource(latest),
    );
    if (latestFingerprint != request.payload.productFingerprint) {
      return VoiceStockIncrementCommitResult(
        status: VoiceStockIncrementCommitStatus.stale,
        product: latest,
      );
    }
    final calculation = const StockIncrementCalculator().calculate(
      product: latest,
      requestedQuantity: request.payload.requestedQuantity,
      requestedUnit: request.payload.requestedUnit,
      trackingEnableConfirmed: request.payload.enableTracking,
    );
    if (calculation.status ==
        StockIncrementCalculationStatus.trackingConfirmationRequired) {
      return VoiceStockIncrementCommitResult(
        status: VoiceStockIncrementCommitStatus.trackingConfirmationRequired,
        product: latest,
      );
    }
    if (!calculation.isSuccess ||
        !_sameQuantity(
          calculation.normalizedQuantity!,
          request.payload.normalizedQuantity,
        ) ||
        !_sameQuantity(calculation.stockBefore!, request.payload.stockBefore) ||
        !_sameQuantity(calculation.stockAfter!, request.payload.stockAfter) ||
        calculation.baseUnit != request.payload.baseUnit) {
      return VoiceStockIncrementCommitResult(
        status: VoiceStockIncrementCommitStatus.stale,
        product: latest,
      );
    }

    final previousSnapshot = current.copy();
    final previousAudits = List<VoiceActionAuditEvent>.of(_voiceActionAudits);
    try {
      _voiceActionAudits.add(request.executionStarted);
      final trackingAudit = request.trackingEnableConfirmed;
      if (trackingAudit != null) _voiceActionAudits.add(trackingAudit);
      final updated = latest.copyWith(
        stockPcs: calculation.stockAfter!,
        trackStock: latest.trackStock || calculation.enableTracking,
        baseUnit: calculation.baseUnit!,
      );
      final products = [...current.products]..[productIndex] = updated;
      _snapshot = _copyWithProducts(current, products);
      _voiceActionAudits.add(request.succeeded);
      return VoiceStockIncrementCommitResult(
        status: VoiceStockIncrementCommitStatus.incremented,
        product: updated,
      );
    } catch (error) {
      _snapshot = previousSnapshot;
      _voiceActionAudits
        ..clear()
        ..addAll(previousAudits);
      throw VoiceStockIncrementCommitException(
        type: VoiceStockIncrementCommitFailureType.databaseFailure,
        cause: error,
      );
    }
  }

  @override
  Future<VoicePriceUpdateCommitResult> updateProductPriceFromVoice(
    VoicePriceUpdateCommitRequest request,
  ) async {
    final current = _snapshot;
    if (current == null) {
      throw StateError('Repository belum diinisialisasi.');
    }
    if (!request.confirmed) {
      return const VoicePriceUpdateCommitResult(
        status: VoicePriceUpdateCommitStatus.notConfirmed,
      );
    }
    if (!DateTime.now().isBefore(request.expiresAt)) {
      return const VoicePriceUpdateCommitResult(
        status: VoicePriceUpdateCommitStatus.expired,
      );
    }
    final payload = request.payload;
    if (payload.actionId != request.actionId ||
        payload.commandFingerprint != request.commandFingerprint ||
        payload.productId.trim().isEmpty) {
      return const VoicePriceUpdateCommitResult(
        status: VoicePriceUpdateCommitStatus.invalidPayload,
      );
    }
    if (payload.requiresAdditionalConfirmation &&
        !request.additionalConfirmationSucceeded) {
      return const VoicePriceUpdateCommitResult(
        status: VoicePriceUpdateCommitStatus.additionalConfirmationRequired,
      );
    }
    final alreadyExecuted = _voiceActionAudits.any(
      (event) =>
          event.status == VoiceActionStatus.succeeded &&
          (event.actionId == request.actionId ||
              event.commandFingerprint == request.commandFingerprint),
    );
    if (alreadyExecuted) {
      Product? product;
      for (final candidate in current.products) {
        if (candidate.id == payload.productId) {
          product = candidate;
          break;
        }
      }
      return VoicePriceUpdateCommitResult(
        status: VoicePriceUpdateCommitStatus.alreadyExecuted,
        product: product,
      );
    }

    final productIndex = current.products.indexWhere(
      (product) => product.id == payload.productId,
    );
    if (productIndex == -1) {
      return const VoicePriceUpdateCommitResult(
        status: VoicePriceUpdateCommitStatus.productNotFound,
      );
    }
    final latest = current.products[productIndex];
    final latestFingerprint = await const StableFingerprintService().create(
      priceMutationProductFingerprintSource(latest),
    );
    if (latestFingerprint != payload.productFingerprint ||
        latest.retailPrice != payload.retailPriceBefore ||
        latest.wholesalePrice != payload.wholesalePriceBefore ||
        latest.costPrice != payload.costPriceBefore ||
        payload.priceType.valueOf(latest) != payload.oldPrice) {
      return VoicePriceUpdateCommitResult(
        status: VoicePriceUpdateCommitStatus.stale,
        product: latest,
      );
    }
    final validation = const ProductPriceUpdateValidator().validate(
      product: latest,
      type: payload.priceType,
      newPrice: payload.newPrice,
    );
    if (validation.status == ProductPriceValidationStatus.samePrice) {
      return VoicePriceUpdateCommitResult(
        status: VoicePriceUpdateCommitStatus.samePrice,
        product: latest,
      );
    }
    if (!validation.isSuccess ||
        validation.oldPrice != payload.oldPrice ||
        validation.difference != payload.difference ||
        !_samePercentage(
          validation.percentageChange,
          payload.percentageChange,
        ) ||
        !_sameWarnings(validation.warnings, payload.warnings) ||
        validation.requiresAdditionalConfirmation !=
            payload.requiresAdditionalConfirmation) {
      return VoicePriceUpdateCommitResult(
        status: VoicePriceUpdateCommitStatus.invalidPayload,
        product: latest,
      );
    }
    final updated = payload.priceType.applyTo(latest, payload.newPrice);
    final afterFingerprint = await const StableFingerprintService().create(
      priceMutationProductFingerprintSource(updated),
    );
    if (afterFingerprint != payload.expectedProductFingerprintAfter) {
      return VoicePriceUpdateCommitResult(
        status: VoicePriceUpdateCommitStatus.invalidPayload,
        product: latest,
      );
    }

    final previousSnapshot = current.copy();
    final previousAudits = List<VoiceActionAuditEvent>.of(_voiceActionAudits);
    try {
      _voiceActionAudits.add(request.executionStarted);
      final products = [...current.products]..[productIndex] = updated;
      _snapshot = _copyWithProducts(current, products);
      _voiceActionAudits.add(request.succeeded);
      return VoicePriceUpdateCommitResult(
        status: VoicePriceUpdateCommitStatus.updated,
        product: updated,
      );
    } catch (error) {
      _snapshot = previousSnapshot;
      _voiceActionAudits
        ..clear()
        ..addAll(previousAudits);
      throw VoicePriceUpdateCommitException(
        type: VoicePriceUpdateCommitFailureType.databaseFailure,
        cause: error,
      );
    }
  }

  @override
  Future<VoicePriceUpdateUndoResult> undoProductPriceUpdate(
    VoicePriceUpdateUndoRequest request,
  ) async {
    final current = _snapshot;
    if (current == null) {
      throw StateError('Repository belum diinisialisasi.');
    }
    if (!_isValidPriceUndoRequest(request)) {
      return const VoicePriceUpdateUndoResult(
        status: VoicePriceUpdateUndoStatus.invalidRequest,
      );
    }

    final alreadyReversed = _voiceActionAudits.any(
      (event) =>
          event.status == VoiceActionStatus.undoSucceeded &&
          event.commandFingerprint == request.undoCommandFingerprint,
    );
    if (alreadyReversed) {
      return VoicePriceUpdateUndoResult(
        status: VoicePriceUpdateUndoStatus.alreadyReversed,
        product: _findProduct(current.products, request.productId),
      );
    }

    final originalSucceeded = _voiceActionAudits.any(
      (event) =>
          event.status == VoiceActionStatus.succeeded &&
          event.actionId == request.originalActionId &&
          event.commandFingerprint == request.originalCommandFingerprint &&
          event.targetEntityId == request.productId,
    );
    if (!originalSucceeded) {
      _recordMemoryUndoRejection(request, 'original_action_not_found');
      return const VoicePriceUpdateUndoResult(
        status: VoicePriceUpdateUndoStatus.originalActionNotFound,
      );
    }

    final productIndex = current.products.indexWhere(
      (product) => product.id == request.productId,
    );
    if (productIndex == -1) {
      _recordMemoryUndoRejection(request, 'product_not_found');
      return const VoicePriceUpdateUndoResult(
        status: VoicePriceUpdateUndoStatus.productNotFound,
      );
    }
    final latest = current.products[productIndex];
    final latestFingerprint = await const StableFingerprintService().create(
      priceMutationProductFingerprintSource(latest),
    );
    if (request.priceType.valueOf(latest) != request.newPrice ||
        latestFingerprint != request.expectedCurrentProductFingerprint) {
      _recordMemoryUndoRejection(request, 'newer_price_change_detected');
      return VoicePriceUpdateUndoResult(
        status: VoicePriceUpdateUndoStatus.stale,
        product: latest,
      );
    }

    final restored = request.priceType.applyTo(latest, request.oldPrice);
    final restoredFingerprint = await const StableFingerprintService().create(
      priceMutationProductFingerprintSource(restored),
    );
    if (restoredFingerprint != request.expectedRestoredProductFingerprint) {
      _recordMemoryUndoRejection(request, 'restored_fingerprint_mismatch');
      return VoicePriceUpdateUndoResult(
        status: VoicePriceUpdateUndoStatus.stale,
        product: latest,
      );
    }

    final previousSnapshot = current.copy();
    final previousAudits = List<VoiceActionAuditEvent>.of(_voiceActionAudits);
    try {
      _voiceActionAudits.add(request.requested);
      final products = [...current.products]..[productIndex] = restored;
      _snapshot = _copyWithProducts(current, products);
      _voiceActionAudits.add(request.succeeded);
      return VoicePriceUpdateUndoResult(
        status: VoicePriceUpdateUndoStatus.reverted,
        product: restored,
      );
    } catch (error) {
      _snapshot = previousSnapshot;
      _voiceActionAudits
        ..clear()
        ..addAll(previousAudits);
      throw VoicePriceUpdateUndoException(
        type: VoicePriceUpdateUndoFailureType.databaseFailure,
        cause: error,
      );
    }
  }

  void _recordMemoryUndoRejection(
    VoicePriceUpdateUndoRequest request,
    String errorCode,
  ) {
    final events = [request.requested, request.rejectionEvent(errorCode)];
    for (final event in events) {
      final duplicate = _voiceActionAudits.any(
        (item) =>
            item.actionId == event.actionId && item.status == event.status,
      );
      if (!duplicate) _voiceActionAudits.add(event);
    }
  }

  @override
  Future<List<VoiceActionAuditEvent>> loadVoiceActionAudits(
    String actionId,
  ) async {
    return _voiceActionAudits
        .where((event) => event.actionId == actionId)
        .toList(growable: false);
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
  Future<void> saveTransactionGraph({
    required TransactionRecord transaction,
    required Wallet wallet,
    required LedgerCategory category,
    List<Product> products = const [],
    Map<String, int> productCategoryPositions = const {},
  }) {
    return _localDataSource.upsertTransactionGraph(
      transaction: transaction,
      wallet: wallet,
      category: category,
      products: products,
      productCategoryPositions: productCategoryPositions,
    );
  }

  @override
  Future<void> recordVoiceLearning({
    List<VoiceProductAlias> productAliases = const [],
    List<VoiceUnitAlias> unitAliases = const [],
    List<VoiceCorrection> corrections = const [],
  }) {
    return _localDataSource.recordVoiceLearning(
      productAliases: productAliases,
      unitAliases: unitAliases,
      corrections: corrections,
    );
  }

  @override
  Future<void> recordVoiceActionAudit(VoiceActionAuditEvent event) {
    return _localDataSource.recordVoiceActionAudit(event);
  }

  @override
  Future<bool> hasSuccessfulVoiceAction({
    required String actionId,
    required String commandFingerprint,
  }) {
    return _localDataSource.hasSuccessfulVoiceAction(
      actionId: actionId,
      commandFingerprint: commandFingerprint,
    );
  }

  @override
  Future<VoiceCreateProductCommitResult> createProductFromVoice(
    VoiceCreateProductCommitRequest request,
  ) {
    return _localDataSource.createProductFromVoice(request);
  }

  @override
  Future<VoiceStockIncrementCommitResult> incrementProductStockFromVoice(
    VoiceStockIncrementCommitRequest request,
  ) {
    return _localDataSource.incrementProductStockFromVoice(request);
  }

  @override
  Future<VoicePriceUpdateCommitResult> updateProductPriceFromVoice(
    VoicePriceUpdateCommitRequest request,
  ) {
    return _localDataSource.updateProductPriceFromVoice(request);
  }

  @override
  Future<VoicePriceUpdateUndoResult> undoProductPriceUpdate(
    VoicePriceUpdateUndoRequest request,
  ) {
    return _localDataSource.undoProductPriceUpdate(request);
  }

  @override
  Future<List<VoiceActionAuditEvent>> loadVoiceActionAudits(String actionId) {
    return _localDataSource.readVoiceActionAudits(actionId);
  }

  @override
  Future<void> close() {
    return _localDataSource.close();
  }
}

bool _sameQuantity(double left, double right) {
  return QuantityFormatter.normalize(left) ==
      QuantityFormatter.normalize(right);
}

bool _samePercentage(double? left, double? right) {
  if (left == null || right == null) return left == right;
  return (left - right).abs() <= 0.000001;
}

bool _sameWarnings<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _isValidPriceUndoRequest(VoicePriceUpdateUndoRequest request) {
  if (request.undoActionId.trim().isEmpty ||
      request.undoCommandFingerprint.trim().isEmpty ||
      request.originalActionId.trim().isEmpty ||
      request.originalCommandFingerprint.trim().isEmpty ||
      request.productId.trim().isEmpty ||
      request.expectedCurrentProductFingerprint.trim().isEmpty ||
      request.expectedRestoredProductFingerprint.trim().isEmpty ||
      request.oldPrice < 0 ||
      request.newPrice < 0 ||
      request.oldPrice == request.newPrice) {
    return false;
  }
  return _isMatchingUndoAudit(
        request.requested,
        request,
        VoiceActionStatus.undoRequested,
      ) &&
      _isMatchingUndoAudit(
        request.succeeded,
        request,
        VoiceActionStatus.undoSucceeded,
      ) &&
      _isMatchingUndoAudit(
        request.rejected,
        request,
        VoiceActionStatus.undoRejected,
      );
}

bool _isMatchingUndoAudit(
  VoiceActionAuditEvent event,
  VoicePriceUpdateUndoRequest request,
  VoiceActionStatus status,
) {
  return event.actionId == request.undoActionId &&
      event.commandFingerprint == request.undoCommandFingerprint &&
      event.actionType == VoiceActionType.updateProductPrice &&
      event.targetEntityId == request.productId &&
      event.status == status;
}

Product? _findProduct(List<Product> products, String productId) {
  for (final product in products) {
    if (product.id == productId) return product;
  }
  return null;
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
    voiceProductAliases: snapshot.voiceProductAliases,
    voiceUnitAliases: snapshot.voiceUnitAliases,
    voiceCorrections: snapshot.voiceCorrections,
    pinEnabled: snapshot.pinEnabled,
    biometricEnabled: snapshot.biometricEnabled,
    cloudSyncEnabled: snapshot.cloudSyncEnabled,
    supabaseUrl: snapshot.supabaseUrl,
    queuedSyncCount: snapshot.queuedSyncCount,
    language: snapshot.language,
    voiceSensitivity: snapshot.voiceSensitivity,
    handsfreeWakeWordEnabled: snapshot.handsfreeWakeWordEnabled,
    silentTimeoutSeconds: snapshot.silentTimeoutSeconds,
    enableVoiceLearning: snapshot.enableVoiceLearning,
    voiceFinancialPrivacyEnabled: snapshot.voiceFinancialPrivacyEnabled,
    maskVoiceFinancialValues: snapshot.maskVoiceFinancialValues,
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
    voiceProductAliases: snapshot.voiceProductAliases,
    voiceUnitAliases: snapshot.voiceUnitAliases,
    voiceCorrections: snapshot.voiceCorrections,
    pinEnabled: snapshot.pinEnabled,
    biometricEnabled: snapshot.biometricEnabled,
    cloudSyncEnabled: snapshot.cloudSyncEnabled,
    supabaseUrl: snapshot.supabaseUrl,
    queuedSyncCount: snapshot.queuedSyncCount,
    language: snapshot.language,
    voiceSensitivity: snapshot.voiceSensitivity,
    handsfreeWakeWordEnabled: snapshot.handsfreeWakeWordEnabled,
    silentTimeoutSeconds: snapshot.silentTimeoutSeconds,
    enableVoiceLearning: snapshot.enableVoiceLearning,
    voiceFinancialPrivacyEnabled: snapshot.voiceFinancialPrivacyEnabled,
    maskVoiceFinancialValues: snapshot.maskVoiceFinancialValues,
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
    voiceProductAliases: snapshot.voiceProductAliases,
    voiceUnitAliases: snapshot.voiceUnitAliases,
    voiceCorrections: snapshot.voiceCorrections,
    pinEnabled: snapshot.pinEnabled,
    biometricEnabled: snapshot.biometricEnabled,
    cloudSyncEnabled: snapshot.cloudSyncEnabled,
    supabaseUrl: snapshot.supabaseUrl,
    queuedSyncCount: snapshot.queuedSyncCount,
    language: snapshot.language,
    voiceSensitivity: snapshot.voiceSensitivity,
    handsfreeWakeWordEnabled: snapshot.handsfreeWakeWordEnabled,
    silentTimeoutSeconds: snapshot.silentTimeoutSeconds,
    enableVoiceLearning: snapshot.enableVoiceLearning,
    voiceFinancialPrivacyEnabled: snapshot.voiceFinancialPrivacyEnabled,
    maskVoiceFinancialValues: snapshot.maskVoiceFinancialValues,
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
    voiceProductAliases: snapshot.voiceProductAliases,
    voiceUnitAliases: snapshot.voiceUnitAliases,
    voiceCorrections: snapshot.voiceCorrections,
    pinEnabled: snapshot.pinEnabled,
    biometricEnabled: snapshot.biometricEnabled,
    cloudSyncEnabled: snapshot.cloudSyncEnabled,
    supabaseUrl: snapshot.supabaseUrl,
    queuedSyncCount: snapshot.queuedSyncCount,
    language: snapshot.language,
    voiceSensitivity: snapshot.voiceSensitivity,
    handsfreeWakeWordEnabled: snapshot.handsfreeWakeWordEnabled,
    silentTimeoutSeconds: snapshot.silentTimeoutSeconds,
    enableVoiceLearning: snapshot.enableVoiceLearning,
    voiceFinancialPrivacyEnabled: snapshot.voiceFinancialPrivacyEnabled,
    maskVoiceFinancialValues: snapshot.maskVoiceFinancialValues,
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
    voiceProductAliases: snapshot.voiceProductAliases,
    voiceUnitAliases: snapshot.voiceUnitAliases,
    voiceCorrections: snapshot.voiceCorrections,
    pinEnabled: snapshot.pinEnabled,
    biometricEnabled: snapshot.biometricEnabled,
    cloudSyncEnabled: snapshot.cloudSyncEnabled,
    supabaseUrl: snapshot.supabaseUrl,
    queuedSyncCount: snapshot.queuedSyncCount,
    language: snapshot.language,
    voiceSensitivity: snapshot.voiceSensitivity,
    handsfreeWakeWordEnabled: snapshot.handsfreeWakeWordEnabled,
    silentTimeoutSeconds: snapshot.silentTimeoutSeconds,
    enableVoiceLearning: snapshot.enableVoiceLearning,
    voiceFinancialPrivacyEnabled: snapshot.voiceFinancialPrivacyEnabled,
    maskVoiceFinancialValues: snapshot.maskVoiceFinancialValues,
    ownerName: snapshot.ownerName,
    email: snapshot.email,
    phone: snapshot.phone,
    businessName: snapshot.businessName,
    businessCategory: snapshot.businessCategory,
    businessLocation: snapshot.businessLocation,
    memberSince: snapshot.memberSince,
  );
}

List<VoiceProductAlias> _mergeProductAliases(
  List<VoiceProductAlias> current,
  List<VoiceProductAlias> incoming,
) {
  final byKey = {for (final alias in current) alias.normalizedAlias: alias};
  for (final alias in incoming) {
    final existing = byKey[alias.normalizedAlias];
    byKey[alias.normalizedAlias] = existing == null
        ? alias
        : alias.copyWith(
            hitCount: alias.hitCount > existing.hitCount
                ? alias.hitCount
                : existing.hitCount + alias.hitCount,
            createdAt: existing.createdAt,
          );
  }
  return byKey.values.toList();
}

List<VoiceUnitAlias> _mergeUnitAliases(
  List<VoiceUnitAlias> current,
  List<VoiceUnitAlias> incoming,
) {
  final byKey = {for (final alias in current) alias.normalizedAlias: alias};
  for (final alias in incoming) {
    final existing = byKey[alias.normalizedAlias];
    byKey[alias.normalizedAlias] = existing == null
        ? alias
        : alias.copyWith(
            hitCount: alias.hitCount > existing.hitCount
                ? alias.hitCount
                : existing.hitCount + alias.hitCount,
            createdAt: existing.createdAt,
          );
  }
  return byKey.values.toList();
}
