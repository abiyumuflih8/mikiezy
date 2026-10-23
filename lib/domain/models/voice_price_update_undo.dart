import '../../models/mikiezy_models.dart';
import 'product_price.dart';
import 'voice_action.dart';

enum VoicePriceUpdateUndoStatus {
  reverted,
  alreadyReversed,
  originalActionNotFound,
  productNotFound,
  stale,
  invalidRequest,
  databaseFailure,
  auditFailure,
  unexpectedFailure,
}

enum VoicePriceUpdateUndoFailureType { databaseFailure, auditFailure }

class VoicePriceUpdateUndoRequest {
  const VoicePriceUpdateUndoRequest({
    required this.undoActionId,
    required this.undoCommandFingerprint,
    required this.originalActionId,
    required this.originalCommandFingerprint,
    required this.productId,
    required this.productName,
    required this.priceType,
    required this.oldPrice,
    required this.newPrice,
    required this.expectedCurrentProductFingerprint,
    required this.expectedRestoredProductFingerprint,
    required this.requested,
    required this.succeeded,
    required this.rejected,
  });

  final String undoActionId;
  final String undoCommandFingerprint;
  final String originalActionId;
  final String originalCommandFingerprint;
  final String productId;
  final String productName;
  final ProductPriceType priceType;
  final int oldPrice;
  final int newPrice;
  final String expectedCurrentProductFingerprint;
  final String expectedRestoredProductFingerprint;
  final VoiceActionAuditEvent requested;
  final VoiceActionAuditEvent succeeded;
  final VoiceActionAuditEvent rejected;

  VoiceActionAuditEvent rejectionEvent(String errorCode) {
    return VoiceActionAuditEvent(
      id: rejected.id,
      actionId: rejected.actionId,
      actionType: rejected.actionType,
      source: rejected.source,
      status: rejected.status,
      targetEntityType: rejected.targetEntityType,
      targetEntityId: rejected.targetEntityId,
      beforeSummary: rejected.beforeSummary,
      afterSummary: rejected.afterSummary,
      confirmed: rejected.confirmed,
      authenticationRequired: rejected.authenticationRequired,
      authenticationSucceeded: rejected.authenticationSucceeded,
      errorCode: errorCode,
      undoStatus: rejected.undoStatus,
      commandFingerprint: rejected.commandFingerprint,
      createdAt: rejected.createdAt,
    );
  }
}

class VoicePriceUpdateUndoResult {
  const VoicePriceUpdateUndoResult({
    required this.status,
    this.product,
    this.errorCode,
  });

  final VoicePriceUpdateUndoStatus status;
  final Product? product;
  final String? errorCode;

  bool get isSuccess => status == VoicePriceUpdateUndoStatus.reverted;
}

class VoicePriceUpdateUndoException implements Exception {
  const VoicePriceUpdateUndoException({required this.type, this.cause});

  final VoicePriceUpdateUndoFailureType type;
  final Object? cause;

  @override
  String toString() => 'Voice price update undo failed: ${type.name}';
}
