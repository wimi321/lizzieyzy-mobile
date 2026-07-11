import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

void main() {
  test('updates a snapshot while preserving its trust type', () async {
    final workspace = KifuWorkspaceController();
    await workspace.initialize();
    final original = PositionSnapshot(
      id: 'position',
      position: BoardPosition.empty(BoardSize.nineteen),
      rules: const GoRules.chinese(),
      source: const KifuSource(kind: KifuSourceKind.camera),
    );
    workspace.add(original);
    final updated = PositionSnapshot(
      id: original.id,
      position: original.position,
      playerToMove: StoneColor.white,
      rules: original.rules,
      source: original.source,
    );

    await workspace.updatePersisted(updated);

    expect(workspace.documents.single, same(updated));
    expect(workspace.selected, same(updated));
    expect(
      (workspace.selected! as PositionSnapshot).playerToMove,
      StoneColor.white,
    );
    workspace.dispose();
  });

  test('an update cannot promote a snapshot to a verified game', () async {
    final workspace = KifuWorkspaceController();
    await workspace.initialize();
    workspace.add(
      PositionSnapshot(
        id: 'same-id',
        position: BoardPosition.empty(BoardSize.nineteen),
        rules: const GoRules.chinese(),
        source: const KifuSource(kind: KifuSourceKind.camera),
      ),
    );
    final game = VerifiedGameRecord(
      id: 'same-id',
      initialPosition: BoardPosition.empty(BoardSize.nineteen),
      moves: const <Move>[
        Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
      ],
      rules: const GoRules.chinese(),
      source: const KifuSource(kind: KifuSourceKind.localFile),
    );

    await expectLater(workspace.updatePersisted(game), throwsArgumentError);

    expect(workspace.documents.single, isA<PositionSnapshot>());
    workspace.dispose();
  });
}
