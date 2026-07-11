import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/vision/vision.dart';

import '../features/scan_test_fakes.dart';

void main() {
  const incompleteBoard = BoardVisionException(
    BoardVisionErrorCode.boardNotFound,
    'board not found',
  );

  group('ScanCaptureController guide fallback', () {
    test(
      'retains the same bounded camera bundle and preserves capture metadata',
      () async {
        final frames = fakeFrames(7);
        FrameBundle? automaticBundle;
        FrameBundle? guideBundle;
        final platform = _ControlledScanPlatform(cameraFrames: frames);
        final automatic = _CallbackVision((bundle) async {
          automaticBundle = bundle;
          throw incompleteBoard;
        });
        final guide = _CallbackVision((bundle) async {
          guideBundle = bundle;
          return fakeScanDraft();
        });
        final controller = ScanCaptureController(
          platform: platform,
          vision: automatic,
          guideFallback: guide,
        );
        addTearDown(controller.dispose);

        expect(await controller.captureCamera(), isNull);

        expect(
          controller.failureKind,
          ScanCaptureFailureKind.recognitionIncompleteBoard,
        );
        expect(controller.canUseGuideFallback, isTrue);
        expect(controller.debugRetainedGuideFrameCount, 3);
        expect(
          controller.debugRetainedGuideEncodedByteCount,
          frames
              .take(3)
              .fold<int>(
                0,
                (total, frame) => total + frame.encodedBytes.length,
              ),
        );
        expect(automaticBundle?.source, FrameSource.cameraBurst);
        expect(automaticBundle?.frames, hasLength(3));

        final payload = await controller.retryWithGuide();

        expect(payload, isNotNull);
        expect(identical(guideBundle, automaticBundle), isTrue);
        expect(payload!.originalFrame, same(frames.first));
        expect(payload.inputKind, ScanInputKind.camera);
        expect(payload.usedBurst, isTrue);
        expect(platform.captureCalls, 1);
        expect(controller.canUseGuideFallback, isFalse);
        expect(controller.debugRetainedGuideFrameCount, 0);
        expect(controller.debugRetainedGuideEncodedByteCount, 0);
      },
    );

    test('preserves a photo-library frame and input kind', () async {
      final frame = fakeFrame(12);
      FrameBundle? automaticBundle;
      FrameBundle? guideBundle;
      final platform = _ControlledScanPlatform(libraryFrame: frame);
      final controller = ScanCaptureController(
        platform: platform,
        vision: _CallbackVision((bundle) async {
          automaticBundle = bundle;
          throw incompleteBoard;
        }),
        guideFallback: _CallbackVision((bundle) async {
          guideBundle = bundle;
          return fakeScanDraft();
        }),
      );
      addTearDown(controller.dispose);

      expect(await controller.pickFromLibrary(), isNull);
      expect(controller.debugRetainedGuideFrameCount, 1);

      final payload = await controller.retryWithGuide();

      expect(identical(guideBundle, automaticBundle), isTrue);
      expect(payload?.originalFrame, same(frame));
      expect(payload?.inputKind, ScanInputKind.photoLibrary);
      expect(payload?.usedBurst, isFalse);
      expect(platform.libraryCalls, 1);
    });

    test('does not retain frames for platform or untyped failures', () async {
      final platformFailureController = ScanCaptureController(
        platform: _ControlledScanPlatform(
          captureError: const ScanPlatformException(
            ScanPlatformFailureKind.captureFailed,
            'capture failed',
          ),
        ),
        vision: _CallbackVision((_) async => fakeScanDraft()),
        guideFallback: _CallbackVision((_) async => fakeScanDraft()),
      );
      addTearDown(platformFailureController.dispose);

      expect(await platformFailureController.captureCamera(), isNull);
      expect(
        platformFailureController.failureKind,
        ScanCaptureFailureKind.cameraCaptureFailed,
      );
      expect(platformFailureController.canUseGuideFallback, isFalse);
      expect(platformFailureController.debugRetainedGuideFrameCount, 0);

      final untypedFailureController = ScanCaptureController(
        platform: _ControlledScanPlatform(),
        vision: _CallbackVision((_) async => throw StateError('bad frame')),
        guideFallback: _CallbackVision((_) async => fakeScanDraft()),
      );
      addTearDown(untypedFailureController.dispose);

      expect(await untypedFailureController.captureCamera(), isNull);
      expect(
        untypedFailureController.failureKind,
        ScanCaptureFailureKind.recognitionFailed,
      );
      expect(untypedFailureController.canUseGuideFallback, isFalse);
      expect(untypedFailureController.debugRetainedGuideFrameCount, 0);
    });

    test('does not offer guide retry for unusable frame bytes', () async {
      for (final code in <BoardVisionErrorCode>[
        BoardVisionErrorCode.undecodableFrame,
        BoardVisionErrorCode.frameTooSmall,
        BoardVisionErrorCode.resourceLimitExceeded,
        BoardVisionErrorCode.invalidFrameMetadata,
      ]) {
        final controller = ScanCaptureController(
          platform: _ControlledScanPlatform(),
          vision: _CallbackVision(
            (_) async => throw BoardVisionException(code, code.name),
          ),
          guideFallback: _CallbackVision((_) async => fakeScanDraft()),
        );

        expect(await controller.captureCamera(), isNull, reason: code.name);
        expect(controller.canUseGuideFallback, isFalse, reason: code.name);
        expect(controller.debugRetainedGuideFrameCount, 0, reason: code.name);
        controller.dispose();
      }
    });

    test('types repeated guide failures and keeps retry available', () async {
      var guideAttempt = 0;
      final controller = ScanCaptureController(
        platform: _ControlledScanPlatform(),
        vision: _CallbackVision((_) async => throw incompleteBoard),
        guideFallback: _CallbackVision((_) async {
          guideAttempt++;
          if (guideAttempt == 1) throw incompleteBoard;
          if (guideAttempt == 2) throw StateError('guide pipeline failed');
          return fakeScanDraft();
        }),
      );
      addTearDown(controller.dispose);

      await controller.captureCamera();

      expect(await controller.retryWithGuide(), isNull);
      expect(
        controller.failureKind,
        ScanCaptureFailureKind.recognitionIncompleteBoard,
      );
      expect(controller.canUseGuideFallback, isTrue);
      expect(controller.debugRetainedGuideFrameCount, 3);

      expect(await controller.retryWithGuide(), isNull);
      expect(controller.failureKind, ScanCaptureFailureKind.recognitionFailed);
      expect(controller.canUseGuideFallback, isTrue);
      expect(controller.debugRetainedGuideFrameCount, 3);

      expect(await controller.retryWithGuide(), isNotNull);
      expect(controller.canUseGuideFallback, isFalse);
      expect(controller.debugRetainedGuideFrameCount, 0);
    });

    test(
      'new selection, lifecycle cancellation, and dispose release frames',
      () async {
        final platform = _ControlledScanPlatform();
        final controller = ScanCaptureController(
          platform: platform,
          vision: _CallbackVision((_) async => throw incompleteBoard),
          guideFallback: _CallbackVision((_) async => fakeScanDraft()),
        );

        await controller.captureCamera();
        expect(controller.debugRetainedGuideFrameCount, 3);

        platform.libraryFrame = null;
        await controller.pickFromLibrary();
        expect(controller.canUseGuideFallback, isFalse);
        expect(controller.debugRetainedGuideFrameCount, 0);

        await controller.captureCamera();
        expect(controller.debugRetainedGuideFrameCount, 3);
        await controller.suspend();
        expect(controller.phase, ScanCapturePhase.suspended);
        expect(controller.debugRetainedGuideFrameCount, 0);

        await controller.resume();
        await controller.captureCamera();
        expect(controller.debugRetainedGuideFrameCount, 3);
        controller.dispose();
        expect(controller.canUseGuideFallback, isFalse);
        expect(controller.debugRetainedGuideFrameCount, 0);
        expect(controller.debugRetainedGuideEncodedByteCount, 0);
      },
    );

    test(
      'ignores stale guide completion after lifecycle cancellation',
      () async {
        final guideCompleter = Completer<ScanDraft>();
        final platform = _ControlledScanPlatform();
        final guide = _CallbackVision((_) => guideCompleter.future);
        final controller = ScanCaptureController(
          platform: platform,
          vision: _CallbackVision((_) async => throw incompleteBoard),
          guideFallback: guide,
        );
        addTearDown(controller.dispose);

        await controller.captureCamera();
        final pendingRetry = controller.retryWithGuide();
        expect(controller.phase, ScanCapturePhase.recognizing);
        expect(guide.calls, 1);

        // A second tap cannot start a competing recognition generation.
        expect(await controller.retryWithGuide(), isNull);
        expect(guide.calls, 1);

        await controller.suspend();
        expect(controller.debugRetainedGuideFrameCount, 0);
        guideCompleter.complete(fakeScanDraft());

        expect(await pendingRetry, isNull);
        expect(controller.phase, ScanCapturePhase.suspended);
        expect(controller.canUseGuideFallback, isFalse);
      },
    );
  });
}

final class _CallbackVision implements BoardVision {
  _CallbackVision(this.callback);

  final Future<ScanDraft> Function(FrameBundle bundle) callback;
  int calls = 0;

  @override
  Future<ScanDraft> recognize(FrameBundle frames) {
    calls++;
    return callback(frames);
  }
}

final class _ControlledScanPlatform implements ScanCapturePlatform {
  _ControlledScanPlatform({
    List<CapturedFrame>? cameraFrames,
    CapturedFrame? libraryFrame,
    this.captureError,
  }) : cameraFrames = cameraFrames ?? fakeFrames(3),
       libraryFrame = libraryFrame ?? fakeFrame(9);

  final List<CapturedFrame> cameraFrames;
  CapturedFrame? libraryFrame;
  final Object? captureError;
  bool ready = true;
  int captureCalls = 0;
  int libraryCalls = 0;
  int disposeCalls = 0;
  ScanFlashMode mode = ScanFlashMode.automatic;

  @override
  bool get isReady => ready;

  @override
  ScanFlashMode get flashMode => mode;

  @override
  Widget? buildPreview() => null;

  @override
  Future<void> initialize() async {
    ready = true;
  }

  @override
  Future<void> resume() => initialize();

  @override
  Future<void> suspend() async {
    ready = false;
  }

  @override
  Future<List<CapturedFrame>> takeBurst({int preferredCount = 3}) async {
    captureCalls++;
    if (captureError case final error?) throw error;
    return cameraFrames;
  }

  @override
  Future<CapturedFrame?> pickFromLibrary() async {
    libraryCalls++;
    if (captureError case final error?) throw error;
    return libraryFrame;
  }

  @override
  Future<void> cycleFlash() async {
    mode = switch (mode) {
      ScanFlashMode.automatic => ScanFlashMode.off,
      ScanFlashMode.off => ScanFlashMode.on,
      ScanFlashMode.on => ScanFlashMode.automatic,
    };
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    ready = false;
  }
}
