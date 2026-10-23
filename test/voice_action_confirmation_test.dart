import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/services/voice_action_audit_store.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/data/repositories/repository_voice_action_audit_store.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/create_product_voice_action_executor.dart';
import 'package:mikiezy/services/voice/voice_action_coordinator.dart';
import 'package:mikiezy/services/voice/voice_mutation_preview_handler.dart';
import 'package:mikiezy/services/voice_assistant_controller.dart';

import 'support/phase6a_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixedNow = DateTime(2026, 7, 13, 10);

  test(
    'valid confirmation is audited but execution remains disabled',
    () async {
      final store = InMemoryVoiceActionAuditStore();
      final coordinator = VoiceActionCoordinator(store, now: () => fixedNow);
      final draft = _draft();

      final preview = await coordinator.preview(draft, isAppLocked: false);
      final confirmed = await coordinator.handleAnswer(
        'ya lanjutkan',
        isAppLocked: false,
        currentBaseFingerprint: (_) async => 'base-v1',
      );
      final statuses = (await store.eventsFor(
        draft.actionId,
      )).map((event) => event.status).toList();

      expect(preview.displayText, contains('belum diterapkan'));
      expect(confirmed.displayText, contains('belum diaktifkan'));
      expect(statuses, [
        VoiceActionStatus.draft,
        VoiceActionStatus.previewed,
        VoiceActionStatus.confirmed,
        VoiceActionStatus.executionDisabled,
      ]);
      expect(coordinator.hasPendingAction, isFalse);
    },
  );

  test('expired confirmation is rejected and audited', () async {
    var clock = DateTime(2026, 7, 13, 10);
    final store = InMemoryVoiceActionAuditStore();
    final coordinator = VoiceActionCoordinator(store, now: () => clock);
    final draft = _draft(
      createdAt: clock,
      expiresAt: clock.add(const Duration(minutes: 2)),
    );
    await coordinator.preview(draft, isAppLocked: false);

    clock = clock.add(const Duration(minutes: 2));
    final response = await coordinator.handleAnswer(
      'konfirmasi',
      isAppLocked: false,
    );

    expect(response.displayText, contains('kedaluwarsa'));
    expect(
      (await store.eventsFor(draft.actionId)).last.status,
      VoiceActionStatus.expired,
    );
  });

  test(
    'cancel, edit, locked, and stale paths never confirm an action',
    () async {
      for (final scenario in ['batal', 'ubah']) {
        final store = InMemoryVoiceActionAuditStore();
        final coordinator = VoiceActionCoordinator(store, now: () => fixedNow);
        await coordinator.preview(_draft(), isAppLocked: false);
        await coordinator.handleAnswer(scenario, isAppLocked: false);
        expect(coordinator.hasPendingAction, isFalse);
        expect(store.events.last.status, VoiceActionStatus.cancelled);
      }

      final lockedStore = InMemoryVoiceActionAuditStore();
      final locked = VoiceActionCoordinator(lockedStore, now: () => fixedNow);
      final lockedResponse = await locked.preview(_draft(), isAppLocked: true);
      expect(lockedResponse.displayText, contains('terkunci'));
      expect(lockedStore.events.single.status, VoiceActionStatus.blockedLocked);

      final staleStore = InMemoryVoiceActionAuditStore();
      final stale = VoiceActionCoordinator(staleStore, now: () => fixedNow);
      await stale.preview(_draft(), isAppLocked: false);
      final staleResponse = await stale.handleAnswer(
        'ya',
        isAppLocked: false,
        currentBaseFingerprint: (_) async => 'base-v2',
      );
      expect(staleResponse.displayText, contains('sudah berubah'));
      expect(staleStore.events.last.status, VoiceActionStatus.staleRejected);
    },
  );

  test(
    'duplicate preview fingerprint and confirmation stay idempotent',
    () async {
      final store = InMemoryVoiceActionAuditStore();
      final coordinator = VoiceActionCoordinator(store, now: () => fixedNow);
      final draft = _draft();

      await coordinator.preview(draft, isAppLocked: false);
      await coordinator.preview(
        _draft(actionId: 'other-action'),
        isAppLocked: false,
      );
      expect(
        store.events.where(
          (event) => event.status == VoiceActionStatus.previewed,
        ),
        hasLength(1),
      );

      await coordinator.handleAnswer('ya', isAppLocked: false);
      final duplicate = await coordinator.handleAnswer(
        'ya',
        isAppLocked: false,
      );
      expect(duplicate.displayText, contains('Tidak ada perubahan'));
      expect(
        store.events.where(
          (event) => event.status == VoiceActionStatus.confirmed,
        ),
        hasLength(1),
      );
    },
  );

  test(
    'controller routes mutation preview and confirmation without data writes',
    () async {
      final product = _product();
      final products = [product];
      final store = InMemoryVoiceActionAuditStore();
      final handler = VoiceMutationPreviewHandler(
        VoiceActionCoordinator(store, now: () => fixedNow),
        () => products,
        now: () => fixedNow,
      );
      final controller = VoiceAssistantController(
        mutationPreviewHandler: handler,
      );
      addTearDown(controller.dispose);

      controller.setTranscript('Ubah harga kopi susu menjadi dua belas ribu');
      await controller.processCurrentTranscript(speakResult: false);
      expect(controller.latestCommandResponse?.kind.name, 'confirmation');
      expect(products.single.retailPrice, 10000);

      controller.setTranscript('ya');
      await controller.processCurrentTranscript(speakResult: false);
      expect(
        controller.latestCommandResponse?.displayText,
        contains('belum diaktifkan'),
      );
      expect(products.single.retailPrice, 10000);
      expect(store.events.last.status, VoiceActionStatus.executionDisabled);
    },
  );

  test(
    'coordinator commits create-product once and only after confirmation',
    () async {
      final repository = MemoryMikiezyRepository();
      await repository.loadOrSeed(phase6aSnapshot());
      final action = phase6aCreateAction(status: VoiceActionStatus.draft);
      final coordinator = VoiceActionCoordinator(
        RepositoryVoiceActionAuditStore(repository),
        featureFlags: const VoiceMutationFeatureFlags(
          enableVoiceCreateProduct: true,
          enableVoiceStockIncrement: false,
          enableVoicePriceUpdate: false,
        ),
        executors: [CreateProductVoiceActionExecutor(repository)],
        now: () => fixedNow,
      );

      await coordinator.preview(action, isAppLocked: false);
      expect(await repository.loadProducts(), isEmpty);

      final response = await coordinator.handleAnswer(
        'konfirmasi',
        isAppLocked: false,
        currentBaseFingerprint: (_) async => action.baseFingerprint,
      );
      final repeated = await coordinator.handleAnswer(
        'konfirmasi',
        isAppLocked: false,
      );

      expect(response.displayText, contains('berhasil ditambahkan'));
      expect(await repository.loadProducts(), hasLength(1));
      expect(repeated.displayText, contains('Tidak ada perubahan'));
      expect(coordinator.hasPendingAction, isFalse);
    },
  );
}

VoiceActionDraft _draft({
  String actionId = 'action-1',
  DateTime? createdAt,
  DateTime? expiresAt,
}) {
  final created = createdAt ?? DateTime(2026, 7, 13, 10);
  return VoiceActionDraft(
    actionId: actionId,
    type: VoiceActionType.updateProductPrice,
    before: VoiceActionSnapshot(
      entityType: 'product',
      entityId: 'product-coffee',
      fingerprint: 'base-v1',
      fields: const {'nama': 'Kopi Susu', 'hargaJual': 'Rp10000'},
    ),
    proposed: VoiceActionSnapshot(
      entityType: 'product',
      entityId: 'product-coffee',
      fingerprint: 'proposed-v1',
      fields: const {'nama': 'Kopi Susu', 'hargaJual': 'Rp12000'},
    ),
    changes: const [
      VoiceActionFieldChange(
        field: 'retailPrice',
        label: 'Harga jual',
        before: 'Rp10000',
        after: 'Rp12000',
      ),
    ],
    summary: 'Harga Kopi Susu akan diubah dari Rp10000 menjadi Rp12000.',
    risk: VoiceActionRisk.medium,
    requiresAuthentication: false,
    isReversible: true,
    createdAt: created,
    expiresAt: expiresAt ?? created.add(const Duration(minutes: 2)),
    sourceTranscript: 'ubah harga kopi susu menjadi dua belas ribu',
    commandFingerprint: 'command-fingerprint',
    baseFingerprint: 'base-v1',
  );
}

Product _product() {
  return const Product(
    id: 'product-coffee',
    name: 'Kopi Susu',
    category: 'Minuman',
    costPrice: 6000,
    retailPrice: 10000,
    wholesalePrice: 9000,
    packSize: 10,
    cartonSize: 24,
    stockPcs: 20,
    baseUnit: SaleUnit.gelas,
  );
}
