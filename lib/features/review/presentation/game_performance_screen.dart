import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../common/presentation/feature_chrome.dart';
import 'review_screen_data.dart';

enum _PerformancePane { core, phases, sample }

class GamePerformanceScreen extends StatefulWidget {
  const GamePerformanceScreen({super.key, this.review, this.report});

  final ReviewScreenData? review;
  final domain.GamePerformanceReport? report;

  @override
  State<GamePerformanceScreen> createState() => _GamePerformanceScreenState();
}

class _GamePerformanceScreenState extends State<GamePerformanceScreen> {
  _PerformancePane _pane = _PerformancePane.core;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final report = widget.report;
    if (review == null) return const _PerformanceUnavailable();
    if (report == null) return _UncalibratedPerformance(review: review);
    final l10n = context.l10n;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final largeText = textScale >= 1.6;
    final extraLargeText = textScale >= 2.5;
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: l10n.reviewGame,
            subtitle:
                '${review.record.metadata.blackPlayer ?? l10n.blackPlayerFallback} · '
                '${l10n.effectiveDecisionCount(report.effectiveDecisions)}',
            leading: const BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  GoSpacing.s3,
                  GoSpacing.s1,
                  GoSpacing.s3,
                  GoSpacing.s2,
                ),
                child: Column(
                  key: const Key('performance-single-viewport'),
                  children: <Widget>[
                    _PerformanceOverview(
                      report: report,
                      compact: largeText,
                      extraCompact: extraLargeText,
                    ),
                    const SizedBox(height: GoSpacing.s1),
                    _PerformanceBoundary(compact: extraLargeText),
                    const SizedBox(height: GoSpacing.s1),
                    if (largeText) ...<Widget>[
                      SegmentedButton<_PerformancePane>(
                        segments: <ButtonSegment<_PerformancePane>>[
                          ButtonSegment(
                            value: _PerformancePane.core,
                            label: Text(l10n.performancePaneCore),
                          ),
                          ButtonSegment(
                            value: _PerformancePane.phases,
                            label: Text(l10n.performancePanePhases),
                          ),
                          ButtonSegment(
                            value: _PerformancePane.sample,
                            label: Text(l10n.performancePaneSample),
                          ),
                        ],
                        selected: <_PerformancePane>{_pane},
                        onSelectionChanged: (value) =>
                            setState(() => _pane = value.single),
                      ),
                      const SizedBox(height: GoSpacing.s1),
                      Expanded(
                        child: _PerformancePaneCard(
                          pane: _pane,
                          report: report,
                          review: review,
                          extraCompact: extraLargeText,
                        ),
                      ),
                    ] else ...<Widget>[
                      _CoreMetrics(report: report),
                      const SizedBox(height: GoSpacing.s1),
                      Expanded(child: _PhaseMetrics(review: review)),
                      const SizedBox(height: GoSpacing.s1),
                      _SampleMetrics(report: report, review: review),
                    ],
                  ],
                ),
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
    required this.report,
    required this.compact,
    required this.extraCompact,
  });

  final domain.GamePerformanceReport report;
  final bool compact;
  final bool extraCompact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weak = _rankLabel(report.weakerBound, l10n);
    final strong = _rankLabel(report.strongerBound, l10n);
    final confidence = report.confidence == domain.PerformanceConfidence.medium
        ? l10n.confidenceMedium
        : l10n.confidenceLow;
    final interval = l10n.coverageInterval((report.coverage * 100).round());
    final decisions = l10n.effectiveDecisionCount(report.effectiveDecisions);
    return Semantics(
      label: l10n.performanceOverviewSemantics(
        weak,
        strong,
        interval,
        confidence,
        decisions,
      ),
      excludeSemantics: true,
      child: SurfacePanel(
        padding: EdgeInsets.all(compact ? GoSpacing.s2 : GoSpacing.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!extraCompact)
              Row(
                children: <Widget>[
                  Expanded(child: Text(l10n.gamePerformanceEstimate)),
                  MetricPill(
                    label: confidence,
                    tone: MetricTone.gold,
                    compact: true,
                  ),
                ],
              ),
            Text(
              '$weak–$strong',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (!extraCompact)
              Text(
                '$interval · $decisions',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceBoundary extends StatelessWidget {
  const _PerformanceBoundary({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.performanceBoundarySemantics,
    child: Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: GoSpacing.s2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(GoRadii.card),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline_rounded, size: 18),
          const SizedBox(width: GoSpacing.s2),
          Expanded(
            child: Text(
              compact
                  ? context.l10n.performanceBoundaryCompact
                  : context.l10n.performanceBoundaryFull,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CoreMetrics extends StatelessWidget {
  const _CoreMetrics({required this.report});

  final domain.GamePerformanceReport report;

  @override
  Widget build(BuildContext context) => SurfacePanel(
    padding: const EdgeInsets.all(GoSpacing.s2),
    child: Row(
      children: <Widget>[
        Expanded(
          child: LabeledValue(
            label: context.l10n.averagePointLoss,
            value: context.l10n.pointsValue(
              report.metrics.averagePointLoss.toStringAsFixed(1),
            ),
          ),
        ),
        Expanded(
          child: LabeledValue(
            label: 'Top-3',
            value: formatPercent(report.metrics.topThreeRate),
            alignEnd: true,
          ),
        ),
        Expanded(
          child: LabeledValue(
            label: context.l10n.severeMistake,
            value: formatPercent(report.metrics.severeMistakeRate),
            alignEnd: true,
            valueColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    ),
  );
}

class _PhaseMetrics extends StatelessWidget {
  const _PhaseMetrics({required this.review});

  final ReviewScreenData review;

  @override
  Widget build(BuildContext context) => SurfacePanel(
    padding: const EdgeInsets.all(GoSpacing.s2),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (final phase in review.report.metrics.phases)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: GoSpacing.s1),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 52,
                  child: Text(_phaseLabel(phase.phase, context.l10n)),
                ),
                Expanded(
                  child: ExcludeSemantics(
                    child: LinearProgressIndicator(
                      value: (1 - phase.averagePointLoss / 8).clamp(0, 1),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: GoSpacing.s2),
                Text(
                  context.l10n.pointsValue(
                    phase.averagePointLoss.toStringAsFixed(1),
                  ),
                ),
                const SizedBox(width: GoSpacing.s2),
                Text(context.l10n.moveCount(phase.decisionCount)),
              ],
            ),
          ),
      ],
    ),
  );
}

class _SampleMetrics extends StatelessWidget {
  const _SampleMetrics({required this.report, required this.review});

  final domain.GamePerformanceReport report;
  final ReviewScreenData review;

  @override
  Widget build(BuildContext context) => SurfacePanel(
    padding: const EdgeInsets.all(GoSpacing.s2),
    child: Row(
      children: <Widget>[
        const Icon(Icons.verified_outlined),
        const SizedBox(width: GoSpacing.s2),
        Expanded(
          child: Text(
            context.l10n.analysisSampleDetail(
              context.l10n.boardDimension(review.record.boardSize.dimension),
              review.analysis.settings.visitsPerMove,
              report.calibrationModelId,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _PerformancePaneCard extends StatelessWidget {
  const _PerformancePaneCard({
    required this.pane,
    required this.report,
    required this.review,
    required this.extraCompact,
  });

  final _PerformancePane pane;
  final domain.GamePerformanceReport report;
  final ReviewScreenData review;
  final bool extraCompact;

  @override
  Widget build(BuildContext context) => switch (pane) {
    _PerformancePane.core =>
      extraCompact
          ? _ExtraLargeCoreMetrics(report: report)
          : _CoreMetrics(report: report),
    _PerformancePane.phases =>
      extraCompact
          ? _ExtraLargePhaseMetrics(review: review)
          : _PhaseMetrics(review: review),
    _PerformancePane.sample => _SampleMetrics(report: report, review: review),
  };
}

class _ExtraLargeCoreMetrics extends StatelessWidget {
  const _ExtraLargeCoreMetrics({required this.report});

  final domain.GamePerformanceReport report;

  @override
  Widget build(BuildContext context) {
    final metrics = report.metrics;
    final values = <String>[
      '${context.l10n.averagePointLoss} '
          '${context.l10n.pointsValue(metrics.averagePointLoss.toStringAsFixed(1))}',
      'Top-3 ${formatPercent(metrics.topThreeRate)}',
      '${context.l10n.severeMistake} '
          '${formatPercent(metrics.severeMistakeRate)}',
    ];
    return Semantics(
      label: values.join('，'),
      excludeSemantics: true,
      child: SurfacePanel(
        padding: const EdgeInsets.all(GoSpacing.s2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final value in values)
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class _ExtraLargePhaseMetrics extends StatelessWidget {
  const _ExtraLargePhaseMetrics({required this.review});

  final ReviewScreenData review;

  @override
  Widget build(BuildContext context) {
    final phases = review.report.metrics.phases;
    final label = phases
        .map(
          (phase) => context.l10n.phaseMetricSemantics(
            _phaseLabel(phase.phase, context.l10n),
            context.l10n.pointsValue(phase.averagePointLoss.toStringAsFixed(1)),
            context.l10n.moveCount(phase.decisionCount),
          ),
        )
        .join('；');
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SurfacePanel(
        padding: const EdgeInsets.all(GoSpacing.s2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final phase in phases)
              Text(
                context.l10n.phaseMetric(
                  _phaseLabel(phase.phase, context.l10n),
                  context.l10n.pointsValue(
                    phase.averagePointLoss.toStringAsFixed(1),
                  ),
                  context.l10n.moveCount(phase.decisionCount),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class _UncalibratedPerformance extends StatelessWidget {
  const _UncalibratedPerformance({required this.review});

  final ReviewScreenData review;

  @override
  Widget build(BuildContext context) {
    final record = review.record;
    final decisions = record.moves.where((move) => !move.isPass).length;
    final checks = <(String, bool)>[
      (
        context.l10n.checkCompleteNineteen,
        record.boardSize == domain.BoardSize.nineteen &&
            record.initialPosition.stones.isEmpty,
      ),
      (context.l10n.checkMinimumDecisions, decisions >= 40),
      (
        context.l10n.checkStandardDeepAnalysis,
        review.analysis.settings.profile != domain.AnalysisProfile.quick,
      ),
      (context.l10n.checkProductionCalibration, false),
    ];
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: context.l10n.reviewGame,
            subtitle: context.l10n.performanceSubtitle,
            leading: const BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(GoSpacing.s4),
                child: SurfacePanel(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Icon(
                        Icons.model_training_outlined,
                        size: 44,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: GoSpacing.s2),
                      Text(
                        context.l10n.performanceUnavailableTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: GoSpacing.s1),
                      Text(
                        context.l10n.performanceUnavailableBody,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: GoSpacing.s3),
                      for (final check in checks)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: GoSpacing.s1,
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                check.$2
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: check.$2
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: GoSpacing.s2),
                              Expanded(child: Text(check.$1)),
                            ],
                          ),
                        ),
                      const SizedBox(height: GoSpacing.s2),
                      Text(
                        context.l10n.verifiableMetrics(
                          context.l10n.pointsValue(
                            review.report.metrics.averagePointLoss
                                .toStringAsFixed(1),
                          ),
                          formatPercent(review.report.metrics.topThreeRate),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceUnavailable extends StatelessWidget {
  const _PerformanceUnavailable();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () => Navigator.maybePop(context),
        child: Text(context.l10n.noCompleteReviewReturn),
      ),
    ),
  );
}

String _rankLabel(domain.GoRank rank, AppLocalizations l10n) =>
    switch (rank.kind) {
      domain.RankKind.kyu => l10n.rankKyu(rank.value),
      domain.RankKind.dan => l10n.rankDan(rank.value),
    };

String _phaseLabel(domain.GamePhase phase, AppLocalizations l10n) =>
    switch (phase) {
      domain.GamePhase.opening => l10n.phaseOpening,
      domain.GamePhase.middleGame => l10n.phaseMiddleGame,
      domain.GamePhase.endgame => l10n.phaseEndgame,
    };
