import '../../domain/models/business_query_data.dart';
import '../../domain/models/business_query_result.dart';
import 'voice_business_query_handler.dart';
import 'voice_clarification_parser.dart';
import 'voice_command.dart';
import 'voice_conversation_context.dart';

class VoiceBusinessConversationTurn {
  const VoiceBusinessConversationTurn({
    this.response,
    this.command,
    this.awaitingClarification = false,
    this.routeAsNewCommand = false,
  });

  final VoiceCommandResponse? response;
  final VoiceCommand? command;
  final bool awaitingClarification;
  final bool routeAsNewCommand;
}

class VoiceBusinessConversationHandler {
  VoiceBusinessConversationHandler({
    VoiceBusinessQueryHandler? queryHandler,
    VoiceConversationSession? session,
    this.answerParser = const VoiceClarificationParser(),
  }) : queryHandler = queryHandler ?? const VoiceBusinessQueryHandler(),
       session = session ?? VoiceConversationSession();

  final VoiceBusinessQueryHandler queryHandler;
  final VoiceConversationSession session;
  final VoiceClarificationParser answerParser;

  bool isAwaitingClarification({DateTime? now}) {
    return session.current(now: now)?.isWaitingForAnswer ?? false;
  }

  VoiceBusinessConversationTurn handleCommand({
    required VoiceCommand command,
    required BusinessQueryData data,
    required DateTime now,
  }) {
    final result = queryHandler.query(command: command, data: data, now: now);
    final response = queryHandler.responseFor(result: result, data: data);
    if (result.status == BusinessQueryStatus.ambiguous &&
        result.items.isNotEmpty) {
      session.startClarification(
        command: command,
        type: _clarificationType(result.metric),
        candidates: result.items
            .map(
              (item) => VoiceClarificationCandidate(
                id: item.id ?? item.name,
                name: item.name,
              ),
            )
            .toList(growable: false),
        metadata: const VoiceConversationHandlerMetadata(
          handlerId: 'business-query',
        ),
        now: now,
      );
      return VoiceBusinessConversationTurn(
        response: response,
        command: command,
        awaitingClarification: true,
      );
    }
    session.clear();
    return VoiceBusinessConversationTurn(response: response, command: command);
  }

  VoiceBusinessConversationTurn handleAnswer({
    required String transcript,
    required BusinessQueryData data,
    required DateTime now,
  }) {
    final hadPending = session.hasPending;
    final context = session.current(now: now);
    if (context == null) {
      return VoiceBusinessConversationTurn(
        response: VoiceCommandResponse(
          displayText: hadPending
              ? 'Pilihan sebelumnya sudah kedaluwarsa. Ulangi pertanyaanmu.'
              : 'Tidak ada pilihan yang sedang menunggu jawaban.',
          kind: VoiceResponseKind.question,
        ),
      );
    }

    final answer = answerParser.parse(transcript, context.candidates);
    switch (answer.type) {
      case VoiceClarificationAnswerType.cancel:
        session.clear();
        return const VoiceBusinessConversationTurn(
          response: VoiceCommandResponse(
            displayText: 'Baik, pilihan dibatalkan.',
          ),
        );
      case VoiceClarificationAnswerType.repeatOptions:
        return VoiceBusinessConversationTurn(
          response: _optionsResponse(context.candidates),
          command: context.pendingCommand,
          awaitingClarification: true,
        );
      case VoiceClarificationAnswerType.newCommand:
        session.clear();
        return const VoiceBusinessConversationTurn(routeAsNewCommand: true);
      case VoiceClarificationAnswerType.invalid:
        final updated = session.recordInvalidAttempt(now: now);
        if (updated == null || !updated.hasAttemptsRemaining) {
          session.clear();
          return const VoiceBusinessConversationTurn(
            response: VoiceCommandResponse(
              displayText:
                  'Pilihan belum dapat dipastikan. Perintah dibatalkan agar tidak memilih data yang salah.',
              kind: VoiceResponseKind.error,
            ),
          );
        }
        return VoiceBusinessConversationTurn(
          response: VoiceCommandResponse(
            displayText:
                'Pilihan belum cocok. Sebutkan nama, ukuran, atau nomor pilihan. ${_optionsText(updated.candidates)}',
            kind: VoiceResponseKind.question,
          ),
          command: updated.pendingCommand,
          awaitingClarification: true,
        );
      case VoiceClarificationAnswerType.selected:
        final candidate = answer.candidate!;
        session.select(candidate, now: now);
        final selectedCommand = _withCandidate(context, candidate);
        try {
          final result = queryHandler.query(
            command: selectedCommand,
            data: data,
            now: now,
          );
          session.clear();
          return VoiceBusinessConversationTurn(
            response: queryHandler.responseFor(result: result, data: data),
            command: selectedCommand,
          );
        } catch (_) {
          session.clear();
          return VoiceBusinessConversationTurn(
            response: const VoiceCommandResponse(
              displayText: 'Data belum dapat dibaca. Silakan coba lagi.',
              kind: VoiceResponseKind.error,
            ),
            command: selectedCommand,
          );
        }
    }
  }

  void clear() => session.clear();

  VoiceCommand _withCandidate(
    VoiceConversationContext context,
    VoiceClarificationCandidate candidate,
  ) {
    final selectedEntities = switch (context.clarificationType) {
      VoiceClarificationType.productSelection => VoiceCommandEntities(
        productName: candidate.name,
      ),
      VoiceClarificationType.walletSelection => VoiceCommandEntities(
        walletName: candidate.name,
      ),
      _ => const VoiceCommandEntities(),
    };
    final pending = context.pendingCommand;
    return VoiceCommand(
      rawText: pending.rawText,
      normalizedText: pending.normalizedText,
      intent: pending.intent,
      entities: pending.entities.merge(selectedEntities),
      confidence: pending.confidence,
      hasMultipleIntents: pending.hasMultipleIntents,
    );
  }

  VoiceClarificationType _clarificationType(BusinessMetricType metric) {
    return switch (metric) {
      BusinessMetricType.productStock =>
        VoiceClarificationType.productSelection,
      BusinessMetricType.walletBalance =>
        VoiceClarificationType.walletSelection,
      _ => VoiceClarificationType.missingInformation,
    };
  }

  VoiceCommandResponse _optionsResponse(
    List<VoiceClarificationCandidate> candidates,
  ) {
    return VoiceCommandResponse(
      displayText: _optionsText(candidates),
      kind: VoiceResponseKind.question,
    );
  }

  static String _optionsText(List<VoiceClarificationCandidate> candidates) {
    final options = <String>[
      for (var index = 0; index < candidates.length; index++)
        '${index + 1}. ${candidates[index].name}',
    ];
    return 'Pilih salah satu: ${options.join(', ')}.';
  }
}
