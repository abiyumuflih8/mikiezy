import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/core/database/app_database.dart';
import 'package:mikiezy/data/local/mikiezy_local_data_source.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/models/voice_action_payload.dart';
import 'package:mikiezy/domain/models/voice_stock_increment_commit.dart';
import 'package:mikiezy/models/mikiezy_models.dart';

import 'support/phase6b_fixtures.dart';

void main() {
  test('stock update and atomic audits commit together', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6bIncrementAction(product: fixture.product);

    final result = await fixture.repository.incrementProductStockFromVoice(
      _request(action),
    );

    expect(result.status, VoiceStockIncrementCommitStatus.incremented);
    expect((await fixture.repository.loadProducts()).single.stockPcs, 30);
    expect(
      (await fixture.repository.loadVoiceActionAudits(
        action.actionId,
      )).map((event) => event.status),
      [VoiceActionStatus.executionStarted, VoiceActionStatus.succeeded],
    );
  });

  test('success audit failure rolls back stock and started audit', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6bIncrementAction(product: fixture.product);

    await expectLater(
      fixture.repository.incrementProductStockFromVoice(
        _request(
          action,
          startedAuditId: 'same-audit-id',
          succeededAuditId: 'same-audit-id',
        ),
      ),
      throwsA(
        isA<VoiceStockIncrementCommitException>().having(
          (error) => error.type,
          'type',
          VoiceStockIncrementCommitFailureType.auditFailure,
        ),
      ),
    );

    expect((await fixture.repository.loadProducts()).single.stockPcs, 20);
    expect(
      await fixture.repository.loadVoiceActionAudits(action.actionId),
      isEmpty,
    );
  });

  test(
    'database update failure leaves stock and success audit unchanged',
    () async {
      final fixture = await _DriftFixture.create();
      addTearDown(fixture.close);
      final action = await phase6bIncrementAction(product: fixture.product);
      await fixture.database.customStatement('''
      CREATE TRIGGER reject_stock_update
      BEFORE UPDATE OF stock_pcs ON products
      BEGIN
        SELECT RAISE(FAIL, 'simulated stock update failure');
      END;
    ''');

      await expectLater(
        fixture.repository.incrementProductStockFromVoice(_request(action)),
        throwsA(
          isA<VoiceStockIncrementCommitException>().having(
            (error) => error.type,
            'type',
            VoiceStockIncrementCommitFailureType.databaseFailure,
          ),
        ),
      );

      expect((await fixture.repository.loadProducts()).single.stockPcs, 20);
      expect(
        await fixture.repository.loadVoiceActionAudits(action.actionId),
        isEmpty,
      );
    },
  );

  test('tracking activation rolls back together with stock', () async {
    final product = phase6bProduct(
      stock: 0,
      trackStock: false,
      baseUnit: SaleUnit.pcs,
    );
    final fixture = await _DriftFixture.create(product: product);
    addTearDown(fixture.close);
    final action = await phase6bIncrementAction(
      product: product,
      quantity: 1.5,
      unit: SaleUnit.liter,
      trackingEnableConfirmed: true,
      wasClarified: true,
    );

    await expectLater(
      fixture.repository.incrementProductStockFromVoice(
        _request(
          action,
          startedAuditId: 'tracking-audit-id',
          succeededAuditId: 'tracking-audit-id',
        ),
      ),
      throwsA(isA<VoiceStockIncrementCommitException>()),
    );

    final restored = (await fixture.repository.loadProducts()).single;
    expect(restored.trackStock, isFalse);
    expect(restored.baseUnit, SaleUnit.pcs);
    expect(restored.stockPcs, 0);
  });

  test('double callback increments stock only once', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6bIncrementAction(product: fixture.product);
    final request = _request(action);

    final first = await fixture.repository.incrementProductStockFromVoice(
      request,
    );
    final second = await fixture.repository.incrementProductStockFromVoice(
      request,
    );

    expect(first.status, VoiceStockIncrementCommitStatus.incremented);
    expect(second.status, VoiceStockIncrementCommitStatus.alreadyExecuted);
    expect((await fixture.repository.loadProducts()).single.stockPcs, 30);
    expect(
      (await fixture.repository.loadVoiceActionAudits(
        action.actionId,
      )).where((event) => event.status == VoiceActionStatus.succeeded),
      hasLength(1),
    );
  });

  test('parallel actions cannot overwrite a newer stock value', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final firstAction = await phase6bIncrementAction(
      product: fixture.product,
      quantity: 10,
    );
    final secondAction = await phase6bIncrementAction(
      product: fixture.product,
      quantity: 5,
    );

    final results = await Future.wait([
      fixture.repository.incrementProductStockFromVoice(_request(firstAction)),
      fixture.repository.incrementProductStockFromVoice(_request(secondAction)),
    ]);

    expect(
      results.map((result) => result.status),
      contains(VoiceStockIncrementCommitStatus.incremented),
    );
    expect(
      results.map((result) => result.status),
      contains(VoiceStockIncrementCommitStatus.stale),
    );
    expect(
      (await fixture.repository.loadProducts()).single.stockPcs,
      anyOf(25, 30),
    );
  });

  test('stale stock is rejected without an audit success', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6bIncrementAction(product: fixture.product);
    await fixture.dataSource.upsertProduct(
      fixture.product.copyWith(stockPcs: 25),
    );

    final result = await fixture.repository.incrementProductStockFromVoice(
      _request(action),
    );

    expect(result.status, VoiceStockIncrementCommitStatus.stale);
    expect(result.product?.stockPcs, 25);
    expect((await fixture.repository.loadProducts()).single.stockPcs, 25);
    expect(
      await fixture.repository.loadVoiceActionAudits(action.actionId),
      isEmpty,
    );
  });

  test('retry after rollback can commit safely', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6bIncrementAction(product: fixture.product);

    await expectLater(
      fixture.repository.incrementProductStockFromVoice(
        _request(
          action,
          startedAuditId: 'retry-audit-id',
          succeededAuditId: 'retry-audit-id',
        ),
      ),
      throwsA(isA<VoiceStockIncrementCommitException>()),
    );
    final retry = await fixture.repository.incrementProductStockFromVoice(
      _request(action),
    );

    expect(retry.status, VoiceStockIncrementCommitStatus.incremented);
    expect((await fixture.repository.loadProducts()).single.stockPcs, 30);
  });

  test('idempotency survives repository recreation', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6bIncrementAction(product: fixture.product);
    final request = _request(action);
    await fixture.repository.incrementProductStockFromVoice(request);

    final recreated = DriftMikiezyRepository(fixture.dataSource);
    final duplicate = await recreated.incrementProductStockFromVoice(request);

    expect(duplicate.status, VoiceStockIncrementCommitStatus.alreadyExecuted);
    expect((await recreated.loadProducts()).single.stockPcs, 30);
  });

  test('soft-deleted product is never incremented', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6bIncrementAction(product: fixture.product);
    await fixture.dataSource.softDeleteProduct(fixture.product.id);

    final result = await fixture.repository.incrementProductStockFromVoice(
      _request(action),
    );

    expect(result.status, VoiceStockIncrementCommitStatus.productNotFound);
    expect(await fixture.repository.loadProducts(), isEmpty);
  });
}

VoiceStockIncrementCommitRequest _request(
  VoiceActionDraft action, {
  String? startedAuditId,
  String? succeededAuditId,
}) {
  final payload = action.payload as IncrementStockVoiceActionPayload;
  return VoiceStockIncrementCommitRequest(
    actionId: action.actionId,
    commandFingerprint: action.commandFingerprint,
    payload: payload,
    confirmed: action.status == VoiceActionStatus.confirmed,
    expiresAt: action.expiresAt,
    executionStarted: _audit(
      action,
      VoiceActionStatus.executionStarted,
      id: startedAuditId,
    ),
    trackingEnableConfirmed: payload.enableTracking
        ? _audit(action, VoiceActionStatus.trackingEnableConfirmed)
        : null,
    succeeded: _audit(
      action,
      VoiceActionStatus.succeeded,
      id: succeededAuditId,
    ),
  );
}

VoiceActionAuditEvent _audit(
  VoiceActionDraft action,
  VoiceActionStatus status, {
  String? id,
}) {
  return VoiceActionAuditEvent(
    id: id ?? '${action.actionId}-${status.name}',
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
    undoStatus: VoiceUndoStatus.notAvailable,
    createdAt: DateTime(2030),
  );
}

class _DriftFixture {
  _DriftFixture._({
    required this.database,
    required this.dataSource,
    required this.repository,
    required this.product,
  });

  final AppDatabase database;
  final MikiezyLocalDataSource dataSource;
  final DriftMikiezyRepository repository;
  final Product product;

  static Future<_DriftFixture> create({Product? product}) async {
    final value = product ?? phase6bProduct();
    final database = AppDatabase(NativeDatabase.memory());
    final dataSource = MikiezyLocalDataSource(database);
    final repository = DriftMikiezyRepository(dataSource);
    await dataSource.upsertProductCategory(value.category, 0);
    await dataSource.upsertProduct(value);
    return _DriftFixture._(
      database: database,
      dataSource: dataSource,
      repository: repository,
      product: value,
    );
  }

  Future<void> close() => dataSource.close();
}
