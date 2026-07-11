import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';

void main() {
  for (final textScale in <double>[2, 3.2]) {
    testWidgets(
      '${textScale}x home keeps primary action and recent game in safe area',
      (tester) async {
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
        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(const LizzieYzyApp());
        await tester.pumpAndSettle();

        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);

        final scanAction = find.bySemanticsLabel(RegExp('打开相机识别棋盘'));
        final recentGame = find.bySemanticsLabel(RegExp('236手，复盘完成'));

        expect(scanAction, findsOneWidget);
        expect(recentGame, findsOneWidget);
        expect(find.text('棋路未央  ·  山海一局'), findsNothing);

        final actions = <Finder>[scanAction, recentGame];
        if (textScale >= 2.75) {
          final activeAnalysis = find.bySemanticsLabel(RegExp('查看正在分析'));
          expect(activeAnalysis, findsOneWidget);
          actions.add(activeAnalysis);
        }
        for (final action in actions) {
          final rect = tester.getRect(action);
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(393));
          expect(rect.top, greaterThanOrEqualTo(59));
          expect(rect.bottom, lessThanOrEqualTo(852 - 34));
        }
        semantics.dispose();
      },
    );
  }
}
