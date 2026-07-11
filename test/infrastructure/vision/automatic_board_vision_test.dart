import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/vision/vision.dart';

void main() {
  for (final boardSize in BoardSize.values) {
    test(
      'detects and rectifies a perspective ${boardSize.dimension}-line board',
      () async {
        final synthetic = _syntheticPerspectiveBoard(boardSize: boardSize);
        final result = await const AutomaticBoardVision().recognize(
          FrameBundle(
            source: FrameSource.photoLibrary,
            frames: <CapturedFrame>[_captured(synthetic)],
          ),
        );

        expect(result.boardSize, boardSize);
        expect(
          result.intersections,
          hasLength(boardSize.dimension * boardSize.dimension),
        );
        expect(result.boardBounds.isConvex, isTrue);
        expect(result.boardConfidence, greaterThan(0.5));
      },
    );
  }

  test(
    'detects an explicitly rotated frame without assuming portrait axes',
    () async {
      final synthetic = _syntheticPerspectiveBoard(
        boardSize: BoardSize.thirteen,
      );
      final result = await const AutomaticBoardVision().recognize(
        FrameBundle(
          source: FrameSource.file,
          frames: <CapturedFrame>[
            _captured(synthetic, rotation: FrameRotation.degrees90),
          ],
        ),
      );

      expect(result.boardSize, BoardSize.thirteen);
      expect(result.intersections, hasLength(169));
    },
  );

  test('rectifies moving burst frames before probability fusion', () async {
    final frames = <CapturedFrame>[
      for (final shift in <int>[-3, 0, 4])
        _captured(
          _syntheticPerspectiveBoard(
            boardSize: BoardSize.nineteen,
            shiftX: shift,
            shiftY: -shift ~/ 2,
          ),
        ),
    ];
    final result = await const AutomaticBoardVision().recognize(
      FrameBundle(source: FrameSource.cameraBurst, frames: frames),
    );

    expect(result.boardSize, BoardSize.nineteen);
    expect(result.intersections, hasLength(361));
    expect(
      _predictionAt(result, const BoardPoint(3, 3)).predictedStone,
      StoneColor.black,
    );
    expect(
      _predictionAt(result, const BoardPoint(15, 15)).predictedStone,
      StoneColor.white,
    );
  });

  test('a tied burst board-size vote fails explicitly', () async {
    final frames = <CapturedFrame>[
      _captured(_syntheticPerspectiveBoard(boardSize: BoardSize.nine)),
      _captured(_syntheticPerspectiveBoard(boardSize: BoardSize.thirteen)),
      _captured(_syntheticPerspectiveBoard(boardSize: BoardSize.nineteen)),
    ];

    await expectLater(
      const AutomaticBoardVision().recognize(
        FrameBundle(source: FrameSource.cameraBurst, frames: frames),
      ),
      throwsA(
        isA<BoardVisionException>().having(
          (error) => error.code,
          'code',
          BoardVisionErrorCode.inconsistentBoardSize,
        ),
      ),
    );
  });

  test(
    'blank input fails explicitly instead of invoking guide fallback',
    () async {
      final blank = img.Image(width: 760, height: 600);
      img.fill(blank, color: img.ColorRgb8(100, 100, 100));

      await expectLater(
        const AutomaticBoardVision().recognize(
          FrameBundle(
            source: FrameSource.file,
            frames: <CapturedFrame>[_captured(blank)],
          ),
        ),
        throwsA(
          isA<BoardVisionException>().having(
            (error) => error.code,
            'code',
            BoardVisionErrorCode.insufficientDetectedFrames,
          ),
        ),
      );
    },
  );

  test('insufficient geometry margin produces a typed ambiguity', () async {
    final synthetic = _syntheticPerspectiveBoard(boardSize: BoardSize.nineteen);

    await expectLater(
      const AutomaticBoardVision(
        detector: ClassicalGridBoardDetector(minimumGeometryMargin: 1),
      ).recognize(
        FrameBundle(
          source: FrameSource.file,
          frames: <CapturedFrame>[_captured(synthetic)],
        ),
      ),
      throwsA(
        isA<BoardVisionException>().having(
          (error) => error.code,
          'code',
          BoardVisionErrorCode.ambiguousBoard,
        ),
      ),
    );
  });
}

IntersectionPrediction _predictionAt(ScanDraft draft, BoardPoint point) =>
    draft.intersections.singleWhere((prediction) => prediction.point == point);

CapturedFrame _captured(
  img.Image image, {
  FrameRotation rotation = FrameRotation.degrees0,
}) {
  final bytes = Uint8List.fromList(img.encodePng(image));
  return CapturedFrame(
    encodedBytes: bytes,
    pixelWidth: image.width,
    pixelHeight: image.height,
    capturedAt: DateTime.utc(2026, 7, 11),
    rotation: rotation,
  );
}

img.Image _syntheticPerspectiveBoard({
  required BoardSize boardSize,
  int shiftX = 0,
  int shiftY = 0,
}) {
  const canonicalSide = 560;
  const gridStart = 38.0;
  const gridEnd = canonicalSide - 39.0;
  final canonical = img.Image(
    width: canonicalSide,
    height: canonicalSide,
    numChannels: 4,
  );
  img.fill(canonical, color: img.ColorRgba8(214, 178, 109, 255));
  final lineColor = img.ColorRgba8(65, 47, 30, 255);
  final step = (gridEnd - gridStart) / (boardSize.dimension - 1);
  for (var index = 0; index < boardSize.dimension; index++) {
    final position = (gridStart + step * index).round();
    img.drawLine(
      canonical,
      x1: gridStart.round(),
      y1: position,
      x2: gridEnd.round(),
      y2: position,
      color: lineColor,
      thickness: 2,
    );
    img.drawLine(
      canonical,
      x1: position,
      y1: gridStart.round(),
      x2: position,
      y2: gridEnd.round(),
      color: lineColor,
      thickness: 2,
    );
  }
  final stones = <BoardPoint, StoneColor>{
    const BoardPoint(3, 3): StoneColor.black,
    BoardPoint(boardSize.dimension - 4, boardSize.dimension - 4):
        StoneColor.white,
    BoardPoint(boardSize.dimension ~/ 2, boardSize.dimension ~/ 2):
        StoneColor.black,
  };
  for (final entry in stones.entries) {
    final x = (gridStart + entry.key.column * step).round();
    final y = (gridStart + entry.key.row * step).round();
    img.fillCircle(
      canonical,
      x: x,
      y: y,
      radius: mathMax(4, (step * 0.43).round()),
      color: entry.value == StoneColor.black
          ? img.ColorRgba8(22, 25, 24, 255)
          : img.ColorRgba8(246, 244, 237, 255),
    );
  }

  const frameWidth = 760;
  const frameHeight = 600;
  final destination = <ProjectivePoint>[
    ProjectivePoint(112.0 + shiftX, 52.0 + shiftY),
    ProjectivePoint(650.0 + shiftX, 78.0 + shiftY),
    ProjectivePoint(704.0 + shiftX, 548.0 + shiftY),
    ProjectivePoint(64.0 + shiftX, 520.0 + shiftY),
  ];
  final transform = Homography.fromPointPairs(
    source: <ProjectivePoint>[
      ProjectivePoint(0, 0),
      ProjectivePoint(canonicalSide - 1.0, 0),
      ProjectivePoint(canonicalSide - 1.0, canonicalSide - 1.0),
      ProjectivePoint(0, canonicalSide - 1.0),
    ],
    destination: destination,
  );
  final projected = warpPerspective(
    source: canonical,
    sourceToDestination: transform,
    outputWidth: frameWidth,
    outputHeight: frameHeight,
    maxOutputPixels: frameWidth * frameHeight,
  );
  final frame = img.Image(
    width: frameWidth,
    height: frameHeight,
    numChannels: 4,
  );
  img.fill(frame, color: img.ColorRgba8(55, 53, 48, 255));
  img.compositeImage(frame, projected);
  return frame;
}

int mathMax(int left, int right) => left > right ? left : right;
