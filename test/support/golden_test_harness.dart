import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';

const goldenSurfaceKey = ValueKey<String>('golden-surface');

abstract final class GoldenViewport {
  static const phone = Size(393, 852);
  static const tabletLandscape = Size(1024, 768);
}

/// Pumps one deterministic, full-viewport product surface for visual tests.
///
/// The harness intentionally fixes every rendering input controlled by the
/// test process. Reference files are still macOS baselines because system font
/// rasterization is platform-specific.
Future<void> pumpGoldenSurface(
  WidgetTester tester, {
  required Widget screen,
  required Size size,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  tester.binding.platformDispatcher.localeTestValue = const Locale('zh', 'CN');

  addTearDown(() {
    tester.view
      ..resetDevicePixelRatio()
      ..resetPhysicalSize();
    tester.binding.platformDispatcher.clearLocaleTestValue();
  });

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      theme: LizzieTheme.light(),
      darkTheme: LizzieTheme.dark(),
      themeMode: themeMode,
      builder: (context, child) {
        final media = MediaQuery.of(context).copyWith(
          accessibleNavigation: true,
          boldText: false,
          disableAnimations: true,
          highContrast: false,
          invertColors: false,
          navigationMode: NavigationMode.traditional,
          textScaler: TextScaler.noScaling,
        );
        return MediaQuery(
          data: media,
          child: TickerMode(enabled: false, child: child!),
        );
      },
      home: RepaintBoundary(key: goldenSurfaceKey, child: screen),
    ),
  );

  await tester.pump();
  await tester.pump(Duration.zero);
  expect(tester.takeException(), isNull);
}
