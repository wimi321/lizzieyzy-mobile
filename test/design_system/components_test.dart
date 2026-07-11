import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';

void main() {
  testWidgets('interactive candidate marker keeps a 48dp touch target', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _harness(
        Center(
          child: CandidateMarker(
            label: 'A',
            detail: '+3.1目',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(CandidateMarker));
    expect(size.height, greaterThanOrEqualTo(GoSizes.minimumTouchTarget));
    expect(size.width, greaterThanOrEqualTo(GoSizes.minimumTouchTarget));
    await tester.tap(find.byType(CandidateMarker));
    expect(tapped, isTrue);
  });

  testWidgets('review tabs expose selection and switch sections', (
    tester,
  ) async {
    ReviewSection? selected;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _harness(
        Align(
          alignment: Alignment.bottomCenter,
          child: ReviewSheet(
            selectedSection: ReviewSection.keyMoves,
            onSectionChanged: (value) => selected = value,
            child: const Text('复盘内容'),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('关键手标签页'), findsOneWidget);
    await tester.tap(find.text('变化'));
    expect(selected, ReviewSection.variations);
    semantics.dispose();
  });

  testWidgets('timeline buttons and slider update the move', (tester) async {
    int? move;
    await tester.pumpWidget(
      _harness(
        Padding(
          padding: const EdgeInsets.all(16),
          child: MoveTimeline(
            currentMove: 87,
            totalMoves: 236,
            keyMoves: const <int>[42, 87, 132],
            onChanged: (value) => move = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('下一手'));
    expect(move, 88);
    expect(find.text('87 / 236'), findsOneWidget);
  });

  testWidgets('analysis progress announces exact progress and controls', (
    tester,
  ) async {
    var paused = false;
    var cancelled = false;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _harness(
        Padding(
          padding: const EdgeInsets.all(16),
          child: AnalysisProgress(
            completed: 142,
            total: 236,
            onPauseResume: () => paused = true,
            onCancel: () => cancelled = true,
          ),
        ),
      ),
    );

    expect(find.text('142 / 236'), findsOneWidget);
    await tester.tap(find.text('暂停'));
    await tester.tap(find.text('取消'));
    expect(paused, isTrue);
    expect(cancelled, isTrue);
    expect(find.bySemanticsLabel(RegExp('标准分析.*142 / 236')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('correction tray uses labelled choices and reports selection', (
    tester,
  ) async {
    CorrectionChoice? selected;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _harness(
        Align(
          alignment: Alignment.bottomCenter,
          child: CorrectionTray(
            pendingCount: 2,
            coordinate: 'Q16',
            onSelected: (choice) => selected = choice,
          ),
        ),
      ),
    );

    await tester.tap(find.text('白'));
    expect(selected, CorrectionChoice.white);
    expect(find.bySemanticsLabel('白棋子'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('data visualizations expose non-visual summaries', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _harness(
        ListView(
          padding: const EdgeInsets.all(16),
          children: const <Widget>[
            ScoreChart(
              samples: <ScoreSample>[
                ScoreSample(move: 0, scoreLead: 0),
                ScoreSample(move: 87, scoreLead: -5.2),
                ScoreSample(move: 120, scoreLead: 3.1),
              ],
              currentMove: 87,
            ),
            SizedBox(height: 16),
            PerformanceBand(
              lowerRank: '3级',
              upperRank: '1级',
              confidenceLabel: '中等置信度',
              effectiveDecisions: 86,
            ),
          ],
        ),
      ),
    );

    expect(find.bySemanticsLabel(RegExp('目差走势.*黑方领先')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('本局发挥估计.*3级.*1级')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('camera overlay provides 56dp auxiliary actions', (tester) async {
    await tester.pumpWidget(
      _harness(
        ScanOverlay(
          status: '棋盘已对齐·保持稳定',
          aligned: true,
          onGallery: () {},
          onCapture: () {},
          onClose: () {},
          child: const ColoredBox(color: Colors.grey),
        ),
      ),
    );

    expect(
      tester.getSize(find.byTooltip('从相册选择')).height,
      greaterThanOrEqualTo(GoSizes.comfortableTouchTarget),
    );
    expect(find.text('棋盘已对齐·保持稳定'), findsOneWidget);
  });

  testWidgets('camera status remains bounded at 200 percent text scaling', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: LizzieTheme.dark(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: ScanOverlay(
            status: '棋盘已对齐·保持稳定',
            aligned: true,
            onGallery: () {},
            onCapture: () {},
            onClose: () {},
            child: const ColoredBox(color: Colors.grey),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('core cards survive 200 percent text scaling in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LizzieTheme.dark(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: const <Widget>[
                KifuCard(
                  blackPlayer: '长名字的黑方棋手',
                  whitePlayer: '长名字的白方棋手',
                  title: '一盘需要认真复盘的测试棋谱',
                  subtitle: '2026-07-11 · 中国规则 · 黑中盘胜',
                  moveCount: 236,
                  status: KifuStatus.analyzed,
                ),
                SizedBox(height: 16),
                PerformanceBand(
                  lowerRank: '3级',
                  upperRank: '1级',
                  confidenceLabel: '中等置信度',
                  effectiveDecisions: 86,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('control-heavy components reflow at 200 percent text scaling', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: LizzieTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                AnalysisProgress(
                  completed: 142,
                  total: 236,
                  onPauseResume: () {},
                  onCancel: () {},
                ),
                const SizedBox(height: 16),
                MoveTimeline(
                  currentMove: 87,
                  totalMoves: 236,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 16),
                ReviewSheet(
                  selectedSection: ReviewSection.keyMoves,
                  onSectionChanged: (_) {},
                  child: const Text('第87手｜Q16→R14｜-5.2目｜-18.4pp'),
                ),
                const SizedBox(height: 16),
                CorrectionTray(
                  pendingCount: 2,
                  coordinate: 'Q16',
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

Widget _harness(Widget child) {
  return MaterialApp(
    theme: LizzieTheme.light(),
    home: Scaffold(body: child),
  );
}
