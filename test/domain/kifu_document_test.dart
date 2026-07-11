import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

import 'test_fixtures.dart';

void main() {
  group('KifuDocument trust boundary', () {
    test('snapshot carries no inferred next player by default', () {
      final snapshot = PositionSnapshot(
        id: 'photo-1',
        position: BoardPosition(
          size: BoardSize.nineteen,
          stones: {const BoardPoint(3, 3): StoneColor.black},
        ),
        rules: testRules,
        source: const KifuSource(kind: KifuSourceKind.camera),
      );

      expect(snapshot.playerToMove, isNull);
      expect(snapshot.boardSize, BoardSize.nineteen);
    });

    test('partial record remains distinct without claiming full validity', () {
      final partial = PartialGameRecord(
        id: 'fragment-1',
        initialPosition: BoardPosition.empty(BoardSize.nine),
        moves: const [
          Move.play(color: StoneColor.white, point: BoardPoint(4, 4)),
        ],
        startingMoveNumber: 88,
        firstPlayer: StoneColor.white,
        rules: testRules,
        source: testSource,
      );

      expect(partial, isA<PartialGameRecord>());
      expect(partial, isNot(isA<VerifiedGameRecord>()));
      expect(partial.startingMoveNumber, 88);
    });

    test('verified record validates sequence and defensively copies moves', () {
      final mutableMoves = <Move>[
        const Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
      ];
      final verified = VerifiedGameRecord(
        id: 'verified-1',
        initialPosition: BoardPosition.empty(BoardSize.nineteen),
        moves: mutableMoves,
        rules: testRules,
        source: testSource,
      );
      mutableMoves.clear();

      expect(verified.moves, hasLength(1));
      expect(verified.validation.isValid, isTrue);
      expect(
        verified.finalPosition.stoneAt(const BoardPoint(3, 3)),
        StoneColor.black,
      );
      expect(() => verified.moves.clear(), throwsUnsupportedError);
    });

    test('invalid sequence cannot be constructed as verified', () {
      expect(
        () => VerifiedGameRecord(
          id: 'invalid',
          initialPosition: BoardPosition.empty(BoardSize.nine),
          moves: const [
            Move.play(color: StoneColor.white, point: BoardPoint(0, 0)),
          ],
          rules: testRules,
          source: testSource,
        ),
        throwsA(
          isA<RuleValidationException>().having(
            (error) => error.result.violations.single.code,
            'violation',
            RuleViolationCode.wrongTurn,
          ),
        ),
      );
    });

    test('sealed hierarchy supports exhaustive product behavior', () {
      String capability(KifuDocument document) => switch (document) {
        PositionSnapshot() => 'position-only',
        PartialGameRecord() => 'partial-review',
        VerifiedGameRecord() => 'full-review',
      };

      expect(capability(verifiedFixture()), 'full-review');
    });
  });
}
