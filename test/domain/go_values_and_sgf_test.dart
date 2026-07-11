import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

void main() {
  group('Go value objects', () {
    test('GTP coordinates skip I and count rows from the bottom', () {
      expect(const BoardPoint(0, 18).toGtp(BoardSize.nineteen), 'A1');
      expect(const BoardPoint(7, 0).toGtp(BoardSize.nineteen), 'H19');
      expect(const BoardPoint(8, 0).toGtp(BoardSize.nineteen), 'J19');
    });

    test('board position defensively copies stones', () {
      final stones = <BoardPoint, StoneColor>{
        const BoardPoint(3, 3): StoneColor.black,
      };
      final position = BoardPosition(size: BoardSize.nine, stones: stones);
      stones.clear();

      expect(position.count(StoneColor.black), 1);
      expect(
        () => position.stones[const BoardPoint(4, 4)] = StoneColor.white,
        throwsUnsupportedError,
      );
    });

    test('play and pass preserve their invariant', () {
      const play = Move.play(color: StoneColor.black, point: BoardPoint(2, 2));
      const pass = Move.pass(color: StoneColor.white);

      expect(play.isPass, isFalse);
      expect(play.point, const BoardPoint(2, 2));
      expect(pass.isPass, isTrue);
      expect(pass.point, isNull);
      expect(StoneColor.black.opponent, StoneColor.white);
    });
  });

  group('SGF value objects', () {
    test('coordinate round trips on supported board sizes', () {
      const point = BoardPoint(15, 3);
      final coordinate = SgfCoordinate.fromPoint(point, BoardSize.nineteen);

      expect(coordinate.value, 'pd');
      expect(coordinate.toPoint(BoardSize.nineteen), point);
    });

    test('invalid coordinate and property fail explicitly', () {
      expect(
        () => const SgfCoordinate('AA').toPoint(BoardSize.nineteen),
        throwsFormatException,
      );
      expect(
        () => SgfProperty(identifier: 'c', values: const ['note']),
        throwsFormatException,
      );
      expect(
        () => SgfProperty(identifier: 'C', values: const []),
        throwsArgumentError,
      );
    });

    test(
      'node rejects duplicate properties and tree rejects empty sequence',
      () {
        expect(
          () => SgfNode(
            properties: [
              SgfProperty(identifier: 'C', values: const ['one']),
              SgfProperty(identifier: 'C', values: const ['two']),
            ],
          ),
          throwsArgumentError,
        );
        expect(() => SgfGameTree(sequence: const []), throwsArgumentError);
      },
    );
  });
}
