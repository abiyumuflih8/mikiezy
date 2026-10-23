import 'package:flutter/widgets.dart';

import 'global_voice_controller.dart';

class GlobalVoiceScope extends InheritedNotifier<GlobalVoiceController> {
  const GlobalVoiceScope({
    super.key,
    required GlobalVoiceController controller,
    required super.child,
  }) : super(notifier: controller);

  static GlobalVoiceController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<GlobalVoiceScope>();
    assert(scope != null, 'GlobalVoiceScope is missing above this widget.');
    return scope!.notifier!;
  }

  static GlobalVoiceController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GlobalVoiceScope>()
        ?.notifier;
  }
}
