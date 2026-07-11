import 'package:flutter/material.dart';

import '../tokens.dart';

enum MetricTone { neutral, primary, gold, positive, negative }

class MetricPill extends StatelessWidget {
  const MetricPill({
    required this.label,
    super.key,
    this.value,
    this.tone = MetricTone.neutral,
    this.icon,
    this.compact = false,
  });

  final String label;
  final String? value;
  final MetricTone tone;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _resolvedColors(context);
    final text = value == null ? label : '$label  $value';
    return Semantics(
      label: value == null ? label : '$label，$value',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? GoSpacing.s2 : GoSpacing.s3,
          vertical: compact ? GoSpacing.s1 : GoSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(GoRadii.pill),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 15, color: colors.foreground),
              const SizedBox(width: GoSpacing.s1),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _MetricColors _resolvedColors(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.goColors;
    return switch (tone) {
      MetricTone.neutral => _MetricColors(
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
        border: semantic.softDivider,
      ),
      MetricTone.primary => _MetricColors(
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
        border: scheme.primary.withValues(alpha: 0.34),
      ),
      MetricTone.gold => _MetricColors(
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
        border: semantic.dataGold.withValues(alpha: 0.45),
      ),
      MetricTone.positive => _MetricColors(
        background: semantic.positive.withValues(alpha: 0.12),
        foreground: semantic.positive,
        border: semantic.positive.withValues(alpha: 0.4),
      ),
      MetricTone.negative => _MetricColors(
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
        border: scheme.error.withValues(alpha: 0.4),
      ),
    };
  }
}

class _MetricColors {
  const _MetricColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
