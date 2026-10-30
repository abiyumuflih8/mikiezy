import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/domain/models/app_lock_models.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/screens/audit_diagnostics_screen.dart';
import 'package:mikiezy/services/security/app_lock_controller.dart';
import 'package:mikiezy/services/security/diagnostics_security_gate.dart';
import 'package:mikiezy/services/security/package_identity.dart';
import 'package:mikiezy/services/security/pin_hasher.dart';
import 'package:mikiezy/services/security/secure_pin_store.dart';

import 'support/phase6a_fixtures.dart';

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
    return verifier.verifierBase64 == base64Encode(utf8.encode('test-only:$pin'));
  }
}

class _FailingAuditRepository extends MemoryMikiezyRepository {
  @override
  Future<List<VoiceActionAuditEvent>> loadRecentVoiceActionAudits({
    int limit = 50,
  }) async {
    throw Exception('Simulated database IO failure during audit query');
  }
}

class _DelayedAuditRepository extends MemoryMikiezyRepository {
  _DelayedAuditRepository({required this.delay});
  final Duration delay;

  @override
  Future<List<VoiceActionAuditEvent>> loadRecentVoiceActionAudits({
    int limit = 50,
  }) async {
    await Future<void>.delayed(delay);
    return super.loadRecentVoiceActionAudits(limit: limit);
  }
}

Future<AppLockController> _createTestAppLockController({
  bool initialized = true,
  bool isPinConfigured = true,
  bool authenticate = true,
  bool isLocked = false,
}) async {
  final store = MemorySecurePinStore();
  final hasher = _FakePinHasher();
  final controller = AppLockController(
    securePinStore: store,
    pinHasher: hasher,
    initializeAsUnlocked: initialized,
  );
  if (initialized) {
    await controller.initialize();
    if (isPinConfigured) {
      await controller.configurePin('1234', '1234');
      if (authenticate) {
        controller.lock();
        await controller.verifyPin('1234');
      }
      if (isLocked) {
        controller.lock();
      }
    }
  }
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Isolated Internal-QA Voice Audit Diagnostics Security Tests', () {
    // 1. Production package cannot access diagnostics
    test('1. Production package (com.mikiezy.mikiezy) cannot access diagnostics', () async {
      final appLock = await _createTestAppLockController();
      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.prodPackage,
          flavor: 'prod',
        ),
      );

      final status = await gate.checkAuthorization(appLockController: appLock);
      expect(status, equals(DiagnosticsGateStatus.unauthorizedPackage));

      final isAuthorized = await gate.isAuthorized(appLockController: appLock);
      expect(isAuthorized, isFalse);
    });

    // 2. Existing QA package cannot access diagnostics
    test('2. Existing QA package (com.mikiezy.mikiezy.qa) cannot access diagnostics', () async {
      final appLock = await _createTestAppLockController();
      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.qaGoldenSamplePackage,
          flavor: 'qa',
        ),
      );

      final status = await gate.checkAuthorization(appLockController: appLock);
      expect(status, equals(DiagnosticsGateStatus.unauthorizedPackage));

      final isAuthorized = await gate.isAuthorized(appLockController: appLock);
      expect(isAuthorized, isFalse);
    });

    // 3. Diagnostic package with feature flag off cannot access diagnostics
    test('3. Diagnostic package with feature flag off cannot access diagnostics', () async {
      final appLock = await _createTestAppLockController();
      const gate = DiagnosticsSecurityGate(
        optInOverride: false, // Flag disabled
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      final status = await gate.checkAuthorization(appLockController: appLock);
      expect(status, equals(DiagnosticsGateStatus.disabledByCompileTimeFlag));

      final isAuthorized = await gate.isAuthorized(appLockController: appLock);
      expect(isAuthorized, isFalse);
    });

    // 4. Diagnostic package with flag on but AppLock locked cannot access diagnostics
    test('4. Diagnostic package with flag on but AppLock locked cannot access diagnostics', () async {
      final appLock = await _createTestAppLockController(isLocked: true);
      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      final status = await gate.checkAuthorization(appLockController: appLock);
      expect(status, equals(DiagnosticsGateStatus.appLocked));

      final isAuthorized = await gate.isAuthorized(appLockController: appLock);
      expect(isAuthorized, isFalse);
    });

    // 5. Diagnostic package with flag on and AppLock unlocked & authenticated may access diagnostics
    test('5. Diagnostic package with flag on and AppLock unlocked may access diagnostics', () async {
      final appLock = await _createTestAppLockController();
      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      final status = await gate.checkAuthorization(appLockController: appLock);
      expect(status, equals(DiagnosticsGateStatus.authorized));

      final isAuthorized = await gate.isAuthorized(appLockController: appLock);
      expect(isAuthorized, isTrue);
    });

    // 6. Forced/direct route navigation while locked fails closed
    testWidgets('6. Forced/direct route navigation while locked fails closed', (tester) async {
      final appLock = await _createTestAppLockController(isLocked: true);
      final repo = MemoryMikiezyRepository();

      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuditDiagnosticsScreen(
            appLockController: appLock,
            repository: repo,
            securityGate: gate,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Akses Ditolak'), findsOneWidget);
      expect(find.textContaining('Akses ditolak: Aplikasi terkunci'), findsOneWidget);
      expect(find.text('Internal Audit QA Diagnostics'), findsNothing);
    });

    // 7. Re-locking dynamically hides diagnostic content
    testWidgets('7. Re-locking dynamically hides diagnostic content', (tester) async {
      final appLock = await _createTestAppLockController();
      final repo = MemoryMikiezyRepository();

      // Seed one event
      await repo.recordVoiceActionAudit(
        VoiceActionAuditEvent(
          id: 'test-event-1-succeeded',
          actionId: 'test-action-1',
          actionType: VoiceActionType.createProduct,
          source: VoiceActionSource.voice,
          status: VoiceActionStatus.succeeded,
          createdAt: DateTime.now(),
          targetEntityType: 'product',
          targetEntityId: 'prod-1',
          beforeSummary: 'Sebelum',
          afterSummary: 'Sesudah',
          commandFingerprint: 'fingerprint-1',
          confirmed: true,
        ),
      );

      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuditDiagnosticsScreen(
            appLockController: appLock,
            repository: repo,
            securityGate: gate,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unlocked: summary and tile are visible
      expect(find.text('Internal Audit QA Diagnostics'), findsOneWidget);
      expect(find.text('createProduct'), findsOneWidget);

      // Dynamically lock the app
      appLock.lock();
      await tester.pumpAndSettle();

      // Locked: diagnostic content is hidden immediately, access denied shown
      expect(find.text('Akses Ditolak'), findsOneWidget);
      expect(find.text('createProduct'), findsNothing);
    });

    // 8. Diagnostic repository access is read-only
    test('8. Diagnostic repository access is strictly read-only', () async {
      final repo = MemoryMikiezyRepository();
      await repo.recordVoiceActionAudit(
        VoiceActionAuditEvent(
          id: 'readonly-test-succeeded',
          actionId: 'readonly-action',
          actionType: VoiceActionType.updateProductPrice,
          source: VoiceActionSource.voice,
          status: VoiceActionStatus.succeeded,
          createdAt: DateTime.now(),
          targetEntityType: 'product',
          targetEntityId: 'prod-ro',
          beforeSummary: 'Rp10.000',
          afterSummary: 'Rp12.000',
          commandFingerprint: 'fingerprint-ro',
          confirmed: true,
        ),
      );

      final beforeEvents = await repo.loadRecentVoiceActionAudits();
      expect(beforeEvents.length, equals(1));

      // Call it multiple times with various limits
      await repo.loadRecentVoiceActionAudits(limit: 10);
      await repo.loadRecentVoiceActionAudits(limit: 100);

      final afterEvents = await repo.loadRecentVoiceActionAudits();
      expect(afterEvents.length, equals(1));
      expect(afterEvents.first.id, equals('readonly-test-succeeded'));
    });

    // 9. No sensitive audit fields are rendered
    testWidgets('9. No sensitive audit fields (transcripts, fingerprints, payloads) are rendered', (tester) async {
      final appLock = await _createTestAppLockController();
      final repo = MemoryMikiezyRepository();

      const sensitiveBefore = 'SENSITIVE_SECRET_BEFORE_DATA_12345';
      const sensitiveAfter = 'SENSITIVE_SECRET_AFTER_DATA_67890';
      const sensitiveFingerprint = 'FINGERPRINT_SECRET_HEX_ABCDEF987654321';
      const sensitiveActionId = 'voice-secret-raw-action-id-ultra-private';

      await repo.recordVoiceActionAudit(
        VoiceActionAuditEvent(
          id: 'test-sensitive-succeeded',
          actionId: sensitiveActionId,
          actionType: VoiceActionType.createProduct,
          source: VoiceActionSource.voice,
          status: VoiceActionStatus.succeeded,
          createdAt: DateTime.now(),
          targetEntityType: 'product',
          targetEntityId: 'prod-sensitive',
          beforeSummary: sensitiveBefore,
          afterSummary: sensitiveAfter,
          commandFingerprint: sensitiveFingerprint,
          confirmed: true,
        ),
      );

      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuditDiagnosticsScreen(
            appLockController: appLock,
            repository: repo,
            securityGate: gate,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sanitized view model renders generic metadata
      expect(find.text('createProduct'), findsOneWidget);
      expect(find.text('succeeded'), findsOneWidget);

      // Sensitive fields must NOT exist in the widget tree
      expect(find.textContaining(sensitiveBefore), findsNothing);
      expect(find.textContaining(sensitiveAfter), findsNothing);
      expect(find.textContaining(sensitiveFingerprint), findsNothing);
      expect(find.textContaining(sensitiveActionId), findsNothing);
    });

    // 10. Empty and malformed audit data fail safely
    testWidgets('10. Empty and malformed audit data fail safely without crashing', (tester) async {
      final appLock = await _createTestAppLockController();
      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      // Test Empty
      final emptyRepo = MemoryMikiezyRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: AuditDiagnosticsScreen(
            key: const ValueKey('empty-screen'),
            appLockController: appLock,
            repository: emptyRepo,
            securityGate: gate,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Belum ada rekaman audit aksi suara di database lokal ini.'), findsOneWidget);

      // Test Failure/Malformed
      final failingRepo = _FailingAuditRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: AuditDiagnosticsScreen(
            key: const ValueKey('failing-screen'),
            appLockController: appLock,
            repository: failingRepo,
            securityGate: gate,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gagal memuat log audit (Akses dibatasi).'), findsOneWidget);
    });

    // 11. Audit reading does not create or change business rows
    test('11. Audit reading does not create or change business rows', () async {
      final repo = MemoryMikiezyRepository();
      await repo.loadOrSeed(phase6aSnapshot(products: [phase6aProduct()]));

      final initialProducts = await repo.loadProducts();
      expect(initialProducts.length, equals(1));
      expect(initialProducts.first.name, equals('Kopi Susu'));

      // Execute audit queries
      final results = await repo.loadRecentVoiceActionAudits();
      expect(results, isEmpty);

      final finalProducts = await repo.loadProducts();
      expect(finalProducts.length, equals(1));
      expect(finalProducts.first.name, equals('Kopi Susu'));
    });

    // 12. Diagnostic logic does not modify original voice mutation behavior
    test('12. Diagnostic logic does not modify original voice audit recording', () async {
      final repo = MemoryMikiezyRepository();
      final event1 = VoiceActionAuditEvent(
        id: 'mutation-check-exec',
        actionId: 'mutation-action-123',
        actionType: VoiceActionType.incrementProductStock,
        source: VoiceActionSource.voice,
        status: VoiceActionStatus.executionStarted,
        createdAt: DateTime.now(),
        targetEntityType: 'product',
        targetEntityId: 'p1',
        beforeSummary: '20 gelas',
        afterSummary: '30 gelas',
        commandFingerprint: 'fp-123',
        confirmed: true,
      );
      final event2 = VoiceActionAuditEvent(
        id: 'mutation-check-succ',
        actionId: 'mutation-action-123',
        actionType: VoiceActionType.incrementProductStock,
        source: VoiceActionSource.voice,
        status: VoiceActionStatus.succeeded,
        createdAt: DateTime.now().add(const Duration(milliseconds: 50)),
        targetEntityType: 'product',
        targetEntityId: 'p1',
        beforeSummary: '20 gelas',
        afterSummary: '30 gelas',
        commandFingerprint: 'fp-123',
        confirmed: true,
      );

      // Record original audit events
      await repo.recordVoiceActionAudit(event1);
      await repo.recordVoiceActionAudit(event2);

      // Verify original coordinator query still works identically
      final actionAudits = await repo.loadVoiceActionAudits('mutation-action-123');
      expect(actionAudits.length, equals(2));
      expect(actionAudits.first.status, equals(VoiceActionStatus.executionStarted));
      expect(actionAudits.last.status, equals(VoiceActionStatus.succeeded));

      // Verify diagnostic query also observes recent events correctly without mutating
      final recentAudits = await repo.loadRecentVoiceActionAudits(limit: 10);
      expect(recentAudits.length, equals(2));
    });

    // 13. Fresh diagnostic installation with no configured PIN must deny diagnostics
    test('13. Fresh diagnostic installation with no configured PIN must deny diagnostics', () async {
      final appLock = await _createTestAppLockController(isPinConfigured: false);
      expect(appLock.isPinConfigured, isFalse);
      expect(appLock.isLocked, isFalse); // default unconfigured state

      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      final status = await gate.checkAuthorization(appLockController: appLock);
      expect(status, equals(DiagnosticsGateStatus.pinNotConfigured));

      final isAuthorized = await gate.isAuthorized(appLockController: appLock);
      expect(isAuthorized, isFalse);
    });

    // 14. PIN freshly configured but no explicit authenticated unlock must deny diagnostics
    test('14. PIN freshly configured but no explicit authenticated unlock must deny diagnostics', () async {
      final appLock = await _createTestAppLockController(
        isPinConfigured: true,
        authenticate: false, // configurePin only, no verifyPin unlock
      );
      expect(appLock.isPinConfigured, isTrue);
      expect(appLock.isLocked, isFalse);
      expect(appLock.hasAuthenticatedSession, isFalse);

      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      final status = await gate.checkAuthorization(appLockController: appLock);
      expect(status, equals(DiagnosticsGateStatus.unauthenticatedSession));

      final isAuthorized = await gate.isAuthorized(appLockController: appLock);
      expect(isAuthorized, isFalse);
    });

    // 15. Configured PIN + successful authenticated unlock may access diagnostics
    test('15. Configured PIN + successful authenticated unlock may access diagnostics', () async {
      final appLock = await _createTestAppLockController(
        isPinConfigured: true,
        authenticate: true, // explicit unlock occurred
      );
      expect(appLock.isPinConfigured, isTrue);
      expect(appLock.isLocked, isFalse);
      expect(appLock.hasAuthenticatedSession, isTrue);

      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      final status = await gate.checkAuthorization(appLockController: appLock);
      expect(status, equals(DiagnosticsGateStatus.authorized));

      final isAuthorized = await gate.isAuthorized(appLockController: appLock);
      expect(isAuthorized, isTrue);
    });

    // 16. Failed PIN verification must not authorize diagnostics
    test('16. Failed PIN verification must not authorize diagnostics', () async {
      final appLock = await _createTestAppLockController(
        isPinConfigured: true,
        authenticate: false,
      );
      appLock.lock();

      // Attempt wrong PIN
      final result = await appLock.verifyPin('9999');
      expect(result.isSuccess, isFalse);
      expect(appLock.isLocked, isTrue);
      expect(appLock.hasAuthenticatedSession, isFalse);

      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      final status = await gate.checkAuthorization(appLockController: appLock);
      expect(status, equals(DiagnosticsGateStatus.appLocked));
    });

    // 17. Relock after successful authentication must immediately revoke diagnostic access
    test('17. Relock after successful authentication must immediately revoke diagnostic access', () async {
      final appLock = await _createTestAppLockController(
        isPinConfigured: true,
        authenticate: true,
      );
      expect(appLock.hasAuthenticatedSession, isTrue);

      // Lock application
      appLock.lock();
      expect(appLock.isLocked, isTrue);
      expect(appLock.hasAuthenticatedSession, isFalse);

      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      final status = await gate.checkAuthorization(appLockController: appLock);
      expect(status, equals(DiagnosticsGateStatus.appLocked));
    });

    // 18. Initialization pending or failed must deny diagnostics
    test('18. Initialization pending or failed must deny diagnostics', () async {
      final appLock = await _createTestAppLockController(initialized: false);
      expect(appLock.initialized, isFalse);

      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      final status = await gate.checkAuthorization(appLockController: appLock);
      expect(status, equals(DiagnosticsGateStatus.uninitializedAppLock));
    });

    // 19. PIN disabled or security reset must revoke previous authorization
    test('19. PIN disabled or security reset must revoke any previous authorization', () async {
      final appLock = await _createTestAppLockController(
        isPinConfigured: true,
        authenticate: true,
      );
      expect(appLock.hasAuthenticatedSession, isTrue);

      // Disable PIN
      final disableResult = await appLock.disablePin('1234');
      expect(disableResult.isSuccess, isTrue);
      expect(appLock.isPinConfigured, isFalse);
      expect(appLock.hasAuthenticatedSession, isFalse);

      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      final status = await gate.checkAuthorization(appLockController: appLock);
      expect(status, equals(DiagnosticsGateStatus.pinNotConfigured));
    });

    // 20. Delayed audit read finishing after relock must not reveal data
    testWidgets('20. Delayed audit read finishing after relock must not reveal data', (tester) async {
      final appLock = await _createTestAppLockController(
        isPinConfigured: true,
        authenticate: true,
      );
      final delayedRepo = _DelayedAuditRepository(delay: const Duration(milliseconds: 300));

      await delayedRepo.recordVoiceActionAudit(
        VoiceActionAuditEvent(
          id: 'delayed-test-1',
          actionId: 'delayed-act-1',
          actionType: VoiceActionType.createProduct,
          source: VoiceActionSource.voice,
          status: VoiceActionStatus.succeeded,
          createdAt: DateTime.now(),
          targetEntityType: 'product',
          targetEntityId: 'p-delay',
          beforeSummary: 'A',
          afterSummary: 'B',
          commandFingerprint: 'fp-delay',
          confirmed: true,
        ),
      );

      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.expectedDiagnosticPackage,
          flavor: PackageIdentity.expectedDiagnosticFlavor,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuditDiagnosticsScreen(
            appLockController: appLock,
            repository: delayedRepo,
            securityGate: gate,
          ),
        ),
      );

      // Initially loading
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Lock app WHILE database read is in flight
      appLock.lock();

      // Finish delay and pump
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Access denied shown, data NOT revealed
      expect(find.text('Akses Ditolak'), findsOneWidget);
      expect(find.text('createProduct'), findsNothing);
    });

    // 21. Normal production package remains denied even when authenticated
    test('21. Normal production package remains denied even when authenticated', () async {
      final appLock = await _createTestAppLockController(
        isPinConfigured: true,
        authenticate: true,
      );
      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.prodPackage,
          flavor: 'prod',
        ),
      );

      final status = await gate.checkAuthorization(appLockController: appLock);
      expect(status, equals(DiagnosticsGateStatus.unauthorizedPackage));
    });

    // 22. Existing QA Run 2 package remains denied even when authenticated
    test('22. Existing QA Run 2 package remains denied even when authenticated', () async {
      final appLock = await _createTestAppLockController(
        isPinConfigured: true,
        authenticate: true,
      );
      const gate = DiagnosticsSecurityGate(
        optInOverride: true,
        packageIdentity: TestPackageIdentity(
          packageName: PackageIdentity.qaGoldenSamplePackage,
          flavor: 'qa',
        ),
      );

      final status = await gate.checkAuthorization(appLockController: appLock);
      expect(status, equals(DiagnosticsGateStatus.unauthorizedPackage));
    });
  });
}
