import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/features/import/presentation/kifu_import_controller.dart';
import 'package:lizzieyzy_mobile/features/import/presentation/kifu_import_screen.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../support/gib_encoding_fixtures.dart';

void main() {
  test(
    'controller imports SGF and GIB through the same trust boundary',
    () async {
      final sgf = KifuImportController(
        picker: () async =>
            _textFile('game.sgf', '(;FF[4]GM[1]SZ[19]PB[黑]PW[白];B[dd];W[pp])'),
      );
      await sgf.pickAndImport();
      expect(
        sgf.status,
        KifuImportStatus.imported,
        reason: '${sgf.failureCode}',
      );
      expect(sgf.result?.document, isA<domain.VerifiedGameRecord>());
      expect(sgf.result?.format, KifuFileFormat.sgf);
      expect(
        sgf.result?.document.id,
        matches(RegExp(r'^import-[0-9a-f]{64}$')),
      );

      final gib = KifuImportController(
        picker: () async =>
            _textFile('game.gib', 'INI 0 1 0\nSTO 0 2 1 3 3\nSTO 0 3 2 15 15'),
      );
      await gib.pickAndImport();
      expect(gib.status, KifuImportStatus.imported);
      expect(gib.result?.document, isA<domain.VerifiedGameRecord>());
      expect(gib.result?.format, KifuFileFormat.gib);
    },
  );

  test('manual import decodes all audited legacy GIB encodings', () async {
    for (final fixture in await loadGibEncodingFixtures()) {
      final controller = KifuImportController(
        picker: () async => XFile.fromData(
          fixture.bytes,
          path: '${fixture.id}.gib',
          name: '${fixture.id}.gib',
          mimeType: 'application/octet-stream',
        ),
      );
      addTearDown(controller.dispose);

      await controller.pickAndImport();

      expect(
        controller.status,
        KifuImportStatus.imported,
        reason: '${fixture.id}: ${controller.failureCode}',
      );
      expect(controller.result?.format, KifuFileFormat.gib);
      expect(controller.result?.textEncoding, fixture.encoding);
      expect(controller.result?.document, isA<domain.VerifiedGameRecord>());
    }
  });

  test('controller cancels cleanly and reports unsupported files', () async {
    final cancelled = KifuImportController(picker: () async => null);
    await cancelled.pickAndImport();
    expect(cancelled.status, KifuImportStatus.idle);

    final unsupported = KifuImportController(
      picker: () async => _textFile('game.txt', 'not a record'),
    );
    await unsupported.pickAndImport();
    expect(unsupported.status, KifuImportStatus.failed);
    expect(unsupported.failureCode, KifuImportFailureCode.unsupportedFormat);
  });

  test('controller rejects declared oversize before reading bytes', () async {
    final file = _LengthGuardXFile('oversized.sgf', declaredLength: 1024);
    final controller = KifuImportController(
      picker: () async => file,
      limits: const KifuResourceLimits(maxInputBytes: 32),
    );

    await controller.pickAndImport();

    expect(controller.status, KifuImportStatus.failed);
    expect(controller.failureCode, KifuImportFailureCode.resourceLimit);
    expect(file.readAsBytesCalled, isFalse);
    expect(file.openReadCalled, isFalse);
  });

  test(
    'controller rechecks bytes when content grows after length stat',
    () async {
      final controller = KifuImportController(
        picker: () async => XFile.fromData(
          Uint8List.fromList(List<int>.filled(64, 0x20)),
          length: 1,
          path: 'changed.sgf',
          name: 'changed.sgf',
        ),
        limits: const KifuResourceLimits(maxInputBytes: 32),
      );

      await controller.pickAndImport();

      expect(controller.status, KifuImportStatus.failed);
      expect(controller.failureCode, KifuImportFailureCode.resourceLimit);
      expect(controller.result, isNull);
    },
  );

  test(
    'controller rejects malformed UTF-8 instead of replacing bytes',
    () async {
      final controller = KifuImportController(
        picker: () async => XFile.fromData(
          Uint8List.fromList(<int>[0x28, 0xC3, 0x28]),
          path: 'malformed.sgf',
          name: 'malformed.sgf',
          mimeType: 'application/x-go-sgf',
        ),
      );

      await controller.pickAndImport();

      expect(controller.status, KifuImportStatus.failed);
      expect(controller.failureCode, KifuImportFailureCode.invalidEncoding);
      expect(controller.result, isNull);
    },
  );

  testWidgets('import and save complete in one 360x800 viewport', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(360, 800);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });
    final workspace = KifuWorkspaceController();
    addTearDown(workspace.dispose);
    final controller = KifuImportController(
      picker: () async => _textFile(
        '山海一局.sgf',
        '(;FF[4]GM[1]SZ[19]PB[山海一局]PW[清风入弦];B[dd];W[pp])',
      ),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      KifuWorkspace(
        controller: workspace,
        child: MaterialApp(
          theme: LizzieTheme.light(),
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: KifuImportScreen(controller: controller),
        ),
      ),
    );

    expect(find.byType(Scrollable), findsNothing);
    await tester.tap(find.text('选择棋谱文件'));
    await tester.runAsync(() async {
      while (controller.status == KifuImportStatus.picking) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    });
    expect(controller.status, KifuImportStatus.imported);
    await tester.pump();
    expect(find.text('完整棋谱'), findsOneWidget);
    expect(find.text('加入棋谱'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('加入棋谱'));
    await tester.pump();
    expect(find.text('已加入棋谱'), findsOneWidget);
    expect(workspace.documents, hasLength(1));
  });
}

XFile _textFile(String name, String content) => XFile.fromData(
  Uint8List.fromList(utf8.encode(content)),
  path: name,
  name: name,
  mimeType: 'text/plain',
);

final class _LengthGuardXFile extends XFile {
  _LengthGuardXFile(super.path, {required this.declaredLength});

  final int declaredLength;
  bool readAsBytesCalled = false;
  bool openReadCalled = false;

  @override
  Future<int> length() async => declaredLength;

  @override
  Future<Uint8List> readAsBytes() async {
    readAsBytesCalled = true;
    throw StateError('readAsBytes must not run after the length guard fails.');
  }

  @override
  Stream<Uint8List> openRead([int? start, int? end]) {
    openReadCalled = true;
    throw StateError('openRead must not run after the length guard fails.');
  }
}
