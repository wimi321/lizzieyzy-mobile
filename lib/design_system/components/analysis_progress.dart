import 'package:flutter/material.dart';

import '../tokens.dart';
import 'metric_pill.dart';

enum AnalysisProgressState { running, paused, completed, error }

class AnalysisProgress extends StatelessWidget {
  const AnalysisProgress({
    required this.completed,
    required this.total,
    super.key,
    this.state = AnalysisProgressState.running,
    this.title = '标准分析',
    this.detail = '可在后台继续',
    this.onPauseResume,
    this.onCancel,
  }) : assert(completed >= 0),
       assert(total >= 0),
       assert(completed <= total || total == 0);

  final int completed;
  final int total;
  final AnalysisProgressState state;
  final String title;
  final String detail;
  final VoidCallback? onPauseResume;
  final VoidCallback? onCancel;

  double? get _progress => total == 0 ? null : completed / total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateData = _stateData;
    final isPaused = state == AnalysisProgressState.paused;
    final canControl = state == AnalysisProgressState.running || isPaused;
    return Semantics(
      container: true,
      liveRegion: true,
      label:
          '$title，${stateData.label}，$completed / $total${total == 0 ? '' : '，${(_progress! * 100).round()}%'}，$detail',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(GoSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: GoSpacing.s1),
                        Text(detail, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: GoSpacing.s2),
                  MetricPill(
                    label: stateData.label,
                    tone: stateData.tone,
                    icon: stateData.icon,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: GoSpacing.s4),
              LinearProgressIndicator(
                value: state == AnalysisProgressState.completed ? 1 : _progress,
                minHeight: 7,
                semanticsLabel: '分析进度',
                // Progress semantics require a numeric value between 0 and
                // 100. The enclosing live region carries the exact count.
                semanticsValue: total == 0
                    ? null
                    : '${(_progress! * 100).round()}',
              ),
              const SizedBox(height: GoSpacing.s2),
              LayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final controls = <Widget>[
                    TextButton.icon(
                      onPressed: onPauseResume,
                      icon: Icon(
                        isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                      ),
                      label: Text(isPaused ? '继续' : '暂停'),
                    ),
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('取消'),
                    ),
                  ];
                  final count = Text(
                    '$completed / $total',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  );
                  if (textScale > 1.35 || constraints.maxWidth < 320) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        count,
                        if (canControl) ...<Widget>[
                          const SizedBox(height: GoSpacing.s1),
                          Wrap(
                            spacing: GoSpacing.s2,
                            runSpacing: GoSpacing.s2,
                            children: controls,
                          ),
                        ],
                      ],
                    );
                  }
                  return Row(
                    children: <Widget>[
                      count,
                      const Spacer(),
                      if (canControl)
                        Wrap(
                          spacing: GoSpacing.s2,
                          runSpacing: GoSpacing.s2,
                          alignment: WrapAlignment.end,
                          children: controls,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  _AnalysisStateData get _stateData => switch (state) {
    AnalysisProgressState.running => const _AnalysisStateData(
      label: '分析中',
      tone: MetricTone.primary,
      icon: Icons.pending_rounded,
    ),
    AnalysisProgressState.paused => const _AnalysisStateData(
      label: '已暂停',
      tone: MetricTone.gold,
      icon: Icons.pause_circle_outline_rounded,
    ),
    AnalysisProgressState.completed => const _AnalysisStateData(
      label: '已完成',
      tone: MetricTone.positive,
      icon: Icons.check_circle_outline_rounded,
    ),
    AnalysisProgressState.error => const _AnalysisStateData(
      label: '分析失败',
      tone: MetricTone.negative,
      icon: Icons.error_outline_rounded,
    ),
  };
}

class _AnalysisStateData {
  const _AnalysisStateData({
    required this.label,
    required this.tone,
    required this.icon,
  });

  final String label;
  final MetricTone tone;
  final IconData icon;
}
