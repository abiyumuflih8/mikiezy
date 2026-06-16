class VoiceTextNormalizer {
  const VoiceTextNormalizer();

  String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(
          RegExp(r'\b(hai|halo|hey)\s+(miki|mikiezy|miky|micki)\b'),
          '',
        )
        .replaceAll(RegExp(r'\b(miki|mikiezy|miky|micki)\b'), '')
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
