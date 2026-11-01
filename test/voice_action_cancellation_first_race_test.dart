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
  final now = DateTime(2030, 1, 1, 10);

  group('M4F.69 Cancellation-First Race & Lifecycle Safety Suite', () {
    test('CASE A: normal cancellation without concurrent confirmation succeeds cleanly', () async {
      final harness = await _TestHarness.create(now: now);
      addTearDown(harness.close);

      final preview = await harness.preview(
        const VoiceCommandRouter().route(
          'Ubah harga kopi susu menjadi dua belas ribu',
        ),
      );
      expect(preview.kind, VoiceResponseKind.confirmation);
      expect(harness.handler.hasPendingAction, isTrue);

      await harness.handler.cancelPending(errorCode: 'user_cancelled');
      expect(harness.handler.hasPendingAction, isFalse);
      expect(harness.executorInvocations, 0);

      final audits = await harness.repository.loadVoiceActionAudits(
        harness.lastActionId!,
      );
      expect(audits.any((e) => e.status == VoiceActionStatus.cancelled), isTrue);
      expect(audits.any((e) => e.status == VoiceActionStatus.confirmed), isFalse);
      expect(audits.any((e) => e.status == VoiceActionStatus.succeeded), isFalse);
    });

    test(
      'CASE B: cancelPending begins first and suspends during audit recording; confirmation arrives for SAME actionId',
      () async {
        final cancelAuditReached = Completer<void>();
        final allowCancelAuditProceed = Completer<void>();

        final harness = await _TestHarness.create(
          now: now,
          onRecordAudit: (event) async {
            if (event.status == VoiceActionStatus.cancelled &&
                !cancelAuditReached.isCompleted) {
              cancelAuditReached.complete();
              await allowCancelAuditProceed.future;
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

        // 1. Cancellation starts first
        final cancelFuture = harness.handler.cancelPending(
          errorCode: 'session_closed',
        );
        await cancelAuditReached.future;

        // 2. While cancelPending is awaiting its audit write, confirmation arrives
        final confirmFuture = harness.handler.handlePendingAnswer('konfirmasi');

        // 3. Unblock cancel audit
        allowCancelAuditProceed.complete();

        final results = await Future.wait([cancelFuture, confirmFuture]);
        final confirmResponse = results[1] as VoiceCommandResponse;
        expect(
          confirmResponse.displayText,
          anyOf(contains('Tidak ada perubahan'), contains('sudah pernah')),
        );

        final audits = await harness.repository.loadVoiceActionAudits(actionId);
        final cancelledAudits =
            audits.where((e) => e.status == VoiceActionStatus.cancelled).toList();
        final confirmedAudits =
            audits.where((e) => e.status == VoiceActionStatus.confirmed).toList();
        final succeededAudits =
            audits.where((e) => e.status == VoiceActionStatus.succeeded).toList();

        // CONTRACT ASSERTIONS:
        // Once cancellation has started/accepted, action must NOT execute or commit
        expect(
          harness.executorInvocations,
          0,
          reason: 'Executor must not be invoked after cancellation started',
        );
        expect(
          succeededAudits,
          isEmpty,
          reason: 'Must not record succeeded audit when cancellation started first',
        );
        expect(
          confirmedAudits,
          isEmpty,
          reason: 'Must not record confirmed audit when cancellation started first',
        );
        expect(
          cancelledAudits.length,
          1,
          reason: 'Must record exactly 1 cancelled audit',
        );
        expect((await harness.repository.loadProducts()).single.retailPrice, 10000);
      },
    );

    test(
      'CASE C: voice cancellation via handleAnswer("batal") starts first and suspends during audit write; confirmation overlaps',
      () async {
        final cancelAuditReached = Completer<void>();
        final allowCancelAuditProceed = Completer<void>();

        final harness = await _TestHarness.create(
          now: now,
          onRecordAudit: (event) async {
            if (event.status == VoiceActionStatus.cancelled &&
                !cancelAuditReached.isCompleted) {
              cancelAuditReached.complete();
              await allowCancelAuditProceed.future;
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

        // 1. Voice 'batal' starts first
        final batalFuture = harness.handler.handlePendingAnswer('batal');
        await cancelAuditReached.future;

        // 2. While 'batal' is awaiting its cancelled audit write, concurrent 'ya' arrives
        final confirmFuture = harness.handler.handlePendingAnswer('ya');

        // 3. Unblock cancel audit
        allowCancelAuditProceed.complete();

        final results = await Future.wait([batalFuture, confirmFuture]);
        final batalResponse = results[0];
        final confirmResponse = results[1];
        expect(batalResponse.displayText, contains('Perubahan dibatalkan'));
        expect(
          confirmResponse.displayText,
          anyOf(contains('Tidak ada perubahan'), contains('sudah pernah')),
        );

        final audits = await harness.repository.loadVoiceActionAudits(actionId);
        final cancelledAudits =
            audits.where((e) => e.status == VoiceActionStatus.cancelled).toList();
        final succeededAudits =
            audits.where((e) => e.status == VoiceActionStatus.succeeded).toList();

        expect(
          harness.executorInvocations,
          0,
          reason: 'Executor must not run if "batal" started first',
        );
        expect(succeededAudits, isEmpty);
        expect(cancelledAudits.length, 1);
        expect((await harness.repository.loadProducts()).single.retailPrice, 10000);
      },
    );

    test('CASE D: confirmation begins first, then cancellation occurs; M4F.67 in-flight guard holds', () async {
      final confirmAuditReached = Completer<void>();
      final allowConfirmAuditProceed = Completer<void>();

      final harness = await _TestHarness.create(
        now: now,
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

      final confirmFuture = harness.handler.handlePendingAnswer('konfirmasi');
      await confirmAuditReached.future;

      // Cancellation arrives while confirmation is in-flight
      final cancelFuture = harness.handler.cancelPending(errorCode: 'user_cancelled');

      allowConfirmAuditProceed.complete();
      await Future.wait([confirmFuture, cancelFuture]);

      final audits = await harness.repository.loadVoiceActionAudits(actionId);
      expect(harness.executorInvocations, 1);
      expect(audits.where((e) => e.status == VoiceActionStatus.succeeded).length, 1);
      expect(audits.where((e) => e.status == VoiceActionStatus.cancelled), isEmpty);
      expect((await harness.repository.loadProducts()).single.retailPrice, 12000);
    });

    test(
      'CASE E: lifecycle/AppLock cancellation requested while confirmation is in-flight before commit boundary',
      () async {
        final inFlightReached = Completer<void>();
        final allowProceed = Completer<void>();

        final harness = await _TestHarness.create(
          now: now,
          onRecordAudit: (event) async {
            if (event.status == VoiceActionStatus.confirmed &&
                !inFlightReached.isCompleted) {
              inFlightReached.complete();
              await allowProceed.future;
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

        final confirmFuture = harness.handler.handlePendingAnswer('konfirmasi');
        await inFlightReached.future;

        // AppLock / lifecycle stop requested
        final cancelFuture = harness.handler.cancelPending(
          errorCode: 'voice_session_stopped',
        );

        allowProceed.complete();
        await Future.wait([confirmFuture, cancelFuture]);

        final audits = await harness.repository.loadVoiceActionAudits(actionId);
        // Confirmation was already accepted and in-flight; M4F.67 protection ensures execution completes cleanly
        expect(harness.executorInvocations, 1);
        expect(audits.where((e) => e.status == VoiceActionStatus.succeeded).length, 1);
        expect(audits.where((e) => e.status == VoiceActionStatus.cancelled), isEmpty);
      },
    );

    test(
      'CASE F: cancellation requested after irreversible commit has started does NOT record false cancelled audit',
      () async {
        final commitStarted = Completer<void>();
        final allowCommitFinish = Completer<void>();

        final harness = await _TestHarness.create(
          now: now,
          onExecuteBeforeCommit: () async {
            if (!commitStarted.isCompleted) {
              commitStarted.complete();
              await allowCommitFinish.future;
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

        final confirmFuture = harness.handler.handlePendingAnswer('konfirmasi');
        await commitStarted.future;

        // Cancellation requested while DB transaction is executing
        final cancelFuture = harness.handler.cancelPending(errorCode: 'timeout');

        allowCommitFinish.complete();
        await Future.wait([confirmFuture, cancelFuture]);

        final audits = await harness.repository.loadVoiceActionAudits(actionId);
        expect(harness.executorInvocations, 1);
        expect(audits.where((e) => e.status == VoiceActionStatus.succeeded).length, 1);
        expect(audits.where((e) => e.status == VoiceActionStatus.cancelled), isEmpty);
        expect((await harness.repository.loadProducts()).single.retailPrice, 12000);
      },
    );

    test(
      'CASE G: older cancellation completes after NEW Action B preview exists; Action B remains intact',
      () async {
        final cancelAudit1Reached = Completer<void>();
        final allowCancelAudit1Proceed = Completer<void>();

        final harness = await _TestHarness.create(
          now: now,
          onRecordAudit: (event) async {
            if (event.status == VoiceActionStatus.cancelled &&
                !cancelAudit1Reached.isCompleted) {
              cancelAudit1Reached.complete();
              await allowCancelAudit1Proceed.future;
            }
          },
        );
        addTearDown(harness.close);

        // Preview Action 1
        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi dua belas ribu',
          ),
        );
        final actionId1 = harness.lastActionId!;

        // Start cancel Action 1
        final cancelFuture1 = harness.handler.cancelPending(
          errorCode: 'session_closed',
        );
        await cancelAudit1Reached.future;

        // While Action 1 is cancelling, user previews Action 2
        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi lima belas ribu',
          ),
        );
        final actionId2 = harness.lastActionId!;
        expect(actionId2, isNot(equals(actionId1)));

        // Unblock Action 1 cancellation
        allowCancelAudit1Proceed.complete();
        await cancelFuture1;

        // Action 2 must still be pending!
        expect(harness.handler.hasPendingAction, isTrue);
        expect(harness.handler.pendingAction?.actionId, actionId2);

        // Action 2 can be confirmed and succeeds
        final confirm2 = await harness.handler.handlePendingAnswer('konfirmasi');
        expect(confirm2.displayText, contains('berhasil diubah'));
        expect((await harness.repository.loadProducts()).single.retailPrice, 15000);
      },
    );

    test('CASE H: additional-confirmation flow cancellation behaves correctly', () async {
      final harness = await _TestHarness.create(now: now);
      addTearDown(harness.close);

      // Price from 10000 to 2000 (80% drop) triggers warning
      final preview = await harness.preview(
        const VoiceCommandRouter().route('Ubah harga kopi susu menjadi dua ribu'),
      );
      expect(preview.kind, VoiceResponseKind.confirmation);

      // First confirmation encounters warning
      final step1 = await harness.handler.handlePendingAnswer('ya');
      expect(step1.displayText, contains('turun sangat besar'));

      // Cancel while in warning state
      await harness.handler.cancelPending(errorCode: 'user_aborted');
      expect(harness.handler.hasPendingAction, isFalse);
      expect(harness.executorInvocations, 0);

      final audits = await harness.repository.loadVoiceActionAudits(
        harness.lastActionId!,
      );
      expect(audits.any((e) => e.status == VoiceActionStatus.cancelled), isTrue);
      expect(audits.any((e) => e.status == VoiceActionStatus.succeeded), isFalse);
      expect((await harness.repository.loadProducts()).single.retailPrice, 10000);
    });

    test(
      'CASE I: failure in audit recording during cancellation does not permanently lock or leave inconsistent state',
      () async {
        var failAudit = true;
        final harness = await _TestHarness.create(
          now: now,
          onRecordAudit: (event) async {
            if (event.status == VoiceActionStatus.cancelled && failAudit) {
              failAudit = false;
              throw Exception('Simulated disk full during cancel audit');
            }
          },
        );
        addTearDown(harness.close);

        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi dua belas ribu',
          ),
        );

        // Cancel fails with simulated disk error
        expect(
          () => harness.handler.cancelPending(errorCode: 'error_test'),
          throwsA(isA<Exception>()),
        );

        // Subsequent preview of new action should still work
        final preview2 = await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi tiga belas ribu',
          ),
        );
        expect(preview2.kind, VoiceResponseKind.confirmation);
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
  });

  final MemoryMikiezyRepository repository;
  final List<Product> products;
  final VoiceMutationPreviewHandler handler;
  final _SpyPriceExecutor executor;

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
    required DateTime now,
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

    final spyExecutor = _SpyPriceExecutor(
      repository,
      onCommitted: reload,
      now: () => now.add(const Duration(minutes: 1)),
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
      now: () => now.add(const Duration(minutes: 1)),
    );

    final handler = VoiceMutationPreviewHandler(
      coordinator,
      () => stateProducts,
      refreshProducts: reload,
      now: () => now,
    );

    return _TestHarness._(
      repository: repository,
      products: stateProducts,
      handler: handler,
      executor: spyExecutor,
    );
  }

  Future<void> close() => repository.close();
}
