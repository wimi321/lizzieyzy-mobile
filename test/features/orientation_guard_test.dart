import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester, {
    required Size size,
    required String route,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });
    await tester.pumpWidget(LizzieYzyApp(initialRoute: route));
    await tester.pumpAndSettle();
  }

  testWidgets('landscape phone shows a bounded portrait guard', (tester) async {
    await pumpAt(
      tester,
      size: const Size(844, 390),
      route: AppRoutes.keyMoveReview,
    );

    expect(find.text('请竖屏使用'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape tablet keeps the expanded review workspace', (
    tester,
  ) async {
    await pumpAt(
      tester,
      size: const Size(1024, 768),
      route: AppRoutes.keyMoveReview,
    );

    expect(find.text('请竖屏使用'), findsNothing);
    expect(find.text('标准复盘'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
