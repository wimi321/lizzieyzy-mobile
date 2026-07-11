import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/analysis/analysis.dart';
import 'package:lizzieyzy_mobile/application/inbound_kifu_controller.dart';
import 'package:lizzieyzy_mobile/application/kifu_export_scope.dart';
import 'package:lizzieyzy_mobile/application/kifu_export_service.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/infrastructure/analysis/analysis.dart';
import 'package:lizzieyzy_mobile/infrastructure/review/review.dart';
import 'package:lizzieyzy_mobile/infrastructure/sharing/sharing.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import 'app_routes.dart';

class LizzieYzyApp extends StatefulWidget {
  const LizzieYzyApp({
    super.key,
    this.initialRoute = AppRoutes.root,
    this.workspaceController,
    this.settingsController,
    this.analysisCoordinator,
    this.exportService,
    this.inboundKifuController,
  });

  final String initialRoute;
  final KifuWorkspaceController? workspaceController;
  final AppSettingsController? settingsController;
  final AnalysisCoordinator? analysisCoordinator;
  final KifuExportService? exportService;
  final InboundKifuController? inboundKifuController;

  @override
  State<LizzieYzyApp> createState() => _LizzieYzyAppState();
}

class _LizzieYzyAppState extends State<LizzieYzyApp>
    with WidgetsBindingObserver {
  late final KifuWorkspaceController _workspace =
      widget.workspaceController ?? KifuWorkspaceController();
  late final bool _ownsWorkspace = widget.workspaceController == null;
  late final AppSettingsController _settings =
      widget.settingsController ??
      AppSettingsController(repository: MemoryAppSettingsRepository());
  late final bool _ownsSettings = widget.settingsController == null;
  late final AnalysisCoordinator _analysis =
      widget.analysisCoordinator ??
      AnalysisCoordinator(
        providerFactory: const WssAnalysisProviderFactory(),
        reviewBuilder: const DefaultReviewBuilder(),
        performanceEstimatorFactory: (calibration) =>
            CalibratedGamePerformanceEstimator(calibration: calibration),
      );
  late final bool _ownsAnalysis = widget.analysisCoordinator == null;
  late final KifuExportService _export =
      widget.exportService ?? PlatformKifuExportService();
  bool _exportCleanupInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_ownsSettings) _settings.initialize();
    if (_ownsWorkspace) _workspace.initialize();
    _scheduleExportCleanup();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleExportCleanup();
  }

  void _scheduleExportCleanup() {
    if (_exportCleanupInFlight) return;
    final maintenance = switch (_export) {
      final KifuExportArtifactMaintenance value => value,
      _ => null,
    };
    if (maintenance == null) return;
    _exportCleanupInFlight = true;
    unawaited(_runExportCleanup(maintenance));
  }

  Future<void> _runExportCleanup(
    KifuExportArtifactMaintenance maintenance,
  ) async {
    try {
      await maintenance.cleanupStaleArtifacts();
    } on Object {
      // Export maintenance is explicitly fail-safe at the lifecycle boundary.
    } finally {
      _exportCleanupInFlight = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsWorkspace) _workspace.dispose();
    if (_ownsSettings) _settings.dispose();
    if (_ownsAnalysis) _analysis.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: _settings,
      child: _OptionalInboundKifuScope(
        controller: widget.inboundKifuController,
        child: KifuWorkspace(
          controller: _workspace,
          child: AnalysisCoordinatorScope(
            coordinator: _analysis,
            child: KifuExportScope(
              service: _export,
              child: AnimatedBuilder(
                animation: _settings,
                builder: (context, _) {
                  final preferences = _settings.settings;
                  return MaterialApp(
                    onGenerateTitle: (context) => context.l10n.appTitle,
                    debugShowCheckedModeBanner: false,
                    theme: LizzieTheme.light(),
                    darkTheme: LizzieTheme.dark(),
                    highContrastTheme: LizzieTheme.highContrastLight(),
                    highContrastDarkTheme: LizzieTheme.highContrastDark(),
                    themeMode: _themeMode(preferences.theme),
                    locale: _locale(preferences.locale),
                    supportedLocales: _productionLocales,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    initialRoute: widget.initialRoute,
                    onGenerateRoute: AppRoutes.onGenerateRoute,
                    builder: (context, child) {
                      final size = MediaQuery.sizeOf(context);
                      final isLandscapePhone =
                          size.width > size.height && size.shortestSide < 600;
                      if (!isLandscapePhone) {
                        return child ?? const SizedBox.shrink();
                      }
                      return const _PortraitPhoneGuard();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionalInboundKifuScope extends StatelessWidget {
  const _OptionalInboundKifuScope({
    required this.controller,
    required this.child,
  });

  final InboundKifuController? controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => controller == null
      ? child
      : InboundKifuScope(controller: controller!, child: child);
}

ThemeMode _themeMode(AppThemePreference preference) => switch (preference) {
  AppThemePreference.system => ThemeMode.system,
  AppThemePreference.light => ThemeMode.light,
  AppThemePreference.dark => ThemeMode.dark,
};

Locale? _locale(AppLocalePreference preference) => switch (preference) {
  AppLocalePreference.system => null,
  AppLocalePreference.simplifiedChinese => const Locale('zh', 'CN'),
  AppLocalePreference.traditionalChinese => const Locale('zh', 'TW'),
  AppLocalePreference.english => const Locale('en'),
  AppLocalePreference.japanese => const Locale('ja'),
  AppLocalePreference.korean => const Locale('ko'),
};

const _productionLocales = <Locale>[
  Locale('zh'),
  Locale('zh', 'TW'),
  Locale('en'),
  Locale('ja'),
  Locale('ko'),
];

class _PortraitPhoneGuard extends StatelessWidget {
  const _PortraitPhoneGuard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: l10n.portraitGuardSemantics,
            child: Padding(
              padding: const EdgeInsets.all(GoSpacing.s6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.screen_rotation_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: GoSpacing.s4),
                  Text(
                    l10n.portraitGuardTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: GoSpacing.s2),
                  Text(
                    l10n.portraitGuardBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
