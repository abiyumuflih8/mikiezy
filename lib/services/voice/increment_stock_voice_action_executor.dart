import 'package:flutter/foundation.dart';

import '../../data/repositories/mikiezy_repository.dart';
import '../../domain/models/voice_action.dart';
import '../../domain/models/voice_action_execution.dart';
import '../../domain/models/voice_action_payload.dart';
import '../../domain/models/voice_stock_increment_commit.dart';
import '../../domain/services/quantity_formatter.dart';
import '../../domain/services/stable_fingerprint_service.dart';
import '../../domain/services/stock_increment_calculator.dart';
import '../../models/mikiezy_models.dart';

class IncrementStockVoiceActionExecutor implements VoiceActionExecutor {
  IncrementStockVoiceActionExecutor(
    this._repository, {
    this.calculator = const StockIncrementCalculator(),
    this.fingerprintService = const StableFingerprintService(),
    this.onCommitted,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final MikiezyRepository _repository;
  final StockIncrementCalculator calculator;
  final StableFingerprintService fingerprintService;
  final Future<void> Function()? onCommitted;
  final DateTime Function() _now;

  @override
  bool supports(VoiceActionType type) =>
      type == VoiceActionType.incrementProductStock;

  @override
  Future<VoiceActionExecutionResult> execute(
    VoiceActionDraft action, {
    required bool isFeatureEnabled,
    required bool isAppLocked,
    bool authenticationSucceeded = false,
    bool authenticationAttempted = false,
    bool additionalConfirmationSucceeded = false,
    String? currentBaseFingerprint,
  }) async {
    if (!supports(action.type)) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.validationFailed,
        status: VoiceActionExecutionStatus.validationFailed,
        message: 'Jenis perubahan stok tidak didukung.',
        errorCode: 'unsupported_stock_action_type',
      );
    }
    if (!isFeatureEnabled) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.executionDisabled,
        status: VoiceActionExecutionStatus.executionDisabled,
        message:
            'Tambah stok melalui suara belum diaktifkan. Tidak ada data yang berubah.',
        errorCode: 'feature_flag_disabled',
      );
    }
    if (isAppLocked) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.blockedLocked,
        status: VoiceActionExecutionStatus.locked,
        message: 'Aplikasi terkunci. Stok tidak diubah.',
        errorCode: 'app_locked',
      );
    }
    if (action.isExpiredAt(_now())) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.expired,
        status: VoiceActionExecutionStatus.expired,
        message: 'Preview stok sudah kedaluwarsa. Ulangi perintah.',
        errorCode: 'action_expired',
      );
    }
    if (action.status != VoiceActionStatus.confirmed) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.notConfirmed,
        status: VoiceActionExecutionStatus.notConfirmed,
        message: 'Penambahan stok belum dikonfirmasi.',
        errorCode: 'action_not_confirmed',
      );
    }
    if (action.requiresAuthentication && !authenticationSucceeded) {
      final failed = authenticationAttempted;
      return _terminal(
        action,
        auditStatus: failed
            ? VoiceActionStatus.authenticationFailed
            : VoiceActionStatus.authenticationRequired,
        status: failed
            ? VoiceActionExecutionStatus.authenticationFailed
            : VoiceActionExecutionStatus.authenticationRequired,
        message: failed
            ? 'Autentikasi gagal atau dibatalkan. Stok tidak diubah.'
            : 'Autentikasi aman diperlukan sebelum stok dapat diubah.',
        errorCode: failed ? 'authentication_failed' : 'authentication_required',
      );
    }

    final payload = action.payload;
    if (payload is! IncrementStockVoiceActionPayload ||
        payload.actionId != action.actionId ||
        payload.commandFingerprint != action.commandFingerprint) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.validationFailed,
        status: VoiceActionExecutionStatus.validationFailed,
        message: 'Data penambahan stok tidak lengkap.',
        errorCode: 'invalid_stock_payload',
      );
    }
    if (!payload.requestedQuantity.isFinite || payload.requestedQuantity <= 0) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.validationFailed,
        status: VoiceActionExecutionStatus.invalidQuantity,
        message: 'Jumlah stok harus lebih besar dari nol.',
        errorCode: 'invalid_stock_quantity',
      );
    }

    try {
      final alreadyExecuted = await _repository.hasSuccessfulVoiceAction(
        actionId: action.actionId,
        commandFingerprint: action.commandFingerprint,
      );
      if (alreadyExecuted) {
        final product = await _loadProduct(payload.productId);
        await _tryRecord(
          _audit(
            action,
            VoiceActionStatus.alreadyExecuted,
            authenticationSucceeded: authenticationSucceeded,
            errorCode: 'already_executed',
          ),
        );
        return VoiceActionExecutionResult(
          status: VoiceActionExecutionStatus.alreadyExecuted,
          message: 'Perintah penambahan stok ini sudah pernah dijalankan.',
          product: product,
        );
      }
      final latest = await _loadProduct(payload.productId);
      if (latest == null) {
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.validationFailed,
          status: VoiceActionExecutionStatus.productNotFound,
          message: 'Produk sudah tidak tersedia. Tidak ada stok yang diubah.',
          errorCode: 'product_not_found',
        );
      }
      final latestFingerprint = await fingerprintService.create(
        stockMutationProductFingerprintSource(latest),
      );
      if (latestFingerprint != payload.productFingerprint ||
          currentBaseFingerprint == null ||
          currentBaseFingerprint != action.baseFingerprint) {
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.staleRejected,
          status: VoiceActionExecutionStatus.stale,
          message:
              'Stok produk sudah berubah. Preview baru perlu dikonfirmasi.',
          errorCode: 'stale_stock_snapshot',
          product: latest,
        );
      }

      final calculation = calculator.calculate(
        product: latest,
        requestedQuantity: payload.requestedQuantity,
        requestedUnit: payload.requestedUnit,
        trackingEnableConfirmed: payload.enableTracking,
      );
      final validationFailure = await _calculationFailure(
        action,
        calculation,
        latest,
      );
      if (validationFailure != null) return validationFailure;
      if (!_same(calculation.normalizedQuantity!, payload.normalizedQuantity) ||
          !_same(calculation.stockBefore!, payload.stockBefore) ||
          !_same(calculation.stockAfter!, payload.stockAfter) ||
          calculation.baseUnit != payload.baseUnit ||
          calculation.enableTracking != payload.enableTracking) {
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.staleRejected,
          status: VoiceActionExecutionStatus.stale,
          message:
              'Stok produk sudah berubah. Preview baru perlu dikonfirmasi.',
          errorCode: 'stale_stock_calculation',
          product: latest,
        );
      }

      final result = await _repository.incrementProductStockFromVoice(
        VoiceStockIncrementCommitRequest(
          actionId: action.actionId,
          commandFingerprint: action.commandFingerprint,
          payload: payload,
          confirmed: true,
          expiresAt: action.expiresAt,
          executionStarted: _audit(
            action,
            VoiceActionStatus.executionStarted,
            authenticationSucceeded: authenticationSucceeded,
          ),
          trackingEnableConfirmed: payload.enableTracking
              ? _audit(
                  action,
                  VoiceActionStatus.trackingEnableConfirmed,
                  authenticationSucceeded: authenticationSucceeded,
                )
              : null,
          succeeded: _audit(
            action,
            VoiceActionStatus.succeeded,
            authenticationSucceeded: authenticationSucceeded,
          ),
        ),
      );
      return _commitResult(action, payload, result, authenticationSucceeded);
    } on VoiceStockIncrementCommitException catch (error, stackTrace) {
      _debugFailure(action.actionId, error, stackTrace);
      return _commitFailure(action, error.type, authenticationSucceeded);
    } catch (error, stackTrace) {
      _debugFailure(action.actionId, error, stackTrace);
      return _unexpectedFailure(action, authenticationSucceeded);
    }
  }

  Future<VoiceActionExecutionResult> _commitResult(
    VoiceActionDraft action,
    IncrementStockVoiceActionPayload payload,
    VoiceStockIncrementCommitResult result,
    bool authenticationSucceeded,
  ) async {
    switch (result.status) {
      case VoiceStockIncrementCommitStatus.incremented:
        await _refreshAfterCommit(action.actionId);
        final product = result.product;
        final currentStock = product?.stockPcs ?? payload.stockAfter;
        final trackingMessage = payload.enableTracking
            ? 'Pelacakan stok ${payload.productName} berhasil diaktifkan dan '
            : 'Stok ${payload.productName} berhasil ditambah '
                  '${QuantityFormatter.label(payload.requestedQuantity)} '
                  '${payload.requestedUnit.label}. ';
        return VoiceActionExecutionResult(
          status: VoiceActionExecutionStatus.succeeded,
          message:
              '${trackingMessage}stok sekarang ${QuantityFormatter.label(currentStock)} ${payload.baseUnit.label}.',
          product: product,
        );
      case VoiceStockIncrementCommitStatus.alreadyExecuted:
        await _tryRecord(
          _audit(
            action,
            VoiceActionStatus.alreadyExecuted,
            authenticationSucceeded: authenticationSucceeded,
            errorCode: 'already_executed',
          ),
        );
        await _refreshAfterCommit(action.actionId);
        return VoiceActionExecutionResult(
          status: VoiceActionExecutionStatus.alreadyExecuted,
          message: 'Perintah penambahan stok ini sudah pernah dijalankan.',
          product: result.product,
        );
      case VoiceStockIncrementCommitStatus.productNotFound:
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.validationFailed,
          status: VoiceActionExecutionStatus.productNotFound,
          message: 'Produk sudah tidak tersedia. Tidak ada stok yang diubah.',
          errorCode: 'product_not_found_in_transaction',
        );
      case VoiceStockIncrementCommitStatus.stale:
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.staleRejected,
          status: VoiceActionExecutionStatus.stale,
          message:
              'Stok produk sudah berubah. Preview baru perlu dikonfirmasi.',
          errorCode: 'stale_in_transaction',
          product: result.product,
        );
      case VoiceStockIncrementCommitStatus.expired:
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.expired,
          status: VoiceActionExecutionStatus.expired,
          message: 'Preview stok sudah kedaluwarsa. Ulangi perintah.',
          errorCode: 'action_expired_in_transaction',
        );
      case VoiceStockIncrementCommitStatus.notConfirmed:
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.notConfirmed,
          status: VoiceActionExecutionStatus.notConfirmed,
          message: 'Penambahan stok belum dikonfirmasi.',
          errorCode: 'action_not_confirmed_in_transaction',
        );
      case VoiceStockIncrementCommitStatus.trackingConfirmationRequired:
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.validationFailed,
          status: VoiceActionExecutionStatus.trackingConfirmationRequired,
          message:
              'Pelacakan stok harus dikonfirmasi sebelum stok dapat ditambah.',
          errorCode: 'tracking_confirmation_required',
          product: result.product,
        );
      case VoiceStockIncrementCommitStatus.invalidPayload:
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.validationFailed,
          status: VoiceActionExecutionStatus.validationFailed,
          message: 'Data penambahan stok tidak lagi valid.',
          errorCode: 'invalid_payload_in_transaction',
          product: result.product,
        );
    }
  }

  Future<VoiceActionExecutionResult?> _calculationFailure(
    VoiceActionDraft action,
    StockIncrementCalculation calculation,
    Product product,
  ) async {
    if (calculation.isSuccess) return null;
    final mapping = switch (calculation.status) {
      StockIncrementCalculationStatus.invalidQuantity => (
        VoiceActionExecutionStatus.invalidQuantity,
        VoiceActionStatus.validationFailed,
        'invalid_stock_quantity',
      ),
      StockIncrementCalculationStatus.incompatibleUnit => (
        VoiceActionExecutionStatus.incompatibleUnit,
        VoiceActionStatus.unitRejected,
        'incompatible_stock_unit',
      ),
      StockIncrementCalculationStatus.missingPackSize => (
        VoiceActionExecutionStatus.missingPackSize,
        VoiceActionStatus.unitRejected,
        'missing_pack_size',
      ),
      StockIncrementCalculationStatus.missingCartonSize => (
        VoiceActionExecutionStatus.missingCartonSize,
        VoiceActionStatus.unitRejected,
        'missing_carton_size',
      ),
      StockIncrementCalculationStatus.trackingConfirmationRequired => (
        VoiceActionExecutionStatus.trackingConfirmationRequired,
        VoiceActionStatus.validationFailed,
        'tracking_confirmation_required',
      ),
      StockIncrementCalculationStatus.success => throw StateError(
        'Successful calculation cannot be mapped as a failure.',
      ),
    };
    return _terminal(
      action,
      auditStatus: mapping.$2,
      status: mapping.$1,
      message: calculation.message ?? 'Penambahan stok belum valid.',
      errorCode: mapping.$3,
      product: product,
    );
  }

  Future<Product?> _loadProduct(String productId) async {
    final products = await _repository.loadProducts();
    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  Future<VoiceActionExecutionResult> _terminal(
    VoiceActionDraft action, {
    required VoiceActionStatus auditStatus,
    required VoiceActionExecutionStatus status,
    required String message,
    required String errorCode,
    Product? product,
  }) async {
    final recorded = await _tryRecord(
      _audit(action, auditStatus, errorCode: errorCode),
    );
    if (!recorded) {
      return const VoiceActionExecutionResult(
        status: VoiceActionExecutionStatus.auditFailure,
        message: 'Perubahan tidak dijalankan karena audit keamanan gagal.',
        errorCode: 'terminal_audit_failed',
      );
    }
    return VoiceActionExecutionResult(
      status: status,
      message: message,
      product: product,
      errorCode: errorCode,
    );
  }

  Future<VoiceActionExecutionResult> _commitFailure(
    VoiceActionDraft action,
    VoiceStockIncrementCommitFailureType failureType,
    bool authenticationSucceeded,
  ) async {
    final auditStatus =
        failureType == VoiceStockIncrementCommitFailureType.auditFailure
        ? VoiceActionStatus.auditFailure
        : VoiceActionStatus.databaseFailure;
    final executionStatus =
        failureType == VoiceStockIncrementCommitFailureType.auditFailure
        ? VoiceActionExecutionStatus.auditFailure
        : VoiceActionExecutionStatus.databaseFailure;
    final errorCode = failureType.name;
    final failureRecorded = await _tryRecord(
      _audit(
        action,
        auditStatus,
        authenticationSucceeded: authenticationSucceeded,
        errorCode: errorCode,
      ),
    );
    await _tryRecord(
      _audit(
        action,
        VoiceActionStatus.transactionRolledBack,
        authenticationSucceeded: authenticationSucceeded,
        errorCode: errorCode,
      ),
    );
    return VoiceActionExecutionResult(
      status: failureRecorded
          ? executionStatus
          : VoiceActionExecutionStatus.auditFailure,
      message:
          'Stok belum berhasil diperbarui dan tidak ada data yang berubah.',
      errorCode: failureRecorded ? errorCode : 'failure_audit_failed',
    );
  }

  Future<VoiceActionExecutionResult> _unexpectedFailure(
    VoiceActionDraft action,
    bool authenticationSucceeded,
  ) async {
    final recorded = await _tryRecord(
      _audit(
        action,
        VoiceActionStatus.failed,
        authenticationSucceeded: authenticationSucceeded,
        errorCode: 'unexpected_failure',
      ),
    );
    return VoiceActionExecutionResult(
      status: recorded
          ? VoiceActionExecutionStatus.unexpectedFailure
          : VoiceActionExecutionStatus.auditFailure,
      message:
          'Stok belum berhasil diperbarui dan tidak ada data yang berubah.',
      errorCode: recorded ? 'unexpected_failure' : 'failure_audit_failed',
    );
  }

  Future<void> _refreshAfterCommit(String actionId) async {
    final callback = onCommitted;
    if (callback == null) return;
    try {
      await callback();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Voice stock refresh failed '
          '(actionId=$actionId, error=${error.runtimeType}): '
          '$error\n$stackTrace',
        );
      }
    }
  }

  Future<bool> _tryRecord(VoiceActionAuditEvent event) async {
    try {
      await _repository.recordVoiceActionAudit(event);
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Voice stock audit failed '
          '(actionId=${event.actionId}, status=${event.status.name}, '
          'error=${error.runtimeType}): $error\n$stackTrace',
        );
      }
      return false;
    }
  }

  VoiceActionAuditEvent _audit(
    VoiceActionDraft action,
    VoiceActionStatus status, {
    bool authenticationSucceeded = false,
    String? errorCode,
  }) {
    return VoiceActionAuditEvent(
      id: '${action.actionId}-${status.name}',
      actionId: action.actionId,
      actionType: action.type,
      source: VoiceActionSource.voice,
      status: status,
      targetEntityType: action.proposed.entityType,
      targetEntityId: action.proposed.entityId,
      beforeSummary: _truncate(action.before?.redactedSummary ?? ''),
      afterSummary: _truncate(action.proposed.redactedSummary),
      confirmed: action.status == VoiceActionStatus.confirmed,
      authenticationRequired: action.requiresAuthentication,
      authenticationSucceeded: authenticationSucceeded,
      errorCode: errorCode,
      undoStatus: VoiceUndoStatus.notAvailable,
      commandFingerprint: action.commandFingerprint,
      createdAt: _now(),
    );
  }

  void _debugFailure(String actionId, Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    debugPrint(
      'Voice stock execution failed '
      '(actionId=$actionId, error=${error.runtimeType}): '
      '$error\n$stackTrace',
    );
  }

  bool _same(double left, double right) {
    return QuantityFormatter.normalize(left) ==
        QuantityFormatter.normalize(right);
  }

  String _truncate(String value) {
    const maxLength = 500;
    return value.length <= maxLength ? value : value.substring(0, maxLength);
  }
}
