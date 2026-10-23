import 'voice_action_payload.dart';

enum VoiceActionType {
  createProduct,
  incrementProductStock,
  updateProductPrice,
  adjustStock,
  updateProfile,
  updateSettings,
  deleteProduct,
  cancelTransaction,
  deleteTransaction,
  updateWalletBalance,
}

enum VoiceActionRisk { low, medium, high }

enum VoiceActionStatus {
  draft,
  clarificationRequested,
  previewed,
  confirmed,
  authenticationRequired,
  authenticationSucceeded,
  authenticationFailed,
  notConfirmed,
  cancelled,
  expired,
  stale,
  blockedLocked,
  executionDisabled,
  executionStarted,
  succeeded,
  duplicateRejected,
  unitRejected,
  trackingEnableConfirmed,
  warningShown,
  additionalConfirmationRequired,
  additionalConfirmationConfirmed,
  validationFailed,
  validationRejected,
  staleRejected,
  alreadyExecuted,
  databaseFailure,
  auditFailure,
  stateRefreshFailed,
  transactionRolledBack,
  undoRequested,
  undoSucceeded,
  undoRejected,
  undoFailed,
  failed,
}

enum VoiceActionSource { voice, manual }

enum VoiceUndoStatus {
  notAvailable,
  available,
  completed,
  alreadyReversed,
  rejected,
  failed,
}

class VoiceActionSnapshot {
  VoiceActionSnapshot({
    required this.entityType,
    this.entityId,
    required this.fingerprint,
    Map<String, String> fields = const {},
  }) : fields = Map.unmodifiable(fields);

  final String entityType;
  final String? entityId;
  final String fingerprint;
  final Map<String, String> fields;

  String get redactedSummary {
    return fields.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('; ');
  }
}

class VoiceActionFieldChange {
  const VoiceActionFieldChange({
    required this.field,
    required this.label,
    this.before,
    required this.after,
  });

  final String field;
  final String label;
  final String? before;
  final String after;
}

class VoiceActionDraft {
  VoiceActionDraft({
    required this.actionId,
    required this.type,
    required this.summary,
    required this.risk,
    required this.requiresAuthentication,
    required this.isReversible,
    required this.createdAt,
    required this.expiresAt,
    required this.sourceTranscript,
    required this.commandFingerprint,
    required this.baseFingerprint,
    this.before,
    this.payload,
    required this.proposed,
    List<VoiceActionFieldChange> changes = const [],
    List<String> validationErrors = const [],
    this.status = VoiceActionStatus.draft,
  }) : changes = List.unmodifiable(changes),
       validationErrors = List.unmodifiable(validationErrors);

  final String actionId;
  final VoiceActionType type;
  final VoiceActionSnapshot? before;
  final VoiceActionPayload? payload;
  final VoiceActionSnapshot proposed;
  final List<VoiceActionFieldChange> changes;
  final String summary;
  final VoiceActionRisk risk;
  final bool requiresAuthentication;
  final bool isReversible;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String sourceTranscript;
  final String commandFingerprint;
  final String baseFingerprint;
  final List<String> validationErrors;
  final VoiceActionStatus status;

  bool get isValid => validationErrors.isEmpty;

  bool isExpiredAt(DateTime value) => !value.isBefore(expiresAt);

  VoiceActionDraft copyWith({VoiceActionStatus? status}) {
    return VoiceActionDraft(
      actionId: actionId,
      type: type,
      before: before,
      payload: payload,
      proposed: proposed,
      changes: changes,
      summary: summary,
      risk: risk,
      requiresAuthentication: requiresAuthentication,
      isReversible: isReversible,
      createdAt: createdAt,
      expiresAt: expiresAt,
      sourceTranscript: sourceTranscript,
      commandFingerprint: commandFingerprint,
      baseFingerprint: baseFingerprint,
      validationErrors: validationErrors,
      status: status ?? this.status,
    );
  }
}

class VoiceActionAuditEvent {
  const VoiceActionAuditEvent({
    required this.id,
    required this.actionId,
    required this.actionType,
    required this.source,
    required this.status,
    this.targetEntityType,
    this.targetEntityId,
    this.beforeSummary = '',
    this.afterSummary = '',
    this.confirmed = false,
    this.authenticationRequired = false,
    this.authenticationSucceeded = false,
    this.errorCode,
    this.undoStatus = VoiceUndoStatus.notAvailable,
    required this.commandFingerprint,
    required this.createdAt,
  });

  final String id;
  final String actionId;
  final VoiceActionType actionType;
  final VoiceActionSource source;
  final VoiceActionStatus status;
  final String? targetEntityType;
  final String? targetEntityId;
  final String beforeSummary;
  final String afterSummary;
  final bool confirmed;
  final bool authenticationRequired;
  final bool authenticationSucceeded;
  final String? errorCode;
  final VoiceUndoStatus undoStatus;
  final String commandFingerprint;
  final DateTime createdAt;
}

class VoiceUndoRequest {
  const VoiceUndoRequest({
    required this.actionId,
    required this.actionType,
    required this.entityFingerprint,
  });

  final String actionId;
  final VoiceActionType actionType;
  final String entityFingerprint;
}

class VoiceUndoResult {
  const VoiceUndoResult({required this.status, required this.message});

  final VoiceUndoStatus status;
  final String message;

  bool get isSuccess => status == VoiceUndoStatus.completed;
}
