import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';

void main() {
  const parser = SgfSyntaxParser();

  test('preserves sequences, variations, comments, and escaped values', () {
    final tree = parser.parseSingleGame(r'''(;FF[4]GM[1]SZ[19]C[line one\
line two \] bracket \\ slash];B[pd](;W[dd]C[main])(;W[dp]))''');

    expect(tree.sequence, hasLength(2));
    expect(tree.variations, hasLength(2));
    expect(
      tree.sequence.first['C']!.values.single,
      r'line oneline two ] bracket \ slash',
    );
    expect(tree.variations.first.sequence.single['C']!.values.single, 'main');
  });

  test('parses an SGF collection without merging game trees', () {
    final games = parser.parseCollection(
      '(;FF[4]GM[1]SZ[9];B[aa]) (;FF[4]GM[1]SZ[13];B[bb])',
    );

    expect(games, hasLength(2));
    expect(games.first.sequence.first['SZ']!.values.single, '9');
    expect(games.last.sequence.first['SZ']!.values.single, '13');
  });

  test('reports malformed syntax with a source offset', () {
    expect(
      () => parser.parseSingleGame('(;FF[4]FF[4])'),
      throwsA(
        isA<SgfFormatException>().having(
          (error) => error.offset,
          'offset',
          isNotNull,
        ),
      ),
    );
    expect(
      () => parser.parseSingleGame('(;C[unterminated)'),
      throwsA(isA<SgfFormatException>()),
    );
    expect(
      () => parser.parseSingleGame(''),
      throwsA(isA<SgfFormatException>()),
    );
  });
}
