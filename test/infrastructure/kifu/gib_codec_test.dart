import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';

void main() {
  const codec = GibCodec();

  test('imports a continuous GIB as a verified record with metadata', () {
    final result = codec.decode(r'''
\[GAMEBLACKNAME=山海一局(2段)\]
\[GAMEWHITENAME=清风入弦(1段)\]
\[GAMEINFOMAIN=GRLT:1,ZIPSU:35,GONGJE:65,\]
\[GAMEINFOSUB=GDATE:2026- 7-11- 9-30-00,\]
INI 0 1 0
STO 0 2 1 3 3
STO 0 3 2 15 15
STO 0 4 1 15 3
STO 0 5 2 3 15
''', documentId: 'gib-1');

    expect(result.document, isA<VerifiedGameRecord>());
    final record = result.document as VerifiedGameRecord;
    expect(record.moves, hasLength(4));
    expect(record.metadata.blackPlayer, '山海一局');
    expect(record.metadata.whitePlayer, '清风入弦');
    expect(record.metadata.result?.type, ResultType.whiteWin);
    expect(record.metadata.result?.margin, 3.5);
    expect(record.rules.komi, 6.5);
    expect(result.blackRank, '2段');
    expect(record.metadata.playedAt, DateTime.utc(2026, 7, 11));
  });

  test('downgrades number gaps or illegal sequences to partial records', () {
    final gap = codec.decode(r'''
INI 0 1 0
STO 0 2 1 3 3
STO 0 4 2 15 15
''', documentId: 'gap');
    expect(gap.document, isA<PartialGameRecord>());
    expect(
      gap.warnings.map((warning) => warning.code),
      contains(GibImportWarningCode.moveNumberGap),
    );

    final occupied = codec.decode(r'''
INI 0 1 0
STO 0 2 1 3 3
STO 0 3 2 3 3
''', documentId: 'occupied');
    expect(occupied.document, isA<PartialGameRecord>());
    expect(
      occupied.warnings.map((warning) => warning.code),
      contains(GibImportWarningCode.ruleViolation),
    );

    final midgameFragment = codec.decode(r'''
INI 0 1 0
STO 0 87 1 3 3
STO 0 88 2 15 15
''', documentId: 'midgame-fragment');
    expect(midgameFragment.document, isA<PartialGameRecord>());
    expect(
      (midgameFragment.document as PartialGameRecord).startingMoveNumber,
      87,
    );
    expect(
      midgameFragment.warnings.map((warning) => warning.code),
      contains(GibImportWarningCode.moveNumberGap),
    );

    final wrongFirstPlayer = codec.decode(r'''
INI 0 1 0
STO 0 2 2 15 15
STO 0 3 1 3 3
''', documentId: 'wrong-first-player');
    expect(wrongFirstPlayer.document, isA<PartialGameRecord>());
    expect(
      wrongFirstPlayer.warnings.map((warning) => warning.code),
      contains(GibImportWarningCode.ruleViolation),
    );
  });

  test('imports handicap setup and empty records without inventing moves', () {
    final result = codec.decode(r'''
\[GAMEINFOMAIN=GONGJE:0,\]
INI 0 1 4
''', documentId: 'handicap');

    expect(result.document, isA<PositionSnapshot>());
    final snapshot = result.document as PositionSnapshot;
    expect(snapshot.position.count(StoneColor.black), 4);
    expect(snapshot.playerToMove, StoneColor.white);
    expect(snapshot.rules.komi, 0);

    final unsupported = codec.decode(r'''
INI 0 1 99
STO 0 2 1 3 3
''', documentId: 'unsupported-handicap');
    expect(unsupported.document, isA<PartialGameRecord>());
    expect(
      unsupported.warnings.map((warning) => warning.code),
      contains(GibImportWarningCode.malformedMetadata),
    );
  });

  test('rejects empty text and downgrades malformed move lines safely', () {
    expect(
      () => codec.decode('   ', documentId: 'empty'),
      throwsFormatException,
    );
    final result = codec.decode(
      'INI 0 1 0\nSTO nope\nSTO 0 2 1 3 3',
      documentId: 'malformed',
    );
    expect(result.document, isA<PartialGameRecord>());
    expect(
      result.warnings.map((warning) => warning.code),
      contains(GibImportWarningCode.invalidMove),
    );

    final outOfBoard = codec.decode(
      'INI 0 1 0\nSTO 0 1 1 99 99\nSTO 0 2 1 3 3',
      documentId: 'out-of-board',
    );
    expect(outOfBoard.document, isA<PartialGameRecord>());
    expect(
      outOfBoard.warnings.map((warning) => warning.code),
      contains(GibImportWarningCode.invalidMove),
    );
  });

  test('enforces linear GIB character, line, property, and value budgets', () {
    void expectLimit(
      GibCodec limited,
      String source,
      KifuResourceLimitKind kind,
    ) {
      expect(
        () => limited.decode(source, documentId: 'limited'),
        throwsA(
          isA<KifuResourceLimitException>().having(
            (error) => error.kind,
            'kind',
            kind,
          ),
        ),
      );
    }

    expectLimit(
      const GibCodec(limits: KifuResourceLimits(maxInputCharacters: 8)),
      'INI 0 1 0',
      KifuResourceLimitKind.inputCharacters,
    );
    expectLimit(
      const GibCodec(limits: KifuResourceLimits(maxNodes: 2)),
      'INI 0 1 0\nSTO 0 2 1 3 3\nSTO 0 3 2 15 15',
      KifuResourceLimitKind.nodes,
    );
    expectLimit(
      const GibCodec(limits: KifuResourceLimits(maxMoves: 1)),
      'INI 0 1 0\nSTO 0 2 1 3 3\nSTO 0 3 2 15 15',
      KifuResourceLimitKind.moves,
    );
    expectLimit(
      const GibCodec(limits: KifuResourceLimits(maxPropertyValueCharacters: 8)),
      r'\[GAMENAME=123456789\]',
      KifuResourceLimitKind.propertyValueCharacters,
    );
    expectLimit(
      const GibCodec(
        limits: KifuResourceLimits(maxPropertyValuesPerProperty: 5),
      ),
      'STO 0 2 1 3 3',
      KifuResourceLimitKind.propertyValuesPerProperty,
    );
  });
}
