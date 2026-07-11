import 'dart:math' as math;

import 'package:lizzieyzy_mobile/domain/domain.dart';

import 'review_input_validator.dart';

final class ReviewBuildPolicy {
  const ReviewBuildPolicy({
    this.maxKeyMoments = 10,
    this.severeMistakePointLoss = 3,
    this.openingEndMoveOn19 = 60,
    this.endgameStartMoveOn19 = 160,
  }) : assert(maxKeyMoments > 0),
       assert(severeMistakePointLoss > 0),
       assert(openingEndMoveOn19 > 0),
       assert(endgameStartMoveOn19 > openingEndMoveOn19);

  final int maxKeyMoments;
  final double severeMistakePointLoss;
  final int openingEndMoveOn19;
  final int endgameStartMoveOn19;

  GamePhase phaseFor(int moveNumber, BoardSize boardSize) {
    final areaScale =
        (boardSize.dimension * boardSize.dimension) / (19.0 * 19.0);
    final openingEnd = math.max(1, (openingEndMoveOn19 * areaScale).round());
    final endgameStart = math.max(
      openingEnd + 1,
      (endgameStartMoveOn19 * areaScale).round(),
    );
    if (moveNumber <= openingEnd) return GamePhase.opening;
    if (moveNumber < endgameStart) return GamePhase.middleGame;
    return GamePhase.endgame;
  }
}

/// Builds a deterministic, numeric-only report from complete game analysis.
final class DefaultReviewBuilder implements ReviewBuilder {
  const DefaultReviewBuilder({this.policy = const ReviewBuildPolicy()});

  final ReviewBuildPolicy policy;

  @override
  ReviewReport build(KifuDocument document, AnalysisBundle analysis) {
    final input = ReviewInputValidator.validate(document, analysis);
    final decisions = input.decisions;
    final losses = decisions.map((decision) => decision.pointLoss).toList();

    final ranked = List<ReviewDecisionEvidence>.of(decisions)
      ..sort((a, b) {
        final lossOrder = b.pointLoss.compareTo(a.pointLoss);
        return lossOrder != 0
            ? lossOrder
            : a.moveNumber.compareTo(b.moveNumber);
      });
    final keyMoments = <KeyMoment>[
      for (
        var index = 0;
        index < ranked.length && index < policy.maxKeyMoments;
        index++
      )
        if (ranked[index].pointLoss > 0)
          KeyMoment(
            playedMove: ranked[index].playedMove,
            before: ranked[index].before,
            after: ranked[index].after,
            candidateRank: ranked[index].candidateRank,
            severityRank: index + 1,
          ),
    ];

    return ReviewReport(
      documentId: input.record.id,
      analysisRequestId: analysis.requestId,
      keyMoments: keyMoments,
      scoreTrend: <ScorePoint>[
        for (final node in analysis.moves)
          ScorePoint(
            moveNumber: node.moveNumber,
            scoreLead: node.scoreLead,
            blackWinRate: node.blackWinRate,
          ),
      ],
      metrics: ReviewMetrics(
        averagePointLoss: _average(losses),
        medianPointLoss: _median(losses),
        severeMistakeRate: _rate(
          decisions
              .where(
                (decision) =>
                    decision.pointLoss >= policy.severeMistakePointLoss,
              )
              .length,
          decisions.length,
        ),
        topOneRate: _topRate(decisions, 1),
        topThreeRate: _topRate(decisions, 3),
        topFiveRate: _topRate(decisions, 5),
        phases: <PhaseMetrics>[
          for (final phase in GamePhase.values) _phaseMetrics(input, phase),
        ],
      ),
    );
  }

  PhaseMetrics _phaseMetrics(ValidatedReviewInput input, GamePhase phase) {
    final decisions = input.decisions
        .where(
          (decision) =>
              policy.phaseFor(decision.moveNumber, input.record.boardSize) ==
              phase,
        )
        .toList();
    return PhaseMetrics(
      phase: phase,
      decisionCount: decisions.length,
      averagePointLoss: _average(
        decisions.map((decision) => decision.pointLoss).toList(),
      ),
    );
  }

  static double _topRate(
    List<ReviewDecisionEvidence> decisions,
    int maximumRank,
  ) {
    final count = decisions
        .where(
          (decision) =>
              decision.candidateRank != null &&
              decision.candidateRank! <= maximumRank,
        )
        .length;
    return _rate(count, decisions.length);
  }

  static double _rate(int numerator, int denominator) {
    return denominator == 0 ? 0 : numerator / denominator;
  }

  static double _average(List<double> values) {
    return values.isEmpty
        ? 0
        : values.reduce((left, right) => left + right) / values.length;
  }

  static double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.of(values)..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }
}
