enum VoiceActionConfirmationDecision {
  confirm,
  cancel,
  edit,
  repeat,
  details,
  unknown,
}

class VoiceActionConfirmationParser {
  const VoiceActionConfirmationParser();

  VoiceActionConfirmationDecision parse(String value) {
    final text = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (RegExp(r'\b(tidak|batal|batalkan|jangan)\b').hasMatch(text)) {
      return VoiceActionConfirmationDecision.cancel;
    }
    if (RegExp(r'\b(lihat detail|detail|rincian)\b').hasMatch(text)) {
      return VoiceActionConfirmationDecision.details;
    }
    if (RegExp(r'\b(ubah|edit|koreksi)\b').hasMatch(text)) {
      return VoiceActionConfirmationDecision.edit;
    }
    if (RegExp(r'\b(ulangi|ulang|sebutkan lagi)\b').hasMatch(text)) {
      return VoiceActionConfirmationDecision.repeat;
    }
    if (RegExp(
      r'\b(ya|iya|konfirmasi|lanjutkan|lanjut|setuju)\b',
    ).hasMatch(text)) {
      return VoiceActionConfirmationDecision.confirm;
    }
    return VoiceActionConfirmationDecision.unknown;
  }
}
