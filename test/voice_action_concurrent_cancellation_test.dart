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

  group('M4F.67 Concurrent Cancellation Safety Suite', () {
    test('CASE A: normal confirmation without cancellation succeeds cleanly', () async {
      final harness = await _TestHarness.create(now: now);
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
      expect(harness.handler.hasPendingAction, isFalse);

      final audits = await harness.repository.loadVoiceActionAudits(
        harness.lastActionId!,
      );
      final confirmedCount = audits
          .where((e) => e.status == VoiceActionStatus.confirmed)
          .length;
      final succeededCount = audits
          .where((e) => e.status == VoiceActionStatus.succeeded)
          .length;
      final cancelledCount = audits
          .where((e) => e.status == VoiceActionStatus.cancelled)
          .length;

      expect(confirmedCount, 1);
      expect(succeededCount, 1);
      expect(cancelledCount, 0);
    });

    test(
      'CASE B: cancelPending while confirmation is suspended during audit recording must not cause contradictory terminal audit or unauthorized mutation',
      () async {
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

        // Start confirmation asynchronously; it suspends inside onRecordAudit(confirmed)
        final confirmFuture = harness.handler.handlePendingAnswer('konfirmasi');
        await confirmAuditReached.future;

        // While confirmation is suspended in-flight, cancelPending() is called
        final cancelFuture = harness.handler.cancelPending(errorCode: 'user_cancelled');

        // Unblock confirmation
        allowConfirmAuditProceed.complete();

        await Future.wait([confirmFuture, cancelFuture]);

        final audits = await harness.repository.loadVoiceActionAudits(actionId);
        final confirmedCount = audits
            .where((e) => e.status == VoiceActionStatus.confirmed)
            .length;
        final succeededCount = audits
            .where((e) => e.status == VoiceActionStatus.succeeded)
            .length;
        final cancelledCount = audits
            .where((e) => e.status == VoiceActionStatus.cancelled)
            .length;

        // CONCURRENCY SAFETY CONTRACT:
        // Audit log must NOT contain both succeeded and cancelled terminal states for the same action.
        expect(
          succeededCount > 0 && cancelledCount > 0,
          isFalse,
          reason: 'Contradictory audit states: action cannot be both succeeded and cancelled',
        );
        expect(confirmedCount, 1);
      },
    );

    test(
      'CASE C: cancelPending during confirmation must NOT strip guard and allow second concurrent confirmation',
      () async {
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

        // Confirmation 1 starts and acquires in-flight guard
        final confirmFuture1 = harness.handler.handlePendingAnswer('konfirmasi');
        await confirmAuditReached.future;

        // cancelPending runs while confirmation 1 is still in-flight
        final cancelFuture = harness.handler.cancelPending(errorCode: 'session_closed');

        // Confirmation 2 arrives while confirmation 1 is still in-flight
        final confirmFuture2 = harness.handler.handlePendingAnswer('konfirmasi');

        // Allow confirmation 1 audit to proceed
        allowConfirmAuditProceed.complete();

        await Future.wait([confirmFuture1, cancelFuture, confirmFuture2]);

        // Executor must NOT be invoked twice for the same action
        expect(
          harness.executorInvocations,
          lessThanOrEqualTo(1),
          reason: 'cancelPending must not allow a second confirmation to re-enter and execute',
        );

        final audits = await harness.repository.loadVoiceActionAudits(actionId);
        final confirmedAudits = audits
            .where((e) => e.status == VoiceActionStatus.confirmed)
            .length;
        expect(
          confirmedAudits,
          1,
          reason: 'Duplicate confirmed audit must not be recorded',
        );
      },
    );

    test(
      'CASE D: cancellation while executor is in-flight must not report cancelled if business commit succeeds',
      () async {
        final executorStarted = Completer<void>();
        final allowExecutorProceed = Completer<void>();

        final harness = await _TestHarness.create(
          now: now,
          onExecuteBeforeCommit: () async {
            if (!executorStarted.isCompleted) {
              executorStarted.complete();
              await allowExecutorProceed.future;
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

        // Confirmation starts and enters executor
        final confirmFuture = harness.handler.handlePendingAnswer('konfirmasi');
        await executorStarted.future;

        // While executor is actively running, attempt cancelPending()
        final cancelFuture = harness.handler.cancelPending(errorCode: 'timeout');

        // Allow executor to proceed
        allowExecutorProceed.complete();

        await Future.wait([confirmFuture, cancelFuture]);

        final audits = await harness.repository.loadVoiceActionAudits(actionId);
        final succeededCount = audits
            .where((e) => e.status == VoiceActionStatus.succeeded)
            .length;
        final cancelledCount = audits
            .where((e) => e.status == VoiceActionStatus.cancelled)
            .length;

        // If the business mutation succeeded in SQLite, it cannot be reported as cancelled
        final product = (await harness.repository.loadProducts()).single;
        if (product.retailPrice == 12000) {
          expect(
            cancelledCount,
            0,
            reason: 'Cannot record cancelled audit for an action whose business mutation committed',
          );
          expect(succeededCount, 1);
        }
      },
    );

    test(
      'CASE E: cancellation during legitimate additional-confirmation state succeeds before second confirmation',
      () async {
        final harness = await _TestHarness.create(now: now);
        addTearDown(harness.close);

        // Kopi susu base price is 10000. Changing to 3000 is a 70% decrease, triggering business warning.
        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi tiga ribu',
          ),
        );
        final actionId = harness.lastActionId!;

        final firstResponse = await harness.handler.handlePendingAnswer('konfirmasi');
        expect(firstResponse.kind, VoiceResponseKind.confirmation);
        expect(firstResponse.displayText, contains('turun sangat besar'));

        // User cancels during additional confirmation
        await harness.handler.cancelPending(errorCode: 'user_cancelled');

        expect(harness.handler.hasPendingAction, isFalse);
        expect(harness.executorInvocations, 0);

        final audits = await harness.repository.loadVoiceActionAudits(actionId);
        final cancelledAudits = audits
            .where((e) => e.status == VoiceActionStatus.cancelled)
            .length;
        expect(cancelledAudits, 1);

        // A subsequent confirmation attempt must be rejected because the action was cancelled
        final secondResponse = await harness.handler.handlePendingAnswer('konfirmasi');
        expect(secondResponse.displayText, contains('Tidak ada perubahan'));
        expect(harness.executorInvocations, 0);
      },
    );

    test('CASE F: exception recovery cleans up in-flight guard properly', () async {
      final harness = await _TestHarness.create(
        now: now,
        onExecuteBeforeCommit: () async {
          throw StateError('Simulated sudden storage failure');
        },
      );
      addTearDown(harness.close);

      await harness.preview(
        const VoiceCommandRouter().route(
          'Ubah harga kopi susu menjadi dua belas ribu',
        ),
      );
      final actionId = harness.lastActionId!;

      final response = await harness.handler.handlePendingAnswer('konfirmasi');
      expect(response.kind, VoiceResponseKind.error);
      expect(response.displayText, contains('belum berhasil'));
      expect(harness.handler.hasPendingAction, isFalse);

      final audits = await harness.repository.loadVoiceActionAudits(actionId);
      final failedCount = audits
          .where((e) => e.status == VoiceActionStatus.failed)
          .length;
      expect(failedCount, 1);
    });

    test(
      'CASE G: _finish of an earlier action must NOT clear a newer pending action',
      () async {
        final confirmStarted = Completer<void>();
        final allowConfirmFinish = Completer<void>();

        final harness = await _TestHarness.create(
          now: now,
          onExecuteBeforeCommit: () async {
            if (!confirmStarted.isCompleted) {
              confirmStarted.complete();
              await allowConfirmFinish.future;
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

        // Confirmation for Action 1 starts and pauses inside executor
        final confirmFuture = harness.handler.handlePendingAnswer('konfirmasi');
        await confirmStarted.future;

        // In the meantime, preview Action 2 (creating new pendingAction)
        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi lima belas ribu',
          ),
        );
        final actionId2 = harness.lastActionId!;
        expect(actionId2, isNot(equals(actionId1)));
        expect(harness.handler.pendingAction?.actionId, actionId2);

        // Now allow Action 1 to finish
        allowConfirmFinish.complete();
        await confirmFuture;

        // Action 2 must NOT have been blown away by Action 1's _finish!
        expect(
          harness.handler.pendingAction?.actionId,
          actionId2,
          reason: 'Earlier action _finish must not clear a newer pendingAction',
        );
      },
    );
  });
}

class _SpyAuditStore implements VoiceActionAuditStore {
  _SpyAuditStore(this._inner, {this.onRecord});

  final VoiceActionAuditStore _inner;
  final Future<void> Function(VoiceActionAuditEvent event)? onRecord;

  @override
  Future<List<VoiceActionAuditEvent>> eventsFor(String actionId) =>
      _inner.eventsFor(actionId);

  @override
  Future<void> record(VoiceActionAuditEvent event) async {
    if (onRecord != null) {
      await onRecord!(event);
    }
    return _inner.record(event);
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
  String? get lastActionId => handler.pendingAction?.actionId ?? _lastObservedActionId;

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

    late final _TestHarness harness;

    final handler = VoiceMutationPreviewHandler(
      coordinator,
      () => stateProducts,
      refreshProducts: reload,
      now: () => now,
    );

    harness = _TestHarness._(
      repository: repository,
      products: stateProducts,
      handler: handler,
      executor: spyExecutor,
    );

    return harness;
  }

  Future<void> close() => repository.close();
}
