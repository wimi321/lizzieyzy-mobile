import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app_routes.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/review_screen_data.dart';

import '../infrastructure/review/review_test_fixtures.dart';
import '../support/review_screen_fixture.dart';

void main() {
  test('document routes preserve the three trust types', () {
    final verified = reviewScreenFixture().record;
    final partial = PartialGameRecord(
      id: 'partial',
      initialPosition: BoardPosition.empty(BoardSize.nineteen),
      moves: const <Move>[
        Move.play(color: StoneColor.white, point: BoardPoint(3, 3)),
      ],
      rules: const GoRules.chinese(),
      source: const KifuSource(kind: KifuSourceKind.localFile),
      startingMoveNumber: 88,
      firstPlayer: StoneColor.white,
    );
    final snapshot = PositionSnapshot(
      id: 'snapshot',
      position: BoardPosition.empty(BoardSize.nineteen),
      rules: const GoRules.chinese(),
      source: const KifuSource(kind: KifuSourceKind.camera),
    );

    expect(AppRoutes.routeForDocument(verified), AppRoutes.analysisProgress);
    expect(AppRoutes.routeForDocument(snapshot), AppRoutes.analysisProgress);
    expect(AppRoutes.routeForDocument(partial), AppRoutes.partialRecord);
  });

  test('review data rejects analysis from a different board geometry', () {
    final data = reviewScreenFixture(id: 'geometry', moveCount: 4);
    final wrongBoard = copyAnalysis(
      data.analysis,
      boardSize: BoardSize.thirteen,
    );

    expect(
      () => ReviewScreenData(
        record: data.record,
        analysis: wrongBoard,
        report: data.report,
      ),
      throwsArgumentError,
    );
  });

  test('review move selection rejects an out-of-range route argument', () {
    final data = reviewScreenFixture(moveCount: 4);

    expect(
      () => ReviewMoveSelection(data: data, moveNumber: 0),
      throwsRangeError,
    );
    expect(
      () => ReviewMoveSelection(data: data, moveNumber: 5),
      throwsRangeError,
    );
  });

  test('position analysis requires a known player and matching root', () {
    final valid = positionScreenFixture();
    final unknownPlayer = PositionSnapshot(
      id: valid.snapshot.id,
      position: valid.snapshot.position,
      rules: valid.snapshot.rules,
      source: valid.snapshot.source,
    );

    expect(
      () => PositionAnalysisData(
        snapshot: unknownPlayer,
        analysis: valid.analysis,
      ),
      throwsArgumentError,
    );
  });

  testWidgets('performance route receives the session-produced report', (
    tester,
  ) async {
    final base = reviewScreenFixture();
    final report = performanceScreenFixture(base);
    final data = ReviewScreenData(
      record: base.record,
      analysis: base.analysis,
      report: base.report,
      performanceReport: report,
    );
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.gamePerformance,
              arguments: data,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('本局'), findsOneWidget);
    expect(find.textContaining('80% 区间'), findsOneWidget);
    expect(find.text('暂不显示棋力区间'), findsNothing);
  });
}
