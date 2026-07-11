import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';

void main() {
  const codec = SgfCodec();

  String fixture(String name) =>
      File('test/infrastructure/kifu/fixtures/$name').readAsStringSync();

  test('imports metadata, main line, comments, and variations as verified', () {
    final result = codec.decode(
      fixture('full_variations.sgf'),
      documentId: 'full-game',
      kifuSource: const KifuSource(
        kind: KifuSourceKind.localFile,
        reference: 'full_variations.sgf',
      ),
    );

    expect(result.document, isA<VerifiedGameRecord>());
    final document = result.document as VerifiedGameRecord;
    expect(document.moves, hasLength(2));
    expect(document.moves.first.point, const BoardPoint(15, 3));
    expect(document.metadata.blackPlayer, '黑]棋');
    expect(document.metadata.whitePlayer, '白棋');
    expect(document.metadata.event, '测试赛');
    expect(document.metadata.playedAt, DateTime.utc(2026, 7, 11));
    expect(document.metadata.result?.type, ResultType.blackWin);
    expect(document.metadata.result?.reason, 'resign');
    expect(result.blackRank, '3d');
    expect(result.whiteRank, '1d');
    expect(result.tree.variations, hasLength(2));
    expect(result.tree.sequence.first['C']!.values.single, '根节点注释');
    expect(
      result.tree.variations.last.sequence.single['C']!.values.single,
      '备选变化',
    );
    expect(result.warnings, isEmpty);
  });

  test(
    'setup-only SGF becomes a position snapshot without invented history',
    () {
      final result = codec.decode(
        fixture('setup_position.sgf'),
        documentId: 'position',
      );

      expect(result.document, isA<PositionSnapshot>());
      final snapshot = result.document as PositionSnapshot;
      expect(snapshot.position.count(StoneColor.black), 2);
      expect(snapshot.position.count(StoneColor.white), 1);
      expect(snapshot.playerToMove, StoneColor.white);
      expect(snapshot.rules.ruleSet, RuleSet.chinese);
      expect(snapshot.rules.komi, 7.5);
    },
  );

  test('occupied move is detected and downgraded instead of trusted', () {
    final result = codec.decode(
      fixture('duplicate_move.sgf'),
      documentId: 'duplicate',
    );

    expect(result.document, isA<PartialGameRecord>());
    expect(
      result.warnings.map((warning) => warning.code),
      contains(SgfImportWarningCode.duplicateOccupiedPoint),
    );
  });

  test('wrong turn and mid-game setup are downgraded', () {
    final wrongTurn = codec.decode(
      '(;FF[4]GM[1]SZ[19];B[dd];B[pp])',
      documentId: 'wrong-turn',
    );
    expect(wrongTurn.document, isA<PartialGameRecord>());
    expect(
      wrongTurn.warnings.map((warning) => warning.code),
      contains(SgfImportWarningCode.ruleViolation),
    );

    final setup = codec.decode(
      '(;FF[4]GM[1]SZ[19];B[dd];AW[pp];W[pd])',
      documentId: 'mid-setup',
    );
    expect(setup.document, isA<PartialGameRecord>());
    expect(
      setup.warnings.map((warning) => warning.code),
      contains(SgfImportWarningCode.midGameSetup),
    );
  });

  test('does not infer the first player from a fragment first move', () {
    final result = codec.decode(
      '(;FF[4]GM[1]SZ[19];W[dd];B[pp])',
      documentId: 'white-fragment',
    );

    expect(result.document, isA<PartialGameRecord>());
    expect(
      result.warnings.map((warning) => warning.code),
      contains(SgfImportWarningCode.ruleViolation),
    );
  });

  test('validates handicap count, setup color, and first player', () {
    final valid = codec.decode(
      '(;FF[4]GM[1]SZ[19]HA[4]AB[dd][pd][dp][pp];W[jj];B[qq])',
      documentId: 'valid-handicap',
    );
    expect(valid.document, isA<VerifiedGameRecord>());
    expect(
      (valid.document as VerifiedGameRecord).firstPlayer,
      StoneColor.white,
    );

    for (final source in <String>[
      '(;FF[4]GM[1]SZ[19]HA[4]AB[dd][pd][dp];W[jj])',
      '(;FF[4]GM[1]SZ[19]HA[4]AB[dd][pd][dp][pp]AW[jj];W[qq])',
      '(;FF[4]GM[1]SZ[19]HA[4]PL[B]AB[dd][pd][dp][pp];B[jj])',
    ]) {
      final mismatch = codec.decode(source, documentId: 'bad-handicap');
      expect(mismatch.document, isA<PartialGameRecord>());
      expect(
        mismatch.warnings.map((warning) => warning.code),
        contains(SgfImportWarningCode.handicapMismatch),
      );
    }
  });

  test('rejects negative handicap values', () {
    expect(
      () => codec.decode(
        '(;FF[4]GM[1]SZ[19]HA[-1])',
        documentId: 'negative-handicap',
      ),
      throwsA(isA<SgfFormatException>()),
    );
  });

  test('non-one move numbering remains an explicit partial record', () {
    final result = codec.decode(
      '(;FF[4]GM[1]SZ[19];B[dd]MN[87];W[pd])',
      documentId: 'fragment',
    );

    expect(result.document, isA<PartialGameRecord>());
    expect((result.document as PartialGameRecord).startingMoveNumber, 87);
    expect(
      result.warnings.map((warning) => warning.code),
      contains(SgfImportWarningCode.moveNumberGap),
    );
  });

  test('empty move value is a legal pass', () {
    final result = codec.decode(
      '(;FF[4]GM[1]SZ[19];B[];W[dd])',
      documentId: 'pass',
    );

    expect(result.document, isA<VerifiedGameRecord>());
    expect((result.document as VerifiedGameRecord).moves.first.isPass, isTrue);
  });

  test('invalid coordinates and conflicting setup are fatal', () {
    for (final source in [
      '(;FF[4]GM[1]SZ[19];B[zz])',
      '(;FF[4]GM[1]SZ[9]AB[aa][aa])',
      '(;FF[4]GM[1]SZ[19]AB[dd]AW[dd])',
      '(;FF[4]GM[1]SZ[19]AB[aa:zz])',
    ]) {
      expect(
        () => codec.decode(source, documentId: 'invalid'),
        throwsA(isA<SgfFormatException>()),
      );
    }
  });

  test('requires FF4 Go and a supported square board', () {
    for (final source in [
      '(;FF[3]GM[1]SZ[19])',
      '(;FF[4]GM[2]SZ[19])',
      '(;FF[4]GM[1]SZ[11])',
      '(;FF[4]GM[1]SZ[19:19])',
    ]) {
      expect(
        () => codec.decode(source, documentId: 'unsupported'),
        throwsA(isA<SgfFormatException>()),
      );
    }
  });

  test('defaults omitted root identifiers and normalizes them for export', () {
    final result = codec.decode('(;C[minimal];B[dd])', documentId: 'minimal');

    expect(result.document, isA<VerifiedGameRecord>());
    final root = result.tree.sequence.first;
    expect(root['FF']!.values.single, '4');
    expect(root['GM']!.values.single, '1');
    expect(root['SZ']!.values.single, '19');
  });

  test('collection imports first game and reports ignored games', () {
    final result = codec.decode(
      '(;FF[4]GM[1]SZ[9];B[aa])(;FF[4]GM[1]SZ[13];B[bb])',
      documentId: 'collection',
    );

    expect(result.document.boardSize, BoardSize.nine);
    expect(
      result.warnings.map((warning) => warning.code),
      contains(SgfImportWarningCode.additionalGamesIgnored),
    );
  });

  test('unknown rules do not produce a falsely verified record', () {
    final result = codec.decode(
      '(;FF[4]GM[1]SZ[19]RU[Server House Rules];B[dd];W[pd])',
      documentId: 'unknown-rules',
    );

    expect(result.document, isA<PartialGameRecord>());
    expect(
      result.warnings.map((warning) => warning.code),
      contains(SgfImportWarningCode.unknownRules),
    );
  });

  test(
    'invalid alternate variation is reported without distrusting main line',
    () {
      final result = codec.decode(
        '(;FF[4]GM[1]SZ[19];B[dd](;W[pp])(;W[dd]))',
        documentId: 'bad-variation',
      );

      expect(result.document, isA<VerifiedGameRecord>());
      expect(
        result.warnings.map((warning) => warning.code),
        contains(SgfImportWarningCode.duplicateOccupiedPoint),
      );
    },
  );

  test('invalid calendar dates remain preserved but are not normalized', () {
    final result = codec.decode(
      '(;FF[4]GM[1]SZ[19]DT[2026-02-31];B[dd])',
      documentId: 'invalid-date',
    );

    expect(result.document.metadata.playedAt, isNull);
    expect(result.tree.sequence.first['DT']!.values.single, '2026-02-31');
  });

  test('bounds main-line moves and aggregate variation replay work', () {
    const moveLimited = SgfCodec(
      syntaxParser: SgfSyntaxParser(limits: KifuResourceLimits(maxMoves: 2)),
    );
    expect(
      () => moveLimited.decode(
        '(;FF[4]GM[1]SZ[9];B[aa];W[bb];B[cc])',
        documentId: 'too-many-moves',
      ),
      throwsA(
        isA<KifuResourceLimitException>().having(
          (error) => error.kind,
          'kind',
          KifuResourceLimitKind.moves,
        ),
      ),
    );

    const replayLimited = SgfCodec(
      syntaxParser: SgfSyntaxParser(
        limits: KifuResourceLimits(maxReplayWork: 7),
      ),
    );
    expect(
      () => replayLimited.decode(
        '(;FF[4]GM[1]SZ[9];B[aa](;W[bb];B[cc])(;W[cc];B[bb]))',
        documentId: 'too-many-branches',
      ),
      throwsA(
        isA<KifuResourceLimitException>().having(
          (error) => error.kind,
          'kind',
          KifuResourceLimitKind.replayWork,
        ),
      ),
    );
  });
}
