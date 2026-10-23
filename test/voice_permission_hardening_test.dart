import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/services/voice/microphone_permission_service.dart';
import 'package:mikiezy/services/voice_assistant_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'denied microphone permission never starts speech recognition',
    () async {
      final permissions = _FakeMicrophonePermissionService(
        requestResult: MicrophonePermissionState.denied,
      );
      final spoken = <String>[];
      final controller = VoiceAssistantController(
        microphonePermissionService: permissions,
        speakOverride: (text) async => spoken.add(text),
      );
      addTearDown(controller.dispose);

      await controller.startListening();

      expect(controller.phase, VoiceAssistantPhase.permissionDenied);
      expect(controller.nativeListening, isFalse);
      expect(
        controller.feedback,
        'Izin mikrofon diperlukan untuk menggunakan fitur suara.',
      );
      expect(permissions.requestCount, 1);
      expect(permissions.openSettingsCount, 0);
      expect(spoken, [controller.feedback]);
    },
  );

  test('permission service error is fail-closed instead of granted', () async {
    final permissions = _FakeMicrophonePermissionService(
      requestResult: MicrophonePermissionState.error,
    );
    final controller = VoiceAssistantController(
      microphonePermissionService: permissions,
      speakOverride: (_) async {},
    );
    addTearDown(controller.dispose);

    await controller.startListening();

    expect(controller.phase, VoiceAssistantPhase.permissionDenied);
    expect(controller.nativeListening, isFalse);
    expect(
      controller.feedback,
      'Status izin mikrofon tidak dapat diperiksa. Coba lagi.',
    );
  });

  test('permanent denial opens settings only after explicit action', () async {
    final permissions = _FakeMicrophonePermissionService(
      requestResult: MicrophonePermissionState.permanentlyDenied,
      settingsResult: true,
    );
    final controller = VoiceAssistantController(
      microphonePermissionService: permissions,
      speakOverride: (_) async {},
    );
    addTearDown(controller.dispose);

    await controller.startListening();
    expect(permissions.openSettingsCount, 0);
    expect(controller.microphonePermissionState.canOpenSettings, isTrue);
    expect(
      controller.feedback,
      'Izin mikrofon ditolak permanen. Buka pengaturan aplikasi untuk mengaktifkannya.',
    );

    final opened = await controller.openMicrophoneSettings();

    expect(opened, isTrue);
    expect(permissions.openSettingsCount, 1);
  });

  test('ordinary denial cannot open application settings implicitly', () async {
    final permissions = _FakeMicrophonePermissionService(
      requestResult: MicrophonePermissionState.denied,
      settingsResult: true,
    );
    final controller = VoiceAssistantController(
      microphonePermissionService: permissions,
      speakOverride: (_) async {},
    );
    addTearDown(controller.dispose);
    await controller.startListening();

    final opened = await controller.openMicrophoneSettings();

    expect(opened, isFalse);
    expect(permissions.openSettingsCount, 0);
  });

  test('disposed controller ignores a pending permission callback', () async {
    final permissions = _PendingMicrophonePermissionService();
    final controller = VoiceAssistantController(
      microphonePermissionService: permissions,
      speakOverride: (_) async {},
    );

    final pendingStart = controller.startListening();
    controller.dispose();
    permissions.complete(MicrophonePermissionState.denied);

    await expectLater(pendingStart, completes);
  });

  test('disposed controller ignores late native speech status', () {
    final controller = VoiceAssistantController(
      microphonePermissionService: _FakeMicrophonePermissionService(
        requestResult: MicrophonePermissionState.denied,
      ),
      speakOverride: (_) async {},
    );

    controller.dispose();

    expect(
      () => controller.handleSpeechStatusForTest('notListening'),
      returnsNormally,
    );
  });
}

class _FakeMicrophonePermissionService implements MicrophonePermissionService {
  _FakeMicrophonePermissionService({
    required this.requestResult,
    this.settingsResult = false,
  });

  final MicrophonePermissionState requestResult;
  final bool settingsResult;
  int requestCount = 0;
  int openSettingsCount = 0;

  @override
  Future<MicrophonePermissionState> check() async =>
      MicrophonePermissionState.denied;

  @override
  Future<bool> openSettings() async {
    openSettingsCount += 1;
    return settingsResult;
  }

  @override
  Future<MicrophonePermissionState> request() async {
    requestCount += 1;
    return requestResult;
  }
}

class _PendingMicrophonePermissionService
    implements MicrophonePermissionService {
  final _requestCompleter = Completer<MicrophonePermissionState>();

  void complete(MicrophonePermissionState state) {
    _requestCompleter.complete(state);
  }

  @override
  Future<MicrophonePermissionState> check() async =>
      MicrophonePermissionState.denied;

  @override
  Future<bool> openSettings() async => false;

  @override
  Future<MicrophonePermissionState> request() => _requestCompleter.future;
}
