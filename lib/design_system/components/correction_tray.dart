import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../tokens.dart';
import 'metric_pill.dart';

enum CorrectionChoice { black, white, empty, unknown }

class CorrectionTray extends StatelessWidget {
  const CorrectionTray({
    required this.pendingCount,
    required this.onSelected,
    super.key,
    this.selected,
    this.title,
    this.coordinate,
  }) : assert(pendingCount >= 0);

  final int pendingCount;
  final CorrectionChoice? selected;
  final ValueChanged<CorrectionChoice>? onSelected;
  final String? title;
  final String? coordinate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(GoRadii.sheet),
        ),
        side: BorderSide(color: context.goColors.softDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            GoSpacing.s4,
            GoSpacing.s4,
            GoSpacing.s4,
            GoSpacing.s5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title ?? l10n.correctBoardTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (coordinate != null) ...<Widget>[
                          const SizedBox(height: GoSpacing.s1),
                          Text(
                            l10n.intersectionCoordinate(coordinate!),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  MetricPill(
                    label: pendingCount == 0
                        ? l10n.confirmed
                        : l10n.pendingConfirmation(pendingCount),
                    tone: pendingCount == 0
                        ? MetricTone.positive
                        : MetricTone.gold,
                    icon: pendingCount == 0
                        ? Icons.check_circle_outline_rounded
                        : Icons.visibility_outlined,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: GoSpacing.s4),
              Wrap(
                spacing: GoSpacing.s2,
                runSpacing: GoSpacing.s2,
                children: <Widget>[
                  for (final choice in CorrectionChoice.values)
                    _CorrectionButton(
                      choice: choice,
                      selected: selected == choice,
                      onPressed: onSelected == null
                          ? null
                          : () => onSelected!.call(choice),
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

class _CorrectionButton extends StatelessWidget {
  const _CorrectionButton({
    required this.choice,
    required this.selected,
    required this.onPressed,
  });

  final CorrectionChoice choice;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final label = _choiceLabel(l10n, choice);
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(76, GoSizes.comfortableTouchTarget),
        backgroundColor: selected ? scheme.primaryContainer : scheme.surface,
        foregroundColor: selected
            ? scheme.onPrimaryContainer
            : scheme.onSurface,
        side: BorderSide(
          color: selected ? scheme.primary : context.goColors.softDivider,
          width: selected ? 2 : 1,
        ),
      ),
      icon: _CorrectionIcon(choice: choice),
      label: Text(label),
    );
    return Semantics(
      button: true,
      enabled: onPressed != null,
      selected: selected,
      label: l10n.stoneChoiceSemantics(label),
      excludeSemantics: true,
      child: button,
    );
  }
}

String _choiceLabel(AppLocalizations l10n, CorrectionChoice choice) =>
    switch (choice) {
      CorrectionChoice.black => l10n.blackStoneShort,
      CorrectionChoice.white => l10n.whiteStoneShort,
      CorrectionChoice.empty => l10n.emptyPoint,
      CorrectionChoice.unknown => l10n.unclearPoint,
    };

class _CorrectionIcon extends StatelessWidget {
  const _CorrectionIcon({required this.choice});

  final CorrectionChoice choice;

  @override
  Widget build(BuildContext context) {
    final colors = context.goColors;
    return switch (choice) {
      CorrectionChoice.black => Icon(
        Icons.circle,
        size: 18,
        color: colors.blackStone,
      ),
      CorrectionChoice.white => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.whiteStone,
          border: Border.all(color: colors.whiteStoneOutline),
        ),
        child: const SizedBox.square(dimension: 18),
      ),
      CorrectionChoice.empty => const Icon(Icons.grid_4x4_rounded, size: 18),
      CorrectionChoice.unknown => const Icon(
        Icons.help_outline_rounded,
        size: 18,
      ),
    };
  }
}
