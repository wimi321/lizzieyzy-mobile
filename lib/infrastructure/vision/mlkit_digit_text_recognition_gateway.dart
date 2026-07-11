import 'dart:io';
import 'dart:math' as math;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:path_provider/path_provider.dart';

typedef OcrTemporaryDirectoryProvider = Future<Directory> Function();

/// Thin, replaceable on-device OCR adapter. Only numeric-looking regions are
/// returned; no image or result leaves the device.
final class MlKitDigitTextRecognitionGateway implements TextRecognitionGateway {
  MlKitDigitTextRecognitionGateway({
    OcrTemporaryDirectoryProvider? temporaryDirectoryProvider,
    this.maximumSide = 2400,
  }) : _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? getTemporaryDirectory;

  final OcrTemporaryDirectoryProvider _temporaryDirectoryProvider;
  final int maximumSide;

  @override
  Future<List<RecognizedTextRegion>> recognize(CapturedFrame frame) async {
    if (maximumSide < 640 || maximumSide > 4096) {
      throw ArgumentError.value(maximumSide, 'maximumSide');
    }
    final decoded = img.decodeImage(frame.encodedBytes);
    if (decoded == null) return const <RecognizedTextRegion>[];
    var oriented = img.bakeOrientation(decoded);
    oriented = switch (frame.rotation) {
      FrameRotation.degrees0 => oriented,
      FrameRotation.degrees90 => img.copyRotate(oriented, angle: 90),
      FrameRotation.degrees180 => img.copyRotate(oriented, angle: 180),
      FrameRotation.degrees270 => img.copyRotate(oriented, angle: 270),
    };
    if (math.max(oriented.width, oriented.height) > maximumSide) {
      final scale = maximumSide / math.max(oriented.width, oriented.height);
      oriented = img.copyResize(
        oriented,
        width: math.max(1, (oriented.width * scale).round()),
        height: math.max(1, (oriented.height * scale).round()),
        interpolation: img.Interpolation.linear,
      );
    }

    final root = await _temporaryDirectoryProvider();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}lizzieyzy-ocr',
    );
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      'frame-${DateTime.now().toUtc().microsecondsSinceEpoch}.jpg',
    );
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      await file.writeAsBytes(
        img.encodeJpg(oriented, quality: 96),
        flush: true,
      );
      final result = await recognizer.processImage(InputImage.fromFile(file));
      return <RecognizedTextRegion>[
        for (final block in result.blocks)
          for (final line in block.lines)
            for (final element in line.elements)
              if (_containsNumberLikeText(element.text))
                ..._regionsForElement(
                  element,
                  imageWidth: oriented.width,
                  imageHeight: oriented.height,
                ),
      ];
    } finally {
      try {
        await recognizer.close();
      } on Object {
        // OCR already completed or failed; native cleanup remains best effort.
      }
      try {
        if (await file.exists()) await file.delete();
      } on Object {
        // The app-private temporary directory is also cleaned by the OS.
      }
    }
  }
}

bool _containsNumberLikeText(String value) =>
    RegExp(r'[0-9OIlSB]').hasMatch(value);

List<RecognizedTextRegion> _regionsForElement(
  TextElement element, {
  required int imageWidth,
  required int imageHeight,
}) {
  final normalized = _normalizeNumberLikeText(element.text);
  final matches = RegExp(r'\d{1,3}').allMatches(normalized).toList();
  if (matches.isEmpty) return const <RecognizedTextRegion>[];
  final rect = element.boundingBox;
  final result = <RecognizedTextRegion>[];
  for (final match in matches.take(4)) {
    final leftFraction = match.start / math.max(1, normalized.length);
    final rightFraction = match.end / math.max(1, normalized.length);
    final left = rect.left + rect.width * leftFraction;
    final right = rect.left + rect.width * rightFraction;
    final clippedLeft = (left / imageWidth).clamp(0.0, 0.999999);
    final clippedRight = (right / imageWidth).clamp(
      clippedLeft + 0.000001,
      1.0,
    );
    final clippedTop = (rect.top / imageHeight).clamp(0.0, 0.999999);
    final clippedBottom = (rect.bottom / imageHeight).clamp(
      clippedTop + 0.000001,
      1.0,
    );
    result.add(
      RecognizedTextRegion(
        text: match.group(0)!,
        bounds: NormalizedTextRect(
          left: clippedLeft,
          top: clippedTop,
          right: clippedRight,
          bottom: clippedBottom,
        ),
        // iOS currently exposes no confidence through ML Kit. A neutral prior
        // remains below the app's auto-accept threshold and triggers review.
        confidence: (element.confidence ?? 0.82).clamp(0, 1),
      ),
    );
  }
  return result;
}

String _normalizeNumberLikeText(String value) => value
    .replaceAll('O', '0')
    .replaceAll('I', '1')
    .replaceAll('l', '1')
    .replaceAll('S', '5')
    .replaceAll('B', '8');
