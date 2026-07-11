import 'dart:math' as math;

import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

import 'automatic_board_vision.dart';
import 'geometry/geometry.dart';
import 'mlkit_digit_text_recognition_gateway.dart';

/// Detects board geometry/stones first, then promotes the draft to a numbered
/// diagram only when enough spatially aligned numeric evidence exists.
final class HybridBoardVision implements BoardVision {
  HybridBoardVision({
    BoardVision? boardVision,
    TextRecognitionGateway? textRecognition,
    this.minimumNumberedTokens = 8,
    this.maximumMoveNumber = 999,
    this.maximumIntersectionDistance = 0.52,
    this.maximumTextRegions = 1024,
    this.duplicateConfidenceCeiling = 0.79,
  }) : _boardVision = boardVision ?? const AutomaticBoardVision(),
       _textRecognition = textRecognition ?? MlKitDigitTextRecognitionGateway();

  final BoardVision _boardVision;
  final TextRecognitionGateway _textRecognition;
  final int minimumNumberedTokens;
  final int maximumMoveNumber;
  final double maximumIntersectionDistance;
  final int maximumTextRegions;
  final double duplicateConfidenceCeiling;

  @override
  Future<ScanDraft> recognize(FrameBundle frames) async {
    if (minimumNumberedTokens < 3 ||
        maximumMoveNumber < 40 ||
        maximumMoveNumber > 9999 ||
        !maximumIntersectionDistance.isFinite ||
        maximumIntersectionDistance <= 0 ||
        maximumIntersectionDistance > 0.75 ||
        maximumTextRegions < minimumNumberedTokens ||
        maximumTextRegions > 4096 ||
        !duplicateConfidenceCeiling.isFinite ||
        duplicateConfidenceCeiling < 0 ||
        duplicateConfidenceCeiling >= 0.9) {
      throw ArgumentError('Invalid hybrid vision configuration.');
    }
    final board = await _boardVision.recognize(frames);
    List<RecognizedTextRegion> regions;
    try {
      regions = await _textRecognition.recognize(frames.frames.first);
    } on Object {
      // Number OCR is an optional, on-device promotion layer. A missing plugin
      // or recognizer failure must never discard a valid physical-board result.
      return board;
    }
    if (regions.length > maximumTextRegions) return board;
    final tokens = _tokensFor(board, regions);
    if (tokens.length < minimumNumberedTokens) return board;
    return ScanDraft(
      kind: ScanKind.numberedDiagram,
      boardSize: board.boardSize,
      boardBounds: board.boardBounds,
      intersections: board.intersections,
      sequenceTokens: tokens,
      boardConfidence: board.boardConfidence,
    );
  }

  List<SequenceToken> _tokensFor(
    ScanDraft board,
    List<RecognizedTextRegion> regions,
  ) {
    final dimension = board.boardSize.dimension;
    final normalizedToGrid = Homography.fromPointPairs(
      source: <ProjectivePoint>[
        for (final point in board.boardBounds.vertices)
          ProjectivePoint(point.x, point.y),
      ],
      destination: <ProjectivePoint>[
        ProjectivePoint(0, 0),
        ProjectivePoint((dimension - 1).toDouble(), 0),
        ProjectivePoint((dimension - 1).toDouble(), (dimension - 1).toDouble()),
        ProjectivePoint(0, (dimension - 1).toDouble()),
      ],
    );
    final predictionByPoint = <BoardPoint, IntersectionPrediction>{
      for (final prediction in board.intersections)
        prediction.point: prediction,
    };
    final candidatesByNumber = <int, List<SequenceToken>>{};
    final occurrenceCount = <int, int>{};
    for (final region in regions) {
      final number = int.tryParse(region.text);
      if (number == null || number < 1 || number > maximumMoveNumber) continue;
      occurrenceCount.update(number, (count) => count + 1, ifAbsent: () => 1);
      ProjectivePoint projected;
      try {
        projected = normalizedToGrid.project(
          ProjectivePoint(region.bounds.centerX, region.bounds.centerY),
        );
      } on HomographyException {
        continue;
      }
      final column = projected.x.round();
      final row = projected.y.round();
      final point = BoardPoint(column, row);
      if (!point.isOn(board.boardSize)) continue;
      final distance = math.sqrt(
        math.pow(projected.x - column, 2) + math.pow(projected.y - row, 2),
      );
      if (distance > maximumIntersectionDistance) continue;
      final prediction = predictionByPoint[point];
      final color = prediction?.predictedStone;
      if (prediction == null || color == null) continue;
      final spatial = 1 - distance / maximumIntersectionDistance;
      final confidence =
          (region.confidence * 0.55 +
                  spatial * 0.25 +
                  prediction.confidence * 0.2)
              .clamp(0, 1)
              .toDouble();
      final token = SequenceToken(
        moveNumber: number,
        move: Move.play(color: color, point: point),
        confidence: confidence,
      );
      candidatesByNumber
          .putIfAbsent(number, () => <SequenceToken>[])
          .add(token);
    }
    final tokens = <SequenceToken>[
      for (final entry in candidatesByNumber.entries)
        _winnerFor(
          entry.value,
          hasDuplicateEvidence: (occurrenceCount[entry.key] ?? 0) > 1,
        ),
    ]..sort((left, right) => left.moveNumber.compareTo(right.moveNumber));
    return tokens;
  }

  SequenceToken _winnerFor(
    List<SequenceToken> candidates, {
    required bool hasDuplicateEvidence,
  }) {
    candidates.sort(
      (left, right) => right.confidence.compareTo(left.confidence),
    );
    final winner = candidates.first;
    if (!hasDuplicateEvidence) return winner;
    return SequenceToken(
      moveNumber: winner.moveNumber,
      move: winner.move,
      confidence: math.min(winner.confidence, duplicateConfidenceCeiling),
    );
  }
}
