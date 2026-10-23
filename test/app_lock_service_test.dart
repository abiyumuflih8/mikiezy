import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/models/app_lock_models.dart';
import 'package:mikiezy/domain/models/business_query_data.dart';
import 'package:mikiezy/domain/models/voice_privacy_policy.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/security/app_lock_controller.dart';
import 'package:mikiezy/services/security/biometric_authenticator.dart';
import 'package:mikiezy/services/security/pin_hasher.dart';
import 'package:mikiezy/services/security/secure_pin_store.dart';
import 'package:mikiezy/services/voice/voice_business_query_handler.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';

void main() {
  group('secure PIN', () {
    test(
      'stores a salted Argon2id verifier rather than plaintext PIN',
      () async {
        final store = MemorySecurePinStore();
      final controller = AppLockController(
        securePinStore: store,
          pinHasher: Argon2PinHasher(memory: 1024, iterations: 1),
          biometricAuthenticator: _FakeBiometricAuthenticator(),
        );
        addTearDown(controller.dispose);
        await controller.initialize();

        final result = await controller.configurePin('4826', '4826');
        final serialized = jsonEncode(store.record!.toJson());

        expect(result.isSuccess, isTrue);
        expect(serialized, isNot(contains('4826')));
        expect(store.record!.pinVerifier.algorithm, 'argon2id-v19');
        expect(store.record!.pinVerifier.saltBase64, isNotEmpty);
        expect(store.record!.pinVerifier.verifierBase64, isNotEmpty);
        expect(
          await controller.verifyPin('4826'),
          isA<AppLockOperationResult>(),
        );
      },
    );

    test('correct PIN unlocks and incorrect PIN stays locked', () async {
      final fixture = await _fixture();
      addTearDown(fixture.controller.dispose);
      fixture.controller.lock();

      final wrong = await fixture.controller.verifyPin('9999');
      expect(wrong.status, AppLockOperationStatus.invalidPin);
      expect(fixture.controller.isLocked, isTrue);

      final correct = await fixture.controller.verifyPin('1234');
      expect(correct.isSuccess, isTrue);
      expect(fixture.controller.isLocked, isFalse);
      expect(fixture.controller.failedAttempts, 0);
    });

    test('five failures trigger persisted cooldown', () async {
      final clock = _FakeClock(DateTime(2026, 7, 13, 10));
      final fixture = await _fixture(clock: clock);
      addTearDown(fixture.controller.dispose);
      fixture.controller.lock();

      for (var attempt = 1; attempt <= 5; attempt++) {
        await fixture.controller.verifyPin('9999');
      }

      expect(fixture.controller.isInCooldown, isTrue);
      expect(fixture.store.record!.failedAttempts, 5);
      expect(
        (await fixture.controller.verifyPin('1234')).status,
        AppLockOperationStatus.cooldown,
      );

      clock.advance(const Duration(seconds: 31));
      expect((await fixture.controller.verifyPin('1234')).isSuccess, isTrue);
      expect(fixture.store.record!.failedAttempts, 0);
      expect(fixture.store.record!.cooldownUntil, isNull);
    });
  });

  group('lock lifecycle', () {
    test('locks only after configured background timeout', () async {
      final clock = _FakeClock(DateTime(2026, 7, 13, 10));
      final fixture = await _fixture(clock: clock);
      addTearDown(fixture.controller.dispose);
      await fixture.controller.setTimeout(AppLockTimeoutOption.seconds30);

      fixture.controller.handleLifecycleState(AppLifecycleState.paused);
      clock.advance(const Duration(seconds: 29));
      fixture.controller.handleLifecycleState(AppLifecycleState.resumed);
      expect(fixture.controller.isLocked, isFalse);

      fixture.controller.handleLifecycleState(AppLifecycleState.paused);
      clock.advance(const Duration(seconds: 31));
      fixture.controller.handleLifecycleState(AppLifecycleState.resumed);
      expect(fixture.controller.isLocked, isTrue);
    });

    test(
      'foreground does not unlock or prompt biometric automatically',
      () async {
        final biometric = _FakeBiometricAuthenticator();
        final fixture = await _fixture(biometric: biometric);
        addTearDown(fixture.controller.dispose);
        await fixture.controller.setBiometricEnabled(true);
        fixture.controller.lock();

        fixture.controller.handleLifecycleState(AppLifecycleState.resumed);

        expect(fixture.controller.isLocked, isTrue);
        expect(biometric.authenticateCalls, 0);
      },
    );
  });

  group('biometric and PIN fallback', () {
    test('biometric success unlocks', () async {
      final biometric = _FakeBiometricAuthenticator(
        nextStatus: BiometricAuthenticationStatus.success,
      );
      final fixture = await _fixture(biometric: biometric);
      addTearDown(fixture.controller.dispose);
      await fixture.controller.setBiometricEnabled(true);
      fixture.controller.lock();

      final result = await fixture.controller.unlockWithBiometrics();

      expect(result.isSuccess, isTrue);
      expect(fixture.controller.isLocked, isFalse);
    });

    test('biometric failure and cancel never unlock', () async {
      final biometric = _FakeBiometricAuthenticator(
        nextStatus: BiometricAuthenticationStatus.failed,
      );
      final fixture = await _fixture(biometric: biometric);
      addTearDown(fixture.controller.dispose);
      await fixture.controller.setBiometricEnabled(true);
      fixture.controller.lock();

      expect(
        (await fixture.controller.unlockWithBiometrics()).status,
        AppLockOperationStatus.invalidPin,
      );
      expect(fixture.controller.isLocked, isTrue);

      biometric.nextStatus = BiometricAuthenticationStatus.cancelled;
      expect(
        (await fixture.controller.unlockWithBiometrics()).status,
        AppLockOperationStatus.cancelled,
      );
      expect(fixture.controller.isLocked, isTrue);
    });

    test('unavailable biometric keeps PIN fallback working', () async {
      final biometric = _FakeBiometricAuthenticator(
        capabilityValue: const BiometricCapability.unavailable(),
      );
      final fixture = await _fixture(biometric: biometric);
      addTearDown(fixture.controller.dispose);
      fixture.controller.lock();

      final unavailable = await fixture.controller.setBiometricEnabled(true);
      expect(unavailable.status, AppLockOperationStatus.unavailable);
      expect(fixture.controller.biometricEnabled, isFalse);
      expect((await fixture.controller.verifyPin('1234')).isSuccess, isTrue);
    });
  });

  test('locked privacy blocks a business query before exposing values', () {
    const handler = VoiceBusinessQueryHandler();
    const router = VoiceCommandRouter();
    final response = handler.handle(
      command: router.route('berapa saldo dompet tunai'),
      data: BusinessQueryData(
        wallets: const [
          Wallet(
            id: 'wallet',
            name: 'Tunai',
            balance: 9876543,
            isPrimary: true,
          ),
        ],
        privacyPolicy: const VoicePrivacyPolicy(isAppLocked: true),
      ),
      now: DateTime(2026, 7, 13),
    );

    expect(response.title, 'Aplikasi terkunci');
    expect(response.displayText, contains('Buka kunci'));
    expect(response.displayText, isNot(contains('9876543')));
    expect(response.spokenText, isNot(contains('sembilan juta')));
  });
}

Future<_AppLockFixture> _fixture({
  _FakeClock? clock,
  _FakeBiometricAuthenticator? biometric,
}) async {
  final store = MemorySecurePinStore();
  final controller = AppLockController(
    securePinStore: store,
    pinHasher: _FakePinHasher(),
    biometricAuthenticator: biometric ?? _FakeBiometricAuthenticator(),
    now: clock?.call,
  );
  await controller.initialize();
  final configured = await controller.configurePin('1234', '1234');
  expect(configured.isSuccess, isTrue);
  return _AppLockFixture(controller, store);
}

class _AppLockFixture {
  const _AppLockFixture(this.controller, this.store);

  final AppLockController controller;
  final MemorySecurePinStore store;
}

class _FakePinHasher implements PinHasher {
  @override
  Future<PinVerifierData> createVerifier(String pin) async {
    return PinVerifierData(
      algorithm: 'fake-test-only',
      saltBase64: base64Encode(const [1, 2, 3]),
      verifierBase64: base64Encode(utf8.encode('test-only:$pin')),
      memory: 1,
      iterations: 1,
      parallelism: 1,
      hashLength: 16,
    );
  }

  @override
  Future<bool> verify(String pin, PinVerifierData verifier) async {
    return verifier.verifierBase64 ==
        base64Encode(utf8.encode('test-only:$pin'));
  }
}

class _FakeBiometricAuthenticator implements BiometricAuthenticator {
  _FakeBiometricAuthenticator({
    this.capabilityValue = const BiometricCapability(
      isSupported: true,
      isEnrolled: true,
      label: 'Sidik jari',
    ),
    this.nextStatus = BiometricAuthenticationStatus.success,
  });

  BiometricCapability capabilityValue;
  BiometricAuthenticationStatus nextStatus;
  int authenticateCalls = 0;

  @override
  Future<BiometricAuthenticationResult> authenticate() async {
    authenticateCalls += 1;
    return BiometricAuthenticationResult(nextStatus);
  }

  @override
  Future<BiometricCapability> capability() async => capabilityValue;

  @override
  Future<void> cancel() async {}
}

class _FakeClock {
  _FakeClock(this.value);

  DateTime value;

  DateTime call() => value;

  void advance(Duration duration) {
    value = value.add(duration);
  }
}
