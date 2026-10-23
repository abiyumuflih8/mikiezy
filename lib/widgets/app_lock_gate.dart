import 'package:flutter/material.dart';

import '../screens/app_lock_screen.dart';
import '../services/security/app_lock_controller.dart';
import '../theme/app_theme.dart';

class AppLockGate extends StatelessWidget {
  const AppLockGate({super.key, required this.controller, required this.child});

  final AppLockController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, navigator) {
        final protected = controller.initialized && !controller.isLocked;
        return Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: !protected,
              child: TickerMode(enabled: protected, child: navigator!),
            ),
            if (!controller.initialized)
              const ColoredBox(
                color: AppColors.bg,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.isLocked)
              AppLockScreen(controller: controller),
          ],
        );
      },
    );
  }
}
