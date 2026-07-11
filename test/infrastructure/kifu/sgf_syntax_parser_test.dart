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

  test('rejects input, node, property, and value resource exhaustion', () {
    void expectLimit(
      SgfSyntaxParser limited,
      String source,
      KifuResourceLimitKind kind,
    ) {
      expect(
        () => limited.parseSingleGame(source),
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
      const SgfSyntaxParser(limits: KifuResourceLimits(maxInputCharacters: 12)),
      '(;C[more than twelve])',
      KifuResourceLimitKind.inputCharacters,
    );
    expectLimit(
      const SgfSyntaxParser(limits: KifuResourceLimits(maxNodes: 2)),
      '(;B[aa];W[bb];B[cc])',
      KifuResourceLimitKind.nodes,
    );
    expectLimit(
      const SgfSyntaxParser(
        limits: KifuResourceLimits(maxPropertiesPerNode: 2),
      ),
      '(;A[1]B[2]C[3])',
      KifuResourceLimitKind.propertiesPerNode,
    );
    expectLimit(
      const SgfSyntaxParser(
        limits: KifuResourceLimits(maxPropertyValueCharacters: 8),
      ),
      '(;C[123456789])',
      KifuResourceLimitKind.propertyValueCharacters,
    );
    expectLimit(
      const SgfSyntaxParser(
        limits: KifuResourceLimits(maxPropertyValuesPerProperty: 2),
      ),
      '(;AB[aa][bb][cc])',
      KifuResourceLimitKind.propertyValuesPerProperty,
    );
  });

  test(
    'bounds variation recursion before adversarial nesting reaches stack',
    () {
      const attemptedDepth = 512;
      final source =
          List<String>.filled(attemptedDepth, '(;C[x]').join() +
          List<String>.filled(attemptedDepth, ')').join();

      expect(
        () => parser.parseSingleGame(source),
        throwsA(
          isA<KifuResourceLimitException>()
              .having(
                (error) => error.kind,
                'kind',
                KifuResourceLimitKind.variationDepth,
              )
              .having((error) => error.actual, 'actual', 129),
        ),
      );
    },
  );
}
