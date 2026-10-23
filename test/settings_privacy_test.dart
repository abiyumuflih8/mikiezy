import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/screens/settings_screen.dart';
import 'package:mikiezy/state/app_state.dart';

void main() {
  testWidgets('privacy switches update state conservatively', (tester) async {
    final state = MikiezyState.seeded();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MikiezyScope(
        notifier: state,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    final privacyLabel = find.text('Lindungi data keuangan dari voice');
    await tester.scrollUntilVisible(
      privacyLabel,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(privacyLabel);
    await tester.pump();
    expect(state.voiceFinancialPrivacyEnabled, isTrue);

    final maskLabel = find.text('Samarkan saldo di layar');
    await tester.tap(maskLabel);
    await tester.pump();
    expect(state.maskVoiceFinancialValues, isTrue);

    await tester.tap(privacyLabel);
    await tester.pump();
    expect(state.voiceFinancialPrivacyEnabled, isFalse);
    expect(state.maskVoiceFinancialValues, isFalse);
  });
}
