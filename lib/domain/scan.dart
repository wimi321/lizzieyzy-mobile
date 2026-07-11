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
  const NormalizedPoint(this.x, this.y);

  final double x;
  final double y;

  /// Enforces the normalized-coordinate contract in release builds.
  ///
  /// The constructor remains `const` so scan fixtures and immutable manifests
  /// can use compile-time values. Trust boundaries such as [ScanDraft] must call
  /// this method instead of relying on debug-only assertions.
  void validate({String name = 'point'}) {
    if (!x.isFinite || !y.isFinite) {
      throw ArgumentError.value(this, name, 'Coordinates must be finite.');
    }
    if (x < 0 || x > 1 || y < 0 || y > 1) {
      throw RangeError('$name must lie inside the normalized unit square.');
    }
  }
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

  List<NormalizedPoint> get vertices => List<NormalizedPoint>.unmodifiable(
    <NormalizedPoint>[topLeft, topRight, bottomRight, bottomLeft],
  );

  /// Signed area in normalized image coordinates.
  ///
  /// With the app's screen coordinate system (positive Y points down), a
  /// correctly ordered top-left → top-right → bottom-right → bottom-left quad
  /// has a positive area.
  double get signedArea {
    final points = vertices;
    var twiceArea = 0.0;
    for (var index = 0; index < points.length; index++) {
      final current = points[index];
      final next = points[(index + 1) % points.length];
      twiceArea += current.x * next.y - current.y * next.x;
    }
    return twiceArea / 2;
  }

  bool get isConvex {
    final points = vertices;
    var expectedSign = 0;
    for (var index = 0; index < points.length; index++) {
      final a = points[index];
      final b = points[(index + 1) % points.length];
      final c = points[(index + 2) % points.length];
      final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
      if (!cross.isFinite || cross.abs() <= 1e-12) return false;
      final sign = cross > 0 ? 1 : -1;
      expectedSign = expectedSign == 0 ? sign : expectedSign;
      if (sign != expectedSign) return false;
    }
    return expectedSign > 0;
  }

  /// Validates ordering, convexity, edge length, and usable area at the domain
  /// trust boundary. This intentionally runs in release mode.
  void validate({double minimumArea = 0.0001}) {
    if (!minimumArea.isFinite || minimumArea <= 0 || minimumArea > 1) {
      throw RangeError.range(minimumArea, 0, 1, 'minimumArea');
    }
    final points = vertices;
    for (var index = 0; index < points.length; index++) {
      points[index].validate(name: 'boardBounds[$index]');
      final next = points[(index + 1) % points.length];
      final dx = next.x - points[index].x;
      final dy = next.y - points[index].y;
      if (dx * dx + dy * dy <= 1e-8) {
        throw ArgumentError(
          'Board quadrilateral contains a duplicate or near-zero edge.',
        );
      }
    }
    if (!isConvex) {
      throw ArgumentError(
        'Board quadrilateral must be a clockwise, strictly convex polygon.',
      );
    }
    final area = signedArea;
    if (!area.isFinite || area < minimumArea) {
      throw ArgumentError.value(
        area,
        'boardBounds',
        'Board quadrilateral has insufficient usable area.',
      );
    }
  }
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
  });

  final int moveNumber;
  final Move move;
  final double confidence;

  void validate() {
    if (moveNumber < 1) {
      throw RangeError.value(moveNumber, 'moveNumber', 'Must be positive.');
    }
    if (!confidence.isFinite || confidence < 0 || confidence > 1) {
      throw RangeError.range(confidence, 0, 1, 'confidence');
    }
  }
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
    boardBounds.validate();
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
    final moveNumbers = <int>{};
    for (final token in sequenceTokens) {
      token.validate();
      if (!moveNumbers.add(token.moveNumber)) {
        throw ArgumentError(
          'Scan draft contains duplicate move number ${token.moveNumber}.',
        );
      }
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

  bool get hasContiguousNumberedSequence {
    if (sequenceTokens.isEmpty) return false;
    final sorted = sequenceTokens.map((token) => token.moveNumber).toList()
      ..sort();
    for (var index = 0; index < sorted.length; index++) {
      if (sorted[index] != index + 1) return false;
    }
    return true;
  }

  bool get needsCorrection =>
      boardConfidence < 0.9 ||
      !hasCompleteIntersectionGrid ||
      intersections.any((prediction) => prediction.confidence < 0.9) ||
      sequenceTokens.any((token) => token.confidence < 0.9) ||
      (kind == ScanKind.numberedDiagram && !hasContiguousNumberedSequence);
}
