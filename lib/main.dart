import 'dart:async';

import 'package:flutter/material.dart';

import 'core/app_scroll_behavior.dart';
import 'data/repositories/mikiezy_repository.dart';
import 'models/mikiezy_models.dart';
import 'screens/dashboard_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/preview_transaction_screen.dart';
import 'screens/products_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/voice_entry_screen.dart';
import 'services/voice/voice_entry_launch_source.dart';
import 'services/voice/voice_assistant_manager.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MikiezyApp());
}

class MikiezyApp extends StatefulWidget {
  const MikiezyApp({
    super.key,
    this.initialHome,
    this.repository,
    this.usePersistentStorage = true,
  });

  final Widget? initialHome;
  final MikiezyRepository? repository;
  final bool usePersistentStorage;

  @override
  State<MikiezyApp> createState() => _MikiezyAppState();
}

class _MikiezyAppState extends State<MikiezyApp> with WidgetsBindingObserver {
  late final MikiezyState state;
  late final MikiezyRepository repository;
  late final VoiceAssistantManager voiceAssistant;
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    repository =
        widget.repository ??
        MikiezyRepository.open(persistent: widget.usePersistentStorage);
    state = MikiezyState.seeded(repository: repository);
    voiceAssistant = VoiceAssistantManager(
      state: state,
      onPreviewRequested: _openVoicePreview,
      onNavigationRequested: _openVoiceRoute,
      onVoiceEntryRequested: _openVoiceEntry,
    );
    unawaited(state.hydrateFromLocal());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    voiceAssistant.dispose();
    state.dispose();
    unawaited(repository.close());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    voiceAssistant.setAppForeground(
      lifecycleState == AppLifecycleState.resumed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MikiezyScope(
      notifier: state,
      child: VoiceAssistantScope(
        notifier: voiceAssistant,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Mikiezy',
          theme: buildMikiezyTheme(),
          darkTheme: buildMikiezyTheme(brightness: Brightness.dark),
          themeMode: ThemeMode.system,
          scrollBehavior: const MikiezyScrollBehavior(),
          home: widget.initialHome ?? const SplashScreen(),
        ),
      ),
    );
  }

  void _openVoicePreview(TransactionDraft draft) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    unawaited(
      navigator.push(
        MaterialPageRoute(
          builder: (_) => PreviewTransactionScreen(initialDraft: draft),
        ),
      ),
    );
  }

  void _openVoiceEntry(
    VoiceEntryLaunchSource launchSource, {
    String? initialTranscript,
  }) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    unawaited(
      navigator
          .push(
            MaterialPageRoute(
              builder: (_) => VoiceEntryScreen(
                autoStart: true,
                launchSource: launchSource,
                initialWakeWordDetected:
                    launchSource == VoiceEntryLaunchSource.wakeWord,
                initialTranscript: initialTranscript,
              ),
            ),
          )
          .whenComplete(() {
            if (!mounted) return;
            unawaited(voiceAssistant.resumeAfterManualSession());
          }),
    );
  }

  void _openVoiceRoute(String route) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    final page = switch (route) {
      'transactions' => const TransactionsScreen(),
      'analytics' => const ReportsScreen(),
      'settings' => const SettingsScreen(),
      'products' => const ProductsScreen(),
      'finance' => const FinanceScreen(),
      _ => const DashboardScreen(),
    };
    unawaited(
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => page)),
    );
  }
}
