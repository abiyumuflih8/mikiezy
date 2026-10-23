import '../../models/mikiezy_models.dart';
import 'voice_action.dart';
import 'voice_action_payload.dart';

enum VoicePriceUpdateCommitStatus {
  updated,
  alreadyExecuted,
  productNotFound,
  stale,
  expired,
  notConfirmed,
  additionalConfirmationRequired,
  invalidPayload,
  samePrice,
}

class VoicePriceUpdateCommitRequest {
  const VoicePriceUpdateCommitRequest({
    required this.actionId,
    required this.commandFingerprint,
    required this.payload,
    required this.confirmed,
    required this.additionalConfirmationSucceeded,
    required this.expiresAt,
    required this.executionStarted,
    required this.succeeded,
  });

  final String actionId;
  final String commandFingerprint;
  final UpdateProductPriceVoiceActionPayload payload;
  final bool confirmed;
  final bool additionalConfirmationSucceeded;
  final DateTime expiresAt;
  final VoiceActionAuditEvent executionStarted;
  final VoiceActionAuditEvent succeeded;
}

class VoicePriceUpdateCommitResult {
  const VoicePriceUpdateCommitResult({required this.status, this.product});

  final VoicePriceUpdateCommitStatus status;
  final Product? product;
}

enum VoicePriceUpdateCommitFailureType { databaseFailure, auditFailure }

class VoicePriceUpdateCommitException implements Exception {
  const VoicePriceUpdateCommitException({
    required this.type,
    required this.cause,
  });

  final VoicePriceUpdateCommitFailureType type;
  final Object cause;

  @override
  String toString() => 'Voice price update commit failed: ${type.name}';
}
