import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../tokens.dart';

enum CandidateTone { primary, secondary, tertiary }

/// A compact, text-labelled candidate indicator.
///
/// The visible mark can be smaller than a touch target; the widget always
/// reserves at least 48dp when interactive.
class CandidateMarker extends StatelessWidget {
  const CandidateMarker({
    required this.label,
    super.key,
    this.detail,
    this.tone = CandidateTone.primary,
    this.selected = false,
    this.onTap,
    this.diameter = 32,
    this.semanticLabel,
  });

  final String label;
  final String? detail;
  final CandidateTone tone;
  final bool selected;
  final VoidCallback? onTap;
  final double diameter;
  final String? semanticLabel;

  Color _color(GoSemanticColors colors) => switch (tone) {
    CandidateTone.primary => colors.candidatePrimary,
    CandidateTone.secondary => colors.candidateSecondary,
    CandidateTone.tertiary => colors.candidateTertiary,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color(context.goColors);
    final visual = AnimatedContainer(
      duration: GoMotion.resolve(context, GoMotion.fast),
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? theme.colorScheme.onSurface
              : theme.colorScheme.surface,
          width: selected ? 2.5 : 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: context.goColors.shadow,
            blurRadius: selected ? 5 : 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: theme.textTheme.labelMedium?.copyWith(
          color: _foregroundFor(color),
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );

    final content = detail == null
        ? visual
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              visual,
              const SizedBox(width: GoSpacing.s2),
              Flexible(
                child: Text(
                  detail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          );

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      selected: selected,
      label:
          semanticLabel ??
          (detail == null
              ? context.l10n.candidateSemantics(label)
              : context.l10n.candidateSemanticsWithDetail(label, detail!)),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: onTap == null ? diameter : GoSizes.minimumTouchTarget,
          minHeight: onTap == null ? diameter : GoSizes.minimumTouchTarget,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }

  Color _foregroundFor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : GoPrimitiveColors.ink;
  }
}
