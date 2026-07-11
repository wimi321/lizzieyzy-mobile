import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/inbound_kifu_controller.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/application/kifu_repository.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';

void main() {
  test('imports and selects a cold-start shared SGF', () async {
    final bridge = _Bridge(
      initial: _payload('cold.sgf', '(;FF[4]GM[1]SZ[19];B[pd];W[dd])'),
    );
    final workspace = KifuWorkspaceController();
    await workspace.initialize();
    final controller = InboundKifuController(
      workspace: workspace,
      service: PlatformInboundKifuService(bridge: bridge),
    );

    await controller.initialize();

    expect(controller.status, InboundKifuStatus.imported);
    expect(controller.lastFileName, 'cold.sgf');
    expect(controller.lastDocument, isA<VerifiedGameRecord>());
    expect(controller.lastDocument!.source.kind, KifuSourceKind.shareSheet);
    expect(workspace.documents, hasLength(1));
    expect(workspace.selected, same(controller.lastDocument));
    controller.dispose();
    workspace.dispose();
    await bridge.close();
  });

  test('serializes runtime files and reports invalid records safely', () async {
    final bridge = _Bridge();
    final workspace = KifuWorkspaceController();
    await workspace.initialize();
    final controller = InboundKifuController(
      workspace: workspace,
      service: PlatformInboundKifuService(bridge: bridge),
    );
    await controller.initialize();

    bridge.add(_payload('broken.sgf', 'not sgf'));
    await _until(() => controller.status == InboundKifuStatus.failed);
    expect(controller.failureCode, InboundKifuFailureCode.invalidFile);

    bridge.add(_payload('valid.gib', 'INI 0 1 0\nSTO 0 1 1 3 3'));
    await _until(() => controller.status == InboundKifuStatus.imported);
    expect(controller.lastFileName, 'valid.gib');
    expect(workspace.documents, hasLength(1));

    controller.clearNotice();
    expect(controller.status, InboundKifuStatus.idle);
    controller.dispose();
    workspace.dispose();
    await bridge.close();
  });

  test('surfaces a native cold-start read failure after mounting', () async {
    final bridge = _Bridge(initial: <String, Object?>{'error': 'unreadable'});
    final workspace = KifuWorkspaceController();
    await workspace.initialize();
    final controller = InboundKifuController(
      workspace: workspace,
      service: PlatformInboundKifuService(bridge: bridge),
    );

    await controller.initialize();

    expect(controller.status, InboundKifuStatus.failed);
    expect(controller.failureCode, InboundKifuFailureCode.platform);
    controller.dispose();
    workspace.dispose();
    await bridge.close();
  });

  test(
    'deduplicated system import exposes the actual workspace document',
    () async {
      final existing = VerifiedGameRecord(
        id: 'existing',
        initialPosition: BoardPosition.empty(BoardSize.nineteen),
        moves: const <Move>[
          Move.play(color: StoneColor.black, point: BoardPoint(15, 3)),
          Move.play(color: StoneColor.white, point: BoardPoint(3, 3)),
        ],
        rules: const GoRules.chinese(),
        source: const KifuSource(kind: KifuSourceKind.localFile),
      );
      final repository = _DeduplicatingRepository(existing);
      final workspace = KifuWorkspaceController(repository: repository);
      await workspace.initialize();
      final bridge = _Bridge(
        initial: _payload(
          'same.sgf',
          '(;FF[4]GM[1]SZ[19]RU[Chinese];B[pd];W[dd])',
        ),
      );
      final controller = InboundKifuController(
        workspace: workspace,
        service: PlatformInboundKifuService(bridge: bridge),
      );

      await controller.initialize();

      expect(controller.status, InboundKifuStatus.imported);
      expect(workspace.documents, hasLength(1));
      expect(workspace.documents.single, same(existing));
      expect(workspace.selected, same(existing));
      expect(controller.lastDocument, same(existing));

      controller.clearNotice();
      bridge.add(
        _payload('same.sgf', '(;FF[4]GM[1]SZ[19]RU[Chinese];B[pd];W[dd])'),
      );
      await _until(() => controller.status == InboundKifuStatus.imported);

      expect(repository.addCount, 2);
      expect(controller.lastDocument, same(existing));
      controller.dispose();
      workspace.dispose();
      await bridge.close();
    },
  );
}

Map<String, Object?> _payload(String name, String text) => <String, Object?>{
  'name': name,
  'bytes': Uint8List.fromList(utf8.encode(text)),
  'action': 'open',
};

Future<void> _until(bool Function() predicate) async {
  for (var attempt = 0; attempt < 100 && !predicate(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  expect(predicate(), isTrue);
}

final class _Bridge implements PlatformInboundKifuBridge {
  _Bridge({this.initial});

  final Object? initial;
  final StreamController<Object?> _events =
      StreamController<Object?>.broadcast();

  @override
  Stream<Object?> get runtimeEvents => _events.stream;

  @override
  Future<Object?> takeInitial() async => initial;

  void add(Object value) => _events.add(value);
  Future<void> close() => _events.close();
}

final class _DeduplicatingRepository implements KifuRepository {
  _DeduplicatingRepository(this.existing);

  final KifuDocument existing;
  var addCount = 0;

  @override
  Future<KifuLoadResult> load() async => KifuLoadResult(
    documents: <KifuDocument>[existing],
    quarantined: const <KifuQuarantineItem>[],
    recoveredFromRedundantIndex: false,
  );

  @override
  Future<KifuWriteResult> add(KifuDocument document) async {
    addCount++;
    return KifuWriteResult(
      disposition: KifuWriteDisposition.duplicate,
      requestedDocumentId: document.id,
      persistedDocumentId: existing.id,
      contentSha256: List<String>.filled(64, 'a').join(),
    );
  }

  @override
  Future<bool> delete(String documentId) async => false;

  @override
  Future<KifuWriteResult> update(KifuDocument document) =>
      throw UnimplementedError();
}
