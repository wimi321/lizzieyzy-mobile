import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/review/review.dart';

import 'review_test_fixtures.dart';

void main() {
  group('DefaultReviewBuilder input trust boundary', () {
    const builder = DefaultReviewBuilder();

    test('accepts only a complete verified game', () {
      final fixture = reviewFixture(moveCount: 4);
      final snapshot = PositionSnapshot(
        id: fixture.record.id,
        position: BoardPosition.empty(BoardSize.nineteen),
        rules: const GoRules.chinese(),
        source: const KifuSource(kind: KifuSourceKind.fixture),
      );

      expect(
        () => builder.build(snapshot, fixture.analysis),
        _throwsReviewInput(ReviewInputErrorCode.unsupportedDocument),
      );
    });

    test('rejects analysis for a different document id', () {
      final fixture = reviewFixture(moveCount: 4);

      expect(
        () => builder.build(
          fixture.record,
          copyAnalysis(fixture.analysis, documentId: 'another-game'),
        ),
        _throwsReviewInput(ReviewInputErrorCode.documentIdMismatch),
      );
    });

    test('rejects analysis for a different board size', () {
      final fixture = reviewFixture(moveCount: 4);

      expect(
        () => builder.build(
          fixture.record,
          copyAnalysis(fixture.analysis, boardSize: BoardSize.thirteen),
        ),
        _throwsReviewInput(ReviewInputErrorCode.boardSizeMismatch),
      );
    });

    test('requires every position from root through the final move', () {
      final fixture = reviewFixture(moveCount: 4);

      expect(
        () => builder.build(
          fixture.record,
          copyAnalysis(
            fixture.analysis,
            moves: fixture.analysis.moves.sublist(
              0,
              fixture.analysis.moves.length - 1,
            ),
          ),
        ),
        _throwsReviewInput(ReviewInputErrorCode.incompleteAnalysis),
      );
    });

    test(
      'requires analyzed moves and turns to match the verified sequence',
      () {
        final fixture = reviewFixture(moveCount: 4);
        final wrongMove = copyMoveAnalysis(
          fixture.analysis.moves[1],
          playedMove: const Move.play(
            color: StoneColor.black,
            point: BoardPoint(18, 18),
          ),
          replacePlayedMove: true,
        );
        final wrongTurn = copyMoveAnalysis(
          fixture.analysis.moves[0],
          toPlay: StoneColor.white,
        );

        expect(
          () => builder.build(
            fixture.record,
            _withNode(fixture.analysis, 1, wrongMove),
          ),
          _throwsReviewInput(ReviewInputErrorCode.moveMismatch),
        );
        expect(
          () => builder.build(
            fixture.record,
            _withNode(fixture.analysis, 0, wrongTurn),
          ),
          _throwsReviewInput(ReviewInputErrorCode.turnMismatch),
        );
      },
    );

    test('requires configured visits at every analyzed position', () {
      final fixture = reviewFixture(moveCount: 4);
      final underVisited = copyMoveAnalysis(
        fixture.analysis.moves[2],
        visits: fixture.analysis.settings.visitsPerMove - 1,
      );

      expect(
        () => builder.build(
          fixture.record,
          _withNode(fixture.analysis, 2, underVisited),
        ),
        _throwsReviewInput(ReviewInputErrorCode.insufficientVisits),
      );
    });

    test('requires root candidates and one point-loss value per decision', () {
      final fixture = reviewFixture(moveCount: 4);
      final noRootCandidates = copyMoveAnalysis(
        fixture.analysis.moves[0],
        candidates: const <Candidate>[],
      );
      final missingLoss = copyMoveAnalysis(
        fixture.analysis.moves[2],
        removePointLoss: true,
      );
      final missingPolicy = copyMoveAnalysis(
        fixture.analysis.moves[2],
        removePlayedMovePolicy: true,
      );
      final rootWithLoss = copyMoveAnalysis(
        fixture.analysis.moves[0],
        pointLoss: 1,
      );

      for (final node in [
        noRootCandidates,
        missingLoss,
        missingPolicy,
        rootWithLoss,
      ]) {
        expect(
          () => builder.build(
            fixture.record,
            _withNode(fixture.analysis, node.moveNumber, node),
          ),
          _throwsReviewInput(ReviewInputErrorCode.incompleteAnalysis),
        );
      }
    });

    test('rejects wrong-color, out-of-board, and duplicate candidates', () {
      final fixture = reviewFixture(moveCount: 4);
      final root = fixture.analysis.moves.first;
      final first = root.candidates.first;
      final second = root.candidates[1];
      final wrongColor = _replaceCandidates(root, <Candidate>[
        copyCandidate(
          first,
          move: Move.play(
            color: first.move.color.opponent,
            point: first.move.point!,
          ),
        ),
        ...root.candidates.skip(1),
      ]);
      final outside = _replaceCandidates(root, <Candidate>[
        copyCandidate(
          first,
          move: const Move.play(
            color: StoneColor.black,
            point: BoardPoint(19, 0),
          ),
        ),
        ...root.candidates.skip(1),
      ]);
      final duplicate = _replaceCandidates(root, <Candidate>[
        first,
        copyCandidate(second, move: first.move),
        ...root.candidates.skip(2),
      ]);

      for (final node in [wrongColor, outside, duplicate]) {
        expect(
          () => builder.build(
            fixture.record,
            _withNode(fixture.analysis, 0, node),
          ),
          _throwsReviewInput(ReviewInputErrorCode.invalidCandidates),
        );
      }
    });

    test('rejects excess candidates and non-reproducible visit ranking', () {
      final fixture = reviewFixture(moveCount: 4);
      final root = fixture.analysis.moves.first;
      final tooMany = _replaceCandidates(root, <Candidate>[
        ...root.candidates,
        Candidate(
          move: const Move.pass(color: StoneColor.black),
          winRate: 0.4,
          scoreLead: 0,
          visits: 0,
          policy: 0.01,
        ),
      ]);
      final abovePositionVisits = _replaceCandidates(root, <Candidate>[
        copyCandidate(root.candidates.first, visits: root.visits + 1),
        ...root.candidates.skip(1),
      ]);
      final unordered = _replaceCandidates(root, <Candidate>[
        root.candidates[1],
        root.candidates[0],
        ...root.candidates.skip(2),
      ]);

      for (final node in [tooMany, abovePositionVisits, unordered]) {
        expect(
          () => builder.build(
            fixture.record,
            _withNode(fixture.analysis, 0, node),
          ),
          _throwsReviewInput(ReviewInputErrorCode.invalidCandidates),
        );
      }
    });

    test('rejects an occupied candidate even when no PV is supplied', () {
      final fixture = reviewFixture(moveCount: 4);
      final node = fixture.analysis.moves[1];
      final occupied = copyCandidate(
        node.candidates.first,
        move: Move.play(
          color: StoneColor.white,
          point: fixture.record.moves.first.point!,
        ),
      );
      final replacement = _replaceCandidates(node, <Candidate>[
        occupied,
        ...node.candidates.skip(1),
      ]);

      expect(
        () => builder.build(
          fixture.record,
          _withNode(fixture.analysis, 1, replacement),
        ),
        _throwsReviewInput(ReviewInputErrorCode.invalidCandidates),
      );
    });
  });

  group('DefaultReviewBuilder numeric report', () {
    const builder = DefaultReviewBuilder(
      policy: ReviewBuildPolicy(
        maxKeyMoments: 4,
        severeMistakePointLoss: 3,
        openingEndMoveOn19: 2,
        endgameStartMoveOn19: 5,
      ),
    );

    test('sorts key moments by loss then move number and drops zero loss', () {
      final fixture = _metricsFixture();

      final report = builder.build(fixture.record, fixture.analysis);

      expect(
        report.keyMoments.map((moment) => moment.moveNumber),
        orderedEquals(<int>[1, 3, 6, 5]),
      );
      expect(
        report.keyMoments.map((moment) => moment.severityRank),
        orderedEquals(<int>[1, 2, 3, 4]),
      );
      expect(
        report.keyMoments.map((moment) => moment.after.playedMovePointLoss),
        orderedEquals(<double>[4, 4, 3, 2]),
      );
      for (final moment in report.keyMoments) {
        expect(moment.before.moveNumber + 1, moment.after.moveNumber);
        expect(moment.playedMove, moment.after.playedMove);
      }
      expect(report.keyMoments.first.candidateRank, 1);
    });

    test('retains before/after evidence when the played move is unlisted', () {
      final fixture = reviewFixture(
        moveCount: 4,
        candidateRankForMove: (_) => 6,
        pointLossForMove: (moveNumber) => moveNumber.toDouble(),
      );

      final moment = builder
          .build(fixture.record, fixture.analysis)
          .keyMoments
          .first;

      expect(moment.moveNumber, 4);
      expect(moment.candidateRank, isNull);
      expect(moment.before.moveNumber, 3);
      expect(moment.after.moveNumber, 4);
      expect(moment.playedMove, fixture.record.moves[3]);
      expect(
        moment.before.candidates.map((candidate) => candidate.move),
        isNot(contains(moment.playedMove)),
      );
    });

    test('computes loss, severe-error, and candidate hit rates exactly', () {
      final fixture = _metricsFixture();

      final metrics = builder.build(fixture.record, fixture.analysis).metrics;

      expect(metrics.averagePointLoss, closeTo(14 / 6, 1e-12));
      expect(metrics.medianPointLoss, 2.5);
      expect(metrics.severeMistakeRate, 0.5);
      expect(metrics.topOneRate, closeTo(1 / 6, 1e-12));
      expect(metrics.topThreeRate, 0.5);
      expect(metrics.topFiveRate, closeTo(5 / 6, 1e-12));
    });

    test('splits opening, middle game, and endgame deterministically', () {
      final fixture = _metricsFixture();

      final phases = builder
          .build(fixture.record, fixture.analysis)
          .metrics
          .phases;

      expect(phases.map((phase) => phase.phase), GamePhase.values);
      expect(phases.map((phase) => phase.decisionCount), <int>[2, 2, 2]);
      expect(phases.map((phase) => phase.averagePointLoss), <double>[
        2.5,
        2,
        2.5,
      ]);
    });

    test('preserves ids and the complete numeric score trend', () {
      final fixture = _metricsFixture();

      final report = builder.build(fixture.record, fixture.analysis);

      expect(report.documentId, fixture.record.id);
      expect(report.analysisRequestId, fixture.analysis.requestId);
      expect(report.scoreTrend, hasLength(fixture.record.moves.length + 1));
      expect(
        report.scoreTrend.map((point) => point.moveNumber),
        orderedEquals(<int>[0, 1, 2, 3, 4, 5, 6]),
      );
      expect(report.scoreTrend.first.scoreLead, -5);
      expect(report.scoreTrend.last.blackWinRate, 0.51);
    });

    test('returns identical numeric output for identical immutable input', () {
      final fixture = _metricsFixture();

      final first = _reviewSnapshot(
        builder.build(fixture.record, fixture.analysis),
      );
      final second = _reviewSnapshot(
        builder.build(fixture.record, fixture.analysis),
      );

      expect(second, first);
    });
  });
}

ReviewFixture _metricsFixture() {
  const losses = <int, double>{1: 4, 2: 1, 3: 4, 4: 0, 5: 2, 6: 3};
  return reviewFixture(
    moveCount: 6,
    candidateRankForMove: (moveNumber) => moveNumber,
    pointLossForMove: (moveNumber) => losses[moveNumber]!,
  );
}

AnalysisBundle _withNode(
  AnalysisBundle analysis,
  int index,
  MoveAnalysis replacement,
) {
  final moves = List<MoveAnalysis>.of(analysis.moves);
  moves[index] = replacement;
  return copyAnalysis(analysis, moves: moves);
}

MoveAnalysis _replaceCandidates(
  MoveAnalysis analysis,
  List<Candidate> candidates,
) => copyMoveAnalysis(analysis, candidates: candidates);

Matcher _throwsReviewInput(ReviewInputErrorCode code) => throwsA(
  isA<ReviewInputException>().having(
    (exception) => exception.code,
    'code',
    code,
  ),
);

List<Object> _reviewSnapshot(ReviewReport report) => <Object>[
  report.documentId,
  report.analysisRequestId,
  for (final moment in report.keyMoments)
    '${moment.severityRank}:${moment.moveNumber}:'
        '${moment.after.playedMovePointLoss}:${moment.candidateRank}',
  for (final point in report.scoreTrend)
    '${point.moveNumber}:${point.scoreLead}:${point.blackWinRate}',
  report.metrics.averagePointLoss,
  report.metrics.medianPointLoss,
  report.metrics.severeMistakeRate,
  report.metrics.topOneRate,
  report.metrics.topThreeRate,
  report.metrics.topFiveRate,
  for (final phase in report.metrics.phases)
    '${phase.phase.name}:${phase.decisionCount}:${phase.averagePointLoss}',
];
