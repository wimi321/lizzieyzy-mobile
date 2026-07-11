import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

@immutable
class ScoreSample {
  const ScoreSample({required this.move, required this.scoreLead});

  final int move;
  final double scoreLead;
}

/// A score-lead chart with a single y-axis. Positive values are black's lead.
class ScoreChart extends StatelessWidget {
  const ScoreChart({
    required this.samples,
    super.key,
    this.currentMove,
    this.height = 156,
    this.semanticLabel = '目差走势',
  });

  final List<ScoreSample> samples;
  final int? currentMove;
  final double height;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final latest = samples.isEmpty ? null : samples.last.scoreLead;
    final direction = latest == null
        ? '暂无数据'
        : latest >= 0
        ? '黑方领先 ${latest.abs().toStringAsFixed(1)} 目'
        : '白方领先 ${latest.abs().toStringAsFixed(1)} 目';
    return Semantics(
      image: true,
      label:
          '$semanticLabel，$direction${currentMove == null ? '' : '，当前第 $currentMove 手'}',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: ScoreChartPainter(
              samples: samples,
              currentMove: currentMove,
              lineColor: Theme.of(context).colorScheme.primary,
              positiveFill: Theme.of(context).colorScheme.primaryContainer,
              negativeFill: Theme.of(context).colorScheme.errorContainer,
              axisColor: context.goColors.softDivider,
              markerColor: context.goColors.dataGold,
              labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class ScoreChartPainter extends CustomPainter {
  const ScoreChartPainter({
    required this.samples,
    required this.lineColor,
    required this.positiveFill,
    required this.negativeFill,
    required this.axisColor,
    required this.markerColor,
    required this.labelColor,
    this.currentMove,
  });

  final List<ScoreSample> samples;
  final int? currentMove;
  final Color lineColor;
  final Color positiveFill;
  final Color negativeFill;
  final Color axisColor;
  final Color markerColor;
  final Color labelColor;

  static const _leftPadding = 36.0;
  static const _rightPadding = 8.0;
  static const _verticalPadding = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTRB(
      _leftPadding,
      _verticalPadding,
      size.width - _rightPadding,
      size.height - _verticalPadding,
    );
    if (bounds.width <= 0 || bounds.height <= 0) return;

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    final zeroY = bounds.center.dy;
    canvas.drawLine(
      Offset(bounds.left, zeroY),
      Offset(bounds.right, zeroY),
      axisPaint,
    );
    canvas
      ..drawLine(
        Offset(bounds.left, bounds.top),
        Offset(bounds.left, bounds.bottom),
        axisPaint,
      )
      ..drawLine(
        Offset(bounds.left, bounds.top),
        Offset(bounds.right, bounds.top),
        axisPaint..color = axisColor.withValues(alpha: 0.45),
      )
      ..drawLine(
        Offset(bounds.left, bounds.bottom),
        Offset(bounds.right, bounds.bottom),
        axisPaint,
      );

    if (samples.isEmpty) return;
    final sorted = List<ScoreSample>.of(samples)
      ..sort((a, b) => a.move.compareTo(b.move));
    final maxMove = math.max(1, sorted.last.move);
    final maxAbs = math.max(
      5,
      sorted.fold<double>(
        0,
        (value, item) => math.max(value, item.scoreLead.abs()),
      ),
    );
    final displayMax = (maxAbs / 5).ceil() * 5.0;
    Offset point(ScoreSample sample) => Offset(
      bounds.left + bounds.width * sample.move / maxMove,
      zeroY - sample.scoreLead / displayMax * bounds.height * 0.45,
    );

    final linePath = Path()
      ..moveTo(point(sorted.first).dx, point(sorted.first).dy);
    for (final sample in sorted.skip(1)) {
      final offset = point(sample);
      linePath.lineTo(offset.dx, offset.dy);
    }
    final fillPath = Path.from(linePath)
      ..lineTo(point(sorted.last).dx, zeroY)
      ..lineTo(point(sorted.first).dx, zeroY)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            positiveFill.withValues(alpha: 0.72),
            negativeFill.withValues(alpha: 0.54),
          ],
          stops: const <double>[0.48, 0.52],
        ).createShader(bounds),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.25
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    final current = _nearestSample(sorted, currentMove ?? sorted.last.move);
    final currentPoint = point(current);
    canvas
      ..drawLine(
        Offset(currentPoint.dx, bounds.top),
        Offset(currentPoint.dx, bounds.bottom),
        Paint()
          ..color = markerColor.withValues(alpha: 0.55)
          ..strokeWidth = 1,
      )
      ..drawCircle(currentPoint, 5, Paint()..color = markerColor)
      ..drawCircle(
        currentPoint,
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

    _paintLabel(canvas, '+${displayMax.toStringAsFixed(0)}', bounds.topLeft);
    _paintLabel(canvas, '0', Offset(bounds.left, zeroY));
    _paintLabel(canvas, '-${displayMax.toStringAsFixed(0)}', bounds.bottomLeft);
  }

  ScoreSample _nearestSample(List<ScoreSample> sorted, int move) {
    return sorted.reduce(
      (a, b) => (a.move - move).abs() <= (b.move - move).abs() ? a : b,
    );
  }

  void _paintLabel(Canvas canvas, String text, Offset anchor) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: labelColor, fontSize: 10, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(anchor.dx - painter.width - 6, anchor.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant ScoreChartPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.currentMove != currentMove ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.positiveFill != positiveFill ||
        oldDelegate.negativeFill != negativeFill ||
        oldDelegate.axisColor != axisColor ||
        oldDelegate.markerColor != markerColor ||
        oldDelegate.labelColor != labelColor;
  }
}
