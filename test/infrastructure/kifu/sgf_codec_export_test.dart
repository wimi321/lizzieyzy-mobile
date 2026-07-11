import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';

void main() {
  const codec = SgfCodec();
  const source = KifuSource(kind: KifuSourceKind.fixture);

  test(
    'import-export round trip preserves comments, ranks, and variations',
    () {
      final original = File(
        'test/infrastructure/kifu/fixtures/full_variations.sgf',
      ).readAsStringSync();
      final imported = codec.decode(original, documentId: 'roundtrip');
      final encoded = codec.encode(imported.document);
      final reparsed = codec.decode(encoded, documentId: 'roundtrip-2');

      expect(reparsed.document, isA<VerifiedGameRecord>());
      expect(reparsed.blackRank, '3d');
      expect(reparsed.whiteRank, '1d');
      expect(reparsed.tree.variations, hasLength(2));
      expect(reparsed.tree.sequence.first['C']!.values.single, '根节点注释');
      expect(reparsed.document.metadata.blackPlayer, '黑]棋');
    },
  );

  test('generates deterministic FF4 SGF from a verified record', () {
    final document = VerifiedGameRecord(
      id: 'manual',
      initialPosition: BoardPosition.empty(BoardSize.nineteen),
      moves: const [
        Move.play(color: StoneColor.black, point: BoardPoint(15, 3)),
        Move.pass(color: StoneColor.white),
      ],
      rules: const GoRules.chinese(),
      source: source,
      metadata: GameMetadata(
        blackPlayer: '甲]方',
        whitePlayer: '乙\\方',
        event: '公开赛',
        playedAt: DateTime.utc(2026, 7, 11),
        result: const GameResult(type: ResultType.blackWin, margin: 2.5),
      ),
    );

    final encoded = codec.encode(document, preserveSourceTree: false);

    expect(encoded, startsWith('(;FF[4]GM[1]SZ[19]KM[7.5]RU[Chinese]'));
    expect(encoded, contains(r'PB[甲\]方]'));
    expect(encoded, contains(r'PW[乙\\方]'));
    expect(encoded, contains('DT[2026-07-11]'));
    expect(encoded, contains('RE[B+2.5]'));
    expect(encoded, contains(';B[pd];W[]'));
    final reparsed = codec.decode(encoded, documentId: 'manual-copy');
    expect(reparsed.document, isA<VerifiedGameRecord>());
    expect(reparsed.document.metadata.blackPlayer, '甲]方');
    expect(reparsed.document.metadata.whitePlayer, '乙\\方');
  });

  test('exports a snapshot with setup stones and explicit next player', () {
    final snapshot = PositionSnapshot(
      id: 'snapshot',
      position: BoardPosition(
        size: BoardSize.nine,
        stones: {
          const BoardPoint(0, 0): StoneColor.black,
          const BoardPoint(8, 8): StoneColor.white,
        },
      ),
      rules: const GoRules.japanese(),
      source: source,
      playerToMove: StoneColor.white,
    );

    final encoded = codec.encode(snapshot, preserveSourceTree: false);
    expect(encoded, contains('AB[aa]'));
    expect(encoded, contains('AW[ii]'));
    expect(encoded, contains('PL[W]'));
    final decoded = codec.decode(encoded, documentId: 'snapshot-copy');
    expect(decoded.document, isA<PositionSnapshot>());
    expect(
      (decoded.document as PositionSnapshot).playerToMove,
      StoneColor.white,
    );
  });

  test('exports partial starting move number and collection', () {
    final partial = PartialGameRecord(
      id: 'partial',
      initialPosition: BoardPosition.empty(BoardSize.thirteen),
      moves: const [
        Move.play(color: StoneColor.white, point: BoardPoint(3, 3)),
      ],
      startingMoveNumber: 87,
      firstPlayer: StoneColor.white,
      rules: const GoRules.japanese(),
      source: source,
    );
    final encoded = codec.encode(partial, preserveSourceTree: false);
    expect(encoded, contains('PL[W]'));
    expect(encoded, contains(';W[dd]MN[87]'));

    final tree = const SgfSyntaxParser().parseSingleGame(encoded);
    final collection = codec.encodeCollection([tree, tree]);
    expect(const SgfSyntaxParser().parseCollection(collection), hasLength(2));
  });
}
