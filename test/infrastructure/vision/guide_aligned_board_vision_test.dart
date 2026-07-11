import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/vision/vision.dart';

void main() {
  group('GuideAlignedBoardVision', () {
    test('recognizes a complete synthetic 19-line physical board', () async {
      final bytes = _syntheticBoard(
        stones: <BoardPoint, StoneColor>{
          const BoardPoint(3, 3): StoneColor.black,
          const BoardPoint(15, 15): StoneColor.white,
          const BoardPoint(9, 9): StoneColor.black,
        },
      );
      final frame = CapturedFrame(
        encodedBytes: bytes,
        pixelWidth: 640,
        pixelHeight: 640,
        capturedAt: DateTime.utc(2026, 7, 11),
      );

      final result = await const GuideAlignedBoardVision().recognize(
        FrameBundle(
          source: FrameSource.photoLibrary,
          frames: <CapturedFrame>[frame],
        ),
      );

      expect(result.kind, ScanKind.physicalBoard);
      expect(result.boardSize, BoardSize.nineteen);
      expect(result.intersections, hasLength(361));
      expect(
        _at(result, const BoardPoint(3, 3)).predictedStone,
        StoneColor.black,
      );
      expect(
        _at(result, const BoardPoint(15, 15)).predictedStone,
        StoneColor.white,
      );
      expect(
        _at(result, const BoardPoint(9, 9)).predictedStone,
        StoneColor.black,
      );
      expect(_at(result, const BoardPoint(10, 10)).predictedStone, isNull);
      expect(
        _at(result, const BoardPoint(10, 10)).confidence,
        greaterThan(0.9),
      );
      expect(result.boardConfidence, greaterThanOrEqualTo(0.9));
    });

    test(
      'fuses a camera burst and preserves the aligned crop bounds',
      () async {
        final bytes = _syntheticBoard(
          stones: <BoardPoint, StoneColor>{
            const BoardPoint(4, 4): StoneColor.white,
          },
        );
        final frames = <CapturedFrame>[
          for (var index = 0; index < 3; index++)
            CapturedFrame(
              encodedBytes: bytes,
              pixelWidth: 640,
              pixelHeight: 640,
              capturedAt: DateTime.utc(2026, 7, 11, 0, 0, index),
            ),
        ];

        final result = await const GuideAlignedBoardVision().recognize(
          FrameBundle(source: FrameSource.cameraBurst, frames: frames),
        );

        expect(
          _at(result, const BoardPoint(4, 4)).predictedStone,
          StoneColor.white,
        );
        expect(result.boardBounds.topLeft.x, closeTo(0.05, 0.01));
        expect(result.boardBounds.bottomRight.x, closeTo(0.95, 0.01));
      },
    );

    test('rejects corrupt and undersized inputs explicitly', () async {
      final corrupt = CapturedFrame(
        encodedBytes: Uint8List.fromList(<int>[1, 2, 3]),
        pixelWidth: 640,
        pixelHeight: 640,
        capturedAt: DateTime.utc(2026, 7, 11),
      );
      await expectLater(
        const GuideAlignedBoardVision().recognize(
          FrameBundle(
            source: FrameSource.file,
            frames: <CapturedFrame>[corrupt],
          ),
        ),
        throwsA(
          isA<BoardVisionException>().having(
            (error) => error.code,
            'code',
            BoardVisionErrorCode.undecodableFrame,
          ),
        ),
      );

      final tinyBytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 64, height: 64)),
      );
      final tiny = CapturedFrame(
        encodedBytes: tinyBytes,
        pixelWidth: 64,
        pixelHeight: 64,
        capturedAt: DateTime.utc(2026, 7, 11),
      );
      await expectLater(
        const GuideAlignedBoardVision().recognize(
          FrameBundle(source: FrameSource.file, frames: <CapturedFrame>[tiny]),
        ),
        throwsA(
          isA<BoardVisionException>().having(
            (error) => error.code,
            'code',
            BoardVisionErrorCode.frameTooSmall,
          ),
        ),
      );
    });
  });
}

IntersectionPrediction _at(ScanDraft draft, BoardPoint point) =>
    draft.intersections.singleWhere((prediction) => prediction.point == point);

Uint8List _syntheticBoard({required Map<BoardPoint, StoneColor> stones}) {
  const size = 640;
  const cropSide = 576;
  const cropOrigin = 32;
  final image = img.Image(width: size, height: size);
  img.fill(image, color: img.ColorRgb8(64, 57, 46));
  img.fillRect(
    image,
    x1: cropOrigin,
    y1: cropOrigin,
    x2: cropOrigin + cropSide,
    y2: cropOrigin + cropSide,
    color: img.ColorRgb8(211, 177, 113),
  );
  const inset = cropSide * 0.055;
  const step = (cropSide - inset * 2) / 18;
  final lineColor = img.ColorRgb8(82, 61, 38);
  for (var index = 0; index < 19; index++) {
    final offset = (cropOrigin + inset + index * step).round();
    final start = (cropOrigin + inset).round();
    final end = (cropOrigin + cropSide - inset).round();
    img.drawLine(
      image,
      x1: start,
      y1: offset,
      x2: end,
      y2: offset,
      color: lineColor,
      thickness: 2,
    );
    img.drawLine(
      image,
      x1: offset,
      y1: start,
      x2: offset,
      y2: end,
      color: lineColor,
      thickness: 2,
    );
  }
  for (final entry in stones.entries) {
    final x = (cropOrigin + inset + entry.key.column * step).round();
    final y = (cropOrigin + inset + entry.key.row * step).round();
    img.fillCircle(
      image,
      x: x,
      y: y,
      radius: (step * 0.45).round(),
      color: entry.value == StoneColor.black
          ? img.ColorRgb8(24, 29, 27)
          : img.ColorRgb8(246, 244, 237),
    );
  }
  return Uint8List.fromList(img.encodePng(image));
}
