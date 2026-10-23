import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';
import 'package:mikiezy/services/voice/voice_navigation_handler.dart';
import 'package:mikiezy/services/voice_assistant_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const router = VoiceCommandRouter();

  test(
    'all supported navigation commands reach the typed navigation port',
    () async {
      final navigation = _FakeNavigationPort();
      final handler = VoiceNavigationHandler(navigation: navigation);
      final commands = <String, VoiceNavigationTarget>{
        'Buka dashboard': VoiceNavigationTarget.dashboard,
        'Buka transaksi': VoiceNavigationTarget.transactions,
        'Buka produk': VoiceNavigationTarget.products,
        'Buka laporan': VoiceNavigationTarget.reports,
        'Buka analitik': VoiceNavigationTarget.analytics,
        'Buka dompet': VoiceNavigationTarget.wallets,
        'Buka kategori': VoiceNavigationTarget.categories,
        'Buka pengaturan': VoiceNavigationTarget.settings,
        'Buka edit profil': VoiceNavigationTarget.editProfile,
        'Buka input suara': VoiceNavigationTarget.voiceEntry,
        'Kembali': VoiceNavigationTarget.back,
      };

      for (final entry in commands.entries) {
        final command = router.route(entry.key);
        final response = await handler.handle(command);
        expect(command.intent.isNavigation, isTrue, reason: entry.key);
        expect(navigation.calls.last, entry.value, reason: entry.key);
        expect(response.kind, VoiceResponseKind.information);
      }
    },
  );

  test(
    'already-there, blocked, and background outcomes are explicit',
    () async {
      final navigation = _FakeNavigationPort();
      final handler = VoiceNavigationHandler(navigation: navigation);
      final command = router.route('Buka produk');

      navigation.status = VoiceNavigationStatus.alreadyThere;
      expect((await handler.handle(command)).displayText, contains('sudah'));

      navigation.status = VoiceNavigationStatus.blocked;
      expect((await handler.handle(command)).displayText, contains('ditahan'));

      navigation.status = VoiceNavigationStatus.notForeground;
      expect((await handler.handle(command)).displayText, contains('terbuka'));
    },
  );

  test('navigation intent never enters transaction preview flow', () async {
    final navigation = _FakeNavigationPort();
    final controller = VoiceAssistantController(
      navigationHandler: VoiceNavigationHandler(navigation: navigation),
    );
    addTearDown(controller.dispose);
    controller.setTranscript('Buka produk');

    final result = await controller.processCurrentTranscript(
      speakResult: false,
    );

    expect(result, isNull);
    expect(controller.latestResult, isNull);
    expect(controller.latestCommandExecution?.handled, isTrue);
    expect(navigation.calls, [VoiceNavigationTarget.products]);
  });

  test('fingerprint prevents duplicate navigation execution', () async {
    final navigation = _FakeNavigationPort();
    final controller = VoiceAssistantController(
      navigationHandler: VoiceNavigationHandler(navigation: navigation),
    );
    addTearDown(controller.dispose);
    controller.setTranscript('Buka analitik');

    await controller.processCurrentTranscript(speakResult: false);
    await controller.processCurrentTranscript(speakResult: false);

    expect(navigation.calls, [VoiceNavigationTarget.analytics]);
  });

  test('legacy sale command still produces a transaction result', () async {
    final navigation = _FakeNavigationPort();
    final controller = VoiceAssistantController(
      navigationHandler: VoiceNavigationHandler(navigation: navigation),
    );
    addTearDown(controller.dispose);
    controller.setTranscript('Jual kopi susu 2 gelas 10000');

    final result = await controller.processCurrentTranscript(
      speakResult: false,
    );

    expect(result, isNotNull);
    expect(result?.draft.lines, isNotEmpty);
    expect(navigation.calls, isEmpty);
  });

  test('data mutation command stays blocked and never opens preview', () async {
    final controller = VoiceAssistantController();
    addTearDown(controller.dispose);
    controller.setTranscript('Tambah produk kopi baru');

    final result = await controller.processCurrentTranscript(
      speakResult: false,
    );

    expect(result, isNull);
    expect(controller.latestResult, isNull);
    expect(controller.latestCommandExecution?.handled, isFalse);
    expect(controller.latestCommandResponse?.displayText, contains('belum'));
  });

  test('late navigation result is ignored after controller disposal', () async {
    final navigation = _DelayedNavigationPort();
    final controller = VoiceAssistantController(
      navigationHandler: VoiceNavigationHandler(navigation: navigation),
    );
    controller.setTranscript('Buka pengaturan');

    final processing = controller.processCurrentTranscript(speakResult: false);
    await navigation.started.future;
    controller.dispose();
    navigation.release.complete();
    await processing;

    expect(controller.latestCommandExecution, isNull);
  });
}

class _FakeNavigationPort implements VoiceNavigationPort {
  VoiceNavigationStatus status = VoiceNavigationStatus.navigated;
  final List<VoiceNavigationTarget> calls = [];

  @override
  Future<VoiceNavigationOutcome> navigate(VoiceNavigationTarget target) async {
    calls.add(target);
    return VoiceNavigationOutcome(status: status, target: target);
  }
}

class _DelayedNavigationPort implements VoiceNavigationPort {
  final Completer<void> started = Completer<void>();
  final Completer<void> release = Completer<void>();

  @override
  Future<VoiceNavigationOutcome> navigate(VoiceNavigationTarget target) async {
    started.complete();
    await release.future;
    return VoiceNavigationOutcome(
      status: VoiceNavigationStatus.navigated,
      target: target,
    );
  }
}
