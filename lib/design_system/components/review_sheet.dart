import 'package:flutter/material.dart';

import '../tokens.dart';

enum ReviewSection { keyMoves, variations, trend, game }

extension ReviewSectionLabel on ReviewSection {
  String get label => switch (this) {
    ReviewSection.keyMoves => '关键手',
    ReviewSection.variations => '变化',
    ReviewSection.trend => '走势',
    ReviewSection.game => '本局',
  };
}

/// Rounded review drawer with a horizontally scrollable, large-target tab row.
class ReviewSheet extends StatelessWidget {
  const ReviewSheet({
    required this.selectedSection,
    required this.onSectionChanged,
    required this.child,
    super.key,
    this.showHandle = true,
    this.contentPadding = const EdgeInsets.fromLTRB(
      GoSpacing.s4,
      GoSpacing.s2,
      GoSpacing.s4,
      GoSpacing.s5,
    ),
  });

  final ReviewSection selectedSection;
  final ValueChanged<ReviewSection>? onSectionChanged;
  final Widget child;
  final bool showHandle;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(GoRadii.sheet),
        ),
        side: BorderSide(color: context.goColors.softDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (showHandle)
              Center(
                child: Semantics(
                  label: '复盘面板',
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(
                      top: GoSpacing.s2,
                      bottom: GoSpacing.s1,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(GoRadii.pill),
                    ),
                  ),
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: GoSpacing.s3),
              child: Row(
                children: <Widget>[
                  for (final section in ReviewSection.values)
                    _ReviewTab(
                      label: section.label,
                      selected: selectedSection == section,
                      onTap: onSectionChanged == null
                          ? null
                          : () => onSectionChanged!.call(section),
                    ),
                ],
              ),
            ),
            Divider(
              height: GoSizes.hairline,
              color: context.goColors.softDivider,
            ),
            Padding(padding: contentPadding, child: child),
          ],
        ),
      ),
    );
  }
}

class _ReviewTab extends StatelessWidget {
  const _ReviewTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label标签页',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GoRadii.small),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 72,
            minHeight: GoSizes.minimumTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: GoSpacing.s3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
