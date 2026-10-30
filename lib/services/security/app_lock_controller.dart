import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../domain/models/app_lock_models.dart';
import '../diagnostics/safe_diagnostics.dart';
import 'biometric_authenticator.dart';
import 'pin_hasher.dart';
import 'secure_pin_store.dart';

class AppLockController extends ChangeNotifier {
  AppLockController({
    required SecurePinStore securePinStore,
    PinHasher? pinHasher,
    BiometricAuthenticator? biometricAuthenticator,
    DateTime Function()? now,
    bool initializeAsUnlocked = false,
  }) : _store = securePinStore,
       _pinHasher = pinHasher ?? Argon2PinHasher(),
       _biometricAuthenticator =
           biometricAuthenticator ?? LocalBiometricAuthenticator(),
       _now = now ?? DateTime.now {
    initialized = initializeAsUnlocked;
  }

  static const maxPinAttempts = 5;
  static const cooldownDuration = Duration(seconds: 30);

  final SecurePinStore _store;
  final PinHasher _pinHasher;
  final BiometricAuthenticator _biometricAuthenticator;
  final DateTime Function() _now;

  SecureAppLockRecord? _record;
  DateTime? _backgroundedAt;
  bool _disposed = false;

  bool initialized = false;
  bool isPinConfigured = false;
  bool isLocked = false;
  bool hasAuthenticatedSession = false;
  bool biometricEnabled = false;
  bool authenticationInProgress = false;
  String? message;
  String? initializationError;
  BiometricCapability biometricCapability =
      const BiometricCapability.unavailable();
  AppLockTimeoutOption timeout = AppLockTimeoutOption.minute1;

  int get failedAttempts => _record?.failedAttempts ?? 0;

  int get remainingAttempts =>
      (maxPinAttempts - failedAttempts).clamp(0, maxPinAttempts);

  DateTime? get cooldownUntil => _record?.cooldownUntil;

  bool get isInCooldown {
    final until = cooldownUntil;
    return until != null && _now().isBefore(until);
  }

  Duration get cooldownRemaining {
    final until = cooldownUntil;
    if (until == null) return Duration.zero;
    final remaining = until.difference(_now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> initialize() async {
    if (initialized) return;
    try {
      _record = await _store.read();
      final record = _record;
      if (record != null) {
        isPinConfigured = true;
        isLocked = true;
        timeout = record.timeout;
      }
      await refreshBiometricCapability(notify: false);
      biometricEnabled =
          record?.biometricEnabled == true && biometricCapability.isAvailable;
    } catch (error, stackTrace) {
      initializationError =
          'Data keamanan tidak dapat dibaca. Aplikasi tetap dikunci.';
      message = initializationError;
      isPinConfigured = true;
      isLocked = true;
      SafeDiagnostics.failure(
        'app_lock_initialization_failed',
        error,
        stackTrace,
      );
    } finally {
      initialized = true;
      _notify();
    }
  }

  Future<AppLockOperationResult> configurePin(
    String pin,
    String confirmation,
  ) async {
    final validation = _validateNewPin(pin, confirmation);
    if (validation != null) return validation;
    try {
      final verifier = await _pinHasher.createVerifier(pin);
      final record = SecureAppLockRecord(
        pinVerifier: verifier,
        biometricEnabled: false,
        timeout: timeout,
      );
      await _store.write(record);
      _record = record;
      isPinConfigured = true;
      isLocked = false;
      hasAuthenticatedSession = false;
      biometricEnabled = false;
      message = null;
      SafeDiagnostics.voiceEvent(
        'app_lock_pin_configured',
        state: isLocked ? 'locked' : 'unlocked',
        status: 'success',
      );
      _notify();
      return const AppLockOperationResult.success('PIN aplikasi telah aktif.');
    } catch (error, stackTrace) {
      _log('Configure PIN failed', error, stackTrace);
      return const AppLockOperationResult(
        status: AppLockOperationStatus.failure,
        message: 'PIN belum dapat disimpan dengan aman.',
      );
    }
  }

  Future<AppLockOperationResult> changePin({
    required String currentPin,
    required String newPin,
    required String confirmation,
  }) async {
    final current = await verifyPin(currentPin, unlockOnSuccess: false);
    if (!current.isSuccess) return current;
    return configurePin(newPin, confirmation);
  }

  Future<AppLockOperationResult> disablePin(String currentPin) async {
    final verified = await verifyPin(currentPin, unlockOnSuccess: false);
    if (!verified.isSuccess) return verified;
    try {
      await _store.clear();
      _record = null;
      isPinConfigured = false;
      isLocked = false;
      hasAuthenticatedSession = false;
      biometricEnabled = false;
      message = null;
      _notify();
      return const AppLockOperationResult.success(
        'Kunci aplikasi dinonaktifkan.',
      );
    } catch (error, stackTrace) {
      _log('Disable PIN failed', error, stackTrace);
      return const AppLockOperationResult(
        status: AppLockOperationStatus.failure,
        message: 'Kunci aplikasi belum dapat dinonaktifkan.',
      );
    }
  }

  Future<AppLockOperationResult> verifyPin(
    String pin, {
    bool unlockOnSuccess = true,
  }) async {
    final record = _record;
    if (record == null) {
      return const AppLockOperationResult(
        status: AppLockOperationStatus.notConfigured,
        message: 'PIN aplikasi belum dikonfigurasi.',
      );
    }
    if (!_isPinFormatValid(pin)) {
      return const AppLockOperationResult(
        status: AppLockOperationStatus.invalidFormat,
        message: 'Masukkan 4 sampai 6 digit PIN.',
      );
    }
    await _clearExpiredCooldown();
    if (isInCooldown) {
      final seconds = cooldownRemaining.inSeconds + 1;
      return AppLockOperationResult(
        status: AppLockOperationStatus.cooldown,
        message: 'Terlalu banyak percobaan. Coba lagi dalam $seconds detik.',
      );
    }

    try {
      final verified = await _pinHasher.verify(pin, record.pinVerifier);
      if (verified) {
        final resetRecord = record.copyWith(
          failedAttempts: 0,
          clearCooldown: true,
        );
        await _store.write(resetRecord);
        _record = resetRecord;
        if (unlockOnSuccess) {
          isLocked = false;
          hasAuthenticatedSession = true;
        }
        message = null;
        SafeDiagnostics.voiceEvent(
          'app_lock_pin_verification',
          state: isLocked ? 'locked' : 'unlocked',
          status: 'success',
        );
        _notify();
        return const AppLockOperationResult.success('Aplikasi terbuka.');
      }

      final attempts = record.failedAttempts + 1;
      final reachedLimit = attempts >= maxPinAttempts;
      final failedRecord = record.copyWith(
        failedAttempts: reachedLimit ? maxPinAttempts : attempts,
        cooldownUntil: reachedLimit ? _now().add(cooldownDuration) : null,
        clearCooldown: !reachedLimit,
      );
      await _store.write(failedRecord);
      _record = failedRecord;
      message = reachedLimit
          ? 'Terlalu banyak percobaan. Tunggu 30 detik.'
          : 'PIN salah. Tersisa $remainingAttempts percobaan.';
      SafeDiagnostics.voiceEvent(
        'app_lock_pin_verification',
        state: 'locked',
        status: reachedLimit ? 'cooldown' : 'rejected',
      );
      _notify();
      return AppLockOperationResult(
        status: reachedLimit
            ? AppLockOperationStatus.cooldown
            : AppLockOperationStatus.invalidPin,
        message: message!,
      );
    } catch (error, stackTrace) {
      _log('Verify PIN failed', error, stackTrace);
      return const AppLockOperationResult(
        status: AppLockOperationStatus.failure,
        message: 'PIN belum dapat diverifikasi.',
      );
    }
  }

  Future<AppLockOperationResult> setBiometricEnabled(bool value) async {
    final record = _record;
    if (record == null) {
      return const AppLockOperationResult(
        status: AppLockOperationStatus.notConfigured,
        message: 'Aktifkan PIN aplikasi terlebih dahulu.',
      );
    }
    if (value) {
      await refreshBiometricCapability();
      if (!biometricCapability.isAvailable) {
        return const AppLockOperationResult(
          status: AppLockOperationStatus.unavailable,
          message:
              'Biometrik belum tersedia atau belum didaftarkan di perangkat.',
        );
      }
    }
    try {
      final updated = record.copyWith(biometricEnabled: value);
      await _store.write(updated);
      _record = updated;
      biometricEnabled = value;
      _notify();
      return AppLockOperationResult.success(
        value ? 'Biometrik diaktifkan.' : 'Biometrik dinonaktifkan.',
      );
    } catch (error, stackTrace) {
      _log('Update biometric setting failed', error, stackTrace);
      return const AppLockOperationResult(
        status: AppLockOperationStatus.failure,
        message: 'Pengaturan biometrik belum dapat disimpan.',
      );
    }
  }

  Future<AppLockOperationResult> unlockWithBiometrics() async {
    if (!biometricEnabled || !biometricCapability.isAvailable) {
      return const AppLockOperationResult(
        status: AppLockOperationStatus.unavailable,
        message: 'Biometrik tidak tersedia. Gunakan PIN.',
      );
    }
    if (authenticationInProgress) {
      return const AppLockOperationResult(
        status: AppLockOperationStatus.failure,
        message: 'Autentikasi sedang berlangsung.',
      );
    }
    authenticationInProgress = true;
    message = null;
    _notify();
    try {
      final result = await _biometricAuthenticator.authenticate();
      if (_disposed) {
        return const AppLockOperationResult(
          status: AppLockOperationStatus.cancelled,
          message: 'Autentikasi dibatalkan.',
        );
      }
      SafeDiagnostics.voiceEvent(
        'app_lock_biometric_result',
        state: isLocked ? 'locked' : 'unlocked',
        status: result.status.name,
      );
      switch (result.status) {
        case BiometricAuthenticationStatus.success:
          isLocked = false;
          hasAuthenticatedSession = true;
          message = null;
          return const AppLockOperationResult.success('Aplikasi terbuka.');
        case BiometricAuthenticationStatus.cancelled:
          return const AppLockOperationResult(
            status: AppLockOperationStatus.cancelled,
            message: 'Autentikasi dibatalkan. Gunakan PIN untuk melanjutkan.',
          );
        case BiometricAuthenticationStatus.unavailable:
          return const AppLockOperationResult(
            status: AppLockOperationStatus.unavailable,
            message: 'Biometrik tidak tersedia. Gunakan PIN.',
          );
        case BiometricAuthenticationStatus.lockedOut:
          return const AppLockOperationResult(
            status: AppLockOperationStatus.unavailable,
            message: 'Biometrik terkunci oleh perangkat. Gunakan PIN.',
          );
        case BiometricAuthenticationStatus.failed:
          return const AppLockOperationResult(
            status: AppLockOperationStatus.invalidPin,
            message: 'Biometrik tidak dikenali. Gunakan PIN atau coba lagi.',
          );
        case BiometricAuthenticationStatus.error:
          return const AppLockOperationResult(
            status: AppLockOperationStatus.failure,
            message: 'Autentikasi biometrik gagal. Gunakan PIN.',
          );
      }
    } finally {
      authenticationInProgress = false;
      _notify();
    }
  }

  Future<void> refreshBiometricCapability({bool notify = true}) async {
    try {
      biometricCapability = await _biometricAuthenticator.capability();
    } catch (error, stackTrace) {
      biometricCapability = const BiometricCapability.unavailable();
      _log('Read biometric capability failed', error, stackTrace);
    }
    if (notify) _notify();
  }

  Future<AppLockOperationResult> setTimeout(AppLockTimeoutOption value) async {
    final record = _record;
    timeout = value;
    if (record == null) {
      _notify();
      return const AppLockOperationResult.success();
    }
    try {
      final updated = record.copyWith(timeout: value);
      await _store.write(updated);
      _record = updated;
      _notify();
      return const AppLockOperationResult.success(
        'Waktu kunci otomatis diperbarui.',
      );
    } catch (error, stackTrace) {
      timeout = record.timeout;
      _log('Update lock timeout failed', error, stackTrace);
      _notify();
      return const AppLockOperationResult(
        status: AppLockOperationStatus.failure,
        message: 'Waktu kunci belum dapat disimpan.',
      );
    }
  }

  void lock() {
    if (!isPinConfigured || isLocked) return;
    isLocked = true;
    hasAuthenticatedSession = false;
    message = null;
    SafeDiagnostics.voiceEvent(
      'app_lock_state_changed',
      state: 'locked',
      status: 'manual_or_timeout',
    );
    _notify();
  }

  void handleLifecycleState(AppLifecycleState state) {
    if (!initialized || !isPinConfigured || authenticationInProgress) return;
    SafeDiagnostics.voiceEvent(
      'app_lock_lifecycle',
      state: isLocked ? 'locked' : 'unlocked',
      status: state.name,
    );
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _backgroundedAt ??= _now();
      case AppLifecycleState.resumed:
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
        if (backgroundedAt != null &&
            _now().difference(backgroundedAt) >= timeout.duration) {
          lock();
        }
      case AppLifecycleState.inactive:
        break;
    }
  }

  void clearMessage() {
    if (message == null) return;
    message = null;
    _notify();
  }

  AppLockOperationResult? _validateNewPin(String pin, String confirmation) {
    if (!_isPinFormatValid(pin)) {
      return const AppLockOperationResult(
        status: AppLockOperationStatus.invalidFormat,
        message: 'PIN harus terdiri dari 4 sampai 6 digit.',
      );
    }
    if (pin != confirmation) {
      return const AppLockOperationResult(
        status: AppLockOperationStatus.mismatch,
        message: 'Konfirmasi PIN tidak sama.',
      );
    }
    return null;
  }

  bool _isPinFormatValid(String pin) => RegExp(r'^\d{4,6}$').hasMatch(pin);

  Future<void> _clearExpiredCooldown() async {
    final record = _record;
    final until = record?.cooldownUntil;
    if (record == null || until == null || _now().isBefore(until)) return;
    final reset = record.copyWith(failedAttempts: 0, clearCooldown: true);
    await _store.write(reset);
    _record = reset;
  }

  void _log(String label, Object error, StackTrace stackTrace) {
    SafeDiagnostics.failure(
      label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
      error,
      stackTrace,
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (authenticationInProgress) {
      unawaited(_biometricAuthenticator.cancel());
    }
    super.dispose();
  }
}
