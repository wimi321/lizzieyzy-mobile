import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';
import '../../fixtures/ui_fixtures.dart';
import 'review_widgets.dart';

class TabletReviewScreen extends StatefulWidget {
  const TabletReviewScreen({super.key});

  @override
  State<TabletReviewScreen> createState() => _TabletReviewScreenState();
}

class _TabletReviewScreenState extends State<TabletReviewScreen> {
  ReviewSection _section = ReviewSection.keyMoves;
  var _currentMove = 87;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: LizzieTheme.dark(),
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Column(
                children: <Widget>[
                  FeatureTopBar(
                    title: '山海一局  vs  清风入弦',
                    subtitle: '中国规则 · 白胜3.5目 · 236手',
                    leading: const BackCircleButton(),
                    actions: <Widget>[
                      const MetricPill(
                        label: '标准复盘',
                        tone: MetricTone.primary,
                        compact: true,
                      ),
                      IconButton(
                        tooltip: '导出复盘',
                        onPressed: () {},
                        icon: const Icon(Icons.ios_share_outlined),
                      ),
                    ],
                    dark: true,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 760) {
                          return const Center(child: Text('请横置平板以使用双栏复盘'));
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  GoSpacing.s4,
                                  GoSpacing.s2,
                                  GoSpacing.s3,
                                  GoSpacing.s4,
                                ),
                                child: Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: Center(
                                        child: GoBoard(
                                          stones: UiFixtures.stones,
                                          candidates: UiFixtures.candidates,
                                          lastMove: const BoardPoint(15, 3),
                                          selectedPoint: const BoardPoint(
                                            16,
                                            5,
                                          ),
                                          showCoordinates: true,
                                          semanticLabel:
                                              '平板复盘棋盘，第$_currentMove手，显示三个候选点',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: GoSpacing.s2),
                                    Wrap(
                                      spacing: GoSpacing.s2,
                                      runSpacing: GoSpacing.s2,
                                      alignment: WrapAlignment.center,
                                      children: <Widget>[
                                        const MetricPill(
                                          label: '白方领先',
                                          value: '3.1目',
                                          tone: MetricTone.gold,
                                          compact: true,
                                        ),
                                        const MetricPill(
                                          label: '白胜率',
                                          value: '57.8%',
                                          compact: true,
                                        ),
                                        MetricPill(
                                          label: '当前',
                                          value: '第$_currentMove手',
                                          compact: true,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: GoSpacing.s1),
                                    MoveTimeline(
                                      currentMove: _currentMove,
                                      totalMoves: 236,
                                      keyMoves:
                                          UiFixtures.keyMove.timelineKeyMoves,
                                      onChanged: (move) =>
                                          setState(() => _currentMove = move),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            VerticalDivider(
                              width: 1,
                              color: context.goColors.softDivider,
                            ),
                            Expanded(
                              flex: 4,
                              child: ColoredBox(
                                color: Theme.of(context).colorScheme.surface,
                                child: ListView(
                                  key: const Key('tablet-review-inspector'),
                                  padding: const EdgeInsets.all(GoSpacing.s4),
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            '第87手',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.headlineSmall,
                                          ),
                                        ),
                                        const MetricPill(
                                          label: '-5.2目',
                                          tone: MetricTone.negative,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: GoSpacing.s3),
                                    ReviewSheet(
                                      selectedSection: _section,
                                      onSectionChanged: (section) =>
                                          setState(() => _section = section),
                                      showHandle: false,
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        0,
                                        GoSpacing.s4,
                                        0,
                                        0,
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: GoMotion.resolve(
                                          context,
                                          GoMotion.standard,
                                        ),
                                        child: _buildInspector(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInspector(BuildContext context) => switch (_section) {
    ReviewSection.keyMoves => KeyedSubtree(
      key: const ValueKey(ReviewSection.keyMoves),
      child: KeyMoveSummary(
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
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.variationComparison),
          ),
          const SizedBox(height: GoSpacing.s3),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.variationComparison),
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('打开变化比较'),
          ),
        ],
      ),
    ),
    ReviewSection.trend => const KeyedSubtree(
      key: ValueKey(ReviewSection.trend),
      child: ReviewTrendPanel(),
    ),
    ReviewSection.game => KeyedSubtree(
      key: const ValueKey(ReviewSection.game),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const PerformanceBand(
            lowerRank: '3级',
            upperRank: '1级',
            confidenceLabel: '中等置信度',
            effectiveDecisions: 86,
          ),
          const SizedBox(height: GoSpacing.s3),
          FilledButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.gamePerformance),
            child: const Text('查看本局指标'),
          ),
        ],
      ),
    ),
  };
}
