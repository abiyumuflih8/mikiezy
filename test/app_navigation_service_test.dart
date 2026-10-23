import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/services/navigation/app_navigation_service.dart';
import 'package:mikiezy/services/voice/voice_command.dart';
import 'package:mikiezy/services/voice/voice_navigation_handler.dart';

void main() {
  testWidgets('service navigates once and detects the current target', (
    tester,
  ) async {
    final key = GlobalKey<NavigatorState>();
    final service = _service(key);
    await tester.pumpWidget(_app(key, service));

    final first = await service.navigate(VoiceNavigationTarget.products);
    await tester.pumpAndSettle();
    final duplicate = await service.navigate(VoiceNavigationTarget.products);

    expect(first.status, VoiceNavigationStatus.navigated);
    expect(duplicate.status, VoiceNavigationStatus.alreadyThere);
    expect(find.text('products'), findsOneWidget);
  });

  testWidgets('concurrent duplicate target creates only one navigation', (
    tester,
  ) async {
    final key = GlobalKey<NavigatorState>();
    final service = _service(key);
    await tester.pumpWidget(_app(key, service));

    final outcomes = await Future.wait([
      service.navigate(VoiceNavigationTarget.products),
      service.navigate(VoiceNavigationTarget.products),
    ]);
    await tester.pumpAndSettle();

    expect(
      outcomes.where(
        (outcome) => outcome.status == VoiceNavigationStatus.navigated,
      ),
      hasLength(1),
    );
    expect(
      outcomes.where(
        (outcome) => outcome.status == VoiceNavigationStatus.alreadyThere,
      ),
      hasLength(1),
    );
    expect(find.text('products'), findsOneWidget);
  });

  testWidgets('preview route blocks voice navigation', (tester) async {
    final key = GlobalKey<NavigatorState>();
    final service = _service(key);
    await tester.pumpWidget(_app(key, service));
    key.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRouteNames.previewTransaction),
        builder: (_) => const Text('preview'),
      ),
    );
    await tester.pumpAndSettle();

    final outcome = await service.navigate(VoiceNavigationTarget.settings);

    expect(outcome.status, VoiceNavigationStatus.blocked);
    expect(find.text('preview'), findsOneWidget);
  });

  testWidgets('back pops voice entry when navigator can pop', (tester) async {
    final key = GlobalKey<NavigatorState>();
    final service = _service(key);
    await tester.pumpWidget(_app(key, service));
    key.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRouteNames.voiceEntry),
        builder: (_) => const Text('voice'),
      ),
    );
    await tester.pumpAndSettle();

    final outcome = await service.navigate(VoiceNavigationTarget.back);
    await tester.pumpAndSettle();

    expect(outcome.status, VoiceNavigationStatus.navigated);
    expect(outcome.target, VoiceNavigationTarget.back);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('background and disposed navigator are rejected safely', (
    tester,
  ) async {
    final key = GlobalKey<NavigatorState>();
    final service = _service(key);
    await tester.pumpWidget(_app(key, service));
    service.setAppForeground(false);

    final background = await service.navigate(VoiceNavigationTarget.analytics);
    expect(background.status, VoiceNavigationStatus.notForeground);

    service.setAppForeground(true);
    await tester.pumpWidget(const SizedBox.shrink());
    final disposed = await service.navigate(VoiceNavigationTarget.analytics);
    expect(disposed.status, VoiceNavigationStatus.unavailable);
  });
}

AppNavigationService _service(GlobalKey<NavigatorState> key) {
  return AppNavigationService(
    navigatorKey: key,
    pageBuilder: (target) => Scaffold(body: Text(target.name)),
  );
}

Widget _app(GlobalKey<NavigatorState> key, AppNavigationService service) {
  return MaterialApp(
    navigatorKey: key,
    navigatorObservers: [service.observer],
    home: const Scaffold(body: Text('home')),
  );
}
