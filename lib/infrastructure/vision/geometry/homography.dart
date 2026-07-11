import 'dart:math' as math;

import 'package:image/image.dart' as img;

enum HomographyErrorCode {
  invalidPointCount,
  nonFiniteCoordinate,
  degenerateConfiguration,
  projectionAtInfinity,
  invalidOutputSize,
  outputBudgetExceeded,
}

final class HomographyException implements Exception {
  const HomographyException(this.code, this.message);

  final HomographyErrorCode code;
  final String message;

  @override
  String toString() => 'HomographyException(${code.name}): $message';
}

final class ProjectivePoint {
  ProjectivePoint(this.x, this.y) {
    if (!x.isFinite || !y.isFinite) {
      throw const HomographyException(
        HomographyErrorCode.nonFiniteCoordinate,
        'Projective point coordinates must be finite.',
      );
    }
  }

  final double x;
  final double y;

  double distanceTo(ProjectivePoint other) =>
      math.sqrt(math.pow(x - other.x, 2) + math.pow(y - other.y, 2));

  @override
  String toString() => 'ProjectivePoint($x, $y)';
}

/// A normalized 3×3 projective transformation.
///
/// Four point pairs are solved with coordinate normalization and partial-pivot
/// Gaussian elimination. This is deterministic and dependency-free; it makes
/// no claim about automatically locating the board corners that feed it.
final class Homography {
  Homography._(List<double> coefficients)
    : _coefficients = List<double>.unmodifiable(coefficients) {
    if (_coefficients.length != 9 ||
        _coefficients.any((value) => !value.isFinite) ||
        _determinant(_coefficients).abs() <= _epsilon) {
      throw const HomographyException(
        HomographyErrorCode.degenerateConfiguration,
        'Homography matrix must be finite and invertible.',
      );
    }
  }

  static const double _epsilon = 1e-12;
  final List<double> _coefficients;

  List<double> get coefficients => _coefficients;

  factory Homography.fromPointPairs({
    required List<ProjectivePoint> source,
    required List<ProjectivePoint> destination,
  }) {
    if (source.length != 4 || destination.length != 4) {
      throw const HomographyException(
        HomographyErrorCode.invalidPointCount,
        'Exactly four source and four destination points are required.',
      );
    }
    _validatePointConfiguration(source, 'source');
    _validatePointConfiguration(destination, 'destination');

    final sourceNormalization = _PointNormalization.from(source);
    final destinationNormalization = _PointNormalization.from(destination);
    final normalizedSource = source
        .map(sourceNormalization.apply)
        .toList(growable: false);
    final normalizedDestination = destination
        .map(destinationNormalization.apply)
        .toList(growable: false);

    final system = <List<double>>[];
    final values = <double>[];
    for (var index = 0; index < 4; index++) {
      final x = normalizedSource[index].x;
      final y = normalizedSource[index].y;
      final u = normalizedDestination[index].x;
      final v = normalizedDestination[index].y;
      system.add(<double>[x, y, 1, 0, 0, 0, -u * x, -u * y]);
      values.add(u);
      system.add(<double>[0, 0, 0, x, y, 1, -v * x, -v * y]);
      values.add(v);
    }

    final solved = _solve(system, values);
    final normalizedMatrix = <double>[...solved, 1];
    final denormalized = _multiply3x3(
      destinationNormalization.inverseMatrix,
      _multiply3x3(normalizedMatrix, sourceNormalization.matrix),
    );
    return Homography._(_normalizeScale(denormalized));
  }

  ProjectivePoint project(ProjectivePoint point) {
    final h = _coefficients;
    final denominator = h[6] * point.x + h[7] * point.y + h[8];
    if (!denominator.isFinite || denominator.abs() <= _epsilon) {
      throw const HomographyException(
        HomographyErrorCode.projectionAtInfinity,
        'The projected point lies at infinity.',
      );
    }
    return ProjectivePoint(
      (h[0] * point.x + h[1] * point.y + h[2]) / denominator,
      (h[3] * point.x + h[4] * point.y + h[5]) / denominator,
    );
  }

  Homography inverse() {
    final h = _coefficients;
    final determinant = _determinant(h);
    if (determinant.abs() <= _epsilon) {
      throw const HomographyException(
        HomographyErrorCode.degenerateConfiguration,
        'The homography cannot be inverted.',
      );
    }
    final inverse = <double>[
      (h[4] * h[8] - h[5] * h[7]) / determinant,
      (h[2] * h[7] - h[1] * h[8]) / determinant,
      (h[1] * h[5] - h[2] * h[4]) / determinant,
      (h[5] * h[6] - h[3] * h[8]) / determinant,
      (h[0] * h[8] - h[2] * h[6]) / determinant,
      (h[2] * h[3] - h[0] * h[5]) / determinant,
      (h[3] * h[7] - h[4] * h[6]) / determinant,
      (h[1] * h[6] - h[0] * h[7]) / determinant,
      (h[0] * h[4] - h[1] * h[3]) / determinant,
    ];
    return Homography._(_normalizeScale(inverse));
  }
}

/// Warps [source] into destination coordinates using inverse mapping.
///
/// The explicit output-pixel budget prevents callers from accidentally
/// allocating unbounded rectified images.
img.Image warpPerspective({
  required img.Image source,
  required Homography sourceToDestination,
  required int outputWidth,
  required int outputHeight,
  int maxOutputPixels = 16 * 1000 * 1000,
  img.Interpolation interpolation = img.Interpolation.linear,
}) {
  if (outputWidth <= 0 || outputHeight <= 0 || maxOutputPixels <= 0) {
    throw const HomographyException(
      HomographyErrorCode.invalidOutputSize,
      'Output dimensions and pixel budget must be positive.',
    );
  }
  if (outputWidth * outputHeight > maxOutputPixels) {
    throw HomographyException(
      HomographyErrorCode.outputBudgetExceeded,
      'The requested warp exceeds the $maxOutputPixels-pixel output budget.',
    );
  }

  final destinationToSource = sourceToDestination.inverse();
  final output = img.Image(
    width: outputWidth,
    height: outputHeight,
    numChannels: 4,
  );
  for (var y = 0; y < outputHeight; y++) {
    for (var x = 0; x < outputWidth; x++) {
      ProjectivePoint sourcePoint;
      try {
        sourcePoint = destinationToSource.project(
          ProjectivePoint(x.toDouble(), y.toDouble()),
        );
      } on HomographyException {
        continue;
      }
      if (sourcePoint.x < 0 ||
          sourcePoint.y < 0 ||
          sourcePoint.x > source.width - 1 ||
          sourcePoint.y > source.height - 1) {
        continue;
      }
      final pixel = interpolation == img.Interpolation.nearest
          ? source.getPixel(sourcePoint.x.round(), sourcePoint.y.round())
          : source.getPixelInterpolate(
              sourcePoint.x,
              sourcePoint.y,
              interpolation: interpolation,
            );
      output.setPixel(x, y, pixel);
    }
  }
  return output;
}

void _validatePointConfiguration(List<ProjectivePoint> points, String name) {
  for (var left = 0; left < points.length; left++) {
    for (var right = left + 1; right < points.length; right++) {
      if (points[left].distanceTo(points[right]) <= Homography._epsilon) {
        throw HomographyException(
          HomographyErrorCode.degenerateConfiguration,
          '$name contains duplicate points.',
        );
      }
    }
  }
  final area = _polygonArea(points).abs();
  final boundsWidth =
      points.map((point) => point.x).reduce(math.max) -
      points.map((point) => point.x).reduce(math.min);
  final boundsHeight =
      points.map((point) => point.y).reduce(math.max) -
      points.map((point) => point.y).reduce(math.min);
  final scale = math.max(1.0, boundsWidth * boundsHeight);
  if (!area.isFinite || area <= Homography._epsilon * scale) {
    throw HomographyException(
      HomographyErrorCode.degenerateConfiguration,
      '$name points are collinear or have negligible area.',
    );
  }
}

double _polygonArea(List<ProjectivePoint> points) {
  var twiceArea = 0.0;
  for (var index = 0; index < points.length; index++) {
    final current = points[index];
    final next = points[(index + 1) % points.length];
    twiceArea += current.x * next.y - current.y * next.x;
  }
  return twiceArea / 2;
}

List<double> _solve(List<List<double>> matrix, List<double> values) {
  final size = values.length;
  final augmented = <List<double>>[
    for (var row = 0; row < size; row++) <double>[...matrix[row], values[row]],
  ];

  for (var column = 0; column < size; column++) {
    var pivotRow = column;
    var pivotMagnitude = augmented[column][column].abs();
    for (var row = column + 1; row < size; row++) {
      final magnitude = augmented[row][column].abs();
      if (magnitude > pivotMagnitude) {
        pivotMagnitude = magnitude;
        pivotRow = row;
      }
    }
    if (!pivotMagnitude.isFinite || pivotMagnitude <= Homography._epsilon) {
      throw const HomographyException(
        HomographyErrorCode.degenerateConfiguration,
        'Point pairs do not determine a stable homography.',
      );
    }
    if (pivotRow != column) {
      final swap = augmented[column];
      augmented[column] = augmented[pivotRow];
      augmented[pivotRow] = swap;
    }

    final pivot = augmented[column][column];
    for (var valueColumn = column; valueColumn <= size; valueColumn++) {
      augmented[column][valueColumn] /= pivot;
    }
    for (var row = 0; row < size; row++) {
      if (row == column) continue;
      final factor = augmented[row][column];
      if (factor.abs() <= Homography._epsilon) continue;
      for (var valueColumn = column; valueColumn <= size; valueColumn++) {
        augmented[row][valueColumn] -= factor * augmented[column][valueColumn];
      }
    }
  }
  return <double>[for (var row = 0; row < size; row++) augmented[row][size]];
}

List<double> _multiply3x3(List<double> left, List<double> right) => <double>[
  for (var row = 0; row < 3; row++)
    for (var column = 0; column < 3; column++)
      left[row * 3] * right[column] +
          left[row * 3 + 1] * right[3 + column] +
          left[row * 3 + 2] * right[6 + column],
];

List<double> _normalizeScale(List<double> matrix) {
  final scale = matrix[8].abs() > Homography._epsilon
      ? matrix[8]
      : matrix.map((value) => value.abs()).reduce(math.max);
  if (!scale.isFinite || scale.abs() <= Homography._epsilon) {
    throw const HomographyException(
      HomographyErrorCode.degenerateConfiguration,
      'Homography has no usable scale.',
    );
  }
  return matrix.map((value) => value / scale).toList(growable: false);
}

double _determinant(List<double> h) =>
    h[0] * (h[4] * h[8] - h[5] * h[7]) -
    h[1] * (h[3] * h[8] - h[5] * h[6]) +
    h[2] * (h[3] * h[7] - h[4] * h[6]);

final class _PointNormalization {
  _PointNormalization._({
    required this.centerX,
    required this.centerY,
    required this.scale,
  });

  factory _PointNormalization.from(List<ProjectivePoint> points) {
    final centerX =
        points.map((point) => point.x).reduce((a, b) => a + b) / points.length;
    final centerY =
        points.map((point) => point.y).reduce((a, b) => a + b) / points.length;
    final meanDistance =
        points
            .map(
              (point) => math.sqrt(
                math.pow(point.x - centerX, 2) + math.pow(point.y - centerY, 2),
              ),
            )
            .reduce((a, b) => a + b) /
        points.length;
    if (!meanDistance.isFinite || meanDistance <= Homography._epsilon) {
      throw const HomographyException(
        HomographyErrorCode.degenerateConfiguration,
        'Point normalization requires a non-zero spread.',
      );
    }
    return _PointNormalization._(
      centerX: centerX,
      centerY: centerY,
      scale: math.sqrt2 / meanDistance,
    );
  }

  final double centerX;
  final double centerY;
  final double scale;

  List<double> get matrix => <double>[
    scale,
    0,
    -scale * centerX,
    0,
    scale,
    -scale * centerY,
    0,
    0,
    1,
  ];

  List<double> get inverseMatrix => <double>[
    1 / scale,
    0,
    centerX,
    0,
    1 / scale,
    centerY,
    0,
    0,
    1,
  ];

  ProjectivePoint apply(ProjectivePoint point) =>
      ProjectivePoint(scale * (point.x - centerX), scale * (point.y - centerY));
}
