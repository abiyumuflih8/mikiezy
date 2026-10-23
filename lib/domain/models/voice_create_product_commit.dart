import 'voice_action.dart';
import 'voice_action_payload.dart';
import '../../models/mikiezy_models.dart';

enum VoiceCreateProductCommitStatus {
  created,
  alreadyExecuted,
  duplicateProduct,
  expired,
  notConfirmed,
}

class VoiceCreateProductCommitResult {
  const VoiceCreateProductCommitResult({
    required this.status,
    this.product,
    this.existingProduct,
  });

  final VoiceCreateProductCommitStatus status;
  final Product? product;
  final Product? existingProduct;
}

enum VoiceCreateProductCommitFailureType { databaseFailure, auditFailure }

class VoiceCreateProductCommitException implements Exception {
  const VoiceCreateProductCommitException({
    required this.type,
    required this.cause,
  });

  final VoiceCreateProductCommitFailureType type;
  final Object cause;

  @override
  String toString() => 'Voice create-product commit failed: ${type.name}';
}

class VoiceCreateProductCommitRequest {
  const VoiceCreateProductCommitRequest({
    required this.actionId,
    required this.commandFingerprint,
    required this.payload,
    required this.categoryPosition,
    required this.confirmed,
    required this.expiresAt,
    required this.executionStarted,
    required this.succeeded,
    required this.duplicateRejected,
  });

  final String actionId;
  final String commandFingerprint;
  final CreateProductVoiceActionPayload payload;
  final int categoryPosition;
  final bool confirmed;
  final DateTime expiresAt;
  final VoiceActionAuditEvent executionStarted;
  final VoiceActionAuditEvent succeeded;
  final VoiceActionAuditEvent duplicateRejected;
}
