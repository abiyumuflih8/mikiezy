import 'wake_word_detector.dart';

class VoiceTextNormalizer {
  const VoiceTextNormalizer();

  static const _wakeWordDetector = WakeWordDetector();

  String normalize(String input) {
    return _wakeWordDetector
        .stripWakeWord(input)
        .toLowerCase()
        .replaceAll(RegExp(r'\brp\.?\s*'), '')
        .replaceAll(RegExp(r'\bmasing masing\b'), 'masing-masing')
        .replaceAll(RegExp(r'\bper\s+1\b'), 'per')
        .replaceAll(RegExp(r'[;]'), ',')
        .replaceAll(RegExp(r'[!?]'), ' ')
        .replaceAll(RegExp(r'\s*,\s*'), ', ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
