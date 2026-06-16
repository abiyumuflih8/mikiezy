class WakeWordDetector {
  const WakeWordDetector();

  static final RegExp _wakeWordPattern = RegExp(
    r'\b(hey\s+)?(oke\s+)?miki\b',
    caseSensitive: false,
  );

  bool containsWakeWord(String transcript) {
    return _wakeWordPattern.hasMatch(transcript);
  }

  String stripWakeWord(String transcript) {
    final match = _wakeWordPattern.firstMatch(transcript);
    if (match == null) return transcript.trim();
    return transcript
        .substring(match.end)
        .replaceFirst(RegExp(r'^[,.\s]+'), '')
        .trim();
  }
}
