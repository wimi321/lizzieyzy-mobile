import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';

void main() {
  const phoneViewports = <Size>[
    Size(360, 800),
    Size(375, 667),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ];

  Future<void> pumpRoute(
    WidgetTester tester, {
    required Size size,
    required String route,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    final safeInsets = size.width >= 390
        ? const FakeViewPadding(top: 59, bottom: 34)
        : const FakeViewPadding(top: 24, bottom: 24);
    tester.view.padding = safeInsets;
    tester.view.viewPadding = safeInsets;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.pumpWidget(LizzieYzyApp(initialRoute: route));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
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

  void expectMinimumTouchTarget(WidgetTester tester, Finder finder) {
    expect(finder, findsOneWidget);
    final size = tester.getSize(finder);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  }

  for (final viewport in phoneViewports) {
    final label = '${viewport.width.toInt()}×${viewport.height.toInt()}';

    testWidgets('$label 分析进度的棋盘、控制与入口同屏可见', (tester) async {
      await pumpRoute(
        tester,
        size: viewport,
        route: AppRoutes.analysisProgress,
      );

      expectNoVerticalScrollable(tester);
      expectFullyVisible(
        tester,
        find.widgetWithText(TextButton, '暂停'),
        viewport,
      );
      expectMinimumTouchTarget(tester, find.widgetWithText(TextButton, '暂停'));
      expectFullyVisible(
        tester,
        find.widgetWithText(OutlinedButton, '查看已完成的142手'),
        viewport,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('$label 关键手的棋盘、时间轴与检查器同屏可见', (tester) async {
      await pumpRoute(tester, size: viewport, route: AppRoutes.keyMoveReview);

      expectNoVerticalScrollable(tester);
      expectFullyVisible(tester, find.text('R14 · 最佳候选'), viewport);
      expectFullyVisible(tester, find.text('本局'), viewport);
      expectMinimumTouchTarget(
        tester,
        find
            .ancestor(of: find.text('关键手'), matching: find.byType(InkWell))
            .first,
      );

      for (final tab in <String>['变化', '走势', '本局', '关键手']) {
        await tester.tap(find.text(tab).last);
        await tester.pump(const Duration(milliseconds: 250));
        expectNoVerticalScrollable(tester);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('$label 变化比较的候选、PV与回主线操作同屏可见', (tester) async {
      await pumpRoute(
        tester,
        size: viewport,
        route: AppRoutes.variationComparison,
      );

      expectNoVerticalScrollable(tester);
      expectFullyVisible(tester, find.text('12,840'), viewport);
      expectMinimumTouchTarget(tester, find.bySemanticsLabel('候选A，R14，+3.1目'));
      expectFullyVisible(
        tester,
        find.widgetWithText(FilledButton, '回到主线第87手'),
        viewport,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('$label 单局棋力的区间、阶段与样本质量同屏可见', (tester) async {
      await pumpRoute(tester, size: viewport, route: AppRoutes.gamePerformance);

      expectNoVerticalScrollable(tester);
      expectFullyVisible(tester, find.text('3级–1级'), viewport);
      expectFullyVisible(tester, find.text('校准范围'), viewport);
      expectMinimumTouchTarget(tester, find.byTooltip('返回'));
      expect(tester.takeException(), isNull);
    });
  }
}
