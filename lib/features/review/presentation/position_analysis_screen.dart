import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';

import '../../common/presentation/feature_chrome.dart';
import '../../fixtures/ui_fixtures.dart';

/// Analysis for a still-photo position.
///
/// A single photo has no trustworthy move sequence, so this screen
/// intentionally has no move timeline, key-move ranking, or performance band.
class PositionAnalysisScreen extends StatefulWidget {
  const PositionAnalysisScreen({super.key});

  @override
  State<PositionAnalysisScreen> createState() => _PositionAnalysisScreenState();
}

class _PositionAnalysisScreenState extends State<PositionAnalysisScreen> {
  var _selectedCandidate = 0;

  static const _coordinates = <String>['R14', 'Q14', 'O16'];
  static const _winRates = <String>['57.8%', '55.1%', '53.6%'];
  static const _scoreLeads = <String>['+3.1目', '+1.4目', '+0.6目'];
  static const _visits = <String>['12,840', '7,226', '4,908'];
  static const _variations = <List<String>>[
    <String>['R14', 'R15', 'Q13', 'P14', 'S13'],
    <String>['Q14', 'R14', 'P15', 'Q13', 'O16'],
    <String>['O16', 'P17', 'N17', 'Q16', 'R15'],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = String.fromCharCode(65 + _selectedCandidate);
    return Scaffold(
      body: Column(
        children: <Widget>[
          const FeatureTopBar(
            title: '局面分析',
            subtitle: '当前局面 · 无完整手顺',
            leading: BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const horizontalPadding = GoSpacing.s3;
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final largeText = textScale > 1.45;
                  final reservedHeight =
                      376 + math.max<double>(0, textScale - 1) * 140;
                  final boardSide = math.min<double>(
                    constraints.maxWidth - horizontalPadding * 2,
                    math.max<double>(
                      184,
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
                      key: const Key('position-analysis-viewport'),
                      children: <Widget>[
                        SizedBox.square(
                          dimension: boardSide,
                          child: GoBoard(
                            stones: UiFixtures.stones,
                            candidates: UiFixtures.candidates,
                            selectedPoint:
                                UiFixtures.candidates[_selectedCandidate].point,
                            semanticLabel: '当前局面分析棋盘，已选择候选$label',
                            showCoordinates: true,
                          ),
                        ),
                        const SizedBox(height: GoSpacing.s1),
                        Semantics(
                          label: '当前局面不包含完整手顺，不提供关键手和棋力评估',
                          child: SurfacePanel(
                            padding: const EdgeInsets.symmetric(
                              horizontal: GoSpacing.s2,
                              vertical: GoSpacing.s1,
                            ),
                            color: theme.colorScheme.secondaryContainer,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: GoSpacing.s3),
                                Expanded(
                                  child: Text(
                                    '单张照片没有落子时间；仅分析此刻的候选与形势，不显示关键手时间轴或棋力。',
                                    maxLines: largeText ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: GoSpacing.s1),
                        Row(
                          children: <Widget>[
                            for (var index = 0; index < 3; index++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: index == 2 ? 0 : GoSpacing.s2,
                                  ),
                                  child: _CandidateChoice(
                                    label: String.fromCharCode(65 + index),
                                    coordinate: _coordinates[index],
                                    selected: index == _selectedCandidate,
                                    singleLine: largeText,
                                    onTap: () => setState(
                                      () => _selectedCandidate = index,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: GoSpacing.s1),
                        if (largeText)
                          _LargeTextPositionInspector(
                            label: label,
                            coordinate: _coordinates[_selectedCandidate],
                            winRate: _winRates[_selectedCandidate],
                            scoreLead: _scoreLeads[_selectedCandidate],
                            visits: _visits[_selectedCandidate],
                            variation: _variations[_selectedCandidate],
                            best: _selectedCandidate == 0,
                          )
                        else
                          SurfacePanel(
                            padding: const EdgeInsets.all(GoSpacing.s2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    CandidateMarker(
                                      label: label,
                                      selected: true,
                                    ),
                                    const SizedBox(width: GoSpacing.s3),
                                    Text(
                                      _coordinates[_selectedCandidate],
                                      style: theme.textTheme.headlineSmall,
                                    ),
                                    const Spacer(),
                                    if (_selectedCandidate == 0)
                                      const MetricPill(
                                        label: '最佳候选',
                                        tone: MetricTone.primary,
                                        compact: true,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: GoSpacing.s1),
                                Wrap(
                                  spacing: GoSpacing.s2,
                                  runSpacing: GoSpacing.s2,
                                  children: <Widget>[
                                    MetricPill(
                                      label: '黑胜率',
                                      value: _winRates[_selectedCandidate],
                                    ),
                                    MetricPill(
                                      label: '黑方目差',
                                      value: _scoreLeads[_selectedCandidate],
                                      tone: MetricTone.positive,
                                    ),
                                    MetricPill(
                                      label: '访问',
                                      value: _visits[_selectedCandidate],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: GoSpacing.s1),
                                Text('主变化', style: theme.textTheme.titleSmall),
                                const SizedBox(height: GoSpacing.s1),
                                Wrap(
                                  spacing: GoSpacing.s2,
                                  runSpacing: GoSpacing.s2,
                                  children: <Widget>[
                                    for (
                                      var index = 0;
                                      index <
                                          _variations[_selectedCandidate]
                                              .length;
                                      index++
                                    )
                                      _VariationMove(
                                        number: index + 1,
                                        coordinate:
                                            _variations[_selectedCandidate][index],
                                        black: index.isEven,
                                      ),
                                  ],
                                ),
                              ],
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

class _CandidateChoice extends StatelessWidget {
  const _CandidateChoice({
    required this.label,
    required this.coordinate,
    required this.selected,
    required this.singleLine,
    required this.onTap,
  });

  final String label;
  final String coordinate;
  final bool selected;
  final bool singleLine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '候选$label，$coordinate',
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoRadii.card),
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary
                : context.goColors.softDivider,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GoRadii.card),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: GoSizes.minimumTouchTarget,
            ),
            child: Center(
              child: singleLine
                  ? Text(
                      '$label · $coordinate',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(label, style: theme.textTheme.labelMedium),
                        Text(coordinate, style: theme.textTheme.bodySmall),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LargeTextPositionInspector extends StatelessWidget {
  const _LargeTextPositionInspector({
    required this.label,
    required this.coordinate,
    required this.winRate,
    required this.scoreLead,
    required this.visits,
    required this.variation,
    required this.best,
  });

  final String label;
  final String coordinate;
  final String winRate;
  final String scoreLead;
  final String visits;
  final List<String> variation;
  final bool best;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variationLabel = variation.join(' → ');
    return Semantics(
      container: true,
      label:
          '候选$label，$coordinate，黑胜率$winRate，黑方目差$scoreLead，$visits访问，主变化$variationLabel',
      excludeSemantics: true,
      child: SurfacePanel(
        padding: const EdgeInsets.symmetric(
          horizontal: GoSpacing.s2,
          vertical: GoSpacing.s1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                CandidateMarker(label: label, selected: true),
                const SizedBox(width: GoSpacing.s2),
                Expanded(
                  child: Text(
                    coordinate,
                    maxLines: 1,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                if (best)
                  const MetricPill(
                    label: '最佳',
                    tone: MetricTone.primary,
                    compact: true,
                  ),
              ],
            ),
            Text(
              '黑胜率 $winRate · 目差 $scoreLead · 访问 $visits',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '主变化 $variationLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _VariationMove extends StatelessWidget {
  const _VariationMove({
    required this.number,
    required this.coordinate,
    required this.black,
  });

  final int number;
  final String coordinate;
  final bool black;

  @override
  Widget build(BuildContext context) {
    final colors = context.goColors;
    return Semantics(
      label: '第$number手，${black ? '黑' : '白'}方$coordinate',
      child: Column(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: black ? colors.blackStone : colors.whiteStone,
              border: Border.all(color: colors.whiteStoneOutline),
            ),
            child: Text(
              '$number',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: black ? colors.whiteStone : colors.blackStone,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(coordinate, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
