import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';

void main() {
  testWidgets('paints stones, candidates, and one board semantic node', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _harness(
        const SizedBox.square(
          dimension: 320,
          child: GoBoard(
            stones: <BoardStone>[
              BoardStone(point: BoardPoint(3, 3), color: StoneColor.black),
              BoardStone(point: BoardPoint(15, 15), color: StoneColor.white),
            ],
            candidates: <BoardCandidate>[
              BoardCandidate(point: BoardPoint(16, 3), label: 'A'),
              BoardCandidate(
                point: BoardPoint(15, 2),
                label: 'B',
                tone: CandidateTone.secondary,
              ),
            ],
            lastMove: BoardPoint(15, 15),
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is GoBoardPainter,
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('围棋棋盘'), findsOneWidget);
    final boardSemantics = tester.getSemantics(find.bySemanticsLabel('围棋棋盘'));
    expect(boardSemantics.getSemanticsData().value, contains('最后一手 Q4'));
    expect(boardSemantics.getSemanticsData().value, contains('A R16'));
    expect(boardSemantics.getSemanticsData().value, contains('当前 Q4，白棋，最后一手'));
    semantics.dispose();
  });

  testWidgets('方向读屏操作同步当前点语义与可视光标', (tester) async {
    final semantics = tester.ensureSemantics();
    const moveRight = CustomSemanticsAction(label: '向右移动');
    await tester.pumpWidget(
      _harness(
        const SizedBox.square(
          dimension: 320,
          child: GoBoard(
            selectedPoint: BoardPoint(9, 9),
            stones: <BoardStone>[
              BoardStone(
                point: BoardPoint(10, 9),
                color: StoneColor.black,
                moveNumber: 87,
              ),
            ],
          ),
        ),
      ),
    );

    tester.semantics.customAction(find.semantics.byLabel('围棋棋盘'), moveRight);
    await tester.pump();

    final boardSemantics = tester.getSemantics(find.bySemanticsLabel('围棋棋盘'));
    expect(
      boardSemantics.getSemanticsData().value,
      contains('当前 L10，黑棋，第 87 手'),
    );
    final paint = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is GoBoardPainter,
      ),
    );
    expect(
      (paint.painter! as GoBoardPainter).selectedPoint,
      const BoardPoint(10, 9),
    );
    semantics.dispose();
  });

  testWidgets('maps a board tap to the nearest intersection', (tester) async {
    BoardPoint? tapped;
    await tester.pumpWidget(
      _harness(
        SizedBox.square(
          dimension: 320,
          child: GoBoard(onIntersectionTap: (point) => tapped = point),
        ),
      ),
    );

    await tester.tapAt(tester.getCenter(find.byType(GoBoard)));
    await tester.pump();

    expect(tapped, const BoardPoint(9, 9));
  });

  test('coordinate labels omit I as standard Go notation', () {
    expect(const BoardPoint(7, 0).coordinate(19), 'H19');
    expect(const BoardPoint(8, 0).coordinate(19), 'J19');
    expect(const BoardPoint(15, 3).coordinate(19), 'Q16');
  });

  test('equivalent immutable board models do not trigger a repaint', () {
    final before = GoBoardPainter(
      boardSize: 19,
      stones: const <BoardStone>[
        BoardStone(point: BoardPoint(3, 3), color: StoneColor.black),
      ],
      candidates: const <BoardCandidate>[
        BoardCandidate(point: BoardPoint(16, 3), label: 'A'),
      ],
      colors: GoSemanticColors.light,
    );
    final after = GoBoardPainter(
      boardSize: 19,
      stones: const <BoardStone>[
        BoardStone(point: BoardPoint(3, 3), color: StoneColor.black),
      ],
      candidates: const <BoardCandidate>[
        BoardCandidate(point: BoardPoint(16, 3), label: 'A'),
      ],
      colors: GoSemanticColors.light,
    );

    expect(after.shouldRepaint(before), isFalse);
  });
}

Widget _harness(Widget child) {
  return MaterialApp(
    theme: LizzieTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );
}
