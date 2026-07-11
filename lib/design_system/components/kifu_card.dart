import 'package:flutter/material.dart';

import '../tokens.dart';
import 'metric_pill.dart';

enum KifuStatus { analyzed, analyzing, unreviewed, error }

class KifuCard extends StatelessWidget {
  const KifuCard({
    required this.blackPlayer,
    required this.whitePlayer,
    super.key,
    this.title,
    this.subtitle,
    this.moveCount,
    this.status = KifuStatus.unreviewed,
    this.analysisProgress,
    this.thumbnail,
    this.onTap,
  }) : assert(
         analysisProgress == null ||
             (analysisProgress >= 0 && analysisProgress <= 1),
       );

  final String blackPlayer;
  final String whitePlayer;
  final String? title;
  final String? subtitle;
  final int? moveCount;
  final KifuStatus status;
  final double? analysisProgress;
  final Widget? thumbnail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final statusData = _statusData;
    final semantics = <String>[
      title ?? '$blackPlayer 对 $whitePlayer',
      '黑方 $blackPlayer，白方 $whitePlayer',
      ?subtitle,
      if (moveCount != null) '$moveCount 手',
      statusData.label,
    ].join('，');

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: semantics,
      excludeSemantics: true,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GoRadii.card),
          child: Padding(
            padding: const EdgeInsets.all(GoSpacing.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (thumbnail != null && textScale <= 1.45) ...<Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(GoRadii.small),
                    child: SizedBox.square(dimension: 76, child: thumbnail),
                  ),
                  const SizedBox(width: GoSpacing.s4),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title ?? '$blackPlayer  对  $whitePlayer',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: GoSpacing.s1),
                      Text(
                        '● $blackPlayer   ○ $whitePlayer',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: GoSpacing.s1),
                        Text(
                          subtitle!,
                          maxLines: textScale > 1.45 ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: GoSpacing.s3),
                      Wrap(
                        spacing: GoSpacing.s2,
                        runSpacing: GoSpacing.s2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          MetricPill(
                            label: statusData.label,
                            tone: statusData.tone,
                            icon: statusData.icon,
                            compact: true,
                          ),
                          if (moveCount != null)
                            MetricPill(label: '$moveCount 手', compact: true),
                        ],
                      ),
                      if (status == KifuStatus.analyzing &&
                          analysisProgress != null) ...<Widget>[
                        const SizedBox(height: GoSpacing.s3),
                        LinearProgressIndicator(value: analysisProgress),
                      ],
                    ],
                  ),
                ),
                if (onTap != null) ...<Widget>[
                  const SizedBox(width: GoSpacing.s2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    semanticLabel: '打开',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _KifuStatusData get _statusData => switch (status) {
    KifuStatus.analyzed => const _KifuStatusData(
      label: '已复盘',
      tone: MetricTone.positive,
      icon: Icons.check_circle_outline_rounded,
    ),
    KifuStatus.analyzing => const _KifuStatusData(
      label: '分析中',
      tone: MetricTone.primary,
      icon: Icons.pending_rounded,
    ),
    KifuStatus.unreviewed => const _KifuStatusData(
      label: '未复盘',
      tone: MetricTone.neutral,
      icon: Icons.circle_outlined,
    ),
    KifuStatus.error => const _KifuStatusData(
      label: '需要处理',
      tone: MetricTone.negative,
      icon: Icons.error_outline_rounded,
    ),
  };
}

class _KifuStatusData {
  const _KifuStatusData({
    required this.label,
    required this.tone,
    required this.icon,
  });

  final String label;
  final MetricTone tone;
  final IconData icon;
}
