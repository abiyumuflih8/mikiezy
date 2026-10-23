import 'package:local_auth/local_auth.dart';

import '../../domain/models/app_lock_models.dart';

abstract interface class BiometricAuthenticator {
  Future<BiometricCapability> capability();

  Future<BiometricAuthenticationResult> authenticate();

  Future<void> cancel();
}

class UnavailableBiometricAuthenticator implements BiometricAuthenticator {
  const UnavailableBiometricAuthenticator();

  @override
  Future<BiometricAuthenticationResult> authenticate() async {
    return const BiometricAuthenticationResult(
      BiometricAuthenticationStatus.unavailable,
    );
  }

  @override
  Future<BiometricCapability> capability() async {
    return const BiometricCapability.unavailable();
  }

  @override
  Future<void> cancel() async {}
}

class LocalBiometricAuthenticator implements BiometricAuthenticator {
  LocalBiometricAuthenticator({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  @override
  Future<BiometricCapability> capability() async {
    final supported = await _authentication.isDeviceSupported();
    if (!supported || !await _authentication.canCheckBiometrics) {
      return const BiometricCapability.unavailable();
    }
    final enrolled = await _authentication.getAvailableBiometrics();
    final label = enrolled.contains(BiometricType.face)
        ? 'Face ID / scan wajah'
        : enrolled.contains(BiometricType.fingerprint)
        ? 'Sidik jari'
        : 'Biometrik';
    return BiometricCapability(
      isSupported: true,
      isEnrolled: enrolled.isNotEmpty,
      label: label,
    );
  }

  @override
  Future<BiometricAuthenticationResult> authenticate() async {
    try {
      final authenticated = await _authentication.authenticate(
        localizedReason: 'Buka kunci aplikasi Mikiezy',
        biometricOnly: true,
        persistAcrossBackgrounding: false,
      );
      return BiometricAuthenticationResult(
        authenticated
            ? BiometricAuthenticationStatus.success
            : BiometricAuthenticationStatus.failed,
      );
    } on LocalAuthException catch (error) {
      final status = switch (error.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback =>
          BiometricAuthenticationStatus.cancelled,
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
          BiometricAuthenticationStatus.unavailable,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
          BiometricAuthenticationStatus.lockedOut,
        _ => BiometricAuthenticationStatus.error,
      };
      return BiometricAuthenticationResult(status, message: error.description);
    } catch (error) {
      return BiometricAuthenticationResult(
        BiometricAuthenticationStatus.error,
        message: error.toString(),
      );
    }
  }

  @override
  Future<void> cancel() async {
    await _authentication.stopAuthentication();
  }
}
