import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/features/import/presentation/kifu_import_controller.dart';
import 'package:lizzieyzy_mobile/features/import/presentation/kifu_import_screen.dart';
import 'package:lizzieyzy_mobile/features/home/presentation/kifu_home_screen.dart';
import 'package:lizzieyzy_mobile/features/scan/presentation/camera_capture_screen.dart';
import 'package:lizzieyzy_mobile/features/settings/presentation/privacy_settings_screen.dart';
import 'package:lizzieyzy_mobile/features/settings/presentation/settings_screen.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../tool/generate_pseudo_arb.dart' as pseudo;
import '../features/scan_test_fakes.dart';

void main() {
  const productionLocales = <Locale>[
    Locale('zh'),
    Locale('zh', 'TW'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  for (final locale in productionLocales) {
    testWidgets('${locale.toLanguageTag()} renders a bounded import screen', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(360, 800);
      addTearDown(() {
        tester.view
          ..resetDevicePixelRatio()
          ..resetPhysicalSize();
      });
      final controller = KifuImportController(picker: () async => null);
      addTearDown(controller.dispose);
      final strings = lookupAppLocalizations(locale);

      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: LizzieTheme.light(),
          home: KifuImportScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.importKifuTitle), findsOneWidget);
      expect(find.text(strings.chooseKifuFile), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('LizzieYzyApp applies the saved locale preference', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(393, 852);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });
    final settings = AppSettingsController(
      repository: MemoryAppSettingsRepository(
        const AppSettings(locale: AppLocalePreference.japanese),
      ),
    );
    await settings.initialize();
    addTearDown(settings.dispose);

    await tester.pumpWidget(LizzieYzyApp(settingsController: settings));
    await tester.pumpAndSettle();

    final japanese = lookupAppLocalizations(const Locale('ja'));
    expect(find.text(japanese.scanTab), findsOneWidget);
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.locale, const Locale('ja'));
    expect(materialApp.supportedLocales, productionLocales);
    expect(tester.takeException(), isNull);
  });

  test(
    'generated pseudo locale is current and expands every message by 30%',
    () {
      final english =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, Object?>;
      final generated =
          jsonDecode(File('lib/l10n/app_en_XA.arb').readAsStringSync())
              as Map<String, Object?>;

      expect(generated, pseudo.buildPseudoArb(english));
      for (final entry in english.entries) {
        if (entry.key.startsWith('@')) continue;
        final source = entry.value! as String;
        final expanded = generated[entry.key]! as String;
        expect(
          expanded.runes.length,
          greaterThanOrEqualTo((source.runes.length * 1.30).ceil()),
          reason: entry.key,
        );
        expect(expanded, contains(source), reason: entry.key);
      }
    },
  );

  testWidgets('30% pseudo locale stays within one 360x800 viewport', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(360, 800);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });
    final controller = KifuImportController(picker: () async => null);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'XA'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: LizzieTheme.light(),
        home: KifuImportScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('⟦Import game⟧'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('30% pseudo locale keeps all non-review core screens bounded', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(360, 800);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });
    final workspace = KifuWorkspaceController();
    await workspace.initialize();
    addTearDown(workspace.dispose);
    final settings = AppSettingsController(
      repository: MemoryAppSettingsRepository(),
    );
    await settings.initialize();
    addTearDown(settings.dispose);
    final camera = ScanCaptureController(
      platform: FakeScanCapturePlatform(),
      vision: FakeBoardVision(),
    );
    addTearDown(camera.dispose);

    Widget app(Widget home) => MaterialApp(
      locale: const Locale('en', 'XA'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: LizzieTheme.light(),
      home: home,
    );

    final screens = <Widget>[
      KifuWorkspace(controller: workspace, child: const KifuHomeScreen()),
      AppSettingsScope(controller: settings, child: const SettingsScreen()),
      const PrivacySettingsScreen(),
      CameraCaptureScreen(controller: camera),
    ];
    for (final screen in screens) {
      await tester.pumpWidget(app(screen));
      await tester.pumpAndSettle();
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
    }
  });
}
