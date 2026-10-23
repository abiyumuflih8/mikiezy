import 'package:flutter/foundation.dart';

import '../voice_assistant_controller.dart';
import 'voice_command.dart';
import 'voice_parse_context.dart';

abstract interface class GlobalVoiceEngine implements Listenable {
  VoiceAssistantPhase get phase;

  String get transcript;

  String get feedback;

  bool get nativeListening;

  bool get isStarting;

  bool get isAwaitingClarification;

  VoiceAssistantResult? get latestResult;

  VoiceCommandExecutionResult? get latestCommandExecution;

  Future<void> startListening({
    String? initialTranscript,
    bool wakeWordAlreadyDetected,
  });

  Future<VoiceAssistantResult?> stopAndProcess({
    required VoiceParseContext parseContext,
    required bool speakResult,
  });

  Future<void> cancelListening();

  Future<void> cancelPendingMutation({required String errorCode});

  Future<void> speak(String text);

  void clearTranscript();

  void prepareForClarification();

  void dispose();
}

class VoiceAssistantGlobalEngine implements GlobalVoiceEngine {
  VoiceAssistantGlobalEngine(this.controller);

  final VoiceAssistantController controller;

  @override
  VoiceAssistantPhase get phase => controller.phase;

  @override
  String get transcript => controller.transcript;

  @override
  String get feedback => controller.feedback;

  @override
  bool get nativeListening => controller.nativeListening;

  @override
  bool get isStarting => controller.isStarting;

  @override
  bool get isAwaitingClarification => controller.isAwaitingClarification;

  @override
  VoiceAssistantResult? get latestResult => controller.latestResult;

  @override
  VoiceCommandExecutionResult? get latestCommandExecution =>
      controller.latestCommandExecution;

  @override
  void addListener(VoidCallback listener) => controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      controller.removeListener(listener);

  @override
  Future<void> startListening({
    String? initialTranscript,
    bool wakeWordAlreadyDetected = false,
  }) {
    return controller.startListening(
      initialTranscript: initialTranscript,
      wakeWordAlreadyDetected: wakeWordAlreadyDetected,
    );
  }

  @override
  Future<VoiceAssistantResult?> stopAndProcess({
    required VoiceParseContext parseContext,
    required bool speakResult,
  }) {
    return controller.stopAndProcess(
      parseContext: parseContext,
      speakResult: speakResult,
    );
  }

  @override
  Future<void> cancelListening() => controller.cancelListening();

  @override
  Future<void> cancelPendingMutation({required String errorCode}) {
    return controller.cancelPendingMutation(errorCode: errorCode);
  }

  @override
  Future<void> speak(String text) => controller.speak(text);

  @override
  void clearTranscript() => controller.clearTranscript();

  @override
  void prepareForClarification() => controller.prepareForClarification();

  @override
  void dispose() => controller.dispose();
}
