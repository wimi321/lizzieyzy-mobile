import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

void main() {
  const validBounds = BoardQuadrilateral(
    topLeft: NormalizedPoint(0.08, 0.12),
    topRight: NormalizedPoint(0.91, 0.08),
    bottomRight: NormalizedPoint(0.95, 0.92),
    bottomLeft: NormalizedPoint(0.05, 0.88),
  );

  ScanDraft draftWith(
    BoardQuadrilateral bounds, {
    List<SequenceToken> tokens = const <SequenceToken>[],
  }) => ScanDraft(
    kind: ScanKind.physicalBoard,
    boardSize: BoardSize.nine,
    boardBounds: bounds,
    intersections: const <IntersectionPrediction>[],
    sequenceTokens: tokens,
    boardConfidence: 0.5,
  );

  test('accepts an ordered convex perspective quadrilateral', () {
    expect(validBounds.isConvex, isTrue);
    expect(validBounds.signedArea, closeTo(0.692, 1e-4));
    expect(() => validBounds.validate(), returnsNormally);
    expect(() => draftWith(validBounds), returnsNormally);
  });

  test(
    'rejects out-of-range and non-finite bounds without relying on asserts',
    () {
      const outOfRange = BoardQuadrilateral(
        topLeft: NormalizedPoint(-0.1, 0.1),
        topRight: NormalizedPoint(0.9, 0.1),
        bottomRight: NormalizedPoint(0.9, 0.9),
        bottomLeft: NormalizedPoint(0.1, 0.9),
      );
      const nonFinite = BoardQuadrilateral(
        topLeft: NormalizedPoint(double.nan, 0.1),
        topRight: NormalizedPoint(0.9, 0.1),
        bottomRight: NormalizedPoint(0.9, 0.9),
        bottomLeft: NormalizedPoint(0.1, 0.9),
      );

      expect(() => draftWith(outOfRange), throwsRangeError);
      expect(() => draftWith(nonFinite), throwsArgumentError);
    },
  );

  test('rejects self-intersection, reversed order, and negligible area', () {
    const selfIntersecting = BoardQuadrilateral(
      topLeft: NormalizedPoint(0.1, 0.1),
      topRight: NormalizedPoint(0.9, 0.9),
      bottomRight: NormalizedPoint(0.9, 0.1),
      bottomLeft: NormalizedPoint(0.1, 0.9),
    );
    const reversed = BoardQuadrilateral(
      topLeft: NormalizedPoint(0.1, 0.1),
      topRight: NormalizedPoint(0.1, 0.9),
      bottomRight: NormalizedPoint(0.9, 0.9),
      bottomLeft: NormalizedPoint(0.9, 0.1),
    );
    const tiny = BoardQuadrilateral(
      topLeft: NormalizedPoint(0.1, 0.1),
      topRight: NormalizedPoint(0.10001, 0.1),
      bottomRight: NormalizedPoint(0.10001, 0.10001),
      bottomLeft: NormalizedPoint(0.1, 0.10001),
    );

    expect(() => draftWith(selfIntersecting), throwsArgumentError);
    expect(() => draftWith(reversed), throwsArgumentError);
    expect(() => draftWith(tiny), throwsArgumentError);
  });

  test('validates sequence token values and uniqueness in release code', () {
    const move = Move.play(color: StoneColor.black, point: BoardPoint(2, 2));
    expect(
      () => draftWith(
        validBounds,
        tokens: const <SequenceToken>[
          SequenceToken(moveNumber: 0, move: move, confidence: 1),
        ],
      ),
      throwsRangeError,
    );
    expect(
      () => draftWith(
        validBounds,
        tokens: const <SequenceToken>[
          SequenceToken(moveNumber: 1, move: move, confidence: double.nan),
        ],
      ),
      throwsRangeError,
    );
    expect(
      () => draftWith(
        validBounds,
        tokens: const <SequenceToken>[
          SequenceToken(moveNumber: 1, move: move, confidence: 1),
          SequenceToken(moveNumber: 1, move: move, confidence: 1),
        ],
      ),
      throwsArgumentError,
    );
  });
}
