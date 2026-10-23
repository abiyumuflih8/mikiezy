import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/services/voice/microphone_permission_service.dart';
import 'package:mikiezy/services/voice/silence_detector.dart';
import 'package:mikiezy/services/voice/voice_assistant_manager.dart';
import 'package:mikiezy/services/voice/wake_word_detector.dart';
import 'package:mikiezy/services/voice/voice_text_normalizer.dart';
import 'package:mikiezy/state/app_state.dart';

void main() {
  test('wake word detector recognizes Miki variants', () {
    const detector = WakeWordDetector();

    expect(detector.containsWakeWord('miki'), isTrue);
    expect(detector.containsWakeWord('miky'), isTrue);
    expect(detector.containsWakeWord('mickey'), isTrue);
    expect(detector.containsWakeWord('mickie'), isTrue);
    expect(detector.containsWakeWord('miiiki'), isTrue);
    expect(detector.containsWakeWord('mi ki'), isTrue);
    expect(detector.containsWakeWord('hey miki'), isTrue);
    expect(detector.containsWakeWord('hey mickey'), isTrue);
    expect(detector.containsWakeWord('halo miki'), isTrue);
    expect(detector.containsWakeWord('miki catat'), isTrue);
    expect(detector.containsWakeWord('oke miki'), isTrue);
    expect(detector.containsWakeWord('tolong miki catat penjualan'), isTrue);
    expect(detector.containsWakeWord('catat penjualan ayam'), isFalse);
    expect(detector.containsWakeWord('minyak goreng'), isFalse);
    expect(detector.containsWakeWord('mika plastik'), isFalse);
  });

  test('wake word detector strips only the wake phrase', () {
    const detector = WakeWordDetector();

    expect(
      detector.stripWakeWord('Miki catat penjualan ayam bakar'),
      'catat penjualan ayam bakar',
    );
    expect(
      detector.stripWakeWord('hey miki, jual nasi goreng'),
      'jual nasi goreng',
    );
    expect(
      detector.stripWakeWord('hey mickey, jual nasi goreng'),
      'jual nasi goreng',
    );
    expect(detector.stripWakeWord('miiiki jual es teh'), 'jual es teh');
    expect(detector.stripWakeWord('mi ki jual es teh'), 'jual es teh');
  });

  test('voice normalizer strips fuzzy wake word before parsing', () {
    const normalizer = VoiceTextNormalizer();

    expect(
      normalizer.normalize('Mickey, jual nasi goreng 2 porsi Rp15.000'),
      'jual nasi goreng 2 porsi 15.000',
    );
    expect(
      normalizer.normalize('mi ki jual es teh 3 gelas Rp5.000'),
      'jual es teh 3 gelas 5.000',
    );
  });

  test('wake word manager clears native stopped state during startup', () {
    final state = MikiezyState.seeded();
    final manager = VoiceAssistantManager(
      state: state,
      onPreviewRequested: (_) {},
    );

    manager.simulateWakeWordListeningForTest(isStarting: true);
    manager.handleSpeechStatusForTest('notListening');

    expect(manager.debugSpeechActive, isFalse);

    manager.dispose();
    state.dispose();
  });

  test('wake word manager ignores permission result after dispose', () async {
    final state = MikiezyState.seeded();
    final permissions = _PendingMicrophonePermissionService();
    final manager = VoiceAssistantManager(
      state: state,
      onPreviewRequested: (_) {},
      microphonePermissionService: permissions,
    );

    manager.attachForeground();
    await permissions.checkStarted;
    manager.dispose();
    permissions.complete(MicrophonePermissionState.granted);

    await Future<void>.delayed(Duration.zero);
    state.dispose();
  });

  test('silence detector fires after timeout and can be stopped', () async {
    var fired = false;
    final detector = SilenceDetector(timeout: const Duration(milliseconds: 15));
    detector.start(() => fired = true);

    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(fired, isTrue);

    fired = false;
    detector.start(() => fired = true);
    detector.stop();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(fired, isFalse);
  });
}

class _PendingMicrophonePermissionService
    implements MicrophonePermissionService {
  final _checkCompleter = Completer<MicrophonePermissionState>();
  final _checkStarted = Completer<void>();

  Future<void> get checkStarted => _checkStarted.future;

  void complete(MicrophonePermissionState state) {
    _checkCompleter.complete(state);
  }

  @override
  Future<MicrophonePermissionState> check() {
    if (!_checkStarted.isCompleted) _checkStarted.complete();
    return _checkCompleter.future;
  }

  @override
  Future<bool> openSettings() async => false;

  @override
  Future<MicrophonePermissionState> request() async =>
      MicrophonePermissionState.denied;
}
