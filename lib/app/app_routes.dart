import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';

import '../features/review/presentation/analysis_progress_screen.dart';
import '../features/import/presentation/kifu_import_screen.dart';
import '../features/review/presentation/game_performance_screen.dart';
import '../features/review/presentation/key_move_review_screen.dart';
import '../features/review/presentation/position_analysis_screen.dart';
import '../features/review/presentation/tablet_review_screen.dart';
import '../features/review/presentation/variation_comparison_screen.dart';
import '../features/scan/presentation/camera_capture_screen.dart';
import '../features/scan/presentation/correction_screens.dart';
import '../features/scan/presentation/scan_result_screen.dart';
import 'home_shell.dart';

abstract final class AppRoutes {
  static const root = '/';
  static const camera = '/scan/camera';
  static const importKifu = '/kifu/import';
  static const boardCorrection = '/scan/correct-board';
  static const numberedCorrection = '/scan/correct-numbered';
  static const scanResult = '/scan/result';
  static const analysisProgress = '/review/analyzing';
  static const keyMoveReview = '/review/key-move';
  static const positionAnalysis = '/review/position';
  static const gamePerformance = '/review/performance';
  static const variationComparison = '/review/variation';
  static const tabletReview = '/review/tablet';

  static Route<void> onGenerateRoute(RouteSettings settings) {
    final child = switch (settings.name) {
      root => const HomeShell(),
      camera => CameraCaptureScreen(
        controller: settings.arguments is ScanCaptureController
            ? settings.arguments! as ScanCaptureController
            : null,
      ),
      importKifu => const KifuImportScreen(),
      boardCorrection => PhysicalBoardCorrectionScreen(
        capture: settings.arguments is ScanCapturePayload
            ? settings.arguments! as ScanCapturePayload
            : null,
      ),
      numberedCorrection => const NumberedKifuCorrectionScreen(),
      scanResult => ScanResultScreen(
        result: settings.arguments is ScanPositionPayload
            ? settings.arguments! as ScanPositionPayload
            : null,
      ),
      analysisProgress => const AnalysisProgressScreen(),
      keyMoveReview => const KeyMoveReviewScreen(),
      positionAnalysis => const PositionAnalysisScreen(),
      gamePerformance => const GamePerformanceScreen(),
      variationComparison => const VariationComparisonScreen(),
      tabletReview => const TabletReviewScreen(),
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
      appBar: AppBar(title: const Text('页面不存在')),
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.root,
            (_) => false,
          ),
          child: const Text('返回棋谱'),
        ),
      ),
    );
  }
}
