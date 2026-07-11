import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:lizzieyzy_mobile/domain/domain.dart';

final class RectifiedBoardSample {
  RectifiedBoardSample({
    required List<IntersectionPrediction> intersections,
    required this.quality,
  }) : intersections = List<IntersectionPrediction>.unmodifiable(intersections);

  final List<IntersectionPrediction> intersections;

  /// Relative sampling quality used only as a fusion weight.
  final double quality;
}

/// Samples a board after its detected outer grid corners have been mapped to a
/// square with explicit padding. This keeps perspective correction separate
/// from stone classification and makes per-frame motion harmless to fusion.
abstract final class RectifiedBoardSampler {
  static RectifiedBoardSample sample({
    required img.Image image,
    required BoardSize boardSize,
    required double gridMargin,
  }) {
    if (!gridMargin.isFinite || gridMargin < 2) {
      throw ArgumentError.value(gridMargin, 'gridMargin');
    }
    final usableSide = math.min(image.width, image.height) - 1 - 2 * gridMargin;
    if (usableSide <= boardSize.dimension * 2) {
      throw ArgumentError('Rectified board has insufficient sampling detail.');
    }
    final step = usableSide / (boardSize.dimension - 1);
    final centerRadius = math.max(2, (step * 0.31).round());
    final ringInnerRadius = math.max(centerRadius + 1, (step * 0.53).round());
    final ringOuterRadius = math.max(ringInnerRadius + 1, (step * 0.7).round());
    final predictions = <IntersectionPrediction>[];
    var exposureQuality = 0.0;
    var confidenceQuality = 0.0;

    for (var row = 0; row < boardSize.dimension; row++) {
      for (var column = 0; column < boardSize.dimension; column++) {
        final x = (gridMargin + column * step).round();
        final y = (gridMargin + row * step).round();
        final ring = _sampleAnnulus(
          image,
          x,
          y,
          innerRadius: ringInnerRadius,
          outerRadius: ringOuterRadius,
        );
        final center = _sampleAnnulus(
          image,
          x,
          y,
          innerRadius: 0,
          outerRadius: centerRadius,
        );
        final weights = _classify(center, ring);
        final prediction = IntersectionPrediction(
          point: BoardPoint(column, row),
          blackProbability: weights.black,
          whiteProbability: weights.white,
          emptyProbability: weights.empty,
        );
        predictions.add(prediction);
        final normalizedExposure = 1 - ((ring.meanLuminance - 150).abs() / 170);
        exposureQuality += normalizedExposure.clamp(0, 1);
        confidenceQuality += prediction.confidence;
      }
    }
    final total = boardSize.dimension * boardSize.dimension;
    return RectifiedBoardSample(
      intersections: predictions,
      quality:
          (0.45 * exposureQuality / total + 0.55 * confidenceQuality / total)
              .clamp(0.05, 1),
    );
  }
}

_PixelSample _sampleAnnulus(
  img.Image image,
  int centerX,
  int centerY, {
  required int innerRadius,
  required int outerRadius,
}) {
  final luminances = <double>[];
  var luminanceSum = 0.0;
  var chromaSum = 0.0;
  final innerSquared = innerRadius * innerRadius;
  final outerSquared = outerRadius * outerRadius;
  for (var yOffset = -outerRadius; yOffset <= outerRadius; yOffset++) {
    for (var xOffset = -outerRadius; xOffset <= outerRadius; xOffset++) {
      final distanceSquared = xOffset * xOffset + yOffset * yOffset;
      if (distanceSquared < innerSquared || distanceSquared > outerSquared) {
        continue;
      }
      final x = centerX + xOffset;
      final y = centerY + yOffset;
      if (x < 0 || y < 0 || x >= image.width || y >= image.height) continue;
      final pixel = image.getPixel(x, y);
      final red = pixel.rNormalized.toDouble() * 255;
      final green = pixel.gNormalized.toDouble() * 255;
      final blue = pixel.bNormalized.toDouble() * 255;
      final luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue;
      final chroma =
          math.max(red, math.max(green, blue)) -
          math.min(red, math.min(green, blue));
      luminances.add(luminance);
      luminanceSum += luminance;
      chromaSum += chroma;
    }
  }
  if (luminances.isEmpty) {
    throw ArgumentError('A rectified intersection falls outside the image.');
  }
  return _PixelSample(
    luminances: luminances,
    meanLuminance: luminanceSum / luminances.length,
    meanChroma: chromaSum / luminances.length,
  );
}

_ClassWeights _classify(_PixelSample center, _PixelSample ring) {
  final darkThreshold = math.min(112.0, ring.meanLuminance - 42);
  final lightThreshold = math.max(205.0, ring.meanLuminance + 22);
  final darkFraction =
      center.luminances.where((value) => value < darkThreshold).length /
      center.luminances.length;
  final lightFraction = center.meanChroma < 48
      ? center.luminances.where((value) => value > lightThreshold).length /
            center.luminances.length
      : 0.0;
  final dominantStoneFraction = math.max(darkFraction, lightFraction);
  final black =
      math.pow(math.max(0, (darkFraction - 0.18) / 0.7), 2).toDouble() + 0.006;
  final white =
      math.pow(math.max(0, (lightFraction - 0.2) / 0.65), 2).toDouble() + 0.006;
  final empty =
      math
          .pow(math.max(0, (0.66 - dominantStoneFraction) / 0.66), 2)
          .toDouble() +
      0.006;
  final total = black + white + empty;
  return _ClassWeights(
    black: black / total,
    white: white / total,
    empty: empty / total,
  );
}

final class _PixelSample {
  const _PixelSample({
    required this.luminances,
    required this.meanLuminance,
    required this.meanChroma,
  });

  final List<double> luminances;
  final double meanLuminance;
  final double meanChroma;
}

final class _ClassWeights {
  const _ClassWeights({
    required this.black,
    required this.white,
    required this.empty,
  });

  final double black;
  final double white;
  final double empty;
}
