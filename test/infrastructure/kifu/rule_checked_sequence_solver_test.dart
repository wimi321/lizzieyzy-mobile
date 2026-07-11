import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';

void main() {
  const solver = RuleCheckedSequenceSolver();
  const source = KifuSource(kind: KifuSourceKind.photoLibrary);

  test(
    'sorts a complete continuous sequence and returns a verified record',
    () async {
      final tokens = <SequenceToken>[
        _play(4, StoneColor.white, 5, 5),
        _play(2, StoneColor.white, 6, 6),
        _play(1, StoneColor.black, 2, 2),
        _play(3, StoneColor.black, 3, 3),
      ];

      final result = await solver.solve(
        tokens,
        const GoRules.chinese(),
        documentId: 'verified',
        boardSize: BoardSize.nine,
        source: source,
      );

      expect(result, isA<VerifiedGameRecord>());
      final record = result as VerifiedGameRecord;
      expect(record.moves, hasLength(4));
      expect(record.moves.first.point, const BoardPoint(2, 2));
    },
  );

  test(
    'rejects missing, duplicate, uncertain, and wrong-color tokens',
    () async {
      await _expectCode(
        solver.solve(
          <SequenceToken>[
            _play(1, StoneColor.black, 1, 1),
            _play(3, StoneColor.black, 2, 2),
          ],
          const GoRules.chinese(),
          documentId: 'missing',
          boardSize: BoardSize.nine,
          source: source,
        ),
        SequenceSolveErrorCode.missingMoveNumber,
      );
      await _expectCode(
        solver.solve(
          <SequenceToken>[
            _play(1, StoneColor.black, 1, 1),
            _play(1, StoneColor.black, 2, 2),
          ],
          const GoRules.chinese(),
          documentId: 'duplicate',
          boardSize: BoardSize.nine,
          source: source,
        ),
        SequenceSolveErrorCode.duplicateMoveNumber,
      );
      await _expectCode(
        solver.solve(
          <SequenceToken>[_play(1, StoneColor.black, 1, 1, confidence: 0.89)],
          const GoRules.chinese(),
          documentId: 'uncertain',
          boardSize: BoardSize.nine,
          source: source,
        ),
        SequenceSolveErrorCode.uncertainToken,
      );
      await _expectCode(
        solver.solve(
          <SequenceToken>[
            _play(1, StoneColor.black, 1, 1),
            _play(2, StoneColor.black, 2, 2),
          ],
          const GoRules.chinese(),
          documentId: 'wrong-color',
          boardSize: BoardSize.nine,
          source: source,
        ),
        SequenceSolveErrorCode.wrongColor,
      );
    },
  );

  test('accepts a legal capture followed by same-point reuse', () async {
    final tokens = <SequenceToken>[
      _play(1, StoneColor.black, 0, 0),
      _play(2, StoneColor.white, 1, 0),
      _play(3, StoneColor.black, 8, 8),
      _play(4, StoneColor.white, 0, 1),
      _play(5, StoneColor.black, 2, 0),
      _play(6, StoneColor.white, 7, 8),
      _play(7, StoneColor.black, 1, 1),
      _play(8, StoneColor.white, 7, 7),
      _play(9, StoneColor.black, 0, 2),
      _play(10, StoneColor.white, 6, 8),
      _play(11, StoneColor.black, 0, 0),
    ];

    final result = await solver.solve(
      tokens,
      const GoRules.chinese(),
      documentId: 'reuse',
      boardSize: BoardSize.nine,
      source: source,
    );

    final record = result as VerifiedGameRecord;
    expect(record.moves.first.point, record.moves.last.point);
    expect(
      record.finalPosition.stoneAt(const BoardPoint(0, 0)),
      StoneColor.black,
    );
    expect(record.validation.whiteCaptured, 2);
  });

  test('rejects ko recapture and occupied-point illegality', () async {
    final koInitial = BoardPosition(
      size: BoardSize.nine,
      stones: <BoardPoint, StoneColor>{
        const BoardPoint(1, 2): StoneColor.black,
        const BoardPoint(2, 1): StoneColor.black,
        const BoardPoint(2, 3): StoneColor.black,
        const BoardPoint(2, 2): StoneColor.white,
        const BoardPoint(3, 1): StoneColor.white,
        const BoardPoint(4, 2): StoneColor.white,
        const BoardPoint(3, 3): StoneColor.white,
      },
    );
    await _expectCode(
      solver.solve(
        <SequenceToken>[
          _play(1, StoneColor.black, 3, 2),
          _play(2, StoneColor.white, 2, 2),
        ],
        const GoRules.japanese(),
        documentId: 'ko',
        boardSize: BoardSize.nine,
        source: source,
        initialPosition: koInitial,
      ),
      SequenceSolveErrorCode.illegalSequence,
      moveNumber: 2,
    );
    await _expectCode(
      solver.solve(
        <SequenceToken>[
          _play(1, StoneColor.black, 1, 1),
          _play(2, StoneColor.white, 1, 1),
        ],
        const GoRules.chinese(),
        documentId: 'occupied',
        boardSize: BoardSize.nine,
        source: source,
      ),
      SequenceSolveErrorCode.illegalSequence,
      moveNumber: 2,
    );
  });

  test(
    'enforces move-count and configuration safety limits before replay',
    () async {
      const bounded = RuleCheckedSequenceSolver(maximumMoves: 40);
      final tokens = <SequenceToken>[
        for (var index = 0; index < 41; index++)
          _play(
            index + 1,
            index.isEven ? StoneColor.black : StoneColor.white,
            index % 9,
            index ~/ 9,
          ),
      ];
      await _expectCode(
        bounded.solve(
          tokens,
          const GoRules.chinese(),
          documentId: 'too-many',
          boardSize: BoardSize.nine,
          source: source,
        ),
        SequenceSolveErrorCode.tooManyMoves,
      );
      expect(
        () => const RuleCheckedSequenceSolver(maximumMoves: 39).solve(
          <SequenceToken>[_play(1, StoneColor.black, 1, 1)],
          const GoRules.chinese(),
          documentId: 'bad-config',
          boardSize: BoardSize.nine,
          source: source,
        ),
        throwsArgumentError,
      );
    },
  );
}

SequenceToken _play(
  int number,
  StoneColor color,
  int column,
  int row, {
  double confidence = 0.99,
}) => SequenceToken(
  moveNumber: number,
  move: Move.play(color: color, point: BoardPoint(column, row)),
  confidence: confidence,
);

Future<void> _expectCode(
  Future<KifuDocument> future,
  SequenceSolveErrorCode code, {
  int? moveNumber,
}) => expectLater(
  future,
  throwsA(
    isA<SequenceSolveException>()
        .having((error) => error.code, 'code', code)
        .having(
          (error) => error.moveNumber,
          'moveNumber',
          moveNumber ?? anything,
        ),
  ),
);
