import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';

void main() {
  testWidgets('2.0x progress view stays single-screen and fully operable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(393, 852)
      ..padding = const FakeViewPadding(top: 59, bottom: 34)
      ..viewPadding = const FakeViewPadding(top: 59, bottom: 34);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize()
        ..resetPadding()
        ..resetViewPadding();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(
      const LizzieYzyApp(initialRoute: AppRoutes.analysisProgress),
    );
    await tester.pumpAndSettle();

    final verticalScrollables = tester
        .widgetList<Scrollable>(find.byType(Scrollable))
        .where(
          (widget) =>
              widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up,
        );
    expect(verticalScrollables, isEmpty);
    expect(tester.takeException(), isNull);

    expect(
      find.bySemanticsLabel(RegExp('标准分析，分析中，142 / 236，已用')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('读取棋谱，已完成或进行中'), findsOneWidget);
    expect(find.bySemanticsLabel('全局分析，已完成或进行中'), findsOneWidget);
    expect(find.bySemanticsLabel('生成报告，等待中'), findsOneWidget);

    for (final tooltip in <String>['暂停分析', '取消分析']) {
      final control = find.byTooltip(tooltip);
      expect(control, findsOneWidget);
      final size = tester.getSize(control);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }

    final review = find.widgetWithText(OutlinedButton, '查看已完成的142手');
    expect(review, findsOneWidget);
    expect(tester.getSize(review).height, greaterThanOrEqualTo(48));

    await tester.tap(find.byTooltip('暂停分析'));
    await tester.pump();
    expect(find.byTooltip('继续分析'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('标准分析，已暂停，142 / 236')), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
