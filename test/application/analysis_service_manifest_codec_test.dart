import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/io/io.dart';
import 'package:lizzieyzy_mobile/infrastructure/settings/settings.dart';

void main() {
  const codec = AnalysisServiceManifestCodec(maximumBytes: 2048);

  test('imports a versioned manifest and injects the secret separately', () {
    final profile = codec.decode(
      utf8.encode(
        jsonEncode(<String, Object>{
          'schemaVersion': 1,
          'endpoint': 'wss://analysis.example.test/v1',
          'reportAnalysisWinratesAs': 'SIDETOMOVE',
          'model': <String, Object>{
            'id': 'katago-b18',
            'displayName': 'KataGo b18',
            'sha256': 'c' * 64,
            'engineVersion': '1.16.5',
            'modelVersion': 'b18c384',
            'license': 'CC-BY-4.0',
            'source': 'https://example.test/models/b18',
            'humanModelSha256': 'd' * 64,
            'humanStyleRanks': <String>['3k', '1d'],
          },
        }),
      ),
      bearerToken: 'secret',
    );

    expect(profile.endpoint.scheme, 'wss');
    expect(profile.winRatePerspective, AnalysisWinRatePerspective.sideToMove);
    expect(profile.model.humanStyleRanks, [GoRank.kyu(3), GoRank.dan(1)]);
    expect(profile.model.humanModelSha256, 'd' * 64);
    expect(profile.bearerToken, 'secret');
  });

  test('rejects embedded secrets, oversized files, and invalid hashes', () {
    List<int> manifest(Map<String, Object?> additions) => utf8.encode(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'endpoint': 'wss://analysis.example.test',
        'reportAnalysisWinratesAs': 'BLACK',
        'model': <String, Object>{
          'id': 'model',
          'displayName': 'Model',
          'sha256': 'a' * 64,
          'engineVersion': '1.0',
          'modelVersion': '1',
          'license': 'MIT',
        },
        ...additions,
      }),
    );

    expect(
      () => codec.decode(manifest({'token': 'nope'})),
      throwsFormatException,
    );
    expect(
      () => codec.decode(manifest({'unreviewedCapability': true})),
      throwsFormatException,
    );
    expect(
      () => codec.decode(List<int>.filled(2049, 0)),
      throwsFormatException,
    );
    expect(
      () => codec.decode(
        utf8.encode(
          jsonEncode(<String, Object>{
            'schemaVersion': 1,
            'endpoint': 'wss://analysis.example.test',
            'reportAnalysisWinratesAs': 'BLACK',
            'model': <String, Object>{
              'id': 'model',
              'displayName': 'Model',
              'sha256': 'not-a-hash',
              'engineVersion': '1.0',
              'modelVersion': '1',
              'license': 'MIT',
            },
          }),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => codec.decode(
        manifest({
          'model': <String, Object>{
            'id': 'human-model',
            'displayName': 'Human model',
            'sha256': 'a' * 64,
            'engineVersion': '1.0',
            'modelVersion': '1',
            'license': 'MIT',
            'humanStyleRanks': <String>['1k'],
          },
        }),
      ),
      throwsFormatException,
    );
  });

  test('file loader rejects declared and streamed manifest growth', () async {
    const loader = AnalysisServiceManifestFileLoader(codec: codec);
    final declared = _UntrustedXFile(
      'declared.json',
      declaredLength: codec.maximumBytes + 1,
      bytes: Uint8List(0),
    );
    await expectLater(
      loader.load(declared),
      throwsA(
        isA<BoundedReadLimitException>().having(
          (error) => error.kind,
          'kind',
          BoundedReadLimitKind.declaredLength,
        ),
      ),
    );
    expect(declared.openReadCalled, isFalse);

    final growing = _UntrustedXFile(
      'growing.json',
      declaredLength: 1,
      bytes: Uint8List(codec.maximumBytes + 50),
    );
    await expectLater(
      loader.load(growing),
      throwsA(
        isA<BoundedReadLimitException>()
            .having(
              (error) => error.kind,
              'kind',
              BoundedReadLimitKind.streamedLength,
            )
            .having(
              (error) => error.observed,
              'observed',
              codec.maximumBytes + 1,
            ),
      ),
    );
    expect(growing.requestedEnd, codec.maximumBytes + 1);
  });
}

final class _UntrustedXFile extends XFile {
  _UntrustedXFile(
    super.path, {
    required this.declaredLength,
    required this.bytes,
  });

  final int declaredLength;
  final Uint8List bytes;
  bool openReadCalled = false;
  int? requestedEnd;

  @override
  Future<int> length() async => declaredLength;

  @override
  Stream<Uint8List> openRead([int? start, int? end]) {
    openReadCalled = true;
    requestedEnd = end;
    // Deliberately ignores the requested range to emulate a lying provider or
    // a file that grows between stat and read.
    return Stream<Uint8List>.value(bytes);
  }

  @override
  Future<Uint8List> readAsBytes() async =>
      throw StateError('The bounded loader must not call readAsBytes.');
}
