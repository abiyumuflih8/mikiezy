import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/core/database/app_database.dart';
import 'package:mikiezy/data/local/mikiezy_local_data_source.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/data/repositories/repository_voice_action_audit_store.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/models/voice_action_execution.dart';
import 'package:mikiezy/domain/models/voice_action_payload.dart';
import 'package:mikiezy/domain/models/voice_price_update_commit.dart';
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

  group('M4F.64 Concurrent Confirmation Regression Suite', () {
    test('TEST A: normal single confirmation executes exactly once', () async {
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
      expect(confirmedCount, 1);
      expect(succeededCount, 1);
    });

    test(
      'TEST B & E: two concurrent handleAnswer calls for same action invoke executor only once',
      () async {
        final harness = await _TestHarness.create(now: now);
        addTearDown(harness.close);

        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi dua belas ribu',
          ),
        );
        expect(harness.handler.hasPendingAction, isTrue);

        // Fire two confirmation calls concurrently without awaiting the first.
        final responses = await Future.wait([
          harness.handler.handlePendingAnswer('konfirmasi'),
          harness.handler.handlePendingAnswer('konfirmasi'),
        ]);

        // TEST E: Executor must only be invoked ONCE by the coordinator.
        expect(
          harness.executorInvocations,
          1,
          reason:
              'Coordinator must guard against duplicate executor invocation for the same pending action',
        );

        // TEST F: Only 1 business mutation.
        expect((await harness.repository.loadProducts()).single.retailPrice, 12000);

        final audits = await harness.repository.loadVoiceActionAudits(
          harness.lastActionId!,
        );
        final succeededCount = audits
            .where((e) => e.status == VoiceActionStatus.succeeded)
            .length;
        expect(succeededCount, 1);

        // One response must be success, the other must be recognized as duplicate/in-flight/already executed
        final displayTexts = responses.map((r) => r.displayText).toList();
        expect(displayTexts, anyElement(contains('berhasil diubah')));
      },
    );

    test(
      'TEST C: first confirmation suspended during async audit record does not allow second confirmation into executor',
      () async {
        final auditGate = Completer<void>();
        var auditSuspendedOnce = false;

        final harness = await _TestHarness.create(
          now: now,
          onRecordAudit: (event) async {
            if (event.status == VoiceActionStatus.confirmed &&
                !auditSuspendedOnce) {
              auditSuspendedOnce = true;
              await auditGate.future;
            }
          },
        );
        addTearDown(harness.close);

        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi dua belas ribu',
          ),
        );
        expect(harness.handler.hasPendingAction, isTrue);

        // Start call 1 (will suspend inside audit recording)
        final call1Future = harness.handler.handlePendingAnswer('konfirmasi');

        // Allow microtasks to run so call 1 reaches the suspension point
        await Future<void>.delayed(Duration.zero);

        // Start call 2 while call 1 is suspended
        final call2Future = harness.handler.handlePendingAnswer('konfirmasi');

        // Now release the audit gate
        auditGate.complete();

        final responses = await Future.wait([call1Future, call2Future]);

        expect(
          harness.executorInvocations,
          1,
          reason:
              'Coordinator must not allow second confirmation while first is suspended in audit recording',
        );
        expect((await harness.repository.loadProducts()).single.retailPrice, 12000);

        final audits = await harness.repository.loadVoiceActionAudits(
          harness.lastActionId!,
        );
        final confirmedCount = audits
            .where((e) => e.status == VoiceActionStatus.confirmed)
            .length;
        expect(
          confirmedCount,
          1,
          reason: 'Duplicate confirmed event must not be recorded',
        );

        final succeededCount = audits
            .where((e) => e.status == VoiceActionStatus.succeeded)
            .length;
        expect(succeededCount, 1);
        expect(responses, hasLength(2));
      },
    );

    test(
      'TEST D & G: first confirmation suspended inside executor prevents second confirmation and preserves state',
      () async {
        final executorGate = Completer<void>();
        var executorSuspendedOnce = false;

        final harness = await _TestHarness.create(
          now: now,
          onExecuteBeforeCommit: () async {
            if (!executorSuspendedOnce) {
              executorSuspendedOnce = true;
              await executorGate.future;
            }
          },
        );
        addTearDown(harness.close);

        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi dua belas ribu',
          ),
        );
        expect(harness.handler.hasPendingAction, isTrue);

        // Start call 1 (will suspend inside executor)
        final call1Future = harness.handler.handlePendingAnswer('konfirmasi');

        // Allow microtasks to run so call 1 enters executor and suspends
        await Future<void>.delayed(Duration.zero);

        // Start call 2 while call 1 is executing
        final call2Future = harness.handler.handlePendingAnswer('konfirmasi');

        // Allow call 2 to run its preliminary synchronous checks
        await Future<void>.delayed(Duration.zero);

        // Release executor gate
        executorGate.complete();

        final responses = await Future.wait([call1Future, call2Future]);

        expect(
          harness.executorInvocations,
          1,
          reason: 'Executor must not be re-entered while already in-flight',
        );
        expect((await harness.repository.loadProducts()).single.retailPrice, 12000);
        expect(harness.handler.hasPendingAction, isFalse);

        final audits = await harness.repository.loadVoiceActionAudits(
          harness.lastActionId!,
        );
        final succeededCount = audits
            .where((e) => e.status == VoiceActionStatus.succeeded)
            .length;
        expect(succeededCount, 1);
        expect(responses, hasLength(2));
      },
    );

    test(
      'TEST H: legitimate business warning flow requiring additional confirmation works correctly',
      () async {
        final harness = await _TestHarness.create(now: now);
        addTearDown(harness.close);

        // Extreme price change: 10.000 -> 100.000 triggers business warning
        final preview = await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi seratus ribu',
          ),
        );
        expect(preview.kind, VoiceResponseKind.confirmation);

        // First confirmation triggers additional confirmation prompt
        final firstConfirm = await harness.handler.handlePendingAnswer('ya');
        expect(firstConfirm.kind, VoiceResponseKind.confirmation);
        expect(harness.handler.hasPendingAction, isTrue);
        expect(harness.executorInvocations, 0);

        // Legitimate second confirmation completes the mutation
        final secondConfirm = await harness.handler.handlePendingAnswer('ya');
        expect(secondConfirm.displayText, contains('berhasil diubah'));
        expect(harness.executorInvocations, 1);
        expect(
          (await harness.repository.loadProducts()).single.retailPrice,
          100000,
        );
        expect(harness.handler.hasPendingAction, isFalse);

        final audits = await harness.repository.loadVoiceActionAudits(
          harness.lastActionId!,
        );
        expect(
          audits.map((e) => e.status),
          containsAllInOrder([
            VoiceActionStatus.previewed,
            VoiceActionStatus.confirmed,
            VoiceActionStatus.additionalConfirmationRequired,
            VoiceActionStatus.additionalConfirmationConfirmed,
            VoiceActionStatus.executionStarted,
            VoiceActionStatus.succeeded,
          ]),
        );
      },
    );

    test(
      'TEST I: executor failure does not leave action permanently locked or corrupt',
      () async {
        final harness = await _TestHarness.create(
          now: now,
          onExecuteBeforeCommit: () async {
            throw StateError('Simulated unexpected executor hardware failure');
          },
        );
        addTearDown(harness.close);

        await harness.preview(
          const VoiceCommandRouter().route(
            'Ubah harga kopi susu menjadi dua belas ribu',
          ),
        );
        expect(harness.handler.hasPendingAction, isTrue);

        final response = await harness.handler.handlePendingAnswer('konfirmasi');
        expect(response.kind, VoiceResponseKind.error);
        expect(response.displayText, contains('belum berhasil disimpan'));

        // Pending action must be cleared
        expect(harness.handler.hasPendingAction, isFalse);

        // Price remains untouched
        expect((await harness.repository.loadProducts()).single.retailPrice, 10000);

        final audits = await harness.repository.loadVoiceActionAudits(
          harness.lastActionId!,
        );
        expect(
          audits.map((e) => e.status),
          contains(VoiceActionStatus.failed),
        );
      },
    );

    test(
      'TEST J: Drift database level concurrent commits produce exactly 1 updated and 1 alreadyExecuted',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        final dataSource = MikiezyLocalDataSource(database);
        final repository = DriftMikiezyRepository(dataSource);
        addTearDown(dataSource.close);

        final product = phase6cProduct();
        await dataSource.upsertProductCategory(product.category, 0);
        await dataSource.upsertProduct(product);

        final action = await phase6cPriceAction(
          product: product,
          newPrice: 15000,
        );
        final payload = action.payload as UpdateProductPriceVoiceActionPayload;

        final request = VoicePriceUpdateCommitRequest(
          actionId: action.actionId,
          commandFingerprint: action.commandFingerprint,
          payload: payload,
          confirmed: true,
          additionalConfirmationSucceeded: true,
          expiresAt: action.expiresAt,
          executionStarted: _auditEvent(
            action,
            VoiceActionStatus.executionStarted,
          ),
          succeeded: _auditEvent(action, VoiceActionStatus.succeeded),
        );

        // Execute two concurrent database commits
        final results = await Future.wait([
          repository.updateProductPriceFromVoice(request),
          repository.updateProductPriceFromVoice(request),
        ]);

        final statuses = results.map((r) => r.status).toList();
        expect(statuses, contains(VoicePriceUpdateCommitStatus.updated));
        expect(statuses, contains(VoicePriceUpdateCommitStatus.alreadyExecuted));

        // Exactly one price update occurred
        expect((await repository.loadProducts()).single.retailPrice, 15000);

        final audits = await repository.loadVoiceActionAudits(action.actionId);
        final succeededAudits = audits
            .where((e) => e.status == VoiceActionStatus.succeeded)
            .toList();
        expect(succeededAudits, hasLength(1));
      },
    );
  });
}

VoiceActionAuditEvent _auditEvent(
  VoiceActionDraft action,
  VoiceActionStatus status,
) {
  return VoiceActionAuditEvent(
    id: '${action.actionId}-${status.name}',
    actionId: action.actionId,
    actionType: action.type,
    source: VoiceActionSource.voice,
    status: status,
    targetEntityType: 'product',
    targetEntityId: action.proposed.entityId,
    beforeSummary: action.before?.redactedSummary ?? '',
    afterSummary: action.proposed.redactedSummary,
    confirmed: true,
    commandFingerprint: action.commandFingerprint,
    undoStatus: VoiceUndoStatus.available,
    createdAt: DateTime(2030),
  );
}

class _SpyAuditStore implements VoiceActionAuditStore {
  _SpyAuditStore(this._inner, {this.onRecord});

  final VoiceActionAuditStore _inner;
  final Future<void> Function(VoiceActionAuditEvent event)? onRecord;

  @override
  Future<List<VoiceActionAuditEvent>> eventsFor(String actionId) {
    return _inner.eventsFor(actionId);
  }

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
