import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';

void main() {
  const routes = <String>[
    AppRoutes.settingsHome,
    AppRoutes.analysisServiceSettings,
    AppRoutes.appearanceSettings,
    AppRoutes.languageSettings,
    AppRoutes.privacySettings,
  ];

  Future<void> pumpRoute(
    WidgetTester tester, {
    required String route,
    required Size size,
    required double textScale,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size
      ..padding = const FakeViewPadding(top: 24, bottom: 24)
      ..viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    tester.binding.platformDispatcher.localesTestValue = const <Locale>[
      Locale('zh'),
    ];
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize()
        ..resetPadding()
        ..resetViewPadding();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.binding.platformDispatcher.clearLocalesTestValue();
    });
    await tester.pumpWidget(LizzieYzyApp(initialRoute: route));
    await tester.pumpAndSettle();
  }

  for (final size in const <Size>[Size(375, 667), Size(393, 852)]) {
    for (final scale in const <double>[1, 2, 3.2]) {
      for (final route in routes) {
        testWidgets(
          '$route fits ${size.width.toInt()}x${size.height.toInt()} at ${scale}x',
          (tester) async {
            await pumpRoute(tester, route: route, size: size, textScale: scale);

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
              reason: 'Settings tasks use bounded modes instead of scrolling.',
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('settings routes expose 48dp controls and readable semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpRoute(
      tester,
      route: AppRoutes.settingsHome,
      size: const Size(393, 852),
      textScale: 1.3,
    );

    expect(find.bySemanticsLabel(RegExp('分析服务')), findsOneWidget);
    final analysisTile = find
        .ancestor(of: find.text('分析服务'), matching: find.byType(InkWell))
        .first;
    expect(tester.getSize(analysisTile).height, greaterThanOrEqualTo(48));
    handle.dispose();
  });
}
