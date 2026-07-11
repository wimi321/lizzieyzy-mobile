import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';

import '../../common/presentation/feature_chrome.dart';
import '../../fixtures/ui_fixtures.dart';

class KeyMoveSummary extends StatelessWidget {
  const KeyMoveSummary({super.key, this.onOpenVariation, this.compact = false});

  final VoidCallback? onOpenVariation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = UiFixtures.keyMove;
    if (compact) {
      return SurfacePanel(
        padding: EdgeInsets.zero,
        color: theme.colorScheme.errorContainer,
        child: Semantics(
          button: onOpenVariation != null,
          label:
              '第${model.moveNumber}手，实战${model.playedMove}，最佳${model.bestMove}，目差损失${model.scoreLoss}，胜率变化${model.winRateLoss}',
          child: InkWell(
            onTap: onOpenVariation,
            borderRadius: BorderRadius.circular(GoRadii.card),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GoSpacing.s3,
                  vertical: GoSpacing.s2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          '第${model.moveNumber}手',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: GoSpacing.s2),
                        Expanded(
                          child: Text(
                            '${model.playedMove} → ${model.bestMove}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          model.scoreLoss,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GoSpacing.s1),
                    Row(
                      children: <Widget>[
                        const CandidateMarker(
                          label: 'A',
                          tone: CandidateTone.primary,
                          diameter: 22,
                        ),
                        const SizedBox(width: GoSpacing.s2),
                        Expanded(
                          child: Text(
                            '${model.bestMove} · 最佳候选',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        Text(
                          '${model.winRateLoss} · ${model.scoreLead}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (onOpenVariation != null)
                          const Icon(Icons.chevron_right_rounded, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SurfacePanel(
          color: theme.colorScheme.errorContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GoSpacing.s3,
                      vertical: GoSpacing.s2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(GoRadii.pill),
                    ),
                    child: Text(
                      '第${model.moveNumber}手',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onError,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_downward_rounded,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: GoSpacing.s1),
                  Text(
                    model.scoreLoss,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GoSpacing.s4),
              Row(
                children: <Widget>[
                  Expanded(
                    child: LabeledValue(label: '实战', value: model.playedMove),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: LabeledValue(
                      label: '最佳',
                      value: model.bestMove,
                      valueColor: theme.colorScheme.primary,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GoSpacing.s3),
              Wrap(
                spacing: GoSpacing.s2,
                runSpacing: GoSpacing.s2,
                children: <Widget>[
                  MetricPill(
                    label: '目差损失',
                    value: model.scoreLoss,
                    tone: MetricTone.negative,
                  ),
                  MetricPill(
                    label: '胜率变化',
                    value: model.winRateLoss,
                    tone: MetricTone.negative,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: GoSpacing.s3),
        CandidateComparison(onTap: onOpenVariation),
      ],
    );
  }
}

class CandidateComparison extends StatelessWidget {
  const CandidateComparison({super.key, this.onTap, this.compact = false});

  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = UiFixtures.keyMove;
    if (compact) {
      return SurfacePanel(
        padding: EdgeInsets.zero,
        child: Semantics(
          button: onTap != null,
          label:
              '最佳候选${model.bestMove}，胜率${model.winRate}，目差${model.scoreLead}，${model.visits}访问',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(GoRadii.card),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: GoSpacing.s3),
                child: Row(
                  children: <Widget>[
                    const CandidateMarker(
                      label: 'A',
                      tone: CandidateTone.primary,
                      diameter: 28,
                    ),
                    const SizedBox(width: GoSpacing.s2),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${model.bestMove} · 最佳候选',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            '胜率 ${model.winRate} · 目差 ${model.scoreLead} · ${model.visits}访问',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null) const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return SurfacePanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GoRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(GoSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const CandidateMarker(
                    label: 'A',
                    tone: CandidateTone.primary,
                    diameter: 28,
                  ),
                  const SizedBox(width: GoSpacing.s2),
                  Expanded(
                    child: Text(
                      '${model.bestMove} · 最佳候选',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: GoSpacing.s3),
              Wrap(
                spacing: GoSpacing.s2,
                runSpacing: GoSpacing.s2,
                children: <Widget>[
                  MetricPill(label: '胜率', value: model.winRate),
                  MetricPill(
                    label: '目差',
                    value: model.scoreLead,
                    tone: MetricTone.positive,
                  ),
                  MetricPill(label: '访问', value: model.visits),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewTrendPanel extends StatelessWidget {
  const ReviewTrendPanel({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return SurfacePanel(
        padding: const EdgeInsets.all(GoSpacing.s2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('目差走势', style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                Text(
                  '黑 +2.1目 → 白 +3.1目',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: GoSpacing.s1),
            const ScoreChart(
              samples: UiFixtures.scoreSamples,
              currentMove: 87,
              height: 40,
            ),
          ],
        ),
      );
    }
    return SurfacePanel(
      padding: const EdgeInsets.all(GoSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('目差走势', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: GoSpacing.s3),
          const ScoreChart(
            samples: UiFixtures.scoreSamples,
            currentMove: 87,
            height: 180,
          ),
          const SizedBox(height: GoSpacing.s2),
          const Row(
            children: <Widget>[
              Expanded(
                child: LabeledValue(label: '第87手前', value: '黑 +2.1目'),
              ),
              Expanded(
                child: LabeledValue(
                  label: '第87手后',
                  value: '白 +3.1目',
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
