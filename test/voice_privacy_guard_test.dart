import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/models/business_query_data.dart';
import 'package:mikiezy/domain/models/business_query_result.dart';
import 'package:mikiezy/domain/models/voice_privacy_policy.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/voice_business_query_handler.dart';
import 'package:mikiezy/services/voice/voice_command_router.dart';

void main() {
  const router = VoiceCommandRouter();
  const handler = VoiceBusinessQueryHandler();
  final now = DateTime(2026, 7, 13);

  test('privacy off allows the balance amount in display and TTS', () {
    final response = handler.handle(
      command: router.route('Berapa saldo dompet Tunai?'),
      data: _data(),
      now: now,
    );

    expect(response.displayText, contains('Rp 2.500.000'));
    expect(response.spokenText, contains('dua juta lima ratus ribu rupiah'));
  });

  test('privacy mode keeps UI value but removes it from TTS', () {
    final response = handler.handle(
      command: router.route('Berapa saldo dompet Tunai?'),
      data: _data(
        policy: const VoicePrivacyPolicy(hideFinancialValuesFromTts: true),
      ),
      now: now,
    );

    expect(response.displayText, contains('Rp 2.500.000'));
    expect(response.spokenText, isNot(contains('dua juta')));
    expect(response.spokenText, contains('tidak dibacakan'));
  });

  test('screen masking hides the nominal but preserves typed result', () {
    final response = handler.handle(
      command: router.route('Berapa saldo dompet Tunai?'),
      data: _data(
        policy: const VoicePrivacyPolicy(
          hideFinancialValuesFromTts: true,
          maskFinancialValuesOnScreen: true,
        ),
      ),
      now: now,
    );

    expect(response.displayText, contains('********'));
    expect(response.displayText, isNot(contains('2.500.000')));
    expect(response.spokenText, isNot(contains('dua juta')));
    expect(response.businessResult?.moneyValue, 2500000);
  });

  test('aggregate balance is protected by the same policy', () {
    final response = handler.handle(
      command: router.route('Berapa total saldo semua dompet?'),
      data: _data(
        policy: const VoicePrivacyPolicy(hideFinancialValuesFromTts: true),
      ),
      now: now,
    );

    expect(response.businessResult?.isAggregate, isTrue);
    expect(response.spokenText, contains('Total saldo seluruh dompet'));
    expect(response.spokenText, isNot(contains('dua juta')));
  });

  test('successful privacy query does not print the sensitive amount', () {
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) logs.add(message);
    };
    addTearDown(() => debugPrint = previousDebugPrint);

    handler.handle(
      command: router.route('Berapa saldo dompet Tunai?'),
      data: _data(
        policy: const VoicePrivacyPolicy(hideFinancialValuesFromTts: true),
      ),
      now: now,
    );

    expect(logs.join(' '), isNot(contains('2500000')));
    expect(logs.join(' '), isNot(contains('2.500.000')));
  });

  test(
    'source failure remains failure and is not presented as zero balance',
    () {
      final response = handler.handle(
        command: router.route('Berapa saldo dompet Tunai?'),
        data: BusinessQueryData(
          sourceError: 'database unavailable',
          privacyPolicy: const VoicePrivacyPolicy(
            hideFinancialValuesFromTts: true,
          ),
        ),
        now: now,
      );

      expect(response.businessResult?.status, BusinessQueryStatus.failure);
      expect(response.businessResult?.moneyValue, isNull);
      expect(response.displayText, isNot(contains('Rp0')));
    },
  );
}

BusinessQueryData _data({
  VoicePrivacyPolicy policy = const VoicePrivacyPolicy(),
}) {
  return BusinessQueryData(
    wallets: const [
      Wallet(id: 'cash', name: 'Tunai', balance: 2500000, isPrimary: true),
      Wallet(id: 'bank', name: 'Bank', balance: 500000, isPrimary: false),
    ],
    privacyPolicy: policy,
  );
}
