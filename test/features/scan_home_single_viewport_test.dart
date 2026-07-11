import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/features/scan/presentation/camera_capture_screen.dart';

import 'scan_test_fakes.dart';

void main() {
  const viewports = <Size>[
    Size(360, 800),
    Size(375, 667),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ];

  Future<void> pumpRoute(
    WidgetTester tester, {
    required Size size,
    required String route,
    Widget? home,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    final safeInsets = size.width >= 390
        ? const FakeViewPadding(top: 59, bottom: 34)
        : const FakeViewPadding(top: 24, bottom: 24);
    tester.view.padding = safeInsets;
    tester.view.viewPadding = safeInsets;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      home == null
          ? LizzieYzyApp(initialRoute: route)
          : MaterialApp(
              theme: LizzieTheme.light(),
              onGenerateRoute: AppRoutes.onGenerateRoute,
              home: home,
            ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(tester.takeException(), isNull);
  }

  void expectNoVerticalViewport() {
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(CustomScrollView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(Scrollable), findsNothing);
  }

  void expectVisible(WidgetTester tester, Finder finder, Size viewport) {
    expect(finder, findsOneWidget);
    final rect = tester.getRect(finder);
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(viewport.height));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(viewport.width));
  }

  for (final viewport in viewports) {
    group('${viewport.width.toInt()}x${viewport.height.toInt()}', () {
      testWidgets('棋谱首页的主操作与两条最近棋谱同屏可见', (tester) async {
        await pumpRoute(tester, size: viewport, route: AppRoutes.root);

        expectNoVerticalViewport();
        expectVisible(tester, find.text('拍照识谱'), viewport);
        expectVisible(tester, find.text('正在分析'), viewport);
        expectVisible(tester, find.text('查看全部'), viewport);
        expectVisible(tester, find.text('山海一局  ·  清风入弦'), viewport);
        expectVisible(tester, find.text('棋路未央  ·  山海一局'), viewport);
        expect(tester.takeException(), isNull);
      });

      testWidgets('相机取景、对齐状态和快门同屏可见', (tester) async {
        final controller = ScanCaptureController(
          platform: FakeScanCapturePlatform(),
          vision: FakeBoardVision(),
        );
        await pumpRoute(
          tester,
          size: viewport,
          route: AppRoutes.camera,
          home: CameraCaptureScreen(controller: controller),
        );

        expectNoVerticalViewport();
        expectVisible(
          tester,
          find.bySemanticsLabel('相机取景框，十九路棋盘需完整入框'),
          viewport,
        );
        expectVisible(tester, find.text('完整棋盘入框 · 保持稳定'), viewport);
        expectVisible(tester, find.bySemanticsLabel('拍照'), viewport);
        expectVisible(tester, find.text('相册'), viewport);
        expectVisible(tester, find.text('拍摄帮助'), viewport);
        expect(tester.takeException(), isNull);
      });

      testWidgets('实体棋盘校对的状态选择和确认操作同屏可见', (tester) async {
        await pumpRoute(
          tester,
          size: viewport,
          route: AppRoutes.boardCorrection,
        );

        expectNoVerticalViewport();
        expectVisible(tester, find.text('待确认 2'), viewport);
        expectVisible(tester, find.text('黑'), viewport);
        expectVisible(tester, find.text('白'), viewport);
        expectVisible(tester, find.text('空'), viewport);
        expectVisible(tester, find.text('看不清'), viewport);
        expectVisible(tester, find.text('请先确认 2 处'), viewport);
        expect(tester.takeException(), isNull);
      });

      testWidgets('编号纠错的候选、降级和验证操作同屏可见', (tester) async {
        await pumpRoute(
          tester,
          size: viewport,
          route: AppRoutes.numberedCorrection,
        );

        expectNoVerticalViewport();
        expectVisible(tester, find.text('第87手无法确认'), viewport);
        expectVisible(tester, find.widgetWithText(ChoiceChip, '87'), viewport);
        expectVisible(tester, find.text('提子后同点复用'), viewport);
        expectVisible(tester, find.text('验证手顺并继续'), viewport);
        expectVisible(tester, find.text('无法判断，按当前局面保存'), viewport);
        expect(tester.takeException(), isNull);
      });

      testWidgets('识别结果的限制说明与两个出口同屏可见', (tester) async {
        await pumpRoute(tester, size: viewport, route: AppRoutes.scanResult);

        expectNoVerticalViewport();
        expectVisible(tester, find.text('棋盘识别完成'), viewport);
        expectVisible(tester, find.text('已识别当前局面：黑84子，白82子。'), viewport);
        expectVisible(tester, find.text('分析当前局面'), viewport);
        expectVisible(tester, find.text('保存局面'), viewport);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
