import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/core/database/app_database.dart';
import 'package:mikiezy/data/local/mikiezy_local_data_source.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/data/repositories/repository_voice_action_audit_store.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/models/voice_action_payload.dart';
import 'package:mikiezy/domain/models/voice_stock_increment_commit.dart';

import 'support/phase6b_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('File-backed SQLite Voice Action Audit Persistence', () {
    late _FileDbFixture fixture;

    setUp(() async {
      fixture = await _FileDbFixture.create();
    });

    tearDown(() async {
      await fixture.dispose();
    });

    test('TEST 1: single audit event survives database close and reopen', () async {
      final event = _syntheticEvent(
        id: 'test-durability-001-succeeded',
        actionId: 'test-durability-001',
        status: VoiceActionStatus.succeeded,
      );

      await fixture.store.record(event);
      final initial = await fixture.store.eventsFor(event.actionId);
      expect(initial, hasLength(1));
      expect(initial.single.id, event.id);

      // Close connection and reopen from the SAME SQLite file on disk
      await fixture.reopen();

      final restored = await fixture.store.eventsFor(event.actionId);
      expect(restored, hasLength(1));
      final reloaded = restored.single;
      expect(reloaded.id, 'test-durability-001-succeeded');
      expect(reloaded.actionId, 'test-durability-001');
      expect(reloaded.actionType, VoiceActionType.updateProductPrice);
      expect(reloaded.status, VoiceActionStatus.succeeded);
      expect(reloaded.source, VoiceActionSource.voice);
      expect(reloaded.targetEntityType, 'product');
      expect(reloaded.targetEntityId, 'product-coffee');
      expect(reloaded.beforeSummary, 'hargaJual: Rp10000');
      expect(reloaded.afterSummary, 'hargaJual: Rp12000');
      expect(reloaded.commandFingerprint, 'test-fingerprint-001');
      expect(reloaded.confirmed, isTrue);
    });

    test('TEST 2: multiple lifecycle statuses retain ordering and uniqueness across reopen', () async {
      const actionId = 'test-lifecycle-002';
      final events = [
        _syntheticEvent(
          id: '$actionId-previewed',
          actionId: actionId,
          status: VoiceActionStatus.previewed,
          createdAt: DateTime(2026, 10, 29, 10, 0, 0),
        ),
        _syntheticEvent(
          id: '$actionId-confirmed',
          actionId: actionId,
          status: VoiceActionStatus.confirmed,
          createdAt: DateTime(2026, 10, 29, 10, 0, 10),
        ),
        _syntheticEvent(
          id: '$actionId-executionStarted',
          actionId: actionId,
          status: VoiceActionStatus.executionStarted,
          createdAt: DateTime(2026, 10, 29, 10, 0, 20),
        ),
        _syntheticEvent(
          id: '$actionId-succeeded',
          actionId: actionId,
          status: VoiceActionStatus.succeeded,
          createdAt: DateTime(2026, 10, 29, 10, 0, 30),
        ),
      ];

      for (final event in events) {
        await fixture.store.record(event);
      }

      await fixture.reopen();

      final restored = await fixture.store.eventsFor(actionId);
      expect(restored, hasLength(4));
      expect(
        restored.map((e) => e.status).toList(),
        [
          VoiceActionStatus.previewed,
          VoiceActionStatus.confirmed,
          VoiceActionStatus.executionStarted,
          VoiceActionStatus.succeeded,
        ],
      );
      expect(
        restored.map((e) => e.id).toList(),
        [
          '$actionId-previewed',
          '$actionId-confirmed',
          '$actionId-executionStarted',
          '$actionId-succeeded',
        ],
      );
    });

    test('TEST 3: duplicate event insertion is ignored and stays unique across reopen', () async {
      final event = _syntheticEvent(
        id: 'test-dup-003-succeeded',
        actionId: 'test-dup-003',
        status: VoiceActionStatus.succeeded,
      );

      // Record twice
      await fixture.store.record(event);
      await fixture.store.record(event);

      await fixture.reopen();

      final restored = await fixture.store.eventsFor(event.actionId);
      expect(restored, hasLength(1));
      expect(restored.single.id, 'test-dup-003-succeeded');
    });

    test('TEST 4: persisted idempotency barrier functions correctly across database reopen', () async {
      const actionId = 'test-idemp-004';
      const commandFingerprint = 'test-idemp-fingerprint-004';

      final succeededEvent = _syntheticEvent(
        id: '$actionId-succeeded',
        actionId: actionId,
        status: VoiceActionStatus.succeeded,
        commandFingerprint: commandFingerprint,
      );

      await fixture.store.record(succeededEvent);

      await fixture.reopen();

      // Check positive match on both actionId and commandFingerprint
      final hasByActionId = await fixture.repository.hasSuccessfulVoiceAction(
        actionId: actionId,
        commandFingerprint: 'non-matching-fingerprint',
      );
      expect(hasByActionId, isTrue);

      final hasByFingerprint = await fixture.repository.hasSuccessfulVoiceAction(
        actionId: 'non-matching-action-id',
        commandFingerprint: commandFingerprint,
      );
      expect(hasByFingerprint, isTrue);

      // Check negative match for unrelated action
      final hasUnrelated = await fixture.repository.hasSuccessfulVoiceAction(
        actionId: 'unrelated-action-id',
        commandFingerprint: 'unrelated-command-fingerprint',
      );
      expect(hasUnrelated, isFalse);
    });

    test('TEST 5: transaction rollback leaves zero partial audits or mutations after reopen', () async {
      // Seed product with 20 stock
      final product = phase6bProduct(id: 'prod-rollback-005', stock: 20);
      await fixture.dataSource.upsertProduct(product);

      final action = await phase6bIncrementAction(product: product);
      final payload = action.payload as IncrementStockVoiceActionPayload;

      // Force a primary key collision between executionStarted and succeeded audits
      const collisionAuditId = 'collision-audit-id-005';
      final request = VoiceStockIncrementCommitRequest(
        actionId: action.actionId,
        commandFingerprint: action.commandFingerprint,
        payload: payload,
        confirmed: true,
        expiresAt: action.expiresAt,
        executionStarted: _auditForAction(
          action,
          VoiceActionStatus.executionStarted,
          id: collisionAuditId,
        ),
        succeeded: _auditForAction(
          action,
          VoiceActionStatus.succeeded,
          id: collisionAuditId, // Triggers unique PK violation on insert
        ),
      );

      await expectLater(
        fixture.repository.incrementProductStockFromVoice(request),
        throwsA(
          isA<VoiceStockIncrementCommitException>().having(
            (error) => error.type,
            'type',
            VoiceStockIncrementCommitFailureType.auditFailure,
          ),
        ),
      );

      // Close and reopen the database from disk
      await fixture.reopen();

      // Verify business data was NOT mutated
      final products = await fixture.repository.loadProducts();
      expect(products.firstWhere((p) => p.id == product.id).stockPcs, 20);

      // Verify started audit was rolled back and not persisted to disk
      final audits = await fixture.repository.loadVoiceActionAudits(action.actionId);
      expect(audits, isEmpty);
    });
  });
}

class _FileDbFixture {
  _FileDbFixture._({
    required this.directory,
    required this.file,
    required this.database,
    required this.dataSource,
    required this.repository,
    required this.store,
  });

  final Directory directory;
  final File file;
  AppDatabase database;
  MikiezyLocalDataSource dataSource;
  DriftMikiezyRepository repository;
  RepositoryVoiceActionAuditStore store;

  static Future<_FileDbFixture> create() async {
    final tempDir = await Directory.systemTemp.createTemp('mikiezy_audit_test_');
    final dbFile = File('${tempDir.path}/test_audit.sqlite');
    final db = AppDatabase(NativeDatabase(dbFile));
    final ds = MikiezyLocalDataSource(db);
    final repo = DriftMikiezyRepository(ds);
    final store = RepositoryVoiceActionAuditStore(repo);
    return _FileDbFixture._(
      directory: tempDir,
      file: dbFile,
      database: db,
      dataSource: ds,
      repository: repo,
      store: store,
    );
  }

  Future<void> reopen() async {
    await repository.close();
    database = AppDatabase(NativeDatabase(file));
    dataSource = MikiezyLocalDataSource(database);
    repository = DriftMikiezyRepository(dataSource);
    store = RepositoryVoiceActionAuditStore(repository);
  }

  Future<void> dispose() async {
    await repository.close();
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (_) {
      // Best-effort cleanup for Windows file locks
    }
  }
}

VoiceActionAuditEvent _syntheticEvent({
  required String id,
  required String actionId,
  required VoiceActionStatus status,
  String commandFingerprint = 'test-fingerprint-001',
  DateTime? createdAt,
}) {
  return VoiceActionAuditEvent(
    id: id,
    actionId: actionId,
    actionType: VoiceActionType.updateProductPrice,
    source: VoiceActionSource.voice,
    status: status,
    targetEntityType: 'product',
    targetEntityId: 'product-coffee',
    beforeSummary: 'hargaJual: Rp10000',
    afterSummary: 'hargaJual: Rp12000',
    confirmed: true,
    commandFingerprint: commandFingerprint,
    createdAt: createdAt ?? DateTime(2026, 10, 29, 12, 0),
  );
}

VoiceActionAuditEvent _auditForAction(
  VoiceActionDraft action,
  VoiceActionStatus status, {
  required String id,
}) {
  return VoiceActionAuditEvent(
    id: id,
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
    createdAt: DateTime(2026, 10, 29, 12, 0),
  );
}
