import 'analysis.dart';
import 'rank_values.dart';

enum GamePhase { opening, middleGame, endgame }

final class KeyMoment {
  const KeyMoment({required this.analysis, required this.severityRank})
    : assert(severityRank >= 1);

  final MoveAnalysis analysis;
  final int severityRank;
}

final class PhaseMetrics {
  const PhaseMetrics({
    required this.phase,
    required this.decisionCount,
    required this.averagePointLoss,
  }) : assert(decisionCount >= 0),
       assert(averagePointLoss >= 0);

  final GamePhase phase;
  final int decisionCount;
  final double averagePointLoss;
}

final class ReviewMetrics {
  ReviewMetrics({
    required this.averagePointLoss,
    required this.medianPointLoss,
    required this.severeMistakeRate,
    required this.topOneRate,
    required this.topThreeRate,
    required this.topFiveRate,
    required List<PhaseMetrics> phases,
  }) : phases = List.unmodifiable(phases) {
    if (!averagePointLoss.isFinite || averagePointLoss < 0) {
      throw ArgumentError.value(averagePointLoss, 'averagePointLoss');
    }
    if (!medianPointLoss.isFinite || medianPointLoss < 0) {
      throw ArgumentError.value(medianPointLoss, 'medianPointLoss');
    }
    for (final rate in [
      severeMistakeRate,
      topOneRate,
      topThreeRate,
      topFiveRate,
    ]) {
      if (!rate.isFinite || rate < 0 || rate > 1) {
        throw RangeError.range(rate, 0, 1, 'rate');
      }
    }
  }

  final double averagePointLoss;
  final double medianPointLoss;
  final double severeMistakeRate;
  final double topOneRate;
  final double topThreeRate;
  final double topFiveRate;
  final List<PhaseMetrics> phases;
}

final class ScorePoint {
  const ScorePoint({
    required this.moveNumber,
    required this.scoreLead,
    required this.blackWinRate,
  }) : assert(moveNumber >= 0),
       assert(blackWinRate >= 0 && blackWinRate <= 1);

  final int moveNumber;
  final double scoreLead;
  final double blackWinRate;
}

final class ReviewReport {
  ReviewReport({
    required this.documentId,
    required this.analysisRequestId,
    required List<KeyMoment> keyMoments,
    required List<ScorePoint> scoreTrend,
    required this.metrics,
  }) : keyMoments = List.unmodifiable(keyMoments),
       scoreTrend = List.unmodifiable(scoreTrend) {
    if (documentId.trim().isEmpty || analysisRequestId.trim().isEmpty) {
      throw ArgumentError('Review ids cannot be empty.');
    }
  }

  final String documentId;
  final String analysisRequestId;
  final List<KeyMoment> keyMoments;
  final List<ScorePoint> scoreTrend;
  final ReviewMetrics metrics;
}

enum PerformanceConfidence { low, medium }

final class PerformanceMetrics {
  const PerformanceMetrics({
    required this.averagePointLoss,
    required this.medianPointLoss,
    required this.topOneRate,
    required this.topThreeRate,
    required this.topFiveRate,
    required this.severeMistakeRate,
    required this.humanStyleLogLikelihood,
  });

  final double averagePointLoss;
  final double medianPointLoss;
  final double topOneRate;
  final double topThreeRate;
  final double topFiveRate;
  final double severeMistakeRate;
  final double humanStyleLogLikelihood;
}

final class GamePerformanceReport {
  GamePerformanceReport({
    required this.weakerBound,
    required this.strongerBound,
    this.coverage = 0.8,
    required this.confidence,
    required this.effectiveDecisions,
    required this.metrics,
    required this.calibrationModelId,
  }) {
    if (weakerBound.compareTo(strongerBound) > 0) {
      throw ArgumentError(
        'The weaker bound cannot be stronger than the upper bound.',
      );
    }
    if (!coverage.isFinite || coverage <= 0 || coverage >= 1) {
      throw RangeError.range(coverage, 0, 1, 'coverage');
    }
    if (effectiveDecisions < 40) {
      throw ArgumentError.value(
        effectiveDecisions,
        'effectiveDecisions',
        'A rank interval requires at least 40 effective decisions.',
      );
    }
    if (calibrationModelId.trim().isEmpty) {
      throw ArgumentError('Calibration model id cannot be empty.');
    }
  }

  final GoRank weakerBound;
  final GoRank strongerBound;
  final double coverage;
  final PerformanceConfidence confidence;
  final int effectiveDecisions;
  final PerformanceMetrics metrics;
  final String calibrationModelId;
}

final class PerformanceModelManifest {
  PerformanceModelManifest({
    required this.id,
    required this.version,
    required this.sha256,
    required this.minimumDecisions,
    required this.minimumRank,
    required this.maximumRank,
  }) {
    if (id.trim().isEmpty || version.trim().isEmpty) {
      throw ArgumentError('Performance model id and version cannot be empty.');
    }
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(sha256)) {
      throw const FormatException(
        'Performance model SHA-256 must be hexadecimal.',
      );
    }
    if (minimumDecisions < 40) {
      throw ArgumentError(
        'Performance models must require at least 40 decisions.',
      );
    }
    if (minimumRank.compareTo(maximumRank) > 0) {
      throw ArgumentError('Performance model rank bounds are reversed.');
    }
  }

  final String id;
  final String version;
  final String sha256;
  final int minimumDecisions;
  final GoRank minimumRank;
  final GoRank maximumRank;
}
