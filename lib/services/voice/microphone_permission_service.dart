import 'package:permission_handler/permission_handler.dart';

enum MicrophonePermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  error,
}

extension MicrophonePermissionStatePresentation on MicrophonePermissionState {
  bool get canListen => this == MicrophonePermissionState.granted;

  bool get canOpenSettings =>
      this == MicrophonePermissionState.permanentlyDenied;

  String get userMessage => switch (this) {
    MicrophonePermissionState.granted => '',
    MicrophonePermissionState.denied =>
      'Izin mikrofon diperlukan untuk menggunakan fitur suara.',
    MicrophonePermissionState.permanentlyDenied =>
      'Izin mikrofon ditolak permanen. Buka pengaturan aplikasi untuk mengaktifkannya.',
    MicrophonePermissionState.restricted =>
      'Izin mikrofon dibatasi oleh pengaturan perangkat.',
    MicrophonePermissionState.error =>
      'Status izin mikrofon tidak dapat diperiksa. Coba lagi.',
  };
}

abstract interface class MicrophonePermissionService {
  Future<MicrophonePermissionState> check();

  Future<MicrophonePermissionState> request();

  Future<bool> openSettings();
}

class PermissionHandlerMicrophonePermissionService
    implements MicrophonePermissionService {
  const PermissionHandlerMicrophonePermissionService();

  @override
  Future<MicrophonePermissionState> check() async {
    try {
      return _map(await Permission.microphone.status);
    } catch (_) {
      return MicrophonePermissionState.error;
    }
  }

  @override
  Future<MicrophonePermissionState> request() async {
    try {
      return _map(await Permission.microphone.request());
    } catch (_) {
      return MicrophonePermissionState.error;
    }
  }

  @override
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  MicrophonePermissionState _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return MicrophonePermissionState.granted;
    }
    if (status.isPermanentlyDenied) {
      return MicrophonePermissionState.permanentlyDenied;
    }
    if (status.isRestricted) {
      return MicrophonePermissionState.restricted;
    }
    return MicrophonePermissionState.denied;
  }
}
