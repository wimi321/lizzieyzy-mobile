import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';
import '../../fixtures/ui_fixtures.dart';
import 'review_widgets.dart';
import 'tablet_review_screen.dart';

class KeyMoveReviewScreen extends StatefulWidget {
  const KeyMoveReviewScreen({super.key});

  @override
  State<KeyMoveReviewScreen> createState() => _KeyMoveReviewScreenState();
}

class _KeyMoveReviewScreenState extends State<KeyMoveReviewScreen> {
  ReviewSection _section = ReviewSection.keyMoves;
  var _currentMove = UiFixtures.keyMove.moveNumber;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 840) {
      return const TabletReviewScreen();
    }
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: '山海一局  vs  清风入弦',
            subtitle: '中国规则 · 白胜3.5目 · 236手',
            leading: const BackCircleButton(),
            actions: <Widget>[
              IconButton(
                tooltip: '导出复盘',
                onPressed: () {},
                icon: const Icon(Icons.ios_share_outlined),
              ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              key: const Key('mobile-review-scroll'),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const horizontalPadding = GoSpacing.s3;
                  final contentWidth =
                      constraints.maxWidth - horizontalPadding * 2;
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final largeText = textScale > 1.45;
                  final reservedHeight = largeText
                      ? 400.0
                      : 330 + math.max<double>(0, textScale - 1) * 24;
                  final boardSide = math.min<double>(
                    contentWidth,
                    math.max<double>(
                      largeText ? 200 : 208,
                      constraints.maxHeight - reservedHeight,
                    ),
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
                        if (!largeText)
                          Row(
                            children: <Widget>[
                              const _PlayerScore(
                                stoneColor: StoneColor.black,
                                player: '山海一局',
                                rank: '2级',
                              ),
                              Expanded(
                                child: Text(
                                  '第 $_currentMove 手',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelLarge,
                                ),
                              ),
                              const _PlayerScore(
                                stoneColor: StoneColor.white,
                                player: '清风入弦',
                                rank: '1级',
                                alignEnd: true,
                              ),
                            ],
                          ),
                        if (!largeText) const SizedBox(height: GoSpacing.s1),
                        SizedBox.square(
                          dimension: boardSide,
                          child: GoBoard(
                            stones: UiFixtures.stones,
                            candidates: UiFixtures.candidates,
                            lastMove: const BoardPoint(15, 3),
                            selectedPoint: const BoardPoint(16, 5),
                            semanticLabel: '第$_currentMove手复盘棋盘，显示三个候选点',
                            showCoordinates: true,
                          ),
                        ),
                        const SizedBox(height: GoSpacing.s1),
                        if (largeText)
                          _LargeTextReviewMetricStrip(currentMove: _currentMove)
                        else
                          _ReviewMetricStrip(currentMove: _currentMove),
                        MoveTimeline(
                          currentMove: _currentMove,
                          totalMoves: 236,
                          keyMoves: UiFixtures.keyMove.timelineKeyMoves,
                          onChanged: (move) =>
                              setState(() => _currentMove = move),
                        ),
                        const SizedBox(height: GoSpacing.s1),
                        _PhoneReviewInspector(
                          selectedSection: _section,
                          onSectionChanged: (section) =>
                              setState(() => _section = section),
                          child: AnimatedSwitcher(
                            duration: GoMotion.resolve(
                              context,
                              GoMotion.standard,
                            ),
                            child: _buildSection(context, largeText: largeText),
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

  Widget _buildSection(BuildContext context, {required bool largeText}) {
    if (largeText) {
      return switch (_section) {
        ReviewSection.keyMoves => _LargeTextInspectorCard(
          key: const ValueKey(ReviewSection.keyMoves),
          text: '第87手 · Q16 → R14\n目损 -5.2目 · 胜率 -18.4pp',
          semanticLabel: '第87手，实战Q16，最佳R14，目差损失5.2目，胜率下降18.4个百分点',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.variationComparison),
        ),
        ReviewSection.variations => _LargeTextInspectorCard(
          key: const ValueKey(ReviewSection.variations),
          text: '最佳 R14 · 57.8%\n+3.1目 · 12,840访问',
          semanticLabel: '最佳候选R14，胜率57.8%，领先3.1目，12840访问',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.variationComparison),
        ),
        ReviewSection.trend => const _LargeTextInspectorCard(
          key: ValueKey(ReviewSection.trend),
          text: '目差走势\n黑 +2.1目 → 白 +3.1目',
          semanticLabel: '目差走势，第87手前黑方领先2.1目，之后白方领先3.1目',
        ),
        ReviewSection.game => _LargeTextInspectorCard(
          key: const ValueKey(ReviewSection.game),
          text: '本局发挥 3级–1级\n80%区间 · 86个有效决策',
          semanticLabel: '本局发挥3级到1级，80%区间，中等置信度，86个有效决策',
          onTap: () => Navigator.pushNamed(context, AppRoutes.gamePerformance),
        ),
      };
    }
    return switch (_section) {
      ReviewSection.keyMoves => KeyedSubtree(
        key: const ValueKey(ReviewSection.keyMoves),
        child: KeyMoveSummary(
          compact: true,
          onOpenVariation: () =>
              Navigator.pushNamed(context, AppRoutes.variationComparison),
        ),
      ),
      ReviewSection.variations => KeyedSubtree(
        key: const ValueKey(ReviewSection.variations),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CandidateComparison(
              compact: true,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.variationComparison),
            ),
          ],
        ),
      ),
      ReviewSection.trend => const KeyedSubtree(
        key: ValueKey(ReviewSection.trend),
        child: ReviewTrendPanel(compact: true),
      ),
      ReviewSection.game => KeyedSubtree(
        key: const ValueKey(ReviewSection.game),
        child: _ReviewDestinationCard(
          title: '本局发挥 3级–1级',
          detail: '80%区间 · 中等置信度 · 86个有效决策',
          actionLabel: '查看本局指标',
          onTap: () => Navigator.pushNamed(context, AppRoutes.gamePerformance),
        ),
      ),
    };
  }
}

class _LargeTextReviewMetricStrip extends StatelessWidget {
  const _LargeTextReviewMetricStrip({required this.currentMove});

  final int currentMove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '第$currentMove手，白方领先3.1目，白方胜率57.8%',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: GoSizes.minimumTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: GoSpacing.s2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(GoRadii.card),
          border: Border.all(color: context.goColors.softDivider),
        ),
        alignment: Alignment.center,
        child: Text(
          '第$currentMove手 · 白 +3.1目 · 57.8%',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _LargeTextInspectorCard extends StatelessWidget {
  const _LargeTextInspectorCard({
    required this.text,
    required this.semanticLabel,
    super.key,
    this.onTap,
  });

  final String text;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: SurfacePanel(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GoRadii.card),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: GoSizes.minimumTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GoSpacing.s2,
                vertical: GoSpacing.s1,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.chevron_right_rounded, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewMetricStrip extends StatelessWidget {
  const _ReviewMetricStrip({required this.currentMove});

  final int currentMove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: GoSpacing.s3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(GoRadii.card),
        border: Border.all(color: context.goColors.softDivider),
      ),
      child: Row(
        children: <Widget>[
          _InlineMetric(
            label: '白方领先',
            value: '3.1目',
            valueColor: context.goColors.dataGold,
          ),
          const _MetricDivider(),
          const _InlineMetric(label: '白胜率', value: '57.8%'),
          const _MetricDivider(),
          _InlineMetric(label: '当前', value: '第$currentMove手'),
        ],
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            value,
            maxLines: 1,
            style: theme.textTheme.labelLarge?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: VerticalDivider(color: context.goColors.softDivider),
    );
  }
}

class _PhoneReviewInspector extends StatelessWidget {
  const _PhoneReviewInspector({
    required this.selectedSection,
    required this.onSectionChanged,
    required this.child,
  });

  final ReviewSection selectedSection;
  final ValueChanged<ReviewSection> onSectionChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(GoRadii.sheet),
        border: Border.all(color: context.goColors.softDivider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              for (final section in ReviewSection.values)
                Expanded(
                  child: Semantics(
                    selected: section == selectedSection,
                    button: true,
                    label: '${section.label}标签页',
                    child: InkWell(
                      onTap: () => onSectionChanged(section),
                      borderRadius: BorderRadius.circular(GoRadii.small),
                      child: Container(
                        height: GoSizes.minimumTouchTarget,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: section == selectedSection
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Text(
                          section.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: section == selectedSection
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: section == selectedSection
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Divider(height: 1, color: context.goColors.softDivider),
          Padding(padding: const EdgeInsets.all(GoSpacing.s2), child: child),
        ],
      ),
    );
  }
}

class _ReviewDestinationCard extends StatelessWidget {
  const _ReviewDestinationCard({
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfacePanel(
      padding: EdgeInsets.zero,
      child: Semantics(
        button: true,
        label: '$title，$detail，$actionLabel',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GoRadii.card),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GoSpacing.s3),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(width: GoSpacing.s2),
                  Text(
                    actionLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerScore extends StatelessWidget {
  const _PlayerScore({
    required this.stoneColor,
    required this.player,
    required this.rank,
    this.alignEnd = false,
  });

  final StoneColor stoneColor;
  final String player;
  final String rank;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.goColors;
    final theme = Theme.of(context);
    final isBlack = stoneColor == StoneColor.black;
    return Semantics(
      label: '${isBlack ? '黑方' : '白方'}$player，$rank',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: alignEnd ? TextDirection.rtl : TextDirection.ltr,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isBlack ? colors.blackStone : colors.whiteStone,
              shape: BoxShape.circle,
              border: Border.all(color: colors.whiteStoneOutline),
              boxShadow: <BoxShadow>[
                BoxShadow(color: colors.shadow, blurRadius: 3),
              ],
            ),
          ),
          const SizedBox(width: GoSpacing.s2),
          Column(
            crossAxisAlignment: alignEnd
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: <Widget>[
              Text(player, style: theme.textTheme.labelMedium),
              Text(rank, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
