import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/features/scan/presentation/camera_capture_screen.dart';
import 'package:lizzieyzy_mobile/features/scan/presentation/correction_screens.dart';
import 'package:lizzieyzy_mobile/features/scan/presentation/scan_result_screen.dart';

import 'scan_test_fakes.dart';

void main() {
  Future<void> pumpPhone(WidgetTester tester, Widget child) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: LizzieTheme.light(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: child,
      ),
    );
    await tester.pump();
  }

  testWidgets('相机在首次进入识谱前保持完全懒初始化', (tester) async {
    final platform = FakeScanCapturePlatform();
    final controller = ScanCaptureController(
      platform: platform,
      vision: FakeBoardVision(),
    );
    await pumpPhone(tester, HomeShell(scanController: controller));

    expect(platform.initializeCalls, 0);
    expect(find.byKey(const Key('fake-camera-preview')), findsNothing);

    await tester.tap(find.text('识谱'));
    await tester.pump();
    await tester.pump();

    expect(platform.initializeCalls, 1);
    expect(find.byKey(const Key('fake-camera-preview')), findsOneWidget);
    expect(find.text('完整棋盘入框 · 保持稳定'), findsOneWidget);
  });

  testWidgets('三帧快门调用识别器并携带真实草稿进入校对', (tester) async {
    final platform = FakeScanCapturePlatform();
    final vision = FakeBoardVision(
      result: fakeScanDraft(
        uncertain: <domain.BoardPoint>{const domain.BoardPoint(7, 7)},
      ),
    );
    final controller = ScanCaptureController(
      platform: platform,
      vision: vision,
    );
    await pumpPhone(tester, CameraCaptureScreen(controller: controller));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('拍照'));
    await tester.pump();
    await tester.pump();

    expect(platform.captureCalls, 1);
    expect(vision.recognizeCalls, 1);
    expect(vision.lastBundle?.source, domain.FrameSource.cameraBurst);
    expect(vision.lastBundle?.frames, hasLength(3));
    expect(find.text('校对棋盘'), findsOneWidget);
    expect(find.text('待确认 1'), findsOneWidget);
  });

  testWidgets('单帧平台降级仍使用有效FrameBundle', (tester) async {
    final platform = FakeScanCapturePlatform(cameraFrames: fakeFrames(1));
    final vision = FakeBoardVision();
    final controller = ScanCaptureController(
      platform: platform,
      vision: vision,
    );
    await pumpPhone(tester, CameraCaptureScreen(controller: controller));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('拍照'));
    await tester.pump();
    await tester.pump();

    expect(vision.lastBundle?.source, domain.FrameSource.file);
    expect(vision.lastBundle?.frames, hasLength(1));
  });

  testWidgets('识别失败单屏呈现原因、重试和相册降级', (tester) async {
    final platform = FakeScanCapturePlatform();
    final controller = ScanCaptureController(
      platform: platform,
      vision: FakeBoardVision(error: StateError('bad frame')),
    );
    await pumpPhone(tester, CameraCaptureScreen(controller: controller));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('拍照'));
    await tester.pump();
    await tester.pump();

    expect(find.text('识别失败，请保持棋盘完整清晰后重试。'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '重试'), findsOneWidget);
    expect(find.text('可改用相册继续'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('拒绝相机权限时不崩溃并保留相册入口', (tester) async {
    final platform = FakeScanCapturePlatform(
      initializeError: const ScanPlatformException(
        ScanPlatformFailureKind.permissionDenied,
        '未获得相机权限，请在系统设置中允许访问，或改用相册。',
      ),
    );
    final controller = ScanCaptureController(
      platform: platform,
      vision: FakeBoardVision(),
    );
    await pumpPhone(tester, CameraCaptureScreen(controller: controller));
    await tester.pump();

    expect(find.text('未获得相机权限，请在系统设置中允许访问，或改用相册。'), findsOneWidget);
    expect(find.text('相册'), findsOneWidget);
    final shutter = tester.widget<Semantics>(find.bySemanticsLabel('拍照').first);
    expect(shutter.properties.enabled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('应用进入后台释放相机，恢复后重新初始化预览', (tester) async {
    final platform = FakeScanCapturePlatform();
    final controller = ScanCaptureController(
      platform: platform,
      vision: FakeBoardVision(),
    );
    await pumpPhone(tester, CameraCaptureScreen(controller: controller));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(platform.suspendCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(platform.initializeCalls, 2);
    expect(find.byKey(const Key('fake-camera-preview')), findsOneWidget);
  });

  testWidgets('相册与快门复用同一识别器', (tester) async {
    final platform = FakeScanCapturePlatform();
    final vision = FakeBoardVision();
    final controller = ScanCaptureController(
      platform: platform,
      vision: vision,
    );
    await pumpPhone(tester, CameraCaptureScreen(controller: controller));
    await tester.pump();

    await tester.tap(find.text('相册'));
    await tester.pump();
    await tester.pump();

    expect(platform.libraryCalls, 1);
    expect(vision.recognizeCalls, 1);
    expect(vision.lastBundle?.source, domain.FrameSource.photoLibrary);
    expect(find.text('校对棋盘'), findsOneWidget);
  });

  testWidgets('361点草稿驱动动态棋子与待确认计数，结果严格为局面快照', (tester) async {
    final stones = <domain.BoardPoint, domain.StoneColor>{
      for (var index = 0; index < 5; index++)
        domain.BoardPoint(index, 0): domain.StoneColor.black,
      for (var index = 0; index < 3; index++)
        domain.BoardPoint(index, 1): domain.StoneColor.white,
    };
    final draft = fakeScanDraft(
      stones: stones,
      uncertain: <domain.BoardPoint>{
        const domain.BoardPoint(8, 8),
        const domain.BoardPoint(9, 9),
      },
    );
    final capture = ScanCapturePayload(
      draft: draft,
      originalFrame: fakeFrame(),
      inputKind: ScanInputKind.photoLibrary,
      usedBurst: false,
    );
    await pumpPhone(tester, PhysicalBoardCorrectionScreen(capture: capture));

    expect(draft.intersections, hasLength(361));
    expect(find.text('黑 7  ·  白 3'), findsOneWidget);
    expect(find.text('待确认 2'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '请先确认 2 处'), findsOneWidget);

    await tester.tap(find.text('白'));
    await tester.pump();
    await tester.tap(find.text('空'));
    await tester.pump();
    expect(find.text('黑 5  ·  白 4'), findsOneWidget);
    expect(find.text('待确认 0'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '确认当前局面'));
    await tester.pump();
    await tester.pump();

    expect(find.text('已识别当前局面：黑5子，白4子。'), findsOneWidget);
    final result = tester.widget<ScanResultScreen>(
      find.byType(ScanResultScreen),
    );
    expect(result.result?.snapshot, isA<domain.PositionSnapshot>());
    expect(find.textContaining('不会显示关键手时间轴或棋力评估'), findsOneWidget);
  });

  testWidgets('相机与校对在360x800和2.0倍字体下仍无滚动与溢出', (tester) async {
    const safeInsets = FakeViewPadding(top: 24, bottom: 24);
    tester.view.padding = safeInsets;
    tester.view.viewPadding = safeInsets;
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    final controller = ScanCaptureController(
      platform: FakeScanCapturePlatform(),
      vision: FakeBoardVision(),
    );
    const media = MediaQueryData(
      size: Size(360, 800),
      textScaler: TextScaler.linear(2),
    );
    await pumpPhone(
      tester,
      MediaQuery(
        data: media,
        child: CameraCaptureScreen(controller: controller),
      ),
    );
    await tester.pump();
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);

    await pumpPhone(
      tester,
      const MediaQuery(data: media, child: PhysicalBoardCorrectionScreen()),
    );
    await tester.pump();
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
