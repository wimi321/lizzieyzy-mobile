import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';
import '../../fixtures/ui_fixtures.dart';

class AnalysisProgressScreen extends StatefulWidget {
  const AnalysisProgressScreen({super.key});

  @override
  State<AnalysisProgressScreen> createState() => _AnalysisProgressScreenState();
}

class _AnalysisProgressScreenState extends State<AnalysisProgressScreen> {
  var _state = AnalysisProgressState.running;

  @override
  Widget build(BuildContext context) {
    final fixture = UiFixtures.analysis;
    final usesLargeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    final detail =
        '已用 ${fixture.elapsed} · 剩余 ${fixture.estimatedRemaining} · 可在后台继续';
    return Scaffold(
      body: Column(
        children: <Widget>[
          const FeatureTopBar(
            title: '分析棋谱',
            subtitle: '棋路未央  vs  山海一局',
            leading: BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (usesLargeText) {
                    return _LargeTextProgressLayout(
                      completed: fixture.completed,
                      total: fixture.total,
                      title: fixture.profile,
                      detail: detail,
                      state: _state,
                      onPauseResume: _togglePause,
                      onCancel: () => _confirmCancel(context),
                      onOpenReview: () =>
                          Navigator.pushNamed(context, AppRoutes.keyMoveReview),
                    );
                  }
                  const horizontalPadding = GoSpacing.s3;
                  final boardSide = math.min<double>(
                    constraints.maxWidth - horizontalPadding * 2,
                    math.max<double>(240, constraints.maxHeight - 264),
                  );
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      horizontalPadding,
                      GoSpacing.s1,
                      horizontalPadding,
                      GoSpacing.s1,
                    ),
                    child: Column(
                      children: <Widget>[
                        SizedBox.square(
                          dimension: boardSide,
                          child: const GoBoard(
                            stones: UiFixtures.stones,
                            lastMove: BoardPoint(16, 5),
                            semanticLabel: '正在分析的十九路棋盘，当前第142手',
                          ),
                        ),
                        const SizedBox(height: GoSpacing.s2),
                        _CompactAnalysisPanel(
                          completed: fixture.completed,
                          total: fixture.total,
                          title: fixture.profile,
                          detail: detail,
                          state: _state,
                          onPauseResume: _togglePause,
                          onCancel: () => _confirmCancel(context),
                        ),
                        const SizedBox(height: GoSpacing.s2),
                        _CompactQueue(
                          running: _state == AnalysisProgressState.running,
                        ),
                        const SizedBox(height: GoSpacing.s2),
                        SizedBox(
                          width: double.infinity,
                          height: GoSizes.minimumTouchTarget,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.keyMoveReview,
                            ),
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('查看已完成的142手'),
                          ),
                        ),
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

  void _togglePause() => setState(() {
    _state = _state == AnalysisProgressState.paused
        ? AnalysisProgressState.running
        : AnalysisProgressState.paused;
  });

  Future<void> _confirmCancel(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('取消分析？'),
      content: const Text('已完成的142手会保留，下次可以继续。'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('继续分析'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            Navigator.maybePop(context);
          },
          child: const Text('取消分析'),
        ),
      ],
    ),
  );
}

/// A dedicated large-type composition keeps the complete task in one viewport.
///
/// The board receives the remaining space, while verbose secondary information
/// moves into semantics and the three analysis stages use shorter visual labels.
/// No text is scaled down and no vertical scrolling is introduced.
class _LargeTextProgressLayout extends StatelessWidget {
  const _LargeTextProgressLayout({
    required this.completed,
    required this.total,
    required this.title,
    required this.detail,
    required this.state,
    required this.onPauseResume,
    required this.onCancel,
    required this.onOpenReview,
  });

  final int completed;
  final int total;
  final String title;
  final String detail;
  final AnalysisProgressState state;
  final VoidCallback onPauseResume;
  final VoidCallback onCancel;
  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GoSpacing.s3,
        GoSpacing.s1,
        GoSpacing.s3,
        GoSpacing.s1,
      ),
      child: Column(
        children: <Widget>[
          const Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: GoBoard(
                  stones: UiFixtures.stones,
                  lastMove: BoardPoint(16, 5),
                  semanticLabel: '正在分析的十九路棋盘，当前第142手',
                ),
              ),
            ),
          ),
          const SizedBox(height: GoSpacing.s1),
          _LargeTextAnalysisPanel(
            completed: completed,
            total: total,
            title: title,
            detail: detail,
            state: state,
            onPauseResume: onPauseResume,
            onCancel: onCancel,
          ),
          const SizedBox(height: GoSpacing.s1),
          _CompactQueue(
            running: state == AnalysisProgressState.running,
            largeText: true,
          ),
          const SizedBox(height: GoSpacing.s1),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenReview,
              icon: const Icon(Icons.visibility_outlined),
              label: Text('查看已完成的$completed手'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeTextAnalysisPanel extends StatelessWidget {
  const _LargeTextAnalysisPanel({
    required this.completed,
    required this.total,
    required this.title,
    required this.detail,
    required this.state,
    required this.onPauseResume,
    required this.onCancel,
  });

  final int completed;
  final int total;
  final String title;
  final String detail;
  final AnalysisProgressState state;
  final VoidCallback onPauseResume;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paused = state == AnalysisProgressState.paused;
    final progress = total == 0 ? null : completed / total;
    return Semantics(
      liveRegion: true,
      label: '$title，${paused ? '已暂停' : '分析中'}，$completed / $total，$detail',
      child: SurfacePanel(
        padding: const EdgeInsets.all(GoSpacing.s2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: GoSpacing.s2),
                MetricPill(
                  label: paused ? '已暂停' : '分析中',
                  tone: paused ? MetricTone.gold : MetricTone.primary,
                  icon: paused
                      ? Icons.pause_circle_outline_rounded
                      : Icons.pending_rounded,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: GoSpacing.s1),
            LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              semanticsLabel: '分析进度',
              semanticsValue: progress == null
                  ? null
                  : '${(progress * 100).round()}',
            ),
            const SizedBox(height: GoSpacing.s1),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '$completed / $total',
                    maxLines: 1,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onPauseResume,
                  tooltip: paused ? '继续分析' : '暂停分析',
                  icon: Icon(
                    paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  ),
                ),
                IconButton(
                  onPressed: onCancel,
                  tooltip: '取消分析',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactAnalysisPanel extends StatelessWidget {
  const _CompactAnalysisPanel({
    required this.completed,
    required this.total,
    required this.title,
    required this.detail,
    required this.state,
    required this.onPauseResume,
    required this.onCancel,
  });

  final int completed;
  final int total;
  final String title;
  final String detail;
  final AnalysisProgressState state;
  final VoidCallback onPauseResume;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paused = state == AnalysisProgressState.paused;
    final progress = total == 0 ? null : completed / total;
    return Semantics(
      liveRegion: true,
      label: '$title，${paused ? '已暂停' : '分析中'}，$completed / $total，$detail',
      child: SurfacePanel(
        padding: const EdgeInsets.fromLTRB(
          GoSpacing.s3,
          GoSpacing.s2,
          GoSpacing.s2,
          GoSpacing.s2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: theme.textTheme.titleSmall),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                MetricPill(
                  label: paused ? '已暂停' : '分析中',
                  tone: paused ? MetricTone.gold : MetricTone.primary,
                  icon: paused
                      ? Icons.pause_circle_outline_rounded
                      : Icons.pending_rounded,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: GoSpacing.s2),
            LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              semanticsLabel: '分析进度',
              semanticsValue: progress == null
                  ? null
                  : '${(progress * 100).round()}',
            ),
            Row(
              children: <Widget>[
                Text(
                  '$completed / $total',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onPauseResume,
                  icon: Icon(
                    paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  ),
                  label: Text(paused ? '继续' : '暂停'),
                ),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('取消'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactQueue extends StatelessWidget {
  const _CompactQueue({required this.running, this.largeText = false});

  final bool running;
  final bool largeText;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      padding: const EdgeInsets.symmetric(
        horizontal: GoSpacing.s2,
        vertical: GoSpacing.s1,
      ),
      child: Row(
        children: <Widget>[
          _QueueStage(
            icon: Icons.check_circle_rounded,
            label: '读取棋谱',
            visualLabel: largeText ? '读取' : null,
            active: true,
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: context.goColors.softDivider,
          ),
          _QueueStage(
            icon: Icons.auto_graph_rounded,
            label: '全局分析',
            visualLabel: largeText ? '分析' : null,
            active: running,
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: context.goColors.softDivider,
          ),
          _QueueStage(
            icon: Icons.summarize_outlined,
            label: '生成报告',
            visualLabel: largeText ? '报告' : null,
          ),
        ],
      ),
    );
  }
}

class _QueueStage extends StatelessWidget {
  const _QueueStage({
    required this.icon,
    required this.label,
    this.visualLabel,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final String? visualLabel;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        label: '$label，${active ? '已完成或进行中' : '等待中'}',
        excludeSemantics: true,
        child: SizedBox(
          height: GoSizes.minimumTouchTarget,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: GoSpacing.s1),
              Flexible(
                child: Text(
                  visualLabel ?? label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
