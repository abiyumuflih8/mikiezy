class WakeWordDetector {
  const WakeWordDetector();

  bool containsWakeWord(String transcript) {
    return _findWakeWord(transcript) != null;
  }

  String stripWakeWord(String transcript) {
    final match = _findWakeWord(transcript);
    if (match == null) return transcript.trim();
    return transcript
        .substring(match.endIndex)
        .replaceFirst(RegExp(r'^[,.\s]+'), '')
        .trim();
  }

  _WakeWordMatch? _findWakeWord(String transcript) {
    final matches = RegExp(
      r'[a-zA-Z0-9]+',
    ).allMatches(transcript).toList(growable: false);
    for (var index = 0; index < matches.length; index++) {
      final token = matches[index].group(0) ?? '';
      if (_isWakeToken(token)) {
        return _WakeWordMatch(matches[index].start, matches[index].end);
      }

      if (index < matches.length - 1) {
        final combined = '$token${matches[index + 1].group(0) ?? ''}';
        if (_isWakeToken(combined)) {
          return _WakeWordMatch(matches[index].start, matches[index + 1].end);
        }
      }
    }
    return null;
  }

  bool _isWakeToken(String token) {
    final normalized = _normalizeWakeToken(token);
    return _wakeTokens.contains(normalized);
  }

  String _normalizeWakeToken(String token) {
    final lower = token.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    final compressed = lower.replaceAllMapped(
      RegExp(r'([a-z])\1+'),
      (match) => match.group(1)!,
    );
    return compressed
        .replaceAll('ck', 'k')
        .replaceAll('c', 'k')
        .replaceAll('y', 'i');
  }

  static const _wakeTokens = {
    'miki',
    'micki',
    'mikie',
    'mikiezi',
    'mikiezy',
    'mikei',
  };
}

class _WakeWordMatch {
  const _WakeWordMatch(this.startIndex, this.endIndex);

  final int startIndex;
  final int endIndex;
}
