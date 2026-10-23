import 'dart:async';

import 'package:flutter/foundation.dart';

import 'voice_command.dart';
import 'voice_conversation_context.dart';
import 'voice_response_builder.dart';

typedef VoiceCommandHandler =
    FutureOr<VoiceCommandResponse> Function(
      VoiceCommand command,
      VoiceConversationContext? context,
    );

class VoiceCommandExecutor {
  VoiceCommandExecutor({
    Map<VoiceCommandIntent, VoiceCommandHandler> handlers = const {},
    this.responseBuilder = const VoiceResponseBuilder(),
  }) : _handlers = Map.unmodifiable(handlers);

  final Map<VoiceCommandIntent, VoiceCommandHandler> _handlers;
  final VoiceResponseBuilder responseBuilder;

  bool supports(VoiceCommandIntent intent) => _handlers.containsKey(intent);

  Future<VoiceCommandExecutionResult> execute(
    VoiceCommand command, {
    VoiceConversationContext? context,
    bool confirmed = false,
    Map<VoiceCommandIntent, VoiceCommandHandler> runtimeHandlers = const {},
  }) async {
    if (command.hasMultipleIntents) {
      return VoiceCommandExecutionResult(
        command: command,
        response: responseBuilder.multipleCommands(),
        handled: false,
      );
    }

    if (command.intent == VoiceCommandIntent.unknown) {
      return VoiceCommandExecutionResult(
        command: command,
        response: responseBuilder.unknown(),
        handled: false,
      );
    }

    final handler =
        runtimeHandlers[command.intent] ?? _handlers[command.intent];
    if (handler == null) {
      return VoiceCommandExecutionResult(
        command: command,
        response: responseBuilder.unsupported(command),
        handled: false,
      );
    }

    if (command.intent.requiresConfirmation && !confirmed) {
      return VoiceCommandExecutionResult(
        command: command,
        response: responseBuilder.confirmationRequired(),
        handled: false,
      );
    }

    try {
      final response = await handler(command, context);
      return VoiceCommandExecutionResult(
        command: command,
        response: response,
        handled: true,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Voice command execution failed: $error\n$stackTrace');
      }
      return VoiceCommandExecutionResult(
        command: command,
        response: responseBuilder.error(
          'Perintah belum dapat dijalankan. Silakan coba lagi.',
        ),
        handled: false,
      );
    }
  }
}
