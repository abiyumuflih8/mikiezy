import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/core/database/app_database.dart';
import 'package:mikiezy/data/local/mikiezy_local_data_source.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/domain/models/product_price.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/models/voice_action_payload.dart';
import 'package:mikiezy/domain/models/voice_price_update_commit.dart';
import 'package:mikiezy/domain/models/voice_price_update_undo.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/voice_price_update_undo_service.dart';

import 'support/phase6c_fixtures.dart';

void main() {
  for (final value in [
    (ProductPriceType.retail, 12000),
    (ProductPriceType.wholesale, 9500),
    (ProductPriceType.cost, 7000),
  ]) {
    test('undo ${value.$1.name} restores only the previous price', () async {
      final fixture = await _DriftFixture.create();
      addTearDown(fixture.close);
      final action = await phase6cPriceAction(
        product: fixture.product,
        priceType: value.$1,
        newPrice: value.$2,
      );
      await _commit(fixture.repository, action);
      final service = VoicePriceUpdateUndoService(
        fixture.repository,
        now: () => DateTime(2030, 1, 1, 10, 2),
      );

      final result = await service.reverse(
        action.payload as UpdateProductPriceVoiceActionPayload,
        undoActionId: 'undo-${value.$1.name}',
      );
      final restored = (await fixture.repository.loadProducts()).single;
      final audits = await fixture.repository.loadVoiceActionAudits(
        'undo-${value.$1.name}',
      );

      expect(result.status, VoicePriceUpdateUndoStatus.reverted);
      expect(value.$1.valueOf(restored), value.$1.valueOf(fixture.product));
      expect(restored.stockPcs, fixture.product.stockPcs);
      expect(restored.name, fixture.product.name);
      expect(audits.map((event) => event.status), [
        VoiceActionStatus.undoRequested,
        VoiceActionStatus.undoSucceeded,
      ]);
      expect(audits.first.beforeSummary, contains('${value.$2}'));
      expect(
        audits.last.afterSummary,
        contains('${value.$1.valueOf(fixture.product)}'),
      );
    });
  }

  test('duplicate undo is rejected idempotently', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6cPriceAction(product: fixture.product);
    await _commit(fixture.repository, action);
    final service = VoicePriceUpdateUndoService(
      fixture.repository,
      now: () => DateTime(2030, 1, 1, 10, 2),
    );
    final payload = action.payload as UpdateProductPriceVoiceActionPayload;

    final first = await service.reverse(payload, undoActionId: 'undo-first');
    final second = await service.reverse(payload, undoActionId: 'undo-second');

    expect(first.status, VoicePriceUpdateUndoStatus.reverted);
    expect(second.status, VoicePriceUpdateUndoStatus.alreadyReversed);
    expect((await fixture.repository.loadProducts()).single.retailPrice, 10000);
    expect(
      await fixture.repository.loadVoiceActionAudits('undo-second'),
      isEmpty,
    );
  });

  test('newer change to the same price field blocks undo', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6cPriceAction(product: fixture.product);
    await _commit(fixture.repository, action);
    await fixture.dataSource.upsertProduct(
      fixture.product.copyWith(retailPrice: 13000),
    );
    final service = VoicePriceUpdateUndoService(fixture.repository);

    final result = await service.reverse(
      action.payload as UpdateProductPriceVoiceActionPayload,
      undoActionId: 'undo-stale-price',
    );

    expect(result.status, VoicePriceUpdateUndoStatus.stale);
    expect((await fixture.repository.loadProducts()).single.retailPrice, 13000);
    expect(
      (await fixture.repository.loadVoiceActionAudits(
        'undo-stale-price',
      )).map((event) => event.status),
      [VoiceActionStatus.undoRequested, VoiceActionStatus.undoRejected],
    );
  });

  test('change to another price field invalidates undo fingerprint', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6cPriceAction(product: fixture.product);
    await _commit(fixture.repository, action);
    await fixture.dataSource.upsertProduct(
      fixture.product.copyWith(retailPrice: 12000, costPrice: 6500),
    );
    final service = VoicePriceUpdateUndoService(fixture.repository);

    final result = await service.reverse(
      action.payload as UpdateProductPriceVoiceActionPayload,
      undoActionId: 'undo-fingerprint-mismatch',
    );

    expect(result.status, VoicePriceUpdateUndoStatus.stale);
    final latest = (await fixture.repository.loadProducts()).single;
    expect(latest.retailPrice, 12000);
    expect(latest.costPrice, 6500);
  });

  test('soft-deleted product blocks undo', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6cPriceAction(product: fixture.product);
    await _commit(fixture.repository, action);
    await fixture.dataSource.softDeleteProduct(fixture.product.id);
    final service = VoicePriceUpdateUndoService(fixture.repository);

    final result = await service.reverse(
      action.payload as UpdateProductPriceVoiceActionPayload,
      undoActionId: 'undo-deleted-product',
    );

    expect(result.status, VoicePriceUpdateUndoStatus.productNotFound);
    expect(await fixture.repository.loadProducts(), isEmpty);
  });

  test('missing original success audit blocks undo', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6cPriceAction(product: fixture.product);
    final payload = action.payload as UpdateProductPriceVoiceActionPayload;
    await fixture.dataSource.upsertProduct(
      ProductPriceType.retail.applyTo(fixture.product, payload.newPrice),
    );
    final service = VoicePriceUpdateUndoService(fixture.repository);

    final result = await service.reverse(
      payload,
      undoActionId: 'undo-without-original-audit',
    );

    expect(result.status, VoicePriceUpdateUndoStatus.originalActionNotFound);
    expect((await fixture.repository.loadProducts()).single.retailPrice, 12000);
  });

  test(
    'price update failure rolls back undo and records typed failure',
    () async {
      final fixture = await _DriftFixture.create();
      addTearDown(fixture.close);
      final action = await phase6cPriceAction(product: fixture.product);
      await _commit(fixture.repository, action);
      await fixture.database.customStatement('''
      CREATE TRIGGER reject_price_undo
      BEFORE UPDATE OF retail_price ON products
      BEGIN
        SELECT RAISE(FAIL, 'simulated undo update failure');
      END;
    ''');
      final service = VoicePriceUpdateUndoService(fixture.repository);

      final result = await service.reverse(
        action.payload as UpdateProductPriceVoiceActionPayload,
        undoActionId: 'undo-update-failure',
      );

      expect(result.status, VoicePriceUpdateUndoStatus.databaseFailure);
      expect(
        (await fixture.repository.loadProducts()).single.retailPrice,
        12000,
      );
      expect(
        (await fixture.repository.loadVoiceActionAudits(
          'undo-update-failure',
        )).map((event) => event.status),
        [VoiceActionStatus.undoFailed],
      );
    },
  );

  test('undo success-audit failure rolls back restored price', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6cPriceAction(product: fixture.product);
    await _commit(fixture.repository, action);
    await fixture.database.customStatement('''
      CREATE TRIGGER reject_undo_success_audit
      BEFORE INSERT ON voice_action_audits
      WHEN NEW.status = 'undoSucceeded'
      BEGIN
        SELECT RAISE(FAIL, 'simulated undo audit failure');
      END;
    ''');
    final service = VoicePriceUpdateUndoService(fixture.repository);

    final result = await service.reverse(
      action.payload as UpdateProductPriceVoiceActionPayload,
      undoActionId: 'undo-audit-failure',
    );

    expect(result.status, VoicePriceUpdateUndoStatus.auditFailure);
    expect((await fixture.repository.loadProducts()).single.retailPrice, 12000);
    expect(
      (await fixture.repository.loadVoiceActionAudits(
        'undo-audit-failure',
      )).map((event) => event.status),
      [VoiceActionStatus.undoFailed],
    );
  });
}

Future<VoicePriceUpdateCommitResult> _commit(
  DriftMikiezyRepository repository,
  VoiceActionDraft action,
) {
  final payload = action.payload as UpdateProductPriceVoiceActionPayload;
  return repository.updateProductPriceFromVoice(
    VoicePriceUpdateCommitRequest(
      actionId: action.actionId,
      commandFingerprint: action.commandFingerprint,
      payload: payload,
      confirmed: true,
      additionalConfirmationSucceeded: payload.requiresAdditionalConfirmation,
      expiresAt: action.expiresAt,
      executionStarted: _audit(action, VoiceActionStatus.executionStarted),
      succeeded: _audit(action, VoiceActionStatus.succeeded),
    ),
  );
}

VoiceActionAuditEvent _audit(
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
    undoStatus: VoiceUndoStatus.available,
    commandFingerprint: action.commandFingerprint,
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

  static Future<_DriftFixture> create() async {
    final product = phase6cProduct();
    final database = AppDatabase(NativeDatabase.memory());
    final dataSource = MikiezyLocalDataSource(database);
    final repository = DriftMikiezyRepository(dataSource);
    await dataSource.upsertProductCategory(product.category, 0);
    await dataSource.upsertProduct(product);
    return _DriftFixture._(
      database: database,
      dataSource: dataSource,
      repository: repository,
      product: product,
    );
  }

  Future<void> close() => dataSource.close();
}
