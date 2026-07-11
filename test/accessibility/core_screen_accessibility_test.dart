import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';

void main() {
  const routes = <String>[
    AppRoutes.root,
    AppRoutes.analysisProgress,
    AppRoutes.keyMoveReview,
    AppRoutes.variationComparison,
    AppRoutes.gamePerformance,
    AppRoutes.positionAnalysis,
  ];

  Future<void> pumpRoute(
    WidgetTester tester, {
    required String route,
    required double textScale,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(393, 852)
      ..padding = const FakeViewPadding(top: 59, bottom: 34)
      ..viewPadding = const FakeViewPadding(top: 59, bottom: 34);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize()
        ..resetPadding()
        ..resetViewPadding();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(LizzieYzyApp(initialRoute: route));
    await tester.pumpAndSettle();
  }

  // 3.2x approximates the largest accessibility text category exposed by
  // current mobile platforms and guards the mode-based large-text layouts.
  for (final scale in <double>[1.3, 2, 3.2]) {
    for (final route in routes) {
      testWidgets('$route survives ${scale}x Dynamic Type without clipping', (
        tester,
      ) async {
        await pumpRoute(tester, route: route, textScale: scale);

        final verticalScrollables = tester
            .widgetList<Scrollable>(find.byType(Scrollable))
            .where(
              (widget) =>
                  widget.axisDirection == AxisDirection.down ||
                  widget.axisDirection == AxisDirection.up,
            );
        expect(
          verticalScrollables,
          isEmpty,
          reason: 'Core mobile tasks must remain mode-based, not scroll-based.',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final scale in <double>[2, 3.2]) {
    testWidgets('review modes remain stable at ${scale}x text', (tester) async {
      await pumpRoute(tester, route: AppRoutes.keyMoveReview, textScale: scale);

      for (final tab in <String>['变化', '走势', '本局', '关键手']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('performance modes remain stable at ${scale}x text', (
      tester,
    ) async {
      await pumpRoute(
        tester,
        route: AppRoutes.gamePerformance,
        textScale: scale,
      );

      for (final tab in <String>['阶段', '样本', '核心']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('Go board remains one adjustable semantic control', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpRoute(tester, route: AppRoutes.positionAnalysis, textScale: 1.3);

    expect(find.bySemanticsLabel(RegExp('当前局面分析棋盘')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('交叉点')), findsNothing);
    semantics.dispose();
  });
}
