import 'package:flutter/foundation.dart';

class SafeTranscriptDiagnostic {
  const SafeTranscriptDiagnostic({
    required this.finalCharacters,
    required this.partialCharacters,
    required this.combinedCharacters,
    required this.combinedWords,
    required this.fingerprint,
  });

  factory SafeTranscriptDiagnostic.fromBuffers({
    required String finalText,
    required String partialText,
    required String combinedText,
  }) {
    return SafeTranscriptDiagnostic(
      finalCharacters: finalText.length,
      partialCharacters: partialText.length,
      combinedCharacters: combinedText.length,
      combinedWords: _wordCount(combinedText),
      fingerprint: SafeDiagnostics.shortFingerprint(combinedText),
    );
  }

  final int finalCharacters;
  final int partialCharacters;
  final int combinedCharacters;
  final int combinedWords;
  final String fingerprint;

  static int _wordCount(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? 0 : normalized.split(RegExp(r'\s+')).length;
  }
}

abstract final class SafeDiagnostics {
  static void voiceTranscript({
    required String event,
    required String finalText,
    required String partialText,
    required String combinedText,
  }) {
    if (!kDebugMode) return;
    final diagnostic = SafeTranscriptDiagnostic.fromBuffers(
      finalText: finalText,
      partialText: partialText,
      combinedText: combinedText,
    );
    debugPrint(
      'MikiezyDiag event=$event '
      'finalChars=${diagnostic.finalCharacters} '
      'partialChars=${diagnostic.partialCharacters} '
      'combinedChars=${diagnostic.combinedCharacters} '
      'combinedWords=${diagnostic.combinedWords} '
      'transcriptFp=${diagnostic.fingerprint}',
    );
  }

  static void voiceEvent(
    String event, {
    int? generation,
    String? state,
    String? intent,
    String? status,
    String? permission,
    String? route,
    String? actionFingerprint,
    int? durationMilliseconds,
  }) {
    if (!kDebugMode) return;
    final fields = <String>[
      'MikiezyDiag event=$event',
      if (generation != null) 'generation=$generation',
      if (state != null) 'state=$state',
      if (intent != null) 'intent=$intent',
      if (status != null) 'status=$status',
      if (permission != null) 'permission=$permission',
      if (route != null) 'route=$route',
      if (actionFingerprint != null)
        'actionFp=${_safeIdentifier(actionFingerprint)}',
      if (durationMilliseconds != null) 'durationMs=$durationMilliseconds',
    ];
    debugPrint(fields.join(' '));
  }

  static void failure(String event, Object error, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    final frames = stackTrace?.toString().split(RegExp(r'\r?\n'));
    final firstFrame = frames == null || frames.isEmpty
        ? null
        : frames.first.trim();
    debugPrint(
      [
        'MikiezyDiag event=$event',
        'errorType=${error.runtimeType}',
        if (firstFrame != null && firstFrame.isNotEmpty)
          'stack=${_safeStackFrame(firstFrame)}',
      ].join(' '),
    );
  }

  static String shortFingerprint(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String _safeIdentifier(String value) {
    final normalized = value.replaceAll(RegExp(r'[^a-zA-Z0-9_.:-]'), '_');
    return normalized.length <= 24 ? normalized : normalized.substring(0, 24);
  }

  static String _safeStackFrame(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), '_');
    return normalized.length <= 160 ? normalized : normalized.substring(0, 160);
  }
}
