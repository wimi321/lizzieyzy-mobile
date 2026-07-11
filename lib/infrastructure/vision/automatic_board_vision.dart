import 'dart:isolate';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:lizzieyzy_mobile/domain/domain.dart';

import 'geometry/geometry.dart';
import 'grid_board_detector.dart';
import 'guide_aligned_board_vision.dart';
import 'rectified_board_sampler.dart';
import 'vision_limits.dart';

/// Deterministic automatic board pipeline.
///
/// Every accepted frame is independently detected and rectified before stone
/// probabilities are fused. Ambiguous geometry or board size throws a typed
/// failure; callers may then explicitly choose [GuideAlignedBoardVision] as a
/// manual fallback. This class never silently treats the centered guide as an
/// automatic detection.
final class AutomaticBoardVision implements BoardVision {
  const AutomaticBoardVision({
    this.resourceLimits = const VisionResourceLimits(),
    this.detector = const ClassicalGridBoardDetector(),
    this.minimumFrameSide = 320,
    this.rectifiedGridSpacing = 34,
  });

  final VisionResourceLimits resourceLimits;
  final ClassicalGridBoardDetector detector;
  final int minimumFrameSide;
  final int rectifiedGridSpacing;

  @override
  Future<ScanDraft> recognize(FrameBundle frames) {
    _validateConfiguration();
    try {
      resourceLimits.validateBundle(frames);
    } on VisionResourceException catch (error) {
      throw _boardVisionExceptionForResource(error);
    }
    return Isolate.run(
      () => _recognizeAutomaticSync(
        frames,
        resourceLimits: resourceLimits,
        detector: detector,
        minimumFrameSide: minimumFrameSide,
        rectifiedGridSpacing: rectifiedGridSpacing,
      ),
    );
  }

  void _validateConfiguration() {
    resourceLimits.validateConfiguration();
    if (minimumFrameSide < 128 ||
        rectifiedGridSpacing < 20 ||
        rectifiedGridSpacing > 64) {
      throw ArgumentError('Invalid automatic board vision configuration.');
    }
  }
}

ScanDraft _recognizeAutomaticSync(
  FrameBundle bundle, {
  required VisionResourceLimits resourceLimits,
  required ClassicalGridBoardDetector detector,
  required int minimumFrameSide,
  required int rectifiedGridSpacing,
}) {
  final recognized = <_RecognizedFrame>[];
  GridDetectionException? lastDetectionError;
  for (final frame in bundle.frames) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(frame.encodedBytes);
    } on Object {
      decoded = null;
    }
    if (decoded == null) {
      throw const BoardVisionException(
        BoardVisionErrorCode.undecodableFrame,
        'The captured frame is not a supported image.',
      );
    }
    try {
      resourceLimits.validateDecodedFrame(
        frame,
        decodedWidth: decoded.width,
        decodedHeight: decoded.height,
      );
    } on VisionResourceException catch (error) {
      throw _boardVisionExceptionForResource(error);
    }
    var oriented = img.bakeOrientation(decoded);
    oriented = switch (frame.rotation) {
      FrameRotation.degrees0 => oriented,
      FrameRotation.degrees90 => img.copyRotate(oriented, angle: 90),
      FrameRotation.degrees180 => img.copyRotate(oriented, angle: 180),
      FrameRotation.degrees270 => img.copyRotate(oriented, angle: 270),
    };
    if (math.min(oriented.width, oriented.height) < minimumFrameSide) {
      throw BoardVisionException(
        BoardVisionErrorCode.frameTooSmall,
        'An automatic board frame needs at least $minimumFrameSide pixels on '
        'its short side.',
      );
    }

    DetectedBoardGeometry geometry;
    try {
      geometry = detector.detect(oriented);
    } on GridDetectionException catch (error) {
      lastDetectionError = error;
      continue;
    }
    final sample = _rectifyAndSample(oriented, geometry, rectifiedGridSpacing);
    recognized.add(_RecognizedFrame(geometry: geometry, sample: sample));
  }

  final minimumAcceptedFrames = bundle.frames.length == 1
      ? 1
      : math.max(2, (bundle.frames.length / 2).ceil());
  if (recognized.length < minimumAcceptedFrames) {
    final ambiguous =
        lastDetectionError?.code == GridDetectionErrorCode.ambiguousGeometry;
    throw BoardVisionException(
      ambiguous
          ? BoardVisionErrorCode.ambiguousBoard
          : BoardVisionErrorCode.insufficientDetectedFrames,
      'Only ${recognized.length} of ${bundle.frames.length} frames had '
      'decisive automatic grid evidence. '
      '${lastDetectionError?.message ?? ''}',
    );
  }
  final byBoardSize = <BoardSize, List<_RecognizedFrame>>{};
  for (final frame in recognized) {
    byBoardSize
        .putIfAbsent(frame.geometry.boardSize, () => <_RecognizedFrame>[])
        .add(frame);
  }
  final rankedSizes = byBoardSize.entries.toList(growable: false)
    ..sort((left, right) {
      final countOrder = right.value.length.compareTo(left.value.length);
      if (countOrder != 0) return countOrder;
      final leftEvidence = left.value.fold<double>(
        0,
        (sum, frame) => sum + frame.geometry.score,
      );
      final rightEvidence = right.value.fold<double>(
        0,
        (sum, frame) => sum + frame.geometry.score,
      );
      return rightEvidence.compareTo(leftEvidence);
    });
  final winningFrames = rankedSizes.first.value;
  final tiedCount =
      rankedSizes.length > 1 &&
      rankedSizes[1].value.length == winningFrames.length;
  if (tiedCount || winningFrames.length < minimumAcceptedFrames) {
    throw const BoardVisionException(
      BoardVisionErrorCode.inconsistentBoardSize,
      'Accepted frames do not provide a decisive majority board size.',
    );
  }
  final boardSize = rankedSizes.first.key;
  final fused = _fuse(winningFrames, boardSize);
  final first = winningFrames.first;
  final boardConfidence =
      winningFrames.fold<double>(
        0,
        (sum, frame) => sum + frame.geometry.score * frame.sample.quality,
      ) /
      winningFrames.length;
  return ScanDraft(
    kind: ScanKind.physicalBoard,
    boardSize: boardSize,
    boardBounds: first.geometry.bounds,
    intersections: fused,
    boardConfidence: boardConfidence.clamp(0, 0.98),
  );
}

RectifiedBoardSample _rectifyAndSample(
  img.Image image,
  DetectedBoardGeometry geometry,
  int gridSpacing,
) {
  final margin = gridSpacing * 0.75;
  final side =
      ((geometry.boardSize.dimension - 1) * gridSpacing + margin * 2 + 1)
          .round();
  final destination = <ProjectivePoint>[
    ProjectivePoint(margin, margin),
    ProjectivePoint(side - 1 - margin, margin),
    ProjectivePoint(side - 1 - margin, side - 1 - margin),
    ProjectivePoint(margin, side - 1 - margin),
  ];
  final transform = Homography.fromPointPairs(
    source: geometry.pixelCorners(image.width, image.height),
    destination: destination,
  );
  final rectified = warpPerspective(
    source: image,
    sourceToDestination: transform,
    outputWidth: side,
    outputHeight: side,
    maxOutputPixels: 1000000,
  );
  return RectifiedBoardSampler.sample(
    image: rectified,
    boardSize: geometry.boardSize,
    gridMargin: margin,
  );
}

List<IntersectionPrediction> _fuse(
  List<_RecognizedFrame> frames,
  BoardSize boardSize,
) {
  final total = boardSize.dimension * boardSize.dimension;
  final black = List<double>.filled(total, 0);
  final white = List<double>.filled(total, 0);
  final empty = List<double>.filled(total, 0);
  var totalWeight = 0.0;
  for (final frame in frames) {
    if (frame.sample.intersections.length != total) {
      throw const BoardVisionException(
        BoardVisionErrorCode.unsupportedGeometry,
        'A rectified frame did not produce a complete intersection grid.',
      );
    }
    final weight = math.max(0.01, frame.geometry.score * frame.sample.quality);
    totalWeight += weight;
    for (var index = 0; index < total; index++) {
      final prediction = frame.sample.intersections[index];
      black[index] += prediction.blackProbability * weight;
      white[index] += prediction.whiteProbability * weight;
      empty[index] += prediction.emptyProbability * weight;
    }
  }
  return <IntersectionPrediction>[
    for (var index = 0; index < total; index++)
      IntersectionPrediction(
        point: BoardPoint(
          index % boardSize.dimension,
          index ~/ boardSize.dimension,
        ),
        blackProbability: black[index] / totalWeight,
        whiteProbability: white[index] / totalWeight,
        emptyProbability: empty[index] / totalWeight,
      ),
  ];
}

BoardVisionException _boardVisionExceptionForResource(
  VisionResourceException error,
) {
  final code = error.violation == VisionResourceViolation.frameMetadataMismatch
      ? BoardVisionErrorCode.invalidFrameMetadata
      : BoardVisionErrorCode.resourceLimitExceeded;
  return BoardVisionException(code, error.message);
}

final class _RecognizedFrame {
  const _RecognizedFrame({required this.geometry, required this.sample});

  final DetectedBoardGeometry geometry;
  final RectifiedBoardSample sample;
}
