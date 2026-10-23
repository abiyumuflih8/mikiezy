import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/core/database/app_database.dart';
import 'package:mikiezy/data/local/mikiezy_local_data_source.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/domain/models/product_price.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/models/voice_action_payload.dart';
import 'package:mikiezy/domain/models/voice_price_update_commit.dart';
import 'package:mikiezy/models/mikiezy_models.dart';

import 'support/phase6c_fixtures.dart';

void main() {
  test('selected price and atomic audits commit together', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6cPriceAction(product: fixture.product);

    final result = await fixture.repository.updateProductPriceFromVoice(
      _request(action),
    );

    expect(result.status, VoicePriceUpdateCommitStatus.updated);
    expect((await fixture.repository.loadProducts()).single.retailPrice, 12000);
    expect(
      (await fixture.repository.loadVoiceActionAudits(
        action.actionId,
      )).map((event) => event.status),
      [VoiceActionStatus.executionStarted, VoiceActionStatus.succeeded],
    );
  });

  test('success-audit failure rolls back price and started audit', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6cPriceAction(product: fixture.product);

    await expectLater(
      fixture.repository.updateProductPriceFromVoice(
        _request(
          action,
          startedAuditId: 'same-price-audit-id',
          succeededAuditId: 'same-price-audit-id',
        ),
      ),
      throwsA(
        isA<VoicePriceUpdateCommitException>().having(
          (error) => error.type,
          'type',
          VoicePriceUpdateCommitFailureType.auditFailure,
        ),
      ),
    );

    expect((await fixture.repository.loadProducts()).single.retailPrice, 10000);
    expect(
      await fixture.repository.loadVoiceActionAudits(action.actionId),
      isEmpty,
    );
  });

  test(
    'database update failure leaves price and success audit unchanged',
    () async {
      final fixture = await _DriftFixture.create();
      addTearDown(fixture.close);
      final action = await phase6cPriceAction(product: fixture.product);
      await fixture.database.customStatement('''
      CREATE TRIGGER reject_retail_price_update
      BEFORE UPDATE OF retail_price ON products
      BEGIN
        SELECT RAISE(FAIL, 'simulated retail update failure');
      END;
    ''');

      await expectLater(
        fixture.repository.updateProductPriceFromVoice(_request(action)),
        throwsA(
          isA<VoicePriceUpdateCommitException>().having(
            (error) => error.type,
            'type',
            VoicePriceUpdateCommitFailureType.databaseFailure,
          ),
        ),
      );

      expect(
        (await fixture.repository.loadProducts()).single.retailPrice,
        10000,
      );
      expect(
        await fixture.repository.loadVoiceActionAudits(action.actionId),
        isEmpty,
      );
    },
  );

  test('partial update preserves every non-target product field', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final before = fixture.product;
    final action = await phase6cPriceAction(
      product: before,
      priceType: ProductPriceType.wholesale,
      newPrice: 9500,
    );

    await fixture.repository.updateProductPriceFromVoice(_request(action));
    final after = (await fixture.repository.loadProducts()).single;

    expect(after.wholesalePrice, 9500);
    expect(after.retailPrice, before.retailPrice);
    expect(after.costPrice, before.costPrice);
    expect(after.name, before.name);
    expect(after.category, before.category);
    expect(after.stockPcs, before.stockPcs);
    expect(after.trackStock, before.trackStock);
    expect(after.baseUnit, before.baseUnit);
    expect(after.minStock, before.minStock);
    expect(after.packSize, before.packSize);
    expect(after.cartonSize, before.cartonSize);
  });

  test('double confirmation produces one success audit', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6cPriceAction(product: fixture.product);
    final request = _request(action);

    final first = await fixture.repository.updateProductPriceFromVoice(request);
    final second = await fixture.repository.updateProductPriceFromVoice(
      request,
    );

    expect(first.status, VoicePriceUpdateCommitStatus.updated);
    expect(second.status, VoicePriceUpdateCommitStatus.alreadyExecuted);
    expect(
      (await fixture.repository.loadVoiceActionAudits(
        action.actionId,
      )).where((event) => event.status == VoiceActionStatus.succeeded),
      hasLength(1),
    );
  });

  test('parallel executors cannot overwrite a newer catalog price', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final first = await phase6cPriceAction(
      product: fixture.product,
      newPrice: 12000,
    );
    final second = await phase6cPriceAction(
      product: fixture.product,
      newPrice: 13000,
      now: DateTime(2030, 1, 1, 10, 0, 1),
    );

    final results = await Future.wait([
      fixture.repository.updateProductPriceFromVoice(_request(first)),
      fixture.repository.updateProductPriceFromVoice(_request(second)),
    ]);

    expect(
      results.map((result) => result.status),
      contains(VoicePriceUpdateCommitStatus.updated),
    );
    expect(
      results.map((result) => result.status),
      contains(VoicePriceUpdateCommitStatus.stale),
    );
    expect(
      (await fixture.repository.loadProducts()).single.retailPrice,
      anyOf(12000, 13000),
    );
  });

  test('stale price is rejected without a success audit', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6cPriceAction(product: fixture.product);
    await fixture.dataSource.upsertProduct(
      fixture.product.copyWith(retailPrice: 11000),
    );

    final result = await fixture.repository.updateProductPriceFromVoice(
      _request(action),
    );

    expect(result.status, VoicePriceUpdateCommitStatus.stale);
    expect(result.product?.retailPrice, 11000);
    expect(
      await fixture.repository.loadVoiceActionAudits(action.actionId),
      isEmpty,
    );
  });

  test('retry after rollback can commit safely', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6cPriceAction(product: fixture.product);
    await fixture.database.customStatement('''
      CREATE TRIGGER reject_price_once
      BEFORE UPDATE OF retail_price ON products
      BEGIN
        SELECT RAISE(FAIL, 'simulated one-time failure');
      END;
    ''');
    await expectLater(
      fixture.repository.updateProductPriceFromVoice(_request(action)),
      throwsA(isA<VoicePriceUpdateCommitException>()),
    );
    await fixture.database.customStatement('DROP TRIGGER reject_price_once');

    final retry = await fixture.repository.updateProductPriceFromVoice(
      _request(action),
    );

    expect(retry.status, VoicePriceUpdateCommitStatus.updated);
    expect((await fixture.repository.loadProducts()).single.retailPrice, 12000);
  });

  test('idempotency survives repository recreation', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6cPriceAction(product: fixture.product);
    final request = _request(action);
    await fixture.repository.updateProductPriceFromVoice(request);

    final recreated = DriftMikiezyRepository(fixture.dataSource);
    final duplicate = await recreated.updateProductPriceFromVoice(request);

    expect(duplicate.status, VoicePriceUpdateCommitStatus.alreadyExecuted);
    expect((await recreated.loadProducts()).single.retailPrice, 12000);
  });

  test('same command fingerprint across action IDs stays idempotent', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final first = await phase6cPriceAction(product: fixture.product);
    final second = await phase6cPriceAction(
      product: fixture.product,
      now: DateTime(2030, 1, 1, 10, 0, 1),
    );

    expect(second.actionId, isNot(first.actionId));
    expect(second.commandFingerprint, first.commandFingerprint);
    await fixture.repository.updateProductPriceFromVoice(_request(first));
    final duplicate = await fixture.repository.updateProductPriceFromVoice(
      _request(second),
    );

    expect(duplicate.status, VoicePriceUpdateCommitStatus.alreadyExecuted);
  });

  test('soft-deleted product is never updated', () async {
    final fixture = await _DriftFixture.create();
    addTearDown(fixture.close);
    final action = await phase6cPriceAction(product: fixture.product);
    await fixture.dataSource.softDeleteProduct(fixture.product.id);

    final result = await fixture.repository.updateProductPriceFromVoice(
      _request(action),
    );

    expect(result.status, VoicePriceUpdateCommitStatus.productNotFound);
    expect(await fixture.repository.loadProducts(), isEmpty);
  });
}

VoicePriceUpdateCommitRequest _request(
  VoiceActionDraft action, {
  String? startedAuditId,
  String? succeededAuditId,
}) {
  final payload = action.payload as UpdateProductPriceVoiceActionPayload;
  return VoicePriceUpdateCommitRequest(
    actionId: action.actionId,
    commandFingerprint: action.commandFingerprint,
    payload: payload,
    confirmed: action.status == VoiceActionStatus.confirmed,
    additionalConfirmationSucceeded: payload.requiresAdditionalConfirmation,
    expiresAt: action.expiresAt,
    executionStarted: _audit(
      action,
      VoiceActionStatus.executionStarted,
      id: startedAuditId,
    ),
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
    undoStatus: VoiceUndoStatus.available,
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
    final value = product ?? phase6cProduct();
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
