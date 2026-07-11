import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

void main() {
  const source = KifuSource(kind: KifuSourceKind.fixture);

  group('GameReplayTimeline', () {
    test('contains the root and every capture-correct position', () {
      final record = VerifiedGameRecord(
        id: 'capture-game',
        initialPosition: BoardPosition.empty(BoardSize.nine),
        moves: const <Move>[
          Move.play(color: StoneColor.black, point: BoardPoint(0, 1)),
          Move.play(color: StoneColor.white, point: BoardPoint(1, 1)),
          Move.play(color: StoneColor.black, point: BoardPoint(1, 0)),
          Move.pass(color: StoneColor.white),
          Move.play(color: StoneColor.black, point: BoardPoint(2, 1)),
          Move.pass(color: StoneColor.white),
          Move.play(color: StoneColor.black, point: BoardPoint(1, 2)),
        ],
        rules: const GoRules.japanese(),
        source: source,
      );

      final timeline = GameReplayTimeline.fromRecord(record);

      expect(timeline.recordId, 'capture-game');
      expect(timeline.totalMoves, 7);
      expect(timeline.positions, hasLength(8));
      expect(
        timeline.positionAt(2).stoneAt(const BoardPoint(1, 1)),
        StoneColor.white,
      );
      expect(
        timeline.positionBeforeMove(7).stoneAt(const BoardPoint(1, 1)),
        StoneColor.white,
      );
      expect(timeline.positionAt(7).stoneAt(const BoardPoint(1, 1)), isNull);
      expect(timeline.positionAt(7), record.finalPosition);
      expect(timeline.moveAt(7), record.moves.last);
    });

    test('preserves a board across pass while retaining move indexing', () {
      final record = VerifiedGameRecord(
        id: 'pass-game',
        initialPosition: BoardPosition.empty(BoardSize.nine),
        moves: const <Move>[
          Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
          Move.pass(color: StoneColor.white),
          Move.play(color: StoneColor.black, point: BoardPoint(4, 4)),
        ],
        rules: const GoRules.japanese(),
        source: source,
      );

      final timeline = GameReplayTimeline.fromRecord(record);

      expect(timeline.positionAt(2), timeline.positionAt(1));
      expect(timeline.positionBeforeMove(3), timeline.positionAt(2));
      expect(timeline.moveAt(2).isPass, isTrue);
    });

    test('is immutable and rejects invalid move indices', () {
      final record = VerifiedGameRecord(
        id: 'immutable-game',
        initialPosition: BoardPosition.empty(BoardSize.nine),
        moves: const <Move>[
          Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
        ],
        rules: const GoRules.japanese(),
        source: source,
      );
      final timeline = GameReplayTimeline.fromRecord(record);

      expect(
        () => timeline.positions.add(BoardPosition.empty(BoardSize.nine)),
        throwsUnsupportedError,
      );
      expect(() => timeline.positionAt(2), throwsA(isA<RangeError>()));
      expect(() => timeline.positionBeforeMove(0), throwsA(isA<RangeError>()));
      expect(() => timeline.moveAt(2), throwsA(isA<RangeError>()));
    });
  });
}
