import '../models/voice_action.dart';

abstract interface class VoiceActionUndoService {
  Future<VoiceUndoResult> reverse(VoiceUndoRequest request);
}

class PreviewOnlyVoiceActionUndoService implements VoiceActionUndoService {
  const PreviewOnlyVoiceActionUndoService();

  @override
  Future<VoiceUndoResult> reverse(VoiceUndoRequest request) async {
    return const VoiceUndoResult(
      status: VoiceUndoStatus.notAvailable,
      message:
          'Undo belum tersedia karena reversal belum dapat dibuktikan aman tanpa riwayat mutasi stok.',
    );
  }
}
