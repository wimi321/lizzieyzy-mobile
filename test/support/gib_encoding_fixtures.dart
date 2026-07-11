import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';

final class GibEncodingFixture {
  const GibEncodingFixture({
    required this.id,
    required this.encoding,
    required this.text,
    required this.bytes,
    required this.sha256,
  });

  final String id;
  final KifuTextEncoding encoding;
  final String text;
  final Uint8List bytes;
  final String sha256;
}

Future<List<GibEncodingFixture>> loadGibEncodingFixtures() async {
  final decoded =
      jsonDecode(
            await File(
              'test/fixtures/gib_legacy_encodings.json',
            ).readAsString(),
          )
          as Map<String, dynamic>;
  if (decoded['schemaVersion'] != 1 || decoded['cases'] is! List) {
    throw const FormatException('Invalid legacy GIB fixture manifest.');
  }
  return <GibEncodingFixture>[
    for (final raw in decoded['cases'] as List<dynamic>)
      _parseFixture((raw as Map).cast<String, dynamic>()),
  ];
}

GibEncodingFixture _parseFixture(Map<String, dynamic> value) {
  final bytes = _decodeHex(value['hex'] as String);
  final expectedSha256 = value['sha256'] as String;
  final actualSha256 = crypto.sha256.convert(bytes).toString();
  if (actualSha256 != expectedSha256) {
    throw FormatException('Fixture ${value['id']} has an invalid SHA-256.');
  }
  return GibEncodingFixture(
    id: value['id'] as String,
    encoding: switch (value['encoding']) {
      'cp949' => KifuTextEncoding.cp949,
      'gb18030' => KifuTextEncoding.gb18030,
      'big5' => KifuTextEncoding.big5,
      _ => throw FormatException(
        'Fixture ${value['id']} uses an unsupported encoding.',
      ),
    },
    text: value['text'] as String,
    bytes: bytes,
    sha256: expectedSha256,
  );
}

Uint8List _decodeHex(String value) {
  if (value.length.isOdd || !RegExp(r'^[0-9a-f]+$').hasMatch(value)) {
    throw const FormatException('Invalid fixture hexadecimal bytes.');
  }
  return Uint8List.fromList(<int>[
    for (var index = 0; index < value.length; index += 2)
      int.parse(value.substring(index, index + 2), radix: 16),
  ]);
}
