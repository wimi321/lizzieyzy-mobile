import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../common/presentation/feature_chrome.dart';
import 'review_screen_data.dart';

class VariationComparisonScreen extends StatefulWidget {
  const VariationComparisonScreen({super.key, this.selection});

  final ReviewMoveSelection? selection;

  @override
  State<VariationComparisonScreen> createState() =>
      _VariationComparisonScreenState();
}

class _VariationComparisonScreenState extends State<VariationComparisonScreen> {
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selection = widget.selection;
    if (selection == null) return const _VariationUnavailable();
    final data = selection.data;
    final moveNumber = selection.moveNumber.clamp(1, data.totalMoves);
    final before = data.beforeMove(moveNumber);
    final candidates = before.candidates.take(3).toList(growable: false);
    if (_selected >= candidates.length) _selected = 0;
    final candidate = candidates.isEmpty ? null : candidates[_selected];
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    final extraLarge = MediaQuery.textScalerOf(context).scale(1) >= 2.5;
    final variationStones = candidate == null
        ? data.stonesBeforeMove(moveNumber)
        : _variationStones(data, moveNumber, candidate);
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: l10n.variationComparisonTitle,
            subtitle: l10n.variationComparisonSubtitle(moveNumber),
            leading: const BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final reserved = extraLarge
                      ? 360.0
                      : largeText
                      ? 340.0
                      : 350.0;
                  final maximumBoardWidth =
                      constraints.maxWidth *
                      (extraLarge
                          ? 0.64
                          : largeText
                          ? 0.78
                          : 1);
                  final boardSide = math.min<double>(
                    maximumBoardWidth - GoSpacing.s6,
                    math.max<double>(128, constraints.maxHeight - reserved),
                  );
                  return Padding(
                    key: const Key('variation-comparison-viewport'),
                    padding: const EdgeInsets.fromLTRB(
                      GoSpacing.s3,
                      GoSpacing.s1,
                      GoSpacing.s3,
                      GoSpacing.s2,
                    ),
                    child: Column(
                      children: <Widget>[
                        SizedBox.square(
                          dimension: boardSide,
                          child: GoBoard(
                            boardSize: data.record.boardSize.dimension,
                            stones: variationStones,
                            candidates: data.candidatesBeforeMove(
                              moveNumber,
                              l10n,
                            ),
                            selectedPoint:
                                candidate == null || candidate.move.isPass
                                ? null
                                : uiPoint(candidate.move.point!),
                            showCoordinates: true,
                            semanticLabel: l10n.variationBoardSemantics(
                              moveNumber,
                              String.fromCharCode(65 + _selected),
                            ),
                          ),
                        ),
                        const SizedBox(height: GoSpacing.s1),
                        if (candidates.isNotEmpty)
                          _VariationSelector(
                            candidates: candidates,
                            boardSize: data.record.boardSize,
                            selected: _selected,
                            compact: largeText,
                            onSelected: (index) =>
                                setState(() => _selected = index),
                          ),
                        const SizedBox(height: GoSpacing.s1),
                        Expanded(
                          child: candidate == null
                              ? SurfacePanel(
                                  child: Center(
                                    child: Text(l10n.noComparableCandidate),
                                  ),
                                )
                              : _VariationDetails(
                                  data: data,
                                  moveNumber: moveNumber,
                                  candidate: candidate,
                                  label: String.fromCharCode(65 + _selected),
                                  compact: largeText,
                                  extraCompact: extraLarge,
                                ),
                        ),
                        const SizedBox(height: GoSpacing.s1),
                        SizedBox(
                          width: double.infinity,
                          child: extraLarge
                              ? Semantics(
                                  button: true,
                                  label: l10n.returnToMainLine(moveNumber),
                                  excludeSemantics: true,
                                  child: FilledButton(
                                    onPressed: () =>
                                        Navigator.maybePop(context),
                                    child: Text(
                                      l10n.returnToMainLine(moveNumber),
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(height: 1),
                                    ),
                                  ),
                                )
                              : FilledButton.icon(
                                  onPressed: () => Navigator.maybePop(context),
                                  icon: const Icon(Icons.fork_right_rounded),
                                  label: Text(
                                    l10n.returnToMainLine(moveNumber),
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
}

class _VariationSelector extends StatelessWidget {
  const _VariationSelector({
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
              selected: selected == index,
              label: context.l10n.candidateChoiceSemantics(
                String.fromCharCode(65 + index),
                formatMove(candidates[index].move, boardSize, context.l10n),
                formatScore(candidates[index].scoreLead, context.l10n),
              ),
              excludeSemantics: true,
              child: ChoiceChip(
                selected: selected == index,
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
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _VariationDetails extends StatelessWidget {
  const _VariationDetails({
    required this.data,
    required this.moveNumber,
    required this.candidate,
    required this.label,
    required this.compact,
    required this.extraCompact,
  });

  final ReviewScreenData data;
  final int moveNumber;
  final domain.Candidate candidate;
  final String label;
  final bool compact;
  final bool extraCompact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final played = data.record.moves[moveNumber - 1];
    final after = data.afterMove(moveNumber);
    final displayedPv = candidate.principalVariation
        .take(extraCompact ? 3 : 5)
        .toList(growable: false);
    final pv = displayedPv
        .map((move) => formatMove(move, data.record.boardSize, l10n))
        .join('  ');
    return Semantics(
      container: true,
      label: l10n.variationDetailsSemantics(
        label,
        formatMove(candidate.move, data.record.boardSize, l10n),
        formatPercent(candidate.winRate),
        formatScore(candidate.scoreLead, l10n),
        l10n.visitsValue(formatVisits(candidate.visits)),
        pv,
        formatMove(played, data.record.boardSize, l10n),
        formatPointLoss(after.playedMovePointLoss, l10n),
      ),
      excludeSemantics: true,
      child: SurfacePanel(
        padding: const EdgeInsets.all(GoSpacing.s2),
        child: extraCompact
            ? Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: GoSpacing.s1,
                  runSpacing: 2,
                  children: <Widget>[
                    Text(
                      '$label · '
                      '${formatMove(candidate.move, data.record.boardSize, l10n)}',
                      key: const Key('variation-primary-metrics'),
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(height: 1),
                    ),
                    Text(
                      '${formatPercent(candidate.winRate)} · '
                      '${formatScore(candidate.scoreLead, l10n)} · '
                      '#${formatVisits(candidate.visits)}',
                      key: const Key('variation-secondary-metrics'),
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(height: 1),
                    ),
                    Text(
                      pv.isEmpty ? l10n.principalVariationNone : 'PV  $pv',
                      key: const Key('variation-pv'),
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(height: 1),
                    ),
                    Text(
                      '${formatMove(played, data.record.boardSize, l10n)} · '
                      '${formatPointLoss(after.playedMovePointLoss, l10n)}',
                      key: const Key('variation-played-loss'),
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(height: 1),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CandidateMarker(label: label, selected: true),
                      const SizedBox(width: GoSpacing.s2),
                      Expanded(
                        child: Text(
                          formatMove(
                            candidate.move,
                            data.record.boardSize,
                            l10n,
                          ),
                          maxLines: 1,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      MetricPill(
                        label: _selectedLabel(
                          candidate,
                          data,
                          moveNumber,
                          l10n,
                        ),
                        compact: true,
                        tone: MetricTone.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: GoSpacing.s1),
                  if (compact) ...<Widget>[
                    Text(
                      l10n.candidateMetricDetail(
                        formatPercent(candidate.winRate),
                        formatScore(candidate.scoreLead, l10n),
                        l10n.visitsValue(formatVisits(candidate.visits)),
                      ),
                      key: const Key('variation-primary-metrics'),
                      maxLines: 2,
                    ),
                    const Spacer(),
                    Text(
                      pv.isEmpty ? l10n.principalVariationNone : 'PV  $pv',
                      key: const Key('variation-pv'),
                      maxLines: 2,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: GoSpacing.s1),
                    Text(
                      l10n.playedMoveWithLoss(
                        formatMove(played, data.record.boardSize, l10n),
                        formatPointLoss(after.playedMovePointLoss, l10n),
                      ),
                      key: const Key('variation-played-loss'),
                      maxLines: 2,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else ...<Widget>[
                    const SizedBox(height: GoSpacing.s1),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: LabeledValue(
                            label: l10n.winRateLabel,
                            value: formatPercent(candidate.winRate),
                          ),
                        ),
                        Expanded(
                          child: LabeledValue(
                            label: l10n.scoreLeadLabel,
                            value: formatScore(candidate.scoreLead, l10n),
                            alignEnd: true,
                          ),
                        ),
                        Expanded(
                          child: LabeledValue(
                            label: l10n.visitsLabel,
                            value: formatVisits(candidate.visits),
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _PrincipalVariationStrip(
                      moves: displayedPv,
                      boardSize: data.record.boardSize,
                    ),
                    const Spacer(),
                    Divider(height: 1, color: context.goColors.softDivider),
                    const SizedBox(height: GoSpacing.s1),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            l10n.playedMoveValue(
                              formatMove(played, data.record.boardSize, l10n),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          formatPointLoss(after.playedMovePointLoss, l10n),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _PrincipalVariationStrip extends StatelessWidget {
  const _PrincipalVariationStrip({
    required this.moves,
    required this.boardSize,
  });

  final List<domain.Move> moves;
  final domain.BoardSize boardSize;

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) {
      return Text(
        context.l10n.serviceNoPrincipalVariation,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Row(
      children: <Widget>[
        for (var index = 0; index < moves.length; index++)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: moves[index].color == domain.StoneColor.black
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: moves[index].color == domain.StoneColor.black
                          ? Theme.of(context).colorScheme.surface
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: GoSpacing.s1),
                Text(
                  formatMove(moves[index], boardSize, context.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _VariationUnavailable extends StatelessWidget {
  const _VariationUnavailable();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        FeatureTopBar(
          title: context.l10n.variationComparisonTitle,
          subtitle: context.l10n.realCandidateData,
          leading: const BackCircleButton(),
        ),
        Expanded(
          child: Center(
            child: FilledButton(
              onPressed: () => Navigator.maybePop(context),
              child: Text(context.l10n.noVariationReturn),
            ),
          ),
        ),
      ],
    ),
  );
}

List<BoardStone> _variationStones(
  ReviewScreenData data,
  int moveNumber,
  domain.Candidate candidate,
) {
  final initial = data.positionBeforeMove(moveNumber);
  final pv = candidate.principalVariation;
  if (pv.isEmpty) return boardStones(initial);
  final validation = domain.GoRuleValidator.validate(
    initialPosition: initial,
    moves: pv,
    rules: data.record.rules,
    firstPlayer: candidate.move.color,
  );
  if (!validation.isValid) return boardStones(initial);
  final finalPosition = validation.finalPosition;
  final numbers = <domain.BoardPoint, int>{};
  for (var index = 0; index < pv.length; index++) {
    final point = pv[index].point;
    if (point != null && finalPosition.stoneAt(point) == pv[index].color) {
      numbers[point] = index + 1;
    }
  }
  return <BoardStone>[
    for (final entry in finalPosition.stones.entries)
      BoardStone(
        point: uiPoint(entry.key),
        color: entry.value == domain.StoneColor.black
            ? StoneColor.black
            : StoneColor.white,
        moveNumber: numbers[entry.key],
      ),
  ];
}

String _selectedLabel(
  domain.Candidate candidate,
  ReviewScreenData data,
  int moveNumber,
  AppLocalizations l10n,
) => candidate == data.beforeMove(moveNumber).candidates.first
    ? l10n.bestCandidate
    : l10n.candidateVariation;
