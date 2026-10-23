import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_command_executor.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';
import 'package:mikiezy/services/voice/voice_conversation_context.dart';
import 'package:mikiezy/services/voice/voice_response_builder.dart';
import 'package:mikiezy/services/voice_assistant_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const router = VoiceCommandRouter();

  group('VoiceCommandRouter navigation', () {
    final cases = <String, (VoiceCommandIntent, VoiceNavigationTarget)>{
      'Buka dashboard': (
        VoiceCommandIntent.navigateDashboard,
        VoiceNavigationTarget.dashboard,
      ),
      'Masuk ke halaman analitik': (
        VoiceCommandIntent.navigateAnalytics,
        VoiceNavigationTarget.analytics,
      ),
      'Tampilkan laporan': (
        VoiceCommandIntent.navigateReports,
        VoiceNavigationTarget.reports,
      ),
      'Saya mau lihat produk': (
        VoiceCommandIntent.navigateProducts,
        VoiceNavigationTarget.products,
      ),
      'Buka edit profil': (
        VoiceCommandIntent.navigateEditProfile,
        VoiceNavigationTarget.editProfile,
      ),
      'Kembali ke halaman sebelumnya': (
        VoiceCommandIntent.goBack,
        VoiceNavigationTarget.back,
      ),
      'Kembali ke beranda': (
        VoiceCommandIntent.navigateDashboard,
        VoiceNavigationTarget.dashboard,
      ),
    };

    for (final entry in cases.entries) {
      test('classifies "${entry.key}"', () {
        final command = router.route(entry.key);

        expect(command.intent, entry.value.$1);
        expect(command.entities.navigationTarget, entry.value.$2);
        expect(command.confidence, greaterThanOrEqualTo(0.9));
      });
    }
  });

  group('VoiceCommandRouter business queries', () {
    test('extracts a period from a profit query', () {
      final command = router.route('Berapa keuntungan hari ini?');

      expect(command.intent, VoiceCommandIntent.queryProfit);
      expect(command.entities.period, VoiceCommandPeriod.today);
    });

    test('classifies revenue and transaction count separately', () {
      final revenue = router.route('Berapa total penjualan bulan ini?');
      final count = router.route('Berapa transaksi bulan ini?');

      expect(revenue.intent, VoiceCommandIntent.querySales);
      expect(revenue.entities.period, VoiceCommandPeriod.thisMonth);
      expect(count.intent, VoiceCommandIntent.queryTransactionCount);
      expect(count.entities.period, VoiceCommandPeriod.thisMonth);
    });

    test('recognizes natural low-stock wording', () {
      final command = router.route('Barang apa yang stoknya hampir habis?');

      expect(command.intent, VoiceCommandIntent.queryLowStock);
    });

    test('extracts product name from a stock query', () {
      final command = router.route('Stok kopi susu tinggal berapa?');

      expect(command.intent, VoiceCommandIntent.queryProductStock);
      expect(command.entities.productName, 'kopi susu');
    });

    test('extracts wallet name from a balance query', () {
      final command = router.route('Berapa saldo dompet BCA sekarang?');

      expect(command.intent, VoiceCommandIntent.queryWalletBalance);
      expect(command.entities.walletName, 'bca');
    });

    test('distinguishes income from revenue', () {
      expect(
        router.route('Berapa omzet minggu ini?').intent,
        VoiceCommandIntent.queryRevenue,
      );
      expect(
        router.route('Berapa pemasukan minggu ini?').intent,
        VoiceCommandIntent.queryIncome,
      );
    });

    test('recognizes natural profit and sales questions', () {
      final profit = router.route('Berapa laba kemarin?');
      final sales = router.route('Berapa penjualan bulan lalu?');

      expect(profit.intent, VoiceCommandIntent.queryProfit);
      expect(profit.entities.period, VoiceCommandPeriod.yesterday);
      expect(sales.intent, VoiceCommandIntent.querySales);
      expect(sales.entities.period, VoiceCommandPeriod.lastMonth);
    });

    test('extracts last-week and all-time periods', () {
      expect(
        router.route('Berapa laba minggu lalu?').entities.period,
        VoiceCommandPeriod.lastWeek,
      );
      expect(
        router.route('Berapa omzet sepanjang waktu?').entities.period,
        VoiceCommandPeriod.allTime,
      );
    });

    test('extracts transaction filter, top N, and aggregate wallet', () {
      final count = router.route('Berapa transaksi pengeluaran minggu ini?');
      final top = router.route('Sebutkan 3 produk terlaris bulan ini');
      final wallet = router.route('Berapa total saldo semua dompet?');

      expect(count.entities.transactionFilter, VoiceTransactionFilter.expense);
      expect(top.entities.resultLimit, 3);
      expect(wallet.entities.allWallets, isTrue);
    });

    test('routes latest transaction before navigation', () {
      final command = router.route('Tampilkan transaksi terbaru');

      expect(command.intent, VoiceCommandIntent.queryLatestTransaction);
    });
  });

  group('VoiceCommandRouter data-changing intents', () {
    test('extracts a product name without swallowing its fields', () {
      final command = router.route(
        'Tambah produk kopi susu harga jual 10000 modal 6000 stok 20 gelas',
      );

      expect(command.intent, VoiceCommandIntent.createProduct);
      expect(command.entities.productName, 'kopi susu');
      expect(command.intent.requiresConfirmation, isTrue);
    });

    test(
      'keeps transaction classification separate from transaction parsing',
      () {
        expect(
          router.route('jual kopi susu 3 gelas').intent,
          VoiceCommandIntent.createSale,
        );
        expect(
          router.route('catat pengeluaran listrik 200000').intent,
          VoiceCommandIntent.createExpense,
        );
        expect(
          router.route('pemasukan modal 500000').intent,
          VoiceCommandIntent.createIncome,
        );
      },
    );

    test('does not guess an intent from an unrelated phrase', () {
      final command = router.route('tolong bantu saya');

      expect(command.intent, VoiceCommandIntent.unknown);
      expect(command.confidence, lessThan(0.5));
    });
  });

  group('VoiceConversationSession', () {
    test('expires unfinished context and never carries it indefinitely', () {
      final now = DateTime(2026, 7, 13, 10);
      final session = VoiceConversationSession(
        timeout: const Duration(seconds: 30),
      );
      final command = router.route('Tambah produk kopi susu');

      session.start(command, missingFields: const ['salePrice'], now: now);

      expect(
        session.current(now: now.add(const Duration(seconds: 29))),
        isNotNull,
      );
      expect(
        session.current(now: now.add(const Duration(seconds: 30))),
        isNull,
      );
    });

    test('merges follow-up entities and waits for confirmation explicitly', () {
      final now = DateTime(2026, 7, 13, 10);
      final session = VoiceConversationSession();
      final command = router.route('Tambah produk kopi susu');

      session.start(
        command,
        missingFields: const ['salePrice', 'stock'],
        now: now,
      );
      session.update(
        entities: const VoiceCommandEntities(salePrice: 10000),
        missingFields: const ['stock'],
        now: now.add(const Duration(seconds: 5)),
      );
      final context = session.waitForConfirmation(
        now: now.add(const Duration(seconds: 10)),
      );

      expect(context?.entities.productName, 'kopi susu');
      expect(context?.entities.salePrice, 10000);
      expect(context?.missingFields, ['stock']);
      expect(context?.stage, VoiceConversationStage.awaitingConfirmation);
    });
  });

  group('VoiceCommandExecutor', () {
    test('does not execute an intent without a registered handler', () async {
      final executor = VoiceCommandExecutor();
      final result = await executor.execute(router.route('Buka analitik'));

      expect(result.handled, isFalse);
      expect(result.response.displayText, contains('belum aktif'));
    });

    test('dispatches only to the handler registered for the intent', () async {
      var calls = 0;
      final executor = VoiceCommandExecutor(
        handlers: {
          VoiceCommandIntent.navigateAnalytics: (command, context) {
            calls += 1;
            return const VoiceResponseBuilder().information(
              'Membuka halaman analitik.',
            );
          },
        },
      );

      final result = await executor.execute(router.route('Buka analitik'));

      expect(calls, 1);
      expect(result.handled, isTrue);
      expect(result.response.displayText, 'Membuka halaman analitik.');
    });

    test('refuses compound commands before calling any handler', () async {
      var calls = 0;
      final executor = VoiceCommandExecutor(
        handlers: {
          VoiceCommandIntent.navigateAnalytics: (command, context) {
            calls += 1;
            return const VoiceResponseBuilder().information(
              'Membuka halaman analitik.',
            );
          },
        },
      );
      final command = router.route(
        'Buka analitik lalu catat pengeluaran listrik 100000',
      );

      final result = await executor.execute(command);

      expect(command.hasMultipleIntents, isTrue);
      expect(calls, 0);
      expect(result.handled, isFalse);
      expect(result.response.kind, VoiceResponseKind.question);
    });

    test('requires explicit confirmation for data-changing handlers', () async {
      var calls = 0;
      final executor = VoiceCommandExecutor(
        handlers: {
          VoiceCommandIntent.createProduct: (command, context) {
            calls += 1;
            return const VoiceResponseBuilder().information('Produk disimpan.');
          },
        },
      );
      final command = router.route('Tambah produk kopi susu');

      final blocked = await executor.execute(command);
      final confirmed = await executor.execute(command, confirmed: true);

      expect(blocked.handled, isFalse);
      expect(blocked.response.kind, VoiceResponseKind.confirmation);
      expect(confirmed.handled, isTrue);
      expect(calls, 1);
    });
  });

  test(
    'VoiceAssistantController records classification without changing parser flow',
    () async {
      final controller = VoiceAssistantController();
      addTearDown(controller.dispose);
      controller.setTranscript('jual kopi susu 3 gelas harga 10000');

      final result = await controller.processCurrentTranscript(
        speakResult: false,
      );

      expect(result, isNotNull);
      expect(controller.latestCommand?.intent, VoiceCommandIntent.createSale);
      expect(result?.draft.amount, 30000);
    },
  );
}
