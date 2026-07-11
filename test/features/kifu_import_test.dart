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

void main() {
  test(
    'controller imports SGF and GIB through the same trust boundary',
    () async {
      final sgf = KifuImportController(
        picker: () async =>
            _textFile('game.sgf', '(;FF[4]GM[1]SZ[19]PB[黑]PW[白];B[dd];W[pp])'),
      );
      await sgf.pickAndImport();
      expect(sgf.status, KifuImportStatus.imported, reason: sgf.errorMessage);
      expect(sgf.result?.document, isA<domain.VerifiedGameRecord>());
      expect(sgf.result?.format, KifuFileFormat.sgf);

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

  test('controller cancels cleanly and reports unsupported files', () async {
    final cancelled = KifuImportController(picker: () async => null);
    await cancelled.pickAndImport();
    expect(cancelled.status, KifuImportStatus.idle);

    final unsupported = KifuImportController(
      picker: () async => _textFile('game.txt', 'not a record'),
    );
    await unsupported.pickAndImport();
    expect(unsupported.status, KifuImportStatus.failed);
    expect(unsupported.errorMessage, contains('.sgf'));
  });

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
          home: KifuImportScreen(controller: controller),
        ),
      ),
    );

    expect(find.byType(Scrollable), findsNothing);
    await tester.tap(find.text('选择棋谱文件'));
    await tester.pumpAndSettle();
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
