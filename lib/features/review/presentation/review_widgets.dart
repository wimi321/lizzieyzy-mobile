import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../common/presentation/feature_chrome.dart';
import 'review_screen_data.dart';

class ReviewInspector extends StatelessWidget {
  const ReviewInspector({
    required this.data,
    required this.currentMove,
    required this.section,
    required this.onSectionChanged,
    required this.onOpenVariation,
    required this.onOpenPerformance,
    super.key,
    this.compact = false,
  });

  final ReviewScreenData data;
  final int currentMove;
  final ReviewSection section;
  final ValueChanged<ReviewSection> onSectionChanged;
  final VoidCallback onOpenVariation;
  final VoidCallback onOpenPerformance;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(GoRadii.sheet),
        border: Border.all(color: context.goColors.softDivider),
      ),
      child: Column(
        children: <Widget>[
          ReviewSectionTabs(selected: section, onSelected: onSectionChanged),
          Divider(height: 1, color: context.goColors.softDivider),
          Expanded(
            child: Padding(
              padding: largeText
                  ? const EdgeInsets.symmetric(horizontal: GoSpacing.s1)
                  : const EdgeInsets.all(GoSpacing.s2),
              child: AnimatedSwitcher(
                duration: GoMotion.resolve(context, GoMotion.fast),
                child: switch (section) {
                  ReviewSection.keyMoves => KeyMoveNumericCard(
                    key: const ValueKey(ReviewSection.keyMoves),
                    data: data,
                    moveNumber: currentMove,
                    compact: compact,
                    onTap: onOpenVariation,
                  ),
                  ReviewSection.variations => CandidateNumericCard(
                    key: const ValueKey(ReviewSection.variations),
                    data: data,
                    moveNumber: currentMove,
                    compact: compact,
                    onTap: onOpenVariation,
                  ),
                  ReviewSection.trend => TrendNumericCard(
                    key: const ValueKey(ReviewSection.trend),
                    data: data,
                    currentMove: currentMove,
                    compact: compact,
                  ),
                  ReviewSection.game => GameNumericCard(
                    key: const ValueKey(ReviewSection.game),
                    data: data,
                    compact: compact,
                    onTap: onOpenPerformance,
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewSectionTabs extends StatelessWidget {
  const ReviewSectionTabs({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ReviewSection selected;
  final ValueChanged<ReviewSection> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      for (final section in ReviewSection.values)
        Expanded(
          child: Semantics(
            button: true,
            selected: section == selected,
            label: context.l10n.tabSemantics(
              section.localizedLabel(context.l10n),
            ),
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onSelected(section),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: GoSizes.minimumTouchTarget,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: section == selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  section.localizedLabel(context.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: section == selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: section == selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class KeyMoveNumericCard extends StatelessWidget {
  const KeyMoveNumericCard({
    required this.data,
    required this.moveNumber,
    required this.onTap,
    super.key,
    this.compact = false,
  });

  final ReviewScreenData data;
  final int moveNumber;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final after = data.afterMove(moveNumber);
    final before = data.beforeMove(moveNumber);
    final played = data.record.moves[moveNumber - 1];
    final best = before.candidates.firstOrNull?.move;
    final severity = data.momentAt(moveNumber)?.severityRank;
    final title = severity == null
        ? l10n.regularMoveTitle(moveNumber)
        : l10n.rankedKeyMoveTitle(severity, moveNumber);
    final comparison =
        '${formatMove(played, data.record.boardSize, l10n)} → '
        '${best == null ? '—' : formatMove(best, data.record.boardSize, l10n)}';
    final detail =
        '${formatPointLoss(after.playedMovePointLoss, l10n)} · '
        '${formatPercentagePointLoss(after.playedMoveWinRateLoss)}';
    return _NumericActionCard(
      semanticLabel: l10n.keyMoveSemantics(title, comparison, detail),
      title: title,
      primary: comparison,
      detail: detail,
      badge: severity == null ? l10n.regularMoveBadge : l10n.lossRankBadge,
      onTap: onTap,
      compact: compact,
      severe: (after.playedMovePointLoss ?? 0) >= 3,
    );
  }
}

class CandidateNumericCard extends StatelessWidget {
  const CandidateNumericCard({
    required this.data,
    required this.moveNumber,
    required this.onTap,
    super.key,
    this.compact = false,
  });

  final ReviewScreenData data;
  final int moveNumber;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final before = data.beforeMove(moveNumber);
    final best = before.candidates.firstOrNull;
    if (best == null) {
      return SurfacePanel(
        child: Center(child: Text(context.l10n.noCandidateData)),
      );
    }
    final l10n = context.l10n;
    final move = formatMove(best.move, data.record.boardSize, l10n);
    final detail = l10n.candidateMetricDetail(
      formatPercent(best.winRate),
      formatScore(best.scoreLead, l10n),
      l10n.visitsValue(formatVisits(best.visits)),
    );
    return _NumericActionCard(
      semanticLabel: l10n.bestCandidateSemantics(move, detail),
      title: l10n.bestCandidate,
      primary: move,
      detail: detail,
      badge: l10n.pvMoveCount(best.principalVariation.length),
      onTap: onTap,
      compact: compact,
    );
  }
}

class TrendNumericCard extends StatelessWidget {
  const TrendNumericCard({
    required this.data,
    required this.currentMove,
    super.key,
    this.compact = false,
  });

  final ReviewScreenData data;
  final int currentMove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final node = data.analysis.analysisAt(currentMove)!;
    final samples = <ScoreSample>[
      for (final point in data.report.scoreTrend)
        ScoreSample(move: point.moveNumber, scoreLead: point.scoreLead),
    ];
    if (compact) {
      final value = context.l10n.trendCompactValue(
        currentMove,
        formatScore(node.scoreLead, context.l10n),
        formatPercent(node.blackWinRate),
      );
      final fragments = value
          .split(RegExp(r'\s*[·•|｜]\s*'))
          .map(_lastNumericToken)
          .toList(growable: false);
      return SurfacePanel(
        padding: const EdgeInsets.all(GoSpacing.s2),
        child: Semantics(
          label: value,
          excludeSemantics: true,
          child: Center(
            child: Wrap(
              key: const Key('review-trend-numeric-content'),
              alignment: WrapAlignment.center,
              spacing: GoSpacing.s1,
              children: <Widget>[
                for (final fragment in fragments)
                  Text(
                    fragment,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(height: 1),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return SurfacePanel(
      padding: const EdgeInsets.all(GoSpacing.s1),
      child: ScoreChart(
        samples: samples,
        currentMove: currentMove,
        height: 78,
        semanticLabel: context.l10n.globalScoreTrend,
      ),
    );
  }
}

class GameNumericCard extends StatelessWidget {
  const GameNumericCard({
    required this.data,
    required this.onTap,
    super.key,
    this.compact = false,
  });

  final ReviewScreenData data;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final metrics = data.report.metrics;
    final l10n = context.l10n;
    final detail = l10n.gameMetricsDetail(
      l10n.pointsValue(metrics.averagePointLoss.toStringAsFixed(1)),
      formatPercent(metrics.topThreeRate),
      formatPercent(metrics.severeMistakeRate),
    );
    return _NumericActionCard(
      semanticLabel: l10n.gameMetricsSemantics(detail),
      title: l10n.gameMetricsTitle,
      primary: l10n.totalMovesKeyMoves(
        data.totalMoves,
        data.keyMoveNumbers.length,
      ),
      detail: detail,
      badge: l10n.performanceNeedsCalibration,
      onTap: onTap,
      compact: compact,
    );
  }
}

class _NumericActionCard extends StatelessWidget {
  const _NumericActionCard({
    required this.semanticLabel,
    required this.title,
    required this.primary,
    required this.detail,
    required this.badge,
    required this.onTap,
    required this.compact,
    this.severe = false,
  });

  final String semanticLabel;
  final String title;
  final String primary;
  final String detail;
  final String badge;
  final VoidCallback onTap;
  final bool compact;
  final bool severe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extraLargeText = MediaQuery.textScalerOf(context).scale(1) >= 2.5;
    final denseText = compact || extraLargeText;
    final severeSurface = Color.alphaBlend(
      theme.colorScheme.error.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.14 : 0.08,
      ),
      theme.colorScheme.surface,
    );
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: SurfacePanel(
        padding: EdgeInsets.zero,
        color: severe ? severeSurface : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GoRadii.card),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: denseText ? GoSpacing.s1 : GoSpacing.s2,
              vertical: denseText ? 0 : GoSpacing.s1,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: denseText
                      ? Center(
                          child: Wrap(
                            key: const Key('review-numeric-content'),
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: GoSpacing.s1,
                            runSpacing: 0,
                            children: _denseFragments().indexed
                                .map((entry) {
                                  final (index, fragment) = entry;
                                  return Text(
                                    fragment,
                                    key: switch (index) {
                                      0 => const Key('review-numeric-title'),
                                      1 => const Key('review-numeric-primary'),
                                      _ => null,
                                    },
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      height: 1,
                                    ),
                                  );
                                })
                                .toList(growable: false),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    title,
                                    key: const Key('review-numeric-title'),
                                    maxLines: 2,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                ),
                                if (!compact)
                                  MetricPill(
                                    label: badge,
                                    compact: true,
                                    tone: MetricTone.gold,
                                  ),
                              ],
                            ),
                            Text(
                              primary,
                              key: const Key('review-numeric-primary'),
                              maxLines: 2,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              detail,
                              key: const Key('review-numeric-detail'),
                              maxLines: compact ? 2 : 3,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                ),
                if (!denseText) const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _denseFragments() {
    final compactTitle = title.split(RegExp(r'\s*[·•|｜]\s*')).first;
    final primaryParts = primary.contains(RegExp(r'[·•|｜]'))
        ? primary.split(RegExp(r'\s*[·•|｜]\s*'))
        : <String>[primary];
    final detailParts = detail.split(RegExp(r'\s*[·•|｜]\s*'));
    return <String>[
      compactTitle,
      ...primaryParts.map(_lastNumericToken),
      ...detailParts.map(_lastNumericToken),
    ].where((fragment) => fragment.isNotEmpty).toList(growable: false);
  }
}

String _lastNumericToken(String source) {
  final matches = RegExp(r'[-+−]?\d[\d,.]*%?').allMatches(source).toList();
  if (matches.isEmpty || source.contains(RegExp(r'[A-Za-z]\d'))) {
    return source.trim();
  }
  return matches.last.group(0)!;
}
