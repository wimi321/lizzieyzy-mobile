import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';

import '../../common/presentation/feature_chrome.dart';
import '../../fixtures/ui_fixtures.dart';

class GamePerformanceScreen extends StatelessWidget {
  const GamePerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = UiFixtures.performance;
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: <Widget>[
          const FeatureTopBar(
            title: '本局',
            subtitle: '山海一局 · 执黑 · 86个有效决策',
            leading: BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final largeText = textScale > 1.45;
                  final compact = constraints.maxHeight < 690 || largeText;
                  final gap = compact ? GoSpacing.s1 : GoSpacing.s2;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      GoSpacing.s3,
                      GoSpacing.s1,
                      GoSpacing.s3,
                      GoSpacing.s1,
                    ),
                    child: Column(
                      key: const Key('performance-single-viewport'),
                      children: <Widget>[
                        _PerformanceOverview(
                          lowerRank: model.lowerRank,
                          upperRank: model.upperRank,
                          confidence: model.confidence,
                          decisions: model.effectiveDecisions,
                          compact: compact,
                          largeText: largeText,
                        ),
                        SizedBox(height: gap),
                        Semantics(
                          label: '此结果只表示本局发挥，不是长期棋力或平台段位',
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: GoSpacing.s3,
                              vertical: GoSpacing.s2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(GoRadii.card),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: theme.colorScheme.onSecondaryContainer,
                                  size: 18,
                                ),
                                const SizedBox(width: GoSpacing.s2),
                                Expanded(
                                  child: Text(
                                    '仅代表这一盘的发挥区间，不是长期棋力或平台段位。',
                                    maxLines: largeText ? 1 : 2,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: gap),
                        if (largeText)
                          _LargeTextPerformanceDetails(
                            averageLoss: model.averageLoss,
                            topThreeRate: model.topThreeRate,
                            severeMistakeRate: model.severeMistakeRate,
                            decisions: model.effectiveDecisions,
                          )
                        else ...<Widget>[
                          _CoreMetricsPanel(
                            averageLoss: model.averageLoss,
                            topThreeRate: model.topThreeRate,
                            severeMistakeRate: model.severeMistakeRate,
                          ),
                          SizedBox(height: gap),
                          const _PhasePanel(),
                          SizedBox(height: gap),
                          const _QualityPanel(),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceOverview extends StatelessWidget {
  const _PerformanceOverview({
    required this.lowerRank,
    required this.upperRank,
    required this.confidence,
    required this.decisions,
    required this.compact,
    required this.largeText,
  });

  final String lowerRank;
  final String upperRank;
  final String confidence;
  final int decisions;
  final bool compact;
  final bool largeText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '本局发挥估计，$lowerRank到$upperRank，80%区间，$confidence，$decisions个有效决策',
      excludeSemantics: true,
      child: SurfacePanel(
        padding: EdgeInsets.symmetric(
          horizontal: GoSpacing.s3,
          vertical: compact ? GoSpacing.s2 : GoSpacing.s3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '本局发挥估计',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Text(
                  confidence,
                  maxLines: 1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: context.goColors.dataGold,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 0 : GoSpacing.s1),
            if (largeText)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    '$lowerRank–$upperRank',
                    maxLines: 1,
                    style: theme.textTheme.headlineMedium,
                  ),
                  Text('80% 区间', style: theme.textTheme.bodySmall),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '$lowerRank–$upperRank',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  Text('80% 区间', style: theme.textTheme.bodySmall),
                ],
              ),
            const SizedBox(height: GoSpacing.s1),
            const _RangeBand(),
            const SizedBox(height: GoSpacing.s1),
            if (largeText)
              Text(
                '$decisions个有效决策 · 校准范围20级至9段',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              )
            else
              Row(
                children: <Widget>[
                  Text('20级', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  Text('$decisions 个有效决策', style: theme.textTheme.labelMedium),
                  const Spacer(),
                  Text('9段', style: theme.textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RangeBand extends StatelessWidget {
  const _RangeBand();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              Container(
                height: 7,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(GoRadii.pill),
                ),
              ),
              Positioned(
                left: width * 0.28,
                width: width * 0.40,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(GoRadii.pill),
                  ),
                ),
              ),
              Positioned(
                left: width * 0.48 - 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: context.goColors.dataGold,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CoreMetricsPanel extends StatelessWidget {
  const _CoreMetricsPanel({
    required this.averageLoss,
    required this.topThreeRate,
    required this.severeMistakeRate,
  });

  final String averageLoss;
  final String topThreeRate;
  final String severeMistakeRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfacePanel(
      padding: const EdgeInsets.symmetric(
        horizontal: GoSpacing.s3,
        vertical: GoSpacing.s2,
      ),
      child: Row(
        children: <Widget>[
          Text('核心指标', style: theme.textTheme.labelLarge),
          const SizedBox(width: GoSpacing.s3),
          Expanded(
            child: LabeledValue(label: '平均目损', value: averageLoss),
          ),
          Expanded(
            child: LabeledValue(
              label: 'Top-3',
              value: topThreeRate,
              alignEnd: true,
            ),
          ),
          Expanded(
            child: LabeledValue(
              label: '严重失误',
              value: severeMistakeRate,
              valueColor: theme.colorScheme.error,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeTextPerformanceDetails extends StatefulWidget {
  const _LargeTextPerformanceDetails({
    required this.averageLoss,
    required this.topThreeRate,
    required this.severeMistakeRate,
    required this.decisions,
  });

  final String averageLoss;
  final String topThreeRate;
  final String severeMistakeRate;
  final int decisions;

  @override
  State<_LargeTextPerformanceDetails> createState() =>
      _LargeTextPerformanceDetailsState();
}

class _LargeTextPerformanceDetailsState
    extends State<_LargeTextPerformanceDetails> {
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summaries = <String>[
      '平均目损 ${widget.averageLoss} · Top-3 ${widget.topThreeRate} · 严重失误 ${widget.severeMistakeRate}',
      '布局 2级 / 1.1目 · 中盘 4级 / 2.7目 · 官子 1级 / 0.8目',
      '完整19路 · ${widget.decisions}/118有效决策 · 1,000+访问 · 校准范围20级–9段',
    ];
    return Semantics(
      container: true,
      label: summaries[_selected],
      excludeSemantics: true,
      child: SurfacePanel(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                for (final (index, label) in <String>['核心', '阶段', '样本'].indexed)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: _selected == index,
                      child: InkWell(
                        onTap: () => setState(() => _selected = index),
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: GoSizes.minimumTouchTarget,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selected == index
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            label,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(GoSpacing.s2),
              child: Text(
                summaries[_selected],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhasePanel extends StatelessWidget {
  const _PhasePanel();

  @override
  Widget build(BuildContext context) {
    return const SurfacePanel(
      padding: EdgeInsets.symmetric(
        horizontal: GoSpacing.s3,
        vertical: GoSpacing.s2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _PanelHeading(title: '分阶段表现'),
          SizedBox(height: GoSpacing.s1),
          _PhaseMetric(
            label: '布局 1–60',
            value: '2级',
            score: 0.76,
            loss: '1.1目',
          ),
          _PhaseMetric(
            label: '中盘 61–170',
            value: '4级',
            score: 0.52,
            loss: '2.7目',
            warning: true,
          ),
          _PhaseMetric(
            label: '官子 171–236',
            value: '1级',
            score: 0.84,
            loss: '0.8目',
          ),
        ],
      ),
    );
  }
}

class _PhaseMetric extends StatelessWidget {
  const _PhaseMetric({
    required this.label,
    required this.value,
    required this.score,
    required this.loss,
    this.warning = false,
  });

  final String label;
  final String value;
  final double score;
  final String loss;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = warning ? theme.colorScheme.error : theme.colorScheme.primary;
    return Semantics(
      label: '$label，发挥$value，平均目损$loss',
      child: SizedBox(
        height: 30,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 92,
              child: Text(label, style: theme.textTheme.labelSmall),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(GoRadii.pill),
                child: LinearProgressIndicator(
                  value: score,
                  minHeight: 6,
                  color: color,
                  semanticsLabel: label,
                  semanticsValue: '${(score * 100).round()}',
                ),
              ),
            ),
            const SizedBox(width: GoSpacing.s2),
            SizedBox(
              width: 38,
              child: Text(loss, style: theme.textTheme.bodySmall),
            ),
            SizedBox(
              width: 28,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityPanel extends StatelessWidget {
  const _QualityPanel();

  @override
  Widget build(BuildContext context) {
    return const SurfacePanel(
      padding: EdgeInsets.symmetric(
        horizontal: GoSpacing.s3,
        vertical: GoSpacing.s2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _PanelHeading(title: '样本质量'),
          SizedBox(height: GoSpacing.s1),
          Row(
            children: <Widget>[
              Expanded(
                child: _QualityItem(label: '完整19路', value: '通过'),
              ),
              Expanded(
                child: _QualityItem(label: '有效决策', value: '86 / 118'),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: _QualityItem(label: '分析档位', value: '1,000+访问'),
              ),
              Expanded(
                child: _QualityItem(label: '校准范围', value: '20级–9段'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _QualityItem extends StatelessWidget {
  const _QualityItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 28,
      child: Row(
        children: <Widget>[
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
