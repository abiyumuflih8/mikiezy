import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/data/repositories/repository_voice_action_audit_store.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/update_product_price_voice_action_executor.dart';
import 'package:mikiezy/services/voice/voice_action_coordinator.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';
import 'package:mikiezy/services/voice/voice_mutation_preview_handler.dart';

import 'support/phase6a_fixtures.dart';
import 'support/phase6c_fixtures.dart';

void main() {
  final now = DateTime(2030, 1, 1, 10);

  test('preview is formatted and normal confirmation commits once', () async {
    final fixture = await _Fixture.create(now: now);
    addTearDown(fixture.close);

    final preview = await fixture.handler.preview(
      const VoiceCommandRouter().route(
        'Ubah harga kopi susu menjadi dua belas ribu',
      ),
    );
    final action = fixture.handler.pendingAction!;

    expect(preview.kind, VoiceResponseKind.confirmation);
    expect(preview.displayText, contains('Harga lama: Rp 10.000'));
    expect(preview.displayText, contains('Harga baru: Rp 12.000'));
    expect(preview.displayText, contains('Selisih: +Rp 2.000'));
    expect(preview.displayText, contains('Berlaku untuk transaksi baru'));
    expect(
      preview.displayText,
      contains('historis tetap memakai snapshot lama'),
    );
    expect((await fixture.repository.loadProducts()).single.retailPrice, 10000);
    expect(action.isReversible, isTrue);

    final response = await fixture.handler.handlePendingAnswer('ya konfirmasi');

    expect(response.displayText, contains('berhasil diubah'));
    expect((await fixture.repository.loadProducts()).single.retailPrice, 12000);
    expect(fixture.products.single.retailPrice, 12000);
    expect(fixture.handler.hasPendingAction, isFalse);
    expect(
      (await fixture.repository.loadVoiceActionAudits(
        action.actionId,
      )).map((event) => event.status),
      containsAllInOrder([
        VoiceActionStatus.draft,
        VoiceActionStatus.previewed,
        VoiceActionStatus.confirmed,
        VoiceActionStatus.executionStarted,
        VoiceActionStatus.succeeded,
      ]),
    );
  });

  test('extreme change needs two distinct confirmations', () async {
    final fixture = await _Fixture.create(now: now);
    addTearDown(fixture.close);
    await fixture.handler.preview(
      const VoiceCommandRouter().route(
        'Ubah harga kopi susu menjadi seratus ribu',
      ),
    );
    final actionId = fixture.handler.pendingAction!.actionId;

    final first = await fixture.handler.handlePendingAnswer('ya');

    expect(first.title, 'Konfirmasi tambahan');
    expect(first.displayText, contains('naik sangat besar'));
    expect(first.displayText, contains('Harga belum diubah'));
    expect((await fixture.repository.loadProducts()).single.retailPrice, 10000);
    expect(fixture.handler.hasPendingAction, isTrue);

    final second = await fixture.handler.handlePendingAnswer('ya');

    expect(second.displayText, contains('berhasil diubah'));
    expect(
      (await fixture.repository.loadProducts()).single.retailPrice,
      100000,
    );
    expect(
      (await fixture.repository.loadVoiceActionAudits(
        actionId,
      )).map((event) => event.status),
      containsAllInOrder([
        VoiceActionStatus.warningShown,
        VoiceActionStatus.confirmed,
        VoiceActionStatus.additionalConfirmationRequired,
        VoiceActionStatus.additionalConfirmationConfirmed,
        VoiceActionStatus.executionStarted,
        VoiceActionStatus.succeeded,
      ]),
    );
  });

  test('cancel during additional confirmation keeps original price', () async {
    final fixture = await _Fixture.create(now: now);
    addTearDown(fixture.close);
    await fixture.handler.preview(
      const VoiceCommandRouter().route(
        'Ubah harga kopi susu menjadi seratus ribu',
      ),
    );
    await fixture.handler.handlePendingAnswer('ya');

    final response = await fixture.handler.handlePendingAnswer('batal');

    expect(response.displayText, contains('dibatalkan'));
    expect((await fixture.repository.loadProducts()).single.retailPrice, 10000);
    expect(fixture.handler.hasPendingAction, isFalse);
  });

  test('state-visible stale price creates a fresh preview', () async {
    final fixture = await _Fixture.create(now: now);
    addTearDown(fixture.close);
    await fixture.handler.preview(
      const VoiceCommandRouter().route(
        'Ubah harga kopi susu menjadi dua belas ribu',
      ),
    );
    final originalActionId = fixture.handler.pendingAction!.actionId;
    final latest = fixture.product.copyWith(retailPrice: 11000);
    await fixture.repository.saveProduct(latest);
    fixture.products[0] = latest;

    final refreshed = await fixture.handler.handlePendingAnswer('ya');

    expect(refreshed.displayText, contains('Preview baru'));
    expect(refreshed.displayText, contains('Harga lama: Rp 11.000'));
    expect((await fixture.repository.loadProducts()).single.retailPrice, 11000);
    expect(fixture.handler.pendingAction?.actionId, isNot(originalActionId));

    final success = await fixture.handler.handlePendingAnswer('ya');
    expect(success.displayText, contains('berhasil diubah'));
    expect((await fixture.repository.loadProducts()).single.retailPrice, 12000);
  });

  test(
    'repository-only stale price reloads state before reconfirmation',
    () async {
      final fixture = await _Fixture.create(now: now);
      addTearDown(fixture.close);
      await fixture.handler.preview(
        const VoiceCommandRouter().route(
          'Ubah harga kopi susu menjadi dua belas ribu',
        ),
      );
      await fixture.repository.saveProduct(
        fixture.product.copyWith(retailPrice: 11000),
      );
      expect(fixture.products.single.retailPrice, 10000);

      final refreshed = await fixture.handler.handlePendingAnswer('ya');

      expect(refreshed.displayText, contains('Harga lama: Rp 11.000'));
      expect(fixture.products.single.retailPrice, 11000);
      final success = await fixture.handler.handlePendingAnswer('ya');
      expect(success.displayText, contains('berhasil diubah'));
      expect(
        (await fixture.repository.loadProducts()).single.retailPrice,
        12000,
      );
    },
  );

  test('feature flag disabled keeps mutation preview-only', () async {
    final fixture = await _Fixture.create(now: now, enablePriceUpdate: false);
    addTearDown(fixture.close);
    await fixture.handler.preview(
      const VoiceCommandRouter().route(
        'Ubah harga kopi susu menjadi dua belas ribu',
      ),
    );

    final response = await fixture.handler.handlePendingAnswer('ya');

    expect(response.displayText, contains('belum diaktifkan'));
    expect((await fixture.repository.loadProducts()).single.retailPrice, 10000);
  });

  test('lock between preview and confirmation blocks commit', () async {
    var locked = false;
    final fixture = await _Fixture.create(now: now, isLocked: () => locked);
    addTearDown(fixture.close);
    await fixture.handler.preview(
      const VoiceCommandRouter().route(
        'Ubah harga kopi susu menjadi dua belas ribu',
      ),
    );
    locked = true;

    final response = await fixture.handler.handlePendingAnswer('ya');

    expect(response.displayText, contains('terkunci'));
    expect((await fixture.repository.loadProducts()).single.retailPrice, 10000);
    expect(fixture.handler.hasPendingAction, isFalse);
  });

  test('ambiguous clarification is audited without raw transcript', () async {
    final products = [
      phase6cProduct(id: 'aqua-600', name: 'Aqua 600 ml'),
      phase6cProduct(id: 'aqua-1500', name: 'Aqua 1,5 liter'),
    ];
    final fixture = await _Fixture.create(now: now, products: products);
    addTearDown(fixture.close);

    final question = await fixture.handler.preview(
      const VoiceCommandRouter().route('Ubah harga Aqua menjadi 5000'),
    );
    expect(question.kind, VoiceResponseKind.question);
    final preview = await fixture.handler.handleClarificationAnswer(
      'Yang 600 ml',
    );
    final action = fixture.handler.pendingAction!;
    final audits = await fixture.repository.loadVoiceActionAudits(
      action.actionId,
    );

    expect(preview?.kind, VoiceResponseKind.confirmation);
    expect(action.proposed.entityId, 'aqua-600');
    expect(
      audits.map((event) => event.status),
      contains(VoiceActionStatus.clarificationRequested),
    );
    expect(
      audits.every(
        (event) =>
            !event.beforeSummary.contains('Yang 600 ml') &&
            !event.afterSummary.contains('Yang 600 ml'),
      ),
      isTrue,
    );
  });
}

class _Fixture {
  _Fixture._({
    required this.repository,
    required this.products,
    required this.handler,
  });

  final MemoryMikiezyRepository repository;
  final List<Product> products;
  final VoiceMutationPreviewHandler handler;

  Product get product => products.first;

  static Future<_Fixture> create({
    required DateTime now,
    List<Product>? products,
    bool enablePriceUpdate = true,
    bool Function()? isLocked,
  }) async {
    final initial = products ?? [phase6cProduct()];
    final repository = MemoryMikiezyRepository();
    await repository.loadOrSeed(phase6aSnapshot(products: initial));
    final stateProducts = List<Product>.of(initial);

    Future<void> reload() async {
      stateProducts
        ..clear()
        ..addAll(await repository.loadProducts());
    }

    final handler = VoiceMutationPreviewHandler(
      VoiceActionCoordinator(
        RepositoryVoiceActionAuditStore(repository),
        featureFlags: VoiceMutationFeatureFlags(
          enableVoiceCreateProduct: true,
          enableVoiceStockIncrement: true,
          enableVoicePriceUpdate: enablePriceUpdate,
        ),
        executors: [
          UpdateProductPriceVoiceActionExecutor(
            repository,
            onCommitted: reload,
            now: () => now.add(const Duration(minutes: 1)),
          ),
        ],
        now: () => now.add(const Duration(minutes: 1)),
      ),
      () => stateProducts,
      refreshProducts: reload,
      isAppLocked: isLocked,
      now: () => now,
    );
    return _Fixture._(
      repository: repository,
      products: stateProducts,
      handler: handler,
    );
  }

  Future<void> close() => repository.close();
}
