import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';

import '../support/analysis_app_harness.dart';

void main() {
  Future<AnalysisAppHarness> completedHarness() async {
    final harness = AnalysisAppHarness.standard(
      emittedPositions: 91,
      complete: true,
    );
    await harness.initialize();
    harness.coordinator.start(
      document: harness.review.record,
      serviceProfile: harness.settings.settings.analysisService,
      settings: harness.settings.settings.analysisRequestSettings,
    );
    return harness;
  }

  testWidgets('landscape phone shows a bounded portrait guard', (tester) async {
    await configureTestView(tester, size: const Size(844, 390));
    final harness = await completedHarness();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app(route: AppRoutes.keyMoveReview));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('请竖屏使用'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape tablet keeps the real expanded review workspace', (
    tester,
  ) async {
    await configureTestView(tester, size: const Size(1024, 768));
    final harness = await completedHarness();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app(route: AppRoutes.keyMoveReview));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('请竖屏使用'), findsNothing);
    expect(find.text('标准复盘'), findsOneWidget);
    expect(find.byKey(const Key('tablet-review-inspector')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
