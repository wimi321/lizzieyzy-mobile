import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';

import '../../common/presentation/feature_chrome.dart';
import '../../fixtures/ui_fixtures.dart';

class VariationComparisonScreen extends StatefulWidget {
  const VariationComparisonScreen({super.key});

  @override
  State<VariationComparisonScreen> createState() =>
      _VariationComparisonScreenState();
}

class _VariationComparisonScreenState extends State<VariationComparisonScreen> {
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: LizzieTheme.dark(),
        child: Builder(
          builder: (context) {
            final model = UiFixtures.keyMove;
            return Scaffold(
              body: Column(
                children: <Widget>[
                  FeatureTopBar(
                    title: '变化比较',
                    subtitle: '第87手 · 白方选择',
                    leading: const BackCircleButton(),
                    actions: <Widget>[
                      IconButton(
                        tooltip: '更多数据',
                        onPressed: () {},
                        icon: const Icon(Icons.more_horiz_rounded),
                      ),
                    ],
                    dark: true,
                  ),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      key: const Key('variation-comparison-scroll'),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const horizontalPadding = GoSpacing.s3;
                          final textScale = MediaQuery.textScalerOf(
                            context,
                          ).scale(1);
                          final largeText = textScale > 1.45;
                          final reservedHeight = largeText
                              ? 445.0
                              : 350 + math.max<double>(0, textScale - 1) * 100;
                          final boardSide = math.min<double>(
                            constraints.maxWidth - horizontalPadding * 2,
                            math.max<double>(
                              largeText ? 196 : 200,
                              constraints.maxHeight - reservedHeight,
                            ),
                          );
                          final coordinate = switch (_selected) {
                            0 => 'R14',
                            1 => 'Q14',
                            _ => 'O16',
                          };
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
                                  child: GoBoard(
                                    stones: model.stones,
                                    candidates: model.candidates,
                                    lastMove: const BoardPoint(15, 3),
                                    selectedPoint:
                                        model.candidates[_selected].point,
                                    semanticLabel:
                                        '第87手变化比较，当前选择候选${String.fromCharCode(65 + _selected)}',
                                    showCoordinates: true,
                                  ),
                                ),
                                const SizedBox(height: GoSpacing.s2),
                                Row(
                                  children: <Widget>[
                                    for (
                                      var index = 0;
                                      index < model.candidates.length;
                                      index++
                                    )
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right:
                                                index ==
                                                    model.candidates.length - 1
                                                ? 0
                                                : GoSpacing.s2,
                                          ),
                                          child: _VariationChoice(
                                            label: String.fromCharCode(
                                              65 + index,
                                            ),
                                            coordinate: switch (index) {
                                              0 => 'R14',
                                              1 => 'Q14',
                                              _ => 'O16',
                                            },
                                            detail:
                                                model
                                                    .candidates[index]
                                                    .detail ??
                                                '',
                                            largeText: largeText,
                                            selected: _selected == index,
                                            onTap: () => setState(
                                              () => _selected = index,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: GoSpacing.s2),
                                _VariationInspector(
                                  coordinate: coordinate,
                                  detail:
                                      model.candidates[_selected].detail ?? '',
                                  best: _selected == 0,
                                  largeText: largeText,
                                ),
                                if (!largeText) ...<Widget>[
                                  const SizedBox(height: GoSpacing.s2),
                                  const _PlayedCandidateComparison(),
                                ],
                                const SizedBox(height: GoSpacing.s2),
                                SizedBox(
                                  width: double.infinity,
                                  height: GoSizes.minimumTouchTarget,
                                  child: FilledButton.icon(
                                    onPressed: () =>
                                        Navigator.maybePop(context),
                                    icon: const Icon(Icons.fork_right_rounded),
                                    label: const Text('回到主线第87手'),
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
          },
        ),
      ),
    );
  }
}

class _VariationChoice extends StatelessWidget {
  const _VariationChoice({
    required this.label,
    required this.coordinate,
    required this.detail,
    required this.selected,
    required this.largeText,
    required this.onTap,
  });

  final String label;
  final String coordinate;
  final String detail;
  final bool selected;
  final bool largeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '候选$label，$coordinate，$detail',
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GoSpacing.s2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CandidateMarker(
                    label: label,
                    selected: selected,
                    diameter: 24,
                  ),
                  const SizedBox(width: GoSpacing.s1),
                  Flexible(
                    child: largeText
                        ? Text(
                            coordinate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge,
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                coordinate,
                                style: theme.textTheme.labelLarge,
                              ),
                              Text(
                                detail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VariationInspector extends StatelessWidget {
  const _VariationInspector({
    required this.coordinate,
    required this.detail,
    required this.best,
    required this.largeText,
  });

  final String coordinate;
  final String detail;
  final bool best;
  final bool largeText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (largeText) {
      return Semantics(
        container: true,
        label:
            '候选$coordinate，$detail，胜率57.8%，目差加3.1目，12840访问，主变化白R14黑R15白Q13黑P14白S13，实战Q16负2.1目',
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
                  Expanded(
                    child: Text(
                      '$coordinate · $detail',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
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
                '57.8% · +3.1目 · 12,840访问',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'PV R14 → R15 → Q13 · 实战 Q16 -2.1目',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }
    return SurfacePanel(
      padding: const EdgeInsets.all(GoSpacing.s2),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(coordinate, style: theme.textTheme.titleLarge),
              const SizedBox(width: GoSpacing.s2),
              if (best)
                const MetricPill(
                  label: '最佳候选',
                  tone: MetricTone.primary,
                  compact: true,
                ),
              const Spacer(),
              Text(detail, style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: GoSpacing.s1),
          const Row(
            children: <Widget>[
              Expanded(
                child: _InspectorMetric(label: '胜率', value: '57.8%'),
              ),
              Expanded(
                child: _InspectorMetric(label: '目差', value: '+3.1目'),
              ),
              Expanded(
                child: _InspectorMetric(label: '访问', value: '12,840'),
              ),
            ],
          ),
          const SizedBox(height: GoSpacing.s1),
          const Row(
            children: <Widget>[
              Text('主变化'),
              SizedBox(width: GoSpacing.s2),
              Expanded(child: _PrincipalVariation()),
            ],
          ),
        ],
      ),
    );
  }
}

class _InspectorMetric extends StatelessWidget {
  const _InspectorMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: theme.textTheme.bodySmall),
        Text(value, style: theme.textTheme.labelMedium),
      ],
    );
  }
}

class _PlayedCandidateComparison extends StatelessWidget {
  const _PlayedCandidateComparison();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfacePanel(
      padding: const EdgeInsets.symmetric(
        horizontal: GoSpacing.s3,
        vertical: GoSpacing.s2,
      ),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: LabeledValue(label: '实战 Q16', value: '-2.1目'),
          ),
          Icon(
            Icons.compare_arrows_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const Expanded(
            child: LabeledValue(
              label: '候选 R14',
              value: '+3.1目',
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrincipalVariation extends StatelessWidget {
  const _PrincipalVariation();

  @override
  Widget build(BuildContext context) {
    const moves = <(String, StoneColor)>[
      ('R14', StoneColor.white),
      ('R15', StoneColor.black),
      ('Q13', StoneColor.white),
      ('P14', StoneColor.black),
      ('S13', StoneColor.white),
    ];
    return Semantics(
      label: '主变化，白R14，黑R15，白Q13，黑P14，白S13',
      child: Wrap(
        spacing: GoSpacing.s1,
        runSpacing: GoSpacing.s1,
        children: <Widget>[
          for (var index = 0; index < moves.length; index++)
            _MoveToken(
              number: index + 1,
              coordinate: moves[index].$1,
              color: moves[index].$2,
            ),
        ],
      ),
    );
  }
}

class _MoveToken extends StatelessWidget {
  const _MoveToken({
    required this.number,
    required this.coordinate,
    required this.color,
  });

  final int number;
  final String coordinate;
  final StoneColor color;

  @override
  Widget build(BuildContext context) {
    final colors = context.goColors;
    final black = color == StoneColor.black;
    return SizedBox(
      width: 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: black ? colors.blackStone : colors.whiteStone,
              shape: BoxShape.circle,
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
