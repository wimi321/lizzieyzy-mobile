import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../tokens.dart';
import 'candidate_marker.dart';

enum StoneColor { black, white }

@immutable
class BoardPoint {
  const BoardPoint(this.x, this.y);

  final int x;
  final int y;

  String coordinate(int boardSize) {
    const columns = 'ABCDEFGHJKLMNOPQRSTUVWXYZ';
    final column = x >= 0 && x < columns.length ? columns[x] : '${x + 1}';
    return '$column${boardSize - y}';
  }

  @override
  bool operator ==(Object other) {
    return other is BoardPoint && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

@immutable
class BoardStone {
  const BoardStone({required this.point, required this.color, this.moveNumber});

  final BoardPoint point;
  final StoneColor color;
  final int? moveNumber;
}

@immutable
class BoardCandidate {
  const BoardCandidate({
    required this.point,
    required this.label,
    this.detail,
    this.tone = CandidateTone.primary,
  });

  final BoardPoint point;
  final String label;
  final String? detail;
  final CandidateTone tone;
}

/// A square, custom-painted Go board exposed to screen readers as one
/// adjustable two-dimensional control instead of 361 focus nodes.
class GoBoard extends StatefulWidget {
  const GoBoard({
    super.key,
    this.boardSize = 19,
    this.stones = const <BoardStone>[],
    this.candidates = const <BoardCandidate>[],
    this.lastMove,
    this.selectedPoint,
    this.onIntersectionTap,
    this.onSelectionChanged,
    this.semanticLabel = '围棋棋盘',
    this.showCoordinates = false,
  }) : assert(boardSize >= 2 && boardSize <= 25);

  final int boardSize;
  final List<BoardStone> stones;
  final List<BoardCandidate> candidates;
  final BoardPoint? lastMove;
  final BoardPoint? selectedPoint;
  final ValueChanged<BoardPoint>? onIntersectionTap;
  final ValueChanged<BoardPoint>? onSelectionChanged;
  final String semanticLabel;
  final bool showCoordinates;

  @override
  State<GoBoard> createState() => _GoBoardState();
}

class _GoBoardState extends State<GoBoard> {
  late BoardPoint _semanticPoint;

  @override
  void initState() {
    super.initState();
    _semanticPoint = _initialPoint;
  }

  @override
  void didUpdateWidget(covariant GoBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPoint != null &&
        widget.selectedPoint != oldWidget.selectedPoint) {
      _semanticPoint = widget.selectedPoint!;
    } else if (widget.boardSize != oldWidget.boardSize) {
      _semanticPoint = _clamp(_semanticPoint);
    }
  }

  BoardPoint get _initialPoint =>
      widget.selectedPoint ??
      widget.lastMove ??
      BoardPoint(widget.boardSize ~/ 2, widget.boardSize ~/ 2);

  BoardPoint _clamp(BoardPoint point) => BoardPoint(
    point.x.clamp(0, widget.boardSize - 1),
    point.y.clamp(0, widget.boardSize - 1),
  );

  void _moveSelection(int dx, int dy) {
    final next = _clamp(
      BoardPoint(_semanticPoint.x + dx, _semanticPoint.y + dy),
    );
    if (next == _semanticPoint) return;
    setState(() => _semanticPoint = next);
    widget.onSelectionChanged?.call(next);
  }

  void _select(BoardPoint point) {
    setState(() => _semanticPoint = point);
    widget.onSelectionChanged?.call(point);
    widget.onIntersectionTap?.call(point);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.goColors;
    final actions = <CustomSemanticsAction, VoidCallback>{
      const CustomSemanticsAction(label: '向左移动'): () => _moveSelection(-1, 0),
      const CustomSemanticsAction(label: '向右移动'): () => _moveSelection(1, 0),
      const CustomSemanticsAction(label: '向上移动'): () => _moveSelection(0, -1),
      const CustomSemanticsAction(label: '向下移动'): () => _moveSelection(0, 1),
    };
    final lastMoveDescription = widget.lastMove == null
        ? '没有最后一手标记'
        : '最后一手 ${widget.lastMove!.coordinate(widget.boardSize)}';
    final candidatesDescription = widget.candidates.isEmpty
        ? '没有候选点'
        : widget.candidates
              .take(3)
              .map(
                (candidate) =>
                    '${candidate.label} ${candidate.point.coordinate(widget.boardSize)}'
                    '${candidate.detail == null ? '' : ' ${candidate.detail}'}',
              )
              .join('，');

    return Semantics(
      container: true,
      focusable: true,
      label: widget.semanticLabel,
      value:
          '${widget.boardSize}路，黑棋 ${widget.stones.where((s) => s.color == StoneColor.black).length} 子，'
          '白棋 ${widget.stones.where((s) => s.color == StoneColor.white).length} 子，'
          '$lastMoveDescription，$candidatesDescription。当前 ${_semanticPoint.coordinate(widget.boardSize)}',
      hint: '使用自定义方向操作移动交叉点${widget.onIntersectionTap == null ? '' : '，双击选择'}',
      onTap: widget.onIntersectionTap == null
          ? null
          : () => _select(_semanticPoint),
      customSemanticsActions: actions,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = math.min(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: widget.onIntersectionTap == null
                  ? null
                  : (details) {
                      _select(
                        _BoardGeometry(
                          widget.boardSize,
                          side,
                        ).nearestPoint(details.localPosition),
                      );
                    },
              child: CustomPaint(
                painter: GoBoardPainter(
                  boardSize: widget.boardSize,
                  stones: widget.stones,
                  candidates: widget.candidates,
                  lastMove: widget.lastMove,
                  selectedPoint: widget.selectedPoint ?? _semanticPoint,
                  colors: colors,
                  showCoordinates: widget.showCoordinates,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

@visibleForTesting
class GoBoardPainter extends CustomPainter {
  const GoBoardPainter({
    required this.boardSize,
    required this.stones,
    required this.candidates,
    required this.colors,
    this.lastMove,
    this.selectedPoint,
    this.showCoordinates = false,
  });

  final int boardSize;
  final List<BoardStone> stones;
  final List<BoardCandidate> candidates;
  final BoardPoint? lastMove;
  final BoardPoint? selectedPoint;
  final GoSemanticColors colors;
  final bool showCoordinates;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final geometry = _BoardGeometry(boardSize, side);
    final boardRect = Rect.fromLTWH(0, 0, side, side);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(GoRadii.card)),
      Paint()..color = colors.boardSurface,
    );

    final gridPaint = Paint()
      ..color = colors.boardGrid
      ..strokeWidth = math.max(0.75, side / 520)
      ..style = PaintingStyle.stroke;
    for (var index = 0; index < boardSize; index++) {
      final position = geometry.padding + geometry.step * index;
      canvas
        ..drawLine(
          Offset(geometry.padding, position),
          Offset(side - geometry.padding, position),
          gridPaint,
        )
        ..drawLine(
          Offset(position, geometry.padding),
          Offset(position, side - geometry.padding),
          gridPaint,
        );
    }

    final starPaint = Paint()..color = colors.boardGrid;
    for (final point in _starPoints(boardSize)) {
      canvas.drawCircle(
        geometry.offset(point),
        math.max(2, geometry.step * 0.095),
        starPaint,
      );
    }

    if (showCoordinates && side >= 280) {
      _paintCoordinates(canvas, geometry);
    }

    for (final stone in stones) {
      final center = geometry.offset(stone.point);
      final radius = geometry.step * 0.455;
      canvas.drawCircle(
        center.translate(0, geometry.step * 0.055),
        radius,
        Paint()..color = colors.shadow,
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = stone.color == StoneColor.black
              ? colors.blackStone
              : colors.whiteStone,
      );
      if (stone.color == StoneColor.white) {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = colors.whiteStoneOutline
            ..strokeWidth = math.max(0.8, geometry.step * 0.035)
            ..style = PaintingStyle.stroke,
        );
      }
    }

    if (lastMove != null) {
      final center = geometry.offset(lastMove!);
      canvas.drawCircle(
        center,
        geometry.step * 0.15,
        Paint()
          ..color = colors.candidateTertiary
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.6, geometry.step * 0.09),
      );
    }

    for (final candidate in candidates.take(3)) {
      _paintCandidate(canvas, geometry, candidate);
    }

    if (selectedPoint != null) {
      canvas.drawCircle(
        geometry.offset(selectedPoint!),
        geometry.step * 0.53,
        Paint()
          ..color = colors.candidatePrimary.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, geometry.step * 0.065),
      );
    }
  }

  void _paintCandidate(
    Canvas canvas,
    _BoardGeometry geometry,
    BoardCandidate candidate,
  ) {
    final center = geometry.offset(candidate.point);
    final background = switch (candidate.tone) {
      CandidateTone.primary => colors.candidatePrimary,
      CandidateTone.secondary => colors.candidateSecondary,
      CandidateTone.tertiary => colors.candidateTertiary,
    };
    final radius = geometry.step * 0.4;
    canvas
      ..drawCircle(center, radius, Paint()..color = background)
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = colors.whiteStone
          ..strokeWidth = math.max(1, geometry.step * 0.045)
          ..style = PaintingStyle.stroke,
      );
    final foreground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : GoPrimitiveColors.ink;
    final textPainter = TextPainter(
      text: TextSpan(
        text: candidate.label,
        style: TextStyle(
          color: foreground,
          fontSize: geometry.step * 0.46,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: radius * 1.6);
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _paintCoordinates(Canvas canvas, _BoardGeometry geometry) {
    for (var index = 0; index < boardSize; index++) {
      final column = BoardPoint(
        index,
        0,
      ).coordinate(boardSize).replaceAll(RegExp(r'\d'), '');
      final row = '${boardSize - index}';
      final position = geometry.padding + geometry.step * index;
      _paintTinyText(canvas, column, Offset(position, geometry.padding * 0.35));
      _paintTinyText(canvas, row, Offset(geometry.padding * 0.35, position));
    }
  }

  void _paintTinyText(Canvas canvas, String text, Offset center) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: colors.boardGrid.withValues(alpha: 0.8),
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant GoBoardPainter oldDelegate) {
    return oldDelegate.boardSize != boardSize ||
        oldDelegate.stones != stones ||
        oldDelegate.candidates != candidates ||
        oldDelegate.lastMove != lastMove ||
        oldDelegate.selectedPoint != selectedPoint ||
        oldDelegate.colors != colors ||
        oldDelegate.showCoordinates != showCoordinates;
  }
}

class _BoardGeometry {
  _BoardGeometry(this.boardSize, this.side)
    : padding = math.max(12, side * 0.058),
      step = (side - math.max(12, side * 0.058) * 2) / (boardSize - 1);

  final int boardSize;
  final double side;
  final double padding;
  final double step;

  Offset offset(BoardPoint point) {
    return Offset(padding + point.x * step, padding + point.y * step);
  }

  BoardPoint nearestPoint(Offset localPosition) {
    return BoardPoint(
      ((localPosition.dx - padding) / step).round().clamp(0, boardSize - 1),
      ((localPosition.dy - padding) / step).round().clamp(0, boardSize - 1),
    );
  }
}

List<BoardPoint> _starPoints(int boardSize) {
  final positions = switch (boardSize) {
    19 => const <int>[3, 9, 15],
    13 => const <int>[3, 6, 9],
    9 => const <int>[2, 4, 6],
    _ => const <int>[],
  };
  return <BoardPoint>[
    for (final x in positions)
      for (final y in positions) BoardPoint(x, y),
  ];
}
