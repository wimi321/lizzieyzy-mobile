import 'package:flutter/widgets.dart';

import 'analysis_coordinator.dart';

/// Exposes the app-owned analysis coordinator without transferring ownership
/// to individual routes. Analysis therefore continues when a review route is
/// covered or popped, until the user explicitly cancels it.
class AnalysisCoordinatorScope extends InheritedNotifier<AnalysisCoordinator> {
  const AnalysisCoordinatorScope({
    required AnalysisCoordinator coordinator,
    required super.child,
    super.key,
  }) : super(notifier: coordinator);

  static AnalysisCoordinator of(BuildContext context) {
    final coordinator = maybeOf(context);
    if (coordinator == null) {
      throw StateError(
        'AnalysisCoordinatorScope is missing above this context.',
      );
    }
    return coordinator;
  }

  static AnalysisCoordinator? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AnalysisCoordinatorScope>()
      ?.notifier;
}
