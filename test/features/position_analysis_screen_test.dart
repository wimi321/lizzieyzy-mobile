import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/lizzieyzy_app.dart';
import 'package:lizzieyzy_mobile/app/app_routes.dart';

void main() {
  Future<void> pumpAtPhone(
    WidgetTester tester,
    String route, {
    Size size = const Size(393, 852),
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    final safeInsets = size.width >= 390
        ? const FakeViewPadding(top: 59, bottom: 34)
        : const FakeViewPadding(top: 24, bottom: 24);
    tester.view
      ..padding = safeInsets
      ..viewPadding = safeInsets;
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize()
        ..resetPadding()
        ..resetViewPadding();
    });
    await tester.pumpWidget(LizzieYzyApp(initialRoute: route));
    await tester.pumpAndSettle();
  }

  for (final size in <Size>[
    const Size(360, 800),
    const Size(375, 667),
    const Size(393, 852),
    const Size(412, 915),
    const Size(430, 932),
  ]) {
    testWidgets(
      '${size.width.toInt()}x${size.height.toInt()} photo position analysis '
      'keeps all analysis in one viewport',
      (tester) async {
        await pumpAtPhone(tester, AppRoutes.positionAnalysis, size: size);

        expect(find.text('局面分析'), findsOneWidget);
        expect(find.textContaining('无完整手顺'), findsWidgets);
        expect(find.text('关键手'), findsNothing);
        expect(find.text('本局发挥'), findsNothing);
        expect(find.byType(Slider), findsNothing);
        expect(find.byType(Scrollable), findsNothing);
        expect(find.text('R14'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('recognition result routes to position analysis', (tester) async {
    await pumpAtPhone(tester, AppRoutes.scanResult);
    await tester.tap(find.text('分析当前局面'));
    await tester.pumpAndSettle();

    expect(find.text('局面分析'), findsOneWidget);
    expect(find.textContaining('无完整手顺'), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
  });
}
