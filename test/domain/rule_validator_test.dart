import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

void main() {
  group('GoRuleValidator', () {
    test('alternates turns, handles pass, and produces final position', () {
      final initial = BoardPosition.empty(BoardSize.nine);
      final result = GoRuleValidator.validate(
        initialPosition: initial,
        moves: const [
          Move.play(color: StoneColor.black, point: BoardPoint(2, 2)),
          Move.pass(color: StoneColor.white),
          Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
        ],
        rules: const GoRules.japanese(),
      );

      expect(result.isValid, isTrue);
      expect(result.finalPosition.count(StoneColor.black), 2);
      expect(result.finalPosition.count(StoneColor.white), 0);
    });

    test('captures a surrounded group', () {
      final initial = BoardPosition(
        size: BoardSize.nine,
        stones: {
          const BoardPoint(0, 0): StoneColor.black,
          const BoardPoint(2, 0): StoneColor.black,
          const BoardPoint(1, 0): StoneColor.white,
        },
      );
      final result = GoRuleValidator.validate(
        initialPosition: initial,
        moves: const [
          Move.play(color: StoneColor.black, point: BoardPoint(1, 1)),
        ],
        rules: const GoRules.japanese(),
      );

      expect(result.isValid, isTrue);
      expect(result.finalPosition.stoneAt(const BoardPoint(1, 0)), isNull);
      expect(result.whiteCaptured, 1);
    });

    test('rejects wrong turn, occupied point, and suicide', () {
      final empty = BoardPosition.empty(BoardSize.nine);
      final wrongTurn = GoRuleValidator.validate(
        initialPosition: empty,
        moves: const [
          Move.play(color: StoneColor.white, point: BoardPoint(1, 1)),
        ],
        rules: const GoRules.japanese(),
      );
      expect(wrongTurn.violations.single.code, RuleViolationCode.wrongTurn);

      final occupied = GoRuleValidator.validate(
        initialPosition: BoardPosition(
          size: BoardSize.nine,
          stones: {const BoardPoint(1, 1): StoneColor.white},
        ),
        moves: const [
          Move.play(color: StoneColor.black, point: BoardPoint(1, 1)),
        ],
        rules: const GoRules.japanese(),
      );
      expect(occupied.violations.single.code, RuleViolationCode.occupied);

      final suicide = GoRuleValidator.validate(
        initialPosition: BoardPosition(
          size: BoardSize.nine,
          stones: {
            const BoardPoint(0, 1): StoneColor.white,
            const BoardPoint(1, 0): StoneColor.white,
          },
        ),
        moves: const [
          Move.play(color: StoneColor.black, point: BoardPoint(0, 0)),
        ],
        rules: const GoRules.japanese(),
      );
      expect(suicide.violations.single.code, RuleViolationCode.suicide);
    });

    test('rejects an immediate simple-ko recapture', () {
      final initial = BoardPosition(
        size: BoardSize.nine,
        stones: {
          const BoardPoint(1, 2): StoneColor.black,
          const BoardPoint(2, 1): StoneColor.black,
          const BoardPoint(2, 3): StoneColor.black,
          const BoardPoint(2, 2): StoneColor.white,
          const BoardPoint(3, 1): StoneColor.white,
          const BoardPoint(4, 2): StoneColor.white,
          const BoardPoint(3, 3): StoneColor.white,
        },
      );
      final result = GoRuleValidator.validate(
        initialPosition: initial,
        moves: const [
          Move.play(color: StoneColor.black, point: BoardPoint(3, 2)),
          Move.play(color: StoneColor.white, point: BoardPoint(2, 2)),
        ],
        rules: const GoRules.japanese(),
      );

      expect(result.isValid, isFalse);
      expect(result.violations.single.moveIndex, 1);
      expect(result.violations.single.code, RuleViolationCode.ko);
      expect(
        result.finalPosition.stoneAt(const BoardPoint(3, 2)),
        StoneColor.black,
      );
    });
  });
}
