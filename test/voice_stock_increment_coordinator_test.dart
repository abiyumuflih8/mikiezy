import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/data/repositories/repository_voice_action_audit_store.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/increment_stock_voice_action_executor.dart';
import 'package:mikiezy/services/voice/voice_action_coordinator.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';
import 'package:mikiezy/services/voice/voice_mutation_preview_handler.dart';

import 'support/phase6a_fixtures.dart';
import 'support/phase6b_fixtures.dart';

void main() {
  final now = DateTime(2030, 1, 1, 10);

  test(
    'coordinator commits only after confirmation and reloads products',
    () async {
      final product = phase6bProduct();
      final repository = MemoryMikiezyRepository();
      await repository.loadOrSeed(phase6aSnapshot(products: [product]));
      final products = <Product>[product];
      final handler = _handler(
        repository: repository,
        products: products,
        now: now,
      );

      final preview = await handler.preview(
        const VoiceCommandRouter().route('tambah stok kopi susu 10 gelas'),
      );

      expect(preview.kind, VoiceResponseKind.confirmation);
      expect(preview.displayText, contains('Stok sebelum: 20 gelas'));
      expect(preview.displayText, contains('Jumlah diucapkan: 10 gelas'));
      expect(preview.displayText, contains('Stok setelah: 30 gelas'));
      expect(preview.displayText, contains('Undo belum tersedia'));
      expect((await repository.loadProducts()).single.stockPcs, 20);
      final actionId = handler.pendingAction!.actionId;

      final success = await handler.handlePendingAnswer('ya konfirmasi');

      expect(success.displayText, contains('berhasil ditambah'));
      expect((await repository.loadProducts()).single.stockPcs, 30);
      expect(products.single.stockPcs, 30);
      expect(handler.hasPendingAction, isFalse);
      expect(
        (await repository.loadVoiceActionAudits(
          actionId,
        )).map((event) => event.status),
        containsAllInOrder([
          VoiceActionStatus.draft,
          VoiceActionStatus.previewed,
          VoiceActionStatus.confirmed,
          VoiceActionStatus.executionStarted,
          VoiceActionStatus.succeeded,
        ]),
      );
    },
  );

  test(
    'stale stock creates a new preview and requires reconfirmation',
    () async {
      final product = phase6bProduct();
      final repository = MemoryMikiezyRepository();
      await repository.loadOrSeed(phase6aSnapshot(products: [product]));
      final products = <Product>[product];
      final handler = _handler(
        repository: repository,
        products: products,
        now: now,
      );
      await handler.preview(
        const VoiceCommandRouter().route('tambah stok kopi susu 10 gelas'),
      );
      final originalAction = handler.pendingAction!;
      final changed = product.copyWith(stockPcs: 25);
      await repository.saveProduct(changed);
      products[0] = changed;

      final refreshed = await handler.handlePendingAnswer('ya');

      expect(refreshed.kind, VoiceResponseKind.confirmation);
      expect(refreshed.displayText, contains('Preview baru'));
      expect(refreshed.displayText, contains('Stok sebelum: 25 gelas'));
      expect(refreshed.displayText, contains('Stok setelah: 35 gelas'));
      expect((await repository.loadProducts()).single.stockPcs, 25);
      expect(handler.pendingAction?.actionId, isNot(originalAction.actionId));

      final success = await handler.handlePendingAnswer('ya');

      expect(success.displayText, contains('stok sekarang 35 gelas'));
      expect((await repository.loadProducts()).single.stockPcs, 35);
      expect(
        (await repository.loadVoiceActionAudits(
          originalAction.actionId,
        )).map((event) => event.status),
        contains(VoiceActionStatus.staleRejected),
      );
    },
  );

  test('pack preview exposes requested and normalized quantities', () async {
    final product = phase6bProduct(
      stock: 100,
      baseUnit: SaleUnit.sachet,
      packSize: 12,
    );
    final repository = MemoryMikiezyRepository();
    await repository.loadOrSeed(phase6aSnapshot(products: [product]));
    final products = <Product>[product];
    final handler = _handler(
      repository: repository,
      products: products,
      now: now,
    );

    final preview = await handler.preview(
      const VoiceCommandRouter().route('tambah kopi susu 3 pack'),
    );

    expect(preview.displayText, contains('Jumlah diucapkan: 3 pack'));
    expect(preview.displayText, contains('Hasil konversi: 36 sachet'));
    expect(preview.displayText, contains('1 pack = 12 sachet'));
    expect(preview.spokenText, isNot(contains('fingerprint')));
  });
}

VoiceMutationPreviewHandler _handler({
  required MemoryMikiezyRepository repository,
  required List<Product> products,
  required DateTime now,
}) {
  Future<void> reload() async {
    products
      ..clear()
      ..addAll(await repository.loadProducts());
  }

  return VoiceMutationPreviewHandler(
    VoiceActionCoordinator(
      RepositoryVoiceActionAuditStore(repository),
      featureFlags: const VoiceMutationFeatureFlags(
        enableVoiceCreateProduct: true,
        enableVoiceStockIncrement: true,
        enableVoicePriceUpdate: false,
      ),
      executors: [
        IncrementStockVoiceActionExecutor(
          repository,
          onCommitted: reload,
          now: () => now.add(const Duration(minutes: 1)),
        ),
      ],
      now: () => now.add(const Duration(minutes: 1)),
    ),
    () => products,
    now: () => now,
  );
}
