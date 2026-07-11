import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/features/scan/presentation/camera_capture_screen.dart';
import 'package:lizzieyzy_mobile/features/scan/presentation/correction_screens.dart';
import 'package:lizzieyzy_mobile/features/scan/presentation/scan_result_screen.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import 'scan_test_fakes.dart';

void main() {
  const viewports = <Size>[
    Size(360, 800),
    Size(375, 667),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ];

  Future<void> pump(
    WidgetTester tester, {
    required Size size,
    required Widget child,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    tester.platformDispatcher.localesTestValue = const <Locale>[Locale('zh')];
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
      tester.platformDispatcher.clearLocalesTestValue();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: LizzieTheme.light(),
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: child,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);
  }

  void expectNoVerticalViewport(WidgetTester tester) {
    final vertical = tester
        .widgetList<Scrollable>(find.byType(Scrollable))
        .where(
          (widget) =>
              widget.axisDirection == AxisDirection.up ||
              widget.axisDirection == AxisDirection.down,
        );
    expect(vertical, isEmpty);
  }

  for (final viewport in viewports) {
    final label = '${viewport.width.toInt()}x${viewport.height.toInt()}';

    testWidgets('$label 空棋谱首页仍把主操作和导入入口放在同屏', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = viewport;
      tester.platformDispatcher.localesTestValue = const <Locale>[Locale('zh')];
      addTearDown(() {
        tester.view
          ..resetDevicePixelRatio()
          ..resetPhysicalSize();
        tester.platformDispatcher.clearLocalesTestValue();
      });
      await tester.pumpWidget(const LizzieYzyApp());
      await tester.pumpAndSettle();
      expectNoVerticalViewport(tester);
      expect(find.text('拍照识谱'), findsOneWidget);
      expect(find.textContaining('还没有棋谱'), findsOneWidget);
      expect(find.byTooltip('导入棋谱'), findsOneWidget);
    });

    testWidgets('$label 相机取景、状态和快门同屏可见', (tester) async {
      final controller = ScanCaptureController(
        platform: FakeScanCapturePlatform(),
        vision: FakeBoardVision(),
      );
      await pump(
        tester,
        size: viewport,
        child: CameraCaptureScreen(controller: controller),
      );
      expectNoVerticalViewport(tester);
      expect(find.bySemanticsLabel('相机取景框，十九路棋盘需完整入框'), findsOneWidget);
      expect(find.text('完整棋盘入框 · 保持稳定'), findsOneWidget);
      expect(find.bySemanticsLabel('拍照'), findsOneWidget);
      expect(find.text('相册'), findsOneWidget);
    });

    testWidgets('$label 实体盘校对状态与确认同屏', (tester) async {
      final capture = _capture(
        fakeScanDraft(
          uncertain: <domain.BoardPoint>{
            const domain.BoardPoint(7, 7),
            const domain.BoardPoint(12, 13),
          },
        ),
      );
      await pump(
        tester,
        size: viewport,
        child: PhysicalBoardCorrectionScreen(capture: capture),
      );
      expectNoVerticalViewport(tester);
      expect(find.bySemanticsLabel('待确认，2'), findsOneWidget);
      for (final text in <String>['黑', '白', '空', '看不清']) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.widgetWithText(FilledButton, '请先确认 2 处'), findsOneWidget);
    });

    testWidgets('$label 编号纠错与局面降级同屏', (tester) async {
      final capture = _capture(
        fakeScanDraft(kind: domain.ScanKind.numberedDiagram),
      );
      await pump(
        tester,
        size: viewport,
        child: NumberedKifuCorrectionScreen(capture: capture),
      );
      expectNoVerticalViewport(tester);
      expect(find.text('第1手无法确认'), findsOneWidget);
      expect(find.text('提子后同点复用'), findsOneWidget);
      expect(find.text('无法恢复手顺，按当前局面保存'), findsOneWidget);
    });

    testWidgets('$label 识别结果限制与两个出口同屏', (tester) async {
      final draft = fakeScanDraft();
      final stones = <domain.BoardPoint, domain.StoneColor>{
        for (final prediction in draft.intersections)
          prediction.point: ?prediction.predictedStone,
      };
      final snapshot = domain.PositionSnapshot(
        id: 'viewport-position',
        position: domain.BoardPosition(size: draft.boardSize, stones: stones),
        rules: const domain.GoRules.chinese(),
        source: const domain.KifuSource(kind: domain.KifuSourceKind.fixture),
      );
      await pump(
        tester,
        size: viewport,
        child: ScanResultScreen(
          result: ScanPositionPayload(
            snapshot: snapshot,
            originalFrame: fakeFrame(),
            draft: draft,
          ),
        ),
      );
      expectNoVerticalViewport(tester);
      expect(find.text('棋盘识别完成'), findsOneWidget);
      expect(find.textContaining('无法恢复完整手顺'), findsOneWidget);
      expect(find.text('先选下一手'), findsOneWidget);
      expect(find.text('保存局面'), findsOneWidget);
    });
  }

  testWidgets('扫描局面保存成功后才携带实际入库对象开始分析', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(393, 852);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });
    final workspace = KifuWorkspaceController();
    await workspace.initialize();
    addTearDown(workspace.dispose);
    final draft = fakeScanDraft();
    final snapshot = domain.PositionSnapshot(
      id: 'persist-before-analysis',
      position: domain.BoardPosition(
        size: draft.boardSize,
        stones: <domain.BoardPoint, domain.StoneColor>{
          for (final prediction in draft.intersections)
            prediction.point: ?prediction.predictedStone,
        },
      ),
      rules: const domain.GoRules.chinese(),
      source: const domain.KifuSource(kind: domain.KifuSourceKind.camera),
    );
    String? pushedRoute;
    Object? pushedArguments;
    await tester.pumpWidget(
      KifuWorkspace(
        controller: workspace,
        child: MaterialApp(
          theme: LizzieTheme.light(),
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          onGenerateRoute: (settings) {
            pushedRoute = settings.name;
            pushedArguments = settings.arguments;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const SizedBox.shrink(),
            );
          },
          home: ScanResultScreen(
            result: ScanPositionPayload(
              snapshot: snapshot,
              originalFrame: fakeFrame(),
              draft: draft,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('黑方'));
    await tester.pump();
    await tester.tap(find.text('分析当前局面'));
    await tester.pumpAndSettle();

    expect(pushedRoute, AppRoutes.analysisProgress);
    expect(workspace.documents, hasLength(1));
    expect(pushedArguments, same(workspace.selected));
    expect(pushedArguments, isA<domain.PositionSnapshot>());
    expect(
      (pushedArguments! as domain.PositionSnapshot).playerToMove,
      domain.StoneColor.black,
    );
  });
}

ScanCapturePayload _capture(domain.ScanDraft draft) => ScanCapturePayload(
  draft: draft,
  originalFrame: fakeFrame(),
  inputKind: ScanInputKind.camera,
  usedBurst: false,
);
