import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

const goldenSurfaceKey = ValueKey<String>('golden-surface');
const _goldenFontFamily = 'LizzieYzyGoldenCjk';
Future<void>? _goldenFontLoad;

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
  await tester.runAsync(() async {
    await (_goldenFontLoad ??= _loadGoldenFonts());
  });
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

  final lightTheme = _withGoldenFont(LizzieTheme.light());
  final darkTheme = _withGoldenFont(LizzieTheme.dark());
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      themeAnimationDuration: Duration.zero,
      theme: lightTheme,
      darkTheme: darkTheme,
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

Future<void> _loadGoldenFonts() async {
  // Flutter tests otherwise replace every glyph with Ahem rectangles. This
  // OFL test-only subset keeps images human-auditable without adding a CJK
  // font to the application bundle.
  final file = File('test/assets/LizzieYzyGoldenCjk.otf');
  if (!file.existsSync()) {
    throw StateError('The deterministic CJK golden font is unavailable.');
  }
  final bytes = await file.readAsBytes();
  final data = ByteData.sublistView(bytes);
  await (FontLoader(_goldenFontFamily)..addFont(Future.value(data))).load();
  final iconData = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
  await (FontLoader('MaterialIcons')..addFont(Future.value(iconData))).load();
}

ThemeData _withGoldenFont(ThemeData source) {
  final textTheme = source.textTheme.apply(fontFamily: _goldenFontFamily);
  final primaryTextTheme = source.primaryTextTheme.apply(
    fontFamily: _goldenFontFamily,
  );
  ButtonStyle? buttonStyle(ButtonStyle? style, TextStyle? textStyle) =>
      style?.copyWith(textStyle: WidgetStatePropertyAll(textStyle));
  return source.copyWith(
    textTheme: textTheme,
    primaryTextTheme: primaryTextTheme,
    filledButtonTheme: FilledButtonThemeData(
      style: buttonStyle(source.filledButtonTheme.style, textTheme.labelLarge),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: buttonStyle(
        source.outlinedButtonTheme.style,
        textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: buttonStyle(source.textButtonTheme.style, textTheme.labelLarge),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: buttonStyle(
        source.elevatedButtonTheme.style,
        textTheme.labelLarge,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: buttonStyle(
        source.segmentedButtonTheme.style,
        textTheme.labelLarge,
      ),
    ),
    chipTheme: source.chipTheme.copyWith(labelStyle: textTheme.labelMedium),
    tabBarTheme: source.tabBarTheme.copyWith(
      labelStyle: textTheme.labelLarge,
      unselectedLabelStyle: textTheme.labelLarge,
    ),
  );
}
