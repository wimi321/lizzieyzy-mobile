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

/// Owns the asynchronous scan state while keeping widgets declarative.
final class ScanCaptureController extends ChangeNotifier {
  ScanCaptureController({
    required ScanCapturePlatform platform,
    BoardVision vision = const GuideAlignedBoardVision(),
  }) : _platform = platform,
       _vision = vision;

  final ScanCapturePlatform _platform;
  final BoardVision _vision;
  ScanCapturePhase _phase = ScanCapturePhase.idle;
  String? _errorMessage;
  ScanInputKind? _lastAttempt;
  int _operationGeneration = 0;
  bool _disposed = false;

  ScanCapturePhase get phase => _phase;
  String? get errorMessage => _errorMessage;
  bool get hasRetryableCapture => _lastAttempt != null;
  ScanFlashMode get flashMode => _platform.flashMode;
  Widget? buildPreview() => _platform.buildPreview();

  Future<void> initialize() async {
    if (_disposed ||
        _phase == ScanCapturePhase.initializing ||
        _platform.isReady) {
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
      _setFailure(_messageFor(error));
    }
  }

  Future<void> suspend() async {
    if (_disposed) return;
    ++_operationGeneration;
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
      _setFailure(_messageFor(error));
    }
  }

  Future<ScanCapturePayload?> captureCamera() async {
    if (_phase == ScanCapturePhase.recognizing) return null;
    final operation = ++_operationGeneration;
    _lastAttempt = ScanInputKind.camera;
    _setPhase(ScanCapturePhase.recognizing);
    try {
      final frames = await _platform.takeBurst(preferredCount: 3);
      final usedBurst = frames.length >= 3;
      final bundle = FrameBundle(
        source: usedBurst ? FrameSource.cameraBurst : FrameSource.file,
        frames: usedBurst
            ? frames.take(3).toList(growable: false)
            : <CapturedFrame>[frames.first],
      );
      final draft = await _vision.recognize(bundle);
      if (!_isCurrent(operation)) return null;
      _setPhase(ScanCapturePhase.ready);
      return ScanCapturePayload(
        draft: draft,
        originalFrame: frames.first,
        inputKind: ScanInputKind.camera,
        usedBurst: usedBurst,
      );
    } on Object catch (error) {
      if (!_isCurrent(operation)) return null;
      _setFailure(_recognitionMessageFor(error));
      return null;
    }
  }

  Future<ScanCapturePayload?> pickFromLibrary() async {
    if (_phase == ScanCapturePhase.recognizing) return null;
    final operation = ++_operationGeneration;
    _lastAttempt = ScanInputKind.photoLibrary;
    _setPhase(ScanCapturePhase.recognizing);
    try {
      final frame = await _platform.pickFromLibrary();
      if (!_isCurrent(operation)) return null;
      if (frame == null) {
        _setPhase(
          _platform.isReady ? ScanCapturePhase.ready : ScanCapturePhase.failure,
        );
        return null;
      }
      final draft = await _vision.recognize(
        FrameBundle(
          source: FrameSource.photoLibrary,
          frames: <CapturedFrame>[frame],
        ),
      );
      if (!_isCurrent(operation)) return null;
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
      _setFailure(_recognitionMessageFor(error));
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
      _setFailure(_messageFor(error));
    }
  }

  void _setPhase(ScanCapturePhase value) {
    if (_disposed) return;
    _phase = value;
    if (value != ScanCapturePhase.failure) _errorMessage = null;
    notifyListeners();
  }

  void _setFailure(String message) {
    if (_disposed) return;
    _phase = ScanCapturePhase.failure;
    _errorMessage = message;
    notifyListeners();
  }

  bool _isCurrent(int operation) =>
      !_disposed && operation == _operationGeneration;

  String _messageFor(Object error) => switch (error) {
    ScanPlatformException(:final message) => message,
    _ => '相机暂时不可用，请重试或改用相册。',
  };

  String _recognitionMessageFor(Object error) => switch (error) {
    ScanPlatformException(:final message) => message,
    BoardVisionException() => '未能识别完整棋盘，请确保四角入框、光线均匀后重试。',
    _ => '识别失败，请保持棋盘完整清晰后重试。',
  };

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ++_operationGeneration;
    unawaited(_platform.dispose());
    super.dispose();
  }
}
