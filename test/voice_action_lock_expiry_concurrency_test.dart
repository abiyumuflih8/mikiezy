import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/data/repositories/repository_voice_action_audit_store.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/models/voice_action_execution.dart';
import 'package:mikiezy/domain/services/voice_action_audit_store.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/update_product_price_voice_action_executor.dart';
import 'package:mikiezy/services/voice/voice_action_coordinator.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';
import 'package:mikiezy/services/voice/voice_mutation_preview_handler.dart';

import 'support/phase6a_fixtures.dart';
import 'support/phase6c_fixtures.dart';

void main() {
  final initialTime = DateTime(2030, 1, 1, 10, 0, 0);

  group('M4F.71 Final Pre-Build AppLock & Expiry Concurrency Gate', () {
    test(
      'CASE A: normal confirmation succeeds once while application remains unlocked and action valid',
      () async {
        final harness = await _TestHarness.create(initialTime: initialTime);
        addTearDown(harness.close);

        final preview = await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi dua belas ribu',
          ),
        );
        expect(preview.kind, VoiceResponseKind.confirmation);
        expect(harness.handler.hasPendingAction, isTrue);

        final response = await harness.handler.handlePendingAnswer('konfirmasi');
        expect(response.displayText, contains('berhasil diubah'));
        expect(harness.executorInvocations, 1);
        expect((await harness.repository.loadProducts()).single.retailPrice, 12000);

        final audits = await harness.repository.loadVoiceActionAudits(
          harness.lastActionId!,
        );
        expect(audits.where((e) => e.status == VoiceActionStatus.succeeded).length, 1);
        expect(audits.where((e) => e.status == VoiceActionStatus.blockedLocked), isEmpty);
        expect(audits.where((e) => e.status == VoiceActionStatus.expired), isEmpty);
      },
    );

    test(
      'CASE B: application is locked BEFORE confirmation begins; no mutation allowed',
      () async {
        final harness = await _TestHarness.create(initialTime: initialTime);
        addTearDown(harness.close);

        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi dua belas ribu',
          ),
        );
        final actionId = harness.lastActionId!;

        // Application becomes locked
        harness.isAppLocked = true;

        final response = await harness.handler.handlePendingAnswer('konfirmasi');
        expect(response.displayText, contains('Aplikasi terkunci'));
        expect(harness.executorInvocations, 0);
        expect(harness.handler.hasPendingAction, isFalse);
        expect((await harness.repository.loadProducts()).single.retailPrice, 10000);

        final audits = await harness.repository.loadVoiceActionAudits(actionId);
        expect(audits.where((e) => e.status == VoiceActionStatus.blockedLocked).length, 1);
        expect(audits.where((e) => e.status == VoiceActionStatus.succeeded), isEmpty);
      },
    );

    test(
      'CASE C: confirmation begins while unlocked and suspends during audit recording; second callback arrives with isAppLocked=true',
      () async {
        final confirmAuditReached = Completer<void>();
        final allowConfirmAuditProceed = Completer<void>();

        final harness = await _TestHarness.create(
          initialTime: initialTime,
          onRecordAudit: (event) async {
            if (event.status == VoiceActionStatus.confirmed &&
                !confirmAuditReached.isCompleted) {
              confirmAuditReached.complete();
              await allowConfirmAuditProceed.future;
            }
          },
        );
        addTearDown(harness.close);

        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi dua belas ribu',
          ),
        );
        final actionId = harness.lastActionId!;

        // Callback 1 starts while unlocked; suspends on confirmed audit
        final future1 = harness.handler.handlePendingAnswer('konfirmasi');
        await confirmAuditReached.future;

        // Application locks during Callback 1's in-flight execution
        harness.isAppLocked = true;

        // Callback 2 arrives for SAME action while locked
        final future2 = harness.handler.handlePendingAnswer('konfirmasi');

        // Resume Callback 1
        allowConfirmAuditProceed.complete();

        final results = await Future.wait<VoiceCommandResponse>([future1, future2]);
        final resp1 = results[0];
        final resp2 = results[1];
        expect(resp1.displayText, contains('berhasil diubah'));

        final audits = await harness.repository.loadVoiceActionAudits(actionId);
        final succeededCount =
            audits.where((e) => e.status == VoiceActionStatus.succeeded).length;
        final blockedCount =
            audits.where((e) => e.status == VoiceActionStatus.blockedLocked).length;

        // CORRECTNESS CONTRACT:
        // Callback 1 entered in-flight confirmation while unlocked.
        // It must NOT have contradictory terminal audits (succeeded + blockedLocked).
        expect(
          harness.executorInvocations,
          1,
          reason: 'Executor must be invoked exactly once',
        );
        expect(
          succeededCount,
          1,
          reason: 'Must record exactly 1 succeeded audit',
        );
        expect(
          blockedCount,
          0,
          reason:
              'Must NOT record blockedLocked for an action that was already in-flight confirmed',
        );
        expect(
          resp2.displayText,
          anyOf(
            contains('sedang diproses'),
            contains('sudah pernah'),
          ),
          reason:
              'Callback 2 must recognize action as in-flight or finalized, not record blockedLocked',
        );
        expect((await harness.repository.loadProducts()).single.retailPrice, 12000);
      },
    );

    test(
      'CASE D: confirmation begins while unlocked and suspends inside executor; second callback arrives with isAppLocked=true',
      () async {
        final executorReached = Completer<void>();
        final allowExecutorFinish = Completer<void>();

        final harness = await _TestHarness.create(
          initialTime: initialTime,
          onExecuteBeforeCommit: () async {
            if (!executorReached.isCompleted) {
              executorReached.complete();
              await allowExecutorFinish.future;
            }
          },
        );
        addTearDown(harness.close);

        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi dua belas ribu',
          ),
        );
        final actionId = harness.lastActionId!;

        final future1 = harness.handler.handlePendingAnswer('konfirmasi');
        await executorReached.future;

        // Application locks while executor is actively committing in SQLite
        harness.isAppLocked = true;

        final future2 = harness.handler.handlePendingAnswer('konfirmasi');

        allowExecutorFinish.complete();

        final results = await Future.wait<VoiceCommandResponse>([future1, future2]);
        final resp2 = results[1];

        final audits = await harness.repository.loadVoiceActionAudits(actionId);
        expect(harness.executorInvocations, 1);
        expect(audits.where((e) => e.status == VoiceActionStatus.succeeded).length, 1);
        expect(audits.where((e) => e.status == VoiceActionStatus.blockedLocked), isEmpty);
        expect(
          resp2.displayText,
          anyOf(contains('sedang diproses'), contains('sudah pernah')),
        );
        expect((await harness.repository.loadProducts()).single.retailPrice, 12000);
      },
    );

    test(
      'CASE E: confirmation begins before expiresAt; second callback arrives after expiresAt while first is in-flight',
      () async {
        final confirmAuditReached = Completer<void>();
        final allowConfirmAuditProceed = Completer<void>();
        var simulatedTime = initialTime;

        final harness = await _TestHarness.create(
          initialTime: initialTime,
          timeProvider: () => simulatedTime,
          onRecordAudit: (event) async {
            if (event.status == VoiceActionStatus.confirmed &&
                !confirmAuditReached.isCompleted) {
              confirmAuditReached.complete();
              await allowConfirmAuditProceed.future;
            }
          },
        );
        addTearDown(harness.close);

        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi dua belas ribu',
          ),
        );
        final actionId = harness.lastActionId!;

        // Callback 1 starts at t=0 (not expired); suspends on confirmed audit
        final future1 = harness.handler.handlePendingAnswer('konfirmasi');
        await confirmAuditReached.future;

        // Time jumps 10 minutes into the future (past default 5m TTL)
        simulatedTime = initialTime.add(const Duration(minutes: 10));

        // Callback 2 arrives after expiration while Callback 1 is in-flight
        final future2 = harness.handler.handlePendingAnswer('konfirmasi');

        allowConfirmAuditProceed.complete();

        final results = await Future.wait<VoiceCommandResponse>([future1, future2]);
        final resp2 = results[1];

        final audits = await harness.repository.loadVoiceActionAudits(actionId);
        expect(harness.executorInvocations, 1);
        expect(audits.where((e) => e.status == VoiceActionStatus.succeeded).length, 1);
        expect(
          audits.where((e) => e.status == VoiceActionStatus.expired),
          isEmpty,
          reason: 'Must NOT record expired for an action already in-flight confirmed',
        );
        expect(
          resp2.displayText,
          anyOf(contains('sedang diproses'), contains('sudah pernah')),
        );
        expect((await harness.repository.loadProducts()).single.retailPrice, 12000);
      },
    );

    test(
      'CASE F: already-expired pending action is rejected before any execution begins',
      () async {
        var simulatedTime = initialTime;
        final harness = await _TestHarness.create(
          initialTime: initialTime,
          timeProvider: () => simulatedTime,
        );
        addTearDown(harness.close);

        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi dua belas ribu',
          ),
        );
        final actionId = harness.lastActionId!;

        // Fast-forward past expiry
        simulatedTime = initialTime.add(const Duration(minutes: 10));

        final response = await harness.handler.handlePendingAnswer('konfirmasi');
        expect(response.displayText, contains('sudah kedaluwarsa'));
        expect(harness.executorInvocations, 0);
        expect(harness.handler.hasPendingAction, isFalse);

        final audits = await harness.repository.loadVoiceActionAudits(actionId);
        expect(audits.where((e) => e.status == VoiceActionStatus.expired).length, 1);
        expect(audits.where((e) => e.status == VoiceActionStatus.succeeded), isEmpty);
        expect((await harness.repository.loadProducts()).single.retailPrice, 10000);
      },
    );

    test(
      'CASE G: pending Action B remains intact when older Action A completes under lock or expiry transitions',
      () async {
        var simulatedTime = initialTime;
        final harness = await _TestHarness.create(
          initialTime: initialTime,
          timeProvider: () => simulatedTime,
        );
        addTearDown(harness.close);

        // Preview Action A
        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi dua belas ribu',
          ),
        );
        final actionIdA = harness.lastActionId!;

        // Advance time to expire Action A
        simulatedTime = initialTime.add(const Duration(minutes: 10));

        // Rejection of Action A due to expiry
        final respA = await harness.handler.handlePendingAnswer('konfirmasi');
        expect(respA.displayText, contains('sudah kedaluwarsa'));

        // Reset clock and preview Action B
        simulatedTime = initialTime.add(const Duration(minutes: 11));
        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi lima belas ribu',
          ),
        );
        final actionIdB = harness.lastActionId!;
        expect(actionIdB, isNot(equals(actionIdA)));
        expect(harness.handler.hasPendingAction, isTrue);

        // Action B can be confirmed cleanly
        final respB = await harness.handler.handlePendingAnswer('konfirmasi');
        expect(respB.displayText, contains('berhasil diubah'));
        expect((await harness.repository.loadProducts()).single.retailPrice, 15000);
      },
    );

    test(
      'CASE H: existing normal cancellation and legitimate additional-confirmation flows remain compatible',
      () async {
        final harness = await _TestHarness.create(initialTime: initialTime);
        addTearDown(harness.close);

        // Price drop 80% triggers additional confirmation warning
        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi dua ribu',
          ),
        );
        final step1 = await harness.handler.handlePendingAnswer('ya');
        expect(step1.displayText, contains('turun sangat besar'));

        // Confirming again while unlocked succeeds
        final step2 = await harness.handler.handlePendingAnswer('ya');
        expect(step2.displayText, contains('berhasil diubah'));
        expect((await harness.repository.loadProducts()).single.retailPrice, 2000);
      },
    );
  });
}

class _SpyAuditStore implements VoiceActionAuditStore {
  _SpyAuditStore(this._inner, {this.onRecord});

  final VoiceActionAuditStore _inner;
  final Future<void> Function(VoiceActionAuditEvent event)? onRecord;

  @override
  Future<void> record(VoiceActionAuditEvent event) async {
    if (onRecord != null) {
      await onRecord!(event);
    }
    await _inner.record(event);
  }

  @override
  Future<List<VoiceActionAuditEvent>> eventsFor(String actionId) {
    return _inner.eventsFor(actionId);
  }
}

class _SpyPriceExecutor extends UpdateProductPriceVoiceActionExecutor {
  _SpyPriceExecutor(
    super.repository, {
    super.onCommitted,
    super.now,
    this.onExecuteBeforeCommit,
  });

  final Future<void> Function()? onExecuteBeforeCommit;
  int invocations = 0;

  @override
  Future<VoiceActionExecutionResult> execute(
    VoiceActionDraft action, {
    required bool isFeatureEnabled,
    required bool isAppLocked,
    bool authenticationSucceeded = false,
    bool authenticationAttempted = false,
    bool additionalConfirmationSucceeded = false,
    String? currentBaseFingerprint,
  }) async {
    invocations++;
    if (onExecuteBeforeCommit != null) {
      await onExecuteBeforeCommit!();
    }
    return super.execute(
      action,
      isFeatureEnabled: isFeatureEnabled,
      isAppLocked: isAppLocked,
      authenticationSucceeded: authenticationSucceeded,
      authenticationAttempted: authenticationAttempted,
      additionalConfirmationSucceeded: additionalConfirmationSucceeded,
      currentBaseFingerprint: currentBaseFingerprint,
    );
  }
}

class _TestHarness {
  _TestHarness._({
    required this.repository,
    required this.products,
    required this.handler,
    required this.executor,
    required this.coordinator,
  });

  final MemoryMikiezyRepository repository;
  final List<Product> products;
  final VoiceMutationPreviewHandler handler;
  final VoiceActionCoordinator coordinator;
  final _SpyPriceExecutor executor;
  bool isAppLocked = false;

  int get executorInvocations => executor.invocations;
  String? _lastObservedActionId;
  String? get lastActionId =>
      handler.pendingAction?.actionId ?? _lastObservedActionId;

  Future<VoiceCommandResponse> preview(VoiceCommand command) async {
    final res = await handler.preview(command);
    if (handler.pendingAction != null) {
      _lastObservedActionId = handler.pendingAction!.actionId;
    }
    return res;
  }

  static Future<_TestHarness> create({
    required DateTime initialTime,
    DateTime Function()? timeProvider,
    Future<void> Function(VoiceActionAuditEvent event)? onRecordAudit,
    Future<void> Function()? onExecuteBeforeCommit,
  }) async {
    final initial = [phase6cProduct()];
    final repository = MemoryMikiezyRepository();
    await repository.loadOrSeed(phase6aSnapshot(products: initial));
    final stateProducts = List<Product>.of(initial);

    Future<void> reload() async {
      stateProducts
        ..clear()
        ..addAll(await repository.loadProducts());
    }

    final spyStore = _SpyAuditStore(
      RepositoryVoiceActionAuditStore(repository),
      onRecord: onRecordAudit,
    );

    final nowFn = timeProvider ?? (() => initialTime);

    final spyExecutor = _SpyPriceExecutor(
      repository,
      onCommitted: reload,
      now: () => initialTime,
      onExecuteBeforeCommit: onExecuteBeforeCommit,
    );

    final coordinator = VoiceActionCoordinator(
      spyStore,
      featureFlags: const VoiceMutationFeatureFlags(
        enableVoiceCreateProduct: true,
        enableVoiceStockIncrement: true,
        enableVoicePriceUpdate: true,
      ),
      executors: [spyExecutor],
      now: nowFn,
    );

    late final _TestHarness harness;

    final handler = VoiceMutationPreviewHandler(
      coordinator,
      () => stateProducts,
      isAppLocked: () => harness.isAppLocked,
      refreshProducts: reload,
      now: nowFn,
    );

    harness = _TestHarness._(
      repository: repository,
      products: stateProducts,
      handler: handler,
      coordinator: coordinator,
      executor: spyExecutor,
    );

    return harness;
  }

  Future<void> close() => repository.close();
}
