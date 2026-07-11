import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/kifu_repository.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';
import 'package:lizzieyzy_mobile/infrastructure/persistence/persistence.dart';

void main() {
  group('KifuContentIdentity', () {
    test('matches the standard SHA-256 vector', () {
      expect(
        KifuContentIdentity.sha256Sgf('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });
  });

  group('FileKifuRepository', () {
    late Directory supportDirectory;

    setUp(() async {
      supportDirectory = await Directory.systemTemp.createTemp(
        'lizzieyzy-kifu-repository-',
      );
    });

    tearDown(() async {
      if (await supportDirectory.exists()) {
        await supportDirectory.delete(recursive: true);
      }
    });

    FileKifuRepository repository({
      KifuRepositoryAtomicWriteHook? atomicWriteHook,
      SgfCodec codec = const SgfCodec(),
    }) => FileKifuRepository(
      supportDirectoryProvider: () async => supportDirectory,
      clock: () => DateTime.utc(2026, 7, 11, 10, 30),
      atomicWriteHook: atomicWriteHook,
      codec: codec,
    );

    test(
      'survives a repository restart without changing trust or source',
      () async {
        final original = _game(
          id: 'restart-game',
          source: const KifuSource(
            kind: KifuSourceKind.localFile,
            reference: 'final.sgf',
          ),
        );
        final first = repository();

        final write = await first.add(original);
        expect(write.disposition, KifuWriteDisposition.added);

        final restarted = repository();
        final loaded = await restarted.load();

        expect(loaded.documents, hasLength(1));
        final document = loaded.documents.single;
        expect(document, isA<VerifiedGameRecord>());
        expect(document.id, 'restart-game');
        expect(document.source.kind, KifuSourceKind.localFile);
        expect(document.source.reference, 'final.sgf');
        expect(document.metadata.blackPlayer, '山海一局');
        expect((document as VerifiedGameRecord).moves, hasLength(2));
        expect(loaded.quarantined, isEmpty);
      },
    );

    test('preserves snapshot and partial trust types across restart', () async {
      final store = repository();
      await store.add(
        PositionSnapshot(
          id: 'snapshot',
          position: BoardPosition(
            size: BoardSize.nine,
            stones: <BoardPoint, StoneColor>{
              const BoardPoint(0, 0): StoneColor.black,
              const BoardPoint(8, 8): StoneColor.white,
            },
          ),
          rules: const GoRules.chinese(),
          source: const KifuSource(kind: KifuSourceKind.camera),
          playerToMove: StoneColor.white,
        ),
      );
      await store.add(
        PartialGameRecord(
          id: 'partial',
          initialPosition: BoardPosition.empty(BoardSize.thirteen),
          moves: const <Move>[
            Move.play(color: StoneColor.white, point: BoardPoint(3, 3)),
          ],
          rules: const GoRules.japanese(),
          source: const KifuSource(kind: KifuSourceKind.shareSheet),
          startingMoveNumber: 87,
          firstPlayer: StoneColor.white,
        ),
      );

      final byId = <String, KifuDocument>{
        for (final document in (await repository().load()).documents)
          document.id: document,
      };

      expect(byId['snapshot'], isA<PositionSnapshot>());
      expect(
        (byId['snapshot']! as PositionSnapshot).playerToMove,
        StoneColor.white,
      );
      expect(byId['partial'], isA<PartialGameRecord>());
      expect((byId['partial']! as PartialGameRecord).startingMoveNumber, 87);
    });

    test(
      'persists amended snapshot truth without stale source setup',
      () async {
        final store = repository();
        final imported = store.codec.decode(
          '(;FF[4]GM[1]SZ[19]C[root](;AB[dd]C[setup]))',
          documentId: 'amended-snapshot',
        );
        final original = imported.document as PositionSnapshot;
        await store.add(original);
        await store.update(
          PositionSnapshot(
            id: original.id,
            position: original.position,
            rules: original.rules,
            source: original.source,
            metadata: original.metadata,
            sourceSgf: original.sourceSgf,
            playerToMove: StoneColor.white,
          ),
        );

        final loaded = await repository().load();
        expect(loaded.quarantined, isEmpty);
        final snapshot = loaded.documents.single as PositionSnapshot;
        expect(snapshot.position.count(StoneColor.black), 1);
        expect(snapshot.playerToMove, StoneColor.white);
        expect(snapshot.sourceSgf!.sequence.first['C']!.values.single, 'root');
        expect(
          snapshot
              .sourceSgf!
              .variations
              .single
              .sequence
              .single['C']!
              .values
              .single,
          'setup',
        );
      },
    );

    test('deduplicates identical SGF content even when ids differ', () async {
      final store = repository();
      await store.add(_game(id: 'original'));

      final duplicate = await store.add(_game(id: 'duplicate'));

      expect(duplicate.disposition, KifuWriteDisposition.duplicate);
      expect(duplicate.requestedDocumentId, 'duplicate');
      expect(duplicate.persistedDocumentId, 'original');
      expect((await store.load()).documents, hasLength(1));
      expect(await _documentFiles(supportDirectory), hasLength(1));
    });

    test('updates atomically and deletes both index entry and SGF', () async {
      final store = repository();
      await store.add(_game(id: 'mutable'));
      final updated = _game(
        id: 'mutable',
        moves: const <Move>[
          Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
          Move.play(color: StoneColor.white, point: BoardPoint(15, 15)),
          Move.play(color: StoneColor.black, point: BoardPoint(15, 3)),
          Move.play(color: StoneColor.white, point: BoardPoint(3, 15)),
        ],
      );

      final update = await store.update(updated);
      expect(update.disposition, KifuWriteDisposition.updated);
      final afterRestart = await repository().load();
      expect(
        (afterRestart.documents.single as VerifiedGameRecord).moves,
        hasLength(4),
      );
      expect(await _documentFiles(supportDirectory), hasLength(1));

      expect(await store.delete('mutable'), isTrue);
      expect(await store.delete('mutable'), isFalse);
      expect((await repository().load()).documents, isEmpty);
      expect(await _documentFiles(supportDirectory), isEmpty);
    });

    test(
      'rolls back add memory and content when the first index commit fails',
      () async {
        final fault = _AtomicWriteFault();
        final store = repository(atomicWriteHook: fault.call);
        await store.load();

        fault.failIndexWriteAfter();
        await expectLater(
          store.add(_game(id: 'retry-add')),
          throwsA(isA<FileSystemException>()),
        );
        expect(await _documentFiles(supportDirectory), isEmpty);
        expect(
          await _indexedDocumentIds(supportDirectory),
          everyElement(isEmpty),
        );

        final retry = await store.add(_game(id: 'retry-add'));
        expect(retry.disposition, KifuWriteDisposition.added);
        final restarted = await repository().load();
        expect(restarted.documents.single.id, 'retry-add');
        expect(await _documentFiles(supportDirectory), hasLength(1));
      },
    );

    test(
      'rolls back update memory and new content when first commit fails',
      () async {
        final fault = _AtomicWriteFault();
        final store = repository(atomicWriteHook: fault.call);
        await store.add(_game(id: 'retry-update'));
        final updated = _game(
          id: 'retry-update',
          moves: const <Move>[
            Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
            Move.play(color: StoneColor.white, point: BoardPoint(15, 15)),
            Move.play(color: StoneColor.black, point: BoardPoint(15, 3)),
            Move.play(color: StoneColor.white, point: BoardPoint(3, 15)),
          ],
        );

        fault.failIndexWriteAfter();
        await expectLater(
          store.update(updated),
          throwsA(isA<FileSystemException>()),
        );
        expect(await _documentFiles(supportDirectory), hasLength(1));
        expect(
          await _indexedDocumentIds(supportDirectory),
          everyElement(equals(<String>{'retry-update'})),
        );

        final retry = await store.update(updated);
        expect(retry.disposition, KifuWriteDisposition.updated);
        final restarted = await repository().load();
        expect(
          (restarted.documents.single as VerifiedGameRecord).moves,
          hasLength(4),
        );
        expect(await _documentFiles(supportDirectory), hasLength(1));
      },
    );

    test('does not publish a delete whose first index commit fails', () async {
      final fault = _AtomicWriteFault();
      final store = repository(atomicWriteHook: fault.call);
      await store.add(_game(id: 'retry-delete'));

      fault.failIndexWriteAfter();
      await expectLater(
        store.delete('retry-delete'),
        throwsA(isA<FileSystemException>()),
      );
      expect(await _documentFiles(supportDirectory), hasLength(1));
      expect(
        await _indexedDocumentIds(supportDirectory),
        everyElement(equals(<String>{'retry-delete'})),
      );

      expect(await store.delete('retry-delete'), isTrue);
      expect(await store.delete('retry-delete'), isFalse);
      expect((await repository().load()).documents, isEmpty);
      expect(await _documentFiles(supportDirectory), isEmpty);
    });

    test(
      'returns success after the commit point when redundant healing fails',
      () async {
        final fault = _AtomicWriteFault();
        final store = repository(atomicWriteHook: fault.call);
        await store.load();

        fault.failIndexWriteAfter(successfulWrites: 1);
        final write = await store.add(_game(id: 'committed-once'));
        expect(write.disposition, KifuWriteDisposition.added);
        final duplicate = await store.add(_game(id: 'same-content'));
        expect(duplicate.disposition, KifuWriteDisposition.duplicate);
        expect(duplicate.persistedDocumentId, 'committed-once');

        final restarted = await repository().load();
        expect(restarted.documents.single.id, 'committed-once');
        expect(restarted.recoveredFromRedundantIndex, isTrue);
      },
    );

    test('quarantines a corrupted SGF and repairs the index', () async {
      final store = repository();
      await store.add(_game(id: 'corrupt-content'));
      final content = (await _documentFiles(supportDirectory)).single;
      await content.writeAsString('not the committed SGF', flush: true);

      final recovered = await repository().load();

      expect(recovered.documents, isEmpty);
      expect(
        recovered.quarantined.map((item) => item.reason),
        contains(KifuQuarantineReason.contentHashMismatch),
      );
      expect(recovered.recoveredFromRedundantIndex, isTrue);
      expect(await _documentFiles(supportDirectory), isEmpty);
      expect(await _quarantineFiles(supportDirectory), isNotEmpty);

      final stableRestart = await repository().load();
      expect(stableRestart.documents, isEmpty);
      expect(stableRestart.quarantined, isEmpty);
    });

    test('bounded load quarantines an oversized persisted SGF', () async {
      final store = repository();
      await store.add(_game(id: 'oversized-content'));
      final content = (await _documentFiles(supportDirectory)).single;
      await content.writeAsBytes(List<int>.filled(65, 0x20), flush: true);
      final limitedCodec = SgfCodec(
        syntaxParser: SgfSyntaxParser(
          limits: const KifuResourceLimits(maxInputBytes: 64),
        ),
      );

      final recovered = await repository(codec: limitedCodec).load();

      expect(recovered.documents, isEmpty);
      expect(
        recovered.quarantined.map((item) => item.reason),
        contains(KifuQuarantineReason.resourceLimitExceeded),
      );
      expect(await _documentFiles(supportDirectory), isEmpty);
      expect(await _quarantineFiles(supportDirectory), isNotEmpty);
    });

    test(
      'recovers from a torn index slot and stale atomic temp file',
      () async {
        final store = repository();
        await store.add(_game(id: 'atomic-game'));
        final indexes = await _indexFiles(supportDirectory);
        expect(indexes, hasLength(2));
        final generations = <File, int>{};
        for (final file in indexes) {
          final json =
              jsonDecode(await file.readAsString()) as Map<String, Object?>;
          generations[file] = json['generation']! as int;
        }
        final newest = generations.entries
            .reduce((left, right) => left.value > right.value ? left : right)
            .key;
        await newest.writeAsString('{"schemaVersion":1', flush: true);
        final stale = File('${newest.parent.path}/index.pending.json.tmp');
        await stale.writeAsString('partial', flush: true);

        final recovered = await repository().load();

        expect(recovered.documents.single.id, 'atomic-game');
        expect(recovered.recoveredFromRedundantIndex, isTrue);
        expect(
          recovered.quarantined.map((item) => item.reason),
          containsAll(<KifuQuarantineReason>[
            KifuQuarantineReason.corruptIndex,
            KifuQuarantineReason.staleAtomicWrite,
          ]),
        );
        final healedIndexes = await _indexFiles(supportDirectory);
        expect(healedIndexes, hasLength(2));
        for (final file in healedIndexes) {
          final json =
              jsonDecode(await file.readAsString()) as Map<String, Object?>;
          expect(json['indexSha256'], isA<String>());
          expect(json['entries'], hasLength(1));
        }
      },
    );

    test('quarantines an unindexed SGF left before index commit', () async {
      final store = repository();
      await store.load();
      final committed = _game(id: 'never-committed');
      final sgf = store.codec.encode(committed);
      final digest = KifuContentIdentity.sha256Sgf(sgf);
      final documents = await _documentsDirectory(supportDirectory);
      await File(
        '${documents.path}/$digest.sgf',
      ).writeAsString(sgf, flush: true);

      final recovered = await repository().load();

      expect(recovered.documents, isEmpty);
      expect(
        recovered.quarantined.map((item) => item.reason),
        contains(KifuQuarantineReason.unindexedContent),
      );
      expect(await _documentFiles(supportDirectory), isEmpty);
    });
  });
}

VerifiedGameRecord _game({
  required String id,
  KifuSource source = const KifuSource(kind: KifuSourceKind.fixture),
  List<Move> moves = const <Move>[
    Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
    Move.play(color: StoneColor.white, point: BoardPoint(15, 15)),
  ],
}) => VerifiedGameRecord(
  id: id,
  initialPosition: BoardPosition.empty(BoardSize.nineteen),
  moves: moves,
  rules: const GoRules.japanese(),
  source: source,
  metadata: const GameMetadata(blackPlayer: '山海一局', whitePlayer: '清风入弦'),
);

Future<List<File>> _allFiles(Directory root) async => <File>[
  await for (final entity in root.list(recursive: true))
    if (entity is File) entity,
];

Future<List<File>> _indexFiles(Directory root) async => (await _allFiles(root))
    .where(
      (file) =>
          !file.path.contains(
            '${Platform.pathSeparator}quarantine${Platform.pathSeparator}',
          ) &&
          RegExp(r'index\.[01]\.json$').hasMatch(file.path),
    )
    .toList();

Future<List<Set<String>>> _indexedDocumentIds(Directory root) async =>
    <Set<String>>[
      for (final file in await _indexFiles(root))
        <String>{
          for (final entry
              in (jsonDecode(await file.readAsString())
                      as Map<String, Object?>)['entries']!
                  as List<Object?>)
            (entry! as Map<String, Object?>)['documentId']! as String,
        },
    ];

Future<List<File>> _documentFiles(Directory root) async =>
    (await _allFiles(root))
        .where(
          (file) =>
              file.path.contains(
                '${Platform.pathSeparator}documents${Platform.pathSeparator}',
              ) &&
              file.path.endsWith('.sgf'),
        )
        .toList();

Future<List<File>> _quarantineFiles(Directory root) async =>
    (await _allFiles(root))
        .where(
          (file) => file.path.contains(
            '${Platform.pathSeparator}quarantine${Platform.pathSeparator}',
          ),
        )
        .toList();

Future<Directory> _documentsDirectory(Directory root) async {
  await for (final entity in root.list(recursive: true)) {
    if (entity is Directory &&
        entity.path.endsWith('${Platform.pathSeparator}documents')) {
      return entity;
    }
  }
  throw StateError('The repository did not create its documents directory.');
}

final class _AtomicWriteFault {
  int? _successfulIndexWritesBeforeFailure;

  void failIndexWriteAfter({int successfulWrites = 0}) {
    if (successfulWrites < 0) {
      throw ArgumentError.value(successfulWrites, 'successfulWrites');
    }
    _successfulIndexWritesBeforeFailure = successfulWrites;
  }

  void call(File destination) {
    if (!RegExp(r'index\.[01]\.json$').hasMatch(destination.path)) return;
    final remaining = _successfulIndexWritesBeforeFailure;
    if (remaining == null) return;
    if (remaining > 0) {
      _successfulIndexWritesBeforeFailure = remaining - 1;
      return;
    }
    _successfulIndexWritesBeforeFailure = null;
    throw FileSystemException(
      'Injected atomic index write failure.',
      destination.path,
    );
  }
}
