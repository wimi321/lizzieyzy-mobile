import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';
import 'package:lizzieyzy_mobile/application/kifu_export_service.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

import '../support/analysis_app_harness.dart';

void main() {
  testWidgets('完整棋谱沿真实分析结果贯通四个复盘区与分享', (tester) async {
    await configureTestView(tester, size: const Size(393, 852));
    final harness = AnalysisAppHarness.standard(
      emittedPositions: 91,
      complete: true,
    );
    await harness.initialize();
    addTearDown(harness.dispose);
    final export = _RecordingExportService();
    await tester.pumpWidget(
      LizzieYzyApp(
        initialRoute: AppRoutes.analysisProgress,
        workspaceController: harness.workspace,
        settingsController: harness.settings,
        analysisCoordinator: harness.coordinator,
        exportService: export,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('复盘已生成'), findsOneWidget);
    await tester.tap(find.text('打开关键手复盘'));
    await tester.pumpAndSettle();
    expect(find.text('关键手'), findsOneWidget);

    await tester.tap(find.text('变化'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('最佳候选')).last);
    await tester.pumpAndSettle();
    expect(find.text('变化比较'), findsOneWidget);
    expect(find.textContaining('访问'), findsWidgets);
    await tester.tap(find.textContaining('回到主线第'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('走势'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('全局目差走势')), findsOneWidget);

    await tester.tap(find.text('本局'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('本局数值')).last);
    await tester.pumpAndSettle();
    expect(find.text('暂不显示棋力区间'), findsOneWidget);
    expect(find.textContaining('不会用演示参数伪造级段'), findsOneWidget);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('导出棋谱'));
    await tester.pumpAndSettle();

    expect(export.shared, hasLength(1));
    expect(export.shared.single, same(harness.review.record));
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

final class _RecordingExportService implements KifuExportService {
  final List<KifuDocument> shared = <KifuDocument>[];

  @override
  Future<KifuShareOutcome> share(
    KifuDocument document, {
    ShareAnchor? anchor,
  }) async {
    shared.add(document);
    return KifuShareOutcome.success;
  }
}
