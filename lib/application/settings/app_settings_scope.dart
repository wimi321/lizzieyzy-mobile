import 'package:flutter/widgets.dart';

import 'app_settings_controller.dart';

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    required AppSettingsController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    if (scope?.notifier == null) {
      throw StateError('AppSettingsScope is missing above this context.');
    }
    return scope!.notifier!;
  }

  static AppSettingsController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()?.notifier;
}
