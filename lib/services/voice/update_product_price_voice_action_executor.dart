import 'package:flutter/foundation.dart';

import '../../data/repositories/mikiezy_repository.dart';
import '../../domain/models/product_price.dart';
import '../../domain/models/voice_action.dart';
import '../../domain/models/voice_action_execution.dart';
import '../../domain/models/voice_action_payload.dart';
import '../../domain/models/voice_price_update_commit.dart';
import '../../domain/services/product_price_update_validator.dart';
import '../../domain/services/stable_fingerprint_service.dart';
import '../../models/mikiezy_models.dart';

class UpdateProductPriceVoiceActionExecutor implements VoiceActionExecutor {
  UpdateProductPriceVoiceActionExecutor(
    this._repository, {
    this.validator = const ProductPriceUpdateValidator(),
    this.fingerprintService = const StableFingerprintService(),
    this.onCommitted,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final MikiezyRepository _repository;
  final ProductPriceUpdateValidator validator;
  final StableFingerprintService fingerprintService;
  final Future<void> Function()? onCommitted;
  final DateTime Function() _now;

  @override
  bool supports(VoiceActionType type) =>
      type == VoiceActionType.updateProductPrice;

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
        auditStatus: VoiceActionStatus.validationRejected,
        status: VoiceActionExecutionStatus.unsupportedPriceType,
        message: 'Jenis perubahan harga tidak didukung.',
        errorCode: 'unsupported_price_action_type',
      );
    }
    if (!isFeatureEnabled) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.executionDisabled,
        status: VoiceActionExecutionStatus.executionDisabled,
        message:
            'Ubah harga melalui suara belum diaktifkan. Tidak ada data yang berubah.',
        errorCode: 'feature_flag_disabled',
      );
    }
    if (isAppLocked) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.blockedLocked,
        status: VoiceActionExecutionStatus.locked,
        message: 'Aplikasi terkunci. Harga tidak diubah.',
        errorCode: 'app_locked',
      );
    }
    if (action.isExpiredAt(_now())) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.expired,
        status: VoiceActionExecutionStatus.expired,
        message: 'Preview harga sudah kedaluwarsa. Ulangi perintah.',
        errorCode: 'action_expired',
      );
    }
    if (action.status != VoiceActionStatus.confirmed) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.notConfirmed,
        status: VoiceActionExecutionStatus.notConfirmed,
        message: 'Perubahan harga belum dikonfirmasi.',
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
            ? 'Autentikasi gagal atau dibatalkan. Harga tidak diubah.'
            : 'Autentikasi aman diperlukan sebelum harga dapat diubah.',
        errorCode: failed ? 'authentication_failed' : 'authentication_required',
      );
    }

    final payload = action.payload;
    if (payload is! UpdateProductPriceVoiceActionPayload ||
        payload.actionId != action.actionId ||
        payload.commandFingerprint != action.commandFingerprint ||
        payload.validationErrors.isNotEmpty) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.validationRejected,
        status: VoiceActionExecutionStatus.invalidPrice,
        message: 'Data perubahan harga tidak lengkap atau tidak valid.',
        errorCode: 'invalid_price_payload',
      );
    }
    if (payload.requiresAdditionalConfirmation &&
        !additionalConfirmationSucceeded) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.additionalConfirmationRequired,
        status: VoiceActionExecutionStatus.additionalConfirmationRequired,
        message:
            'Warning perubahan harga memerlukan konfirmasi tambahan. Harga belum diubah.',
        errorCode: 'additional_confirmation_required',
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
          message: 'Perintah perubahan harga ini sudah pernah dijalankan.',
          product: product,
        );
      }

      final latest = await _loadProduct(payload.productId);
      if (latest == null) {
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.validationRejected,
          status: VoiceActionExecutionStatus.productNotFound,
          message: 'Produk sudah tidak tersedia. Tidak ada harga yang diubah.',
          errorCode: 'product_not_found',
        );
      }
      final latestFingerprint = await fingerprintService.create(
        priceMutationProductFingerprintSource(latest),
      );
      if (latestFingerprint != payload.productFingerprint ||
          currentBaseFingerprint == null ||
          currentBaseFingerprint != action.baseFingerprint) {
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.staleRejected,
          status: VoiceActionExecutionStatus.stale,
          message:
              'Harga produk sudah berubah. Preview baru perlu dikonfirmasi.',
          errorCode: 'stale_price_snapshot',
          product: latest,
        );
      }

      final validation = validator.validate(
        product: latest,
        type: payload.priceType,
        newPrice: payload.newPrice,
      );
      if (validation.status == ProductPriceValidationStatus.samePrice) {
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.validationRejected,
          status: VoiceActionExecutionStatus.samePrice,
          message:
              validation.message ??
              'Harga baru sama dengan harga saat ini. Tidak ada perubahan yang dilakukan.',
          errorCode: 'same_price',
          product: latest,
        );
      }
      if (!validation.isSuccess) {
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.validationRejected,
          status: VoiceActionExecutionStatus.invalidPrice,
          message: validation.message ?? 'Harga baru tidak valid.',
          errorCode: 'invalid_price',
          product: latest,
        );
      }
      if (validation.oldPrice != payload.oldPrice ||
          validation.newPrice != payload.newPrice ||
          validation.difference != payload.difference ||
          !_samePercentage(
            validation.percentageChange,
            payload.percentageChange,
          ) ||
          !_sameWarnings(validation.warnings, payload.warnings) ||
          validation.requiresAdditionalConfirmation !=
              payload.requiresAdditionalConfirmation) {
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.staleRejected,
          status: VoiceActionExecutionStatus.stale,
          message:
              'Kondisi harga atau warning bisnis sudah berubah. Preview baru perlu dikonfirmasi.',
          errorCode: 'stale_price_validation',
          product: latest,
        );
      }

      final result = await _repository.updateProductPriceFromVoice(
        VoicePriceUpdateCommitRequest(
          actionId: action.actionId,
          commandFingerprint: action.commandFingerprint,
          payload: payload,
          confirmed: true,
          additionalConfirmationSucceeded: additionalConfirmationSucceeded,
          expiresAt: action.expiresAt,
          executionStarted: _audit(
            action,
            VoiceActionStatus.executionStarted,
            authenticationSucceeded: authenticationSucceeded,
          ),
          succeeded: _audit(
            action,
            VoiceActionStatus.succeeded,
            authenticationSucceeded: authenticationSucceeded,
          ),
        ),
      );
      return _commitResult(action, payload, result, authenticationSucceeded);
    } on VoicePriceUpdateCommitException catch (error, stackTrace) {
      _debugFailure(action.actionId, error, stackTrace);
      return _commitFailure(action, error.type, authenticationSucceeded);
    } catch (error, stackTrace) {
      _debugFailure(action.actionId, error, stackTrace);
      return _unexpectedFailure(action, authenticationSucceeded);
    }
  }

  Future<VoiceActionExecutionResult> _commitResult(
    VoiceActionDraft action,
    UpdateProductPriceVoiceActionPayload payload,
    VoicePriceUpdateCommitResult result,
    bool authenticationSucceeded,
  ) async {
    switch (result.status) {
      case VoicePriceUpdateCommitStatus.updated:
        final refreshed = await _refreshAfterCommit(action.actionId);
        if (!refreshed) {
          await _tryRecord(
            _audit(
              action,
              VoiceActionStatus.stateRefreshFailed,
              authenticationSucceeded: authenticationSucceeded,
              errorCode: 'state_refresh_failed_after_commit',
            ),
          );
          return VoiceActionExecutionResult(
            status: VoiceActionExecutionStatus.stateRefreshFailed,
            message:
                '${_capitalized(payload.priceType.label)} ${payload.productName} sudah tersimpan menjadi ${_rupiah(payload.newPrice)}, tetapi tampilan produk belum berhasil dimuat ulang. Muat ulang halaman produk.',
            product: result.product,
            errorCode: 'state_refresh_failed_after_commit',
          );
        }
        return VoiceActionExecutionResult(
          status: VoiceActionExecutionStatus.succeeded,
          message:
              '${_capitalized(payload.priceType.label)} ${payload.productName} berhasil diubah menjadi ${_rupiah(payload.newPrice)}.',
          product: result.product,
        );
      case VoicePriceUpdateCommitStatus.alreadyExecuted:
        await _tryRecord(
          _audit(
            action,
            VoiceActionStatus.alreadyExecuted,
            authenticationSucceeded: authenticationSucceeded,
            errorCode: 'already_executed',
          ),
        );
        final refreshed = await _refreshAfterCommit(action.actionId);
        if (!refreshed) {
          await _tryRecord(
            _audit(
              action,
              VoiceActionStatus.stateRefreshFailed,
              authenticationSucceeded: authenticationSucceeded,
              errorCode: 'state_refresh_failed_after_duplicate',
            ),
          );
          return VoiceActionExecutionResult(
            status: VoiceActionExecutionStatus.stateRefreshFailed,
            message:
                'Perintah perubahan harga ini sudah pernah dijalankan, tetapi tampilan produk belum berhasil dimuat ulang. Muat ulang halaman produk.',
            product: result.product,
            errorCode: 'state_refresh_failed_after_duplicate',
          );
        }
        return VoiceActionExecutionResult(
          status: VoiceActionExecutionStatus.alreadyExecuted,
          message: 'Perintah perubahan harga ini sudah pernah dijalankan.',
          product: result.product,
        );
      case VoicePriceUpdateCommitStatus.productNotFound:
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.validationRejected,
          status: VoiceActionExecutionStatus.productNotFound,
          message: 'Produk sudah tidak tersedia. Tidak ada harga yang diubah.',
          errorCode: 'product_not_found_in_transaction',
        );
      case VoicePriceUpdateCommitStatus.stale:
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.staleRejected,
          status: VoiceActionExecutionStatus.stale,
          message:
              'Harga produk sudah berubah. Preview baru perlu dikonfirmasi.',
          errorCode: 'stale_in_transaction',
          product: result.product,
        );
      case VoicePriceUpdateCommitStatus.expired:
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.expired,
          status: VoiceActionExecutionStatus.expired,
          message: 'Preview harga sudah kedaluwarsa. Ulangi perintah.',
          errorCode: 'action_expired_in_transaction',
        );
      case VoicePriceUpdateCommitStatus.notConfirmed:
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.notConfirmed,
          status: VoiceActionExecutionStatus.notConfirmed,
          message: 'Perubahan harga belum dikonfirmasi.',
          errorCode: 'action_not_confirmed_in_transaction',
        );
      case VoicePriceUpdateCommitStatus.additionalConfirmationRequired:
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.additionalConfirmationRequired,
          status: VoiceActionExecutionStatus.additionalConfirmationRequired,
          message:
              'Warning perubahan harga memerlukan konfirmasi tambahan. Harga belum diubah.',
          errorCode: 'additional_confirmation_required_in_transaction',
        );
      case VoicePriceUpdateCommitStatus.samePrice:
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.validationRejected,
          status: VoiceActionExecutionStatus.samePrice,
          message:
              'Harga baru sama dengan harga saat ini. Tidak ada perubahan yang dilakukan.',
          errorCode: 'same_price_in_transaction',
          product: result.product,
        );
      case VoicePriceUpdateCommitStatus.invalidPayload:
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.validationRejected,
          status: VoiceActionExecutionStatus.invalidPrice,
          message: 'Data perubahan harga tidak lagi valid.',
          errorCode: 'invalid_payload_in_transaction',
          product: result.product,
        );
    }
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
    VoicePriceUpdateCommitFailureType failureType,
    bool authenticationSucceeded,
  ) async {
    final auditStatus =
        failureType == VoicePriceUpdateCommitFailureType.auditFailure
        ? VoiceActionStatus.auditFailure
        : VoiceActionStatus.databaseFailure;
    final executionStatus =
        failureType == VoicePriceUpdateCommitFailureType.auditFailure
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
      message: 'Harga belum berhasil diubah dan tidak ada data yang berubah.',
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
      message: 'Harga belum berhasil diubah dan tidak ada data yang berubah.',
      errorCode: recorded ? 'unexpected_failure' : 'failure_audit_failed',
    );
  }

  Future<bool> _refreshAfterCommit(String actionId) async {
    final callback = onCommitted;
    if (callback == null) return true;
    try {
      await callback();
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Voice price refresh failed '
          '(actionId=$actionId, error=${error.runtimeType}): '
          '$error\n$stackTrace',
        );
      }
      return false;
    }
  }

  Future<bool> _tryRecord(VoiceActionAuditEvent event) async {
    try {
      await _repository.recordVoiceActionAudit(event);
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Voice price audit failed '
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
      undoStatus: VoiceUndoStatus.available,
      commandFingerprint: action.commandFingerprint,
      createdAt: _now(),
    );
  }

  void _debugFailure(String actionId, Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    debugPrint(
      'Voice price execution failed '
      '(actionId=$actionId, error=${error.runtimeType}): '
      '$error\n$stackTrace',
    );
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

  String _capitalized(String value) {
    return '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';
  }

  String _rupiah(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < raw.length; index++) {
      final remaining = raw.length - index;
      buffer.write(raw[index]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }

  String _truncate(String value) {
    const maxLength = 500;
    return value.length <= maxLength ? value : value.substring(0, maxLength);
  }
}
