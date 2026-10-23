enum AppLockTimeoutOption {
  immediately,
  seconds30,
  minute1,
  minutes5,
  minutes15,
}

extension AppLockTimeoutOptionX on AppLockTimeoutOption {
  String get storageValue => name;

  Duration get duration => switch (this) {
    AppLockTimeoutOption.immediately => Duration.zero,
    AppLockTimeoutOption.seconds30 => const Duration(seconds: 30),
    AppLockTimeoutOption.minute1 => const Duration(minutes: 1),
    AppLockTimeoutOption.minutes5 => const Duration(minutes: 5),
    AppLockTimeoutOption.minutes15 => const Duration(minutes: 15),
  };

  String get label => switch (this) {
    AppLockTimeoutOption.immediately => 'Langsung',
    AppLockTimeoutOption.seconds30 => '30 detik',
    AppLockTimeoutOption.minute1 => '1 menit',
    AppLockTimeoutOption.minutes5 => '5 menit',
    AppLockTimeoutOption.minutes15 => '15 menit',
  };
}

AppLockTimeoutOption appLockTimeoutFromStorage(String? value) {
  return AppLockTimeoutOption.values.firstWhere(
    (option) => option.storageValue == value,
    orElse: () => AppLockTimeoutOption.minute1,
  );
}

enum AppLockOperationStatus {
  success,
  invalidFormat,
  mismatch,
  invalidPin,
  cooldown,
  notConfigured,
  unavailable,
  cancelled,
  failure,
}

class AppLockOperationResult {
  const AppLockOperationResult({required this.status, required this.message});

  const AppLockOperationResult.success([this.message = 'Berhasil.'])
    : status = AppLockOperationStatus.success;

  final AppLockOperationStatus status;
  final String message;

  bool get isSuccess => status == AppLockOperationStatus.success;
}

class PinVerifierData {
  const PinVerifierData({
    required this.algorithm,
    required this.saltBase64,
    required this.verifierBase64,
    required this.memory,
    required this.iterations,
    required this.parallelism,
    required this.hashLength,
  });

  final String algorithm;
  final String saltBase64;
  final String verifierBase64;
  final int memory;
  final int iterations;
  final int parallelism;
  final int hashLength;

  Map<String, Object> toJson() => {
    'algorithm': algorithm,
    'salt': saltBase64,
    'verifier': verifierBase64,
    'memory': memory,
    'iterations': iterations,
    'parallelism': parallelism,
    'hashLength': hashLength,
  };

  factory PinVerifierData.fromJson(Map<String, Object?> json) {
    return PinVerifierData(
      algorithm: json['algorithm'] as String,
      saltBase64: json['salt'] as String,
      verifierBase64: json['verifier'] as String,
      memory: json['memory'] as int,
      iterations: json['iterations'] as int,
      parallelism: json['parallelism'] as int,
      hashLength: json['hashLength'] as int,
    );
  }
}

class SecureAppLockRecord {
  const SecureAppLockRecord({
    required this.pinVerifier,
    this.failedAttempts = 0,
    this.cooldownUntil,
    this.biometricEnabled = false,
    this.timeout = AppLockTimeoutOption.minute1,
  });

  final PinVerifierData pinVerifier;
  final int failedAttempts;
  final DateTime? cooldownUntil;
  final bool biometricEnabled;
  final AppLockTimeoutOption timeout;

  SecureAppLockRecord copyWith({
    PinVerifierData? pinVerifier,
    int? failedAttempts,
    DateTime? cooldownUntil,
    bool clearCooldown = false,
    bool? biometricEnabled,
    AppLockTimeoutOption? timeout,
  }) {
    return SecureAppLockRecord(
      pinVerifier: pinVerifier ?? this.pinVerifier,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      cooldownUntil: clearCooldown
          ? null
          : (cooldownUntil ?? this.cooldownUntil),
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      timeout: timeout ?? this.timeout,
    );
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'pinVerifier': pinVerifier.toJson(),
    'failedAttempts': failedAttempts,
    'cooldownUntil': cooldownUntil?.toUtc().toIso8601String(),
    'biometricEnabled': biometricEnabled,
    'timeout': timeout.storageValue,
  };

  factory SecureAppLockRecord.fromJson(Map<String, Object?> json) {
    final verifier = json['pinVerifier'];
    if (json['version'] != 1 || verifier is! Map) {
      throw const FormatException('Format app lock tidak didukung.');
    }
    return SecureAppLockRecord(
      pinVerifier: PinVerifierData.fromJson(
        Map<String, Object?>.from(verifier),
      ),
      failedAttempts: (json['failedAttempts'] as int?) ?? 0,
      cooldownUntil: switch (json['cooldownUntil']) {
        final String value when value.isNotEmpty => DateTime.parse(value),
        _ => null,
      },
      biometricEnabled: (json['biometricEnabled'] as bool?) ?? false,
      timeout: appLockTimeoutFromStorage(json['timeout'] as String?),
    );
  }
}

class BiometricCapability {
  const BiometricCapability({
    required this.isSupported,
    required this.isEnrolled,
    this.label = 'Biometrik',
  });

  const BiometricCapability.unavailable()
    : isSupported = false,
      isEnrolled = false,
      label = 'Biometrik';

  final bool isSupported;
  final bool isEnrolled;
  final String label;

  bool get isAvailable => isSupported && isEnrolled;
}

enum BiometricAuthenticationStatus {
  success,
  failed,
  cancelled,
  unavailable,
  lockedOut,
  error,
}

class BiometricAuthenticationResult {
  const BiometricAuthenticationResult(this.status, {this.message});

  final BiometricAuthenticationStatus status;
  final String? message;

  bool get isSuccess => status == BiometricAuthenticationStatus.success;
}
