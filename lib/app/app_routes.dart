import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../features/review/presentation/analysis_progress_screen.dart';
import '../features/import/presentation/kifu_import_screen.dart';
import '../features/import/presentation/partial_record_screen.dart';
import '../features/review/presentation/game_performance_screen.dart';
import '../features/review/presentation/key_move_review_screen.dart';
import '../features/review/presentation/position_analysis_screen.dart';
import '../features/review/presentation/review_screen_data.dart';
import '../features/review/presentation/tablet_review_screen.dart';
import '../features/review/presentation/variation_comparison_screen.dart';
import '../features/scan/presentation/camera_capture_screen.dart';
import '../features/scan/presentation/correction_screens.dart';
import '../features/scan/presentation/scan_result_screen.dart';
import '../features/settings/presentation/analysis_service_settings_screen.dart';
import '../features/settings/presentation/privacy_settings_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'home_shell.dart';

abstract final class AppRoutes {
  static const root = '/';
  static const camera = '/scan/camera';
  static const importKifu = '/kifu/import';
  static const partialRecord = '/kifu/partial';
  static const boardCorrection = '/scan/correct-board';
  static const numberedCorrection = '/scan/correct-numbered';
  static const scanResult = '/scan/result';
  static const analysisProgress = '/review/analyzing';
  static const keyMoveReview = '/review/key-move';
  static const positionAnalysis = '/review/position';
  static const gamePerformance = '/review/performance';
  static const variationComparison = '/review/variation';
  static const tabletReview = '/review/tablet';
  static const settingsHome = '/settings';
  static const analysisServiceSettings = '/settings/analysis-service';
  static const appearanceSettings = '/settings/appearance';
  static const languageSettings = '/settings/language';
  static const privacySettings = '/settings/privacy';

  /// The document subtype is a trust boundary, not a presentation hint.
  /// Partial records can only open their confirmation screen; snapshots and
  /// verified games may be analyzed, but only verified games can later create
  /// a full review report.
  static String routeForDocument(KifuDocument document) => switch (document) {
    VerifiedGameRecord() || PositionSnapshot() => analysisProgress,
    PartialGameRecord() => partialRecord,
  };

  static Route<void> onGenerateRoute(RouteSettings settings) {
    final child = switch (settings.name) {
      root => const HomeShell(),
      camera => CameraCaptureScreen(
        controller: settings.arguments is ScanCaptureController
            ? settings.arguments! as ScanCaptureController
            : null,
      ),
      importKifu => const KifuImportScreen(),
      partialRecord => PartialRecordScreen(
        record: settings.arguments is PartialGameRecord
            ? settings.arguments! as PartialGameRecord
            : null,
      ),
      boardCorrection => PhysicalBoardCorrectionScreen(
        capture: settings.arguments is ScanCapturePayload
            ? settings.arguments! as ScanCapturePayload
            : null,
      ),
      numberedCorrection => NumberedKifuCorrectionScreen(
        capture: settings.arguments is ScanCapturePayload
            ? settings.arguments! as ScanCapturePayload
            : null,
      ),
      scanResult => ScanResultScreen(
        result: settings.arguments is ScanPositionPayload
            ? settings.arguments! as ScanPositionPayload
            : null,
      ),
      analysisProgress => AnalysisProgressScreen(
        document: settings.arguments is KifuDocument
            ? settings.arguments! as KifuDocument
            : null,
      ),
      keyMoveReview => KeyMoveReviewScreen(
        data: settings.arguments is ReviewScreenData
            ? settings.arguments! as ReviewScreenData
            : null,
      ),
      positionAnalysis => PositionAnalysisScreen(
        data: settings.arguments is PositionAnalysisData
            ? settings.arguments! as PositionAnalysisData
            : null,
        snapshot: settings.arguments is PositionSnapshot
            ? settings.arguments! as PositionSnapshot
            : null,
      ),
      gamePerformance => GamePerformanceScreen(
        review: settings.arguments is ReviewScreenData
            ? settings.arguments! as ReviewScreenData
            : null,
        report: settings.arguments is ReviewScreenData
            ? (settings.arguments! as ReviewScreenData).performanceReport
            : null,
      ),
      variationComparison => VariationComparisonScreen(
        selection: settings.arguments is ReviewMoveSelection
            ? settings.arguments! as ReviewMoveSelection
            : null,
      ),
      tabletReview => TabletReviewScreen(
        data: settings.arguments is ReviewScreenData
            ? settings.arguments! as ReviewScreenData
            : null,
      ),
      settingsHome => const SettingsScreen(),
      analysisServiceSettings => const AnalysisServiceSettingsScreen(),
      appearanceSettings => const AppearanceSettingsScreen(),
      languageSettings => const LanguageSettingsScreen(),
      privacySettings => const PrivacySettingsScreen(),
      _ => const _UnknownRouteScreen(),
    };
    return MaterialPageRoute<void>(settings: settings, builder: (_) => child);
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.pageNotFound)),
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.root,
            (_) => false,
          ),
          child: Text(context.l10n.returnToKifu),
        ),
      ),
    );
  }
}
