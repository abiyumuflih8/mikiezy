import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/core/database/app_database.dart';
import 'package:mikiezy/data/local/mikiezy_local_data_source.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/domain/models/product_price.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/models/voice_action_payload.dart';
import 'package:mikiezy/domain/models/voice_price_update_commit.dart';
import 'package:mikiezy/domain/services/business_metrics_service.dart';
import 'package:mikiezy/domain/services/report_period_resolver.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/screens/receipt_screen.dart';
import 'package:mikiezy/services/voice/parsed_transaction_item.dart';
import 'package:mikiezy/services/voice/voice_product_price_resolver.dart';
import 'package:mikiezy/services/voice/voice_product_resolver.dart';
import 'package:mikiezy/state/app_state.dart';

import 'support/phase6c_fixtures.dart';

void main() {
  test(
    'catalog updates preserve every historical financial snapshot',
    () async {
      final fixture = await _HistoricalFixture.create();
      addTearDown(fixture.close);
      final beforeMetrics = _metrics([fixture.oldTransaction]);

      await fixture.applyRetailAndCostUpdates();
      final restored = await fixture.repository.loadTransactionById(
        fixture.oldTransaction.id,
      );
      final afterMetrics = _metrics(
        await fixture.repository.loadTransactions(),
      );

      expect(restored, isNotNull);
      expect(restored!.lines.single.unitPrice, 10000);
      expect(restored.lines.single.costPrice, 6000);
      expect(restored.lines.single.unitMultiplier, 1);
      expect(restored.lines.single.total, 20000);
      expect(restored.amount, 20000);
      expect(restored.totalCost, 12000);
      expect(restored.profitContribution, 8000);
      expect(afterMetrics.$1, beforeMetrics.$1);
      expect(afterMetrics.$2, beforeMetrics.$2);
    },
  );

  test(
    'resolver and a new saved transaction use new retail and cost',
    () async {
      final fixture = await _HistoricalFixture.create();
      addTearDown(fixture.close);
      await fixture.applyRetailAndCostUpdates();
      final products = await fixture.repository.loadProducts();
      final updated = products.single;
      final match = const VoiceProductResolver().resolve(
        spokenName: updated.name,
        products: products,
      );
      final price = const VoiceProductPriceResolver().resolve(
        item: ParsedTransactionItem(
          rawText: 'kopi susu satu gelas',
          productName: updated.name,
          quantity: 1,
          unit: 'gelas',
        ),
        productMatch: match,
      );

      expect(match.product?.id, updated.id);
      expect(price.source, VoicePriceSource.catalogRetail);
      expect(price.unitPrice, 12000);

      final state = MikiezyState(
        products: products,
        productCategories: [updated.category],
        wallets: [fixture.wallet],
        categories: [fixture.category],
        transactions: await fixture.repository.loadTransactions(),
        repository: fixture.repository,
      )..enableVoiceLearning = false;
      addTearDown(state.dispose);
      final saved = await state.saveDraft(
        TransactionDraft(
          kind: TransactionKind.sale,
          productName: updated.name,
          quantity: 1,
          unit: SaleUnit.gelas,
          unitPrice: price.unitPrice!,
          discount: 0,
          categoryName: fixture.category.name,
          walletName: fixture.wallet.name,
          segment: PriceSegment.retail,
          note: '',
          rawText: 'jual kopi susu satu gelas',
          lines: [
            TransactionDraftLine(
              tempId: 'new-line',
              productId: updated.id,
              productName: updated.name,
              quantity: 1,
              unit: SaleUnit.gelas,
              unitPrice: price.unitPrice!,
              segment: PriceSegment.retail,
              priceSource: TransactionDraftPriceSource.catalogRetail,
              productStatus: TransactionDraftProductStatus.matched,
            ),
          ],
        ),
      );

      expect(saved.lines.single.unitPrice, 12000);
      expect(saved.lines.single.costPrice, 7000);
      expect(saved.lines.single.unitMultiplier, 1);
      final old = state.transactions.firstWhere(
        (transaction) => transaction.id == fixture.oldTransaction.id,
      );
      expect(old.lines.single.unitPrice, 10000);
      expect(old.lines.single.costPrice, 6000);
      final metrics = _metrics(state.transactions);
      expect(metrics.$1, 32000);
      expect(metrics.$2, 13000);
    },
  );

  testWidgets('old receipt renders its saved price after catalog update', (
    tester,
  ) async {
    final fixture = await _HistoricalFixture.create();
    addTearDown(fixture.close);
    await fixture.applyRetailAndCostUpdates();
    final historical = await fixture.repository.loadTransactionById(
      fixture.oldTransaction.id,
    );
    final state = MikiezyState(
      products: await fixture.repository.loadProducts(),
      productCategories: [fixture.product.category],
      wallets: [fixture.wallet],
      categories: [fixture.category],
      transactions: [historical!],
      repository: fixture.repository,
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MikiezyScope(
        notifier: state,
        child: MaterialApp(home: ReceiptScreen(transaction: historical)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('2 gelas x Rp 10.000'), findsOneWidget);
    expect(find.textContaining('2 gelas x Rp 12.000'), findsNothing);
  });
}

(int, int) _metrics(List<TransactionRecord> transactions) {
  const service = BusinessMetricsService();
  final revenue = service.revenue(
    transactions: transactions,
    period: ReportPeriodType.allTime,
    now: DateTime(2030),
  );
  final profit = service.profit(
    transactions: transactions,
    period: ReportPeriodType.allTime,
    now: DateTime(2030),
  );
  return (revenue.moneyValue!, profit.moneyValue!);
}

class _HistoricalFixture {
  _HistoricalFixture._({
    required this.database,
    required this.dataSource,
    required this.repository,
    required this.product,
    required this.wallet,
    required this.category,
    required this.oldTransaction,
  });

  final AppDatabase database;
  final MikiezyLocalDataSource dataSource;
  final DriftMikiezyRepository repository;
  final Product product;
  final Wallet wallet;
  final LedgerCategory category;
  final TransactionRecord oldTransaction;

  static Future<_HistoricalFixture> create() async {
    final product = phase6cProduct(stock: 0, trackStock: false, minStock: 0);
    const wallet = Wallet(
      id: 'wallet-history',
      name: 'Dompet Utama',
      balance: 0,
      isPrimary: true,
    );
    const category = LedgerCategory(
      id: 'category-sales-history',
      name: 'Penjualan',
      direction: MoneyDirection.income,
      isSystem: true,
    );
    final oldTransaction = TransactionRecord(
      id: 'transaction-before-price-change',
      kind: TransactionKind.sale,
      createdAt: DateTime(2030, 1, 1, 9),
      walletId: wallet.id,
      walletName: wallet.name,
      categoryId: category.id,
      categoryName: category.name,
      lines: [
        TransactionLine(
          productId: product.id,
          productName: product.name,
          quantity: 2,
          unit: SaleUnit.gelas,
          unitPrice: 10000,
          costPrice: 6000,
          segment: PriceSegment.retail,
          unitMultiplier: 1,
        ),
      ],
      amount: 20000,
      discount: 0,
      note: 'snapshot sebelum perubahan harga',
      evidencePath: null,
      ocrSource: null,
      syncStatus: SyncStatus.localOnly,
    );
    final database = AppDatabase(NativeDatabase.memory());
    final dataSource = MikiezyLocalDataSource(database);
    final repository = DriftMikiezyRepository(dataSource);
    await dataSource.upsertProductCategory(product.category, 0);
    await dataSource.upsertProduct(product);
    await dataSource.upsertWallet(wallet);
    await dataSource.upsertTransactionCategory(category);
    await dataSource.upsertTransaction(oldTransaction);
    return _HistoricalFixture._(
      database: database,
      dataSource: dataSource,
      repository: repository,
      product: product,
      wallet: wallet,
      category: category,
      oldTransaction: oldTransaction,
    );
  }

  Future<void> applyRetailAndCostUpdates() async {
    final retailAction = await phase6cPriceAction(
      product: product,
      priceType: ProductPriceType.retail,
      newPrice: 12000,
    );
    await _commit(repository, retailAction);
    final retailUpdated = (await repository.loadProducts()).single;
    final costAction = await phase6cPriceAction(
      product: retailUpdated,
      priceType: ProductPriceType.cost,
      newPrice: 7000,
      now: DateTime(2030, 1, 1, 10, 0, 1),
    );
    await _commit(repository, costAction);
  }

  Future<void> close() => dataSource.close();
}

Future<void> _commit(
  DriftMikiezyRepository repository,
  VoiceActionDraft action,
) async {
  final payload = action.payload as UpdateProductPriceVoiceActionPayload;
  final result = await repository.updateProductPriceFromVoice(
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
  expect(result.status, VoicePriceUpdateCommitStatus.updated);
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
