import 'dart:async';

import 'package:flutter/material.dart';

import '../diagnostics/safe_diagnostics.dart';
import '../voice/voice_command.dart';
import '../voice/voice_navigation_handler.dart';

typedef VoiceNavigationPageBuilder =
    Widget? Function(VoiceNavigationTarget target);

abstract final class AppRouteNames {
  static const previewTransaction = 'preview-transaction';
  static const voiceEntry = 'voice-entry';

  static String forTarget(VoiceNavigationTarget target) {
    return 'voice-${_canonical(target).name}';
  }

  static VoiceNavigationTarget? targetFor(String? name) {
    if (name == null || !name.startsWith('voice-')) return null;
    final value = name.substring('voice-'.length);
    for (final target in VoiceNavigationTarget.values) {
      if (_canonical(target).name == value) return _canonical(target);
    }
    return null;
  }

  static VoiceNavigationTarget _canonical(VoiceNavigationTarget target) {
    return switch (target) {
      VoiceNavigationTarget.reports => VoiceNavigationTarget.analytics,
      VoiceNavigationTarget.categories => VoiceNavigationTarget.wallets,
      _ => target,
    };
  }
}

class AppNavigationScope extends InheritedWidget {
  const AppNavigationScope({
    super.key,
    required this.service,
    required super.child,
  });

  final AppNavigationService service;

  static AppNavigationService? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppNavigationScope>()
        ?.service;
  }

  @override
  bool updateShouldNotify(AppNavigationScope oldWidget) =>
      !identical(service, oldWidget.service);
}

class AppNavigationService implements VoiceNavigationPort {
  AppNavigationService({
    required this.navigatorKey,
    required this.pageBuilder,
    this.onVoiceRequested,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final VoiceNavigationPageBuilder pageBuilder;
  final Future<void> Function()? onVoiceRequested;
  final AppNavigationObserver observer = AppNavigationObserver();
  bool _appForeground = true;

  void setAppForeground(bool value) {
    _appForeground = value;
  }

  @override
  Future<VoiceNavigationOutcome> navigate(VoiceNavigationTarget target) async {
    SafeDiagnostics.voiceEvent(
      'voice_navigation_requested',
      route: target.name,
    );
    if (!_appForeground) {
      return _outcome(VoiceNavigationStatus.notForeground, target);
    }
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return _outcome(VoiceNavigationStatus.unavailable, target);
    }
    if (_hasProtectedRoute()) {
      return _outcome(VoiceNavigationStatus.blocked, target);
    }
    if (target == VoiceNavigationTarget.back) {
      if (navigator.canPop()) {
        navigator.pop();
        return _outcome(VoiceNavigationStatus.navigated, target);
      }
      target = VoiceNavigationTarget.dashboard;
    }
    if (target == VoiceNavigationTarget.voiceEntry &&
        onVoiceRequested != null) {
      await onVoiceRequested!();
      return _outcome(
        VoiceNavigationStatus.navigated,
        VoiceNavigationTarget.voiceEntry,
      );
    }

    final canonicalTarget = _canonical(target);
    if (_currentPageTarget() == canonicalTarget ||
        (canonicalTarget == VoiceNavigationTarget.voiceEntry &&
            observer.topRouteName == AppRouteNames.voiceEntry)) {
      return _outcome(VoiceNavigationStatus.alreadyThere, canonicalTarget);
    }
    final page = pageBuilder(canonicalTarget);
    if (page == null) {
      return _outcome(VoiceNavigationStatus.unavailable, canonicalTarget);
    }
    unawaited(
      navigator.pushReplacement(
        MaterialPageRoute<void>(
          settings: RouteSettings(
            name: AppRouteNames.forTarget(canonicalTarget),
          ),
          builder: (_) => page,
        ),
      ),
    );
    return _outcome(VoiceNavigationStatus.navigated, canonicalTarget);
  }

  VoiceNavigationOutcome _outcome(
    VoiceNavigationStatus status,
    VoiceNavigationTarget target,
  ) {
    SafeDiagnostics.voiceEvent(
      'voice_navigation_result',
      route: target.name,
      status: status.name,
    );
    return VoiceNavigationOutcome(status: status, target: target);
  }

  VoiceNavigationTarget? _currentPageTarget() {
    for (final route in observer.routes.reversed) {
      if (route.settings.name == AppRouteNames.voiceEntry) continue;
      final target = AppRouteNames.targetFor(route.settings.name);
      if (target != null) return target;
    }
    return null;
  }

  bool _hasProtectedRoute() {
    for (final route in observer.routes.reversed.take(3)) {
      if (route.settings.name == AppRouteNames.voiceEntry) continue;
      if (route.settings.name == AppRouteNames.previewTransaction ||
          route.settings.name ==
              AppRouteNames.forTarget(VoiceNavigationTarget.editProfile) ||
          route is PopupRoute<dynamic>) {
        return true;
      }
      break;
    }
    return false;
  }

  bool get hasProtectedRoute => _hasProtectedRoute();

  VoiceNavigationTarget _canonical(VoiceNavigationTarget target) {
    return switch (target) {
      VoiceNavigationTarget.reports => VoiceNavigationTarget.analytics,
      VoiceNavigationTarget.categories => VoiceNavigationTarget.wallets,
      _ => target,
    };
  }
}

class AppNavigationObserver extends NavigatorObserver with ChangeNotifier {
  final List<Route<dynamic>> _routes = [];

  List<Route<dynamic>> get routes => List.unmodifiable(_routes);
  String? get topRouteName =>
      _routes.isEmpty ? null : _routes.last.settings.name;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    notifyListeners();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    notifyListeners();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    notifyListeners();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index == -1) {
      if (newRoute != null) _routes.add(newRoute);
      notifyListeners();
      return;
    }
    if (newRoute == null) {
      _routes.removeAt(index);
    } else {
      _routes[index] = newRoute;
    }
    notifyListeners();
  }
}
