import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';
import 'review_screen_data.dart';

/// Numeric analysis for a still-photo position.
///
/// A single photo has no trustworthy move sequence, so this screen has no
/// move timeline, key-move ranking, or performance interval by construction.
class PositionAnalysisScreen extends StatefulWidget {
  const PositionAnalysisScreen({super.key, this.data, this.snapshot});

  final PositionAnalysisData? data;
  final domain.PositionSnapshot? snapshot;

  @override
  State<PositionAnalysisScreen> createState() => _PositionAnalysisScreenState();
}

class _PositionAnalysisScreenState extends State<PositionAnalysisScreen> {
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = widget.data;
    if (data == null) {
      return _PositionAnalysisRequired(snapshot: widget.snapshot);
    }
    final candidates = data.root.candidates.take(3).toList(growable: false);
    if (_selected >= candidates.length) {
      _selected = 0;
    }
    final selected = candidates.isEmpty ? null : candidates[_selected];
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    final extraLargeText = MediaQuery.textScalerOf(context).scale(1) >= 2.5;
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: l10n.positionAnalysisTitle,
            subtitle: l10n.positionAnalysisSubtitle,
            leading: const BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final reserved = extraLargeText
                      ? 212.0
                      : largeText
                      ? 250.0
                      : 326.0;
                  final boardSide = math.min<double>(
                    constraints.maxWidth - GoSpacing.s6,
                    math.max<double>(120, constraints.maxHeight - reserved),
                  );
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      GoSpacing.s3,
                      GoSpacing.s1,
                      GoSpacing.s3,
                      GoSpacing.s2,
                    ),
                    child: Column(
                      key: const Key('position-analysis-viewport'),
                      children: <Widget>[
                        SizedBox.square(
                          dimension: boardSide,
                          child: GoBoard(
                            boardSize: data.snapshot.boardSize.dimension,
                            stones: data.stones,
                            candidates: data.candidatesFor(l10n),
                            selectedPoint:
                                selected == null || selected.move.isPass
                                ? null
                                : uiPoint(selected.move.point!),
                            semanticLabel: l10n.positionBoardSemantics(
                              _playerLabel(data.root.toPlay, l10n),
                              candidates.length,
                            ),
                            showCoordinates: true,
                          ),
                        ),
                        const SizedBox(height: GoSpacing.s1),
                        if (!largeText) const _StaticPositionBoundary(),
                        if (!largeText) const SizedBox(height: GoSpacing.s1),
                        if (candidates.isNotEmpty)
                          _CandidateSelector(
                            candidates: candidates,
                            boardSize: data.snapshot.boardSize,
                            selected: _selected,
                            compact: largeText,
                            onSelected: (index) =>
                                setState(() => _selected = index),
                          ),
                        const SizedBox(height: GoSpacing.s1),
                        Expanded(
                          child: selected == null
                              ? const _NoCandidatePanel()
                              : _PositionCandidatePanel(
                                  candidate: selected,
                                  label: String.fromCharCode(65 + _selected),
                                  boardSize: data.snapshot.boardSize,
                                  toPlay: data.root.toPlay,
                                  compact: largeText,
                                  extraCompact: extraLargeText,
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
}

class _StaticPositionBoundary extends StatelessWidget {
  const _StaticPositionBoundary();

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.staticPositionBoundarySemantics,
    child: SurfacePanel(
      padding: const EdgeInsets.symmetric(
        horizontal: GoSpacing.s2,
        vertical: GoSpacing.s1,
      ),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: GoSpacing.s2),
          Expanded(
            child: Text(
              context.l10n.staticPositionBoundaryBody,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CandidateSelector extends StatelessWidget {
  const _CandidateSelector({
    required this.candidates,
    required this.boardSize,
    required this.selected,
    required this.compact,
    required this.onSelected,
  });

  final List<domain.Candidate> candidates;
  final domain.BoardSize boardSize;
  final int selected;
  final bool compact;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      for (var index = 0; index < candidates.length; index++)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == candidates.length - 1 ? 0 : GoSpacing.s2,
            ),
            child: Semantics(
              button: true,
              selected: index == selected,
              label: context.l10n.candidateChoiceSemantics(
                String.fromCharCode(65 + index),
                formatMove(candidates[index].move, boardSize, context.l10n),
                formatScore(candidates[index].scoreLead, context.l10n),
              ),
              excludeSemantics: true,
              child: ChoiceChip(
                selected: index == selected,
                showCheckmark: false,
                onSelected: (_) => onSelected(index),
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    compact
                        ? String.fromCharCode(65 + index)
                        : '${String.fromCharCode(65 + index)} · '
                              '${formatMove(candidates[index].move, boardSize, context.l10n)}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _PositionCandidatePanel extends StatelessWidget {
  const _PositionCandidatePanel({
    required this.candidate,
    required this.label,
    required this.boardSize,
    required this.toPlay,
    required this.compact,
    required this.extraCompact,
  });

  final domain.Candidate candidate;
  final String label;
  final domain.BoardSize boardSize;
  final domain.StoneColor toPlay;
  final bool compact;
  final bool extraCompact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final move = formatMove(candidate.move, boardSize, l10n);
    final pv = candidate.principalVariation
        .take(extraCompact ? 3 : 6)
        .map((move) => formatMove(move, boardSize, l10n))
        .join('  ');
    final semantics = l10n.candidatePanelSemantics(
      label,
      move,
      _playerLabel(toPlay, l10n),
      formatPercent(candidate.winRate),
      formatScore(candidate.scoreLead, l10n),
      l10n.visitsValue(formatVisits(candidate.visits)),
      pv,
    );
    return Semantics(
      container: true,
      label: semantics,
      excludeSemantics: true,
      child: SurfacePanel(
        padding: EdgeInsets.all(compact ? GoSpacing.s2 : GoSpacing.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                CandidateMarker(label: label, selected: true),
                const SizedBox(width: GoSpacing.s2),
                Expanded(
                  child: Text(
                    move,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (label == 'A' && !extraCompact)
                  MetricPill(
                    label: l10n.bestCandidate,
                    tone: MetricTone.primary,
                    compact: true,
                  ),
              ],
            ),
            const SizedBox(height: GoSpacing.s1),
            if (extraCompact)
              Text(
                l10n.candidateMetricDetail(
                  formatPercent(candidate.winRate),
                  formatScore(candidate.scoreLead, l10n),
                  l10n.visitsValue(formatVisits(candidate.visits)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              Wrap(
                spacing: GoSpacing.s1,
                runSpacing: GoSpacing.s1,
                children: <Widget>[
                  MetricPill(
                    label: l10n.playerWinRate(_playerLabel(toPlay, l10n)),
                    value: formatPercent(candidate.winRate),
                  ),
                  MetricPill(
                    label: l10n.blackScoreLeadLabel,
                    value: formatScore(candidate.scoreLead, l10n),
                    tone: MetricTone.gold,
                  ),
                  MetricPill(
                    label: l10n.visitsLabel,
                    value: formatVisits(candidate.visits),
                  ),
                ],
              ),
            const Spacer(),
            Text(
              pv.isEmpty
                  ? l10n.principalVariationNone
                  : l10n.principalVariationValue(pv),
              maxLines: extraCompact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoCandidatePanel extends StatelessWidget {
  const _NoCandidatePanel();

  @override
  Widget build(BuildContext context) => SurfacePanel(
    child: Center(child: Text(context.l10n.noPlayableCandidate)),
  );
}

class _PositionAnalysisRequired extends StatelessWidget {
  const _PositionAnalysisRequired({this.snapshot});

  final domain.PositionSnapshot? snapshot;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        FeatureTopBar(
          title: context.l10n.positionAnalysisTitle,
          subtitle: context.l10n.positionAnalysisSubtitle,
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
                        Icons.analytics_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: GoSpacing.s3),
                      Text(
                        snapshot == null
                            ? context.l10n.positionDataExpired
                            : context.l10n.positionNotAnalyzed,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: GoSpacing.s2),
                      Text(context.l10n.realKatagoOnly),
                      const SizedBox(height: GoSpacing.s4),
                      FilledButton(
                        onPressed: snapshot == null
                            ? () => Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.root,
                                (_) => false,
                              )
                            : () => Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.analysisProgress,
                                arguments: snapshot,
                              ),
                        child: Text(
                          snapshot == null
                              ? context.l10n.returnToKifu
                              : context.l10n.startAnalysis,
                        ),
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

String _playerLabel(domain.StoneColor color, AppLocalizations l10n) =>
    color == domain.StoneColor.black
    ? l10n.blackPlayerFallback
    : l10n.whitePlayerFallback;
