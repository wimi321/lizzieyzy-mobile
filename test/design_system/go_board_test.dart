import 'package:flutter/material.dart';
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
}

Widget _harness(Widget child) {
  return MaterialApp(
    theme: LizzieTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );
}
