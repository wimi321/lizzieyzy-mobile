import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../tokens.dart';
import 'metric_pill.dart';

enum AnalysisProgressState { running, paused, completed, error }

class AnalysisProgress extends StatelessWidget {
  const AnalysisProgress({
    required this.completed,
    required this.total,
    super.key,
    this.state = AnalysisProgressState.running,
    this.title,
    this.detail,
    this.onPauseResume,
    this.onCancel,
  }) : assert(completed >= 0),
       assert(total >= 0),
       assert(completed <= total || total == 0);

  final int completed;
  final int total;
  final AnalysisProgressState state;
  final String? title;
  final String? detail;
  final VoidCallback? onPauseResume;
  final VoidCallback? onCancel;

  double? get _progress => total == 0 ? null : completed / total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final resolvedTitle = title ?? l10n.analysisDefaultTitle;
    final resolvedDetail = detail ?? l10n.analysisContinuesInApp;
    final stateData = _stateData(l10n);
    final isPaused = state == AnalysisProgressState.paused;
    final canControl = state == AnalysisProgressState.running || isPaused;
    return Semantics(
      container: true,
      liveRegion: true,
      label:
          '$resolvedTitle, ${stateData.label}, $completed / $total'
          '${total == 0 ? '' : ', ${(_progress! * 100).round()}%'}, '
          '$resolvedDetail',
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
                        Text(resolvedTitle, style: theme.textTheme.titleMedium),
                        const SizedBox(height: GoSpacing.s1),
                        Text(resolvedDetail, style: theme.textTheme.bodySmall),
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
                semanticsLabel: l10n.analysisProgressLabel,
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
                      label: Text(
                        isPaused ? l10n.resumeAction : l10n.pauseAction,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close_rounded),
                      label: Text(l10n.cancelAction),
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

  _AnalysisStateData _stateData(AppLocalizations l10n) => switch (state) {
    AnalysisProgressState.running => _AnalysisStateData(
      label: l10n.analysisRunning,
      tone: MetricTone.primary,
      icon: Icons.pending_rounded,
    ),
    AnalysisProgressState.paused => _AnalysisStateData(
      label: l10n.analysisPaused,
      tone: MetricTone.gold,
      icon: Icons.pause_circle_outline_rounded,
    ),
    AnalysisProgressState.completed => _AnalysisStateData(
      label: l10n.analysisCompleted,
      tone: MetricTone.positive,
      icon: Icons.check_circle_outline_rounded,
    ),
    AnalysisProgressState.error => _AnalysisStateData(
      label: l10n.analysisFailed,
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
