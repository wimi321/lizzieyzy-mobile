import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/analysis_app_harness.dart';

void main() {
  testWidgets('2.0x real progress stays single-screen and cancellable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await configureTestView(tester, size: const Size(393, 852), textScale: 2);
    final harness = AnalysisAppHarness.standard(emittedPositions: 42);
    await harness.initialize();
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final verticalScrollables = tester
        .widgetList<Scrollable>(find.byType(Scrollable))
        .where(
          (widget) =>
              widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up,
        );
    expect(verticalScrollables, isEmpty);
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel(RegExp('全局分析中，42 / 91')), findsOneWidget);

    final cancel = find.widgetWithText(TextButton, '取消');
    expect(cancel, findsOneWidget);
    expect(tester.getSize(cancel).height, greaterThanOrEqualTo(48));
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(find.text('取消分析？'), findsOneWidget);
    semantics.dispose();
  });
}
