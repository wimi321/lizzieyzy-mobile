import 'dart:convert';
import 'dart:typed_data';

import 'package:big5_utf8_converter/big5_utf8_converter.dart' as big5;
import 'package:charset/charset.dart' as charset;
import 'package:cp949_codec/cp949_codec.dart' as korean;

import '../../domain/domain.dart';
import 'gib_codec.dart';
import 'kifu_resource_limits.dart';

enum KifuTextEncoding {
  utf8('UTF-8'),
  cp949('CP949'),
  gb18030('GB18030 / GBK'),
  big5('Big5');

  const KifuTextEncoding(this.label);

  final String label;
}

final class DecodedKifuText {
  const DecodedKifuText({required this.text, required this.encoding});

  final String text;
  final KifuTextEncoding encoding;
}

final class AmbiguousKifuTextEncodingException extends FormatException {
  const AmbiguousKifuTextEncodingException()
    : super('The GIB text encoding is ambiguous.');
}

/// Deterministic, platform-independent decoding for imported kifu bytes.
///
/// SGF remains strict UTF-8. Legacy decoding is available only for GIB and
/// accepts a candidate only when decoding is strict, re-encoding reproduces
/// the exact input, and the resulting text passes the real [GibCodec]
/// structure/rule boundary. Near-tied legacy candidates fail closed.
final class KifuTextDecoder {
  const KifuTextDecoder({
    this.limits = const KifuResourceLimits(),
    this.gibCodec = const GibCodec(),
  });

  final KifuResourceLimits limits;
  final GibCodec gibCodec;

  DecodedKifuText decodeSgf(List<int> bytes) {
    final text = _strictUtf8(bytes);
    limits.enforceInputCharacters(text.length);
    return DecodedKifuText(text: text, encoding: KifuTextEncoding.utf8);
  }

  DecodedKifuText decodeGib(List<int> bytes) {
    // Strict UTF-8 is authoritative whenever it is well formed. A malformed
    // GIB then remains a record-format error instead of being reinterpreted as
    // an unrelated legacy charset.
    try {
      final text = _strictUtf8(bytes);
      limits.enforceInputCharacters(text.length);
      return DecodedKifuText(text: text, encoding: KifuTextEncoding.utf8);
    } on KifuTextDecodingException {
      // Continue through the explicit legacy allowlist only.
    }

    final input = Uint8List.fromList(bytes);
    final candidates = <_LegacyCandidate>[];
    for (final encoding in const <KifuTextEncoding>[
      KifuTextEncoding.cp949,
      KifuTextEncoding.gb18030,
      KifuTextEncoding.big5,
    ]) {
      try {
        final text = _decodeLegacy(input, encoding);
        limits.enforceInputCharacters(text.length);
        if (!_isExactRoundTrip(input, text, encoding) ||
            !_hasSafeText(text) ||
            !_hasGibStructure(text)) {
          continue;
        }
        gibCodec.decode(
          text,
          documentId: '__encoding_probe__',
          kifuSource: const KifuSource(kind: KifuSourceKind.localFile),
        );
        candidates.add(
          _LegacyCandidate(
            text: text,
            encoding: encoding,
            score: _textQualityScore(text, encoding),
          ),
        );
      } on Object {
        // Strict conversion, exact round trip, syntax, and resource failures
        // all disqualify only this candidate.
      }
    }

    if (candidates.isEmpty) throw const KifuTextDecodingException();
    candidates.sort((left, right) => right.score.compareTo(left.score));
    if (candidates.length > 1 &&
        candidates.first.score - candidates[1].score < 12) {
      throw const AmbiguousKifuTextEncodingException();
    }
    final selected = candidates.first;
    return DecodedKifuText(text: selected.text, encoding: selected.encoding);
  }
}

String _strictUtf8(List<int> bytes) {
  try {
    final decoded = utf8.decode(bytes, allowMalformed: false);
    return decoded.startsWith('\uFEFF') ? decoded.substring(1) : decoded;
  } on FormatException {
    throw const KifuTextDecodingException();
  }
}

String _decodeLegacy(Uint8List bytes, KifuTextEncoding encoding) =>
    switch (encoding) {
      KifuTextEncoding.cp949 => korean.cp949.decode(bytes, allowInvalid: false),
      KifuTextEncoding.gb18030 => _decodeGb18030(bytes),
      KifuTextEncoding.big5 => big5.Big5Decoder().convert(bytes),
      KifuTextEncoding.utf8 => throw StateError('UTF-8 is decoded separately.'),
    };

bool _isExactRoundTrip(
  Uint8List input,
  String text,
  KifuTextEncoding encoding,
) {
  late final List<int> encoded;
  try {
    encoded = switch (encoding) {
      KifuTextEncoding.cp949 => korean.cp949.encode(text),
      KifuTextEncoding.gb18030 => _encodeGb18030(text),
      KifuTextEncoding.big5 => big5.Big5Encoder().encode(text),
      KifuTextEncoding.utf8 => utf8.encode(text),
    };
  } on Object {
    return false;
  }
  if (encoded.length != input.length) return false;
  for (var index = 0; index < encoded.length; index++) {
    if (encoded[index] != input[index]) return false;
  }
  return true;
}

bool _hasSafeText(String text) {
  for (final rune in text.runes) {
    if (rune == 0xFFFD ||
        rune == 0 ||
        (rune < 0x20 && rune != 0x09 && rune != 0x0A && rune != 0x0D) ||
        (rune >= 0xD800 && rune <= 0xDFFF) ||
        (rune >= 0xE000 && rune <= 0xF8FF) ||
        (rune >= 0xF0000 && rune <= 0xFFFFD) ||
        (rune >= 0x100000 && rune <= 0x10FFFD) ||
        rune == 0x202E ||
        rune == 0x202D ||
        rune == 0x2066 ||
        rune == 0x2067 ||
        rune == 0x2068 ||
        rune == 0x2069) {
      return false;
    }
  }
  return true;
}

bool _hasGibStructure(String text) {
  var recognized = 0;
  for (final rawLine in const LineSplitter().convert(text)) {
    final line = rawLine.trim();
    if (line.startsWith('INI ') ||
        line.startsWith('STO ') ||
        RegExp(r'^\\\[[A-Z0-9_]+=.*\\\]$').hasMatch(line)) {
      recognized++;
    }
  }
  return recognized > 0;
}

int _textQualityScore(String text, KifuTextEncoding encoding) {
  var score = 0;
  var scoredNonAscii = 0;
  for (final rune in text.runes) {
    if (rune <= 0x7F) continue;
    if (scoredNonAscii++ >= 64) continue;
    final hangul =
        (rune >= 0x1100 && rune <= 0x11FF) ||
        (rune >= 0xAC00 && rune <= 0xD7AF);
    final compatibilityJamo = rune >= 0x3130 && rune <= 0x318F;
    final han =
        (rune >= 0x3400 && rune <= 0x4DBF) ||
        (rune >= 0x4E00 && rune <= 0x9FFF) ||
        (rune >= 0xF900 && rune <= 0xFAFF) ||
        (rune >= 0x20000 && rune <= 0x323AF);
    final kana = rune >= 0x3040 && rune <= 0x30FF;
    final ordinary =
        (rune >= 0x00A0 && rune <= 0x02FF) ||
        (rune >= 0x2000 && rune <= 0x206F) ||
        (rune >= 0x3000 && rune <= 0x303F) ||
        (rune >= 0xFF00 && rune <= 0xFFEF);
    if (hangul) {
      score += encoding == KifuTextEncoding.cp949 ? 14 : -5;
    } else if (compatibilityJamo) {
      // Standalone compatibility jamo are legal but uncommon in player/event
      // names. Legacy Chinese byte pairs frequently become accidental jamo
      // under CP949, so they are deliberately weak—not decisive—evidence.
      score += encoding == KifuTextEncoding.cp949 ? 2 : -5;
    } else if (han) {
      score += encoding == KifuTextEncoding.cp949 ? 2 : 5;
      final character = String.fromCharCode(rune);
      if (_simplifiedEvidence.contains(character)) {
        score += encoding == KifuTextEncoding.gb18030 ? 10 : -6;
      }
      if (_traditionalEvidence.contains(character)) {
        score += encoding == KifuTextEncoding.big5 ? 10 : -6;
      }
    } else if (kana) {
      score -= 2;
    } else if (ordinary) {
      score += 1;
    } else {
      score -= 4;
    }
  }
  return score;
}

const _simplifiedEvidence = '国汉龙马门风云东书车长张刘陈赵孙吴郑冯卫杨许苏叶钟万与为发后里这来时对开关胜';
const _traditionalEvidence = '國漢龍馬門風雲東書車長張劉陳趙孫吳鄭馮衛楊許蘇葉鐘萬與為發後裡這來時對開關勝';

final class _LegacyCandidate {
  const _LegacyCandidate({
    required this.text,
    required this.encoding,
    required this.score,
  });

  final String text;
  final KifuTextEncoding encoding;
  final int score;
}

String _decodeGb18030(Uint8List bytes) {
  final output = StringBuffer();
  var index = 0;
  while (index < bytes.length) {
    final first = bytes[index];
    if (first <= 0x7F) {
      output.writeCharCode(first);
      index++;
      continue;
    }
    if (first == 0x80) {
      output.writeCharCode(0x20AC);
      index++;
      continue;
    }
    if (first < 0x81 || first > 0xFE || index + 1 >= bytes.length) {
      throw const FormatException('Invalid GB18030 lead byte.');
    }
    final second = bytes[index + 1];
    if (second >= 0x30 && second <= 0x39) {
      if (index + 3 >= bytes.length) {
        throw const FormatException('Incomplete GB18030 four-byte sequence.');
      }
      final third = bytes[index + 2];
      final fourth = bytes[index + 3];
      if (third < 0x81 || third > 0xFE || fourth < 0x30 || fourth > 0x39) {
        throw const FormatException('Invalid GB18030 four-byte sequence.');
      }
      final pointer =
          (((first - 0x81) * 10 + (second - 0x30)) * 126 + (third - 0x81)) *
              10 +
          (fourth - 0x30);
      final codePoint = _gb18030CodePointFor(pointer);
      if (codePoint == null) {
        throw const FormatException('Unmapped GB18030 pointer.');
      }
      output.writeCharCode(codePoint);
      index += 4;
      continue;
    }
    if (second < 0x40 || second > 0xFE || second == 0x7F) {
      throw const FormatException('Invalid GB18030 trail byte.');
    }
    output.write(
      const charset.GbkCodec(
        allowMalformed: false,
      ).decode(<int>[first, second], allowMalformed: false),
    );
    index += 2;
  }
  return output.toString();
}

List<int> _encodeGb18030(String text) {
  final output = BytesBuilder(copy: false);
  for (final rune in text.runes) {
    if (rune <= 0x7F) {
      output.addByte(rune);
      continue;
    }
    if (rune == 0x20AC) {
      output.addByte(0x80);
      continue;
    }
    final character = String.fromCharCode(rune);
    final gbk = const charset.GbkCodec().encode(character);
    try {
      if (gbk.length == 2 &&
          const charset.GbkCodec(
                allowMalformed: false,
              ).decode(gbk, allowMalformed: false) ==
              character) {
        output.add(gbk);
        continue;
      }
    } on Object {
      // Continue with the standard four-byte range mapping.
    }
    final pointer = _gb18030PointerFor(rune);
    if (pointer == null) {
      throw FormatException(
        'Unicode U+${rune.toRadixString(16)} is not representable in GB18030.',
      );
    }
    var remainder = pointer;
    final fourth = remainder % 10 + 0x30;
    remainder ~/= 10;
    final third = remainder % 126 + 0x81;
    remainder ~/= 126;
    final second = remainder % 10 + 0x30;
    remainder ~/= 10;
    final first = remainder + 0x81;
    if (first > 0xFE) throw const FormatException('GB18030 pointer overflow.');
    output.add(<int>[first, second, third, fourth]);
  }
  return output.takeBytes();
}

int? _gb18030CodePointFor(int pointer) {
  if (pointer < 0 || pointer > 1237575) return null;
  var lower = 0;
  var upper = _gb18030Ranges.length - 1;
  while (lower <= upper) {
    final middle = (lower + upper) >> 1;
    if (_gb18030Ranges[middle].$1 <= pointer) {
      lower = middle + 1;
    } else {
      upper = middle - 1;
    }
  }
  if (upper < 0) return null;
  final range = _gb18030Ranges[upper];
  final codePoint = range.$2 + pointer - range.$1;
  if (codePoint > 0x10FFFF || (codePoint >= 0xD800 && codePoint <= 0xDFFF)) {
    return null;
  }
  return codePoint;
}

int? _gb18030PointerFor(int codePoint) {
  if (codePoint < 0x80 ||
      codePoint > 0x10FFFF ||
      (codePoint >= 0xD800 && codePoint <= 0xDFFF)) {
    return null;
  }
  var lower = 0;
  var upper = _gb18030Ranges.length - 1;
  while (lower <= upper) {
    final middle = (lower + upper) >> 1;
    if (_gb18030Ranges[middle].$2 <= codePoint) {
      lower = middle + 1;
    } else {
      upper = middle - 1;
    }
  }
  if (upper < 0) return null;
  final range = _gb18030Ranges[upper];
  final pointer = range.$1 + codePoint - range.$2;
  final nextPointer = upper + 1 < _gb18030Ranges.length
      ? _gb18030Ranges[upper + 1].$1
      : 1237576;
  return pointer < nextPointer ? pointer : null;
}

/// WHATWG Encoding Standard, index-gb18030-ranges.txt, 2024-09-18,
/// identifier f963aaa1653f630c523e7b04729fb4e4458f35806c45eb5c179445623138f0c0.
/// The incorporated source-code data is available under BSD-3-Clause per the
/// Encoding Standard copyright notice.
final List<(int, int)> _gb18030Ranges = _parseGb18030Ranges();

List<(int, int)> _parseGb18030Ranges() {
  final values = _gb18030RangeData
      .trim()
      .split(RegExp(r'\s+'))
      .map((value) => int.parse(value, radix: 16))
      .toList(growable: false);
  return <(int, int)>[
    for (var index = 0; index < values.length; index += 2)
      (values[index], values[index + 1]),
  ];
}

// Pointer and Unicode scalar pairs, both encoded as hexadecimal to keep the
// checked-in standard data compact and reviewable.
const _gb18030RangeData = '''
0 80 24 A5 26 A9 2D B2 32 B8 51 D8 59 E2 5F EB 60 EE 64 F4 67 F8
68 FB 69 FD 6D 102 7E 114 85 11C 94 12C AC 145 AF 149 B3 14E D0 16C
132 1CF 133 1D1 134 1D3 135 1D5 136 1D7 137 1D9 138 1DB 139 1DD
155 1FA 1AC 252 1BB 262 220 2C8 221 2CC 22E 2DA 2E5 3A2 2E6 3AA
2ED 3C2 2EE 3CA 325 402 333 450 334 452 1EF2 2011 1EF4 2017
1EF5 201A 1EF7 201E 1EFE 2027 1F07 2031 1F08 2034 1F09 2036
1F0E 203C 1F7E 20AD 1FD4 2104 1FD5 2106 1FD8 210A 1FE4 2117
1FEE 2122 202C 216C 2030 217A 2046 2194 2048 219A 20B6 2209
20BC 2210 20BD 2212 20C0 2216 20C4 221B 20C6 2221 20C8 2224
20C9 2226 20CA 222C 20CC 222F 20D1 2238 20D6 223E 20E0 2249
20E3 224D 20E8 2253 20F5 2262 20F7 2268 20FD 2270 2122 2296
2125 229A 2130 22A6 2149 22C0 219B 2313 22E8 246A 22F2 249C
2356 254C 235A 2574 2367 2590 236A 2596 2374 25A2 2384 25B4
238C 25BE 2394 25C8 2397 25CC 2399 25D0 23AB 25E6 23CA 2607
23CC 260A 2402 2641 2403 2643 2C41 2E82 2C43 2E85 2C46 2E89
2C48 2E8D 2C52 2E98 2C61 2EA8 2C63 2EAB 2C66 2EAF 2C6A 2EB4
2C6C 2EB8 2C6F 2EBC 2C7D 2ECB 2DA2 2FFC 2DA6 3004 2DA7 3018
2DAC 301F 2DAE 302A 2DC2 303F 2DC4 3094 2DCB 309F 2DCD 30F7
2DD2 30FF 2DD8 312A 2ECE 322A 2ED5 3232 2F46 32A4 3030 3390
303C 339F 303E 33A2 3060 33C5 3069 33CF 306B 33D3 306D 33D6
30DE 3448 3109 3474 3233 359F 32A2 360F 32AD 361B 35AA 3919
35FF 396F 365F 39D1 366D 39E0 3700 3A74 37DA 3B4F 38F9 3C6F
396A 3CE1 3CDF 4057 3DE7 4160 3FBE 4338 4032 43AD 4036 43B2
4061 43DE 4159 44D7 42CE 464D 42E2 4662 43A3 4724 43A8 472A
43FA 477D 440A 478E 45C3 4948 45F5 497B 45F7 497E 45FB 4984
45FC 4987 4610 499C 4613 49A0 4629 49B8 48E8 4C78 490F 4CA4
497E 4D1A 4A12 4DAF 4A63 9FA6 82BD E76C 82BE E7C8 82BF E7E7
82CC E815 82CD E819 82D2 E81F 82D9 E827 82DD E82D 82E1 E833
82E9 E83C 82F0 E844 8300 E856 830E E865 93D5 F92D 9421 F97A
943C F996 948D F9E8 9496 F9F2 94B0 FA10 94B1 FA12 94B2 FA15
94B5 FA19 94BB FA22 94BC FA25 94BE FA2A 98C4 FE32 98C5 FE45
98C9 FE53 98CA FE58 98CB FE67 98CC FE6C 9961 FF5F 99E2 FFE6
2E248 10000
''';
