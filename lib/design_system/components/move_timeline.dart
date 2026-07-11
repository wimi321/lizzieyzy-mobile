import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../tokens.dart';

class MoveTimeline extends StatelessWidget {
  const MoveTimeline({
    required this.currentMove,
    required this.totalMoves,
    required this.onChanged,
    super.key,
    this.keyMoves = const <int>[],
    this.label,
    this.minimumMove = 0,
  }) : assert(totalMoves >= 0),
       assert(minimumMove >= 0),
       assert(minimumMove <= totalMoves || totalMoves == 0),
       assert(currentMove >= minimumMove),
       assert(currentMove <= totalMoves);

  final int currentMove;
  final int totalMoves;
  final List<int> keyMoves;
  final ValueChanged<int>? onChanged;
  final String? label;
  final int minimumMove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final resolvedLabel = label ?? l10n.timelineLabel;
    final canGoBack = onChanged != null && currentMove > minimumMove;
    final canGoForward = onChanged != null && currentMove < totalMoves;
    final moveRange = totalMoves - minimumMove;
    final max = totalMoves == 0 ? 1.0 : totalMoves.toDouble();
    final value = currentMove.clamp(minimumMove, totalMoves).toDouble();
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Semantics(
      container: true,
      label: l10n.timelineSemantics(resolvedLabel, currentMove, totalMoves),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (textScale > 2.4)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$currentMove / $totalMoves',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          else
            Row(
              children: <Widget>[
                Text(resolvedLabel, style: theme.textTheme.labelMedium),
                const Spacer(),
                Text(
                  '$currentMove / $totalMoves',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          const SizedBox(height: GoSpacing.s1),
          SizedBox(
            height: GoSizes.comfortableTouchTarget,
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: l10n.previousMove,
                  onPressed: canGoBack
                      ? () => onChanged!.call(currentMove - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      if (keyMoves.isNotEmpty && totalMoves > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _KeyMovePainter(
                                keyMoves: keyMoves,
                                totalMoves: totalMoves,
                                color: context.goColors.dataGold,
                              ),
                            ),
                          ),
                        ),
                      Slider(
                        value: value,
                        min: minimumMove.toDouble(),
                        max: max,
                        divisions: moveRange <= 0 ? null : moveRange,
                        label: l10n.moveOrdinal(currentMove),
                        semanticFormatterCallback: (move) =>
                            l10n.sliderMoveSemantics(move.round(), totalMoves),
                        onChanged: moveRange <= 0 || onChanged == null
                            ? null
                            : (next) => onChanged!.call(next.round()),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.nextMove,
                  onPressed: canGoForward
                      ? () => onChanged!.call(currentMove + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyMovePainter extends CustomPainter {
  const _KeyMovePainter({
    required this.keyMoves,
    required this.totalMoves,
    required this.color,
  });

  final List<int> keyMoves;
  final int totalMoves;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const horizontalInset = 24.0;
    final width = (size.width - horizontalInset * 2).clamp(0, double.infinity);
    final paint = Paint()..color = color;
    for (final move in keyMoves) {
      if (move < 0 || move > totalMoves) continue;
      final x = horizontalInset + width * move / totalMoves;
      canvas.drawCircle(Offset(x, size.height * 0.77), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _KeyMovePainter oldDelegate) {
    return oldDelegate.keyMoves != keyMoves ||
        oldDelegate.totalMoves != totalMoves ||
        oldDelegate.color != color;
  }
}
