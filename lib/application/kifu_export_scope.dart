import 'package:flutter/widgets.dart';

import 'kifu_export_service.dart';

class KifuExportScope extends InheritedWidget {
  const KifuExportScope({
    required this.service,
    required super.child,
    super.key,
  });

  final KifuExportService service;

  static KifuExportService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<KifuExportScope>();
    if (scope == null) {
      throw StateError('KifuExportScope is missing above this context.');
    }
    return scope.service;
  }

  static KifuExportService? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KifuExportScope>()?.service;

  @override
  bool updateShouldNotify(KifuExportScope oldWidget) =>
      oldWidget.service != service;
}
