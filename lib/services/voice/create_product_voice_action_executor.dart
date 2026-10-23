import 'package:flutter/foundation.dart';

import '../../data/repositories/mikiezy_repository.dart';
import '../../domain/models/voice_action.dart';
import '../../domain/models/voice_action_execution.dart';
import '../../domain/models/voice_action_payload.dart';
import '../../domain/models/voice_create_product_commit.dart';
import '../../domain/services/product_validator.dart';

class CreateProductVoiceActionExecutor implements VoiceActionExecutor {
  CreateProductVoiceActionExecutor(
    this._repository, {
    this.productValidator = const ProductValidator(),
    this._onCommitted,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final MikiezyRepository _repository;
  final ProductValidator productValidator;
  final Future<void> Function()? _onCommitted;
  final DateTime Function() _now;

  @override
  bool supports(VoiceActionType type) => type == VoiceActionType.createProduct;

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
        message: 'Jenis perubahan tidak didukung oleh executor produk.',
        errorCode: 'unsupported_action_type',
      );
    }
    if (!isFeatureEnabled) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.executionDisabled,
        status: VoiceActionExecutionStatus.executionDisabled,
        message:
            'Tambah produk melalui suara belum diaktifkan. Tidak ada data yang diubah.',
        errorCode: 'feature_flag_disabled',
      );
    }
    if (isAppLocked) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.blockedLocked,
        status: VoiceActionExecutionStatus.locked,
        message: 'Aplikasi terkunci. Produk tidak dibuat.',
        errorCode: 'app_locked',
      );
    }
    if (action.isExpiredAt(_now())) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.expired,
        status: VoiceActionExecutionStatus.expired,
        message: 'Preview sudah kedaluwarsa. Ulangi perintah.',
        errorCode: 'action_expired',
      );
    }
    if (action.status != VoiceActionStatus.confirmed) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.notConfirmed,
        status: VoiceActionExecutionStatus.notConfirmed,
        message: 'Produk belum dikonfirmasi dan tidak dibuat.',
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
            ? 'Autentikasi gagal atau dibatalkan. Produk tidak dibuat.'
            : 'Autentikasi diperlukan sebelum produk dapat dibuat.',
        errorCode: failed ? 'authentication_failed' : 'authentication_required',
      );
    }
    if (currentBaseFingerprint == null ||
        currentBaseFingerprint != action.baseFingerprint) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.staleRejected,
        status: VoiceActionExecutionStatus.stale,
        message:
            'Data katalog sudah berubah sejak preview dibuat. Ulangi perintah.',
        errorCode: 'stale_catalog',
      );
    }

    final payload = action.payload;
    if (payload is! CreateProductVoiceActionPayload) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.validationFailed,
        status: VoiceActionExecutionStatus.validationFailed,
        message: 'Data produk tidak lengkap. Produk tidak dibuat.',
        errorCode: 'invalid_create_product_payload',
      );
    }
    if (payload.similarProductName != null &&
        !payload.similarProductConfirmed) {
      return _terminal(
        action,
        auditStatus: VoiceActionStatus.validationFailed,
        status: VoiceActionExecutionStatus.similarProductWarning,
        message:
            'Nama produk mirip dengan ${payload.similarProductName}. Konfirmasi tambahan diperlukan.',
        errorCode: 'similar_product_unconfirmed',
      );
    }

    try {
      final validation = productValidator.validate(payload.product);
      if (!validation.isValid) {
        return _terminal(
          action,
          auditStatus: VoiceActionStatus.validationFailed,
          status: VoiceActionExecutionStatus.validationFailed,
          message: validation.userMessage,
          errorCode: 'product_validation_failed',
        );
      }

      final categories = await _repository.loadProductCategories();
      final existingCategoryIndex = categories.indexWhere(
        (category) =>
            category.toLowerCase() == payload.product.category.toLowerCase(),
      );
      final result = await _repository.createProductFromVoice(
        VoiceCreateProductCommitRequest(
          actionId: action.actionId,
          commandFingerprint: action.commandFingerprint,
          payload: payload,
          categoryPosition: existingCategoryIndex == -1
              ? categories.length
              : existingCategoryIndex,
          confirmed: true,
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
          duplicateRejected: _audit(
            action,
            VoiceActionStatus.duplicateRejected,
            authenticationSucceeded: authenticationSucceeded,
            errorCode: 'duplicate_product_name',
          ),
        ),
      );
      switch (result.status) {
        case VoiceCreateProductCommitStatus.created:
          await _refreshAfterCommit(action.actionId);
          return VoiceActionExecutionResult(
            status: VoiceActionExecutionStatus.succeeded,
            message: 'Produk ${payload.product.name} berhasil ditambahkan.',
            product: result.product ?? payload.product,
          );
        case VoiceCreateProductCommitStatus.alreadyExecuted:
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
            message: 'Perintah ini sudah pernah dijalankan.',
            product: result.product,
          );
        case VoiceCreateProductCommitStatus.duplicateProduct:
          return VoiceActionExecutionResult(
            status: VoiceActionExecutionStatus.duplicateProduct,
            message:
                'Produk ${result.existingProduct?.name ?? payload.product.name} sudah tersedia. Produk baru tidak dibuat.',
            product: result.existingProduct,
            errorCode: 'duplicate_product_name',
          );
        case VoiceCreateProductCommitStatus.expired:
          return _terminal(
            action,
            auditStatus: VoiceActionStatus.expired,
            status: VoiceActionExecutionStatus.expired,
            message: 'Preview sudah kedaluwarsa. Ulangi perintah.',
            errorCode: 'action_expired_in_transaction',
          );
        case VoiceCreateProductCommitStatus.notConfirmed:
          return _terminal(
            action,
            auditStatus: VoiceActionStatus.notConfirmed,
            status: VoiceActionExecutionStatus.notConfirmed,
            message: 'Produk belum dikonfirmasi dan tidak dibuat.',
            errorCode: 'action_not_confirmed_in_transaction',
          );
      }
    } on VoiceCreateProductCommitException catch (error, stackTrace) {
      _debugFailure(action.actionId, error, stackTrace);
      return _commitFailure(action, error.type, authenticationSucceeded);
    } catch (error, stackTrace) {
      _debugFailure(action.actionId, error, stackTrace);
      return _unexpectedFailure(action, authenticationSucceeded);
    }
  }

  Future<VoiceActionExecutionResult> _terminal(
    VoiceActionDraft action, {
    required VoiceActionStatus auditStatus,
    required VoiceActionExecutionStatus status,
    required String message,
    required String errorCode,
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
      errorCode: errorCode,
    );
  }

  Future<VoiceActionExecutionResult> _commitFailure(
    VoiceActionDraft action,
    VoiceCreateProductCommitFailureType failureType,
    bool authenticationSucceeded,
  ) async {
    final auditStatus =
        failureType == VoiceCreateProductCommitFailureType.auditFailure
        ? VoiceActionStatus.auditFailure
        : VoiceActionStatus.databaseFailure;
    final executionStatus =
        failureType == VoiceCreateProductCommitFailureType.auditFailure
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
          'Produk belum berhasil ditambahkan dan tidak ada data yang berubah.',
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
          'Produk belum berhasil ditambahkan dan tidak ada data yang berubah.',
      errorCode: recorded ? 'unexpected_failure' : 'failure_audit_failed',
    );
  }

  Future<void> _refreshAfterCommit(String actionId) async {
    final callback = _onCommitted;
    if (callback == null) return;
    try {
      await callback();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Voice create-product refresh failed '
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
          'Voice create-product audit failed '
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
      'Voice create-product execution failed '
      '(actionId=$actionId, error=${error.runtimeType}): '
      '$error\n$stackTrace',
    );
  }

  String _truncate(String value) {
    const maxLength = 500;
    return value.length <= maxLength ? value : value.substring(0, maxLength);
  }
}
