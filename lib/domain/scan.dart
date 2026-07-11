import 'dart:typed_data';

import 'go_values.dart';

enum FrameSource { cameraBurst, photoLibrary, file }

enum FrameRotation { degrees0, degrees90, degrees180, degrees270 }

final class CapturedFrame {
  CapturedFrame({
    required Uint8List encodedBytes,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.capturedAt,
    this.rotation = FrameRotation.degrees0,
  }) : encodedBytes = Uint8List.fromList(encodedBytes) {
    if (encodedBytes.isEmpty) {
      throw ArgumentError.value(
        encodedBytes,
        'encodedBytes',
        'A frame cannot be empty.',
      );
    }
    if (pixelWidth <= 0 || pixelHeight <= 0) {
      throw ArgumentError('Frame dimensions must be positive.');
    }
  }

  final Uint8List encodedBytes;
  final int pixelWidth;
  final int pixelHeight;
  final DateTime capturedAt;
  final FrameRotation rotation;
}

final class FrameBundle {
  FrameBundle({required this.source, required List<CapturedFrame> frames})
    : frames = List.unmodifiable(frames) {
    if (frames.isEmpty || frames.length > 7) {
      throw ArgumentError.value(
        frames.length,
        'frames',
        'A bundle contains 1 to 7 frames.',
      );
    }
    if (source == FrameSource.cameraBurst && frames.length < 3) {
      throw ArgumentError.value(
        frames.length,
        'frames',
        'A camera burst needs at least 3 frames.',
      );
    }
    if (source != FrameSource.cameraBurst && frames.length != 1) {
      throw ArgumentError(
        'Photo-library and file bundles contain exactly one frame.',
      );
    }
  }

  final FrameSource source;
  final List<CapturedFrame> frames;
}

final class NormalizedPoint {
  const NormalizedPoint(this.x, this.y)
    : assert(x >= 0 && x <= 1),
      assert(y >= 0 && y <= 1);

  final double x;
  final double y;
}

final class BoardQuadrilateral {
  const BoardQuadrilateral({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  final NormalizedPoint topLeft;
  final NormalizedPoint topRight;
  final NormalizedPoint bottomRight;
  final NormalizedPoint bottomLeft;
}

enum ScanKind { physicalBoard, numberedDiagram, screenshot, unknown }

final class IntersectionPrediction {
  IntersectionPrediction({
    required this.point,
    required this.blackProbability,
    required this.whiteProbability,
    required this.emptyProbability,
  }) {
    for (final probability in [
      blackProbability,
      whiteProbability,
      emptyProbability,
    ]) {
      if (!probability.isFinite || probability < 0 || probability > 1) {
        throw RangeError.range(probability, 0, 1, 'probability');
      }
    }
    if (blackProbability + whiteProbability + emptyProbability <= 0) {
      throw ArgumentError(
        'At least one intersection class must have non-zero probability.',
      );
    }
  }

  final BoardPoint point;
  final double blackProbability;
  final double whiteProbability;
  final double emptyProbability;

  double get confidence => [
    blackProbability,
    whiteProbability,
    emptyProbability,
  ].reduce((left, right) => left > right ? left : right);

  StoneColor? get predictedStone {
    if (emptyProbability >= blackProbability &&
        emptyProbability >= whiteProbability) {
      return null;
    }
    return blackProbability >= whiteProbability
        ? StoneColor.black
        : StoneColor.white;
  }
}

final class SequenceToken {
  const SequenceToken({
    required this.moveNumber,
    required this.move,
    required this.confidence,
  }) : assert(moveNumber >= 1),
       assert(confidence >= 0 && confidence <= 1);

  final int moveNumber;
  final Move move;
  final double confidence;
}

final class ScanDraft {
  ScanDraft({
    required this.kind,
    required this.boardSize,
    required this.boardBounds,
    required List<IntersectionPrediction> intersections,
    List<SequenceToken> sequenceTokens = const [],
    required this.boardConfidence,
  }) : intersections = List.unmodifiable(intersections),
       sequenceTokens = List.unmodifiable(sequenceTokens) {
    if (!boardConfidence.isFinite ||
        boardConfidence < 0 ||
        boardConfidence > 1) {
      throw RangeError.range(boardConfidence, 0, 1, 'boardConfidence');
    }
    final points = <BoardPoint>{};
    for (final prediction in intersections) {
      if (!prediction.point.isOn(boardSize)) {
        throw RangeError(
          'Scan prediction ${prediction.point} is outside the board.',
        );
      }
      if (!points.add(prediction.point)) {
        throw ArgumentError(
          'Scan draft contains duplicate intersection ${prediction.point}.',
        );
      }
    }
    for (final token in sequenceTokens) {
      if (!token.move.isPass && !token.move.point!.isOn(boardSize)) {
        throw RangeError(
          'Sequence token ${token.moveNumber} is outside the board.',
        );
      }
    }
  }

  final ScanKind kind;
  final BoardSize boardSize;
  final BoardQuadrilateral boardBounds;
  final List<IntersectionPrediction> intersections;
  final List<SequenceToken> sequenceTokens;
  final double boardConfidence;

  bool get hasCompleteIntersectionGrid =>
      intersections.length == boardSize.dimension * boardSize.dimension;

  bool get needsCorrection =>
      boardConfidence < 0.9 ||
      !hasCompleteIntersectionGrid ||
      intersections.any((prediction) => prediction.confidence < 0.9) ||
      sequenceTokens.any((token) => token.confidence < 0.9);
}
