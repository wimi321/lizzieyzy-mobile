import 'package:lizzieyzy_mobile/domain/domain.dart';

enum VisionResourceViolation {
  invalidConfiguration,
  tooManyFrames,
  encodedFrameTooLarge,
  encodedBundleTooLarge,
  declaredDimensionTooLarge,
  declaredPixelCountTooLarge,
  declaredBundlePixelCountTooLarge,
  decodedDimensionTooLarge,
  decodedPixelCountTooLarge,
  frameMetadataMismatch,
}

final class VisionResourceException implements Exception {
  const VisionResourceException(this.violation, this.message);

  final VisionResourceViolation violation;
  final String message;

  @override
  String toString() => 'VisionResourceException(${violation.name}): $message';
}

/// Hard limits applied before and immediately after image decoding.
///
/// These are safety budgets, not recognition-quality claims. The decoder is
/// still allowed to process high-resolution phone photos, while malformed
/// metadata and decompression bombs are rejected before expensive sampling.
final class VisionResourceLimits {
  const VisionResourceLimits({
    this.maxFrames = 7,
    this.maxEncodedBytesPerFrame = 32 * 1024 * 1024,
    this.maxEncodedBytesPerBundle = 64 * 1024 * 1024,
    this.maxDimension = 8192,
    this.maxPixelsPerFrame = 24 * 1000 * 1000,
    this.maxPixelsPerBundle = 72 * 1000 * 1000,
    this.requireMetadataMatch = true,
  });

  final int maxFrames;
  final int maxEncodedBytesPerFrame;
  final int maxEncodedBytesPerBundle;
  final int maxDimension;
  final int maxPixelsPerFrame;
  final int maxPixelsPerBundle;
  final bool requireMetadataMatch;

  void validateConfiguration() {
    final positiveValues = <String, int>{
      'maxFrames': maxFrames,
      'maxEncodedBytesPerFrame': maxEncodedBytesPerFrame,
      'maxEncodedBytesPerBundle': maxEncodedBytesPerBundle,
      'maxDimension': maxDimension,
      'maxPixelsPerFrame': maxPixelsPerFrame,
      'maxPixelsPerBundle': maxPixelsPerBundle,
    };
    for (final entry in positiveValues.entries) {
      if (entry.value <= 0) {
        throw VisionResourceException(
          VisionResourceViolation.invalidConfiguration,
          '${entry.key} must be positive.',
        );
      }
    }
    if (maxEncodedBytesPerBundle < maxEncodedBytesPerFrame) {
      throw const VisionResourceException(
        VisionResourceViolation.invalidConfiguration,
        'The bundle byte limit cannot be smaller than the per-frame limit.',
      );
    }
    if (maxPixelsPerBundle < maxPixelsPerFrame) {
      throw const VisionResourceException(
        VisionResourceViolation.invalidConfiguration,
        'The bundle pixel limit cannot be smaller than the per-frame limit.',
      );
    }
  }

  void validateBundle(FrameBundle bundle) {
    validateConfiguration();
    if (bundle.frames.length > maxFrames) {
      throw VisionResourceException(
        VisionResourceViolation.tooManyFrames,
        'The frame bundle exceeds the $maxFrames-frame processing budget.',
      );
    }

    var totalBytes = 0;
    var totalPixels = 0;
    for (final frame in bundle.frames) {
      final encodedBytes = frame.encodedBytes.length;
      if (encodedBytes > maxEncodedBytesPerFrame) {
        throw VisionResourceException(
          VisionResourceViolation.encodedFrameTooLarge,
          'An encoded frame exceeds the $maxEncodedBytesPerFrame-byte limit.',
        );
      }
      totalBytes += encodedBytes;
      if (totalBytes > maxEncodedBytesPerBundle) {
        throw VisionResourceException(
          VisionResourceViolation.encodedBundleTooLarge,
          'The frame bundle exceeds the $maxEncodedBytesPerBundle-byte limit.',
        );
      }

      if (frame.pixelWidth > maxDimension || frame.pixelHeight > maxDimension) {
        throw VisionResourceException(
          VisionResourceViolation.declaredDimensionTooLarge,
          'Declared frame dimensions exceed the $maxDimension-pixel edge limit.',
        );
      }
      final pixels = frame.pixelWidth * frame.pixelHeight;
      if (pixels > maxPixelsPerFrame) {
        throw VisionResourceException(
          VisionResourceViolation.declaredPixelCountTooLarge,
          'A declared frame exceeds the $maxPixelsPerFrame-pixel limit.',
        );
      }
      totalPixels += pixels;
      if (totalPixels > maxPixelsPerBundle) {
        throw VisionResourceException(
          VisionResourceViolation.declaredBundlePixelCountTooLarge,
          'The frame bundle exceeds the $maxPixelsPerBundle-pixel limit.',
        );
      }
    }
  }

  void validateDecodedFrame(
    CapturedFrame frame, {
    required int decodedWidth,
    required int decodedHeight,
  }) {
    validateConfiguration();
    if (decodedWidth <= 0 || decodedHeight <= 0) {
      throw const VisionResourceException(
        VisionResourceViolation.decodedPixelCountTooLarge,
        'Decoded frame dimensions must be positive.',
      );
    }
    if (decodedWidth > maxDimension || decodedHeight > maxDimension) {
      throw VisionResourceException(
        VisionResourceViolation.decodedDimensionTooLarge,
        'Decoded frame dimensions exceed the $maxDimension-pixel edge limit.',
      );
    }
    if (decodedWidth * decodedHeight > maxPixelsPerFrame) {
      throw VisionResourceException(
        VisionResourceViolation.decodedPixelCountTooLarge,
        'A decoded frame exceeds the $maxPixelsPerFrame-pixel limit.',
      );
    }
    if (requireMetadataMatch &&
        (decodedWidth != frame.pixelWidth ||
            decodedHeight != frame.pixelHeight)) {
      throw VisionResourceException(
        VisionResourceViolation.frameMetadataMismatch,
        'Declared ${frame.pixelWidth}x${frame.pixelHeight} dimensions do not '
        'match decoded ${decodedWidth}x$decodedHeight dimensions.',
      );
    }
  }
}
