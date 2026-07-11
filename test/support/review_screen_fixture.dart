import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/review_screen_data.dart';
import 'package:lizzieyzy_mobile/infrastructure/review/review.dart';

import '../infrastructure/review/review_test_fixtures.dart';

ReviewScreenData reviewScreenFixture({
  String id = 'screen-review',
  int moveCount = 90,
}) {
  final fixture = reviewFixture(
    documentId: id,
    moveCount: moveCount,
    metadata: GameMetadata(
      blackPlayer: '山海一局',
      whitePlayer: '清风入弦',
      playedAt: DateTime.utc(2026, 7, 11, 8, 6),
      result: const GameResult(type: ResultType.whiteWin, margin: 3.5),
    ),
    candidateRankForMove: (moveNumber) =>
        moveNumber == 87 ? 4 : (moveNumber % 5) + 1,
    pointLossForMove: (moveNumber) =>
        moveNumber == 87 ? 5.2 : (moveNumber % 7) * 0.45,
    principalVariationMoveNumber: 87,
  );
  return ReviewScreenData(
    record: fixture.record,
    analysis: fixture.analysis,
    report: const DefaultReviewBuilder().build(
      fixture.record,
      fixture.analysis,
    ),
  );
}

PositionAnalysisData positionScreenFixture({String id = 'screen-position'}) {
  final snapshot = PositionSnapshot(
    id: id,
    position: BoardPosition(
      size: BoardSize.nineteen,
      stones: <BoardPoint, StoneColor>{
        const BoardPoint(3, 3): StoneColor.black,
        const BoardPoint(15, 15): StoneColor.white,
        const BoardPoint(15, 3): StoneColor.black,
        const BoardPoint(3, 15): StoneColor.white,
      },
    ),
    playerToMove: StoneColor.black,
    rules: const GoRules.chinese(),
    source: const KifuSource(kind: KifuSourceKind.fixture),
  );
  final model = analysisModelFixture();
  return PositionAnalysisData(
    snapshot: snapshot,
    analysis: AnalysisBundle(
      requestId: 'analysis-$id',
      documentId: id,
      boardSize: BoardSize.nineteen,
      model: model,
      settings: const AnalysisSettings(
        profile: AnalysisProfile.standard,
        visitsPerMove: 1000,
      ),
      moves: <MoveAnalysis>[
        MoveAnalysis(
          moveNumber: 0,
          toPlay: StoneColor.black,
          playedMove: null,
          blackWinRate: 0.578,
          scoreLead: 3.1,
          visits: 12840,
          candidates: <Candidate>[
            Candidate(
              move: const Move.play(
                color: StoneColor.black,
                point: BoardPoint(16, 5),
              ),
              winRate: 0.578,
              scoreLead: 3.1,
              visits: 12840,
              policy: 0.22,
              principalVariation: const <Move>[
                Move.play(color: StoneColor.black, point: BoardPoint(16, 5)),
                Move.play(color: StoneColor.white, point: BoardPoint(16, 6)),
              ],
            ),
            Candidate(
              move: const Move.play(
                color: StoneColor.black,
                point: BoardPoint(15, 5),
              ),
              winRate: 0.551,
              scoreLead: 1.4,
              visits: 7226,
              policy: 0.13,
            ),
            Candidate(
              move: const Move.play(
                color: StoneColor.black,
                point: BoardPoint(13, 3),
              ),
              winRate: 0.536,
              scoreLead: 0.6,
              visits: 4908,
              policy: 0.08,
            ),
          ],
        ),
      ],
      completedAt: DateTime.utc(2026, 7, 11),
    ),
  );
}

GamePerformanceReport performanceScreenFixture(ReviewScreenData review) =>
    CalibratedGamePerformanceEstimator(
      calibration: calibrationFixture(),
    ).estimate(review.record, review.analysis, review.analysis.model);
