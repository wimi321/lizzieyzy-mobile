import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

final class GrayImagePlane {
  GrayImagePlane._({
    required this.width,
    required this.height,
    required Float32List luminance,
  }) : luminance = Float32List.fromList(luminance) {
    if (width <= 0 ||
        height <= 0 ||
        luminance.length != width * height ||
        luminance.any((value) => !value.isFinite || value < 0 || value > 1)) {
      throw ArgumentError('Invalid bounded grayscale image plane.');
    }
  }

  factory GrayImagePlane.fromImage(
    img.Image source, {
    int maxSide = 640,
    int maxPixels = 400000,
  }) {
    if (source.width <= 0 ||
        source.height <= 0 ||
        maxSide < 64 ||
        maxPixels < 4096) {
      throw ArgumentError('Invalid grayscale analysis budget.');
    }
    final sourcePixels = source.width * source.height;
    final scale = math.min(
      1.0,
      math.min(
        maxSide / math.max(source.width, source.height),
        math.sqrt(maxPixels / sourcePixels),
      ),
    );
    final width = math.max(1, (source.width * scale).floor());
    final height = math.max(1, (source.height * scale).floor());
    final luminance = Float32List(width * height);
    for (var y = 0; y < height; y++) {
      final sourceY = ((y + 0.5) * source.height / height - 0.5).clamp(
        0,
        source.height - 1.0,
      );
      for (var x = 0; x < width; x++) {
        final sourceX = ((x + 0.5) * source.width / width - 0.5).clamp(
          0,
          source.width - 1.0,
        );
        final pixel = source.getPixelInterpolate(
          sourceX,
          sourceY,
          interpolation: img.Interpolation.linear,
        );
        luminance[y * width + x] = pixel.luminanceNormalized.toDouble();
      }
    }
    return GrayImagePlane._(width: width, height: height, luminance: luminance);
  }

  final int width;
  final int height;
  final Float32List luminance;

  double at(int x, int y) => luminance[y * width + x];

  EdgeEvidence sobel({double quantile = 0.86, int maxPoints = 50000}) {
    if (!quantile.isFinite ||
        quantile <= 0.5 ||
        quantile >= 1 ||
        maxPoints < 256 ||
        maxPoints > 100000) {
      throw ArgumentError('Invalid Sobel edge extraction budget.');
    }
    final magnitude = Float32List(width * height);
    final nonZero = <double>[];
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final topLeft = at(x - 1, y - 1);
        final top = at(x, y - 1);
        final topRight = at(x + 1, y - 1);
        final left = at(x - 1, y);
        final right = at(x + 1, y);
        final bottomLeft = at(x - 1, y + 1);
        final bottom = at(x, y + 1);
        final bottomRight = at(x + 1, y + 1);
        final gradientX =
            -topLeft -
            2 * left -
            bottomLeft +
            topRight +
            2 * right +
            bottomRight;
        final gradientY =
            -topLeft -
            2 * top -
            topRight +
            bottomLeft +
            2 * bottom +
            bottomRight;
        final value = math.sqrt(gradientX * gradientX + gradientY * gradientY);
        magnitude[y * width + x] = value;
        if (value > 1e-6) nonZero.add(value);
      }
    }
    if (nonZero.isEmpty) {
      return EdgeEvidence(
        width: width,
        height: height,
        points: const <EdgePoint>[],
      );
    }
    nonZero.sort();
    final threshold = math.max(
      0.04,
      nonZero[((nonZero.length - 1) * quantile).round()],
    );
    var qualifying = 0;
    for (final value in magnitude) {
      if (value >= threshold) qualifying++;
    }
    final stride = math.max(1, (qualifying / maxPoints).ceil());
    final points = <EdgePoint>[];
    var qualifiedIndex = 0;
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final value = magnitude[y * width + x];
        if (value < threshold) continue;
        if (qualifiedIndex % stride == 0 && points.length < maxPoints) {
          points.add(EdgePoint(x: x, y: y, strength: value.clamp(0, 4) / 4));
        }
        qualifiedIndex++;
      }
    }
    return EdgeEvidence(width: width, height: height, points: points);
  }

  ({List<double> horizontal, List<double> vertical}) darknessProjections() {
    final horizontal = List<double>.filled(height, 0);
    final vertical = List<double>.filled(width, 0);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final darkness = 1 - at(x, y);
        horizontal[y] += darkness;
        vertical[x] += darkness;
      }
    }
    for (var y = 0; y < height; y++) {
      horizontal[y] /= width;
    }
    for (var x = 0; x < width; x++) {
      vertical[x] /= height;
    }
    return (horizontal: horizontal, vertical: vertical);
  }
}

final class EdgePoint {
  const EdgePoint({required this.x, required this.y, required this.strength});

  final int x;
  final int y;
  final double strength;
}

final class EdgeEvidence {
  EdgeEvidence({
    required this.width,
    required this.height,
    required List<EdgePoint> points,
  }) : points = List<EdgePoint>.unmodifiable(points) {
    if (width <= 0 || height <= 0 || points.length > 100000) {
      throw ArgumentError('Invalid bounded edge evidence.');
    }
  }

  final int width;
  final int height;
  final List<EdgePoint> points;
}
