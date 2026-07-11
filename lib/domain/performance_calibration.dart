import 'analysis.dart';
import 'rank_values.dart';
import 'reports.dart';

enum PerformanceFeature {
  averagePointLoss,
  medianPointLoss,
  topOneRate,
  topThreeRate,
  topFiveRate,
  severeMistakeRate,
  humanStyleLogLikelihood,
}

/// A fully explicit linear feature transform used by a calibration artifact.
///
/// A raw value contributes `weight * ((value - center) / scale)` to the
/// calibration score. Feature direction therefore lives in data, not code.
final class CalibrationFeatureWeight {
  const CalibrationFeatureWeight({
    required this.feature,
    required this.weight,
    required this.center,
    required this.scale,
  }) : assert(scale > 0);

  final PerformanceFeature feature;
  final double weight;
  final double center;
  final double scale;

  double contribution(double value) => weight * ((value - center) / scale);
}

/// One contiguous score bucket mapped to a pre-calibrated 80% rank interval.
final class CalibrationBucket {
  CalibrationBucket({
    required this.minimumScore,
    required this.maximumScore,
    required this.weakerBound,
    required this.strongerBound,
  }) {
    if (minimumScore.isNaN || maximumScore.isNaN) {
      throw ArgumentError('Calibration bucket boundaries cannot be NaN.');
    }
    if (minimumScore >= maximumScore) {
      throw ArgumentError('Calibration bucket boundaries are reversed.');
    }
    if (weakerBound.compareTo(strongerBound) > 0) {
      throw ArgumentError('Calibration rank interval is reversed.');
    }
  }

  final double minimumScore;
  final double maximumScore;
  final GoRank weakerBound;
  final GoRank strongerBound;

  bool contains(double score) => score >= minimumScore && score < maximumScore;
}

/// Auditable metadata shipped beside the machine-readable calibration.
final class CalibrationModelCard {
  CalibrationModelCard({
    required this.modelId,
    required this.intendedUse,
    required this.datasetDescription,
    required this.limitations,
    required this.trainingGames,
    required this.heldOutGames,
    required this.distinctPlayers,
  }) {
    if (modelId.trim().isEmpty ||
        intendedUse.trim().isEmpty ||
        datasetDescription.trim().isEmpty ||
        limitations.trim().isEmpty) {
      throw ArgumentError('Calibration model-card fields cannot be empty.');
    }
    if (trainingGames <= 0 || heldOutGames <= 0 || distinctPlayers <= 0) {
      throw ArgumentError('Calibration model-card counts must be positive.');
    }
  }

  final String modelId;
  final String intendedUse;
  final String datasetDescription;
  final String limitations;
  final int trainingGames;
  final int heldOutGames;
  final int distinctPlayers;
}

/// Versioned, manifest-driven calibration input for game-performance reports.
final class GamePerformanceCalibration {
  GamePerformanceCalibration({
    required this.model,
    required this.modelCard,
    required this.intercept,
    required List<CalibrationFeatureWeight> featureWeights,
    required List<CalibrationBucket> buckets,
    required Set<String> allowedAnalysisModelSha256,
    required Set<String> allowedHumanModelSha256,
    required Set<AnalysisProfile> allowedProfiles,
    required this.minimumVisitsPerPosition,
    required this.mediumConfidenceDecisions,
    required this.severeMistakePointLoss,
    required this.policyFloor,
    required this.requiresHumanStyleRanks,
    this.humanStyleProfile,
    this.coverage = 0.8,
  }) : featureWeights = List.unmodifiable(featureWeights),
       buckets = List.unmodifiable(buckets),
       allowedAnalysisModelSha256 = Set.unmodifiable(
         allowedAnalysisModelSha256.map((hash) => hash.toLowerCase()),
       ),
       allowedHumanModelSha256 = Set.unmodifiable(
         allowedHumanModelSha256.map((hash) => hash.toLowerCase()),
       ),
       allowedProfiles = Set.unmodifiable(allowedProfiles) {
    if (modelCard.modelId != model.id) {
      throw ArgumentError(
        'Model card id does not match the performance model.',
      );
    }
    if (!intercept.isFinite) {
      throw ArgumentError.value(intercept, 'intercept');
    }
    if (featureWeights.isEmpty) {
      throw ArgumentError('At least one calibrated feature is required.');
    }
    final features = <PerformanceFeature>{};
    for (final feature in featureWeights) {
      if (!feature.weight.isFinite ||
          !feature.center.isFinite ||
          !feature.scale.isFinite ||
          feature.scale <= 0) {
        throw ArgumentError('Feature transforms must contain finite values.');
      }
      if (!features.add(feature.feature)) {
        throw ArgumentError('Calibration features must be unique.');
      }
    }
    if (allowedAnalysisModelSha256.isEmpty ||
        allowedAnalysisModelSha256.any(
          (hash) => !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(hash),
        )) {
      throw ArgumentError('Allowed analysis models require SHA-256 hashes.');
    }
    if (allowedProfiles.isEmpty ||
        allowedProfiles.contains(AnalysisProfile.quick)) {
      throw ArgumentError(
        'Performance calibration must explicitly use standard/deep analysis.',
      );
    }
    if (minimumVisitsPerPosition <= 0) {
      throw ArgumentError('Minimum visits must be positive.');
    }
    if (mediumConfidenceDecisions < model.minimumDecisions) {
      throw ArgumentError(
        'Medium-confidence threshold cannot be below the model minimum.',
      );
    }
    if (!severeMistakePointLoss.isFinite || severeMistakePointLoss <= 0) {
      throw ArgumentError('Severe-mistake threshold must be positive.');
    }
    if (!policyFloor.isFinite || policyFloor <= 0 || policyFloor > 1) {
      throw RangeError.range(policyFloor, 0, 1, 'policyFloor');
    }
    if (requiresHumanStyleRanks && humanStyleProfile == null) {
      throw ArgumentError(
        'Human-style calibrations must pin the exact HumanSL profile.',
      );
    }
    if (!requiresHumanStyleRanks && humanStyleProfile != null) {
      throw ArgumentError(
        'Generic-policy calibrations cannot declare a HumanSL profile.',
      );
    }
    if (requiresHumanStyleRanks &&
        (allowedHumanModelSha256.isEmpty ||
            allowedHumanModelSha256.any((hash) => !_sha256.hasMatch(hash)))) {
      throw ArgumentError(
        'Human-style calibrations must allowlist HumanSL model SHA-256 values.',
      );
    }
    if (!requiresHumanStyleRanks && allowedHumanModelSha256.isNotEmpty) {
      throw ArgumentError(
        'Generic-policy calibrations cannot allowlist HumanSL models.',
      );
    }
    if (coverage != 0.8) {
      throw ArgumentError('This estimator requires calibrated 80% intervals.');
    }
    _validateBuckets(buckets, model);
  }

  final PerformanceModelManifest model;
  final CalibrationModelCard modelCard;
  final double intercept;
  final List<CalibrationFeatureWeight> featureWeights;
  final List<CalibrationBucket> buckets;
  final Set<String> allowedAnalysisModelSha256;
  final Set<String> allowedHumanModelSha256;
  final Set<AnalysisProfile> allowedProfiles;
  final int minimumVisitsPerPosition;
  final int mediumConfidenceDecisions;
  final double severeMistakePointLoss;
  final double policyFloor;
  final bool requiresHumanStyleRanks;
  final GoRank? humanStyleProfile;
  final double coverage;

  String get calibrationModelId => '${model.id}@${model.version}';

  double score(Map<PerformanceFeature, double> values) {
    var result = intercept;
    for (final transform in featureWeights) {
      final value = values[transform.feature];
      if (value == null || !value.isFinite) {
        throw ArgumentError(
          'Missing finite value for ${transform.feature.name}.',
        );
      }
      result += transform.contribution(value);
    }
    return result;
  }

  CalibrationBucket bucketFor(double score) {
    if (!score.isFinite) {
      throw ArgumentError.value(score, 'score');
    }
    return buckets.firstWhere((bucket) => bucket.contains(score));
  }

  static void _validateBuckets(
    List<CalibrationBucket> buckets,
    PerformanceModelManifest model,
  ) {
    if (buckets.isEmpty ||
        buckets.first.minimumScore != double.negativeInfinity ||
        buckets.last.maximumScore != double.infinity) {
      throw ArgumentError(
        'Calibration buckets must cover negative to positive infinity.',
      );
    }
    for (var index = 0; index < buckets.length; index++) {
      final bucket = buckets[index];
      if (index > 0 && buckets[index - 1].maximumScore != bucket.minimumScore) {
        throw ArgumentError(
          'Calibration buckets must be ordered, contiguous, and non-overlapping.',
        );
      }
      if (bucket.weakerBound.compareTo(model.minimumRank) < 0 ||
          bucket.strongerBound.compareTo(model.maximumRank) > 0) {
        throw ArgumentError('Calibration bucket exceeds model rank bounds.');
      }
    }
  }
}

final RegExp _sha256 = RegExp(r'^[a-fA-F0-9]{64}$');
