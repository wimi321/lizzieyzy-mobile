import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/game_performance_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/key_move_review_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/review_screen_data.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/variation_comparison_screen.dart';

import '../support/analysis_app_harness.dart';
import '../support/review_screen_fixture.dart';

void main() {
  const phoneViewports = <Size>[
    Size(360, 800),
    Size(375, 667),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ];

  Future<void> pumpScreen(
    WidgetTester tester, {
    required Size size,
    required Widget screen,
  }) async {
    await configureTestView(tester, size: size);
    await tester.pumpWidget(
      MaterialApp(theme: LizzieTheme.light(), home: screen),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  void expectNoVerticalScrollable(WidgetTester tester) {
    final verticalScrollables = tester
        .widgetList<Scrollable>(find.byType(Scrollable))
        .where(
          (widget) =>
              widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up,
        );
    expect(verticalScrollables, isEmpty, reason: '手机复盘核心任务不应依赖纵向滚动');
  }

  void expectFullyVisible(WidgetTester tester, Finder finder, Size viewport) {
    expect(finder, findsOneWidget);
    final rect = tester.getRect(finder);
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(viewport.height + 0.01));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(viewport.width + 0.01));
  }

  for (final viewport in phoneViewports) {
    final label = '${viewport.width.toInt()}×${viewport.height.toInt()}';

    testWidgets('$label 真实分析进度的棋盘与取消同屏可见', (tester) async {
      await configureTestView(tester, size: viewport);
      final harness = AnalysisAppHarness.standard(emittedPositions: 42);
      await harness.initialize();
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expectNoVerticalScrollable(tester);
      expectFullyVisible(
        tester,
        find.widgetWithText(TextButton, '取消'),
        viewport,
      );
      expect(find.text('42 / 91 个局面'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$label 真实关键手的棋盘、时间轴与检查器同屏可见', (tester) async {
      final data = reviewScreenFixture();
      await pumpScreen(
        tester,
        size: viewport,
        screen: KeyMoveReviewScreen(data: data),
      );

      expectNoVerticalScrollable(tester);
      expectFullyVisible(tester, find.text('本局'), viewport);
      expect(find.byKey(const Key('mobile-review-viewport')), findsOneWidget);
      for (final tab in <String>['变化', '走势', '本局', '关键手']) {
        await tester.tap(find.text(tab));
        await tester.pump(const Duration(milliseconds: 200));
        expectNoVerticalScrollable(tester);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('$label 真实变化候选、PV与回主线操作同屏可见', (tester) async {
      final data = reviewScreenFixture();
      final move = data.primaryMoment!.moveNumber;
      await pumpScreen(
        tester,
        size: viewport,
        screen: VariationComparisonScreen(
          selection: ReviewMoveSelection(data: data, moveNumber: move),
        ),
      );

      expectNoVerticalScrollable(tester);
      expect(find.bySemanticsLabel(RegExp('候选A')), findsWidgets);
      expectFullyVisible(
        tester,
        find.widgetWithText(FilledButton, '回到主线第$move手'),
        viewport,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('$label 已校准单局棋力的区间与样本同屏可见', (tester) async {
      final data = reviewScreenFixture();
      final report = performanceScreenFixture(data);
      await pumpScreen(
        tester,
        size: viewport,
        screen: GamePerformanceScreen(review: data, report: report),
      );

      expectNoVerticalScrollable(tester);
      expect(find.textContaining('80% 区间'), findsOneWidget);
      expect(find.textContaining('有效决策'), findsWidgets);
      expect(find.textContaining('不是长期棋力'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
