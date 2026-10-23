import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/core/database/app_database.dart';
import 'package:mikiezy/data/local/mikiezy_local_data_source.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/data/repositories/repository_voice_action_audit_store.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/services/voice_action_audit_store.dart';
import 'package:mikiezy/domain/services/voice_action_undo.dart';
import 'package:mikiezy/services/voice/voice_action_coordinator.dart';
import 'package:mikiezy/services/voice/voice_command.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Drift audit store persists redacted event once', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = DriftMikiezyRepository(MikiezyLocalDataSource(database));
    final store = RepositoryVoiceActionAuditStore(repository);
    addTearDown(repository.close);
    final event = _event();

    await store.record(event);
    await store.record(event);
    final restored = await store.eventsFor(event.actionId);

    expect(restored, hasLength(1));
    expect(restored.single.actionType, VoiceActionType.updateProductPrice);
    expect(restored.single.beforeSummary, 'hargaJual: Rp10000');
    expect(restored.single.afterSummary, 'hargaJual: Rp12000');

    final columns = await database
        .customSelect('PRAGMA table_info(voice_action_audits)')
        .get();
    final names = columns.map((row) => row.read<String>('name')).toSet();
    expect(names, isNot(contains('source_transcript')));
    expect(names, isNot(contains('pin')));
    expect(names, isNot(contains('biometric_data')));
  });

  test(
    'audit captures preview, cancel, expired, and validation failure',
    () async {
      var clock = DateTime(2026, 7, 13, 10);
      final store = InMemoryVoiceActionAuditStore();
      final coordinator = VoiceActionCoordinator(store, now: () => clock);

      await coordinator.preview(
        _draft('cancel-action', clock),
        isAppLocked: false,
      );
      await coordinator.handleAnswer('batal', isAppLocked: false);

      final expiring = _draft('expired-action', clock);
      await coordinator.preview(expiring, isAppLocked: false);
      clock = clock.add(const Duration(minutes: 3));
      await coordinator.handleAnswer('ya', isAppLocked: false);

      final invalid = _draft(
        'invalid-action',
        clock,
        validationErrors: const ['Harga belum valid.'],
      );
      await coordinator.preview(invalid, isAppLocked: false);

      expect(
        (await store.eventsFor('cancel-action')).map((event) => event.status),
        [
          VoiceActionStatus.draft,
          VoiceActionStatus.previewed,
          VoiceActionStatus.cancelled,
        ],
      );
      expect(
        (await store.eventsFor('expired-action')).last.status,
        VoiceActionStatus.expired,
      );
      expect(
        (await store.eventsFor('invalid-action')).single.status,
        VoiceActionStatus.validationFailed,
      );
    },
  );

  test(
    'early exact duplicate rejection is audited without a pending action',
    () async {
      final now = DateTime(2026, 7, 13, 10);
      final store = InMemoryVoiceActionAuditStore();
      final coordinator = VoiceActionCoordinator(store, now: () => now);
      final draft = _draft(
        'duplicate-action',
        now,
        type: VoiceActionType.createProduct,
      );

      final response = await coordinator.rejectDuplicate(
        draft,
        response: const VoiceCommandResponse(
          displayText: 'Produk Kopi Susu sudah tersedia.',
          kind: VoiceResponseKind.error,
        ),
        isAppLocked: false,
      );

      final events = await store.eventsFor(draft.actionId);
      expect(response.displayText, contains('sudah tersedia'));
      expect(events, hasLength(1));
      expect(events.single.status, VoiceActionStatus.duplicateRejected);
      expect(events.single.errorCode, 'duplicate_product_name');
      expect(coordinator.hasPendingAction, isFalse);
    },
  );

  test(
    'undo contract is typed while production implementation stays off',
    () async {
      const request = VoiceUndoRequest(
        actionId: 'action-1',
        actionType: VoiceActionType.updateProductPrice,
        entityFingerprint: 'entity-v1',
      );
      const disabled = PreviewOnlyVoiceActionUndoService();
      final fake = _FakeUndoService();

      final disabledResult = await disabled.reverse(request);
      final fakeResult = await fake.reverse(request);

      expect(disabledResult.status, VoiceUndoStatus.notAvailable);
      expect(fakeResult.status, VoiceUndoStatus.completed);
      expect(fake.lastRequest, same(request));
    },
  );
}

VoiceActionAuditEvent _event() {
  return VoiceActionAuditEvent(
    id: 'action-1-previewed',
    actionId: 'action-1',
    actionType: VoiceActionType.updateProductPrice,
    source: VoiceActionSource.voice,
    status: VoiceActionStatus.previewed,
    targetEntityType: 'product',
    targetEntityId: 'product-coffee',
    beforeSummary: 'hargaJual: Rp10000',
    afterSummary: 'hargaJual: Rp12000',
    commandFingerprint: 'safe-hash',
    createdAt: DateTime(2026, 7, 13, 10),
  );
}

VoiceActionDraft _draft(
  String actionId,
  DateTime now, {
  VoiceActionType type = VoiceActionType.updateProductPrice,
  List<String> validationErrors = const [],
}) {
  return VoiceActionDraft(
    actionId: actionId,
    type: type,
    before: VoiceActionSnapshot(
      entityType: 'product',
      entityId: 'product-coffee',
      fingerprint: 'base-v1',
      fields: const {'hargaJual': 'Rp10000'},
    ),
    proposed: VoiceActionSnapshot(
      entityType: 'product',
      entityId: 'product-coffee',
      fingerprint: 'proposed-v1',
      fields: const {'hargaJual': 'Rp12000'},
    ),
    summary: 'Harga akan diubah.',
    risk: VoiceActionRisk.medium,
    requiresAuthentication: false,
    isReversible: true,
    createdAt: now,
    expiresAt: now.add(const Duration(minutes: 2)),
    sourceTranscript: 'transcript hanya di memory',
    commandFingerprint: 'command-hash',
    baseFingerprint: 'base-v1',
    validationErrors: validationErrors,
  );
}

class _FakeUndoService implements VoiceActionUndoService {
  VoiceUndoRequest? lastRequest;

  @override
  Future<VoiceUndoResult> reverse(VoiceUndoRequest request) async {
    lastRequest = request;
    return const VoiceUndoResult(
      status: VoiceUndoStatus.completed,
      message: 'Fake reversal complete.',
    );
  }
}
