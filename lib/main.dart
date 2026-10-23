import 'dart:async';

import 'package:flutter/material.dart';

import 'core/app_scroll_behavior.dart';
import 'data/repositories/mikiezy_repository.dart';
import 'data/repositories/repository_voice_action_audit_store.dart';
import 'models/mikiezy_models.dart';
import 'screens/dashboard_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/preview_transaction_screen.dart';
import 'screens/products_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/transactions_screen.dart';
import 'services/navigation/app_navigation_service.dart';
import 'services/security/app_lock_controller.dart';
import 'services/security/app_lock_scope.dart';
import 'services/security/biometric_authenticator.dart';
import 'services/security/secure_pin_store.dart';
import 'services/voice/global_voice_controller.dart';
import 'services/voice/global_voice_engine.dart';
import 'services/voice/global_voice_scope.dart';
import 'services/voice/create_product_voice_action_executor.dart';
import 'services/voice/increment_stock_voice_action_executor.dart';
import 'services/voice/update_product_price_voice_action_executor.dart';
import 'services/voice/voice_command.dart';
import 'services/voice/voice_action_coordinator.dart';
import 'services/voice/voice_entry_launch_source.dart';
import 'services/voice/voice_assistant_manager.dart';
import 'services/voice/voice_navigation_handler.dart';
import 'services/voice/voice_mutation_preview_handler.dart';
import 'services/voice/voice_parse_context.dart';
import 'services/voice_assistant_controller.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/app_lock_gate.dart';
import 'widgets/voice_overlay_host.dart';

void main() {
  runApp(const MikiezyApp());
}

class MikiezyApp extends StatefulWidget {
  const MikiezyApp({
    super.key,
    this.initialHome,
    this.repository,
    this.usePersistentStorage = true,
    this.appLockController,
  });

  final Widget? initialHome;
  final MikiezyRepository? repository;
  final bool usePersistentStorage;
  final AppLockController? appLockController;

  @override
  State<MikiezyApp> createState() => _MikiezyAppState();
}

class _MikiezyAppState extends State<MikiezyApp> with WidgetsBindingObserver {
  late final MikiezyState state;
  late final MikiezyRepository repository;
  late final VoiceAssistantManager voiceAssistant;
  late final AppNavigationService navigationService;
  late final AppLockController appLockController;
  late final VoiceAssistantController voiceSessionController;
  late final GlobalVoiceController globalVoiceController;
  late final bool _ownsAppLockController;
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    repository =
        widget.repository ??
        MikiezyRepository.open(persistent: widget.usePersistentStorage);
    state = MikiezyState.seeded(repository: repository);
    _ownsAppLockController = widget.appLockController == null;
    appLockController =
        widget.appLockController ??
        AppLockController(
          securePinStore: widget.usePersistentStorage
              ? FlutterSecurePinStore()
              : MemorySecurePinStore(),
          biometricAuthenticator: widget.usePersistentStorage
              ? null
              : const UnavailableBiometricAuthenticator(),
          initializeAsUnlocked: !widget.usePersistentStorage,
        );
    navigationService = AppNavigationService(
      navigatorKey: navigatorKey,
      pageBuilder: _voiceNavigationPage,
      onVoiceRequested: () => globalVoiceController.startPushToTalk(),
    );
    voiceAssistant = VoiceAssistantManager(
      state: state,
      onPreviewRequested: _openVoicePreview,
      onVoiceEntryRequested: _openVoiceEntry,
      navigationHandler: VoiceNavigationHandler(navigation: navigationService),
      isAppLocked: () => appLockController.isLocked,
    );
    final mutationPreviewHandler = VoiceMutationPreviewHandler(
      VoiceActionCoordinator(
        RepositoryVoiceActionAuditStore(repository),
        featureFlags: const VoiceMutationFeatureFlags(
          enableVoiceCreateProduct: true,
          enableVoiceStockIncrement: true,
          enableVoicePriceUpdate: true,
        ),
        executors: [
          CreateProductVoiceActionExecutor(
            repository,
            onCommitted: () =>
                state.refreshProducts(showLoading: false, rethrowErrors: true),
          ),
          IncrementStockVoiceActionExecutor(
            repository,
            onCommitted: () =>
                state.refreshProducts(showLoading: false, rethrowErrors: true),
          ),
          UpdateProductPriceVoiceActionExecutor(
            repository,
            onCommitted: () =>
                state.refreshProducts(showLoading: false, rethrowErrors: true),
          ),
        ],
      ),
      () => state.products,
      aliasesProvider: () => state.voiceProductAliases,
      unitAliasesProvider: () => state.voiceUnitAliases,
      refreshProducts: () =>
          state.refreshProducts(showLoading: false, rethrowErrors: true),
      isAppLocked: () => appLockController.isLocked,
    );
    voiceSessionController = VoiceAssistantController(
      navigationHandler: VoiceNavigationHandler(navigation: navigationService),
      mutationPreviewHandler: mutationPreviewHandler,
      businessDataProvider: () =>
          state.businessQueryDataFor(isAppLocked: appLockController.isLocked),
    );
    globalVoiceController = GlobalVoiceController(
      sessionEngine: VoiceAssistantGlobalEngine(voiceSessionController),
      buildParseContext: _voiceParseContext,
      previewCallback: _openVoicePreviewRoute,
      pauseWakeWordSession: voiceAssistant.pauseForManualSession,
      resumeWakeWordSession: voiceAssistant.resumeAfterManualSession,
      silenceTimeoutProvider: () =>
          Duration(seconds: state.silentTimeoutSeconds),
      isAppLocked: () => appLockController.isLocked,
    );
    appLockController.addListener(_handleAppLockChanged);
    navigationService.observer.addListener(_handleRouteChanged);
    unawaited(_initializeApplication());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    navigationService.observer.removeListener(_handleRouteChanged);
    globalVoiceController.dispose();
    voiceAssistant.dispose();
    appLockController.removeListener(_handleAppLockChanged);
    if (_ownsAppLockController) appLockController.dispose();
    state.dispose();
    unawaited(repository.close());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    appLockController.handleLifecycleState(lifecycleState);
    globalVoiceController.handleLifecycleState(lifecycleState);
    final isForeground = lifecycleState == AppLifecycleState.resumed;
    navigationService.setAppForeground(isForeground);
    voiceAssistant.setAppForeground(isForeground);
  }

  @override
  Widget build(BuildContext context) {
    return MikiezyScope(
      notifier: state,
      child: AppNavigationScope(
        service: navigationService,
        child: AppLockScope(
          controller: appLockController,
          child: GlobalVoiceScope(
            controller: globalVoiceController,
            child: VoiceAssistantScope(
              notifier: voiceAssistant,
              child: MaterialApp(
                navigatorKey: navigatorKey,
                navigatorObservers: [navigationService.observer],
                debugShowCheckedModeBanner: false,
                title: 'Mikiezy',
                theme: buildMikiezyTheme(),
                darkTheme: buildMikiezyTheme(brightness: Brightness.dark),
                themeMode: ThemeMode.system,
                scrollBehavior: const MikiezyScrollBehavior(),
                home: widget.initialHome ?? const SplashScreen(),
                builder: (context, child) => AppLockGate(
                  controller: appLockController,
                  child: VoiceOverlayHost(
                    controller: globalVoiceController,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _initializeApplication() async {
    await Future.wait([
      state.hydrateFromLocal(),
      appLockController.initialize(),
    ]);
    if (!mounted) return;
    if (state.pinEnabled != appLockController.isPinConfigured) {
      state.togglePin(appLockController.isPinConfigured);
    }
    if (state.biometricEnabled != appLockController.biometricEnabled) {
      state.toggleBiometric(appLockController.biometricEnabled);
    }
    _handleAppLockChanged();
  }

  void _handleAppLockChanged() {
    voiceAssistant.setAppSecurityLocked(appLockController.isLocked);
    globalVoiceController.setAppLocked(appLockController.isLocked);
  }

  void _handleRouteChanged() {
    globalVoiceController.setSensitiveSurfaceVisible(
      navigationService.hasProtectedRoute,
    );
  }

  void _openVoicePreview(TransactionDraft draft) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    unawaited(
      navigator.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: AppRouteNames.previewTransaction),
          builder: (_) => PreviewTransactionScreen(initialDraft: draft),
        ),
      ),
    );
  }

  void _openVoiceEntry(
    VoiceEntryLaunchSource launchSource, {
    String? initialTranscript,
  }) {
    unawaited(
      launchSource == VoiceEntryLaunchSource.wakeWord
          ? globalVoiceController.startFromWakeWord(initialTranscript)
          : globalVoiceController.startPushToTalk(),
    );
  }

  Future<void> _openVoicePreviewRoute(TransactionDraft draft) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    await navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRouteNames.previewTransaction),
        builder: (_) => PreviewTransactionScreen(initialDraft: draft),
      ),
    );
  }

  VoiceParseContext _voiceParseContext() {
    return VoiceParseContext(
      products: state.products,
      wallets: state.wallets,
      categories: state.categories,
      productAliases: state.voiceProductAliases,
      unitAliases: state.voiceUnitAliases,
      defaultWalletName: _defaultWalletName(),
    );
  }

  String? _defaultWalletName() {
    for (final wallet in state.wallets) {
      if (wallet.isPrimary) return wallet.name;
    }
    return state.wallets.isEmpty ? null : state.wallets.first.name;
  }

  Widget? _voiceNavigationPage(VoiceNavigationTarget target) {
    return switch (target) {
      VoiceNavigationTarget.dashboard => const DashboardScreen(),
      VoiceNavigationTarget.transactions => const TransactionsScreen(),
      VoiceNavigationTarget.products => const ProductsScreen(),
      VoiceNavigationTarget.reports ||
      VoiceNavigationTarget.analytics => const ReportsScreen(),
      VoiceNavigationTarget.wallets ||
      VoiceNavigationTarget.categories => const FinanceScreen(),
      VoiceNavigationTarget.settings => const SettingsScreen(),
      VoiceNavigationTarget.editProfile => const EditProfileScreen(),
      VoiceNavigationTarget.voiceEntry => null,
      VoiceNavigationTarget.back => null,
    };
  }
}
