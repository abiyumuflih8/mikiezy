import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/core/database/app_database.dart';
import 'package:mikiezy/data/local/mikiezy_local_data_source.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/models/voice_action_payload.dart';
import 'package:mikiezy/domain/models/voice_create_product_commit.dart';

import 'support/phase6a_fixtures.dart';

void main() {
  test(
    'product, category, started audit, and success audit commit together',
    () async {
      final fixture = _DriftFixture();
      addTearDown(fixture.close);
      final action = phase6aCreateAction(
        product: phase6aProduct(category: 'Kategori Voice Baru'),
      );

      final result = await fixture.repository.createProductFromVoice(
        _request(action),
      );

      expect(result.status, VoiceCreateProductCommitStatus.created);
      expect(await fixture.repository.loadProducts(), hasLength(1));
      expect(
        await fixture.repository.loadProductCategories(),
        contains('Kategori Voice Baru'),
      );
      expect(
        (await fixture.repository.loadVoiceActionAudits(
          action.actionId,
        )).map((event) => event.status),
        [VoiceActionStatus.executionStarted, VoiceActionStatus.succeeded],
      );
    },
  );

  test(
    'success-audit failure rolls back product, category, and started audit',
    () async {
      final fixture = _DriftFixture();
      addTearDown(fixture.close);
      final action = phase6aCreateAction(
        actionId: 'audit-rollback',
        product: phase6aProduct(
          id: 'audit-rollback-product',
          category: 'Rollback Audit Category',
        ),
      );
      final request = _request(
        action,
        startedAuditId: 'same-audit-primary-key',
        succeededAuditId: 'same-audit-primary-key',
      );

      await expectLater(
        fixture.repository.createProductFromVoice(request),
        throwsA(
          isA<VoiceCreateProductCommitException>().having(
            (error) => error.type,
            'type',
            VoiceCreateProductCommitFailureType.auditFailure,
          ),
        ),
      );

      expect(await fixture.repository.loadProducts(), isEmpty);
      expect(
        await fixture.repository.loadProductCategories(),
        isNot(contains('Rollback Audit Category')),
      );
      expect(
        await fixture.repository.loadVoiceActionAudits(action.actionId),
        isEmpty,
      );
    },
  );

  test(
    'product insert collision rolls back new category and all action audits',
    () async {
      final fixture = _DriftFixture();
      addTearDown(fixture.close);
      await fixture.dataSource.upsertProductCategory('Existing', 0);
      await fixture.dataSource.upsertProduct(
        phase6aProduct(
          id: 'product-primary-key',
          name: 'Produk Lama',
          category: 'Existing',
        ),
      );
      final action = phase6aCreateAction(
        actionId: 'insert-rollback',
        product: phase6aProduct(
          id: 'product-primary-key',
          name: 'Produk Baru',
          category: 'Rollback Insert Category',
        ),
      );

      await expectLater(
        fixture.repository.createProductFromVoice(_request(action)),
        throwsA(
          isA<VoiceCreateProductCommitException>().having(
            (error) => error.type,
            'type',
            VoiceCreateProductCommitFailureType.databaseFailure,
          ),
        ),
      );

      final products = await fixture.repository.loadProducts();
      expect(products, hasLength(1));
      expect(products.single.name, 'Produk Lama');
      expect(
        await fixture.repository.loadProductCategories(),
        isNot(contains('Rollback Insert Category')),
      );
      expect(
        await fixture.repository.loadVoiceActionAudits(action.actionId),
        isEmpty,
      );
    },
  );

  test(
    'double callback with the same action creates only one product',
    () async {
      final fixture = _DriftFixture();
      addTearDown(fixture.close);
      final action = phase6aCreateAction(actionId: 'double-action');
      final request = _request(action);

      final first = await fixture.repository.createProductFromVoice(request);
      final second = await fixture.repository.createProductFromVoice(request);

      expect(first.status, VoiceCreateProductCommitStatus.created);
      expect(second.status, VoiceCreateProductCommitStatus.alreadyExecuted);
      expect(await fixture.repository.loadProducts(), hasLength(1));
      final successAudits = (await fixture.repository.loadVoiceActionAudits(
        action.actionId,
      )).where((event) => event.status == VoiceActionStatus.succeeded);
      expect(successAudits, hasLength(1));
    },
  );

  test(
    'duplicate command fingerprint is idempotent across action IDs',
    () async {
      final fixture = _DriftFixture();
      addTearDown(fixture.close);
      final firstAction = phase6aCreateAction(
        actionId: 'fingerprint-first',
        commandFingerprint: 'same-command-fingerprint',
      );
      final secondAction = phase6aCreateAction(
        actionId: 'fingerprint-second',
        commandFingerprint: 'same-command-fingerprint',
        product: phase6aProduct(id: 'second-product', name: 'Teh Susu'),
      );

      await fixture.repository.createProductFromVoice(_request(firstAction));
      final second = await fixture.repository.createProductFromVoice(
        _request(secondAction),
      );

      expect(second.status, VoiceCreateProductCommitStatus.alreadyExecuted);
      expect(await fixture.repository.loadProducts(), hasLength(1));
    },
  );

  test('exact duplicate race is rejected after shared normalization', () async {
    final fixture = _DriftFixture();
    addTearDown(fixture.close);
    final firstAction = phase6aCreateAction(
      actionId: 'duplicate-first',
      commandFingerprint: 'duplicate-fingerprint-first',
    );
    final secondAction = phase6aCreateAction(
      actionId: 'duplicate-second',
      commandFingerprint: 'duplicate-fingerprint-second',
      product: phase6aProduct(id: 'duplicate-id-two', name: 'Kopi   Susu'),
    );

    await fixture.repository.createProductFromVoice(_request(firstAction));
    final duplicate = await fixture.repository.createProductFromVoice(
      _request(secondAction),
    );

    expect(duplicate.status, VoiceCreateProductCommitStatus.duplicateProduct);
    expect(await fixture.repository.loadProducts(), hasLength(1));
    expect(
      (await fixture.repository.loadVoiceActionAudits(
        secondAction.actionId,
      )).single.status,
      VoiceActionStatus.duplicateRejected,
    );
  });

  test(
    'committed product remains available through a repository reload',
    () async {
      final fixture = _DriftFixture();
      addTearDown(fixture.close);
      final action = phase6aCreateAction(actionId: 'reload-action');

      await fixture.repository.createProductFromVoice(_request(action));
      final reloaded = DriftMikiezyRepository(fixture.dataSource);

      expect(
        (await reloaded.loadProducts()).single.id,
        (action.payload as CreateProductVoiceActionPayload).product.id,
      );
    },
  );
}

VoiceCreateProductCommitRequest _request(
  VoiceActionDraft action, {
  String? startedAuditId,
  String? succeededAuditId,
}) {
  return VoiceCreateProductCommitRequest(
    actionId: action.actionId,
    commandFingerprint: action.commandFingerprint,
    payload: action.payload as CreateProductVoiceActionPayload,
    categoryPosition: 0,
    confirmed: action.status == VoiceActionStatus.confirmed,
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
    duplicateRejected: _audit(action, VoiceActionStatus.duplicateRejected),
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
    targetEntityType: action.proposed.entityType,
    targetEntityId: action.proposed.entityId,
    afterSummary: action.proposed.redactedSummary,
    confirmed: true,
    commandFingerprint: action.commandFingerprint,
    undoStatus: VoiceUndoStatus.notAvailable,
    createdAt: DateTime(2030),
  );
}

class _DriftFixture {
  _DriftFixture() : database = AppDatabase(NativeDatabase.memory()) {
    dataSource = MikiezyLocalDataSource(database);
    repository = DriftMikiezyRepository(dataSource);
  }

  final AppDatabase database;
  late MikiezyLocalDataSource dataSource;
  late DriftMikiezyRepository repository;

  Future<void> close() => dataSource.close();
}
