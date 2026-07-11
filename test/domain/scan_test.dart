import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

void main() {
  CapturedFrame frame(int millisecond) => CapturedFrame(
    encodedBytes: Uint8List.fromList([1, 2, 3]),
    pixelWidth: 1920,
    pixelHeight: 1080,
    capturedAt: DateTime.utc(2026, 7, 11, 0, 0, 0, millisecond),
  );

  const bounds = BoardQuadrilateral(
    topLeft: NormalizedPoint(0.1, 0.1),
    topRight: NormalizedPoint(0.9, 0.1),
    bottomRight: NormalizedPoint(0.9, 0.9),
    bottomLeft: NormalizedPoint(0.1, 0.9),
  );

  test('camera burst requires 3 to 7 frames and gallery uses one', () {
    expect(
      () => FrameBundle(source: FrameSource.cameraBurst, frames: [frame(0)]),
      throwsArgumentError,
    );
    expect(
      FrameBundle(
        source: FrameSource.cameraBurst,
        frames: [frame(0), frame(1), frame(2)],
      ).frames,
      hasLength(3),
    );
    expect(
      FrameBundle(source: FrameSource.photoLibrary, frames: [frame(0)]).frames,
      hasLength(1),
    );
  });

  test('complete confident grid does not need correction', () {
    final predictions = [
      for (var row = 0; row < 9; row++)
        for (var column = 0; column < 9; column++)
          IntersectionPrediction(
            point: BoardPoint(column, row),
            blackProbability: 0.01,
            whiteProbability: 0.01,
            emptyProbability: 0.98,
          ),
    ];
    final draft = ScanDraft(
      kind: ScanKind.physicalBoard,
      boardSize: BoardSize.nine,
      boardBounds: bounds,
      intersections: predictions,
      boardConfidence: 0.97,
    );

    expect(draft.hasCompleteIntersectionGrid, isTrue);
    expect(draft.needsCorrection, isFalse);
  });

  test('low-confidence token or incomplete grid requires correction', () {
    final draft = ScanDraft(
      kind: ScanKind.numberedDiagram,
      boardSize: BoardSize.nine,
      boardBounds: bounds,
      intersections: [
        IntersectionPrediction(
          point: const BoardPoint(4, 4),
          blackProbability: 0.45,
          whiteProbability: 0.1,
          emptyProbability: 0.45,
        ),
      ],
      sequenceTokens: const [
        SequenceToken(
          moveNumber: 87,
          move: Move.play(color: StoneColor.black, point: BoardPoint(4, 4)),
          confidence: 0.72,
        ),
      ],
      boardConfidence: 0.95,
    );

    expect(draft.needsCorrection, isTrue);
    expect(draft.intersections.single.predictedStone, isNull);
  });

  test('duplicate or out-of-board predictions are rejected', () {
    final duplicate = IntersectionPrediction(
      point: const BoardPoint(0, 0),
      blackProbability: 1,
      whiteProbability: 0,
      emptyProbability: 0,
    );
    expect(
      () => ScanDraft(
        kind: ScanKind.screenshot,
        boardSize: BoardSize.nine,
        boardBounds: bounds,
        intersections: [duplicate, duplicate],
        boardConfidence: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => ScanDraft(
        kind: ScanKind.screenshot,
        boardSize: BoardSize.nine,
        boardBounds: bounds,
        intersections: [
          IntersectionPrediction(
            point: const BoardPoint(10, 10),
            blackProbability: 1,
            whiteProbability: 0,
            emptyProbability: 0,
          ),
        ],
        boardConfidence: 1,
      ),
      throwsRangeError,
    );
  });
}
