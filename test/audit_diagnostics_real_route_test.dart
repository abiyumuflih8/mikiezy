import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/domain/models/app_lock_models.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/screens/audit_diagnostics_screen.dart';
import 'package:mikiezy/services/navigation/app_navigation_service.dart';
import 'package:mikiezy/services/security/app_lock_controller.dart';
import 'package:mikiezy/services/security/app_lock_scope.dart';
import 'package:mikiezy/services/security/diagnostics_security_gate.dart';
import 'package:mikiezy/services/security/package_identity.dart';
import 'package:mikiezy/services/security/pin_hasher.dart';
import 'package:mikiezy/services/security/secure_pin_store.dart';

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

Future<AppLockController> _createController({
  bool initialized = true,
  bool isPinConfigured = false,
  bool authenticate = false,
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
    }
  }
  return controller;
}

const _validGate = DiagnosticsSecurityGate(
  optInOverride: true,
  packageIdentity: TestPackageIdentity(
    packageName: PackageIdentity.expectedDiagnosticPackage,
    flavor: PackageIdentity.expectedDiagnosticFlavor,
  ),
);

Widget _buildApp({
  required AppLockController controller,
  required MikiezyRepository repository,
  DiagnosticsSecurityGate gate = _validGate,
  Widget? customHome,
}) {
  return AppLockScope(
    controller: controller,
    child: MaterialApp(
      home: customHome ??
          AuditDiagnosticsScreen(
            // Deliberately omit appLockController to exercise production AppLockScope resolution
            repository: repository,
            securityGate: gate,
          ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Real-Route Audit Diagnostics Lifecycle & AppLockScope Integration Tests', () {
    testWidgets('TEST A: Fresh screen creation through AppLockScope produces no unexpected Flutter framework error',
        (tester) async {
      final controller = await _createController(
        isPinConfigured: true,
        authenticate: true,
      );
      final repo = MemoryMikiezyRepository();

      await tester.pumpWidget(
        _buildApp(controller: controller, repository: repo),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Internal Audit QA Diagnostics'), findsOneWidget);
    });

    testWidgets('TEST B: Before PIN enrollment, the screen fails closed', (tester) async {
      final controller = await _createController(
        isPinConfigured: false,
        authenticate: false,
      );
      final repo = MemoryMikiezyRepository();

      await tester.pumpWidget(
        _buildApp(controller: controller, repository: repo),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Akses Ditolak'), findsOneWidget);
      expect(
        find.textContaining('PIN aplikasi belum dikonfigurasi'),
        findsOneWidget,
      );
    });

    testWidgets('TEST C: After PIN enrollment without authenticated unlock, the screen remains denied',
        (tester) async {
      final controller = await _createController(
        isPinConfigured: true,
        authenticate: false,
      );
      final repo = MemoryMikiezyRepository();

      await tester.pumpWidget(
        _buildApp(controller: controller, repository: repo),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Akses Ditolak'), findsOneWidget);
      expect(
        find.textContaining('Sesi belum terautentikasi'),
        findsOneWidget,
      );
    });

    testWidgets('TEST D: After explicit successful lock/unlock, the screen can display the authorized empty audit state',
        (tester) async {
      final controller = await _createController(
        isPinConfigured: true,
        authenticate: true,
      );
      final repo = MemoryMikiezyRepository();

      await tester.pumpWidget(
        _buildApp(controller: controller, repository: repo),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Belum ada rekaman audit aksi suara di database lokal ini.'),
        findsOneWidget,
      );
    });

    testWidgets('TEST E: Relocking while the diagnostic route is visible hides audit metadata immediately',
        (tester) async {
      final controller = await _createController(
        isPinConfigured: true,
        authenticate: true,
      );
      final repo = MemoryMikiezyRepository();
      await repo.recordVoiceActionAudit(
        VoiceActionAuditEvent(
          id: 'test-e-1',
          actionId: 'act-e-1',
          actionType: VoiceActionType.incrementProductStock,
          source: VoiceActionSource.voice,
          status: VoiceActionStatus.succeeded,
          createdAt: DateTime.now(),
          targetEntityType: 'product',
          targetEntityId: 'p1',
          beforeSummary: '10',
          afterSummary: '20',
          commandFingerprint: 'fp-1',
          confirmed: true,
        ),
      );

      await tester.pumpWidget(
        _buildApp(controller: controller, repository: repo),
      );
      await tester.pumpAndSettle();

      // Verified visible initially
      expect(find.text('incrementProductStock'), findsOneWidget);

      // Lock app
      controller.lock();
      await tester.pump();

      // Access denied shown immediately, data hidden
      expect(find.text('Akses Ditolak'), findsOneWidget);
      expect(find.text('incrementProductStock'), findsNothing);
    });

    testWidgets('TEST F: An asynchronous query completing after relock cannot reveal audit data',
        (tester) async {
      final controller = await _createController(
        isPinConfigured: true,
        authenticate: true,
      );
      final delayedRepo = _DelayedAuditRepository(delay: const Duration(milliseconds: 200));
      await delayedRepo.recordVoiceActionAudit(
        VoiceActionAuditEvent(
          id: 'test-f-1',
          actionId: 'act-f-1',
          actionType: VoiceActionType.createProduct,
          source: VoiceActionSource.voice,
          status: VoiceActionStatus.succeeded,
          createdAt: DateTime.now(),
          targetEntityType: 'product',
          targetEntityId: 'p-f',
          beforeSummary: 'A',
          afterSummary: 'B',
          commandFingerprint: 'fp-f',
          confirmed: true,
        ),
      );

      await tester.pumpWidget(
        _buildApp(controller: controller, repository: delayedRepo),
      );

      // In flight
      await tester.pump(const Duration(milliseconds: 50));

      // Relock during IO
      controller.lock();

      // Complete async operation
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Akses Ditolak'), findsOneWidget);
      expect(find.text('createProduct'), findsNothing);
    });

    testWidgets(
        'TEST G: Opening the diagnostic page through a realistic navigation route does not crash, throw an inherited-widget lifecycle assertion, or bypass security',
        (tester) async {
      final controller = await _createController(
        isPinConfigured: true,
        authenticate: true,
      );
      final repo = MemoryMikiezyRepository();

      // Simulate a parent screen with a button that pushes AuditDiagnosticsScreen (like SettingsScreen)
      final parentWidget = Builder(
        builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: AppRouteNames.auditDiagnostics),
                    builder: (_) => AuditDiagnosticsScreen(
                      repository: repo,
                      securityGate: _validGate,
                    ),
                  ),
                );
              },
              child: const Text('Buka Diagnostik'),
            ),
          );
        },
      );

      await tester.pumpWidget(
        _buildApp(
          controller: controller,
          repository: repo,
          customHome: parentWidget,
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to navigate
      await tester.tap(find.text('Buka Diagnostik'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Internal Audit QA Diagnostics'), findsOneWidget);
      expect(
        find.text('Belum ada rekaman audit aksi suara di database lokal ini.'),
        findsOneWidget,
      );
    });

    testWidgets('TEST H: After a security dependency changes, any refreshed authorization check remains fail-closed',
        (tester) async {
      final controller = await _createController(
        isPinConfigured: true,
        authenticate: true,
      );
      final repo = MemoryMikiezyRepository();

      await tester.pumpWidget(
        _buildApp(controller: controller, repository: repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Internal Audit QA Diagnostics'), findsOneWidget);

      // Disable PIN (simulate security reset while page is open)
      await controller.disablePin('1234');
      await tester.pump();

      expect(find.text('Akses Ditolak'), findsOneWidget);
      expect(
        find.textContaining('PIN aplikasi belum dikonfigurasi'),
        findsOneWidget,
      );
    });
  });
}
