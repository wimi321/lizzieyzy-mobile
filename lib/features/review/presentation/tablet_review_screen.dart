import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizzieyzy_mobile/application/kifu_export_scope.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' show AnalysisProfile;
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';
import '../../common/presentation/share_anchor.dart';
import 'review_screen_data.dart';
import 'review_widgets.dart';

class TabletReviewScreen extends StatefulWidget {
  const TabletReviewScreen({super.key, this.data, this.initialMove});

  final ReviewScreenData? data;
  final int? initialMove;

  @override
  State<TabletReviewScreen> createState() => _TabletReviewScreenState();
}

class _TabletReviewScreenState extends State<TabletReviewScreen> {
  ReviewSection _section = ReviewSection.keyMoves;
  int? _currentMove;
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = widget.data;
    if (data == null) return const _TabletReviewUnavailable();
    final move =
        (_currentMove ??
                widget.initialMove ??
                data.primaryMoment?.moveNumber ??
                1)
            .clamp(1, data.totalMoves);
    final before = data.beforeMove(move);
    final bestPoint = before.candidates.firstOrNull?.move.point;
    final inheritedFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final darkTheme = LizzieTheme.dark();
    final resolvedDarkTheme = inheritedFamily == null
        ? darkTheme
        : darkTheme.copyWith(
            textTheme: darkTheme.textTheme.apply(fontFamily: inheritedFamily),
            primaryTextTheme: darkTheme.primaryTextTheme.apply(
              fontFamily: inheritedFamily,
            ),
          );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: resolvedDarkTheme,
        child: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: <Widget>[
                FeatureTopBar(
                  title: data.localizedTitle(l10n),
                  subtitle: data.localizedSubtitle(l10n),
                  leading: const BackCircleButton(),
                  actions: <Widget>[
                    MetricPill(
                      label: _profileLabel(data, l10n),
                      tone: MetricTone.primary,
                      compact: true,
                    ),
                    Builder(
                      builder: (buttonContext) => IconButton(
                        tooltip: l10n.shareKifu,
                        onPressed: _sharing
                            ? null
                            : () => _share(buttonContext, data),
                        icon: _sharing
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.ios_share_outlined),
                      ),
                    ),
                  ],
                  dark: true,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 760) {
                        return Center(child: Text(l10n.tabletLandscapeHint));
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                          GoSpacing.s4,
                          GoSpacing.s2,
                          GoSpacing.s4,
                          GoSpacing.s3,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: <Widget>[
                                  Expanded(
                                    child: Center(
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: GoBoard(
                                          boardSize:
                                              data.record.boardSize.dimension,
                                          stones: data.stonesBeforeMove(move),
                                          candidates: data.candidatesBeforeMove(
                                            move,
                                            l10n,
                                          ),
                                          lastMove: _previousPoint(data, move),
                                          selectedPoint: bestPoint == null
                                              ? null
                                              : uiPoint(bestPoint),
                                          showCoordinates: true,
                                          semanticLabel: l10n
                                              .tabletBoardSemantics(
                                                move,
                                                before.candidates.length,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: GoSpacing.s2),
                                  _TabletMetricRow(data: data, move: move),
                                  const SizedBox(height: GoSpacing.s1),
                                  MoveTimeline(
                                    currentMove: move,
                                    minimumMove: 1,
                                    totalMoves: data.totalMoves,
                                    keyMoves: data.keyMoveNumbers,
                                    onChanged: (value) =>
                                        setState(() => _currentMove = value),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: GoSpacing.s4),
                            Expanded(
                              flex: 4,
                              child: ReviewInspector(
                                key: const Key('tablet-review-inspector'),
                                data: data,
                                currentMove: move,
                                section: _section,
                                onSectionChanged: (value) =>
                                    setState(() => _section = value),
                                onOpenVariation: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.variationComparison,
                                  arguments: ReviewMoveSelection(
                                    data: data,
                                    moveNumber: move,
                                  ),
                                ),
                                onOpenPerformance: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.gamePerformance,
                                  arguments: data,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _share(BuildContext buttonContext, ReviewScreenData data) async {
    final service = KifuExportScope.maybeOf(context);
    if (service == null) return;
    setState(() => _sharing = true);
    try {
      await service.share(
        data.record,
        anchor: resolveShareAnchor(buttonContext),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.shareUnavailable)));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class _TabletMetricRow extends StatelessWidget {
  const _TabletMetricRow({required this.data, required this.move});

  final ReviewScreenData data;
  final int move;

  @override
  Widget build(BuildContext context) {
    final before = data.beforeMove(move);
    final after = data.afterMove(move);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        MetricPill(
          label: context.l10n.moveOrdinal(move),
          tone: MetricTone.primary,
        ),
        const SizedBox(width: GoSpacing.s2),
        MetricPill(
          label: context.l10n.blackScoreLeadLabel,
          value: formatScore(before.scoreLead, context.l10n),
        ),
        const SizedBox(width: GoSpacing.s2),
        MetricPill(
          label: context.l10n.pointLossLabel,
          value: formatPointLoss(after.playedMovePointLoss, context.l10n),
          tone: (after.playedMovePointLoss ?? 0) >= 3
              ? MetricTone.negative
              : MetricTone.gold,
        ),
      ],
    );
  }
}

class _TabletReviewUnavailable extends StatelessWidget {
  const _TabletReviewUnavailable();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.root,
          (_) => false,
        ),
        child: Text(context.l10n.noReviewDataReturn),
      ),
    ),
  );
}

BoardPoint? _previousPoint(ReviewScreenData data, int move) {
  if (move <= 1) return null;
  final point = data.record.moves[move - 2].point;
  return point == null ? null : uiPoint(point);
}

String _profileLabel(ReviewScreenData data, AppLocalizations l10n) =>
    switch (data.analysis.settings.profile) {
      AnalysisProfile.quick => l10n.quickReview,
      AnalysisProfile.standard => l10n.standardReview,
      AnalysisProfile.deep => l10n.deepReview,
    };
