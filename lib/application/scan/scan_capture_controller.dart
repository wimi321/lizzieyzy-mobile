import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/vision/vision.dart';

import 'scan_capture_runtime.dart';

enum ScanCapturePhase {
  idle,
  initializing,
  ready,
  recognizing,
  failure,
  suspended,
}

enum ScanInputKind { camera, photoLibrary }

enum ScanCaptureFailureKind {
  cameraPermissionDenied,
  cameraRestricted,
  cameraUnavailable,
  cameraCaptureFailed,
  photoLibraryPermissionDenied,
  photoLibraryUnavailable,
  selectedImageUnreadable,
  recognitionIncompleteBoard,
  recognitionFailed,
}

final class ScanCapturePayload {
  const ScanCapturePayload({
    required this.draft,
    required this.originalFrame,
    required this.inputKind,
    required this.usedBurst,
  });

  final ScanDraft draft;
  final CapturedFrame originalFrame;
  final ScanInputKind inputKind;
  final bool usedBurst;
}

final class ScanPositionPayload {
  const ScanPositionPayload({
    required this.snapshot,
    required this.originalFrame,
    required this.draft,
  });

  final PositionSnapshot snapshot;
  final CapturedFrame originalFrame;
  final ScanDraft draft;
}

final class _GuideFallbackCapture {
  const _GuideFallbackCapture({
    required this.bundle,
    required this.originalFrame,
    required this.inputKind,
    required this.usedBurst,
  });

  final FrameBundle bundle;
  final CapturedFrame originalFrame;
  final ScanInputKind inputKind;
  final bool usedBurst;
}

/// Owns the asynchronous scan state while keeping widgets declarative.
final class ScanCaptureController extends ChangeNotifier {
  ScanCaptureController({
    required ScanCapturePlatform platform,
    BoardVision? vision,
    BoardVision? guideFallback,
  }) : _platform = platform,
       _vision = vision ?? HybridBoardVision(),
       _guideFallback = guideFallback ?? const GuideAlignedBoardVision();

  final ScanCapturePlatform _platform;
  final BoardVision _vision;
  final BoardVision _guideFallback;
  ScanCapturePhase _phase = ScanCapturePhase.idle;
  ScanCaptureFailureKind? _failureKind;
  ScanInputKind? _lastAttempt;
  _GuideFallbackCapture? _retainedGuideCapture;
  int _operationGeneration = 0;
  bool _disposed = false;

  ScanCapturePhase get phase => _phase;
  ScanCaptureFailureKind? get failureKind => _failureKind;
  bool get hasRetryableCapture => _lastAttempt != null;
  bool get canUseGuideFallback =>
      !_disposed &&
      _phase == ScanCapturePhase.failure &&
      _retainedGuideCapture != null;

  @visibleForTesting
  int get debugRetainedGuideFrameCount =>
      _retainedGuideCapture?.bundle.frames.length ?? 0;

  @visibleForTesting
  int get debugRetainedGuideEncodedByteCount =>
      _retainedGuideCapture?.bundle.frames.fold<int>(
        0,
        (total, frame) => total + frame.encodedBytes.length,
      ) ??
      0;

  ScanFlashMode get flashMode => _platform.flashMode;
  Widget? buildPreview() => _platform.buildPreview();

  Future<void> initialize() async {
    if (_disposed || _phase == ScanCapturePhase.initializing) return;
    if (_platform.isReady) {
      _setPhase(ScanCapturePhase.ready);
      return;
    }
    final operation = ++_operationGeneration;
    _setPhase(ScanCapturePhase.initializing);
    try {
      await _platform.initialize();
      if (!_isCurrent(operation)) return;
      _setPhase(ScanCapturePhase.ready);
    } on Object catch (error) {
      if (!_isCurrent(operation)) return;
      _setFailure(_cameraFailureFor(error));
    }
  }

  Future<void> suspend() async {
    if (_disposed) return;
    ++_operationGeneration;
    _clearGuideFallbackCapture();
    try {
      await _platform.suspend();
    } on Object {
      // Releasing a camera is best-effort; navigation/backgrounding must not
      // be blocked by a platform teardown race.
    }
    _setPhase(ScanCapturePhase.suspended);
  }

  Future<void> resume() async {
    if (_disposed) return;
    final operation = ++_operationGeneration;
    _setPhase(ScanCapturePhase.initializing);
    try {
      await _platform.resume();
      if (!_isCurrent(operation)) return;
      _setPhase(ScanCapturePhase.ready);
    } on Object catch (error) {
      if (!_isCurrent(operation)) return;
      _setFailure(_cameraFailureFor(error));
    }
  }

  Future<ScanCapturePayload?> captureCamera() async {
    if (_phase == ScanCapturePhase.recognizing) return null;
    _clearGuideFallbackCapture();
    final operation = ++_operationGeneration;
    _lastAttempt = ScanInputKind.camera;
    _setPhase(ScanCapturePhase.recognizing);
    FrameBundle? bundle;
    CapturedFrame? originalFrame;
    var usedBurst = false;
    try {
      final frames = await _platform.takeBurst(preferredCount: 3);
      usedBurst = frames.length >= 3;
      originalFrame = frames.first;
      bundle = FrameBundle(
        source: usedBurst ? FrameSource.cameraBurst : FrameSource.file,
        frames: usedBurst
            ? frames.take(3).toList(growable: false)
            : <CapturedFrame>[frames.first],
      );
      final draft = await _vision.recognize(bundle);
      if (!_isCurrent(operation)) return null;
      _clearGuideFallbackCapture();
      _setPhase(ScanCapturePhase.ready);
      return ScanCapturePayload(
        draft: draft,
        originalFrame: originalFrame,
        inputKind: ScanInputKind.camera,
        usedBurst: usedBurst,
      );
    } on Object catch (error) {
      if (!_isCurrent(operation)) return null;
      _retainGuideFallbackIfEligible(
        error: error,
        bundle: bundle,
        originalFrame: originalFrame,
        inputKind: ScanInputKind.camera,
        usedBurst: usedBurst,
      );
      _setFailure(_recognitionFailureFor(error, ScanInputKind.camera));
      return null;
    }
  }

  Future<ScanCapturePayload?> pickFromLibrary() async {
    if (_phase == ScanCapturePhase.recognizing) return null;
    _clearGuideFallbackCapture();
    final operation = ++_operationGeneration;
    final previousFailure = _failureKind;
    _lastAttempt = ScanInputKind.photoLibrary;
    _setPhase(ScanCapturePhase.recognizing);
    FrameBundle? bundle;
    CapturedFrame? originalFrame;
    try {
      final frame = await _platform.pickFromLibrary();
      if (!_isCurrent(operation)) return null;
      if (frame == null) {
        if (_platform.isReady) {
          _setPhase(ScanCapturePhase.ready);
        } else {
          _setFailure(
            previousFailure ?? ScanCaptureFailureKind.cameraUnavailable,
          );
        }
        return null;
      }
      originalFrame = frame;
      bundle = FrameBundle(
        source: FrameSource.photoLibrary,
        frames: <CapturedFrame>[frame],
      );
      final draft = await _vision.recognize(bundle);
      if (!_isCurrent(operation)) return null;
      _clearGuideFallbackCapture();
      _setPhase(
        _platform.isReady ? ScanCapturePhase.ready : ScanCapturePhase.failure,
      );
      return ScanCapturePayload(
        draft: draft,
        originalFrame: frame,
        inputKind: ScanInputKind.photoLibrary,
        usedBurst: false,
      );
    } on Object catch (error) {
      if (!_isCurrent(operation)) return null;
      _retainGuideFallbackIfEligible(
        error: error,
        bundle: bundle,
        originalFrame: originalFrame,
        inputKind: ScanInputKind.photoLibrary,
        usedBurst: false,
      );
      _setFailure(_recognitionFailureFor(error, ScanInputKind.photoLibrary));
      return null;
    }
  }

  /// Re-runs recognition against the exact captured frames using the visible
  /// board guide. No camera or photo-library access occurs during this retry.
  Future<ScanCapturePayload?> retryWithGuide() async {
    if (!canUseGuideFallback) return null;
    final retained = _retainedGuideCapture;
    if (retained == null) return null;

    final operation = ++_operationGeneration;
    _setPhase(ScanCapturePhase.recognizing);
    try {
      final draft = await _guideFallback.recognize(retained.bundle);
      if (!_isCurrent(operation)) return null;
      _clearGuideFallbackCapture();
      _setPhase(
        _platform.isReady ? ScanCapturePhase.ready : ScanCapturePhase.failure,
      );
      return ScanCapturePayload(
        draft: draft,
        originalFrame: retained.originalFrame,
        inputKind: retained.inputKind,
        usedBurst: retained.usedBurst,
      );
    } on Object catch (error) {
      if (!_isCurrent(operation)) return null;
      // Keep the bounded frame bundle so a recoverable guide recognizer error
      // can be retried without another capture.
      _setFailure(_recognitionFailureFor(error, retained.inputKind));
      return null;
    }
  }

  Future<ScanCapturePayload?> retryLastAttempt() => switch (_lastAttempt) {
    ScanInputKind.camera => captureCamera(),
    ScanInputKind.photoLibrary => pickFromLibrary(),
    null => Future<ScanCapturePayload?>.value(null),
  };

  Future<void> cycleFlash() async {
    if (_phase != ScanCapturePhase.ready) return;
    try {
      await _platform.cycleFlash();
      notifyListeners();
    } on Object catch (error) {
      _setFailure(_cameraFailureFor(error));
    }
  }

  void _setPhase(ScanCapturePhase value) {
    if (_disposed) return;
    _phase = value;
    if (value != ScanCapturePhase.failure) _failureKind = null;
    notifyListeners();
  }

  void _setFailure(ScanCaptureFailureKind kind) {
    if (_disposed) return;
    _phase = ScanCapturePhase.failure;
    _failureKind = kind;
    notifyListeners();
  }

  bool _isCurrent(int operation) =>
      !_disposed && operation == _operationGeneration;

  void _retainGuideFallbackIfEligible({
    required Object error,
    required FrameBundle? bundle,
    required CapturedFrame? originalFrame,
    required ScanInputKind inputKind,
    required bool usedBurst,
  }) {
    if (error is! BoardVisionException ||
        !_canRecoverWithGuide(error.code) ||
        bundle == null ||
        originalFrame == null) {
      _clearGuideFallbackCapture();
      return;
    }
    // Capture construction is intentionally bounded to one still or the
    // original three-frame burst. Never retain an unbounded platform result.
    if (bundle.frames.length > 3) {
      _clearGuideFallbackCapture();
      return;
    }
    _retainedGuideCapture = _GuideFallbackCapture(
      bundle: bundle,
      originalFrame: originalFrame,
      inputKind: inputKind,
      usedBurst: usedBurst,
    );
  }

  void _clearGuideFallbackCapture() {
    _retainedGuideCapture = null;
  }

  bool _canRecoverWithGuide(BoardVisionErrorCode code) => switch (code) {
    BoardVisionErrorCode.unsupportedGeometry ||
    BoardVisionErrorCode.boardNotFound ||
    BoardVisionErrorCode.ambiguousBoard ||
    BoardVisionErrorCode.inconsistentBoardSize ||
    BoardVisionErrorCode.insufficientDetectedFrames => true,
    BoardVisionErrorCode.undecodableFrame ||
    BoardVisionErrorCode.frameTooSmall ||
    BoardVisionErrorCode.resourceLimitExceeded ||
    BoardVisionErrorCode.invalidFrameMetadata => false,
  };

  ScanCaptureFailureKind _cameraFailureFor(Object error) => switch (error) {
    ScanPlatformException(:final kind) => switch (kind) {
      ScanPlatformFailureKind.permissionDenied =>
        ScanCaptureFailureKind.cameraPermissionDenied,
      ScanPlatformFailureKind.restricted =>
        ScanCaptureFailureKind.cameraRestricted,
      ScanPlatformFailureKind.unavailable =>
        ScanCaptureFailureKind.cameraUnavailable,
      ScanPlatformFailureKind.captureFailed =>
        ScanCaptureFailureKind.cameraCaptureFailed,
    },
    _ => ScanCaptureFailureKind.cameraUnavailable,
  };

  ScanCaptureFailureKind _recognitionFailureFor(
    Object error,
    ScanInputKind inputKind,
  ) => switch (error) {
    ScanPlatformException() when inputKind == ScanInputKind.camera =>
      _cameraFailureFor(error),
    ScanPlatformException(:final kind) => switch (kind) {
      ScanPlatformFailureKind.permissionDenied =>
        ScanCaptureFailureKind.photoLibraryPermissionDenied,
      ScanPlatformFailureKind.restricted ||
      ScanPlatformFailureKind.unavailable =>
        ScanCaptureFailureKind.photoLibraryUnavailable,
      ScanPlatformFailureKind.captureFailed =>
        ScanCaptureFailureKind.selectedImageUnreadable,
    },
    BoardVisionException() => ScanCaptureFailureKind.recognitionIncompleteBoard,
    _ => ScanCaptureFailureKind.recognitionFailed,
  };

  @override
  void dispose() {
    if (_disposed) return;
    _clearGuideFallbackCapture();
    _disposed = true;
    ++_operationGeneration;
    unawaited(_platform.dispose());
    super.dispose();
  }
}
