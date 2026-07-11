import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/infrastructure/io/io.dart';

void main() {
  test('reads a valid image through the bounded stream path', () async {
    final bytes = Uint8List.fromList(
      image_lib.encodePng(image_lib.Image(width: 2, height: 3)),
    );
    final file = _UntrustedImageXFile(
      'valid.png',
      declaredLength: bytes.length,
      bytes: bytes,
      honorRange: true,
    );

    final frame = await CapturedFrameFileReader(
      maximumBytes: bytes.length,
    ).read(file);

    expect(frame.pixelWidth, 2);
    expect(frame.pixelHeight, 3);
    expect(frame.encodedBytes, bytes);
    expect(file.readAsBytesCalled, isFalse);
  });

  test('rejects declared oversize image before opening its stream', () async {
    final file = _UntrustedImageXFile(
      'declared.png',
      declaredLength: 9,
      bytes: Uint8List(0),
    );

    await expectLater(
      const CapturedFrameFileReader(maximumBytes: 8).read(file),
      throwsA(
        isA<BoundedReadLimitException>().having(
          (error) => error.kind,
          'kind',
          BoundedReadLimitKind.declaredLength,
        ),
      ),
    );
    expect(file.openReadCalled, isFalse);
    expect(file.readAsBytesCalled, isFalse);
  });

  test('rejects a growing image at the sentinel byte', () async {
    final file = _UntrustedImageXFile(
      'growing.png',
      declaredLength: 1,
      bytes: Uint8List(40),
    );

    await expectLater(
      const CapturedFrameFileReader(maximumBytes: 8).read(file),
      throwsA(
        isA<BoundedReadLimitException>()
            .having(
              (error) => error.kind,
              'kind',
              BoundedReadLimitKind.streamedLength,
            )
            .having((error) => error.observed, 'observed', 9),
      ),
    );
    expect(file.requestedEnd, 9);
    expect(file.readAsBytesCalled, isFalse);
  });
}

final class _UntrustedImageXFile extends XFile {
  _UntrustedImageXFile(
    super.path, {
    required this.declaredLength,
    required this.bytes,
    this.honorRange = false,
  });

  final int declaredLength;
  final Uint8List bytes;
  final bool honorRange;
  bool openReadCalled = false;
  bool readAsBytesCalled = false;
  int? requestedEnd;

  @override
  Future<int> length() async => declaredLength;

  @override
  Stream<Uint8List> openRead([int? start, int? end]) {
    openReadCalled = true;
    requestedEnd = end;
    final begin = start ?? 0;
    final finish = honorRange ? (end ?? bytes.length) : bytes.length;
    return Stream<Uint8List>.value(
      Uint8List.sublistView(bytes, begin, finish.clamp(begin, bytes.length)),
    );
  }

  @override
  Future<Uint8List> readAsBytes() async {
    readAsBytesCalled = true;
    throw StateError('The bounded image reader must not call readAsBytes.');
  }
}
