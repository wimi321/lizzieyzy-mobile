import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:image_picker/image_picker.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

enum ScanPlatformFailureKind {
  permissionDenied,
  restricted,
  unavailable,
  captureFailed,
}

final class ScanPlatformException implements Exception {
  const ScanPlatformException(this.kind, this.message, [this.cause]);

  final ScanPlatformFailureKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => 'ScanPlatformException(${kind.name}): $message';
}

enum ScanFlashMode { automatic, off, on }

/// The small platform boundary used by the scan flow.
///
/// Keeping camera and photo-library plugins behind this interface lets widget
/// tests prove lazy permission access without invoking a method channel.
abstract interface class ScanCapturePlatform {
  bool get isReady;
  ScanFlashMode get flashMode;

  /// Returns null until a real camera controller has initialized.
  Widget? buildPreview();

  Future<void> initialize();
  Future<void> suspend();
  Future<void> resume();
  Future<List<CapturedFrame>> takeBurst({int preferredCount = 3});
  Future<CapturedFrame?> pickFromLibrary();
  Future<void> cycleFlash();
  Future<void> dispose();
}

/// Camera/image-picker implementation used on iOS and Android.
final class PluginScanCapturePlatform implements ScanCapturePlatform {
  PluginScanCapturePlatform({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;
  CameraController? _controller;
  ScanFlashMode _flashMode = ScanFlashMode.automatic;
  int _lifecycleGeneration = 0;
  bool _disposed = false;

  @override
  bool get isReady => _controller?.value.isInitialized ?? false;

  @override
  ScanFlashMode get flashMode => _flashMode;

  @override
  Widget? buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final sensorAspect = controller.value.aspectRatio;
        final previewAspect =
            MediaQuery.orientationOf(context) == Orientation.portrait
            ? 1 / sensorAspect
            : sensorAspect;
        final boundsAspect = constraints.maxWidth / constraints.maxHeight;
        final width = previewAspect > boundsAspect
            ? constraints.maxHeight * previewAspect
            : constraints.maxWidth;
        final height = previewAspect > boundsAspect
            ? constraints.maxHeight
            : constraints.maxWidth / previewAspect;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: CameraPreview(controller),
          ),
        );
      },
    );
  }

  @override
  Future<void> initialize() async {
    if (_disposed || isReady) return;
    final generation = ++_lifecycleGeneration;
    CameraController? initializingController;
    try {
      final cameras = await availableCameras();
      if (!_isCurrent(generation)) return;
      if (cameras.isEmpty) {
        throw const ScanPlatformException(
          ScanPlatformFailureKind.unavailable,
          '未检测到可用的后置相机。',
        );
      }
      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selected,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      initializingController = controller;
      _controller = controller;
      await controller.initialize();
      if (!_isCurrent(generation)) {
        await _releaseSpecific(controller);
        return;
      }
      await _applyFlashMode(_flashMode, tolerateUnsupported: true);
      if (!_isCurrent(generation)) await _releaseSpecific(controller);
    } on ScanPlatformException {
      await _releaseSpecific(initializingController);
      rethrow;
    } on CameraException catch (error) {
      await _releaseSpecific(initializingController);
      throw _mapCameraException(error);
    } on MissingPluginException catch (error) {
      await _releaseSpecific(initializingController);
      throw ScanPlatformException(
        ScanPlatformFailureKind.unavailable,
        '当前运行环境未提供相机。',
        error,
      );
    } on PlatformException catch (error) {
      await _releaseSpecific(initializingController);
      throw ScanPlatformException(
        ScanPlatformFailureKind.unavailable,
        '相机暂时不可用，请改用相册。',
        error,
      );
    } on Object catch (error) {
      await _releaseSpecific(initializingController);
      throw ScanPlatformException(
        ScanPlatformFailureKind.unavailable,
        '无法启动相机，请稍后重试或从相册选择。',
        error,
      );
    }
  }

  @override
  Future<void> suspend() async {
    ++_lifecycleGeneration;
    await _releaseController();
  }

  @override
  Future<void> resume() => initialize();

  @override
  Future<List<CapturedFrame>> takeBurst({int preferredCount = 3}) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw const ScanPlatformException(
        ScanPlatformFailureKind.unavailable,
        '相机尚未就绪。',
      );
    }

    final target = preferredCount.clamp(1, 3);
    final frames = <CapturedFrame>[];
    for (var index = 0; index < target; index++) {
      try {
        final file = await controller.takePicture();
        try {
          frames.add(await _frameFromFile(file));
        } finally {
          await _deleteTemporaryCapture(file.path);
        }
        if (index + 1 < target) {
          await Future<void>.delayed(const Duration(milliseconds: 90));
        }
      } on CameraException catch (error) {
        if (frames.isEmpty) throw _mapCameraException(error);
        // A few camera backends cannot queue repeated still captures. One
        // complete frame is an explicit, valid fallback; never emit a partial
        // two-frame bundle because the domain contract rejects it.
        return <CapturedFrame>[frames.first];
      } on Object catch (error) {
        if (frames.isEmpty) {
          throw ScanPlatformException(
            ScanPlatformFailureKind.captureFailed,
            '拍摄失败，请保持设备稳定后重试。',
            error,
          );
        }
        return <CapturedFrame>[frames.first];
      }
    }
    return frames.length >= 3 ? frames : <CapturedFrame>[frames.first];
  }

  @override
  Future<CapturedFrame?> pickFromLibrary() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
        // A non-100 value forces HEIC/other platform formats through the
        // picker codec into a decoder-compatible JPEG with imperceptible loss.
        imageQuality: 99,
        requestFullMetadata: false,
      );
      if (file == null) return null;
      return _frameFromFile(file);
    } on PlatformException catch (error) {
      final denied = error.code.toLowerCase().contains('denied');
      throw ScanPlatformException(
        denied
            ? ScanPlatformFailureKind.permissionDenied
            : ScanPlatformFailureKind.unavailable,
        denied ? '无法访问相册，请在系统设置中允许照片访问。' : '无法打开相册，请稍后重试。',
        error,
      );
    } on Object catch (error) {
      throw ScanPlatformException(
        ScanPlatformFailureKind.captureFailed,
        '无法读取所选图片，请换一张完整清晰的棋盘照片。',
        error,
      );
    }
  }

  @override
  Future<void> cycleFlash() async {
    final next = switch (_flashMode) {
      ScanFlashMode.automatic => ScanFlashMode.off,
      ScanFlashMode.off => ScanFlashMode.on,
      ScanFlashMode.on => ScanFlashMode.automatic,
    };
    await _applyFlashMode(next);
    _flashMode = next;
  }

  Future<void> _applyFlashMode(
    ScanFlashMode mode, {
    bool tolerateUnsupported = false,
  }) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.setFlashMode(switch (mode) {
        ScanFlashMode.automatic => FlashMode.auto,
        ScanFlashMode.off => FlashMode.off,
        ScanFlashMode.on => FlashMode.always,
      });
    } on CameraException catch (error) {
      if (tolerateUnsupported) {
        _flashMode = ScanFlashMode.off;
        try {
          await controller.setFlashMode(FlashMode.off);
        } on Object {
          // A camera without a flash is still fully usable for recognition.
        }
        return;
      }
      throw _mapCameraException(error);
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await suspend();
  }

  Future<void> _releaseController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) await controller.dispose();
  }

  Future<void> _releaseSpecific(CameraController? controller) async {
    if (controller == null) return;
    if (identical(_controller, controller)) _controller = null;
    await controller.dispose();
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _lifecycleGeneration;
}

Future<CapturedFrame> _frameFromFile(XFile file) async {
  final bytes = await file.readAsBytes();
  return _frameFromBytes(bytes);
}

CapturedFrame _frameFromBytes(Uint8List bytes) {
  final decoder = image_lib.findDecoderForData(bytes);
  final imageInfo = decoder?.startDecode(bytes);
  if (imageInfo == null) {
    throw const ScanPlatformException(
      ScanPlatformFailureKind.captureFailed,
      '图片格式不受支持。',
    );
  }
  return CapturedFrame(
    encodedBytes: bytes,
    pixelWidth: imageInfo.width,
    pixelHeight: imageInfo.height,
    capturedAt: DateTime.now().toUtc(),
  );
}

Future<void> _deleteTemporaryCapture(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } on Object {
    // Temporary-file cleanup must not turn a successful capture into failure.
  }
}

ScanPlatformException _mapCameraException(CameraException error) {
  return switch (error.code) {
    'CameraAccessDenied' ||
    'CameraAccessDeniedWithoutPrompt' => ScanPlatformException(
      ScanPlatformFailureKind.permissionDenied,
      '未获得相机权限，请在系统设置中允许访问，或改用相册。',
      error,
    ),
    'CameraAccessRestricted' => ScanPlatformException(
      ScanPlatformFailureKind.restricted,
      '此设备限制了相机访问，请改用相册。',
      error,
    ),
    _ => ScanPlatformException(
      ScanPlatformFailureKind.captureFailed,
      '相机操作失败，请重试或改用相册。',
      error,
    ),
  };
}
