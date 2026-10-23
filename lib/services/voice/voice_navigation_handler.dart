import 'voice_command.dart';

enum VoiceNavigationStatus {
  navigated,
  alreadyThere,
  blocked,
  notForeground,
  unavailable,
}

class VoiceNavigationOutcome {
  const VoiceNavigationOutcome({required this.status, required this.target});

  final VoiceNavigationStatus status;
  final VoiceNavigationTarget target;
}

abstract interface class VoiceNavigationPort {
  Future<VoiceNavigationOutcome> navigate(VoiceNavigationTarget target);
}

class VoiceNavigationHandler {
  const VoiceNavigationHandler({required this.navigation});

  final VoiceNavigationPort navigation;

  bool supports(VoiceCommandIntent intent) => intent.isNavigation;

  Future<VoiceCommandResponse> handle(VoiceCommand command) async {
    final target = command.entities.navigationTarget;
    if (target == null) {
      return const VoiceCommandResponse(
        displayText: 'Halaman tujuan belum dikenali.',
        kind: VoiceResponseKind.error,
      );
    }
    final outcome = await navigation.navigate(target);
    final responseTarget = outcome.target;
    final label = _label(responseTarget);
    return switch (outcome.status) {
      VoiceNavigationStatus.navigated => VoiceCommandResponse(
        displayText: responseTarget == VoiceNavigationTarget.back
            ? 'Kembali ke halaman sebelumnya.'
            : 'Membuka $label.',
      ),
      VoiceNavigationStatus.alreadyThere => VoiceCommandResponse(
        displayText: 'Kamu sudah berada di $label.',
      ),
      VoiceNavigationStatus.blocked => const VoiceCommandResponse(
        displayText:
            'Navigasi ditahan karena ada preview atau formulir yang belum ditutup.',
        kind: VoiceResponseKind.question,
      ),
      VoiceNavigationStatus.notForeground => const VoiceCommandResponse(
        displayText: 'Navigasi hanya dapat dijalankan saat aplikasi terbuka.',
        kind: VoiceResponseKind.error,
      ),
      VoiceNavigationStatus.unavailable => VoiceCommandResponse(
        displayText: 'Halaman $label belum tersedia.',
        kind: VoiceResponseKind.error,
      ),
    };
  }

  String _label(VoiceNavigationTarget target) {
    return switch (target) {
      VoiceNavigationTarget.dashboard => 'dashboard',
      VoiceNavigationTarget.transactions => 'daftar transaksi',
      VoiceNavigationTarget.products => 'daftar produk',
      VoiceNavigationTarget.reports ||
      VoiceNavigationTarget.analytics => 'halaman analitik',
      VoiceNavigationTarget.wallets => 'halaman dompet',
      VoiceNavigationTarget.categories => 'halaman kategori',
      VoiceNavigationTarget.settings => 'pengaturan',
      VoiceNavigationTarget.editProfile => 'edit profil',
      VoiceNavigationTarget.voiceEntry => 'pencatatan suara',
      VoiceNavigationTarget.back => 'halaman sebelumnya',
    };
  }
}
