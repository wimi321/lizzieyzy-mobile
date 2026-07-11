import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';

void main() {
  for (final textScale in <double>[2, 3.2]) {
    testWidgets(
      '${textScale}x empty home keeps primary and import actions in one viewport',
      (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(393, 852);
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        tester.platformDispatcher.localesTestValue = const <Locale>[
          Locale('zh'),
        ];
        addTearDown(() {
          tester.view
            ..resetDevicePixelRatio()
            ..resetPhysicalSize();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
          tester.platformDispatcher.clearLocalesTestValue();
        });
        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(const LizzieYzyApp());
        await tester.pumpAndSettle();

        expect(find.byType(Scrollable), findsNothing);
        expect(tester.takeException(), isNull);
        final scanAction = find.bySemanticsLabel(RegExp('打开相机识别棋盘'));
        expect(scanAction, findsOneWidget);
        expect(find.textContaining('还没有棋谱'), findsOneWidget);
        expect(find.byTooltip('导入第一份棋谱'), findsOneWidget);

        final rect = tester.getRect(scanAction);
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(393));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(852));
        semantics.dispose();
      },
    );
  }
}
