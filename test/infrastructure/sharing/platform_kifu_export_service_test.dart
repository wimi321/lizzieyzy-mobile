import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/kifu_export_service.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/sharing/sharing.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  late Directory temporary;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('lizzieyzy-share-test-');
  });

  tearDown(() async {
    if (await temporary.exists()) await temporary.delete(recursive: true);
  });

  test('exports deterministic SGF and supplies an iPad-safe anchor', () async {
    ShareParams? captured;
    final service = PlatformKifuExportService(
      temporaryDirectoryProvider: () async => temporary,
      clock: () => DateTime.utc(2026, 7, 11),
      shareSheetInvoker: (params) async {
        captured = params;
        return const ShareResult('test', ShareResultStatus.success);
      },
    );

    final outcome = await service.share(
      _record(),
      anchor: const ShareAnchor(left: 10, top: 20, width: 48, height: 48),
    );

    expect(outcome, KifuShareOutcome.success);
    expect(captured, isNotNull);
    expect(captured!.sharePositionOrigin, const Rect.fromLTWH(10, 20, 48, 48));
    expect(captured!.files, hasLength(1));
    final file = File(captured!.files!.single.path);
    expect(await file.exists(), isTrue);
    final sgf = await file.readAsString();
    expect(sgf, contains('PB[黑/手]'));
    expect(sgf, contains(';B[dd]'));
    expect(file.uri.pathSegments.last, startsWith('黑_手-vs-白方-LizzieYZY-'));
  });

  test(
    'lifecycle cleanup removes owned SGF and only marked plugin copies',
    () async {
      final now = DateTime.utc(2026, 7, 11, 12);
      final stale = now.subtract(const Duration(hours: 25));
      final ownedDirectory = Directory(
        '${temporary.path}${Platform.pathSeparator}lizzieyzy-share',
      );
      final pluginDirectory = Directory(
        '${temporary.path}${Platform.pathSeparator}share_plus',
      );
      await ownedDirectory.create();
      await pluginDirectory.create();

      final staleOwned = await _writeAt(
        ownedDirectory,
        'match-LizzieYZY-1720000000000.sgf',
        stale,
      );
      final freshOwned = await _writeAt(
        ownedDirectory,
        'fresh-LizzieYZY-1720000000001.sgf',
        now,
      );
      final legacyOwned = await _writeAt(
        ownedDirectory,
        'legacy-player-vs-player-1720000000002.sgf',
        stale,
      );
      final unrelatedOwnedBinary = await _writeAt(
        ownedDirectory,
        'legacy-player-vs-player-1720000000002.bin',
        stale,
      );
      final stalePluginCopy = await _writeAt(
        pluginDirectory,
        'match-LizzieYZY-1720000000000.sgf',
        stale,
      );
      final unrelatedSgf = await _writeAt(
        pluginDirectory,
        'another-feature-1720000000000.sgf',
        stale,
      );
      final unrelatedBinary = await _writeAt(
        pluginDirectory,
        'match-LizzieYZY-1720000000000.bin',
        stale,
      );
      final nested = Directory(
        '${pluginDirectory.path}${Platform.pathSeparator}foreign',
      );
      await nested.create();
      final nestedMarked = await _writeAt(
        nested,
        'nested-LizzieYZY-1720000000000.sgf',
        stale,
      );

      final service = PlatformKifuExportService(
        temporaryDirectoryProvider: () async => temporary,
        clock: () => now,
      );
      await service.cleanupStaleArtifacts();

      expect(await staleOwned.exists(), isFalse);
      expect(await stalePluginCopy.exists(), isFalse);
      expect(await legacyOwned.exists(), isFalse);
      expect(await freshOwned.exists(), isTrue);
      expect(await unrelatedOwnedBinary.exists(), isTrue);
      expect(await unrelatedSgf.exists(), isTrue);
      expect(await unrelatedBinary.exists(), isTrue);
      expect(await nestedMarked.exists(), isTrue);
    },
  );

  test('lifecycle cleanup has a shared scan and deletion budget', () async {
    final now = DateTime.utc(2026, 7, 11, 12);
    final directory = Directory(
      '${temporary.path}${Platform.pathSeparator}lizzieyzy-share',
    );
    await directory.create();
    for (var index = 0; index < 6; index++) {
      await _writeAt(
        directory,
        'game-$index-LizzieYZY-${1720000000000 + index}.sgf',
        now.subtract(const Duration(days: 2)),
      );
    }
    final service = PlatformKifuExportService(
      temporaryDirectoryProvider: () async => temporary,
      clock: () => now,
      maxCleanupEntries: 6,
      maxCleanupDeletes: 2,
    );

    await service.cleanupStaleArtifacts();

    expect(await directory.list().where((entity) => entity is File).length, 4);
  });

  test('lifecycle cleanup is fail-safe when the cache root is unavailable', () {
    final service = PlatformKifuExportService(
      temporaryDirectoryProvider: () async =>
          throw FileSystemException('unavailable'),
    );

    expect(service.cleanupStaleArtifacts(), completes);
  });

  test(
    'maps dismissed and platform failures without leaking raw errors',
    () async {
      final dismissed = PlatformKifuExportService(
        temporaryDirectoryProvider: () async => temporary,
        shareSheetInvoker: (_) async =>
            const ShareResult('', ShareResultStatus.dismissed),
      );
      expect(await dismissed.share(_record()), KifuShareOutcome.dismissed);

      final failing = PlatformKifuExportService(
        temporaryDirectoryProvider: () async => temporary,
        shareSheetInvoker: (_) async => throw StateError('platform detail'),
      );
      await expectLater(
        failing.share(_record()),
        throwsA(isA<KifuExportShareException>()),
      );
    },
  );
}

Future<File> _writeAt(
  Directory directory,
  String name,
  DateTime modified,
) async {
  final file = File('${directory.path}${Platform.pathSeparator}$name');
  await file.writeAsString('artifact');
  await file.setLastModified(modified);
  return file;
}

VerifiedGameRecord _record() => VerifiedGameRecord(
  id: 'game',
  initialPosition: BoardPosition.empty(BoardSize.nineteen),
  moves: const <Move>[
    Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
    Move.play(color: StoneColor.white, point: BoardPoint(15, 15)),
  ],
  rules: const GoRules(
    ruleSet: RuleSet.chinese,
    komi: 7.5,
    koRule: KoRule.situationalSuperko,
    allowSuicide: false,
  ),
  source: const KifuSource(kind: KifuSourceKind.localFile),
  metadata: const GameMetadata(blackPlayer: '黑/手', whitePlayer: '白方'),
);
