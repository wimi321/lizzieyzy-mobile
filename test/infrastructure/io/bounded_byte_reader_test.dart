import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/infrastructure/io/io.dart';

void main() {
  test('rejects declared oversize before opening the stream', () async {
    final source = _FakeSource(
      declaredLength: 11,
      chunks: <Uint8List>[Uint8List(1)],
    );

    await expectLater(
      readBoundedBytes(source, maximumBytes: 10),
      throwsA(
        isA<BoundedReadLimitException>()
            .having(
              (error) => error.kind,
              'kind',
              BoundedReadLimitKind.declaredLength,
            )
            .having((error) => error.observed, 'observed', 11),
      ),
    );

    expect(source.openCalls, 0);
  });

  test(
    'cancels at limit plus one when a growing source ignores range',
    () async {
      final source = _FakeSource(
        declaredLength: 2,
        chunks: <Uint8List>[
          Uint8List.fromList(<int>[1, 2, 3]),
          Uint8List.fromList(<int>[4, 5, 6, 7, 8]),
          Uint8List.fromList(<int>[9, 10, 11, 12]),
        ],
      );

      await expectLater(
        readBoundedBytes(source, maximumBytes: 6),
        throwsA(
          isA<BoundedReadLimitException>()
              .having(
                (error) => error.kind,
                'kind',
                BoundedReadLimitKind.streamedLength,
              )
              .having((error) => error.observed, 'observed', 7),
        ),
      );

      expect(source.requestedStart, 0);
      expect(source.requestedEndExclusive, 7);
      expect(source.cancelled, isTrue);
    },
  );

  test('accepts an exact-limit stream', () async {
    final source = _FakeSource(
      declaredLength: 6,
      chunks: <Uint8List>[
        Uint8List.fromList(<int>[1, 2]),
        Uint8List.fromList(<int>[3, 4, 5, 6]),
      ],
    );

    expect(await readBoundedBytes(source, maximumBytes: 6), <int>[
      1,
      2,
      3,
      4,
      5,
      6,
    ]);
  });
}

final class _FakeSource implements BoundedByteSource {
  _FakeSource({required this.declaredLength, required this.chunks});

  final int declaredLength;
  final List<Uint8List> chunks;
  var openCalls = 0;
  var cancelled = false;
  int? requestedStart;
  int? requestedEndExclusive;

  @override
  Future<int> length() async => declaredLength;

  @override
  Stream<Uint8List> openRead(int start, int endExclusive) {
    openCalls++;
    requestedStart = start;
    requestedEndExclusive = endExclusive;
    late final StreamController<Uint8List> controller;
    controller = StreamController<Uint8List>(
      onListen: () {
        scheduleMicrotask(() async {
          for (final chunk in chunks) {
            if (controller.isClosed) return;
            controller.add(chunk);
          }
          if (!controller.isClosed) await controller.close();
        });
      },
      onCancel: () {
        cancelled = true;
      },
    );
    return controller.stream;
  }
}
