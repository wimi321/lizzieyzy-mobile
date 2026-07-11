import 'dart:isolate';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:lizzieyzy_mobile/domain/domain.dart';

enum BoardVisionErrorCode {
  undecodableFrame,
  frameTooSmall,
  unsupportedGeometry,
}

final class BoardVisionException implements Exception {
  const BoardVisionException(this.code, this.message);

  final BoardVisionErrorCode code;
  final String message;

  @override
  String toString() => 'BoardVisionException(${code.name}): $message';
}

/// A deterministic physical-board recognizer for the camera guide workflow.
///
/// The capture UI asks the user to place the complete board inside a centered
/// square guide. This implementation decodes the real frames, normalizes their
/// orientation, samples every intersection, and fuses a 3–7 frame burst. It is
/// deliberately conservative: uncertain intersections flow into correction
/// instead of being silently committed as stones.
///
/// Perspective-free guide alignment is the v1 baseline. A learned corner
/// detector can replace only [_cropFor] without changing [BoardVision] or the
/// correction data contract.
final class GuideAlignedBoardVision implements BoardVision {
  const GuideAlignedBoardVision({
    this.boardSize = BoardSize.nineteen,
    this.cropFraction = 0.9,
    this.gridInsetFraction = 0.055,
    this.minimumFrameSide = 320,
  }) : assert(cropFraction > 0.5 && cropFraction <= 1),
       assert(gridInsetFraction >= 0 && gridInsetFraction < 0.2),
       assert(minimumFrameSide >= 128);

  final BoardSize boardSize;
  final double cropFraction;
  final double gridInsetFraction;
  final int minimumFrameSide;

  @override
  Future<ScanDraft> recognize(FrameBundle frames) => Isolate.run(
    () => _recognizeSync(
      frames,
      boardSize: boardSize,
      cropFraction: cropFraction,
      gridInsetFraction: gridInsetFraction,
      minimumFrameSide: minimumFrameSide,
    ),
  );
}

ScanDraft _recognizeSync(
  FrameBundle bundle, {
  required BoardSize boardSize,
  required double cropFraction,
  required double gridInsetFraction,
  required int minimumFrameSide,
}) {
  final probabilitySums = <BoardPoint, _ClassWeights>{};
  _Crop? firstCrop;
  int? firstWidth;
  int? firstHeight;
  var qualitySum = 0.0;

  for (final frame in bundle.frames) {
    img.Image? source;
    try {
      source = img.decodeImage(frame.encodedBytes);
    } on Object {
      source = null;
    }
    if (source == null) {
      throw const BoardVisionException(
        BoardVisionErrorCode.undecodableFrame,
        'The captured frame is not a supported image.',
      );
    }
    var oriented = img.bakeOrientation(source);
    oriented = switch (frame.rotation) {
      FrameRotation.degrees0 => oriented,
      FrameRotation.degrees90 => img.copyRotate(oriented, angle: 90),
      FrameRotation.degrees180 => img.copyRotate(oriented, angle: 180),
      FrameRotation.degrees270 => img.copyRotate(oriented, angle: 270),
    };
    if (math.min(oriented.width, oriented.height) < minimumFrameSide) {
      throw BoardVisionException(
        BoardVisionErrorCode.frameTooSmall,
        'A board frame needs at least $minimumFrameSide pixels on its short side.',
      );
    }
    final crop = _cropFor(oriented, cropFraction);
    firstCrop ??= crop;
    firstWidth ??= oriented.width;
    firstHeight ??= oriented.height;
    final sampled = _sampleFrame(oriented, crop, boardSize, gridInsetFraction);
    qualitySum += sampled.quality;
    for (final entry in sampled.weights.entries) {
      probabilitySums.update(
        entry.key,
        (current) => current + entry.value,
        ifAbsent: () => entry.value,
      );
    }
  }

  final divisor = bundle.frames.length.toDouble();
  final predictions = <IntersectionPrediction>[
    for (var row = 0; row < boardSize.dimension; row++)
      for (var column = 0; column < boardSize.dimension; column++)
        _prediction(
          BoardPoint(column, row),
          probabilitySums[BoardPoint(column, row)]! / divisor,
        ),
  ];
  final width = firstWidth!.toDouble();
  final height = firstHeight!.toDouble();
  final boundsCrop = firstCrop!;
  final bounds = BoardQuadrilateral(
    topLeft: NormalizedPoint(boundsCrop.left / width, boundsCrop.top / height),
    topRight: NormalizedPoint(
      boundsCrop.right / width,
      boundsCrop.top / height,
    ),
    bottomRight: NormalizedPoint(
      boundsCrop.right / width,
      boundsCrop.bottom / height,
    ),
    bottomLeft: NormalizedPoint(
      boundsCrop.left / width,
      boundsCrop.bottom / height,
    ),
  );

  return ScanDraft(
    kind: ScanKind.physicalBoard,
    boardSize: boardSize,
    boardBounds: bounds,
    intersections: predictions,
    boardConfidence: (qualitySum / divisor).clamp(0, 1),
  );
}

_Crop _cropFor(img.Image image, double cropFraction) {
  final side = (math.min(image.width, image.height) * cropFraction).round();
  if (side <= 0) {
    throw const BoardVisionException(
      BoardVisionErrorCode.unsupportedGeometry,
      'The board crop has no usable area.',
    );
  }
  final left = ((image.width - side) / 2).round();
  final top = ((image.height - side) / 2).round();
  return _Crop(left: left, top: top, side: side);
}

_FrameSample _sampleFrame(
  img.Image image,
  _Crop crop,
  BoardSize boardSize,
  double gridInsetFraction,
) {
  final inset = crop.side * gridInsetFraction;
  final step = (crop.side - inset * 2) / (boardSize.dimension - 1);
  final centerRadius = math.max(2, (step * 0.31).round());
  final ringInnerRadius = math.max(centerRadius + 1, (step * 0.53).round());
  final ringOuterRadius = math.max(ringInnerRadius + 1, (step * 0.7).round());
  final weights = <BoardPoint, _ClassWeights>{};
  var exposureQuality = 0.0;

  for (var row = 0; row < boardSize.dimension; row++) {
    for (var column = 0; column < boardSize.dimension; column++) {
      final x = (crop.left + inset + column * step).round();
      final y = (crop.top + inset + row * step).round();
      final ring = _sampleDisk(
        image,
        x,
        y,
        innerRadius: ringInnerRadius,
        outerRadius: ringOuterRadius,
      );
      final center = _sampleDisk(
        image,
        x,
        y,
        innerRadius: 0,
        outerRadius: centerRadius,
      );
      weights[BoardPoint(column, row)] = _classify(center, ring);
      final normalizedExposure = 1 - ((ring.meanLuminance - 150).abs() / 170);
      exposureQuality += normalizedExposure.clamp(0, 1);
    }
  }

  final total = boardSize.dimension * boardSize.dimension;
  return _FrameSample(
    weights: weights,
    quality: (0.9 + 0.08 * exposureQuality / total).clamp(0, 0.98),
  );
}

_PixelSample _sampleDisk(
  img.Image image,
  int centerX,
  int centerY, {
  required int innerRadius,
  required int outerRadius,
}) {
  var luminanceSum = 0.0;
  var chromaSum = 0.0;
  final luminances = <double>[];
  final innerSquared = innerRadius * innerRadius;
  final outerSquared = outerRadius * outerRadius;
  for (var dy = -outerRadius; dy <= outerRadius; dy++) {
    for (var dx = -outerRadius; dx <= outerRadius; dx++) {
      final distanceSquared = dx * dx + dy * dy;
      if (distanceSquared < innerSquared || distanceSquared > outerSquared) {
        continue;
      }
      final x = (centerX + dx).clamp(0, image.width - 1);
      final y = (centerY + dy).clamp(0, image.height - 1);
      final pixel = image.getPixel(x, y);
      final red = pixel.r.toDouble();
      final green = pixel.g.toDouble();
      final blue = pixel.b.toDouble();
      final luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue;
      final chroma =
          math.max(red, math.max(green, blue)) -
          math.min(red, math.min(green, blue));
      luminanceSum += luminance;
      chromaSum += chroma;
      luminances.add(luminance);
    }
  }
  if (luminances.isEmpty) {
    throw const BoardVisionException(
      BoardVisionErrorCode.unsupportedGeometry,
      'An intersection sample fell outside the image.',
    );
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
  return _ClassWeights(black: black, white: white, empty: empty).normalized;
}

IntersectionPrediction _prediction(BoardPoint point, _ClassWeights weights) {
  final normalized = weights.normalized;
  return IntersectionPrediction(
    point: point,
    blackProbability: normalized.black,
    whiteProbability: normalized.white,
    emptyProbability: normalized.empty,
  );
}

final class _Crop {
  const _Crop({required this.left, required this.top, required this.side});

  final int left;
  final int top;
  final int side;

  int get right => left + side;
  int get bottom => top + side;
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

  _ClassWeights get normalized {
    final sum = black + white + empty;
    return _ClassWeights(
      black: black / sum,
      white: white / sum,
      empty: empty / sum,
    );
  }

  _ClassWeights operator +(_ClassWeights other) => _ClassWeights(
    black: black + other.black,
    white: white + other.white,
    empty: empty + other.empty,
  );

  _ClassWeights operator /(double divisor) => _ClassWeights(
    black: black / divisor,
    white: white / divisor,
    empty: empty / divisor,
  );
}

final class _FrameSample {
  const _FrameSample({required this.weights, required this.quality});

  final Map<BoardPoint, _ClassWeights> weights;
  final double quality;
}
