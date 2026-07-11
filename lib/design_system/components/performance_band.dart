import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../tokens.dart';
import 'metric_pill.dart';

class PerformanceBand extends StatelessWidget {
  const PerformanceBand({
    required this.lowerRank,
    required this.upperRank,
    required this.confidenceLabel,
    required this.effectiveDecisions,
    super.key,
    this.bandStart = 0.28,
    this.bandEnd = 0.68,
    this.title,
  }) : assert(effectiveDecisions >= 0),
       assert(bandStart >= 0 && bandStart <= 1),
       assert(bandEnd >= 0 && bandEnd <= 1),
       assert(bandStart <= bandEnd);

  final String lowerRank;
  final String upperRank;
  final String confidenceLabel;
  final int effectiveDecisions;
  final double bandStart;
  final double bandEnd;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final resolvedTitle = title ?? l10n.gamePerformanceEstimate;
    final decisions = l10n.effectiveDecisionCount(effectiveDecisions);
    return Semantics(
      container: true,
      label: l10n.performanceBandSemantics(
        resolvedTitle,
        lowerRank,
        upperRank,
        confidenceLabel,
        decisions,
      ),
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(GoSpacing.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(resolvedTitle, style: theme.textTheme.labelLarge),
              const SizedBox(height: GoSpacing.s2),
              Text(
                '$lowerRank–$upperRank',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: GoSpacing.s4),
              SizedBox(
                height: 28,
                width: double.infinity,
                child: CustomPaint(
                  painter: _PerformanceBandPainter(
                    start: bandStart,
                    end: bandEnd,
                    trackColor: theme.colorScheme.surfaceContainerHighest,
                    bandColor: theme.colorScheme.primary,
                    markerColor: context.goColors.dataGold,
                  ),
                ),
              ),
              const SizedBox(height: GoSpacing.s3),
              Wrap(
                spacing: GoSpacing.s2,
                runSpacing: GoSpacing.s2,
                children: <Widget>[
                  MetricPill(
                    label: l10n.coverageInterval(80),
                    tone: MetricTone.primary,
                    icon: Icons.horizontal_rule_rounded,
                    compact: true,
                  ),
                  MetricPill(
                    label: confidenceLabel,
                    tone: MetricTone.gold,
                    icon: Icons.verified_outlined,
                    compact: true,
                  ),
                  MetricPill(
                    label: decisions,
                    icon: Icons.data_usage_rounded,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerformanceBandPainter extends CustomPainter {
  const _PerformanceBandPainter({
    required this.start,
    required this.end,
    required this.trackColor,
    required this.bandColor,
    required this.markerColor,
  });

  final double start;
  final double end;
  final Color trackColor;
  final Color bandColor;
  final Color markerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height / 2 - 4, size.width, 8),
      const Radius.circular(GoRadii.pill),
    );
    canvas.drawRRect(track, Paint()..color = trackColor);
    final bandRect = Rect.fromLTRB(
      size.width * start,
      size.height / 2 - 7,
      size.width * end,
      size.height / 2 + 7,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bandRect, const Radius.circular(GoRadii.pill)),
      Paint()..color = bandColor,
    );
    final midpoint = size.width * (start + end) / 2;
    canvas
      ..drawCircle(
        Offset(midpoint, size.height / 2),
        6,
        Paint()..color = markerColor,
      )
      ..drawCircle(
        Offset(midpoint, size.height / 2),
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
  }

  @override
  bool shouldRepaint(covariant _PerformanceBandPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.bandColor != bandColor ||
        oldDelegate.markerColor != markerColor;
  }
}
