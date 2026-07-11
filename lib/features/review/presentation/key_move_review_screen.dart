import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/analysis/analysis.dart';
import 'package:lizzieyzy_mobile/application/kifu_export_scope.dart';
import 'package:lizzieyzy_mobile/application/kifu_export_service.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';
import '../../common/presentation/share_anchor.dart';
import 'review_screen_data.dart';
import 'review_widgets.dart';
import 'tablet_review_screen.dart';

class KeyMoveReviewScreen extends StatefulWidget {
  const KeyMoveReviewScreen({super.key, this.data});

  final ReviewScreenData? data;

  @override
  State<KeyMoveReviewScreen> createState() => _KeyMoveReviewScreenState();
}

class _KeyMoveReviewScreenState extends State<KeyMoveReviewScreen> {
  ReviewSection _section = ReviewSection.keyMoves;
  int? _currentMove;
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = widget.data ?? _dataFromActiveSession(context);
    if (data == null) return const _ReviewDataRequired();
    final initialMove = data.primaryMoment?.moveNumber ?? 1;
    final currentMove = (_currentMove ?? initialMove).clamp(1, data.totalMoves);
    if (MediaQuery.sizeOf(context).width >= 840) {
      return TabletReviewScreen(data: data, initialMove: currentMove);
    }
    final before = data.beforeMove(currentMove);
    final candidates = data.candidatesBeforeMove(currentMove, l10n);
    final bestPoint = before.candidates.firstOrNull?.move.point;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: data.localizedTitle(l10n),
            subtitle: data.localizedSubtitle(l10n),
            leading: const BackCircleButton(),
            actions: <Widget>[
              Builder(
                builder: (buttonContext) => IconButton(
                  tooltip: l10n.shareKifu,
                  onPressed: _sharing
                      ? null
                      : () => _share(buttonContext, data.record),
                  icon: _sharing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_outlined),
                ),
              ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const horizontalPadding = GoSpacing.s3;
                  final reserved = largeText ? 354.0 : 318.0;
                  final boardSide = math.min<double>(
                    constraints.maxWidth - horizontalPadding * 2,
                    math.max<double>(132, constraints.maxHeight - reserved),
                  );
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      horizontalPadding,
                      GoSpacing.s1,
                      horizontalPadding,
                      GoSpacing.s1,
                    ),
                    child: Column(
                      key: const Key('mobile-review-viewport'),
                      children: <Widget>[
                        SizedBox.square(
                          dimension: boardSide,
                          child: GoBoard(
                            boardSize: data.record.boardSize.dimension,
                            stones: data.stonesBeforeMove(currentMove),
                            candidates: candidates,
                            lastMove: _previousMovePoint(data, currentMove),
                            selectedPoint: bestPoint == null
                                ? null
                                : uiPoint(bestPoint),
                            semanticLabel: l10n.reviewBoardSemantics(
                              currentMove,
                              candidates.length,
                            ),
                            showCoordinates: true,
                          ),
                        ),
                        const SizedBox(height: GoSpacing.s1),
                        _PositionMetricStrip(
                          moveNumber: currentMove,
                          scoreLead: before.scoreLead,
                          blackWinRate: before.blackWinRate,
                          compact: largeText,
                        ),
                        MoveTimeline(
                          currentMove: currentMove,
                          minimumMove: 1,
                          totalMoves: data.totalMoves,
                          keyMoves: data.keyMoveNumbers,
                          onChanged: (move) =>
                              setState(() => _currentMove = move),
                        ),
                        const SizedBox(height: GoSpacing.s1),
                        Expanded(
                          child: ReviewInspector(
                            data: data,
                            currentMove: currentMove,
                            section: _section,
                            compact: largeText,
                            onSectionChanged: (section) =>
                                setState(() => _section = section),
                            onOpenVariation: () => Navigator.pushNamed(
                              context,
                              AppRoutes.variationComparison,
                              arguments: ReviewMoveSelection(
                                data: data,
                                moveNumber: currentMove,
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
          ),
        ],
      ),
    );
  }

  Future<void> _share(
    BuildContext buttonContext,
    domain.VerifiedGameRecord record,
  ) async {
    final service = KifuExportScope.maybeOf(context);
    if (service == null) return;
    setState(() => _sharing = true);
    try {
      final outcome = await service.share(
        record,
        anchor: resolveShareAnchor(buttonContext),
      );
      if (!mounted || outcome == KifuShareOutcome.dismissed) return;
      final message = outcome == KifuShareOutcome.success
          ? context.l10n.shareOpened
          : context.l10n.shareNoTarget;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on KifuExportException {
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

class _PositionMetricStrip extends StatelessWidget {
  const _PositionMetricStrip({
    required this.moveNumber,
    required this.scoreLead,
    required this.blackWinRate,
    required this.compact,
  });

  final int moveNumber;
  final double scoreLead;
  final double blackWinRate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final leader = scoreLead >= 0 ? l10n.blackStoneShort : l10n.whiteStoneShort;
    final winRate = scoreLead >= 0 ? blackWinRate : 1 - blackWinRate;
    return Semantics(
      label: l10n.positionMetricSemantics(
        moveNumber,
        leader,
        scoreLead.abs().toStringAsFixed(1),
        formatPercent(winRate),
      ),
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: GoSpacing.s2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(GoRadii.card),
          border: Border.all(color: context.goColors.softDivider),
        ),
        alignment: Alignment.center,
        child: Text(
          compact
              ? l10n.positionMetricCompact(
                  moveNumber,
                  leader,
                  scoreLead.abs().toStringAsFixed(1),
                  formatPercent(winRate),
                )
              : l10n.positionMetricFull(
                  moveNumber,
                  leader,
                  scoreLead.abs().toStringAsFixed(1),
                  formatPercent(winRate),
                ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

class _ReviewDataRequired extends StatelessWidget {
  const _ReviewDataRequired();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        FeatureTopBar(
          title: context.l10n.reviewTitle,
          subtitle: context.l10n.completeAnalysisResults,
          leading: const BackCircleButton(),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(GoSpacing.s4),
                child: SurfacePanel(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.query_stats_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: GoSpacing.s3),
                      Text(
                        context.l10n.noCompletedReview,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: GoSpacing.s2),
                      Text(context.l10n.verifiedGlobalAnalysisOnly),
                      const SizedBox(height: GoSpacing.s4),
                      FilledButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.root,
                          (_) => false,
                        ),
                        child: Text(context.l10n.returnToKifu),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

ReviewScreenData? _dataFromActiveSession(BuildContext context) {
  final document = KifuWorkspace.maybeOf(context)?.notifier?.selected;
  if (document is! domain.VerifiedGameRecord) return null;
  final state = AnalysisCoordinatorScope.maybeOf(
    context,
  )?.sessionForDocument(document)?.state;
  final bundle = state?.bundle;
  final report = state?.reviewReport;
  if (bundle == null || report == null) return null;
  return ReviewScreenData(
    record: document,
    analysis: bundle,
    report: report,
    performanceReport: state?.performanceReport,
  );
}

BoardPoint? _previousMovePoint(ReviewScreenData data, int moveNumber) {
  if (moveNumber <= 1) return null;
  final point = data.record.moves[moveNumber - 2].point;
  return point == null ? null : uiPoint(point);
}
