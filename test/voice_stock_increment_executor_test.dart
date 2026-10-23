import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/models/voice_action_execution.dart';
import 'package:mikiezy/domain/models/voice_stock_increment_commit.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/increment_stock_voice_action_executor.dart';

import 'support/phase6a_fixtures.dart';
import 'support/phase6b_fixtures.dart';

void main() {
  final clock = DateTime(2030, 1, 1, 10, 1);

  test('success increments integer stock and refreshes once', () async {
    final product = phase6bProduct();
    final repository = await _repositoryWith(product);
    var refreshCount = 0;
    final executor = IncrementStockVoiceActionExecutor(
      repository,
      onCommitted: () async => refreshCount += 1,
      now: () => clock,
    );
    final action = await phase6bIncrementAction(product: product);

    final result = await _execute(executor, action);

    expect(result.status, VoiceActionExecutionStatus.succeeded);
    expect((await repository.loadProducts()).single.stockPcs, 30);
    expect(refreshCount, 1);
  });

  test('success preserves decimal quantity', () async {
    final product = phase6bProduct(stock: 10, baseUnit: SaleUnit.kilo);
    final repository = await _repositoryWith(product);
    final action = await phase6bIncrementAction(
      product: product,
      quantity: 0.5,
      unit: SaleUnit.kilo,
    );

    final result = await _execute(
      IncrementStockVoiceActionExecutor(repository, now: () => clock),
      action,
    );

    expect(result.status, VoiceActionExecutionStatus.succeeded);
    expect((await repository.loadProducts()).single.stockPcs, 10.5);
  });

  test('pack and carton use product metadata', () async {
    for (final entry in {SaleUnit.pack: 36.0, SaleUnit.carton: 96.0}.entries) {
      final product = phase6bProduct(
        stock: 100,
        baseUnit: SaleUnit.sachet,
        packSize: 12,
        cartonSize: 48,
      );
      final repository = await _repositoryWith(product);
      final action = await phase6bIncrementAction(
        product: product,
        quantity: entry.key == SaleUnit.pack ? 3 : 2,
        unit: entry.key,
      );

      final result = await _execute(
        IncrementStockVoiceActionExecutor(repository, now: () => clock),
        action,
      );

      expect(result.status, VoiceActionExecutionStatus.succeeded);
      expect(
        (await repository.loadProducts()).single.stockPcs,
        100 + entry.value,
      );
    }
  });

  test(
    'confirmed tracking activation updates tracking and base unit',
    () async {
      final product = phase6bProduct(
        stock: 0,
        trackStock: false,
        baseUnit: SaleUnit.pcs,
      );
      final repository = await _repositoryWith(product);
      final action = await phase6bIncrementAction(
        product: product,
        quantity: 1.5,
        unit: SaleUnit.liter,
        trackingEnableConfirmed: true,
        wasClarified: true,
      );

      final result = await _execute(
        IncrementStockVoiceActionExecutor(repository, now: () => clock),
        action,
      );
      final updated = (await repository.loadProducts()).single;
      final auditStatuses = (await repository.loadVoiceActionAudits(
        action.actionId,
      )).map((event) => event.status);

      expect(result.status, VoiceActionExecutionStatus.succeeded);
      expect(updated.trackStock, isTrue);
      expect(updated.baseUnit, SaleUnit.liter);
      expect(updated.stockPcs, 1.5);
      expect(
        auditStatuses,
        contains(VoiceActionStatus.trackingEnableConfirmed),
      );
    },
  );

  test('feature flag disabled is typed and non-mutating', () async {
    final product = phase6bProduct();
    final repository = await _repositoryWith(product);
    final action = await phase6bIncrementAction(product: product);

    final result = await _execute(
      IncrementStockVoiceActionExecutor(repository, now: () => clock),
      action,
      enabled: false,
    );

    expect(result.status, VoiceActionExecutionStatus.executionDisabled);
    expect((await repository.loadProducts()).single.stockPcs, 20);
  });

  test('locked app and failed authentication never mutate stock', () async {
    final product = phase6bProduct();
    final repository = await _repositoryWith(product);
    final action = await phase6bIncrementAction(product: product);
    final executor = IncrementStockVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final locked = await _execute(executor, action, locked: true);
    final authAction = _copyAction(action, requiresAuthentication: true);
    final authFailed = await _execute(
      executor,
      authAction,
      authenticationAttempted: true,
    );

    expect(locked.status, VoiceActionExecutionStatus.locked);
    expect(authFailed.status, VoiceActionExecutionStatus.authenticationFailed);
    expect((await repository.loadProducts()).single.stockPcs, 20);
  });

  test('expired and not-confirmed actions are rejected', () async {
    final product = phase6bProduct();
    final repository = await _repositoryWith(product);
    final createdAt = DateTime(2030, 1, 1, 10);
    final expired = await phase6bIncrementAction(
      product: product,
      now: createdAt,
    );
    final notConfirmed = await phase6bIncrementAction(
      product: product,
      status: VoiceActionStatus.previewed,
      now: createdAt,
    );
    final expiredExecutor = IncrementStockVoiceActionExecutor(
      repository,
      now: () => createdAt.add(const Duration(minutes: 3)),
    );

    expect(
      (await _execute(expiredExecutor, expired)).status,
      VoiceActionExecutionStatus.expired,
    );
    expect(
      (await _execute(expiredExecutor, notConfirmed)).status,
      VoiceActionExecutionStatus.expired,
    );

    final activeExecutor = IncrementStockVoiceActionExecutor(
      repository,
      now: () => createdAt.add(const Duration(minutes: 1)),
    );
    expect(
      (await _execute(activeExecutor, notConfirmed)).status,
      VoiceActionExecutionStatus.notConfirmed,
    );
  });

  test('deleted or missing product is rejected', () async {
    final product = phase6bProduct();
    final repository = await _repositoryWith(product);
    final action = await phase6bIncrementAction(product: product);
    await repository.deleteProduct(product.id);

    final result = await _execute(
      IncrementStockVoiceActionExecutor(repository, now: () => clock),
      action,
    );

    expect(result.status, VoiceActionExecutionStatus.productNotFound);
  });

  test('invalid quantity is rejected', () async {
    final product = phase6bProduct();
    final repository = await _repositoryWith(product);
    final action = await phase6bIncrementAction(product: product, quantity: 0);

    final result = await _execute(
      IncrementStockVoiceActionExecutor(repository, now: () => clock),
      action,
    );

    expect(result.status, VoiceActionExecutionStatus.invalidQuantity);
    expect((await repository.loadProducts()).single.stockPcs, 20);
  });

  test('incompatible unit and missing packaging metadata stay typed', () async {
    final bottle = phase6bProduct(baseUnit: SaleUnit.botol);
    final incompatibleRepository = await _repositoryWith(bottle);
    final incompatibleAction = await phase6bIncrementAction(
      product: bottle,
      quantity: 1,
      unit: SaleUnit.kilo,
    );
    final missingPack = phase6bProduct(
      baseUnit: SaleUnit.sachet,
      packSize: 0,
      cartonSize: 0,
    );
    final packRepository = await _repositoryWith(missingPack);
    final packAction = await phase6bIncrementAction(
      product: missingPack,
      quantity: 1,
      unit: SaleUnit.pack,
    );
    final cartonAction = await phase6bIncrementAction(
      product: missingPack,
      quantity: 1,
      unit: SaleUnit.carton,
    );

    expect(
      (await _execute(
        IncrementStockVoiceActionExecutor(
          incompatibleRepository,
          now: () => clock,
        ),
        incompatibleAction,
      )).status,
      VoiceActionExecutionStatus.incompatibleUnit,
    );
    expect(
      (await _execute(
        IncrementStockVoiceActionExecutor(packRepository, now: () => clock),
        packAction,
      )).status,
      VoiceActionExecutionStatus.missingPackSize,
    );
    expect(
      (await _execute(
        IncrementStockVoiceActionExecutor(packRepository, now: () => clock),
        cartonAction,
      )).status,
      VoiceActionExecutionStatus.missingCartonSize,
    );
  });

  for (final mutation in const ['stock', 'base', 'pack']) {
    test('stale $mutation metadata returns latest product', () async {
      final product = phase6bProduct();
      final repository = await _repositoryWith(product);
      final action = await phase6bIncrementAction(product: product);
      final changed = switch (mutation) {
        'stock' => product.copyWith(stockPcs: 25),
        'base' => product.copyWith(baseUnit: SaleUnit.pcs),
        _ => product.copyWith(packSize: 10),
      };
      await repository.saveProduct(changed);

      final result = await _execute(
        IncrementStockVoiceActionExecutor(repository, now: () => clock),
        action,
      );

      expect(result.status, VoiceActionExecutionStatus.stale);
      expect(result.product, changed);
    });
  }

  test('duplicate callback increments stock only once', () async {
    final product = phase6bProduct();
    final repository = await _repositoryWith(product);
    final action = await phase6bIncrementAction(product: product);
    final executor = IncrementStockVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final first = await _execute(executor, action);
    final second = await _execute(executor, action);

    expect(first.status, VoiceActionExecutionStatus.succeeded);
    expect(second.status, VoiceActionExecutionStatus.alreadyExecuted);
    expect((await repository.loadProducts()).single.stockPcs, 30);
  });

  test('typed database and audit failures never report success', () async {
    final product = phase6bProduct();
    for (final failureType in VoiceStockIncrementCommitFailureType.values) {
      final repository = _CommitFailureRepository(failureType);
      await repository.loadOrSeed(phase6aSnapshot(products: [product]));
      final action = await phase6bIncrementAction(product: product);

      final result = await _execute(
        IncrementStockVoiceActionExecutor(repository, now: () => clock),
        action,
      );

      expect(
        result.status,
        failureType == VoiceStockIncrementCommitFailureType.auditFailure
            ? VoiceActionExecutionStatus.auditFailure
            : VoiceActionExecutionStatus.databaseFailure,
      );
      expect((await repository.loadProducts()).single.stockPcs, 20);
    }
  });

  test('unexpected repository error is typed and non-mutating', () async {
    final product = phase6bProduct();
    final repository = _UnexpectedLoadRepository();
    await repository.loadOrSeed(phase6aSnapshot(products: [product]));
    final action = await phase6bIncrementAction(product: product);

    final result = await _execute(
      IncrementStockVoiceActionExecutor(repository, now: () => clock),
      action,
    );

    expect(result.status, VoiceActionExecutionStatus.unexpectedFailure);
  });
}

Future<MemoryMikiezyRepository> _repositoryWith(Product product) async {
  final repository = MemoryMikiezyRepository();
  await repository.loadOrSeed(phase6aSnapshot(products: [product]));
  return repository;
}

Future<VoiceActionExecutionResult> _execute(
  IncrementStockVoiceActionExecutor executor,
  VoiceActionDraft action, {
  bool enabled = true,
  bool locked = false,
  bool authenticationSucceeded = false,
  bool authenticationAttempted = false,
}) {
  return executor.execute(
    action,
    isFeatureEnabled: enabled,
    isAppLocked: locked,
    authenticationSucceeded: authenticationSucceeded,
    authenticationAttempted: authenticationAttempted,
    currentBaseFingerprint: action.baseFingerprint,
  );
}

VoiceActionDraft _copyAction(
  VoiceActionDraft action, {
  bool? requiresAuthentication,
}) {
  return VoiceActionDraft(
    actionId: action.actionId,
    type: action.type,
    before: action.before,
    payload: action.payload,
    proposed: action.proposed,
    changes: action.changes,
    summary: action.summary,
    risk: action.risk,
    requiresAuthentication:
        requiresAuthentication ?? action.requiresAuthentication,
    isReversible: action.isReversible,
    createdAt: action.createdAt,
    expiresAt: action.expiresAt,
    sourceTranscript: action.sourceTranscript,
    commandFingerprint: action.commandFingerprint,
    baseFingerprint: action.baseFingerprint,
    validationErrors: action.validationErrors,
    status: action.status,
  );
}

class _CommitFailureRepository extends MemoryMikiezyRepository {
  _CommitFailureRepository(this.failureType);

  final VoiceStockIncrementCommitFailureType failureType;

  @override
  Future<VoiceStockIncrementCommitResult> incrementProductStockFromVoice(
    VoiceStockIncrementCommitRequest request,
  ) {
    throw VoiceStockIncrementCommitException(
      type: failureType,
      cause: StateError('simulated commit failure'),
    );
  }
}

class _UnexpectedLoadRepository extends MemoryMikiezyRepository {
  @override
  Future<List<Product>> loadProducts() {
    throw StateError('simulated product load failure');
  }
}
