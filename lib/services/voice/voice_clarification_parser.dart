import 'voice_conversation_context.dart';

enum VoiceClarificationAnswerType {
  selected,
  cancel,
  repeatOptions,
  newCommand,
  invalid,
}

class VoiceClarificationAnswer {
  const VoiceClarificationAnswer(this.type, {this.candidate});

  final VoiceClarificationAnswerType type;
  final VoiceClarificationCandidate? candidate;
}

class VoiceClarificationParser {
  const VoiceClarificationParser();

  VoiceClarificationAnswer parse(
    String transcript,
    List<VoiceClarificationCandidate> candidates,
  ) {
    final normalized = _normalize(transcript);
    if (normalized.isEmpty) {
      return const VoiceClarificationAnswer(
        VoiceClarificationAnswerType.invalid,
      );
    }
    if (RegExp(r'\b(batal|berhenti)\b').hasMatch(normalized) ||
        normalized == 'kembali') {
      return const VoiceClarificationAnswer(
        VoiceClarificationAnswerType.cancel,
      );
    }
    if (normalized.contains('ulangi pilihan') ||
        normalized.contains('sebutkan lagi')) {
      return const VoiceClarificationAnswer(
        VoiceClarificationAnswerType.repeatOptions,
      );
    }

    final ordinal = _ordinalIndex(normalized, candidates.length);
    if (ordinal != null) {
      return VoiceClarificationAnswer(
        VoiceClarificationAnswerType.selected,
        candidate: candidates[ordinal],
      );
    }

    final selected = _uniqueNameMatch(normalized, candidates);
    if (selected != null) {
      return VoiceClarificationAnswer(
        VoiceClarificationAnswerType.selected,
        candidate: selected,
      );
    }

    if (normalized.startsWith('mulai perintah baru') ||
        RegExp(
          r'^(buka|tampilkan|pergi|masuk|berapa|cek|jual|catat|omzet|saldo|stok)\b',
        ).hasMatch(normalized)) {
      return const VoiceClarificationAnswer(
        VoiceClarificationAnswerType.newCommand,
      );
    }
    return const VoiceClarificationAnswer(VoiceClarificationAnswerType.invalid);
  }

  VoiceClarificationCandidate? _uniqueNameMatch(
    String answer,
    List<VoiceClarificationCandidate> candidates,
  ) {
    final cleanedAnswer = answer
        .replaceFirst(RegExp(r'^(yang|pilih|produk|dompet)\s+'), '')
        .trim();
    if (cleanedAnswer.isEmpty) return null;
    final matches = candidates
        .where((candidate) {
          final variants = [
            candidate.name,
            ...candidate.aliases,
          ].map(_normalize);
          return variants.any(
            (variant) =>
                variant == cleanedAnswer ||
                variant.contains(cleanedAnswer) ||
                cleanedAnswer.contains(variant),
          );
        })
        .toList(growable: false);
    return matches.length == 1 ? matches.single : null;
  }

  int? _ordinalIndex(String value, int length) {
    if (value.contains('yang terakhir') || value == 'terakhir') {
      return length == 0 ? null : length - 1;
    }
    const ordinals = <String, int>{
      'pertama': 0,
      'satu': 0,
      '1': 0,
      'kedua': 1,
      'dua': 1,
      '2': 1,
      'ketiga': 2,
      'tiga': 2,
      '3': 2,
      'keempat': 3,
      'empat': 3,
      '4': 3,
      'kelima': 4,
      'lima': 4,
      '5': 4,
    };
    for (final entry in ordinals.entries) {
      if (value == entry.key ||
          RegExp('^(?:yang|nomor|pilihan)\\s+${entry.key}\$').hasMatch(value)) {
        return entry.value < length ? entry.value : null;
      }
    }
    return null;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('satu setengah', '1 5')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
