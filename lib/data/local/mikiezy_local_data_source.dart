import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_seed_service.dart';
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
    final productAliasRows = await _database
        .select(_database.voiceProductAliases)
        .get();
    final unitAliasRows = await _database
        .select(_database.voiceUnitAliases)
        .get();
    final correctionRows = await _database
        .select(_database.voiceCorrections)
        .get();
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
      voiceProductAliases: productAliasRows.map(_productAliasFromRow).toList(),
      voiceUnitAliases: unitAliasRows.map(_unitAliasFromRow).toList(),
      voiceCorrections: correctionRows.map(_correctionFromRow).toList(),
      onboardingCompleted: settings.containsKey(_SettingKey.onboardingCompleted)
          ? (bool.tryParse(settings[_SettingKey.onboardingCompleted]!) ??
                fallback.onboardingCompleted)
          : (settings[_SettingKey.pinEnabled] == 'true' ||
                fallback.onboardingCompleted),
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
      enableVoiceLearning: _boolSetting(
        settings,
        _SettingKey.enableVoiceLearning,
        fallback.enableVoiceLearning,
      ),
      voiceFinancialPrivacyEnabled: _boolSetting(
        settings,
        _SettingKey.voiceFinancialPrivacyEnabled,
        fallback.voiceFinancialPrivacyEnabled,
      ),
      maskVoiceFinancialValues: _boolSetting(
        settings,
        _SettingKey.maskVoiceFinancialValues,
        fallback.maskVoiceFinancialValues,
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
      await _database.delete(_database.voiceCorrections).go();
      await _database.delete(_database.voiceUnitAliases).go();
      await _database.delete(_database.voiceProductAliases).go();
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
        batch.insertAll(
          _database.voiceProductAliases,
          snapshot.voiceProductAliases.map(_productAliasToCompanion),
        );
        batch.insertAll(
          _database.voiceUnitAliases,
          snapshot.voiceUnitAliases.map(_unitAliasToCompanion),
        );
        batch.insertAll(
          _database.voiceCorrections,
          snapshot.voiceCorrections.map(_correctionToCompanion),
        );
      });
    });
  }

  Future<void> recordVoiceLearning({
    List<VoiceProductAlias> productAliases = const [],
    List<VoiceUnitAlias> unitAliases = const [],
    List<VoiceCorrection> corrections = const [],
  }) {
    if (productAliases.isEmpty && unitAliases.isEmpty && corrections.isEmpty) {
      return Future.value();
    }
    return _database.transaction(() async {
      await _database.batch((batch) {
        batch.insertAllOnConflictUpdate(
          _database.voiceProductAliases,
          productAliases.map(_productAliasToCompanion),
        );
        batch.insertAllOnConflictUpdate(
          _database.voiceUnitAliases,
          unitAliases.map(_unitAliasToCompanion),
        );
        batch.insertAll(
          _database.voiceCorrections,
          corrections.map(_correctionToCompanion),
          mode: InsertMode.insertOrIgnore,
        );
      });
    });
  }

  Future<void> recordVoiceActionAudit(VoiceActionAuditEvent event) {
    return _database
        .into(_database.voiceActionAudits)
        .insert(
          _voiceActionAuditToCompanion(event),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<bool> hasSuccessfulVoiceAction({
    required String actionId,
    required String commandFingerprint,
  }) async {
    final row =
        await (_database.select(_database.voiceActionAudits)
              ..where(
                (table) =>
                    table.status.equals(VoiceActionStatus.succeeded.name) &
                    (table.actionId.equals(actionId) |
                        table.commandFingerprint.equals(commandFingerprint)),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<VoiceCreateProductCommitResult> createProductFromVoice(
    VoiceCreateProductCommitRequest request,
  ) async {
    var stage = _VoiceCreateProductCommitStage.preflight;
    try {
      return await _database.transaction(() async {
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
        final successfulRows =
            await (_database.select(_database.voiceActionAudits)..where(
                  (table) =>
                      table.status.equals(VoiceActionStatus.succeeded.name) &
                      (table.actionId.equals(request.actionId) |
                          table.commandFingerprint.equals(
                            request.commandFingerprint,
                          )),
                ))
                .get();
        if (successfulRows.isNotEmpty) {
          final existingById = await (_database.select(
            _database.products,
          )..where((table) => table.id.equals(product.id))).getSingleOrNull();
          return VoiceCreateProductCommitResult(
            status: VoiceCreateProductCommitStatus.alreadyExecuted,
            product: existingById == null
                ? null
                : _productFromRow(existingById),
          );
        }

        Product? duplicate;
        final normalizedName = normalizeProductName(product.name);
        final activeRows = await _readProductRows();
        for (final row in activeRows) {
          if (row.id == product.id &&
              normalizeProductName(row.name) == normalizedName) {
            return VoiceCreateProductCommitResult(
              status: VoiceCreateProductCommitStatus.alreadyExecuted,
              product: _productFromRow(row),
            );
          }
          if (normalizeProductName(row.name) == normalizedName) {
            duplicate = _productFromRow(row);
            break;
          }
        }
        if (duplicate != null) {
          stage = _VoiceCreateProductCommitStage.duplicateAudit;
          await _database
              .into(_database.voiceActionAudits)
              .insert(
                _voiceActionAuditToCompanion(request.duplicateRejected),
                mode: InsertMode.insertOrIgnore,
              );
          return VoiceCreateProductCommitResult(
            status: VoiceCreateProductCommitStatus.duplicateProduct,
            existingProduct: duplicate,
          );
        }

        final now = DateTime.now();
        final categoryName = _cleanName(
          product.category,
          fallback: 'Lain-lain',
        );
        stage = _VoiceCreateProductCommitStage.startedAudit;
        await _database
            .into(_database.voiceActionAudits)
            .insert(_voiceActionAuditToCompanion(request.executionStarted));
        stage = _VoiceCreateProductCommitStage.categoryInsert;
        await _database
            .into(_database.productCategories)
            .insertOnConflictUpdate(
              ProductCategoriesCompanion.insert(
                id: _productCategoryId(categoryName),
                name: categoryName,
                position: Value(request.categoryPosition),
                updatedAt: Value(now),
                syncStatus: const Value('queued'),
              ),
            );
        stage = _VoiceCreateProductCommitStage.productInsert;
        await _database
            .into(_database.products)
            .insert(
              _productToCompanion(product, now, syncStatus: 'queued'),
              mode: InsertMode.insert,
            );
        stage = _VoiceCreateProductCommitStage.succeededAudit;
        await _database
            .into(_database.voiceActionAudits)
            .insert(_voiceActionAuditToCompanion(request.succeeded));
        return VoiceCreateProductCommitResult(
          status: VoiceCreateProductCommitStatus.created,
          product: product,
        );
      });
    } catch (error) {
      final auditStage =
          stage == _VoiceCreateProductCommitStage.startedAudit ||
          stage == _VoiceCreateProductCommitStage.succeededAudit ||
          stage == _VoiceCreateProductCommitStage.duplicateAudit;
      throw VoiceCreateProductCommitException(
        type: auditStage
            ? VoiceCreateProductCommitFailureType.auditFailure
            : VoiceCreateProductCommitFailureType.databaseFailure,
        cause: error,
      );
    }
  }

  Future<VoiceStockIncrementCommitResult> incrementProductStockFromVoice(
    VoiceStockIncrementCommitRequest request,
  ) async {
    var stage = _VoiceStockIncrementCommitStage.preflight;
    try {
      return await _database.transaction(() async {
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
        final payload = request.payload;
        if (payload.actionId != request.actionId ||
            payload.commandFingerprint != request.commandFingerprint ||
            payload.productId.trim().isEmpty) {
          return const VoiceStockIncrementCommitResult(
            status: VoiceStockIncrementCommitStatus.invalidPayload,
          );
        }

        final successfulRows =
            await (_database.select(_database.voiceActionAudits)..where(
                  (table) =>
                      table.status.equals(VoiceActionStatus.succeeded.name) &
                      (table.actionId.equals(request.actionId) |
                          table.commandFingerprint.equals(
                            request.commandFingerprint,
                          )),
                ))
                .get();
        if (successfulRows.isNotEmpty) {
          final existing =
              await (_database.select(_database.products)..where(
                    (table) =>
                        table.id.equals(payload.productId) &
                        table.deletedAt.isNull(),
                  ))
                  .getSingleOrNull();
          return VoiceStockIncrementCommitResult(
            status: VoiceStockIncrementCommitStatus.alreadyExecuted,
            product: existing == null ? null : _productFromRow(existing),
          );
        }

        final row =
            await (_database.select(_database.products)..where(
                  (table) =>
                      table.id.equals(payload.productId) &
                      table.deletedAt.isNull(),
                ))
                .getSingleOrNull();
        if (row == null) {
          return const VoiceStockIncrementCommitResult(
            status: VoiceStockIncrementCommitStatus.productNotFound,
          );
        }
        final latest = _productFromRow(row);
        final latestFingerprint = await const StableFingerprintService().create(
          stockMutationProductFingerprintSource(latest),
        );
        if (latestFingerprint != payload.productFingerprint ||
            !_sameStockQuantity(latest.stockPcs, payload.stockBefore) ||
            latest.trackStock != payload.trackStockBefore ||
            latest.baseUnit != payload.baseUnitBefore ||
            latest.packSize != payload.packSize ||
            latest.cartonSize != payload.cartonSize) {
          return VoiceStockIncrementCommitResult(
            status: VoiceStockIncrementCommitStatus.stale,
            product: latest,
          );
        }

        final calculation = const StockIncrementCalculator().calculate(
          product: latest,
          requestedQuantity: payload.requestedQuantity,
          requestedUnit: payload.requestedUnit,
          trackingEnableConfirmed: payload.enableTracking,
        );
        if (calculation.status ==
            StockIncrementCalculationStatus.trackingConfirmationRequired) {
          return VoiceStockIncrementCommitResult(
            status:
                VoiceStockIncrementCommitStatus.trackingConfirmationRequired,
            product: latest,
          );
        }
        if (!calculation.isSuccess) {
          return VoiceStockIncrementCommitResult(
            status: VoiceStockIncrementCommitStatus.invalidPayload,
            product: latest,
          );
        }
        if (!_sameStockQuantity(
              calculation.normalizedQuantity!,
              payload.normalizedQuantity,
            ) ||
            !_sameStockQuantity(
              calculation.stockBefore!,
              payload.stockBefore,
            ) ||
            !_sameStockQuantity(calculation.stockAfter!, payload.stockAfter) ||
            calculation.baseUnit != payload.baseUnit ||
            calculation.enableTracking != payload.enableTracking) {
          return VoiceStockIncrementCommitResult(
            status: VoiceStockIncrementCommitStatus.stale,
            product: latest,
          );
        }

        stage = _VoiceStockIncrementCommitStage.startedAudit;
        await _database
            .into(_database.voiceActionAudits)
            .insert(_voiceActionAuditToCompanion(request.executionStarted));
        final trackingAudit = request.trackingEnableConfirmed;
        if (trackingAudit != null) {
          stage = _VoiceStockIncrementCommitStage.trackingAudit;
          await _database
              .into(_database.voiceActionAudits)
              .insert(_voiceActionAuditToCompanion(trackingAudit));
        }

        stage = _VoiceStockIncrementCommitStage.productUpdate;
        final updatedAt = DateTime.now();
        final affected =
            await (_database.update(_database.products)..where(
                  (table) =>
                      table.id.equals(payload.productId) &
                      table.deletedAt.isNull(),
                ))
                .write(
                  ProductsCompanion(
                    stockPcs: Value(calculation.stockAfter!),
                    trackStock: Value(
                      latest.trackStock || calculation.enableTracking,
                    ),
                    baseUnit: Value(calculation.baseUnit!.name),
                    updatedAt: Value(updatedAt),
                    syncStatus: const Value('queued'),
                  ),
                );
        if (affected != 1) {
          throw StateError('Produk tidak dapat diperbarui secara atomik.');
        }

        stage = _VoiceStockIncrementCommitStage.succeededAudit;
        await _database
            .into(_database.voiceActionAudits)
            .insert(_voiceActionAuditToCompanion(request.succeeded));
        return VoiceStockIncrementCommitResult(
          status: VoiceStockIncrementCommitStatus.incremented,
          product: latest.copyWith(
            stockPcs: calculation.stockAfter!,
            trackStock: latest.trackStock || calculation.enableTracking,
            baseUnit: calculation.baseUnit!,
          ),
        );
      });
    } catch (error) {
      final auditStage =
          stage == _VoiceStockIncrementCommitStage.startedAudit ||
          stage == _VoiceStockIncrementCommitStage.trackingAudit ||
          stage == _VoiceStockIncrementCommitStage.succeededAudit;
      throw VoiceStockIncrementCommitException(
        type: auditStage
            ? VoiceStockIncrementCommitFailureType.auditFailure
            : VoiceStockIncrementCommitFailureType.databaseFailure,
        cause: error,
      );
    }
  }

  Future<VoicePriceUpdateCommitResult> updateProductPriceFromVoice(
    VoicePriceUpdateCommitRequest request,
  ) async {
    var stage = _VoicePriceUpdateCommitStage.preflight;
    try {
      return await _database.transaction(() async {
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

        final successfulRows =
            await (_database.select(_database.voiceActionAudits)..where(
                  (table) =>
                      table.status.equals(VoiceActionStatus.succeeded.name) &
                      (table.actionId.equals(request.actionId) |
                          table.commandFingerprint.equals(
                            request.commandFingerprint,
                          )),
                ))
                .get();
        if (successfulRows.isNotEmpty) {
          final existing =
              await (_database.select(_database.products)..where(
                    (table) =>
                        table.id.equals(payload.productId) &
                        table.deletedAt.isNull(),
                  ))
                  .getSingleOrNull();
          return VoicePriceUpdateCommitResult(
            status: VoicePriceUpdateCommitStatus.alreadyExecuted,
            product: existing == null ? null : _productFromRow(existing),
          );
        }

        final row =
            await (_database.select(_database.products)..where(
                  (table) =>
                      table.id.equals(payload.productId) &
                      table.deletedAt.isNull(),
                ))
                .getSingleOrNull();
        if (row == null) {
          return const VoicePriceUpdateCommitResult(
            status: VoicePriceUpdateCommitStatus.productNotFound,
          );
        }
        final latest = _productFromRow(row);
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
            !_samePricePercentage(
              validation.percentageChange,
              payload.percentageChange,
            ) ||
            !_samePriceWarnings(validation.warnings, payload.warnings) ||
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

        stage = _VoicePriceUpdateCommitStage.startedAudit;
        await _database
            .into(_database.voiceActionAudits)
            .insert(_voiceActionAuditToCompanion(request.executionStarted));

        stage = _VoicePriceUpdateCommitStage.productUpdate;
        final updatedAt = DateTime.now();
        final priceCompanion = switch (payload.priceType) {
          ProductPriceType.retail => ProductsCompanion(
            retailPrice: Value(payload.newPrice),
            updatedAt: Value(updatedAt),
            syncStatus: const Value('queued'),
          ),
          ProductPriceType.wholesale => ProductsCompanion(
            wholesalePrice: Value(payload.newPrice),
            updatedAt: Value(updatedAt),
            syncStatus: const Value('queued'),
          ),
          ProductPriceType.cost => ProductsCompanion(
            costPrice: Value(payload.newPrice),
            updatedAt: Value(updatedAt),
            syncStatus: const Value('queued'),
          ),
        };
        final affected =
            await (_database.update(_database.products)..where(
                  (table) =>
                      table.id.equals(payload.productId) &
                      table.deletedAt.isNull(),
                ))
                .write(priceCompanion);
        if (affected != 1) {
          throw StateError(
            'Harga produk tidak dapat diperbarui secara atomik.',
          );
        }

        stage = _VoicePriceUpdateCommitStage.succeededAudit;
        await _database
            .into(_database.voiceActionAudits)
            .insert(_voiceActionAuditToCompanion(request.succeeded));
        return VoicePriceUpdateCommitResult(
          status: VoicePriceUpdateCommitStatus.updated,
          product: updated,
        );
      });
    } catch (error) {
      final auditStage =
          stage == _VoicePriceUpdateCommitStage.startedAudit ||
          stage == _VoicePriceUpdateCommitStage.succeededAudit;
      throw VoicePriceUpdateCommitException(
        type: auditStage
            ? VoicePriceUpdateCommitFailureType.auditFailure
            : VoicePriceUpdateCommitFailureType.databaseFailure,
        cause: error,
      );
    }
  }

  Future<VoicePriceUpdateUndoResult> undoProductPriceUpdate(
    VoicePriceUpdateUndoRequest request,
  ) async {
    var stage = _VoicePriceUpdateUndoStage.preflight;
    try {
      return await _database.transaction(() async {
        if (!_isValidPriceUndoEnvelope(request)) {
          return const VoicePriceUpdateUndoResult(
            status: VoicePriceUpdateUndoStatus.invalidRequest,
          );
        }

        final reversedRows =
            await (_database.select(_database.voiceActionAudits)..where(
                  (table) =>
                      table.status.equals(
                        VoiceActionStatus.undoSucceeded.name,
                      ) &
                      table.commandFingerprint.equals(
                        request.undoCommandFingerprint,
                      ),
                ))
                .get();
        if (reversedRows.isNotEmpty) {
          final existing =
              await (_database.select(_database.products)..where(
                    (table) =>
                        table.id.equals(request.productId) &
                        table.deletedAt.isNull(),
                  ))
                  .getSingleOrNull();
          return VoicePriceUpdateUndoResult(
            status: VoicePriceUpdateUndoStatus.alreadyReversed,
            product: existing == null ? null : _productFromRow(existing),
          );
        }

        stage = _VoicePriceUpdateUndoStage.requestedAudit;
        await _database
            .into(_database.voiceActionAudits)
            .insert(_voiceActionAuditToCompanion(request.requested));
        stage = _VoicePriceUpdateUndoStage.verification;

        final originalSuccess =
            await (_database.select(_database.voiceActionAudits)..where(
                  (table) =>
                      table.status.equals(VoiceActionStatus.succeeded.name) &
                      table.actionId.equals(request.originalActionId) &
                      table.commandFingerprint.equals(
                        request.originalCommandFingerprint,
                      ) &
                      table.targetEntityId.equals(request.productId),
                ))
                .getSingleOrNull();
        if (originalSuccess == null) {
          stage = _VoicePriceUpdateUndoStage.rejectedAudit;
          await _database
              .into(_database.voiceActionAudits)
              .insert(
                _voiceActionAuditToCompanion(
                  request.rejectionEvent('original_action_not_found'),
                ),
              );
          return const VoicePriceUpdateUndoResult(
            status: VoicePriceUpdateUndoStatus.originalActionNotFound,
          );
        }

        final row =
            await (_database.select(_database.products)..where(
                  (table) =>
                      table.id.equals(request.productId) &
                      table.deletedAt.isNull(),
                ))
                .getSingleOrNull();
        if (row == null) {
          stage = _VoicePriceUpdateUndoStage.rejectedAudit;
          await _database
              .into(_database.voiceActionAudits)
              .insert(
                _voiceActionAuditToCompanion(
                  request.rejectionEvent('product_not_found'),
                ),
              );
          return const VoicePriceUpdateUndoResult(
            status: VoicePriceUpdateUndoStatus.productNotFound,
          );
        }

        final latest = _productFromRow(row);
        final latestFingerprint = await const StableFingerprintService().create(
          priceMutationProductFingerprintSource(latest),
        );
        if (request.priceType.valueOf(latest) != request.newPrice ||
            latestFingerprint != request.expectedCurrentProductFingerprint) {
          stage = _VoicePriceUpdateUndoStage.rejectedAudit;
          await _database
              .into(_database.voiceActionAudits)
              .insert(
                _voiceActionAuditToCompanion(
                  request.rejectionEvent('newer_price_change_detected'),
                ),
              );
          return VoicePriceUpdateUndoResult(
            status: VoicePriceUpdateUndoStatus.stale,
            product: latest,
          );
        }

        final restored = request.priceType.applyTo(latest, request.oldPrice);
        final restoredFingerprint = await const StableFingerprintService()
            .create(priceMutationProductFingerprintSource(restored));
        if (restoredFingerprint != request.expectedRestoredProductFingerprint) {
          stage = _VoicePriceUpdateUndoStage.rejectedAudit;
          await _database
              .into(_database.voiceActionAudits)
              .insert(
                _voiceActionAuditToCompanion(
                  request.rejectionEvent('restored_fingerprint_mismatch'),
                ),
              );
          return VoicePriceUpdateUndoResult(
            status: VoicePriceUpdateUndoStatus.stale,
            product: latest,
          );
        }

        stage = _VoicePriceUpdateUndoStage.productUpdate;
        final updatedAt = DateTime.now();
        final priceCompanion = switch (request.priceType) {
          ProductPriceType.retail => ProductsCompanion(
            retailPrice: Value(request.oldPrice),
            updatedAt: Value(updatedAt),
            syncStatus: const Value('queued'),
          ),
          ProductPriceType.wholesale => ProductsCompanion(
            wholesalePrice: Value(request.oldPrice),
            updatedAt: Value(updatedAt),
            syncStatus: const Value('queued'),
          ),
          ProductPriceType.cost => ProductsCompanion(
            costPrice: Value(request.oldPrice),
            updatedAt: Value(updatedAt),
            syncStatus: const Value('queued'),
          ),
        };
        final affected =
            await (_database.update(_database.products)..where(
                  (table) =>
                      table.id.equals(request.productId) &
                      table.deletedAt.isNull(),
                ))
                .write(priceCompanion);
        if (affected != 1) {
          throw StateError(
            'Undo harga produk tidak dapat diterapkan secara atomik.',
          );
        }

        stage = _VoicePriceUpdateUndoStage.succeededAudit;
        await _database
            .into(_database.voiceActionAudits)
            .insert(_voiceActionAuditToCompanion(request.succeeded));
        return VoicePriceUpdateUndoResult(
          status: VoicePriceUpdateUndoStatus.reverted,
          product: restored,
        );
      });
    } catch (error) {
      final auditStage =
          stage == _VoicePriceUpdateUndoStage.requestedAudit ||
          stage == _VoicePriceUpdateUndoStage.rejectedAudit ||
          stage == _VoicePriceUpdateUndoStage.succeededAudit;
      throw VoicePriceUpdateUndoException(
        type: auditStage
            ? VoicePriceUpdateUndoFailureType.auditFailure
            : VoicePriceUpdateUndoFailureType.databaseFailure,
        cause: error,
      );
    }
  }

  Future<List<VoiceActionAuditEvent>> readVoiceActionAudits(
    String actionId,
  ) async {
    final rows =
        await (_database.select(_database.voiceActionAudits)
              ..where((table) => table.actionId.equals(actionId))
              ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
            .get();
    return rows.map(_voiceActionAuditFromRow).toList(growable: false);
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

  Future<void> upsertTransactionGraph({
    required TransactionRecord transaction,
    required Wallet wallet,
    required LedgerCategory category,
    List<Product> products = const [],
    Map<String, int> productCategoryPositions = const {},
  }) async {
    final now = DateTime.now();
    await _database.transaction(() async {
      for (final product in products) {
        final categoryName = _cleanName(
          product.category,
          fallback: 'Lain-lain',
        );
        final position =
            productCategoryPositions[product.category] ??
            productCategoryPositions[categoryName] ??
            0;
        await _database
            .into(_database.productCategories)
            .insertOnConflictUpdate(
              ProductCategoriesCompanion.insert(
                id: _productCategoryId(categoryName),
                name: categoryName,
                position: Value(position),
                updatedAt: Value(now),
                syncStatus: const Value('queued'),
              ),
            );
        await _database
            .into(_database.products)
            .insertOnConflictUpdate(_productToCompanion(product, now));
      }
      await _database
          .into(_database.transactionCategories)
          .insertOnConflictUpdate(
            _transactionCategoryToCompanion(category, now),
          );
      await _database
          .into(_database.wallets)
          .insertOnConflictUpdate(_walletToCompanion(wallet, now));
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

  ProductsCompanion _productToCompanion(
    Product product,
    DateTime now, {
    String syncStatus = 'localOnly',
  }) {
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
      trackStock: Value(product.trackStock),
      baseUnit: Value(product.baseUnit.name),
      minStock: Value(product.minStock),
      updatedAt: Value(now),
      syncStatus: Value(syncStatus),
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
      _SettingKey.onboardingCompleted: snapshot.onboardingCompleted.toString(),
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
      _SettingKey.enableVoiceLearning: snapshot.enableVoiceLearning.toString(),
      _SettingKey.voiceFinancialPrivacyEnabled: snapshot
          .voiceFinancialPrivacyEnabled
          .toString(),
      _SettingKey.maskVoiceFinancialValues: snapshot.maskVoiceFinancialValues
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
      trackStock: row.trackStock,
      baseUnit: _enumByName(SaleUnit.values, row.baseUnit, SaleUnit.pcs),
      minStock: row.minStock < 0 ? 0 : row.minStock,
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
      unitMultiplier: row.unitMultiplier <= 0 ? 1 : row.unitMultiplier,
    );
  }

  VoiceProductAlias _productAliasFromRow(VoiceProductAliasRow row) {
    return VoiceProductAlias(
      id: row.id,
      aliasText: row.aliasText,
      normalizedAlias: row.normalizedAlias,
      productId: row.productId,
      canonicalProductName: row.canonicalProductName,
      hitCount: row.hitCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  VoiceProductAliasesCompanion _productAliasToCompanion(
    VoiceProductAlias alias,
  ) {
    return VoiceProductAliasesCompanion.insert(
      id: alias.id,
      aliasText: alias.aliasText,
      normalizedAlias: alias.normalizedAlias,
      productId: Value(alias.productId),
      canonicalProductName: alias.canonicalProductName,
      hitCount: Value(alias.hitCount),
      createdAt: Value(alias.createdAt),
      updatedAt: Value(alias.updatedAt),
    );
  }

  VoiceUnitAlias _unitAliasFromRow(VoiceUnitAliasRow row) {
    return VoiceUnitAlias(
      id: row.id,
      aliasText: row.aliasText,
      normalizedAlias: row.normalizedAlias,
      canonicalUnit: row.canonicalUnit,
      hitCount: row.hitCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  VoiceUnitAliasesCompanion _unitAliasToCompanion(VoiceUnitAlias alias) {
    return VoiceUnitAliasesCompanion.insert(
      id: alias.id,
      aliasText: alias.aliasText,
      normalizedAlias: alias.normalizedAlias,
      canonicalUnit: alias.canonicalUnit,
      hitCount: Value(alias.hitCount),
      createdAt: Value(alias.createdAt),
      updatedAt: Value(alias.updatedAt),
    );
  }

  VoiceCorrection _correctionFromRow(VoiceCorrectionRow row) {
    return VoiceCorrection(
      id: row.id,
      rawText: row.rawText,
      parsedProductName: row.parsedProductName,
      correctedProductName: row.correctedProductName,
      parsedUnit: row.parsedUnit,
      correctedUnit: row.correctedUnit,
      parsedQuantity: row.parsedQuantity,
      correctedQuantity: row.correctedQuantity,
      createdAt: row.createdAt,
    );
  }

  VoiceCorrectionsCompanion _correctionToCompanion(VoiceCorrection correction) {
    return VoiceCorrectionsCompanion.insert(
      id: correction.id,
      rawText: correction.rawText,
      parsedProductName: Value(correction.parsedProductName),
      correctedProductName: correction.correctedProductName,
      parsedUnit: Value(correction.parsedUnit),
      correctedUnit: correction.correctedUnit,
      parsedQuantity: Value(correction.parsedQuantity),
      correctedQuantity: correction.correctedQuantity,
      createdAt: Value(correction.createdAt),
    );
  }

  VoiceActionAuditEvent _voiceActionAuditFromRow(VoiceActionAuditRow row) {
    return VoiceActionAuditEvent(
      id: row.id,
      actionId: row.actionId,
      actionType: _enumByName(
        VoiceActionType.values,
        row.actionType,
        VoiceActionType.updateSettings,
      ),
      source: _enumByName(
        VoiceActionSource.values,
        row.source,
        VoiceActionSource.voice,
      ),
      status: _enumByName(
        VoiceActionStatus.values,
        row.status,
        VoiceActionStatus.failed,
      ),
      targetEntityType: row.targetEntityType,
      targetEntityId: row.targetEntityId,
      beforeSummary: row.beforeSummary,
      afterSummary: row.afterSummary,
      confirmed: row.confirmed,
      authenticationRequired: row.authRequired,
      authenticationSucceeded: row.authSucceeded,
      errorCode: row.errorCode,
      undoStatus: _enumByName(
        VoiceUndoStatus.values,
        row.undoStatus,
        VoiceUndoStatus.notAvailable,
      ),
      commandFingerprint: row.commandFingerprint,
      createdAt: row.createdAt,
    );
  }

  VoiceActionAuditsCompanion _voiceActionAuditToCompanion(
    VoiceActionAuditEvent event,
  ) {
    return VoiceActionAuditsCompanion.insert(
      id: event.id,
      actionId: event.actionId,
      actionType: event.actionType.name,
      source: event.source.name,
      status: event.status.name,
      targetEntityType: Value(event.targetEntityType),
      targetEntityId: Value(event.targetEntityId),
      beforeSummary: Value(event.beforeSummary),
      afterSummary: Value(event.afterSummary),
      confirmed: Value(event.confirmed),
      authRequired: Value(event.authenticationRequired),
      authSucceeded: Value(event.authenticationSucceeded),
      errorCode: Value(event.errorCode),
      undoStatus: Value(event.undoStatus.name),
      commandFingerprint: event.commandFingerprint,
      createdAt: Value(event.createdAt),
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

enum _VoiceCreateProductCommitStage {
  preflight,
  duplicateAudit,
  startedAudit,
  categoryInsert,
  productInsert,
  succeededAudit,
}

enum _VoiceStockIncrementCommitStage {
  preflight,
  startedAudit,
  trackingAudit,
  productUpdate,
  succeededAudit,
}

enum _VoicePriceUpdateCommitStage {
  preflight,
  startedAudit,
  productUpdate,
  succeededAudit,
}

enum _VoicePriceUpdateUndoStage {
  preflight,
  requestedAudit,
  verification,
  rejectedAudit,
  productUpdate,
  succeededAudit,
}

bool _sameStockQuantity(double left, double right) {
  return QuantityFormatter.normalize(left) ==
      QuantityFormatter.normalize(right);
}

bool _samePricePercentage(double? left, double? right) {
  if (left == null || right == null) return left == right;
  return (left - right).abs() <= 0.000001;
}

bool _samePriceWarnings<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _isValidPriceUndoEnvelope(VoicePriceUpdateUndoRequest request) {
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
  return _matchesPriceUndoAudit(
        request.requested,
        request,
        VoiceActionStatus.undoRequested,
      ) &&
      _matchesPriceUndoAudit(
        request.succeeded,
        request,
        VoiceActionStatus.undoSucceeded,
      ) &&
      _matchesPriceUndoAudit(
        request.rejected,
        request,
        VoiceActionStatus.undoRejected,
      );
}

bool _matchesPriceUndoAudit(
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

abstract final class _SettingKey {
  static const onboardingCompleted = 'onboarding_completed';
  static const pinEnabled = 'pin_enabled';
  static const biometricEnabled = 'biometric_enabled';
  static const cloudSyncEnabled = 'cloud_sync_enabled';
  static const supabaseUrl = 'supabase_url';
  static const queuedSyncCount = 'queued_sync_count';
  static const language = 'language';
  static const voiceSensitivity = 'voice_sensitivity';
  static const handsfreeWakeWordEnabled = 'handsfree_wake_word_enabled';
  static const silentTimeoutSeconds = 'silent_timeout_seconds';
  static const enableVoiceLearning = 'enable_voice_learning';
  static const voiceFinancialPrivacyEnabled = 'voice_financial_privacy_enabled';
  static const maskVoiceFinancialValues = 'mask_voice_financial_values';
}
