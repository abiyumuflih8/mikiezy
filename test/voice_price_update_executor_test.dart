import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/domain/models/product_price.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/models/voice_action_execution.dart';
import 'package:mikiezy/domain/models/voice_action_payload.dart';
import 'package:mikiezy/domain/models/voice_price_update_commit.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/update_product_price_voice_action_executor.dart';

import 'support/phase6a_fixtures.dart';
import 'support/phase6c_fixtures.dart';

void main() {
  final clock = DateTime(2030, 1, 1, 10, 1);

  for (final value in [
    (ProductPriceType.retail, 12000),
    (ProductPriceType.wholesale, 9500),
    (ProductPriceType.cost, 7000),
  ]) {
    test('${value.$1.name} update commits only its selected price', () async {
      final product = phase6cProduct();
      final repository = await _repository(product);
      addTearDown(repository.close);
      final action = await phase6cPriceAction(
        product: product,
        priceType: value.$1,
        newPrice: value.$2,
      );
      var refreshCount = 0;
      final executor = UpdateProductPriceVoiceActionExecutor(
        repository,
        now: () => clock,
        onCommitted: () async => refreshCount += 1,
      );

      final result = await _execute(executor, action);
      final updated = (await repository.loadProducts()).single;

      expect(result.status, VoiceActionExecutionStatus.succeeded);
      expect(value.$1.valueOf(updated), value.$2);
      expect(
        updated.retailPrice,
        value.$1 == ProductPriceType.retail ? value.$2 : product.retailPrice,
      );
      expect(
        updated.wholesalePrice,
        value.$1 == ProductPriceType.wholesale
            ? value.$2
            : product.wholesalePrice,
      );
      expect(
        updated.costPrice,
        value.$1 == ProductPriceType.cost ? value.$2 : product.costPrice,
      );
      expect(updated.stockPcs, product.stockPcs);
      expect(updated.name, product.name);
      expect(updated.category, product.category);
      expect(refreshCount, 1);
    });
  }

  test('feature flag disabled never mutates a price', () async {
    final product = phase6cProduct();
    final repository = await _repository(product);
    addTearDown(repository.close);
    final action = await phase6cPriceAction(product: product);
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final result = await _execute(executor, action, isFeatureEnabled: false);

    expect(result.status, VoiceActionExecutionStatus.executionDisabled);
    expect((await repository.loadProducts()).single.retailPrice, 10000);
  });

  test('committed price reports a typed state refresh failure', () async {
    final product = phase6cProduct();
    final repository = await _repository(product);
    addTearDown(repository.close);
    final action = await phase6cPriceAction(product: product);
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
      onCommitted: () async => throw StateError('refresh failed'),
    );

    final result = await _execute(executor, action);
    final audits = await repository.loadVoiceActionAudits(action.actionId);

    expect(result.status, VoiceActionExecutionStatus.stateRefreshFailed);
    expect(result.message, contains('sudah tersimpan'));
    expect((await repository.loadProducts()).single.retailPrice, 12000);
    expect(
      audits.map((event) => event.status),
      contains(VoiceActionStatus.stateRefreshFailed),
    );
  });

  test('locked app blocks commit', () async {
    final product = phase6cProduct();
    final repository = await _repository(product);
    addTearDown(repository.close);
    final action = await phase6cPriceAction(product: product);
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final result = await _execute(executor, action, isAppLocked: true);

    expect(result.status, VoiceActionExecutionStatus.locked);
    expect((await repository.loadProducts()).single.retailPrice, 10000);
  });

  test('authentication failure is typed and non-mutating', () async {
    final product = phase6cProduct();
    final repository = await _repository(product);
    addTearDown(repository.close);
    final base = await phase6cPriceAction(product: product);
    final action = copyPhase6cAction(base, requiresAuthentication: true);
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final result = await _execute(
      executor,
      action,
      authenticationAttempted: true,
    );

    expect(result.status, VoiceActionExecutionStatus.authenticationFailed);
    expect((await repository.loadProducts()).single.retailPrice, 10000);
  });

  test('expired action is rejected', () async {
    final product = phase6cProduct();
    final repository = await _repository(product);
    addTearDown(repository.close);
    final base = await phase6cPriceAction(product: product);
    final action = copyPhase6cAction(base, expiresAt: DateTime(2030, 1, 1, 10));
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final result = await _execute(executor, action);

    expect(result.status, VoiceActionExecutionStatus.expired);
  });

  test('unconfirmed action is rejected', () async {
    final product = phase6cProduct();
    final repository = await _repository(product);
    addTearDown(repository.close);
    final action = await phase6cPriceAction(
      product: product,
      status: VoiceActionStatus.previewed,
    );
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final result = await _execute(executor, action);

    expect(result.status, VoiceActionExecutionStatus.notConfirmed);
  });

  test('high-risk warning requires a second confirmation', () async {
    final product = phase6cProduct();
    final repository = await _repository(product);
    addTearDown(repository.close);
    final action = await phase6cPriceAction(product: product, newPrice: 100000);
    final payload = action.payload as UpdateProductPriceVoiceActionPayload;
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final blocked = await _execute(executor, action);
    final committed = await _execute(
      executor,
      action,
      additionalConfirmationSucceeded: true,
    );

    expect(payload.requiresAdditionalConfirmation, isTrue);
    expect(
      blocked.status,
      VoiceActionExecutionStatus.additionalConfirmationRequired,
    );
    expect(committed.status, VoiceActionExecutionStatus.succeeded);
    expect((await repository.loadProducts()).single.retailPrice, 100000);
  });

  test('invalid payload is rejected before repository mutation', () async {
    final product = phase6cProduct();
    final repository = await _repository(product);
    addTearDown(repository.close);
    final base = await phase6cPriceAction(product: product);
    final payload = _copyPayload(
      base.payload as UpdateProductPriceVoiceActionPayload,
      validationErrors: const ['invalid'],
    );
    final action = copyPhase6cAction(base, payload: payload);
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final result = await _execute(executor, action);

    expect(result.status, VoiceActionExecutionStatus.invalidPrice);
    expect((await repository.loadProducts()).single.retailPrice, 10000);
  });

  test('same price returns a typed no-op', () async {
    final product = phase6cProduct();
    final repository = await _repository(product);
    addTearDown(repository.close);
    final base = await phase6cPriceAction(product: product);
    final original = base.payload as UpdateProductPriceVoiceActionPayload;
    final payload = _copyPayload(
      original,
      newPrice: original.oldPrice,
      difference: 0,
      percentageChange: 0,
      expectedProductFingerprintAfter: original.productFingerprint,
    );
    final action = copyPhase6cAction(base, payload: payload);
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final result = await _execute(executor, action);

    expect(result.status, VoiceActionExecutionStatus.samePrice);
    expect((await repository.loadProducts()).single.retailPrice, 10000);
  });

  test('deleted or missing product is rejected', () async {
    final product = phase6cProduct();
    final repository = MemoryMikiezyRepository();
    await repository.loadOrSeed(phase6aSnapshot());
    addTearDown(repository.close);
    final action = await phase6cPriceAction(product: product);
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final result = await _execute(executor, action);

    expect(result.status, VoiceActionExecutionStatus.productNotFound);
  });

  for (final type in ProductPriceType.values) {
    test('stale ${type.name} snapshot is rejected', () async {
      final product = phase6cProduct();
      final repository = await _repository(product);
      addTearDown(repository.close);
      final target = switch (type) {
        ProductPriceType.retail => 12000,
        ProductPriceType.wholesale => 9500,
        ProductPriceType.cost => 7000,
      };
      final action = await phase6cPriceAction(
        product: product,
        priceType: type,
        newPrice: target,
      );
      await repository.saveProduct(
        type.applyTo(product, type.valueOf(product) + 100),
      );
      final executor = UpdateProductPriceVoiceActionExecutor(
        repository,
        now: () => clock,
      );

      final result = await _execute(executor, action);

      expect(result.status, VoiceActionExecutionStatus.stale);
      expect(result.product, isNotNull);
    });
  }

  test(
    'change to another price field also invalidates the fingerprint',
    () async {
      final product = phase6cProduct();
      final repository = await _repository(product);
      addTearDown(repository.close);
      final action = await phase6cPriceAction(product: product);
      await repository.saveProduct(product.copyWith(costPrice: 6500));
      final executor = UpdateProductPriceVoiceActionExecutor(
        repository,
        now: () => clock,
      );

      final result = await _execute(executor, action);

      expect(result.status, VoiceActionExecutionStatus.stale);
    },
  );

  test('duplicate action and fingerprint execute only once', () async {
    final product = phase6cProduct();
    final repository = await _repository(product);
    addTearDown(repository.close);
    final action = await phase6cPriceAction(product: product);
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final first = await _execute(executor, action);
    final second = await _execute(executor, action);
    final successes = (await repository.loadVoiceActionAudits(
      action.actionId,
    )).where((event) => event.status == VoiceActionStatus.succeeded);

    expect(first.status, VoiceActionExecutionStatus.succeeded);
    expect(second.status, VoiceActionExecutionStatus.alreadyExecuted);
    expect(successes, hasLength(1));
  });

  test('database failure is typed and never reports success', () async {
    final product = phase6cProduct();
    final repository = _CommitFailureRepository(
      VoicePriceUpdateCommitFailureType.databaseFailure,
    );
    await repository.loadOrSeed(phase6aSnapshot(products: [product]));
    addTearDown(repository.close);
    final action = await phase6cPriceAction(product: product);
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final result = await _execute(executor, action);

    expect(result.status, VoiceActionExecutionStatus.databaseFailure);
    expect((await repository.loadProducts()).single.retailPrice, 10000);
  });

  test('audit failure is typed and never reports success', () async {
    final product = phase6cProduct();
    final repository = _CommitFailureRepository(
      VoicePriceUpdateCommitFailureType.auditFailure,
      rejectAuditWrites: true,
    );
    await repository.loadOrSeed(phase6aSnapshot(products: [product]));
    addTearDown(repository.close);
    final action = await phase6cPriceAction(product: product);
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final result = await _execute(executor, action);

    expect(result.status, VoiceActionExecutionStatus.auditFailure);
    expect((await repository.loadProducts()).single.retailPrice, 10000);
  });

  test('unexpected repository error is converted to typed failure', () async {
    final repository = _UnexpectedLoadRepository();
    addTearDown(repository.close);
    final action = await phase6cPriceAction();
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final result = await _execute(executor, action);

    expect(result.status, VoiceActionExecutionStatus.unexpectedFailure);
  });

  test('unsupported action type is rejected by the price executor', () async {
    final repository = await _repository(phase6cProduct());
    addTearDown(repository.close);
    final action = phase6aCreateAction();
    final executor = UpdateProductPriceVoiceActionExecutor(
      repository,
      now: () => clock,
    );

    final result = await _execute(executor, action);

    expect(result.status, VoiceActionExecutionStatus.unsupportedPriceType);
  });
}

Future<MemoryMikiezyRepository> _repository(Product product) async {
  final repository = MemoryMikiezyRepository();
  await repository.loadOrSeed(phase6aSnapshot(products: [product]));
  return repository;
}

Future<VoiceActionExecutionResult> _execute(
  UpdateProductPriceVoiceActionExecutor executor,
  VoiceActionDraft action, {
  bool isFeatureEnabled = true,
  bool isAppLocked = false,
  bool authenticationSucceeded = false,
  bool authenticationAttempted = false,
  bool additionalConfirmationSucceeded = false,
}) {
  return executor.execute(
    action,
    isFeatureEnabled: isFeatureEnabled,
    isAppLocked: isAppLocked,
    authenticationSucceeded: authenticationSucceeded,
    authenticationAttempted: authenticationAttempted,
    additionalConfirmationSucceeded: additionalConfirmationSucceeded,
    currentBaseFingerprint: action.baseFingerprint,
  );
}

UpdateProductPriceVoiceActionPayload _copyPayload(
  UpdateProductPriceVoiceActionPayload payload, {
  int? newPrice,
  int? difference,
  double? percentageChange,
  String? expectedProductFingerprintAfter,
  List<String>? validationErrors,
}) {
  return UpdateProductPriceVoiceActionPayload(
    actionId: payload.actionId,
    commandFingerprint: payload.commandFingerprint,
    productId: payload.productId,
    spokenProductName: payload.spokenProductName,
    productName: payload.productName,
    priceType: payload.priceType,
    oldPrice: payload.oldPrice,
    newPrice: newPrice ?? payload.newPrice,
    difference: difference ?? payload.difference,
    percentageChange: percentageChange ?? payload.percentageChange,
    retailPriceBefore: payload.retailPriceBefore,
    wholesalePriceBefore: payload.wholesalePriceBefore,
    costPriceBefore: payload.costPriceBefore,
    productFingerprint: payload.productFingerprint,
    expectedProductFingerprintAfter:
        expectedProductFingerprintAfter ??
        payload.expectedProductFingerprintAfter,
    risk: payload.risk,
    requiresAdditionalConfirmation: payload.requiresAdditionalConfirmation,
    expiresAt: payload.expiresAt,
    wasClarified: payload.wasClarified,
    warnings: payload.warnings,
    validationErrors: validationErrors ?? payload.validationErrors,
  );
}

class _CommitFailureRepository extends MemoryMikiezyRepository {
  _CommitFailureRepository(this.failureType, {this.rejectAuditWrites = false});

  final VoicePriceUpdateCommitFailureType failureType;
  final bool rejectAuditWrites;

  @override
  Future<VoicePriceUpdateCommitResult> updateProductPriceFromVoice(
    VoicePriceUpdateCommitRequest request,
  ) {
    throw VoicePriceUpdateCommitException(
      type: failureType,
      cause: StateError('simulated commit failure'),
    );
  }

  @override
  Future<void> recordVoiceActionAudit(VoiceActionAuditEvent event) {
    if (rejectAuditWrites) throw StateError('simulated audit failure');
    return super.recordVoiceActionAudit(event);
  }
}

class _UnexpectedLoadRepository extends MemoryMikiezyRepository {
  @override
  Future<List<Never>> loadProducts() {
    throw StateError('simulated product load failure');
  }
}
