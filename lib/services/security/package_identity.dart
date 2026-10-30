import 'package:flutter/services.dart';

/// Contract for querying installed package identity and build flavor.
abstract class PackageIdentity {
  const PackageIdentity();

  static const String expectedDiagnosticPackage = 'com.mikiezy.mikiezy.qa.audit';
  static const String expectedDiagnosticFlavor = 'qaAudit';
  static const String prodPackage = 'com.mikiezy.mikiezy';
  static const String qaGoldenSamplePackage = 'com.mikiezy.mikiezy.qa';

  /// Asynchronously retrieves the installed Android application package name.
  Future<String?> getPackageName();

  /// Synchronously retrieves the Flutter app flavor string if present.
  String? getAppFlavor();

  /// Returns true if and only if both the package name and flavor match the isolated diagnostic identity.
  Future<bool> isDiagnosticPackage() async {
    final name = await getPackageName();
    if (name != expectedDiagnosticPackage) return false;
    // When flavor is available, it must also match expected diagnostic flavor.
    final flavor = getAppFlavor();
    if (flavor != null && flavor != expectedDiagnosticFlavor) return false;
    return true;
  }
}

/// Default production/device implementation using native platform channel.
class NativePackageIdentity extends PackageIdentity {
  const NativePackageIdentity({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.mikiezy/package_identity');

  final MethodChannel _channel;

  @override
  Future<String?> getPackageName() async {
    try {
      final result = await _channel.invokeMethod<String>('getPackageName');
      return result;
    } catch (_) {
      return null;
    }
  }

  @override
  String? getAppFlavor() => appFlavor;
}

/// Test/synthetic package identity fixture for automated host verification.
class TestPackageIdentity extends PackageIdentity {
  const TestPackageIdentity({
    this.packageName,
    this.flavor,
    this.simulateError = false,
  });

  final String? packageName;
  final String? flavor;
  final bool simulateError;

  @override
  Future<String?> getPackageName() async {
    if (simulateError) return null;
    return packageName;
  }

  @override
  String? getAppFlavor() => flavor;
}
