import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';
import '../../fixtures/ui_fixtures.dart';
import '../../fixtures/ui_models.dart';

class KifuHomeScreen extends StatelessWidget {
  const KifuHomeScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = const KifuHomeView();
    if (embedded) return content;
    return Scaffold(body: content);
  }
}

class KifuHomeView extends StatelessWidget {
  const KifuHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width >= 840 ? 760.0 : 680.0;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final largeTextMode = textScale >= 1.75;
    final extraLargeTextMode = textScale >= 2.75;
    final imported =
        KifuWorkspace.maybeOf(context)?.notifier?.documents ??
        const <domain.KifuDocument>[];
    final recent = <({KifuSummaryModel item, String route})>[
      for (final document in imported)
        (item: _summaryFor(document), route: _routeFor(document)),
      for (final item in UiFixtures.recentKifu)
        (item: item, route: AppRoutes.keyMoveReview),
    ];
    return Column(
      key: const Key('kifu-home-viewport'),
      children: <Widget>[
        FeatureTopBar(
          title: '棋谱',
          subtitle: 'LIZZIEYZY · 把每一盘复盘清楚',
          actions: <Widget>[
            IconButton(
              tooltip: '导入棋谱',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.importKifu),
              icon: const Icon(Icons.file_download_outlined),
            ),
            IconButton(
              tooltip: '设置',
              onPressed: () {},
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // At accessibility text sizes, reserve the saved vertical space
                // for complete (unclamped) glyphs and full-size touch targets.
                // The ordinary layout continues to show two recent games.
                final dense = constraints.maxHeight < 600 || largeTextMode;
                final recentCount = largeTextMode ? 1 : 2;
                final gap = dense ? GoSpacing.s2 : GoSpacing.s3;
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    GoSpacing.s4,
                    dense ? GoSpacing.s1 : GoSpacing.s2,
                    GoSpacing.s4,
                    dense ? GoSpacing.s2 : GoSpacing.s3,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _ScanHeroCard(
                            dense: dense,
                            onTap: () =>
                                Navigator.pushNamed(context, AppRoutes.camera),
                          ),
                          SizedBox(height: gap),
                          if (!extraLargeTextMode) ...<Widget>[
                            const SectionHeading(title: '正在分析'),
                            const SizedBox(height: GoSpacing.s2),
                            _ActiveAnalysisCard(
                              dense: dense,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.analysisProgress,
                              ),
                            ),
                            SizedBox(height: gap),
                          ],
                          SectionHeading(
                            title: '最近棋谱',
                            trailing: extraLargeTextMode
                                ? Semantics(
                                    button: true,
                                    label: '查看正在分析的棋谱',
                                    excludeSemantics: true,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.analysisProgress,
                                    ),
                                    child: IconButton(
                                      tooltip: '查看正在分析的棋谱',
                                      onPressed: () => Navigator.pushNamed(
                                        context,
                                        AppRoutes.analysisProgress,
                                      ),
                                      icon: const Icon(
                                        Icons.analytics_outlined,
                                      ),
                                    ),
                                  )
                                : TextButton(
                                    onPressed: () {},
                                    child: const Text('查看全部'),
                                  ),
                          ),
                          const SizedBox(height: GoSpacing.s1),
                          for (final entry in recent.take(
                            recentCount,
                          )) ...<Widget>[
                            _KifuTile(
                              dense: dense,
                              item: entry.item,
                              onTap: () =>
                                  Navigator.pushNamed(context, entry.route),
                            ),
                            const SizedBox(height: GoSpacing.s2),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  static KifuSummaryModel _summaryFor(domain.KifuDocument document) {
    final metadata = document.metadata;
    final (moves, status) = switch (document) {
      domain.VerifiedGameRecord(:final moves) => (moves.length, '已校验'),
      domain.PartialGameRecord(:final moves) => (moves.length, '需确认'),
      domain.PositionSnapshot() => (0, '当前局面'),
    };
    return KifuSummaryModel(
      blackPlayer: metadata.blackPlayer ?? '黑方',
      whitePlayer: metadata.whitePlayer ?? '白方',
      result: switch (document) {
        domain.VerifiedGameRecord() => '完整棋谱',
        domain.PartialGameRecord() => '片段棋谱',
        domain.PositionSnapshot() => '照片局面',
      },
      playedAt: '刚刚导入',
      moveCount: moves,
      status: status,
    );
  }

  static String _routeFor(domain.KifuDocument document) => switch (document) {
    domain.VerifiedGameRecord() => AppRoutes.analysisProgress,
    domain.PartialGameRecord() => AppRoutes.numberedCorrection,
    domain.PositionSnapshot() => AppRoutes.positionAnalysis,
  };
}

class _ScanHeroCard extends StatelessWidget {
  const _ScanHeroCard({required this.dense, required this.onTap});

  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = dense ? 44.0 : 48.0;
    return Semantics(
      button: true,
      label: '拍照识谱，打开相机识别棋盘',
      child: Material(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(GoRadii.large),
        child: InkWell(
          borderRadius: BorderRadius.circular(GoRadii.large),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(dense ? GoSpacing.s3 : GoSpacing.s4),
            child: Row(
              children: <Widget>[
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(GoRadii.card),
                  ),
                  child: Icon(
                    Icons.document_scanner_outlined,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: GoSpacing.s3),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '拍照识谱',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      Text(
                        '实体棋盘 · 编号棋谱图',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.82,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveAnalysisCard extends StatelessWidget {
  const _ActiveAnalysisCard({required this.dense, required this.onTap});

  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const value = 142 / 236;
    return SurfacePanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GoRadii.card),
        child: Padding(
          padding: EdgeInsets.all(dense ? GoSpacing.s3 : GoSpacing.s4),
          child: Row(
            children: <Widget>[
              Semantics(
                label: '分析进度百分之六十',
                excludeSemantics: true,
                child: SizedBox.square(
                  dimension: dense ? 44 : 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      const CircularProgressIndicator(
                        value: value,
                        strokeWidth: 4,
                      ),
                      Text('60%', style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: GoSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('棋路未央  vs  山海一局', style: theme.textTheme.titleSmall),
                    const SizedBox(height: GoSpacing.s1),
                    Text(
                      '标准分析 · 142 / 236 手',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _KifuTile extends StatelessWidget {
  const _KifuTile({
    required this.dense,
    required this.item,
    required this.onTap,
  });

  final bool dense;
  final KifuSummaryModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = item.analysisProgress != null;
    return Semantics(
      button: true,
      label:
          '${item.blackPlayer} 对 ${item.whitePlayer}，${item.result}，${item.moveCount}手，${item.status}',
      child: SurfacePanel(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(GoRadii.card),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(dense ? GoSpacing.s3 : GoSpacing.s4),
            child: Row(
              children: <Widget>[
                _StoneAvatar(
                  black: true,
                  label: item.blackPlayer.characters.first,
                  size: dense ? 38 : 42,
                ),
                const SizedBox(width: GoSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${item.blackPlayer}  ·  ${item.whitePlayer}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: GoSpacing.s1),
                      Text(
                        '${item.result} · ${item.moveCount}手 · ${item.playedAt}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GoSpacing.s2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      item.status,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: active
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: GoSpacing.s2),
                    const Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoneAvatar extends StatelessWidget {
  const _StoneAvatar({
    required this.black,
    required this.label,
    required this.size,
  });

  final bool black;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.goColors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: black ? colors.blackStone : colors.whiteStone,
          shape: BoxShape.circle,
          border: Border.all(color: colors.whiteStoneOutline),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: black ? colors.whiteStone : colors.blackStone,
          ),
        ),
      ),
    );
  }
}
