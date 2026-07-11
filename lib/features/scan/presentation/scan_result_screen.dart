import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';
import '../../fixtures/ui_fixtures.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key, this.result});

  final ScanPositionPayload? result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final position = result?.snapshot.position;
    final stones = position == null
        ? UiFixtures.stones
        : <BoardStone>[
            for (final entry in position.stones.entries)
              BoardStone(
                point: BoardPoint(entry.key.column, entry.key.row),
                color: entry.value == domain.StoneColor.black
                    ? StoneColor.black
                    : StoneColor.white,
              ),
          ];
    final blackCount =
        position?.count(domain.StoneColor.black) ?? UiFixtures.scan.blackStones;
    final whiteCount =
        position?.count(domain.StoneColor.white) ?? UiFixtures.scan.whiteStones;
    return Scaffold(
      body: Column(
        children: <Widget>[
          const FeatureTopBar(
            title: '识别结果',
            subtitle: '当前局面 · 19路',
            leading: BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boardSide = math.min(
                    math.min(constraints.maxWidth, 520.0) - GoSpacing.s8,
                    math.max(180.0, constraints.maxHeight - 220.0),
                  );
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        key: const Key('scan-result-viewport'),
                        padding: const EdgeInsets.fromLTRB(
                          GoSpacing.s4,
                          GoSpacing.s1,
                          GoSpacing.s4,
                          GoSpacing.s3,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Center(
                              child: SizedBox.square(
                                dimension: boardSide,
                                child: GoBoard(
                                  boardSize: position?.size.dimension ?? 19,
                                  stones: stones,
                                  semanticLabel:
                                      '识别完成的十九路围棋局面，黑$blackCount子，白$whiteCount子',
                                ),
                              ),
                            ),
                            const SizedBox(height: GoSpacing.s2),
                            SurfacePanel(
                              padding: const EdgeInsets.all(GoSpacing.s3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme
                                              .primaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 20,
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                      const SizedBox(width: GoSpacing.s2),
                                      Expanded(
                                        child: Text(
                                          '棋盘识别完成',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ),
                                      Text(
                                        '黑 $blackCount  ·  白 $whiteCount',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: GoSpacing.s2),
                                  Text(
                                    '已识别当前局面：黑$blackCount子，白$whiteCount子。',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: GoSpacing.s1),
                                  Text(
                                    '单张照片不包含落子时间，无法恢复完整手顺。此局面不会显示关键手时间轴或棋力评估。',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: GoSpacing.s3),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: GoSpacing.s2,
                                      ),
                                    ),
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.positionAnalysis,
                                      arguments: result?.snapshot,
                                    ),
                                    icon: const Icon(
                                      Icons.analytics_outlined,
                                      size: 20,
                                    ),
                                    label: const Text('分析当前局面'),
                                  ),
                                ),
                                const SizedBox(width: GoSpacing.s2),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: GoSpacing.s2,
                                      ),
                                    ),
                                    onPressed: () => Navigator.popUntil(
                                      context,
                                      (route) => route.isFirst,
                                    ),
                                    icon: const Icon(
                                      Icons.save_outlined,
                                      size: 20,
                                    ),
                                    label: const Text('保存局面'),
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}
