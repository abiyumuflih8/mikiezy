import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/models/voice_action_execution.dart';
import 'package:mikiezy/domain/models/voice_create_product_commit.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/create_product_voice_action_executor.dart';
import 'package:mikiezy/services/voice/voice_product_resolver.dart';
import 'package:mikiezy/state/app_state.dart';

import 'support/phase6a_fixtures.dart';

void main() {
  test('success commits product and refresh callback once', () async {
    final repository = await _memoryRepository();
    var refreshCount = 0;
    final executor = CreateProductVoiceActionExecutor(
      repository,
      onCommitted: () async => refreshCount += 1,
    );

    final result = await _execute(executor, phase6aCreateAction());

    expect(result.status, VoiceActionExecutionStatus.succeeded);
    expect(await repository.loadProducts(), hasLength(1));
    expect(refreshCount, 1);
    final audits = await repository.loadVoiceActionAudits('voice-action-1');
    expect(
      audits.map((event) => event.status),
      containsAll([
        VoiceActionStatus.executionStarted,
        VoiceActionStatus.succeeded,
      ]),
    );
    expect(audits.last.undoStatus, VoiceUndoStatus.notAvailable);
  });

  test('feature flag disabled rejects commit with typed result', () async {
    final repository = await _memoryRepository();
    final executor = CreateProductVoiceActionExecutor(repository);

    final result = await executor.execute(
      phase6aCreateAction(),
      isFeatureEnabled: false,
      isAppLocked: false,
      currentBaseFingerprint: 'catalog-fingerprint-1',
    );

    expect(result.status, VoiceActionExecutionStatus.executionDisabled);
    expect(await repository.loadProducts(), isEmpty);
  });

  test('locked, expired, and not-confirmed actions are rejected', () async {
    final repository = await _memoryRepository();
    final executor = CreateProductVoiceActionExecutor(
      repository,
      now: () => DateTime(2031),
    );

    final locked = await executor.execute(
      phase6aCreateAction(expiresAt: DateTime(2032)),
      isFeatureEnabled: true,
      isAppLocked: true,
      currentBaseFingerprint: 'catalog-fingerprint-1',
    );
    final expired = await executor.execute(
      phase6aCreateAction(actionId: 'expired', expiresAt: DateTime(2030)),
      isFeatureEnabled: true,
      isAppLocked: false,
      currentBaseFingerprint: 'catalog-fingerprint-1',
    );
    final notConfirmed = await executor.execute(
      phase6aCreateAction(
        actionId: 'not-confirmed',
        status: VoiceActionStatus.previewed,
        expiresAt: DateTime(2032),
      ),
      isFeatureEnabled: true,
      isAppLocked: false,
      currentBaseFingerprint: 'catalog-fingerprint-1',
    );

    expect(locked.status, VoiceActionExecutionStatus.locked);
    expect(expired.status, VoiceActionExecutionStatus.expired);
    expect(notConfirmed.status, VoiceActionExecutionStatus.notConfirmed);
    expect(await repository.loadProducts(), isEmpty);
  });

  test(
    'authentication required and failed remain typed and non-mutating',
    () async {
      final repository = await _memoryRepository();
      final executor = CreateProductVoiceActionExecutor(repository);
      final action = phase6aCreateAction(requiresAuthentication: true);

      final required = await executor.execute(
        action,
        isFeatureEnabled: true,
        isAppLocked: false,
        currentBaseFingerprint: action.baseFingerprint,
      );
      final failed = await executor.execute(
        phase6aCreateAction(
          actionId: 'auth-failed',
          requiresAuthentication: true,
        ),
        isFeatureEnabled: true,
        isAppLocked: false,
        authenticationAttempted: true,
        currentBaseFingerprint: action.baseFingerprint,
      );

      expect(
        required.status,
        VoiceActionExecutionStatus.authenticationRequired,
      );
      expect(failed.status, VoiceActionExecutionStatus.authenticationFailed);
      expect(await repository.loadProducts(), isEmpty);
    },
  );

  test('stale catalog is rejected before repository mutation', () async {
    final repository = await _memoryRepository();
    final executor = CreateProductVoiceActionExecutor(repository);

    final result = await executor.execute(
      phase6aCreateAction(),
      isFeatureEnabled: true,
      isAppLocked: false,
      currentBaseFingerprint: 'different-catalog',
    );

    expect(result.status, VoiceActionExecutionStatus.stale);
    expect(await repository.loadProducts(), isEmpty);
  });

  test('domain validation failure never reaches commit', () async {
    final repository = await _memoryRepository();
    final executor = CreateProductVoiceActionExecutor(repository);
    final action = phase6aCreateAction(
      product: phase6aProduct(retailPrice: -1),
    );

    final result = await _execute(executor, action);

    expect(result.status, VoiceActionExecutionStatus.validationFailed);
    expect(await repository.loadProducts(), isEmpty);
  });

  test('unconfirmed similar-product warning blocks execution', () async {
    final repository = await _memoryRepository();
    final executor = CreateProductVoiceActionExecutor(repository);
    final action = phase6aCreateAction(
      similarProductName: 'Kopi Susu Original',
      similarProductConfirmed: false,
    );

    final result = await _execute(executor, action);

    expect(result.status, VoiceActionExecutionStatus.similarProductWarning);
    expect(await repository.loadProducts(), isEmpty);
  });

  test('exact duplicate is rejected without overwriting old data', () async {
    final existing = phase6aProduct(
      id: 'existing',
      name: 'Kopi Susu',
      retailPrice: 7000,
    );
    final repository = await _memoryRepository(products: [existing]);
    final executor = CreateProductVoiceActionExecutor(repository);
    final action = phase6aCreateAction(
      product: phase6aProduct(id: 'new', name: 'Kopi   Susu'),
    );

    final result = await _execute(executor, action);
    final products = await repository.loadProducts();

    expect(result.status, VoiceActionExecutionStatus.duplicateProduct);
    expect(products, hasLength(1));
    expect(products.single.id, 'existing');
    expect(products.single.retailPrice, 7000);
  });

  test('duplicate action ID and fingerprint execute only once', () async {
    final repository = await _memoryRepository();
    final executor = CreateProductVoiceActionExecutor(repository);
    final action = phase6aCreateAction();

    final first = await _execute(executor, action);
    final repeatedAction = await _execute(executor, action);
    final repeatedFingerprint = await _execute(
      executor,
      phase6aCreateAction(
        actionId: 'voice-action-2',
        commandFingerprint: action.commandFingerprint,
        product: phase6aProduct(id: 'different-id', name: 'Teh Susu'),
      ),
    );

    expect(first.status, VoiceActionExecutionStatus.succeeded);
    expect(repeatedAction.status, VoiceActionExecutionStatus.alreadyExecuted);
    expect(
      repeatedFingerprint.status,
      VoiceActionExecutionStatus.alreadyExecuted,
    );
    expect(await repository.loadProducts(), hasLength(1));
  });

  test(
    'typed database and audit commit failures do not report success',
    () async {
      for (final type in VoiceCreateProductCommitFailureType.values) {
        final repository = _CommitFailureRepository(type);
        await repository.loadOrSeed(phase6aSnapshot());
        final executor = CreateProductVoiceActionExecutor(repository);

        final result = await _execute(executor, phase6aCreateAction());

        expect(
          result.status,
          type == VoiceCreateProductCommitFailureType.databaseFailure
              ? VoiceActionExecutionStatus.databaseFailure
              : VoiceActionExecutionStatus.auditFailure,
        );
        expect(await repository.loadProducts(), isEmpty);
      }
    },
  );

  test('terminal audit failure is returned as auditFailure', () async {
    final repository = _AuditWriteFailureRepository();
    await repository.loadOrSeed(phase6aSnapshot());
    final executor = CreateProductVoiceActionExecutor(repository);

    final result = await executor.execute(
      phase6aCreateAction(),
      isFeatureEnabled: false,
      isAppLocked: false,
      currentBaseFingerprint: 'catalog-fingerprint-1',
    );

    expect(result.status, VoiceActionExecutionStatus.auditFailure);
    expect(await repository.loadProducts(), isEmpty);
  });

  test('unexpected repository error is typed and logged as failure', () async {
    final repository = _UnexpectedReadFailureRepository();
    await repository.loadOrSeed(phase6aSnapshot());
    final executor = CreateProductVoiceActionExecutor(repository);

    final result = await _execute(executor, phase6aCreateAction());

    expect(result.status, VoiceActionExecutionStatus.unexpectedFailure);
    expect(await repository.loadProducts(), isEmpty);
  });

  test(
    'commit refreshes state and the resolver sees the persisted product',
    () async {
      final repository = MemoryMikiezyRepository();
      final state = MikiezyState.seeded(repository: repository);
      addTearDown(state.dispose);
      await state.hydrateFromLocal();
      final product = phase6aProduct(
        id: 'voice-new-product',
        name: 'Matcha Latte Demo',
      );
      final executor = CreateProductVoiceActionExecutor(
        repository,
        onCommitted: () =>
            state.refreshProducts(showLoading: false, rethrowErrors: true),
      );

      final result = await _execute(
        executor,
        phase6aCreateAction(product: product),
      );
      final matches = state.products.where((item) => item.id == product.id);
      const resolver = VoiceProductResolver();
      final resolved = resolver.resolve(
        spokenName: 'matcha latte demo',
        products: state.products,
      );

      expect(result.status, VoiceActionExecutionStatus.succeeded);
      expect(matches, hasLength(1));
      expect(resolved.product?.id, product.id);
      expect(await repository.loadProducts(), contains(product));
    },
  );
}

Future<MemoryMikiezyRepository> _memoryRepository({
  List<Product> products = const [],
}) async {
  final repository = MemoryMikiezyRepository();
  await repository.loadOrSeed(phase6aSnapshot(products: products));
  return repository;
}

Future<VoiceActionExecutionResult> _execute(
  CreateProductVoiceActionExecutor executor,
  VoiceActionDraft action,
) {
  return executor.execute(
    action,
    isFeatureEnabled: true,
    isAppLocked: false,
    currentBaseFingerprint: action.baseFingerprint,
  );
}

class _CommitFailureRepository extends MemoryMikiezyRepository {
  _CommitFailureRepository(this.type);

  final VoiceCreateProductCommitFailureType type;

  @override
  Future<VoiceCreateProductCommitResult> createProductFromVoice(
    VoiceCreateProductCommitRequest request,
  ) {
    throw VoiceCreateProductCommitException(
      type: type,
      cause: StateError('simulated commit failure'),
    );
  }
}

class _AuditWriteFailureRepository extends MemoryMikiezyRepository {
  @override
  Future<void> recordVoiceActionAudit(VoiceActionAuditEvent event) {
    throw StateError('simulated audit write failure');
  }
}

class _UnexpectedReadFailureRepository extends MemoryMikiezyRepository {
  @override
  Future<List<String>> loadProductCategories() {
    throw StateError('simulated unexpected read failure');
  }
}
