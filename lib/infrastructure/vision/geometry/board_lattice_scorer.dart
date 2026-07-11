import 'dart:math' as math;

import 'package:lizzieyzy_mobile/domain/domain.dart';

enum LatticeScoringErrorCode {
  invalidConfiguration,
  invalidProjection,
  invalidPeak,
}

final class LatticeScoringException implements Exception {
  const LatticeScoringException(this.code, this.message);

  final LatticeScoringErrorCode code;
  final String message;

  @override
  String toString() => 'LatticeScoringException(${code.name}): $message';
}

final class LatticePeak {
  LatticePeak({required this.position, required this.strength}) {
    if (!position.isFinite || position < 0 || position > 1) {
      throw const LatticeScoringException(
        LatticeScoringErrorCode.invalidPeak,
        'Peak position must be finite and normalized to 0…1.',
      );
    }
    if (!strength.isFinite || strength <= 0 || strength > 1) {
      throw const LatticeScoringException(
        LatticeScoringErrorCode.invalidPeak,
        'Peak strength must be finite and normalized to (0, 1].',
      );
    }
  }

  final double position;
  final double strength;
}

/// One-dimensional line evidence, usually produced from the horizontal or
/// vertical projection of a rectified edge-energy image.
final class LatticeAxisEvidence {
  LatticeAxisEvidence(List<LatticePeak> peaks)
    : peaks = List<LatticePeak>.unmodifiable(
        List<LatticePeak>.of(peaks)
          ..sort((left, right) => left.position.compareTo(right.position)),
      ) {
    if (this.peaks.length > maximumPeakCount) {
      throw LatticeScoringException(
        LatticeScoringErrorCode.invalidProjection,
        'Lattice evidence exceeds the $maximumPeakCount-peak search budget.',
      );
    }
    for (var index = 1; index < this.peaks.length; index++) {
      if ((this.peaks[index].position - this.peaks[index - 1].position).abs() <=
          1e-9) {
        throw const LatticeScoringException(
          LatticeScoringErrorCode.invalidPeak,
          'Lattice peaks must have distinct positions.',
        );
      }
    }
  }

  /// Extracts thick line runs from a non-negative projection signal.
  ///
  /// This is deliberately a small deterministic primitive. Edge detection and
  /// perspective rectification remain separate stages, so tests can validate
  /// size scoring without coupling it to a particular corner detector.
  factory LatticeAxisEvidence.fromProjection(
    List<double> projection, {
    double relativeThreshold = 0.28,
    int maxPeaks = 32,
  }) {
    if (projection.length < 3 ||
        projection.length > maximumProjectionSamples ||
        projection.any((value) => !value.isFinite || value < 0)) {
      throw LatticeScoringException(
        LatticeScoringErrorCode.invalidProjection,
        'Projection must contain 3 to $maximumProjectionSamples finite '
        'non-negative samples.',
      );
    }
    if (!relativeThreshold.isFinite ||
        relativeThreshold <= 0 ||
        relativeThreshold >= 1 ||
        maxPeaks < 2 ||
        maxPeaks > maximumPeakCount) {
      throw const LatticeScoringException(
        LatticeScoringErrorCode.invalidConfiguration,
        'Projection threshold and peak budget are invalid.',
      );
    }

    final sorted = List<double>.of(projection)..sort();
    final median = sorted[sorted.length ~/ 2];
    final maximum = sorted.last;
    final contrast = maximum - median;
    if (contrast <= 1e-12) return LatticeAxisEvidence(const <LatticePeak>[]);
    final threshold = median + contrast * relativeThreshold;
    final peaks = <LatticePeak>[];

    var index = 0;
    while (index < projection.length) {
      if (projection[index] < threshold) {
        index++;
        continue;
      }
      var weightedPosition = 0.0;
      var totalWeight = 0.0;
      var runMaximum = projection[index];
      while (index < projection.length && projection[index] >= threshold) {
        final weight = math.max(1e-12, projection[index] - median);
        weightedPosition += index * weight;
        totalWeight += weight;
        runMaximum = math.max(runMaximum, projection[index]);
        index++;
      }
      peaks.add(
        LatticePeak(
          position: (weightedPosition / totalWeight) / (projection.length - 1),
          strength: ((runMaximum - median) / contrast).clamp(1e-12, 1),
        ),
      );
    }

    if (peaks.length > maxPeaks) {
      peaks.sort((left, right) => right.strength.compareTo(left.strength));
      peaks.removeRange(maxPeaks, peaks.length);
    }
    return LatticeAxisEvidence(peaks);
  }

  static const int maximumPeakCount = 64;
  static const int maximumProjectionSamples = 16384;
  final List<LatticePeak> peaks;
}

final class BoardLatticeCandidate {
  const BoardLatticeCandidate({
    required this.boardSize,
    required this.score,
    required this.horizontalScore,
    required this.verticalScore,
  });

  final BoardSize boardSize;

  /// Relative evidence score, not a calibrated probability.
  final double score;
  final double horizontalScore;
  final double verticalScore;
}

final class BoardLatticeResult {
  BoardLatticeResult(List<BoardLatticeCandidate> candidates)
    : candidates = List<BoardLatticeCandidate>.unmodifiable(
        List<BoardLatticeCandidate>.of(candidates)
          ..sort((left, right) => right.score.compareTo(left.score)),
      ) {
    if (this.candidates.isEmpty) {
      throw const LatticeScoringException(
        LatticeScoringErrorCode.invalidConfiguration,
        'At least one board-size candidate is required.',
      );
    }
  }

  final List<BoardLatticeCandidate> candidates;

  BoardLatticeCandidate get best => candidates.first;

  double get margin =>
      candidates.length < 2 ? best.score : best.score - candidates[1].score;

  bool isDecisive({double minimumScore = 0.75, double minimumMargin = 0.08}) {
    if (!minimumScore.isFinite ||
        !minimumMargin.isFinite ||
        minimumScore < 0 ||
        minimumScore > 1 ||
        minimumMargin < 0 ||
        minimumMargin > 1) {
      throw const LatticeScoringException(
        LatticeScoringErrorCode.invalidConfiguration,
        'Decision thresholds must be finite values between zero and one.',
      );
    }
    return best.score >= minimumScore && margin >= minimumMargin;
  }

  BoardSize? decisiveSize({
    double minimumScore = 0.75,
    double minimumMargin = 0.08,
  }) => isDecisive(minimumScore: minimumScore, minimumMargin: minimumMargin)
      ? best.boardSize
      : null;
}

/// Scores whether rectified line evidence is best explained by a 9, 13, or
/// 19-line Go board.
///
/// Every candidate must explain both outer grid lines and as many strong peaks
/// as possible. Unused strong peaks reduce precision, preventing a 19-line
/// board from being mistaken for a sparse 9-line subset.
final class BoardSizeLatticeScorer {
  const BoardSizeLatticeScorer({
    this.matchToleranceInSpacings = 0.2,
    this.minimumGridSpan = 0.45,
  });

  final double matchToleranceInSpacings;
  final double minimumGridSpan;

  BoardLatticeResult score({
    required LatticeAxisEvidence horizontal,
    required LatticeAxisEvidence vertical,
  }) {
    _validateConfiguration();
    return BoardLatticeResult(<BoardLatticeCandidate>[
      for (final boardSize in BoardSize.values)
        _candidate(boardSize, horizontal.peaks, vertical.peaks),
    ]);
  }

  void _validateConfiguration() {
    if (!matchToleranceInSpacings.isFinite ||
        matchToleranceInSpacings <= 0 ||
        matchToleranceInSpacings >= 0.5 ||
        !minimumGridSpan.isFinite ||
        minimumGridSpan <= 0 ||
        minimumGridSpan > 1) {
      throw const LatticeScoringException(
        LatticeScoringErrorCode.invalidConfiguration,
        'Lattice scorer configuration is outside its safe range.',
      );
    }
  }

  BoardLatticeCandidate _candidate(
    BoardSize boardSize,
    List<LatticePeak> horizontal,
    List<LatticePeak> vertical,
  ) {
    final horizontalScore = _scoreAxis(boardSize.dimension, horizontal);
    final verticalScore = _scoreAxis(boardSize.dimension, vertical);
    return BoardLatticeCandidate(
      boardSize: boardSize,
      score: math.sqrt(horizontalScore * verticalScore).clamp(0, 1),
      horizontalScore: horizontalScore,
      verticalScore: verticalScore,
    );
  }

  double _scoreAxis(int dimension, List<LatticePeak> peaks) {
    if (peaks.length < 2) return 0;
    var bestScore = 0.0;
    for (var first = 0; first < peaks.length - 1; first++) {
      for (var last = first + 1; last < peaks.length; last++) {
        final span = peaks[last].position - peaks[first].position;
        if (span < minimumGridSpan) continue;
        final spacing = span / (dimension - 1);
        final tolerance = spacing * matchToleranceInSpacings;
        final used = <int>{};
        var matchedStrength = 0.0;
        var residualInSpacings = 0.0;
        var matched = 0;

        for (var line = 0; line < dimension; line++) {
          final expected = peaks[first].position + spacing * line;
          var nearestIndex = -1;
          var nearestDistance = double.infinity;
          for (var peakIndex = 0; peakIndex < peaks.length; peakIndex++) {
            if (used.contains(peakIndex)) continue;
            final distance = (peaks[peakIndex].position - expected).abs();
            if (distance < nearestDistance) {
              nearestDistance = distance;
              nearestIndex = peakIndex;
            }
          }
          if (nearestIndex < 0 || nearestDistance > tolerance) continue;
          used.add(nearestIndex);
          matched++;
          matchedStrength += peaks[nearestIndex].strength;
          residualInSpacings += nearestDistance / spacing;
        }

        final totalStrength = peaks.fold<double>(
          0,
          (total, peak) => total + peak.strength,
        );
        final coverage = matched / dimension;
        final precision = totalStrength <= 0
            ? 0.0
            : (matchedStrength / totalStrength).clamp(0, 1);
        final regularity = matched == 0
            ? 0.0
            : math.exp(-6 * residualInSpacings / matched);
        final edgeStrength = (peaks[first].strength + peaks[last].strength) / 2;
        final spanScore = span.clamp(0, 1);
        final score =
            0.35 * coverage +
            0.30 * precision +
            0.20 * regularity +
            0.10 * edgeStrength +
            0.05 * spanScore;
        bestScore = math.max(bestScore, score);
      }
    }
    return bestScore.clamp(0, 1);
  }
}
