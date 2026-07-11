import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/vision/vision.dart';

void main() {
  const tokenPoints = <BoardPoint>[
    BoardPoint(0, 0),
    BoardPoint(1, 0),
    BoardPoint(2, 0),
    BoardPoint(3, 0),
    BoardPoint(4, 0),
    BoardPoint(5, 0),
    BoardPoint(6, 0),
    BoardPoint(7, 0),
  ];

  test('maps perspective OCR centers back to exact intersections', () async {
    final board = _physicalDraft();
    final gateway = _FakeTextRecognitionGateway(
      regions: <RecognizedTextRegion>[
        for (var index = 0; index < tokenPoints.length; index++)
          _regionFor(board, tokenPoints[index], moveNumber: index + 1),
      ],
    );
    final vision = HybridBoardVision(
      boardVision: _FakeBoardVision(board),
      textRecognition: gateway,
    );

    final result = await vision.recognize(_frameBundle());

    expect(result.kind, ScanKind.numberedDiagram);
    expect(result.sequenceTokens, hasLength(8));
    for (var index = 0; index < result.sequenceTokens.length; index++) {
      expect(result.sequenceTokens[index].moveNumber, index + 1);
      expect(result.sequenceTokens[index].move.point, tokenPoints[index]);
    }
    expect(result.needsCorrection, isFalse);
    expect(gateway.calls, 1);
  });

  test('insufficient numeric evidence preserves the physical draft', () async {
    final board = _physicalDraft();
    final gateway = _FakeTextRecognitionGateway(
      regions: <RecognizedTextRegion>[
        for (var index = 0; index < 7; index++)
          _regionFor(board, tokenPoints[index], moveNumber: index + 1),
      ],
    );

    final result = await HybridBoardVision(
      boardVision: _FakeBoardVision(board),
      textRecognition: gateway,
    ).recognize(_frameBundle());

    expect(identical(result, board), isTrue);
    expect(result.kind, ScanKind.physicalBoard);
  });

  test(
    'duplicate move evidence keeps one winner but forces confirmation',
    () async {
      const competingPoint = BoardPoint(0, 1);
      final board = _physicalDraft(
        additionalStones: <BoardPoint, StoneColor>{
          competingPoint: StoneColor.black,
        },
      );
      final regions = <RecognizedTextRegion>[
        for (var index = 0; index < tokenPoints.length; index++)
          _regionFor(
            board,
            tokenPoints[index],
            moveNumber: index + 1,
            confidence: index == 0 ? 0.94 : 0.99,
          ),
        _regionFor(board, competingPoint, moveNumber: 1, confidence: 0.995),
      ];

      final result = await HybridBoardVision(
        boardVision: _FakeBoardVision(board),
        textRecognition: _FakeTextRecognitionGateway(regions: regions),
      ).recognize(_frameBundle());

      expect(result.kind, ScanKind.numberedDiagram);
      expect(result.sequenceTokens, hasLength(8));
      final winner = result.sequenceTokens.singleWhere(
        (token) => token.moveNumber == 1,
      );
      expect(winner.move.point, competingPoint);
      expect(winner.confidence, lessThan(0.9));
      expect(winner.confidence, 0.79);
      expect(result.needsCorrection, isTrue);
    },
  );

  test('misaligned and empty-point OCR regions are rejected', () async {
    final board = _physicalDraft();
    final regions = <RecognizedTextRegion>[
      for (var index = 0; index < tokenPoints.length; index++)
        _regionFor(board, tokenPoints[index], moveNumber: index + 1),
      _regionForGridCoordinate(board, 2.5, 2.5, moveNumber: 9),
      _regionFor(board, const BoardPoint(8, 8), moveNumber: 10),
    ];

    final result = await HybridBoardVision(
      boardVision: _FakeBoardVision(board),
      textRecognition: _FakeTextRecognitionGateway(regions: regions),
    ).recognize(_frameBundle());

    expect(result.kind, ScanKind.numberedDiagram);
    expect(result.sequenceTokens, hasLength(8));
    expect(
      result.sequenceTokens.map((token) => token.moveNumber),
      isNot(contains(anyOf(9, 10))),
    );
  });

  test(
    'parseable duplicate on an empty point still lowers the valid winner',
    () async {
      final board = _physicalDraft();
      final regions = <RecognizedTextRegion>[
        for (var index = 0; index < tokenPoints.length; index++)
          _regionFor(board, tokenPoints[index], moveNumber: index + 1),
        _regionFor(board, const BoardPoint(8, 8), moveNumber: 2),
      ];

      final result = await HybridBoardVision(
        boardVision: _FakeBoardVision(board),
        textRecognition: _FakeTextRecognitionGateway(regions: regions),
      ).recognize(_frameBundle());

      expect(
        result.sequenceTokens
            .singleWhere((token) => token.moveNumber == 2)
            .confidence,
        0.79,
      );
      expect(result.needsCorrection, isTrue);
    },
  );

  test(
    'OCR region budget overflow cannot promote the physical draft',
    () async {
      final board = _physicalDraft();
      final regions = <RecognizedTextRegion>[
        for (var index = 0; index < tokenPoints.length; index++)
          _regionFor(board, tokenPoints[index], moveNumber: index + 1),
        _regionFor(board, tokenPoints.first, moveNumber: 9),
      ];

      final result = await HybridBoardVision(
        boardVision: _FakeBoardVision(board),
        textRecognition: _FakeTextRecognitionGateway(regions: regions),
        maximumTextRegions: 8,
      ).recognize(_frameBundle());

      expect(identical(result, board), isTrue);
    },
  );

  test(
    'unavailable OCR plugin degrades locally without network or failure',
    () async {
      final board = _physicalDraft();
      final gateway = _FakeTextRecognitionGateway(
        error: StateError('no plugin'),
      );

      final result = await HybridBoardVision(
        boardVision: _FakeBoardVision(board),
        textRecognition: gateway,
      ).recognize(_frameBundle());

      expect(identical(result, board), isTrue);
      expect(gateway.calls, 1);
    },
  );
}

ScanDraft _physicalDraft({
  Map<BoardPoint, StoneColor> additionalStones =
      const <BoardPoint, StoneColor>{},
}) {
  const bounds = BoardQuadrilateral(
    topLeft: NormalizedPoint(0.12, 0.08),
    topRight: NormalizedPoint(0.90, 0.14),
    bottomRight: NormalizedPoint(0.84, 0.90),
    bottomLeft: NormalizedPoint(0.08, 0.82),
  );
  final stones = <BoardPoint, StoneColor>{
    for (var index = 0; index < 8; index++)
      BoardPoint(index, 0): index.isEven ? StoneColor.black : StoneColor.white,
    ...additionalStones,
  };
  return ScanDraft(
    kind: ScanKind.physicalBoard,
    boardSize: BoardSize.nine,
    boardBounds: bounds,
    intersections: <IntersectionPrediction>[
      for (var row = 0; row < 9; row++)
        for (var column = 0; column < 9; column++)
          _prediction(BoardPoint(column, row), stones[BoardPoint(column, row)]),
    ],
    boardConfidence: 0.98,
  );
}

IntersectionPrediction _prediction(BoardPoint point, StoneColor? stone) =>
    switch (stone) {
      StoneColor.black => IntersectionPrediction(
        point: point,
        blackProbability: 0.98,
        whiteProbability: 0.01,
        emptyProbability: 0.01,
      ),
      StoneColor.white => IntersectionPrediction(
        point: point,
        blackProbability: 0.01,
        whiteProbability: 0.98,
        emptyProbability: 0.01,
      ),
      null => IntersectionPrediction(
        point: point,
        blackProbability: 0.01,
        whiteProbability: 0.01,
        emptyProbability: 0.98,
      ),
    };

RecognizedTextRegion _regionFor(
  ScanDraft board,
  BoardPoint point, {
  required int moveNumber,
  double confidence = 0.99,
}) => _regionForGridCoordinate(
  board,
  point.column.toDouble(),
  point.row.toDouble(),
  moveNumber: moveNumber,
  confidence: confidence,
);

RecognizedTextRegion _regionForGridCoordinate(
  ScanDraft board,
  double column,
  double row, {
  required int moveNumber,
  double confidence = 0.99,
}) {
  final dimension = board.boardSize.dimension;
  final gridToNormalized = Homography.fromPointPairs(
    source: <ProjectivePoint>[
      ProjectivePoint(0, 0),
      ProjectivePoint((dimension - 1).toDouble(), 0),
      ProjectivePoint((dimension - 1).toDouble(), (dimension - 1).toDouble()),
      ProjectivePoint(0, (dimension - 1).toDouble()),
    ],
    destination: <ProjectivePoint>[
      for (final point in board.boardBounds.vertices)
        ProjectivePoint(point.x, point.y),
    ],
  );
  final center = gridToNormalized.project(ProjectivePoint(column, row));
  const half = 0.004;
  return RecognizedTextRegion(
    text: '$moveNumber',
    bounds: NormalizedTextRect(
      left: center.x - half,
      top: center.y - half,
      right: center.x + half,
      bottom: center.y + half,
    ),
    confidence: confidence,
  );
}

FrameBundle _frameBundle() => FrameBundle(
  source: FrameSource.file,
  frames: <CapturedFrame>[
    CapturedFrame(
      encodedBytes: Uint8List.fromList(<int>[1, 2, 3]),
      pixelWidth: 1200,
      pixelHeight: 900,
      capturedAt: DateTime.utc(2026, 7, 11),
    ),
  ],
);

final class _FakeBoardVision implements BoardVision {
  const _FakeBoardVision(this.result);

  final ScanDraft result;

  @override
  Future<ScanDraft> recognize(FrameBundle frames) async => result;
}

final class _FakeTextRecognitionGateway implements TextRecognitionGateway {
  _FakeTextRecognitionGateway({
    this.regions = const <RecognizedTextRegion>[],
    this.error,
  });

  final List<RecognizedTextRegion> regions;
  final Object? error;
  int calls = 0;

  @override
  Future<List<RecognizedTextRegion>> recognize(CapturedFrame frame) async {
    calls++;
    if (error case final error?) throw error;
    return regions;
  }
}
