import 'package:flutter/widgets.dart';

import 'app_lock_controller.dart';

class AppLockScope extends InheritedNotifier<AppLockController> {
  const AppLockScope({
    super.key,
    required AppLockController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLockController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLockScope>();
    assert(scope != null, 'AppLockScope is missing above this widget.');
    return scope!.notifier!;
  }

  static AppLockController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppLockScope>()?.notifier;
  }
}
