import '../../models/mikiezy_models.dart';
import 'voice_action.dart';
import 'voice_action_payload.dart';

enum VoiceStockIncrementCommitStatus {
  incremented,
  alreadyExecuted,
  productNotFound,
  stale,
  expired,
  notConfirmed,
  invalidPayload,
  trackingConfirmationRequired,
}

enum VoiceStockIncrementCommitFailureType { databaseFailure, auditFailure }

class VoiceStockIncrementCommitRequest {
  const VoiceStockIncrementCommitRequest({
    required this.actionId,
    required this.commandFingerprint,
    required this.payload,
    required this.confirmed,
    required this.expiresAt,
    required this.executionStarted,
    required this.succeeded,
    this.trackingEnableConfirmed,
  });

  final String actionId;
  final String commandFingerprint;
  final IncrementStockVoiceActionPayload payload;
  final bool confirmed;
  final DateTime expiresAt;
  final VoiceActionAuditEvent executionStarted;
  final VoiceActionAuditEvent succeeded;
  final VoiceActionAuditEvent? trackingEnableConfirmed;
}

class VoiceStockIncrementCommitResult {
  const VoiceStockIncrementCommitResult({required this.status, this.product});

  final VoiceStockIncrementCommitStatus status;
  final Product? product;
}

class VoiceStockIncrementCommitException implements Exception {
  const VoiceStockIncrementCommitException({
    required this.type,
    required this.cause,
  });

  final VoiceStockIncrementCommitFailureType type;
  final Object cause;

  @override
  String toString() => 'Voice stock increment commit failed: ${type.name}';
}
