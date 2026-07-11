import 'package:lizzieyzy_mobile/domain/domain.dart';

final class NormalizedTextRect {
  const NormalizedTextRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;

  void validate() {
    final values = <double>[left, top, right, bottom];
    if (values.any((value) => !value.isFinite || value < 0 || value > 1) ||
        left >= right ||
        top >= bottom) {
      throw ArgumentError('Text bounds must be a non-empty normalized rect.');
    }
  }
}

final class RecognizedTextRegion {
  RecognizedTextRegion({
    required this.text,
    required this.bounds,
    required this.confidence,
  }) {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'Recognized text is empty.');
    }
    bounds.validate();
    if (!confidence.isFinite || confidence < 0 || confidence > 1) {
      throw RangeError.range(confidence, 0, 1, 'confidence');
    }
  }

  final String text;
  final NormalizedTextRect bounds;
  final double confidence;
}

abstract interface class TextRecognitionGateway {
  Future<List<RecognizedTextRegion>> recognize(CapturedFrame frame);
}
