import 'voice_command.dart';

enum VoiceConversationStage {
  collectingEntities,
  awaitingConfirmation,
  awaitingClarification,
}

enum VoiceConversationStatus { waiting, completed, cancelled }

enum VoiceClarificationType {
  productSelection,
  walletSelection,
  pageSelection,
  commandConfirmation,
  missingInformation,
}

class VoiceClarificationCandidate {
  const VoiceClarificationCandidate({
    required this.id,
    required this.name,
    this.aliases = const [],
  });

  final String id;
  final String name;
  final List<String> aliases;
}

class VoiceConversationHandlerMetadata {
  const VoiceConversationHandlerMetadata({required this.handlerId});

  final String handlerId;
}

class VoiceConversationContext {
  VoiceConversationContext({
    required this.command,
    required this.entities,
    required List<String> missingFields,
    required this.stage,
    required this.startedAt,
    required this.expiresAt,
    VoiceCommandIntent? initialIntent,
    String? initialTranscript,
    VoiceCommandEntities? initialEntities,
    this.clarificationType,
    List<VoiceClarificationCandidate> candidates = const [],
    this.selectedCandidate,
    VoiceCommand? pendingCommand,
    this.status = VoiceConversationStatus.waiting,
    this.attemptCount = 0,
    this.maxAttempts = 3,
    this.metadata,
  }) : missingFields = List.unmodifiable(missingFields),
       initialIntent = initialIntent ?? command.intent,
       initialTranscript = initialTranscript ?? command.rawText,
       initialEntities = initialEntities ?? command.entities,
       candidates = List.unmodifiable(candidates),
       pendingCommand = pendingCommand ?? command;

  final VoiceCommand command;
  final VoiceCommandEntities entities;
  final List<String> missingFields;
  final VoiceConversationStage stage;
  final DateTime startedAt;
  final DateTime expiresAt;
  final VoiceCommandIntent initialIntent;
  final String initialTranscript;
  final VoiceCommandEntities initialEntities;
  final VoiceClarificationType? clarificationType;
  final List<VoiceClarificationCandidate> candidates;
  final VoiceClarificationCandidate? selectedCandidate;
  final VoiceCommand pendingCommand;
  final VoiceConversationStatus status;
  final int attemptCount;
  final int maxAttempts;
  final VoiceConversationHandlerMetadata? metadata;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
  bool get isWaitingForAnswer =>
      status == VoiceConversationStatus.waiting &&
      stage == VoiceConversationStage.awaitingClarification;
  bool get hasAttemptsRemaining => attemptCount < maxAttempts;

  VoiceConversationContext copyWith({
    VoiceCommandEntities? entities,
    List<String>? missingFields,
    VoiceConversationStage? stage,
    DateTime? expiresAt,
    List<VoiceClarificationCandidate>? candidates,
    VoiceClarificationCandidate? selectedCandidate,
    VoiceConversationStatus? status,
    int? attemptCount,
  }) {
    return VoiceConversationContext(
      command: command,
      entities: entities ?? this.entities,
      missingFields: missingFields ?? this.missingFields,
      stage: stage ?? this.stage,
      startedAt: startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      initialIntent: initialIntent,
      initialTranscript: initialTranscript,
      initialEntities: initialEntities,
      clarificationType: clarificationType,
      candidates: candidates ?? this.candidates,
      selectedCandidate: selectedCandidate ?? this.selectedCandidate,
      pendingCommand: pendingCommand,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      maxAttempts: maxAttempts,
      metadata: metadata,
    );
  }
}

class VoiceConversationSession {
  VoiceConversationSession({
    this.timeout = const Duration(minutes: 2),
    this.maxClarificationAttempts = 3,
  });

  final Duration timeout;
  final int maxClarificationAttempts;
  VoiceConversationContext? _context;

  bool get hasPending => _context != null;

  VoiceConversationContext? current({DateTime? now}) {
    final context = _context;
    if (context == null) return null;
    if (context.isExpiredAt(now ?? DateTime.now())) {
      _context = null;
      return null;
    }
    return context;
  }

  VoiceConversationContext start(
    VoiceCommand command, {
    List<String> missingFields = const [],
    DateTime? now,
  }) {
    final startedAt = now ?? DateTime.now();
    final context = VoiceConversationContext(
      command: command,
      entities: command.entities,
      missingFields: missingFields,
      stage: VoiceConversationStage.collectingEntities,
      startedAt: startedAt,
      expiresAt: startedAt.add(timeout),
    );
    _context = context;
    return context;
  }

  VoiceConversationContext startClarification({
    required VoiceCommand command,
    required VoiceClarificationType type,
    required List<VoiceClarificationCandidate> candidates,
    VoiceConversationHandlerMetadata? metadata,
    DateTime? now,
  }) {
    final startedAt = now ?? DateTime.now();
    final context = VoiceConversationContext(
      command: command,
      entities: command.entities,
      missingFields: const [],
      stage: VoiceConversationStage.awaitingClarification,
      startedAt: startedAt,
      expiresAt: startedAt.add(timeout),
      clarificationType: type,
      candidates: candidates,
      maxAttempts: maxClarificationAttempts,
      metadata: metadata,
    );
    _context = context;
    return context;
  }

  VoiceConversationContext? update({
    required VoiceCommandEntities entities,
    List<String>? missingFields,
    DateTime? now,
  }) {
    final updatedAt = now ?? DateTime.now();
    final context = current(now: updatedAt);
    if (context == null) return null;
    final updated = context.copyWith(
      entities: context.entities.merge(entities),
      missingFields: missingFields,
      expiresAt: updatedAt.add(timeout),
    );
    _context = updated;
    return updated;
  }

  VoiceConversationContext? recordInvalidAttempt({DateTime? now}) {
    final updatedAt = now ?? DateTime.now();
    final context = current(now: updatedAt);
    if (context == null) return null;
    final updated = context.copyWith(
      attemptCount: context.attemptCount + 1,
      expiresAt: updatedAt.add(timeout),
    );
    _context = updated;
    return updated;
  }

  VoiceConversationContext? select(
    VoiceClarificationCandidate candidate, {
    DateTime? now,
  }) {
    final context = current(now: now);
    if (context == null) return null;
    final updated = context.copyWith(selectedCandidate: candidate);
    _context = updated;
    return updated;
  }

  VoiceConversationContext? waitForConfirmation({DateTime? now}) {
    final updatedAt = now ?? DateTime.now();
    final context = current(now: updatedAt);
    if (context == null) return null;
    final updated = context.copyWith(
      stage: VoiceConversationStage.awaitingConfirmation,
      expiresAt: updatedAt.add(timeout),
    );
    _context = updated;
    return updated;
  }

  void clear() {
    _context = null;
  }
}
