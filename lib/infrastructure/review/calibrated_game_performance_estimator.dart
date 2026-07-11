import 'dart:math' as math;

import 'package:lizzieyzy_mobile/domain/domain.dart';

import 'review_input_validator.dart';

enum PerformanceEstimationErrorCode {
  unsupportedBoard,
  handicapOrSetupGame,
  disallowedAnalysisProfile,
  insufficientAnalysisQuality,
  analysisModelMismatch,
  uncalibratedAnalysisModel,
  uncalibratedHumanModel,
  missingHumanStyleModel,
  insufficientDecisions,
}

final class PerformanceEstimationException implements Exception {
  const PerformanceEstimationException(this.code, this.message);

  final PerformanceEstimationErrorCode code;
  final String message;

  @override
  String toString() => 'PerformanceEstimationException(${code.name}): $message';
}

/// Applies an explicit, versioned calibration artifact to numeric review data.
final class CalibratedGamePerformanceEstimator
    implements GamePerformanceEstimator {
  const CalibratedGamePerformanceEstimator({required this.calibration});

  final GamePerformanceCalibration calibration;

  @override
  GamePerformanceReport estimate(
    VerifiedGameRecord record,
    AnalysisBundle analysis,
    ModelManifest manifest,
  ) {
    if (record.boardSize != BoardSize.nineteen) {
      throw const PerformanceEstimationException(
        PerformanceEstimationErrorCode.unsupportedBoard,
        'Performance intervals are calibrated only for 19-line games.',
      );
    }
    if (record.initialPosition.stones.isNotEmpty ||
        record.firstPlayer != StoneColor.black) {
      throw const PerformanceEstimationException(
        PerformanceEstimationErrorCode.handicapOrSetupGame,
        'Handicap and setup-position games are outside calibration scope.',
      );
    }
    if (!calibration.allowedProfiles.contains(analysis.settings.profile)) {
      throw PerformanceEstimationException(
        PerformanceEstimationErrorCode.disallowedAnalysisProfile,
        'Profile ${analysis.settings.profile.name} is not calibrated.',
      );
    }
    if (analysis.settings.visitsPerMove <
        calibration.minimumVisitsPerPosition) {
      throw PerformanceEstimationException(
        PerformanceEstimationErrorCode.insufficientAnalysisQuality,
        'Analysis settings are below the calibration visit floor.',
      );
    }
    if (!_sameModel(manifest, analysis.model)) {
      throw const PerformanceEstimationException(
        PerformanceEstimationErrorCode.analysisModelMismatch,
        'The supplied model manifest does not match the analysis bundle.',
      );
    }
    if (!calibration.allowedAnalysisModelSha256.contains(
      manifest.sha256.toLowerCase(),
    )) {
      throw const PerformanceEstimationException(
        PerformanceEstimationErrorCode.uncalibratedAnalysisModel,
        'The analysis model hash is not included in this calibration.',
      );
    }
    if (calibration.requiresHumanStyleRanks &&
        manifest.humanStyleRanks.isEmpty) {
      throw const PerformanceEstimationException(
        PerformanceEstimationErrorCode.missingHumanStyleModel,
        'This calibration requires a human-style policy model.',
      );
    }
    final humanProfile = calibration.humanStyleProfile;
    if (humanProfile != null &&
        !manifest.humanStyleRanks.contains(humanProfile)) {
      throw const PerformanceEstimationException(
        PerformanceEstimationErrorCode.missingHumanStyleModel,
        'The analysis manifest does not provide the calibrated HumanSL profile.',
      );
    }
    if (calibration.requiresHumanStyleRanks) {
      final humanModelHash = manifest.humanModelSha256?.toLowerCase();
      if (humanModelHash == null ||
          !calibration.allowedHumanModelSha256.contains(humanModelHash)) {
        throw const PerformanceEstimationException(
          PerformanceEstimationErrorCode.uncalibratedHumanModel,
          'The HumanSL model hash is not included in this calibration.',
        );
      }
    }

    if (analysis.moves.any(
      (node) => node.visits < calibration.minimumVisitsPerPosition,
    )) {
      throw const PerformanceEstimationException(
        PerformanceEstimationErrorCode.insufficientAnalysisQuality,
        'At least one analyzed position is below the calibration visit floor.',
      );
    }
    final input = ReviewInputValidator.validateVerified(record, analysis);
    final effective = input.decisions
        .where((decision) => !decision.playedMove.isPass)
        .toList();
    final minimumDecisions = calibration.model.minimumDecisions;
    if (effective.length < minimumDecisions) {
      throw PerformanceEstimationException(
        PerformanceEstimationErrorCode.insufficientDecisions,
        '${effective.length} effective decisions; $minimumDecisions required.',
      );
    }

    final humanStyleLogLikelihood = _meanPlayedPolicyLogLikelihood(effective);
    final metrics = PerformanceMetrics(
      averagePointLoss: _averagePointLoss(effective),
      medianPointLoss: _medianPointLoss(effective),
      topOneRate: _topRate(effective, 1),
      topThreeRate: _topRate(effective, 3),
      topFiveRate: _topRate(effective, 5),
      severeMistakeRate: _rate(
        effective
            .where(
              (decision) =>
                  decision.pointLoss >= calibration.severeMistakePointLoss,
            )
            .length,
        effective.length,
      ),
      humanStyleLogLikelihood: humanStyleLogLikelihood,
    );
    final score = calibration.score(<PerformanceFeature, double>{
      PerformanceFeature.averagePointLoss: metrics.averagePointLoss,
      PerformanceFeature.medianPointLoss: metrics.medianPointLoss,
      PerformanceFeature.topOneRate: metrics.topOneRate,
      PerformanceFeature.topThreeRate: metrics.topThreeRate,
      PerformanceFeature.topFiveRate: metrics.topFiveRate,
      PerformanceFeature.severeMistakeRate: metrics.severeMistakeRate,
      PerformanceFeature.humanStyleLogLikelihood:
          metrics.humanStyleLogLikelihood,
    });
    final bucket = calibration.bucketFor(score);

    return GamePerformanceReport(
      weakerBound: bucket.weakerBound,
      strongerBound: bucket.strongerBound,
      coverage: calibration.coverage,
      confidence: effective.length >= calibration.mediumConfidenceDecisions
          ? PerformanceConfidence.medium
          : PerformanceConfidence.low,
      effectiveDecisions: effective.length,
      metrics: metrics,
      calibrationModelId: calibration.calibrationModelId,
    );
  }

  double _meanPlayedPolicyLogLikelihood(
    List<ReviewDecisionEvidence> decisions,
  ) {
    var total = 0.0;
    for (final decision in decisions) {
      final rawPolicy = calibration.requiresHumanStyleRanks
          ? decision.after.playedMoveHumanPolicy
          : decision.after.playedMovePolicy;
      if (rawPolicy == null) {
        throw const PerformanceEstimationException(
          PerformanceEstimationErrorCode.missingHumanStyleModel,
          'Calibrated played-move policy evidence is missing.',
        );
      }
      final policy = math.max(calibration.policyFloor, rawPolicy);
      total += math.log(policy);
    }
    return total / decisions.length;
  }

  static double _averagePointLoss(List<ReviewDecisionEvidence> decisions) {
    return decisions.fold<double>(
          0,
          (total, decision) => total + decision.pointLoss,
        ) /
        decisions.length;
  }

  static double _medianPointLoss(List<ReviewDecisionEvidence> decisions) {
    final losses = decisions.map((decision) => decision.pointLoss).toList()
      ..sort();
    final middle = losses.length ~/ 2;
    return losses.length.isOdd
        ? losses[middle]
        : (losses[middle - 1] + losses[middle]) / 2;
  }

  static double _topRate(
    List<ReviewDecisionEvidence> decisions,
    int maximumRank,
  ) {
    return _rate(
      decisions
          .where(
            (decision) =>
                decision.candidateRank != null &&
                decision.candidateRank! <= maximumRank,
          )
          .length,
      decisions.length,
    );
  }

  static double _rate(int numerator, int denominator) =>
      numerator / denominator;

  static bool _sameModel(ModelManifest left, ModelManifest right) {
    return left.id == right.id &&
        left.sha256.toLowerCase() == right.sha256.toLowerCase() &&
        left.humanModelSha256?.toLowerCase() ==
            right.humanModelSha256?.toLowerCase() &&
        left.engineVersion == right.engineVersion &&
        left.modelVersion == right.modelVersion &&
        _sameRanks(left.humanStyleRanks, right.humanStyleRanks);
  }

  static bool _sameRanks(List<GoRank> left, List<GoRank> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
