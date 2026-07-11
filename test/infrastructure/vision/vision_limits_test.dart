import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/vision/vision.dart';

void main() {
  CapturedFrame frame({int bytes = 3, int width = 100, int height = 100}) =>
      CapturedFrame(
        encodedBytes: Uint8List(bytes),
        pixelWidth: width,
        pixelHeight: height,
        capturedAt: DateTime.utc(2026, 7, 11),
      );

  test('rejects per-frame, bundle, and declared-pixel budget violations', () {
    final single = FrameBundle(
      source: FrameSource.file,
      frames: <CapturedFrame>[frame(bytes: 4)],
    );
    expect(
      () => const VisionResourceLimits(
        maxEncodedBytesPerFrame: 3,
        maxEncodedBytesPerBundle: 6,
      ).validateBundle(single),
      throwsA(
        isA<VisionResourceException>().having(
          (error) => error.violation,
          'violation',
          VisionResourceViolation.encodedFrameTooLarge,
        ),
      ),
    );

    final burst = FrameBundle(
      source: FrameSource.cameraBurst,
      frames: <CapturedFrame>[
        frame(bytes: 3),
        frame(bytes: 3),
        frame(bytes: 3),
      ],
    );
    expect(
      () => const VisionResourceLimits(
        maxEncodedBytesPerFrame: 4,
        maxEncodedBytesPerBundle: 8,
      ).validateBundle(burst),
      throwsA(
        isA<VisionResourceException>().having(
          (error) => error.violation,
          'violation',
          VisionResourceViolation.encodedBundleTooLarge,
        ),
      ),
    );
    expect(
      () => const VisionResourceLimits(
        maxDimension: 200,
        maxPixelsPerFrame: 9000,
        maxPixelsPerBundle: 27000,
      ).validateBundle(single),
      throwsA(
        isA<VisionResourceException>().having(
          (error) => error.violation,
          'violation',
          VisionResourceViolation.declaredPixelCountTooLarge,
        ),
      ),
    );
  });

  test('rejects decoded dimensions that disagree with trusted metadata', () {
    final captured = frame(width: 640, height: 480);
    expect(
      () => const VisionResourceLimits().validateDecodedFrame(
        captured,
        decodedWidth: 641,
        decodedHeight: 480,
      ),
      throwsA(
        isA<VisionResourceException>().having(
          (error) => error.violation,
          'violation',
          VisionResourceViolation.frameMetadataMismatch,
        ),
      ),
    );
  });

  test('guide recognizer maps metadata mismatch to a typed vision failure', () {
    final image = img.Image(width: 128, height: 128);
    final encoded = Uint8List.fromList(img.encodePng(image));
    final captured = CapturedFrame(
      encodedBytes: encoded,
      pixelWidth: 129,
      pixelHeight: 128,
      capturedAt: DateTime.utc(2026, 7, 11),
    );

    expect(
      () => const GuideAlignedBoardVision(minimumFrameSide: 128).recognize(
        FrameBundle(
          source: FrameSource.file,
          frames: <CapturedFrame>[captured],
        ),
      ),
      throwsA(
        isA<BoardVisionException>().having(
          (error) => error.code,
          'code',
          BoardVisionErrorCode.invalidFrameMetadata,
        ),
      ),
    );
  });

  test('guide recognizer validates its const configuration at runtime', () {
    final image = img.Image(width: 128, height: 128);
    final encoded = Uint8List.fromList(img.encodePng(image));
    final captured = CapturedFrame(
      encodedBytes: encoded,
      pixelWidth: 128,
      pixelHeight: 128,
      capturedAt: DateTime.utc(2026, 7, 11),
    );

    expect(
      () =>
          const GuideAlignedBoardVision(
            cropFraction: 0.4,
            minimumFrameSide: 128,
          ).recognize(
            FrameBundle(
              source: FrameSource.file,
              frames: <CapturedFrame>[captured],
            ),
          ),
      throwsRangeError,
    );
  });
}
