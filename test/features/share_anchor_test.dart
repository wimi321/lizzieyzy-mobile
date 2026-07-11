import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/kifu_export_scope.dart';
import 'package:lizzieyzy_mobile/application/kifu_export_service.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart'
    show LizzieTheme;
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/features/import/presentation/partial_record_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/key_move_review_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/tablet_review_screen.dart';

import '../support/review_screen_fixture.dart';

void main() {
  testWidgets('key-move share uses the laid-out button global anchor', (
    tester,
  ) async {
    await _setView(tester, const Size(393, 852));
    final export = _RecordingExportService();
    await tester.pumpWidget(
      _host(export, KeyMoveReviewScreen(data: reviewScreenFixture())),
    );
    await tester.pumpAndSettle();
    final button = find.byTooltip('导出棋谱');

    await tester.tap(button);
    await tester.pumpAndSettle();

    _expectButtonAnchor(tester, export.singleAnchor, button);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet share supplies a non-empty iPad popover anchor', (
    tester,
  ) async {
    await _setView(tester, const Size(1024, 768));
    final export = _RecordingExportService();
    await tester.pumpWidget(
      _host(export, TabletReviewScreen(data: reviewScreenFixture())),
    );
    await tester.pumpAndSettle();
    final button = find.byTooltip('导出棋谱');

    await tester.tap(button);
    await tester.pumpAndSettle();

    final anchor = export.singleAnchor;
    _expectButtonAnchor(tester, anchor, button);
    expect(anchor.left + anchor.width, lessThanOrEqualTo(1024));
    expect(anchor.top + anchor.height, lessThanOrEqualTo(768));
    expect(tester.takeException(), isNull);
  });

  testWidgets('partial-record share uses its visible action global anchor', (
    tester,
  ) async {
    await _setView(tester, const Size(393, 852));
    final export = _RecordingExportService();
    await tester.pumpWidget(
      _host(export, PartialRecordScreen(record: _partialRecord())),
    );
    await tester.pumpAndSettle();
    final button = find.widgetWithText(OutlinedButton, '导出原记录');

    await tester.tap(button);
    await tester.pumpAndSettle();

    _expectButtonAnchor(tester, export.singleAnchor, button);
    expect(tester.takeException(), isNull);
  });
}

Widget _host(_RecordingExportService export, Widget child) => KifuExportScope(
  service: export,
  child: MaterialApp(theme: LizzieTheme.light(), home: child),
);

Future<void> _setView(WidgetTester tester, Size size) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  tester.platformDispatcher.localesTestValue = const <Locale>[Locale('zh')];
  addTearDown(() {
    tester.view
      ..resetDevicePixelRatio()
      ..resetPhysicalSize();
    tester.platformDispatcher.clearLocalesTestValue();
  });
}

void _expectButtonAnchor(
  WidgetTester tester,
  ShareAnchor anchor,
  Finder button,
) {
  final topLeft = tester.getTopLeft(button);
  final size = tester.getSize(button);
  expect(anchor.left.isFinite, isTrue);
  expect(anchor.top.isFinite, isTrue);
  expect(anchor.width, greaterThan(0));
  expect(anchor.height, greaterThan(0));
  expect(anchor.left, closeTo(topLeft.dx, 0.01));
  expect(anchor.top, closeTo(topLeft.dy, 0.01));
  expect(anchor.width, closeTo(size.width, 0.01));
  expect(anchor.height, closeTo(size.height, 0.01));
}

final class _RecordingExportService implements KifuExportService {
  final List<ShareAnchor?> anchors = <ShareAnchor?>[];

  ShareAnchor get singleAnchor {
    expect(anchors, hasLength(1));
    expect(anchors.single, isNotNull);
    return anchors.single!;
  }

  @override
  Future<KifuShareOutcome> share(
    KifuDocument document, {
    ShareAnchor? anchor,
  }) async {
    anchors.add(anchor);
    return KifuShareOutcome.dismissed;
  }
}

PartialGameRecord _partialRecord() => PartialGameRecord(
  id: 'partial-share-anchor',
  initialPosition: BoardPosition.empty(BoardSize.nineteen),
  moves: const <Move>[
    Move.play(color: StoneColor.white, point: BoardPoint(3, 3)),
  ],
  rules: const GoRules.chinese(),
  source: const KifuSource(kind: KifuSourceKind.localFile),
  startingMoveNumber: 87,
  firstPlayer: StoneColor.white,
);
