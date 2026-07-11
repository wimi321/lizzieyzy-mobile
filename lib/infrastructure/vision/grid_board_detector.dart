import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:lizzieyzy_mobile/domain/domain.dart';

import 'bounded_image_pipeline.dart';
import 'geometry/geometry.dart';

enum GridDetectionErrorCode {
  insufficientEdges,
  missingLineFamilies,
  noConvexCandidate,
  insufficientLatticeEvidence,
  ambiguousGeometry,
}

final class GridDetectionException implements Exception {
  const GridDetectionException(this.code, this.message);

  final GridDetectionErrorCode code;
  final String message;

  @override
  String toString() => 'GridDetectionException(${code.name}): $message';
}

final class DetectedBoardGeometry {
  const DetectedBoardGeometry({
    required this.bounds,
    required this.boardSize,
    required this.score,
    required this.boardSizeMargin,
    required this.lineSupport,
  });

  final BoardQuadrilateral bounds;
  final BoardSize boardSize;

  /// Relative deterministic evidence, not a calibrated probability.
  final double score;
  final double boardSizeMargin;
  final double lineSupport;

  List<ProjectivePoint> pixelCorners(int width, int height) =>
      <ProjectivePoint>[
        for (final point in bounds.vertices)
          ProjectivePoint(point.x * (width - 1), point.y * (height - 1)),
      ];
}

/// Classical bounded grid detector used by [AutomaticBoardVision].
///
/// It detects two line families with a finite Hough accumulator, builds a
/// bounded number of convex outer-line quadrilaterals, rectifies each candidate,
/// and accepts only a decisive 9/13/19 lattice score.
final class ClassicalGridBoardDetector {
  const ClassicalGridBoardDetector({
    this.maxAnalysisSide = 640,
    this.maxAnalysisPixels = 400000,
    this.thetaBins = 180,
    this.rhoResolution = 2,
    this.maxHoughLines = 128,
    this.maxPairsPerFamily = 10,
    this.candidateWarpSide = 192,
    this.minimumLatticeScore = 0.72,
    this.minimumBoardSizeMargin = 0.03,
    this.minimumGeometryScore = 0.75,
    this.minimumGeometryMargin = 0.002,
  });

  final int maxAnalysisSide;
  final int maxAnalysisPixels;
  final int thetaBins;
  final double rhoResolution;
  final int maxHoughLines;
  final int maxPairsPerFamily;
  final int candidateWarpSide;
  final double minimumLatticeScore;
  final double minimumBoardSizeMargin;
  final double minimumGeometryScore;
  final double minimumGeometryMargin;

  DetectedBoardGeometry detect(img.Image image) {
    _validateConfiguration();
    final gray = GrayImagePlane.fromImage(
      image,
      maxSide: maxAnalysisSide,
      maxPixels: maxAnalysisPixels,
    );
    final edges = gray.sobel();
    if (edges.points.length < 256) {
      throw const GridDetectionException(
        GridDetectionErrorCode.insufficientEdges,
        'The frame does not contain enough bounded edge evidence.',
      );
    }
    final lines = _houghLines(edges);
    final families = _lineFamilies(lines, gray.width, gray.height);
    if (families == null ||
        families.first.length < 2 ||
        families.second.length < 2) {
      throw const GridDetectionException(
        GridDetectionErrorCode.missingLineFamilies,
        'Two distinct Go-grid line families were not found.',
      );
    }

    final firstPairs = _outerPairs(families.first, gray.width, gray.height);
    final secondPairs = _outerPairs(families.second, gray.width, gray.height);
    final candidates = <_ScoredCandidate>[];
    for (final firstPair in firstPairs) {
      for (final secondPair in secondPairs) {
        final bounds = _quadFor(firstPair, secondPair, gray.width, gray.height);
        if (bounds == null) continue;
        final scored = _scoreCandidate(
          image,
          bounds,
          (firstPair.support + secondPair.support) / 2,
          math.min(firstPair.insideLineCount, secondPair.insideLineCount),
          firstPair.latticeEvidence,
          secondPair.latticeEvidence,
        );
        if (scored != null) candidates.add(scored);
      }
    }
    if (candidates.isEmpty) {
      throw const GridDetectionException(
        GridDetectionErrorCode.noConvexCandidate,
        'No convex quadrilateral had decisive grid evidence.',
      );
    }
    candidates.sort((left, right) => right.score.compareTo(left.score));
    final distinct = <_ScoredCandidate>[];
    for (final candidate in candidates) {
      if (distinct.any(
        (accepted) => _cornerDistance(candidate.bounds, accepted.bounds) < 0.05,
      )) {
        continue;
      }
      distinct.add(candidate);
    }
    final best = distinct.first;
    if (best.score < minimumGeometryScore) {
      throw const GridDetectionException(
        GridDetectionErrorCode.insufficientLatticeEvidence,
        'The strongest board candidate did not reach the evidence threshold.',
      );
    }
    final geometryMargin = distinct.length < 2
        ? best.score
        : best.score - distinct[1].score;
    if (geometryMargin < minimumGeometryMargin) {
      final runnerUp = distinct[1];
      throw GridDetectionException(
        GridDetectionErrorCode.ambiguousGeometry,
        'Competing board quadrilaterals differ by only '
        '${geometryMargin.toStringAsFixed(3)} '
        '(corner distance '
        '${_cornerDistance(best.bounds, runnerUp.bounds).toStringAsFixed(3)}, '
        'scores ${best.score.toStringAsFixed(3)}/'
        '${runnerUp.score.toStringAsFixed(3)}).',
      );
    }
    final refinedBounds = _refineBounds(image, best.bounds, best.boardSize);
    return DetectedBoardGeometry(
      bounds: refinedBounds ?? best.bounds,
      boardSize: best.boardSize,
      score: best.score,
      boardSizeMargin: best.boardSizeMargin,
      lineSupport: best.lineSupport,
    );
  }

  void _validateConfiguration() {
    if (maxAnalysisSide < 128 ||
        maxAnalysisSide > 1024 ||
        maxAnalysisPixels < 16384 ||
        maxAnalysisPixels > 1000000 ||
        thetaBins < 90 ||
        thetaBins > 360 ||
        !rhoResolution.isFinite ||
        rhoResolution < 1 ||
        rhoResolution > 4 ||
        maxHoughLines < 16 ||
        maxHoughLines > 128 ||
        maxPairsPerFamily < 2 ||
        maxPairsPerFamily > 16 ||
        candidateWarpSide < 96 ||
        candidateWarpSide > 320 ||
        !_unitThreshold(minimumLatticeScore) ||
        !_unitThreshold(minimumBoardSizeMargin) ||
        !_unitThreshold(minimumGeometryScore) ||
        !_unitThreshold(minimumGeometryMargin)) {
      throw ArgumentError('Invalid bounded grid detector configuration.');
    }
  }

  List<_ImageLine> _houghLines(EdgeEvidence edges) {
    final diagonal = math.sqrt(
      edges.width * edges.width + edges.height * edges.height,
    );
    final rhoBins = (2 * diagonal / rhoResolution).ceil() + 1;
    final accumulator = Uint32List(thetaBins * rhoBins);
    final cosines = List<double>.generate(
      thetaBins,
      (index) => math.cos(math.pi * index / thetaBins),
      growable: false,
    );
    final sines = List<double>.generate(
      thetaBins,
      (index) => math.sin(math.pi * index / thetaBins),
      growable: false,
    );
    var maximumVote = 0;
    for (final point in edges.points) {
      final weight = 1 + (point.strength * 3).round();
      for (var theta = 0; theta < thetaBins; theta++) {
        final rho = point.x * cosines[theta] + point.y * sines[theta];
        final rhoIndex = ((rho + diagonal) / rhoResolution).round();
        if (rhoIndex < 0 || rhoIndex >= rhoBins) continue;
        final index = theta * rhoBins + rhoIndex;
        final updated = accumulator[index] + weight;
        accumulator[index] = updated;
        maximumVote = math.max(maximumVote, updated);
      }
    }
    if (maximumVote == 0) return const <_ImageLine>[];
    final voteThreshold = math.max(10, (maximumVote * 0.10).round());
    final raw = <_ImageLine>[];
    for (var theta = 0; theta < thetaBins; theta++) {
      for (var rhoIndex = 0; rhoIndex < rhoBins; rhoIndex++) {
        final votes = accumulator[theta * rhoBins + rhoIndex];
        if (votes < voteThreshold) continue;
        var localMaximum = true;
        for (
          var thetaOffset = -2;
          thetaOffset <= 2 && localMaximum;
          thetaOffset++
        ) {
          final otherTheta = theta + thetaOffset;
          if (otherTheta < 0 || otherTheta >= thetaBins) continue;
          for (var rhoOffset = -2; rhoOffset <= 2; rhoOffset++) {
            if (thetaOffset == 0 && rhoOffset == 0) continue;
            final otherRho = rhoIndex + rhoOffset;
            if (otherRho < 0 || otherRho >= rhoBins) continue;
            if (accumulator[otherTheta * rhoBins + otherRho] > votes) {
              localMaximum = false;
              break;
            }
          }
        }
        if (!localMaximum) continue;
        raw.add(
          _ImageLine(
            thetaDegrees: 180 * theta / thetaBins,
            rho: rhoIndex * rhoResolution - diagonal,
            strength: votes / maximumVote,
          ),
        );
      }
    }
    raw.sort((left, right) => right.strength.compareTo(left.strength));
    final selected = <_ImageLine>[];
    for (final line in raw) {
      if (selected.any(
        (accepted) =>
            _angularDistance(line.thetaDegrees, accepted.thetaDegrees) < 2.5 &&
            (line.rho - accepted.rho).abs() < 4,
      )) {
        continue;
      }
      selected.add(line);
      if (selected.length >= maxHoughLines) break;
    }
    return selected;
  }

  ({List<_AlignedLine> first, List<_AlignedLine> second})? _lineFamilies(
    List<_ImageLine> lines,
    int width,
    int height,
  ) {
    if (lines.length < 4) return null;
    final histogram = List<double>.filled(thetaBins, 0);
    for (final line in lines) {
      final bin = (line.thetaDegrees * thetaBins / 180).round() % thetaBins;
      for (var offset = -4; offset <= 4; offset++) {
        final target = (bin + offset) % thetaBins;
        histogram[target] += line.strength * (5 - offset.abs());
      }
    }
    var firstBin = 0;
    for (var index = 1; index < histogram.length; index++) {
      if (histogram[index] > histogram[firstBin]) firstBin = index;
    }
    var secondBin = -1;
    for (var index = 0; index < histogram.length; index++) {
      final distance = _angularDistance(
        180 * firstBin / thetaBins,
        180 * index / thetaBins,
      );
      if (distance < 45) continue;
      if (secondBin < 0 || histogram[index] > histogram[secondBin]) {
        secondBin = index;
      }
    }
    if (secondBin < 0) return null;
    final firstCenter = 180 * firstBin / thetaBins;
    final secondCenter = 180 * secondBin / thetaBins;
    final first = _alignFamily(lines, firstCenter, width, height);
    final second = _alignFamily(lines, secondCenter, width, height);
    return (first: first, second: second);
  }

  List<_AlignedLine> _alignFamily(
    List<_ImageLine> lines,
    double centerDegrees,
    int width,
    int height,
  ) {
    final centerRadians = centerDegrees * math.pi / 180;
    final centerX = (width - 1) / 2;
    final centerY = (height - 1) / 2;
    final aligned = <_AlignedLine>[];
    for (final line in lines) {
      if (_angularDistance(line.thetaDegrees, centerDegrees) > 18) continue;
      var a = math.cos(line.thetaDegrees * math.pi / 180);
      var b = math.sin(line.thetaDegrees * math.pi / 180);
      var rho = line.rho;
      if (a * math.cos(centerRadians) + b * math.sin(centerRadians) < 0) {
        a = -a;
        b = -b;
        rho = -rho;
      }
      final candidate = _AlignedLine(
        a: a,
        b: b,
        rho: rho,
        centerPosition: rho - a * centerX - b * centerY,
        strength: line.strength,
      );
      final duplicate = aligned.indexWhere(
        (accepted) =>
            (accepted.centerPosition - candidate.centerPosition).abs() < 3,
      );
      if (duplicate < 0) {
        aligned.add(candidate);
      } else if (candidate.strength > aligned[duplicate].strength) {
        aligned[duplicate] = candidate;
      }
    }
    aligned.sort(
      (left, right) => left.centerPosition.compareTo(right.centerPosition),
    );
    return aligned;
  }

  List<_LinePair> _outerPairs(List<_AlignedLine> lines, int width, int height) {
    final minimumSeparation = math.min(width, height) * 0.38;
    final totalStrength = lines.fold<double>(
      0,
      (sum, line) => sum + line.strength,
    );
    final candidates = <_LinePair>[];
    for (var first = 0; first < lines.length - 1; first++) {
      for (var second = first + 1; second < lines.length; second++) {
        final separation =
            (lines[second].centerPosition - lines[first].centerPosition).abs();
        if (separation < minimumSeparation) continue;
        final strength = (lines[first].strength + lines[second].strength) / 2;
        final span = (separation / math.min(width, height)).clamp(0, 1);
        var outsideStrength = 0.0;
        for (var index = 0; index < lines.length; index++) {
          if (index < first || index > second) {
            outsideStrength += lines[index].strength;
          }
        }
        final containment = totalStrength <= 0
            ? 0.0
            : (1 - outsideStrength / totalStrength).clamp(0, 1);
        candidates.add(
          _LinePair(
            first: lines[first],
            second: lines[second],
            support: 0.30 * strength + 0.40 * span + 0.30 * containment,
            insideLineCount: second - first + 1,
            latticeEvidence: LatticeAxisEvidence(
              _boundedLatticePeaks(lines, first, second, separation),
            ),
          ),
        );
      }
    }
    candidates.sort((left, right) => right.support.compareTo(left.support));
    return candidates.take(maxPairsPerFamily).toList(growable: false);
  }

  BoardQuadrilateral? _quadFor(
    _LinePair first,
    _LinePair second,
    int width,
    int height,
  ) {
    final intersections = <ProjectivePoint>[];
    for (final firstLine in <_AlignedLine>[first.first, first.second]) {
      for (final secondLine in <_AlignedLine>[second.first, second.second]) {
        final point = _intersection(firstLine, secondLine);
        if (point == null ||
            point.x < -width * 0.02 ||
            point.x > width * 1.02 ||
            point.y < -height * 0.02 ||
            point.y > height * 1.02) {
          return null;
        }
        intersections.add(
          ProjectivePoint(
            point.x.clamp(0, width - 1.0),
            point.y.clamp(0, height - 1.0),
          ),
        );
      }
    }
    final centerX =
        intersections.fold<double>(0, (sum, point) => sum + point.x) /
        intersections.length;
    final centerY =
        intersections.fold<double>(0, (sum, point) => sum + point.y) /
        intersections.length;
    intersections.sort(
      (left, right) => math
          .atan2(left.y - centerY, left.x - centerX)
          .compareTo(math.atan2(right.y - centerY, right.x - centerX)),
    );
    var start = 0;
    for (var index = 1; index < intersections.length; index++) {
      if (intersections[index].x + intersections[index].y <
          intersections[start].x + intersections[start].y) {
        start = index;
      }
    }
    final ordered = <ProjectivePoint>[
      for (var offset = 0; offset < 4; offset++)
        intersections[(start + offset) % 4],
    ];
    final bounds = BoardQuadrilateral(
      topLeft: NormalizedPoint(
        ordered[0].x / (width - 1),
        ordered[0].y / (height - 1),
      ),
      topRight: NormalizedPoint(
        ordered[1].x / (width - 1),
        ordered[1].y / (height - 1),
      ),
      bottomRight: NormalizedPoint(
        ordered[2].x / (width - 1),
        ordered[2].y / (height - 1),
      ),
      bottomLeft: NormalizedPoint(
        ordered[3].x / (width - 1),
        ordered[3].y / (height - 1),
      ),
    );
    try {
      bounds.validate(minimumArea: 0.04);
    } on Object {
      return null;
    }
    return bounds;
  }

  _ScoredCandidate? _scoreCandidate(
    img.Image source,
    BoardQuadrilateral bounds,
    double lineSupport,
    int containedLineCount,
    LatticeAxisEvidence firstLineEvidence,
    LatticeAxisEvidence secondLineEvidence,
  ) {
    final lineLattice = const BoardSizeLatticeScorer(
      matchToleranceInSpacings: 0.36,
    ).score(horizontal: firstLineEvidence, vertical: secondLineEvidence);
    if (lineLattice.best.score < 0.65) return null;
    final sourceCorners = <ProjectivePoint>[
      for (final point in bounds.vertices)
        ProjectivePoint(
          point.x * (source.width - 1),
          point.y * (source.height - 1),
        ),
    ];
    final destination = <ProjectivePoint>[
      ProjectivePoint(0, 0),
      ProjectivePoint(candidateWarpSide - 1.0, 0),
      ProjectivePoint(candidateWarpSide - 1.0, candidateWarpSide - 1.0),
      ProjectivePoint(0, candidateWarpSide - 1.0),
    ];
    Homography homography;
    try {
      homography = Homography.fromPointPairs(
        source: sourceCorners,
        destination: destination,
      );
    } on HomographyException {
      return null;
    }
    final rectified = warpPerspective(
      source: source,
      sourceToDestination: homography,
      outputWidth: candidateWarpSide,
      outputHeight: candidateWarpSide,
      maxOutputPixels: candidateWarpSide * candidateWarpSide,
    );
    final gray = GrayImagePlane.fromImage(
      rectified,
      maxSide: candidateWarpSide,
      maxPixels: candidateWarpSide * candidateWarpSide,
    );
    final projections = gray.darknessProjections();
    LatticeAxisEvidence horizontal;
    LatticeAxisEvidence vertical;
    try {
      horizontal = LatticeAxisEvidence.fromProjection(
        projections.horizontal,
        relativeThreshold: 0.18,
      );
      vertical = LatticeAxisEvidence.fromProjection(
        projections.vertical,
        relativeThreshold: 0.18,
      );
    } on LatticeScoringException {
      return null;
    }
    final imageLattice = const BoardSizeLatticeScorer(
      matchToleranceInSpacings: 0.24,
    ).score(horizontal: horizontal, vertical: vertical);
    final lattice = _combineLatticeEvidence(imageLattice, lineLattice);
    if (lattice.score < minimumLatticeScore ||
        lattice.margin < minimumBoardSizeMargin) {
      return null;
    }
    if (containedLineCount < lattice.boardSize.dimension - 1) return null;
    final areaScore = math.sqrt(bounds.signedArea).clamp(0, 1);
    final borderAlignment =
        (_borderAlignment(horizontal) + _borderAlignment(vertical)) / 2;
    final peakCountAgreement =
        (_peakCountAgreement(
              horizontal.peaks.length,
              lattice.boardSize.dimension,
            ) +
            _peakCountAgreement(
              vertical.peaks.length,
              lattice.boardSize.dimension,
            )) /
        2;
    final score =
        0.61 * lattice.score +
        0.12 * borderAlignment +
        0.07 * peakCountAgreement +
        0.16 * lineSupport.clamp(0, 1) +
        0.04 * areaScore;
    return _ScoredCandidate(
      bounds: bounds,
      boardSize: lattice.boardSize,
      boardSizeMargin: lattice.margin,
      lineSupport: lineSupport,
      score: score.clamp(0, 1),
    );
  }

  BoardQuadrilateral? _refineBounds(
    img.Image source,
    BoardQuadrilateral initial,
    BoardSize boardSize,
  ) {
    const expansion = 1.18;
    const side = 256;
    final centerX =
        initial.vertices.fold<double>(0, (sum, point) => sum + point.x) / 4;
    final centerY =
        initial.vertices.fold<double>(0, (sum, point) => sum + point.y) / 4;
    final expanded = <ProjectivePoint>[
      for (final point in initial.vertices)
        ProjectivePoint(
          (centerX + (point.x - centerX) * expansion).clamp(0, 1) *
              (source.width - 1),
          (centerY + (point.y - centerY) * expansion).clamp(0, 1) *
              (source.height - 1),
        ),
    ];
    final destination = <ProjectivePoint>[
      ProjectivePoint(0, 0),
      ProjectivePoint(side - 1.0, 0),
      ProjectivePoint(side - 1.0, side - 1.0),
      ProjectivePoint(0, side - 1.0),
    ];
    Homography transform;
    try {
      transform = Homography.fromPointPairs(
        source: expanded,
        destination: destination,
      );
    } on HomographyException {
      return null;
    }
    final rectified = warpPerspective(
      source: source,
      sourceToDestination: transform,
      outputWidth: side,
      outputHeight: side,
      maxOutputPixels: side * side,
    );
    final projections = GrayImagePlane.fromImage(
      rectified,
      maxSide: side,
      maxPixels: side * side,
    ).darknessProjections();
    LatticeAxisEvidence horizontal;
    LatticeAxisEvidence vertical;
    try {
      horizontal = LatticeAxisEvidence.fromProjection(
        projections.horizontal,
        relativeThreshold: 0.16,
      );
      vertical = LatticeAxisEvidence.fromProjection(
        projections.vertical,
        relativeThreshold: 0.16,
      );
    } on LatticeScoringException {
      return null;
    }
    final horizontalFit = _fitFixedLattice(horizontal, boardSize.dimension);
    final verticalFit = _fitFixedLattice(vertical, boardSize.dimension);
    if (horizontalFit == null || verticalFit == null) return null;
    final inverse = transform.inverse();
    final adjusted = <ProjectivePoint>[
      inverse.project(
        ProjectivePoint(
          verticalFit.start * (side - 1),
          horizontalFit.start * (side - 1),
        ),
      ),
      inverse.project(
        ProjectivePoint(
          verticalFit.end * (side - 1),
          horizontalFit.start * (side - 1),
        ),
      ),
      inverse.project(
        ProjectivePoint(
          verticalFit.end * (side - 1),
          horizontalFit.end * (side - 1),
        ),
      ),
      inverse.project(
        ProjectivePoint(
          verticalFit.start * (side - 1),
          horizontalFit.end * (side - 1),
        ),
      ),
    ];
    final bounds = BoardQuadrilateral(
      topLeft: NormalizedPoint(
        adjusted[0].x / (source.width - 1),
        adjusted[0].y / (source.height - 1),
      ),
      topRight: NormalizedPoint(
        adjusted[1].x / (source.width - 1),
        adjusted[1].y / (source.height - 1),
      ),
      bottomRight: NormalizedPoint(
        adjusted[2].x / (source.width - 1),
        adjusted[2].y / (source.height - 1),
      ),
      bottomLeft: NormalizedPoint(
        adjusted[3].x / (source.width - 1),
        adjusted[3].y / (source.height - 1),
      ),
    );
    try {
      bounds.validate(minimumArea: 0.04);
    } on Object {
      return null;
    }
    return bounds;
  }
}

_AxisFit? _fitFixedLattice(LatticeAxisEvidence evidence, int dimension) {
  if (evidence.peaks.length < dimension - 1) return null;
  _AxisFit? best;
  for (var first = 0; first < evidence.peaks.length - 1; first++) {
    for (var last = first + 1; last < evidence.peaks.length; last++) {
      final start = evidence.peaks[first].position;
      final end = evidence.peaks[last].position;
      final span = end - start;
      if (span < 0.45) continue;
      final spacing = span / (dimension - 1);
      final tolerance = spacing * 0.28;
      final used = <int>{};
      var matched = 0;
      var residual = 0.0;
      var matchedStrength = 0.0;
      for (var line = 0; line < dimension; line++) {
        final expected = start + spacing * line;
        var nearest = -1;
        var distance = double.infinity;
        for (var index = 0; index < evidence.peaks.length; index++) {
          if (used.contains(index)) continue;
          final candidateDistance = (evidence.peaks[index].position - expected)
              .abs();
          if (candidateDistance < distance) {
            distance = candidateDistance;
            nearest = index;
          }
        }
        if (nearest < 0 || distance > tolerance) continue;
        used.add(nearest);
        matched++;
        residual += distance / spacing;
        matchedStrength += evidence.peaks[nearest].strength;
      }
      if (matched < dimension - 1) continue;
      final totalStrength = evidence.peaks.fold<double>(
        0,
        (sum, peak) => sum + peak.strength,
      );
      final coverage = matched / dimension;
      final precision = (matchedStrength / totalStrength).clamp(0, 1);
      final regularity = math.exp(-6 * residual / matched);
      final score =
          0.45 * coverage + 0.30 * precision + 0.20 * regularity + 0.05 * span;
      if (best == null || score > best.score) {
        best = _AxisFit(start: start, end: end, score: score);
      }
    }
  }
  return best;
}

_CombinedLattice _combineLatticeEvidence(
  BoardLatticeResult image,
  BoardLatticeResult lines,
) {
  final scores = <BoardSize, double>{};
  for (final size in BoardSize.values) {
    final imageScore = image.candidates
        .singleWhere((candidate) => candidate.boardSize == size)
        .score;
    final lineScore = lines.candidates
        .singleWhere((candidate) => candidate.boardSize == size)
        .score;
    scores[size] = 0.48 * imageScore + 0.52 * lineScore;
  }
  final ranked = scores.entries.toList(growable: false)
    ..sort((left, right) => right.value.compareTo(left.value));
  return _CombinedLattice(
    boardSize: ranked.first.key,
    score: ranked.first.value,
    margin: ranked.first.value - ranked[1].value,
  );
}

double _borderAlignment(LatticeAxisEvidence evidence) {
  if (evidence.peaks.length < 2) return 0;
  final inset =
      evidence.peaks.first.position + (1 - evidence.peaks.last.position);
  return (1 - inset / 0.14).clamp(0, 1);
}

double _peakCountAgreement(int actual, int expected) =>
    math.exp(-0.45 * (actual - expected).abs());

List<LatticePeak> _boundedLatticePeaks(
  List<_AlignedLine> lines,
  int first,
  int second,
  double separation,
) {
  final peaks = <LatticePeak>[
    for (var index = first; index <= second; index++)
      LatticePeak(
        position:
            (lines[index].centerPosition - lines[first].centerPosition) /
            separation,
        strength: lines[index].strength.clamp(1e-6, 1),
      ),
  ];
  if (peaks.length <= LatticeAxisEvidence.maximumPeakCount) return peaks;
  final endpoints = <LatticePeak>[peaks.first, peaks.last];
  final middle = peaks.sublist(1, peaks.length - 1)
    ..sort((left, right) => right.strength.compareTo(left.strength));
  final bounded = <LatticePeak>[
    ...endpoints,
    ...middle.take(LatticeAxisEvidence.maximumPeakCount - endpoints.length),
  ]..sort((left, right) => left.position.compareTo(right.position));
  return bounded;
}

bool _unitThreshold(double value) => value.isFinite && value >= 0 && value <= 1;

double _angularDistance(double left, double right) {
  final raw = (left - right).abs() % 180;
  return math.min(raw, 180 - raw);
}

ProjectivePoint? _intersection(_AlignedLine first, _AlignedLine second) {
  final determinant = first.a * second.b - second.a * first.b;
  if (!determinant.isFinite || determinant.abs() < 1e-8) return null;
  return ProjectivePoint(
    (first.rho * second.b - second.rho * first.b) / determinant,
    (first.a * second.rho - second.a * first.rho) / determinant,
  );
}

double _cornerDistance(BoardQuadrilateral left, BoardQuadrilateral right) {
  var squared = 0.0;
  for (var index = 0; index < 4; index++) {
    final dx = left.vertices[index].x - right.vertices[index].x;
    final dy = left.vertices[index].y - right.vertices[index].y;
    squared += dx * dx + dy * dy;
  }
  return math.sqrt(squared / 4);
}

final class _ImageLine {
  const _ImageLine({
    required this.thetaDegrees,
    required this.rho,
    required this.strength,
  });

  final double thetaDegrees;
  final double rho;
  final double strength;
}

final class _AlignedLine {
  const _AlignedLine({
    required this.a,
    required this.b,
    required this.rho,
    required this.centerPosition,
    required this.strength,
  });

  final double a;
  final double b;
  final double rho;
  final double centerPosition;
  final double strength;
}

final class _LinePair {
  const _LinePair({
    required this.first,
    required this.second,
    required this.support,
    required this.insideLineCount,
    required this.latticeEvidence,
  });

  final _AlignedLine first;
  final _AlignedLine second;
  final double support;
  final int insideLineCount;
  final LatticeAxisEvidence latticeEvidence;
}

final class _CombinedLattice {
  const _CombinedLattice({
    required this.boardSize,
    required this.score,
    required this.margin,
  });

  final BoardSize boardSize;
  final double score;
  final double margin;
}

final class _AxisFit {
  const _AxisFit({required this.start, required this.end, required this.score});

  final double start;
  final double end;
  final double score;
}

final class _ScoredCandidate {
  const _ScoredCandidate({
    required this.bounds,
    required this.boardSize,
    required this.score,
    required this.boardSizeMargin,
    required this.lineSupport,
  });

  final BoardQuadrilateral bounds;
  final BoardSize boardSize;
  final double score;
  final double boardSizeMargin;
  final double lineSupport;
}
