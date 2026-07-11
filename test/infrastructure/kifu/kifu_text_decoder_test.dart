import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';

import '../../support/gib_encoding_fixtures.dart';

void main() {
  const decoder = KifuTextDecoder();

  test(
    'selects each audited legacy codec by exact round trip and structure',
    () async {
      for (final fixture in await loadGibEncodingFixtures()) {
        final decoded = decoder.decodeGib(fixture.bytes);

        expect(decoded.encoding, fixture.encoding, reason: fixture.id);
        expect(decoded.text, fixture.text, reason: fixture.id);
      }
    },
  );

  test(
    'SGF remains strict UTF-8 even when bytes form valid legacy text',
    () async {
      final fixture = (await loadGibEncodingFixtures()).first;

      expect(
        () => decoder.decodeSgf(fixture.bytes),
        throwsA(isA<KifuTextDecodingException>()),
      );
    },
  );

  test('fails closed when GB18030 and Big5 candidates have equal quality', () {
    final bytes = Uint8List.fromList(<int>[
      ...r'\[GAMEBLACKNAME='.codeUnits,
      0xAA,
      0x40,
      ...r'\]'.codeUnits,
      0x0A,
      ...'INI 0 1 0'.codeUnits,
    ]);

    expect(
      () => decoder.decodeGib(bytes),
      throwsA(isA<AmbiguousKifuTextEncodingException>()),
    );
  });
}
