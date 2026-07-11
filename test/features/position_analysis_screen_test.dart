import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/lizzieyzy_app.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/position_analysis_screen.dart';
import 'package:lizzieyzy_mobile/features/scan/presentation/scan_result_screen.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../support/review_screen_fixture.dart';

void main() {
  Future<void> pumpPosition(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: LizzieTheme.light(),
        home: PositionAnalysisScreen(data: positionScreenFixture()),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in <Size>[
    const Size(360, 800),
    const Size(375, 667),
    const Size(393, 852),
    const Size(412, 915),
    const Size(430, 932),
  ]) {
    testWidgets(
      '${size.width.toInt()}x${size.height.toInt()} real position analysis is one viewport',
      (tester) async {
        await pumpPosition(tester, size: size);

        expect(find.text('局面分析'), findsOneWidget);
        expect(find.textContaining('无完整手顺'), findsOneWidget);
        expect(find.text('关键手'), findsNothing);
        expect(find.text('本局发挥'), findsNothing);
        expect(find.byType(Slider), findsNothing);
        expect(find.byType(Scrollable), findsNothing);
        expect(find.textContaining('R14'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('scan result starts the real analysis gate', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(393, 852);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });
    final data = positionScreenFixture();
    final frame = CapturedFrame(
      encodedBytes: Uint8List.fromList(<int>[1]),
      pixelWidth: 1,
      pixelHeight: 1,
      capturedAt: DateTime.utc(2026, 7, 11),
    );
    final draft = ScanDraft(
      kind: ScanKind.physicalBoard,
      boardSize: BoardSize.nineteen,
      boardBounds: const BoardQuadrilateral(
        topLeft: NormalizedPoint(0.1, 0.1),
        topRight: NormalizedPoint(0.9, 0.1),
        bottomRight: NormalizedPoint(0.9, 0.9),
        bottomLeft: NormalizedPoint(0.1, 0.9),
      ),
      intersections: const <IntersectionPrediction>[],
      boardConfidence: 0.5,
    );
    await tester.pumpWidget(const LizzieYzyApp());
    await tester.pumpAndSettle();
    final rootContext = tester.element(find.byType(NavigationBar));
    Navigator.of(rootContext).push(
      MaterialPageRoute<void>(
        builder: (_) => ScanResultScreen(
          result: ScanPositionPayload(
            snapshot: data.snapshot,
            originalFrame: frame,
            draft: draft,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = tester.element(find.byType(ScanResultScreen)).l10n;
    await tester.tap(find.text(l10n.analyzeCurrentPosition));
    await tester.pumpAndSettle();

    expect(find.text(l10n.analyzeKifuTitle), findsOneWidget);
    expect(find.text(l10n.katagoUnconfigured), findsOneWidget);
    expect(find.text(l10n.positionAnalysisTitle), findsNothing);
  });
}
