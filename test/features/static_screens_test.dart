import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;

import 'scan_test_fakes.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester, {
    required Size size,
    String initialRoute = AppRoutes.root,
    Widget? home,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      home == null
          ? LizzieYzyApp(initialRoute: initialRoute)
          : MaterialApp(onGenerateRoute: AppRoutes.onGenerateRoute, home: home),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);
  }

  group('一级入口', () {
    testWidgets('393宽棋谱首页只呈现棋谱和识谱两个一级入口', (tester) async {
      final controller = ScanCaptureController(
        platform: FakeScanCapturePlatform(),
        vision: FakeBoardVision(),
      );
      await pumpAt(
        tester,
        size: const Size(393, 852),
        home: HomeShell(scanController: controller),
      );

      expect(find.text('棋谱'), findsWidgets);
      expect(find.text('识谱'), findsOneWidget);
      expect(find.text('拍照识谱'), findsOneWidget);
      expect(find.text('正在分析'), findsOneWidget);
      expect(find.text('最近棋谱'), findsOneWidget);
      expect(find.text('训练'), findsNothing);

      await tester.tap(find.text('识谱'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('相机取景框，十九路棋盘需完整入框'), findsOneWidget);
      expect(find.bySemanticsLabel('拍照'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('360宽相机快门进入实体盘校对', (tester) async {
      final controller = ScanCaptureController(
        platform: FakeScanCapturePlatform(),
        vision: FakeBoardVision(
          result: fakeScanDraft(
            uncertain: <domain.BoardPoint>{
              const domain.BoardPoint(7, 7),
              const domain.BoardPoint(12, 13),
            },
          ),
        ),
      );
      await pumpAt(
        tester,
        size: const Size(360, 800),
        home: HomeShell(scanController: controller),
      );
      await tester.tap(find.text('识谱'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('拍照'));
      await tester.pumpAndSettle();

      expect(find.text('校对棋盘'), findsOneWidget);
      expect(find.text('待确认 2'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('实体棋盘识别校对')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('识谱流程', () {
    testWidgets('实体盘校对可选择棋子状态并进入识别结果', (tester) async {
      await pumpAt(
        tester,
        size: const Size(393, 852),
        initialRoute: AppRoutes.boardCorrection,
      );

      expect(find.text('待确认 2'), findsOneWidget);
      await tester.tap(find.text('白'));
      await tester.pump();
      await tester.tap(find.text('空'));
      await tester.pump();
      expect(find.text('待确认 0'), findsOneWidget);

      await tester.tap(find.text('确认当前局面'));
      await tester.pumpAndSettle();
      expect(find.text('棋盘识别完成'), findsOneWidget);
      expect(
        find.textContaining(RegExp(r'已识别当前局面：黑\d+子，白\d+子。')),
        findsOneWidget,
      );
      expect(find.textContaining('无法恢复完整手顺'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('编号棋谱纠错需要选择数字才能验证手顺', (tester) async {
      await pumpAt(
        tester,
        size: const Size(360, 800),
        initialRoute: AppRoutes.numberedCorrection,
      );

      expect(find.text('第87手无法确认'), findsOneWidget);
      final continueButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '验证手顺并继续'),
      );
      expect(continueButton.onPressed, isNull);

      await tester.tap(find.widgetWithText(ChoiceChip, '87'));
      await tester.pump();
      final enabledButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '验证手顺并继续'),
      );
      expect(enabledButton.onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('复盘流程', () {
    testWidgets('分析进度支持暂停并明确可后台继续', (tester) async {
      await pumpAt(
        tester,
        size: const Size(393, 852),
        initialRoute: AppRoutes.analysisProgress,
      );

      expect(find.text('142 / 236'), findsWidgets);
      expect(find.textContaining('可在后台继续'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '暂停'));
      await tester.pump();
      expect(find.text('已暂停'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '继续'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('393宽关键手可以打开变化比较再回到主线', (tester) async {
      await pumpAt(
        tester,
        size: const Size(393, 852),
        initialRoute: AppRoutes.keyMoveReview,
      );

      expect(find.bySemanticsLabel(RegExp('第87手复盘棋盘')), findsOneWidget);
      expect(find.text('-5.2目'), findsWidgets);
      await tester.ensureVisible(find.text('R14 · 最佳候选'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('R14 · 最佳候选'));
      await tester.pumpAndSettle();

      expect(find.text('变化比较'), findsOneWidget);
      expect(find.text('R14'), findsWidgets);
      expect(find.textContaining('12,840'), findsOneWidget);
      await tester.fling(
        find.byKey(const Key('variation-comparison-scroll')),
        const Offset(0, -900),
        2000,
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, '回到主线第87手'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('单局棋力只显示区间、置信度和可验证指标', (tester) async {
      await pumpAt(
        tester,
        size: const Size(393, 852),
        initialRoute: AppRoutes.gamePerformance,
      );

      expect(find.text('3级–1级'), findsOneWidget);
      expect(find.text('中等置信度'), findsOneWidget);
      expect(find.text('86 个有效决策'), findsOneWidget);
      expect(find.text('平均目损'), findsOneWidget);
      expect(find.textContaining('不是长期棋力'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1024宽自动使用深色双栏复盘', (tester) async {
      await pumpAt(
        tester,
        size: const Size(1024, 768),
        initialRoute: AppRoutes.keyMoveReview,
      );

      expect(find.byKey(const Key('tablet-review-inspector')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('平板复盘棋盘')), findsOneWidget);
      expect(find.text('第87手'), findsWidgets);
      expect(find.text('关键手'), findsOneWidget);
      expect(find.text('变化'), findsOneWidget);
      expect(find.text('走势'), findsOneWidget);
      expect(find.text('本局'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
