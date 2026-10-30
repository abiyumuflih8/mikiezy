import 'app_lock_controller.dart';
import 'package:mikiezy/services/security/package_identity.dart';

/// The three-layer security gate governing access to internal QA audit diagnostics.
enum DiagnosticsGateStatus {
  authorized,
  disabledByCompileTimeFlag,
  unauthorizedPackage,
  uninitializedAppLock,
  pinNotConfigured,
  appLocked,
  unauthenticatedSession,
  detectionFailed,
}

class DiagnosticsSecurityGate {
  const DiagnosticsSecurityGate({
    PackageIdentity? packageIdentity,
    this._optInOverride,
  }) : _packageIdentity = packageIdentity ?? const NativePackageIdentity();

  /// Layer 1: Compile-time opt-in flag. Default is false.
  static const bool kEnableQaAuditDiagnostics = bool.fromEnvironment(
    'ENABLE_QA_AUDIT_DIAGNOSTICS',
    defaultValue: false,
  );

  final PackageIdentity _packageIdentity;
  final bool? _optInOverride;

  bool get isOptInEnabled => _optInOverride ?? kEnableQaAuditDiagnostics;

  /// Evaluates all three layers and returns a deterministic authorization status.
  Future<DiagnosticsGateStatus> checkAuthorization({
    required AppLockController? appLockController,
  }) async {
    // Layer 1: Compile-time opt-in check
    if (!isOptInEnabled) {
      return DiagnosticsGateStatus.disabledByCompileTimeFlag;
    }

    // Layer 2: Actual runtime package identity check
    final packageName = await _packageIdentity.getPackageName();
    if (packageName == null || packageName.isEmpty) {
      return DiagnosticsGateStatus.detectionFailed;
    }

    // Explicitly reject production and existing golden-sample QA applications
    if (packageName == PackageIdentity.prodPackage ||
        packageName == PackageIdentity.qaGoldenSamplePackage ||
        packageName != PackageIdentity.expectedDiagnosticPackage) {
      return DiagnosticsGateStatus.unauthorizedPackage;
    }

    final isDiagnosticPkg = await _packageIdentity.isDiagnosticPackage();
    if (!isDiagnosticPkg) {
      return DiagnosticsGateStatus.unauthorizedPackage;
    }

    // Layer 3: Authenticated AppLock state check
    if (appLockController == null) {
      return DiagnosticsGateStatus.uninitializedAppLock;
    }

    if (!appLockController.initialized) {
      return DiagnosticsGateStatus.uninitializedAppLock;
    }

    if (!appLockController.isPinConfigured) {
      return DiagnosticsGateStatus.pinNotConfigured;
    }

    if (appLockController.isLocked) {
      return DiagnosticsGateStatus.appLocked;
    }

    if (!appLockController.hasAuthenticatedSession) {
      return DiagnosticsGateStatus.unauthenticatedSession;
    }

    return DiagnosticsGateStatus.authorized;
  }

  /// Convenience boolean check: returns true ONLY if all 3 layers pass.
  Future<bool> isAuthorized({
    required AppLockController? appLockController,
  }) async {
    final status = await checkAuthorization(appLockController: appLockController);
    return status == DiagnosticsGateStatus.authorized;
  }
}
