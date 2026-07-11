import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';

import '../../support/gib_encoding_fixtures.dart';

void main() {
  test('takes one initial SGF and copies validated platform bytes', () async {
    final bytes = Uint8List.fromList(utf8.encode('(;FF[4]GM[1]SZ[19])'));
    final bridge = _FakeBridge(
      initial: _payload(name: 'Game.SGF', bytes: bytes, action: 'view'),
    );
    final service = PlatformInboundKifuService(bridge: bridge);

    final results = await Future.wait(<Future<PlatformInboundKifuFile?>>[
      service.takeInitial(),
      service.takeInitial(),
    ]);
    bytes.fillRange(0, bytes.length, 0);

    expect(bridge.initialReadCount, 1);
    expect(results.first, same(results.last));
    final file = results.first!;
    expect(file.fileName, 'Game.SGF');
    expect(file.format, PlatformInboundKifuFormat.sgf);
    expect(file.action, PlatformInboundKifuAction.view);
    expect(file.isInitial, isTrue);
    expect(file.text, '(;FF[4]GM[1]SZ[19])');
    expect(file.bytes.first, isNot(0));
    expect(file.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
    await bridge.close();
  });

  test(
    'platform entry decodes every audited legacy GIB encoding end to end',
    () async {
      for (final fixture in await loadGibEncodingFixtures()) {
        final bridge = _FakeBridge(
          initial: _payload(
            name: '${fixture.id}.gib',
            bytes: fixture.bytes,
            action: 'send',
          ),
        );
        final service = PlatformInboundKifuService(bridge: bridge);

        final file = (await service.takeInitial())!;

        expect(file.textEncoding, fixture.encoding, reason: fixture.id);
        expect(file.text, fixture.text, reason: fixture.id);
        expect(file.sha256, fixture.sha256, reason: fixture.id);
        final decoded = const GibCodec().decode(
          file.text,
          documentId: fixture.id,
        );
        expect(decoded.document, isA<VerifiedGameRecord>());
        await bridge.close();
      }
    },
  );

  test('accepts only safe basename-only SGF and GIB names', () async {
    for (final name in <String>[
      '../game.sgf',
      r'..\game.gib',
      'game.txt',
      '.sgf',
      '..',
      'bad\u0000.sgf',
    ]) {
      final bridge = _FakeBridge(
        initial: _payload(name: name, text: '(;FF[4])'),
      );
      final service = PlatformInboundKifuService(bridge: bridge);

      await expectLater(
        service.takeInitial(),
        throwsA(isA<UnsupportedInboundKifuFormatException>()),
      );
      await bridge.close();
    }
  });

  test('repeats byte, character, and strict UTF-8 checks in Dart', () async {
    final oversized = _FakeBridge(
      initial: _payload(name: 'large.sgf', text: '12345'),
    );
    await expectLater(
      PlatformInboundKifuService(
        bridge: oversized,
        limits: const KifuResourceLimits(maxInputBytes: 4),
      ).takeInitial(),
      throwsA(
        isA<KifuResourceLimitException>().having(
          (error) => error.kind,
          'kind',
          KifuResourceLimitKind.inputBytes,
        ),
      ),
    );
    await oversized.close();

    final tooManyCharacters = _FakeBridge(
      initial: _payload(name: 'long.gib', text: '12345'),
    );
    await expectLater(
      PlatformInboundKifuService(
        bridge: tooManyCharacters,
        limits: const KifuResourceLimits(maxInputCharacters: 4),
      ).takeInitial(),
      throwsA(
        isA<KifuResourceLimitException>().having(
          (error) => error.kind,
          'kind',
          KifuResourceLimitKind.inputCharacters,
        ),
      ),
    );
    await tooManyCharacters.close();

    final malformed = _FakeBridge(
      initial: _payload(
        name: 'bad.sgf',
        bytes: Uint8List.fromList(<int>[0xC3, 0x28]),
      ),
    );
    await expectLater(
      PlatformInboundKifuService(bridge: malformed).takeInitial(),
      throwsA(isA<KifuTextDecodingException>()),
    );
    await malformed.close();
  });

  test(
    'delivers an explicit repeat open even when content is identical',
    () async {
      final first = _payload(name: 'first.sgf', text: '(;C[first])');
      final bridge = _FakeBridge(initial: first);
      final service = PlatformInboundKifuService(bridge: bridge);
      final runtime = service.runtimeEvents.first;

      expect(await service.takeInitial(), isNotNull);
      bridge
        ..add(first)
        ..add(
          _payload(name: 'second.sgf', text: '(;C[second])', action: 'send'),
        );

      final delivered = await runtime;
      expect(delivered.fileName, 'first.sgf');
      expect(delivered.text, '(;C[first])');
      expect(delivered.action, PlatformInboundKifuAction.open);
      expect(delivered.isInitial, isFalse);
      await bridge.close();
    },
  );

  test(
    'runtime validation errors do not terminate later valid events',
    () async {
      final bridge = _FakeBridge();
      final service = PlatformInboundKifuService(bridge: bridge);
      final expectation = expectLater(
        service.runtimeEvents,
        emitsInOrder(<Object>[
          emitsError(isA<UnsupportedInboundKifuFormatException>()),
          isA<PlatformInboundKifuFile>().having(
            (file) => file.fileName,
            'fileName',
            'valid.gib',
          ),
        ]),
      );

      bridge
        ..add(_payload(name: '../invalid.sgf', text: '(;)'))
        ..add(_payload(name: 'valid.gib', text: 'INI 0 1 0'));

      await expectation;
      await bridge.close();
    },
  );

  test('rejects malformed channel fields and unknown native actions', () async {
    final wrongBytes = _FakeBridge(
      initial: <String, Object?>{
        'name': 'game.sgf',
        'bytes': <int>[1, 2, 3],
        'action': 'open',
      },
    );
    await expectLater(
      PlatformInboundKifuService(bridge: wrongBytes).takeInitial(),
      throwsA(isA<InvalidInboundKifuPayloadException>()),
    );
    await wrongBytes.close();

    final unknownAction = _FakeBridge(
      initial: _payload(name: 'game.sgf', action: 'preview'),
    );
    await expectLater(
      PlatformInboundKifuService(bridge: unknownAction).takeInitial(),
      throwsA(isA<InvalidInboundKifuPayloadException>()),
    );
    await unknownAction.close();
  });

  test(
    'maps bounded native read failures without accepting extra fields',
    () async {
      final failed = _FakeBridge(
        initial: <String, Object?>{'error': 'unreadable'},
      );
      await expectLater(
        PlatformInboundKifuService(bridge: failed).takeInitial(),
        throwsA(isA<NativeInboundKifuReadException>()),
      );
      await failed.close();

      final malformed = _FakeBridge(
        initial: <String, Object?>{
          'error': 'unreadable',
          'name': 'must-not-leak.sgf',
        },
      );
      await expectLater(
        PlatformInboundKifuService(bridge: malformed).takeInitial(),
        throwsA(isA<InvalidInboundKifuPayloadException>()),
      );
      await malformed.close();
    },
  );

  test('bounds a native initial method call that never completes', () async {
    final bridge = _NeverInitialBridge();
    await expectLater(
      PlatformInboundKifuService(
        bridge: bridge,
        initialReadTimeout: const Duration(milliseconds: 10),
      ).takeInitial(),
      throwsA(isA<NativeInboundKifuReadException>()),
    );
    await bridge.close();
  });

  test(
    'does not suppress consecutive runtime opens of the same file',
    () async {
      final first = _payload(name: 'first.sgf', text: '(;C[first])');
      final bridge = _FakeBridge();
      final service = PlatformInboundKifuService(bridge: bridge);

      final runtime = service.runtimeEvents.take(2).toList();
      bridge
        ..add(first)
        ..add(first);

      expect((await runtime).map((file) => file.fileName), <String>[
        'first.sgf',
        'first.sgf',
      ]);
      await bridge.close();
    },
  );

  test('releases the native event subscription when listeners leave', () async {
    final bridge = _FakeBridge();
    final service = PlatformInboundKifuService(bridge: bridge);

    expect(service.runtimeEvents.isBroadcast, isTrue);
    final subscription = service.runtimeEvents.listen((_) {});
    expect(bridge.listenCount, 1);

    await subscription.cancel();
    expect(bridge.cancelCount, 1);
    await bridge.close();
  });
}

Map<String, Object?> _payload({
  required String name,
  String text = '(;FF[4]GM[1]SZ[19])',
  Uint8List? bytes,
  String action = 'open',
}) => <String, Object?>{
  'name': name,
  'bytes': bytes ?? Uint8List.fromList(utf8.encode(text)),
  'action': action,
};

final class _FakeBridge implements PlatformInboundKifuBridge {
  _FakeBridge({this.initial}) {
    _events = StreamController<Object?>.broadcast(
      onListen: () => listenCount++,
      onCancel: () => cancelCount++,
    );
  }

  final Object? initial;
  late final StreamController<Object?> _events;
  var initialReadCount = 0;
  var listenCount = 0;
  var cancelCount = 0;

  @override
  Future<Object?> takeInitial() async {
    initialReadCount++;
    return initial;
  }

  @override
  Stream<Object?> get runtimeEvents => _events.stream;

  void add(Object? event) => _events.add(event);

  Future<void> close() => _events.close();
}

final class _NeverInitialBridge implements PlatformInboundKifuBridge {
  final Completer<Object?> _initial = Completer<Object?>();
  final StreamController<Object?> _events =
      StreamController<Object?>.broadcast();

  @override
  Future<Object?> takeInitial() => _initial.future;

  @override
  Stream<Object?> get runtimeEvents => _events.stream;

  Future<void> close() => _events.close();
}
