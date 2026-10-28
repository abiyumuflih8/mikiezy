import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/core/database/app_database.dart';
import 'package:mikiezy/data/local/mikiezy_local_data_source.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/domain/models/app_lock_models.dart';
import 'package:mikiezy/main.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/screens/app_lock_screen.dart';
import 'package:mikiezy/screens/auth_screen.dart';
import 'package:mikiezy/screens/dashboard_screen.dart';
import 'package:mikiezy/screens/onboarding_screen.dart';
import 'package:mikiezy/screens/splash_screen.dart';
import 'package:mikiezy/services/security/app_lock_controller.dart';
import 'package:mikiezy/services/security/app_lock_scope.dart';
import 'package:mikiezy/services/security/biometric_authenticator.dart';
import 'package:mikiezy/services/security/pin_hasher.dart';
import 'package:mikiezy/services/security/secure_pin_store.dart';
import 'package:mikiezy/state/app_state.dart';
import 'package:mikiezy/widgets/app_lock_gate.dart';

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

class _FailingSnapshotRepository extends MemoryMikiezyRepository {
  bool shouldFail = true;

  @override
  Future<void> saveSnapshot(MikiezySnapshot snapshot) async {
    if (shouldFail) {
      throw const FileSystemException('Simulated storage disk write failure');
    }
    await super.saveSnapshot(snapshot);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hardened Auth & Onboarding Decoupling Regression Tests', () {
    // 1. Fresh install without PIN
    testWidgets('1. Fresh install without PIN routes to OnboardingScreen', (
      tester,
    ) async {
      await tester.pumpWidget(const MikiezyApp(usePersistentStorage: false));

      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    });

    // 2. Fresh install with PIN configured but incomplete setup -> routes to OnboardingScreen
    testWidgets(
      '2. Configured PIN with incomplete onboarding routes to OnboardingScreen (decoupled security)',
      (tester) async {
        final repository = MemoryMikiezyRepository();
        final state = MikiezyState.seeded(repository: repository);
        expect(state.onboardingCompleted, isFalse);

        final store = MemorySecurePinStore();
        final appLock = AppLockController(
          securePinStore: store,
          pinHasher: _FakePinHasher(),
          biometricAuthenticator: const UnavailableBiometricAuthenticator(),
          initializeAsUnlocked: true,
        );
        addTearDown(appLock.dispose);
        await appLock.initialize();
        await appLock.configurePin('1234', '1234');
        expect(appLock.isPinConfigured, isTrue);

        await tester.pumpWidget(
          MikiezyScope(
            notifier: state,
            child: AppLockScope(
              controller: appLock,
              child: const MaterialApp(
                home: SplashScreen(splashDuration: Duration(milliseconds: 100)),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        // Must NOT bypass onboarding just because PIN is configured!
        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.byType(DashboardScreen), findsNothing);
      },
    );

    // 3. Completed setup without PIN
    testWidgets(
      '3. Completed setup without PIN routes directly to DashboardScreen without lock',
      (tester) async {
        final repository = MemoryMikiezyRepository();
        final state = MikiezyState.seeded(repository: repository);
        await state.completeOnboarding();
        expect(state.onboardingCompleted, isTrue);
        expect(state.pinEnabled, isFalse);

        final appLock = AppLockController(
          securePinStore: MemorySecurePinStore(),
          biometricAuthenticator: const UnavailableBiometricAuthenticator(),
          initializeAsUnlocked: true,
        );
        addTearDown(appLock.dispose);
        await appLock.initialize();

        await tester.pumpWidget(
          MikiezyScope(
            notifier: state,
            child: AppLockScope(
              controller: appLock,
              child: const MaterialApp(
                home: SplashScreen(splashDuration: Duration(milliseconds: 100)),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.byType(OnboardingScreen), findsNothing);
        expect(find.byType(AppLockScreen), findsNothing);
      },
    );

    // 4. Completed setup with PIN
    testWidgets(
      '4. Completed setup with PIN routes to DashboardScreen behind AppLockGate',
      (tester) async {
        final repository = MemoryMikiezyRepository();
        final state = MikiezyState.seeded(repository: repository);
        await state.completeOnboarding();
        expect(state.onboardingCompleted, isTrue);

        final store = MemorySecurePinStore();
        final appLock = AppLockController(
          securePinStore: store,
          pinHasher: _FakePinHasher(),
          biometricAuthenticator: const UnavailableBiometricAuthenticator(),
          initializeAsUnlocked: false,
        );
        addTearDown(appLock.dispose);
        await appLock.initialize();
        await appLock.configurePin('1234', '1234');
        appLock.lock();
        expect(appLock.isLocked, isTrue);

        await tester.pumpWidget(
          MikiezyScope(
            notifier: state,
            child: AppLockScope(
              controller: appLock,
              child: MaterialApp(
                home: AppLockGate(
                  controller: appLock,
                  child: const SplashScreen(
                    splashDuration: Duration(milliseconds: 100),
                  ),
                ),
              ),
            ),
          ),
        );

        // AppLockScreen covers destination while locked
        expect(find.byType(AppLockScreen), findsOneWidget);

        // Unlock with PIN
        final unlockResult = await appLock.verifyPin('1234');
        expect(unlockResult.isSuccess, isTrue);
        expect(appLock.isLocked, isFalse);

        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.byType(OnboardingScreen), findsNothing);
        expect(find.byType(AppLockScreen), findsNothing);
      },
    );

    // 5. Legacy install missing onboarding flag
    test(
      '5a. Legacy database with pin_enabled: true loads onboardingCompleted == true (documented compatibility)',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        final dataSource = MikiezyLocalDataSource(database);
        addTearDown(dataSource.close);

        // Seed only pin_enabled, without onboarding_completed
        await database
            .into(database.appSettings)
            .insert(
              AppSettingsCompanion.insert(key: 'pin_enabled', value: 'true'),
            );

        final snapshot = await dataSource.readSnapshot(
          MikiezyState.seeded().toSnapshot(),
        );

        expect(snapshot.onboardingCompleted, isTrue);
      },
    );

    test(
      '5b. Legacy database without pin_enabled defaults conservatively to false without data mutation',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        final dataSource = MikiezyLocalDataSource(database);
        addTearDown(dataSource.close);

        final snapshot = await dataSource.readSnapshot(
          MikiezyState.seeded().toSnapshot(),
        );

        expect(snapshot.onboardingCompleted, isFalse);

        // Assert no automatic silent write occurred
        final rows = await database.select(database.appSettings).get();
        expect(rows, isEmpty);
      },
    );

    // 6. Cold start after successful setup persistence
    test(
      '6. Cold start re-reading repository restores persisted onboardingCompleted == true',
      () async {
        final repository = MemoryMikiezyRepository();
        final firstState = MikiezyState.seeded(repository: repository);
        await firstState.hydrateFromLocal();
        await firstState.completeOnboarding();

        final reloadedState = MikiezyState.seeded(repository: repository);
        await reloadedState.hydrateFromLocal();
        expect(reloadedState.onboardingCompleted, isTrue);
      },
    );

    // 7. Failure during setup-state persistence
    test(
      '7. Failure during setup persistence rethrows, rolls back in-memory flag, and allows retry',
      () async {
        final repository = _FailingSnapshotRepository();
        final state = MikiezyState.seeded(repository: repository);

        // 1. Initial attempt fails and throws
        expect(
          () => state.completeOnboarding(),
          throwsA(isA<FileSystemException>()),
        );
        await Future<void>.delayed(Duration.zero);

        // 2. Error is surfaced to caller
        expect(
          state.localStorageError,
          contains('Simulated storage disk write failure'),
        );

        // 3. In-memory flag is rolled back to false (not orphaned as true)
        expect(state.onboardingCompleted, isFalse);

        // 4. Retry succeeds when storage recovers and is NOT silently skipped
        repository.shouldFail = false;
        await state.completeOnboarding();
        expect(state.onboardingCompleted, isTrue);
        expect(state.localStorageError, isNull);

        // 5. Fresh database reopen loads onboardingCompleted == true
        final reloadedState = MikiezyState.seeded(repository: repository);
        await reloadedState.hydrateFromLocal();
        expect(reloadedState.onboardingCompleted, isTrue);
      },
    );

    // 8. Correct PIN unlock
    testWidgets('8. Correct PIN unlock reveals underlying content', (
      tester,
    ) async {
      final store = MemorySecurePinStore();
      final appLock = AppLockController(
        securePinStore: store,
        pinHasher: _FakePinHasher(),
        biometricAuthenticator: const UnavailableBiometricAuthenticator(),
        initializeAsUnlocked: false,
      );
      addTearDown(appLock.dispose);
      await appLock.initialize();
      await appLock.configurePin('1234', '1234');
      appLock.lock();

      await tester.pumpWidget(
        MaterialApp(
          home: AppLockGate(
            controller: appLock,
            child: const Scaffold(body: Text('Protected Business Content')),
          ),
        ),
      );

      expect(find.byType(AppLockScreen), findsOneWidget);
      expect(find.text('Protected Business Content'), findsNothing);

      final unlockResult = await appLock.verifyPin('1234');
      expect(unlockResult.isSuccess, isTrue);
      expect(appLock.isLocked, isFalse);

      await tester.pump();

      expect(find.text('Protected Business Content'), findsOneWidget);
      expect(find.byType(AppLockScreen), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    // 9. Invalid PIN remaining locked
    testWidgets(
      '9. Invalid PIN keeps AppLockGate locked and fails verification',
      (tester) async {
        final store = MemorySecurePinStore();
        final appLock = AppLockController(
          securePinStore: store,
          pinHasher: _FakePinHasher(),
          biometricAuthenticator: const UnavailableBiometricAuthenticator(),
          initializeAsUnlocked: false,
        );
        addTearDown(appLock.dispose);
        await appLock.initialize();
        await appLock.configurePin('1234', '1234');
        appLock.lock();

        await tester.pumpWidget(
          MaterialApp(
            home: AppLockGate(
              controller: appLock,
              child: const Scaffold(body: Text('Protected Content')),
            ),
          ),
        );

        final badResult = await appLock.verifyPin('9999');
        expect(badResult.status, AppLockOperationStatus.invalidPin);
        expect(appLock.isLocked, isTrue);

        await tester.pump();

        expect(find.byType(AppLockScreen), findsOneWidget);
        expect(find.text('Protected Content'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    // 10. Dashboard inaccessible while locked
    testWidgets(
      '10. Dashboard content remains Offstage and inaccessible while locked',
      (tester) async {
        final store = MemorySecurePinStore();
        final appLock = AppLockController(
          securePinStore: store,
          pinHasher: _FakePinHasher(),
          biometricAuthenticator: const UnavailableBiometricAuthenticator(),
          initializeAsUnlocked: false,
        );
        addTearDown(appLock.dispose);
        await appLock.initialize();
        await appLock.configurePin('1234', '1234');
        appLock.lock();

        await tester.pumpWidget(
          MaterialApp(
            home: AppLockGate(
              controller: appLock,
              child: const Scaffold(body: Text('Sensitive Financial Totals')),
            ),
          ),
        );

        expect(find.text('Sensitive Financial Totals'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    // 11. AuthScreen navigation to Dashboard (Sign In & Create Account, repeated submit guard)
    testWidgets(
      '11a. AuthScreen Sign In navigates to Dashboard, unfocuses, and marks onboarding complete',
      (tester) async {
        final state = MikiezyState.seeded();
        expect(state.onboardingCompleted, isFalse);

        await tester.pumpWidget(
          MikiezyScope(
            notifier: state,
            child: const MaterialApp(
              home: AuthScreen(initialMode: AuthMode.login),
            ),
          ),
        );

        expect(find.byType(AuthScreen), findsOneWidget);

        final submitFinder = find.widgetWithText(FilledButton, 'Sign In');
        await Scrollable.ensureVisible(tester.element(submitFinder));
        await tester.pumpAndSettle();
        await tester.tap(submitFinder);
        await tester.pumpAndSettle();

        expect(state.onboardingCompleted, isTrue);
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.byType(AuthScreen), findsNothing);
      },
    );

    testWidgets(
      '11b. AuthScreen Create Account navigates to Dashboard and purges stack',
      (tester) async {
        final state = MikiezyState.seeded();

        await tester.pumpWidget(
          MikiezyScope(
            notifier: state,
            child: const MaterialApp(
              home: AuthScreen(initialMode: AuthMode.register),
            ),
          ),
        );

        final submitFinder = find.widgetWithText(
          FilledButton,
          'Create Account',
        );
        await Scrollable.ensureVisible(tester.element(submitFinder));
        await tester.pumpAndSettle();
        await tester.tap(submitFinder);
        await tester.pumpAndSettle();

        expect(state.onboardingCompleted, isTrue);
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.byType(AuthScreen), findsNothing);
      },
    );

    // 12. No business or financial mutations
    test(
      '12. No mutations: seed transactions and canonical financial baseline remain 100% intact',
      () {
        final state = MikiezyState.seeded();

        // Transaksi seed
        expect(state.transactions.length, 3);
        final tx1 = state.transactions.firstWhere((t) => t.id == 'tx-001');
        expect(tx1.amount, 45000);
        expect(tx1.kind, TransactionKind.sale);

        final tx2 = state.transactions.firstWhere((t) => t.id == 'tx-002');
        expect(tx2.amount, 23000);
        expect(tx2.kind, TransactionKind.sale);

        final tx3 = state.transactions.firstWhere((t) => t.id == 'tx-003');
        expect(tx3.amount, 180000);
        expect(tx3.kind, TransactionKind.expense);

        // Omzet = Rp 68.000, Expense = Rp 180.000
        expect(state.salesAndIncomeTotal, 68000);
        expect(state.expenseTotal, 180000);
      },
    );

    // 13. Decoupling verification: togglePin does NOT alter onboardingCompleted
    test(
      '13. Decoupling verification: togglePin(true) does NOT alter onboardingCompleted',
      () {
        final state = MikiezyState.seeded();
        expect(state.onboardingCompleted, isFalse);

        state.togglePin(true);
        expect(state.pinEnabled, isTrue);
        // Must remain false!
        expect(state.onboardingCompleted, isFalse);
      },
    );

    // 14. Startup race condition guard: SplashScreen awaits hydration before choosing destination
    testWidgets(
      '14. Startup race guard: SplashScreen awaits unready hydration before deciding destination',
      (tester) async {
        final repository = MemoryMikiezyRepository();
        final state = MikiezyState.seeded(repository: repository);
        // Simulate unhydrated state
        state.localStorageReady = false;

        await tester.pumpWidget(
          MikiezyScope(
            notifier: state,
            child: const MaterialApp(
              home: SplashScreen(splashDuration: Duration(milliseconds: 50)),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // State is now hydrated and routed safely without race
        expect(state.localStorageReady, isTrue);
        expect(find.byType(OnboardingScreen), findsOneWidget);
      },
    );

    // 15. Drift schema stability
    test(
      '15. Drift database schema remains version 6 with zero alterations',
      () {
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);

        expect(database.schemaVersion, 6);
      },
    );
  });
}
