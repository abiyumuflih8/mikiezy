import 'package:flutter/foundation.dart';

import '../../data/repositories/mikiezy_repository.dart';
import '../../domain/models/product_price.dart';
import '../../domain/models/voice_action.dart';
import '../../domain/models/voice_action_payload.dart';
import '../../domain/models/voice_price_update_undo.dart';
import '../../domain/services/stable_fingerprint_service.dart';

class VoicePriceUpdateUndoService {
  VoicePriceUpdateUndoService(
    this._repository, {
    this.fingerprintService = const StableFingerprintService(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final MikiezyRepository _repository;
  final StableFingerprintService fingerprintService;
  final DateTime Function() _now;

  Future<VoicePriceUpdateUndoResult> reverse(
    UpdateProductPriceVoiceActionPayload payload, {
    String? undoActionId,
  }) async {
    if (payload.actionId.trim().isEmpty ||
        payload.commandFingerprint.trim().isEmpty ||
        payload.productId.trim().isEmpty ||
        payload.productFingerprint.trim().isEmpty ||
        payload.expectedProductFingerprintAfter.trim().isEmpty ||
        payload.oldPrice == payload.newPrice ||
        payload.validationErrors.isNotEmpty) {
      return const VoicePriceUpdateUndoResult(
        status: VoicePriceUpdateUndoStatus.invalidRequest,
        errorCode: 'invalid_undo_payload',
      );
    }

    final now = _now();
    final commandFingerprint = await fingerprintService.create(
      [
        'undo-product-price',
        payload.actionId,
        payload.commandFingerprint,
        payload.productId,
        payload.priceType.name,
        payload.oldPrice,
        payload.newPrice,
        payload.expectedProductFingerprintAfter,
      ].join('|'),
    );
    final actionId =
        undoActionId ??
        'voice-undo-${now.microsecondsSinceEpoch}-${commandFingerprint.substring(0, 10)}';
    final beforeSummary = '${payload.priceType.fieldName}: ${payload.newPrice}';
    final afterSummary = '${payload.priceType.fieldName}: ${payload.oldPrice}';
    final request = VoicePriceUpdateUndoRequest(
      undoActionId: actionId,
      undoCommandFingerprint: commandFingerprint,
      originalActionId: payload.actionId,
      originalCommandFingerprint: payload.commandFingerprint,
      productId: payload.productId,
      productName: payload.productName,
      priceType: payload.priceType,
      oldPrice: payload.oldPrice,
      newPrice: payload.newPrice,
      expectedCurrentProductFingerprint:
          payload.expectedProductFingerprintAfter,
      expectedRestoredProductFingerprint: payload.productFingerprint,
      requested: _audit(
        actionId: actionId,
        commandFingerprint: commandFingerprint,
        payload: payload,
        status: VoiceActionStatus.undoRequested,
        undoStatus: VoiceUndoStatus.available,
        beforeSummary: beforeSummary,
        afterSummary: afterSummary,
        createdAt: now,
      ),
      succeeded: _audit(
        actionId: actionId,
        commandFingerprint: commandFingerprint,
        payload: payload,
        status: VoiceActionStatus.undoSucceeded,
        undoStatus: VoiceUndoStatus.completed,
        beforeSummary: beforeSummary,
        afterSummary: afterSummary,
        createdAt: now.add(const Duration(seconds: 1)),
      ),
      rejected: _audit(
        actionId: actionId,
        commandFingerprint: commandFingerprint,
        payload: payload,
        status: VoiceActionStatus.undoRejected,
        undoStatus: VoiceUndoStatus.rejected,
        beforeSummary: beforeSummary,
        afterSummary: afterSummary,
        createdAt: now.add(const Duration(seconds: 1)),
      ),
    );

    try {
      return await _repository.undoProductPriceUpdate(request);
    } on VoicePriceUpdateUndoException catch (error, stackTrace) {
      _debugFailure(actionId, error, stackTrace);
      final status = error.type == VoicePriceUpdateUndoFailureType.auditFailure
          ? VoicePriceUpdateUndoStatus.auditFailure
          : VoicePriceUpdateUndoStatus.databaseFailure;
      final recorded = await _recordFailure(
        request,
        error.type.name,
        createdAt: _now(),
      );
      return VoicePriceUpdateUndoResult(
        status: recorded ? status : VoicePriceUpdateUndoStatus.auditFailure,
        errorCode: recorded ? error.type.name : 'undo_failure_audit_failed',
      );
    } catch (error, stackTrace) {
      _debugFailure(actionId, error, stackTrace);
      final recorded = await _recordFailure(
        request,
        'unexpected_undo_failure',
        createdAt: _now(),
      );
      return VoicePriceUpdateUndoResult(
        status: recorded
            ? VoicePriceUpdateUndoStatus.unexpectedFailure
            : VoicePriceUpdateUndoStatus.auditFailure,
        errorCode: recorded
            ? 'unexpected_undo_failure'
            : 'undo_failure_audit_failed',
      );
    }
  }

  Future<bool> _recordFailure(
    VoicePriceUpdateUndoRequest request,
    String errorCode, {
    required DateTime createdAt,
  }) async {
    try {
      await _repository.recordVoiceActionAudit(
        VoiceActionAuditEvent(
          id: '${request.undoActionId}-undoFailed',
          actionId: request.undoActionId,
          actionType: VoiceActionType.updateProductPrice,
          source: VoiceActionSource.voice,
          status: VoiceActionStatus.undoFailed,
          targetEntityType: 'product',
          targetEntityId: request.productId,
          beforeSummary: '${request.priceType.fieldName}: ${request.newPrice}',
          afterSummary: '${request.priceType.fieldName}: ${request.oldPrice}',
          confirmed: true,
          errorCode: errorCode,
          undoStatus: VoiceUndoStatus.failed,
          commandFingerprint: request.undoCommandFingerprint,
          createdAt: createdAt,
        ),
      );
      return true;
    } catch (error, stackTrace) {
      _debugFailure(request.undoActionId, error, stackTrace);
      return false;
    }
  }

  VoiceActionAuditEvent _audit({
    required String actionId,
    required String commandFingerprint,
    required UpdateProductPriceVoiceActionPayload payload,
    required VoiceActionStatus status,
    required VoiceUndoStatus undoStatus,
    required String beforeSummary,
    required String afterSummary,
    required DateTime createdAt,
  }) {
    return VoiceActionAuditEvent(
      id: '$actionId-${status.name}',
      actionId: actionId,
      actionType: VoiceActionType.updateProductPrice,
      source: VoiceActionSource.voice,
      status: status,
      targetEntityType: 'product',
      targetEntityId: payload.productId,
      beforeSummary: beforeSummary,
      afterSummary: afterSummary,
      confirmed: true,
      undoStatus: undoStatus,
      commandFingerprint: commandFingerprint,
      createdAt: createdAt,
    );
  }

  void _debugFailure(String actionId, Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    debugPrint(
      'Voice price undo failed '
      '(actionId=$actionId, error=${error.runtimeType}): '
      '$error\n$stackTrace',
    );
  }
}
