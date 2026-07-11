import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/features/review/presentation/key_move_review_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/tablet_review_screen.dart';
import 'package:lizzieyzy_mobile/features/scan/presentation/correction_screens.dart';

import '../support/review_screen_fixture.dart';
import 'scan_test_fakes.dart';

void main() {
  Future<void> setView(WidgetTester tester, Size size) async {
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
  }

  testWidgets('棋谱首页只保留棋谱和识谱两个一级入口', (tester) async {
    await setView(tester, const Size(393, 852));
    final controller = ScanCaptureController(
      platform: FakeScanCapturePlatform(),
      vision: FakeBoardVision(),
    );
    await tester.pumpWidget(
      LizzieYzyApp(workspaceController: null, initialRoute: AppRoutes.root),
    );
    await tester.pumpAndSettle();

    expect(find.text('棋谱'), findsWidgets);
    expect(find.text('识谱'), findsOneWidget);
    expect(find.text('拍照识谱'), findsOneWidget);
    expect(find.text('最近棋谱'), findsOneWidget);
    expect(find.text('训练'), findsNothing);
    controller.dispose();
  });

  testWidgets('相机识别结果进入真实实体盘校对', (tester) async {
    await setView(tester, const Size(360, 800));
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
    await tester.pumpWidget(
      MaterialApp(
        theme: LizzieTheme.light(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: HomeShell(scanController: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('识谱'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('拍照'));
    await tester.pumpAndSettle();

    expect(find.text('校对棋盘'), findsOneWidget);
    expect(find.bySemanticsLabel('待确认，2'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('实体棋盘识别校对')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('实体盘校对完成后进入真实识别结果', (tester) async {
    await setView(tester, const Size(393, 852));
    final capture = _capture(
      fakeScanDraft(
        uncertain: <domain.BoardPoint>{
          const domain.BoardPoint(7, 7),
          const domain.BoardPoint(12, 13),
        },
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: LizzieTheme.light(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: PhysicalBoardCorrectionScreen(capture: capture),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('白'));
    await tester.pump();
    await tester.tap(find.text('空'));
    await tester.pump();
    await tester.tap(find.text('确认当前局面'));
    await tester.pumpAndSettle();

    expect(find.text('棋盘识别完成'), findsOneWidget);
    expect(find.textContaining('无法恢复完整手顺'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('编号棋谱低置信手必须人工确认并规则验证', (tester) async {
    await setView(tester, const Size(393, 852));
    final draft = _numberedDraft();
    await tester.pumpWidget(
      MaterialApp(
        theme: LizzieTheme.light(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: NumberedKifuCorrectionScreen(capture: _capture(draft)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('第1手无法确认'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '确认第1手在 D16'));
    await tester.pumpAndSettle();
    expect(find.text('手顺验证完成'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('共2手')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('真实关键手可以打开变化比较再回主线', (tester) async {
    await setView(tester, const Size(393, 852));
    final data = reviewScreenFixture();
    await tester.pumpWidget(
      MaterialApp(
        theme: LizzieTheme.light(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: KeyMoveReviewScreen(data: data),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('变化'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('最佳候选'));
    await tester.pumpAndSettle();

    expect(find.text('变化比较'), findsOneWidget);
    expect(find.textContaining('访问'), findsWidgets);
    expect(
      find.widgetWithText(
        FilledButton,
        '回到主线第${data.primaryMoment!.moveNumber}手',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('1024宽使用真实深色双栏复盘', (tester) async {
    await setView(tester, const Size(1024, 768));
    final data = reviewScreenFixture();
    await tester.pumpWidget(
      MaterialApp(
        theme: LizzieTheme.light(),
        home: TabletReviewScreen(data: data),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tablet-review-inspector')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('平板复盘棋盘')), findsOneWidget);
    for (final tab in <String>['关键手', '变化', '走势', '本局']) {
      expect(find.text(tab), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}

ScanCapturePayload _capture(domain.ScanDraft draft) => ScanCapturePayload(
  draft: draft,
  originalFrame: domain.CapturedFrame(
    encodedBytes: Uint8List.fromList(<int>[1]),
    pixelWidth: 1,
    pixelHeight: 1,
    capturedAt: DateTime.utc(2026, 7, 11),
  ),
  inputKind: ScanInputKind.camera,
  usedBurst: false,
);

domain.ScanDraft _numberedDraft() {
  final black = const domain.BoardPoint(3, 3);
  final white = const domain.BoardPoint(15, 15);
  return domain.ScanDraft(
    kind: domain.ScanKind.numberedDiagram,
    boardSize: domain.BoardSize.nineteen,
    boardBounds: const domain.BoardQuadrilateral(
      topLeft: domain.NormalizedPoint(0.1, 0.1),
      topRight: domain.NormalizedPoint(0.9, 0.1),
      bottomRight: domain.NormalizedPoint(0.9, 0.9),
      bottomLeft: domain.NormalizedPoint(0.1, 0.9),
    ),
    intersections: <domain.IntersectionPrediction>[
      for (var row = 0; row < 19; row++)
        for (var column = 0; column < 19; column++)
          domain.IntersectionPrediction(
            point: domain.BoardPoint(column, row),
            blackProbability: domain.BoardPoint(column, row) == black
                ? 0.98
                : 0.01,
            whiteProbability: domain.BoardPoint(column, row) == white
                ? 0.98
                : 0.01,
            emptyProbability:
                domain.BoardPoint(column, row) == black ||
                    domain.BoardPoint(column, row) == white
                ? 0.01
                : 0.98,
          ),
    ],
    sequenceTokens: const <domain.SequenceToken>[
      domain.SequenceToken(
        moveNumber: 1,
        move: domain.Move.play(
          color: domain.StoneColor.black,
          point: domain.BoardPoint(3, 3),
        ),
        confidence: 0.7,
      ),
      domain.SequenceToken(
        moveNumber: 2,
        move: domain.Move.play(
          color: domain.StoneColor.white,
          point: domain.BoardPoint(15, 15),
        ),
        confidence: 0.99,
      ),
    ],
    boardConfidence: 0.95,
  );
}
