import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/game_performance_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/key_move_review_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/position_analysis_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/review_screen_data.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/variation_comparison_screen.dart';

import '../support/analysis_app_harness.dart';
import '../support/review_screen_fixture.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    required Widget screen,
    required double textScale,
  }) async {
    await configureTestView(
      tester,
      size: const Size(393, 852),
      textScale: textScale,
    );
    await tester.pumpWidget(
      MaterialApp(theme: LizzieTheme.light(), home: screen),
    );
    await tester.pumpAndSettle();
  }

  void expectBounded(WidgetTester tester) {
    final verticalScrollables = tester
        .widgetList<Scrollable>(find.byType(Scrollable))
        .where(
          (widget) =>
              widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up,
        );
    expect(verticalScrollables, isEmpty);
    expect(tester.takeException(), isNull);
  }

  for (final scale in <double>[1.3, 2, 3.2]) {
    testWidgets('real review screens survive ${scale}x Dynamic Type', (
      tester,
    ) async {
      final review = reviewScreenFixture();
      final move = review.primaryMoment!.moveNumber;
      final screens = <Widget>[
        KeyMoveReviewScreen(data: review),
        VariationComparisonScreen(
          selection: ReviewMoveSelection(data: review, moveNumber: move),
        ),
        GamePerformanceScreen(
          review: review,
          report: performanceScreenFixture(review),
        ),
        PositionAnalysisScreen(data: positionScreenFixture()),
      ];
      for (final screen in screens) {
        await pumpScreen(tester, screen: screen, textScale: scale);
        expectBounded(tester);
      }
    });

    testWidgets('real progress survives ${scale}x Dynamic Type', (
      tester,
    ) async {
      await configureTestView(
        tester,
        size: const Size(393, 852),
        textScale: scale,
      );
      final harness = AnalysisAppHarness.standard(emittedPositions: 42);
      await harness.initialize();
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expectBounded(tester);
    });
  }

  for (final scale in <double>[2, 3.2]) {
    testWidgets('review modes remain stable at ${scale}x text', (tester) async {
      await pumpScreen(
        tester,
        screen: KeyMoveReviewScreen(data: reviewScreenFixture()),
        textScale: scale,
      );
      for (final tab in <String>['变化', '走势', '本局', '关键手']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expectBounded(tester);
      }
    });

    testWidgets('performance modes remain stable at ${scale}x text', (
      tester,
    ) async {
      final review = reviewScreenFixture();
      await pumpScreen(
        tester,
        screen: GamePerformanceScreen(
          review: review,
          report: performanceScreenFixture(review),
        ),
        textScale: scale,
      );
      for (final tab in <String>['阶段', '样本', '核心']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expectBounded(tester);
      }
    });
  }

  testWidgets('Go board remains one adjustable semantic control', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(
      tester,
      screen: PositionAnalysisScreen(data: positionScreenFixture()),
      textScale: 1.3,
    );

    expect(find.bySemanticsLabel(RegExp('当前局面分析棋盘')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('交叉点')), findsNothing);
    semantics.dispose();
  });
}
