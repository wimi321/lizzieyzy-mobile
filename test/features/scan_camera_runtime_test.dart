import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/features/scan/presentation/camera_capture_screen.dart';
import 'package:lizzieyzy_mobile/features/scan/presentation/correction_screens.dart';
import 'package:lizzieyzy_mobile/features/scan/presentation/scan_result_screen.dart';
import 'package:lizzieyzy_mobile/infrastructure/vision/vision.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import 'scan_test_fakes.dart';

void main() {
  void expectTextIsComplete(
    WidgetTester tester,
    Finder root, {
    String? reason,
  }) {
    final textElements = <Element>[
      ...root.evaluate().where((element) => element.widget is Text),
      ...find.descendant(of: root, matching: find.byType(Text)).evaluate(),
    ];
    final paragraphs = textElements
        .map((element) => element.renderObject)
        .whereType<RenderParagraph>();
    expect(paragraphs, isNotEmpty);
    for (final paragraph in paragraphs) {
      expect(paragraph.didExceedMaxLines, isFalse, reason: reason);
    }
  }

  Future<void> pumpPhone(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('zh'),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: LizzieTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
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
    await tester.pumpAndSettle();

    expect(platform.captureCalls, 1);
    expect(vision.recognizeCalls, 1);
    expect(vision.lastBundle?.source, domain.FrameSource.cameraBurst);
    expect(vision.lastBundle?.frames, hasLength(3));
    expect(find.text('校对棋盘'), findsOneWidget);
    expect(find.bySemanticsLabel('待确认，1'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '请先确认 1 处'), findsOneWidget);
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

  testWidgets('自动识别失败后可用同一帧导框识别并保留普通重试', (tester) async {
    const automaticFailure = BoardVisionException(
      BoardVisionErrorCode.boardNotFound,
      'board not found',
    );
    final platform = FakeScanCapturePlatform();
    final guide = _CompletingBoardVision();
    final controller = ScanCaptureController(
      platform: platform,
      vision: FakeBoardVision(error: automaticFailure),
      guideFallback: guide,
    );
    await pumpPhone(
      tester,
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 800),
          textScaler: TextScaler.linear(3.2),
        ),
        child: CameraCaptureScreen(controller: controller),
      ),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('拍照'));
    await tester.pump();
    await tester.pump();

    expect(controller.canUseGuideFallback, isTrue);
    expect(find.text('使用同一组已拍画面，按棋盘导框重新识别。'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '改用导框识别'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '重试'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    expectTextIsComplete(tester, find.byKey(const Key('camera-state-message')));
    expectTextIsComplete(tester, find.byKey(const Key('camera-state-detail')));
    for (final index in <int>[0, 1]) {
      final action = find.byKey(Key('camera-state-action-$index'));
      final size = tester.getSize(action);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expectTextIsComplete(tester, action);
    }
    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithText(FilledButton, '改用导框识别'));
    await tester.pump();
    expect(find.text('正在按导框重新识别…'), findsOneWidget);
    expect(guide.recognizeCalls, 1);

    guide.complete(fakeScanDraft());
    await tester.pumpAndSettle();

    expect(platform.captureCalls, 1);
    expect(find.text('校对棋盘'), findsOneWidget);
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
    expect(
      controller.failureKind,
      ScanCaptureFailureKind.cameraPermissionDenied,
    );
    expect(find.text('相册'), findsOneWidget);
    final shutter = tester.widget<Semantics>(find.bySemanticsLabel('拍照').first);
    expect(shutter.properties.enabled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('相册权限错误按类型本地化且不泄露平台原文', (tester) async {
    final platform = FakeScanCapturePlatform(
      captureError: const ScanPlatformException(
        ScanPlatformFailureKind.permissionDenied,
        'raw platform permission text',
      ),
    );
    final controller = ScanCaptureController(
      platform: platform,
      vision: FakeBoardVision(),
    );
    await pumpPhone(tester, CameraCaptureScreen(controller: controller));
    await tester.pump();

    await tester.tap(find.text('相册'));
    await tester.pump();

    expect(find.text('无法访问相册，请在系统设置中允许照片访问。'), findsOneWidget);
    expect(find.text('raw platform permission text'), findsNothing);
    expect(
      controller.failureKind,
      ScanCaptureFailureKind.photoLibraryPermissionDenied,
    );
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

  testWidgets('校对页前后台切换不恢复背后预览且返回后仅恢复一次', (tester) async {
    final platform = FakeScanCapturePlatform();
    final controller = ScanCaptureController(
      platform: platform,
      vision: FakeBoardVision(),
    );
    await pumpPhone(tester, CameraCaptureScreen(controller: controller));
    await tester.pumpAndSettle();
    expect(platform.initializeCalls, 1);

    await tester.tap(find.bySemanticsLabel('拍照'));
    await tester.pumpAndSettle();
    expect(find.byType(PhysicalBoardCorrectionScreen), findsOneWidget);
    expect(platform.suspendCalls, 1);
    expect(platform.initializeCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(platform.suspendCalls, 1);
    expect(platform.initializeCalls, 1);

    Navigator.of(
      tester.element(find.byType(PhysicalBoardCorrectionScreen)),
    ).pop();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fake-camera-preview')), findsOneWidget);
    expect(platform.initializeCalls, 2);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(platform.initializeCalls, 2);
    expect(tester.takeException(), isNull);
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

  testWidgets('编号棋谱图识别结果进入手顺校对且保留原始载荷', (tester) async {
    final payloadDraft = fakeScanDraft(kind: domain.ScanKind.numberedDiagram);
    final controller = ScanCaptureController(
      platform: FakeScanCapturePlatform(),
      vision: FakeBoardVision(result: payloadDraft),
    );
    String? pushedRoute;
    Object? pushedArguments;
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(360, 800);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: LizzieTheme.light(),
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        onGenerateRoute: (settings) {
          pushedRoute = settings.name;
          pushedArguments = settings.arguments;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const SizedBox.shrink(),
          );
        },
        home: CameraCaptureScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('拍照'));
    await tester.pumpAndSettle();

    expect(pushedRoute, AppRoutes.numberedCorrection);
    final arguments = pushedArguments;
    expect(arguments, isA<ScanCapturePayload>());
    expect((arguments! as ScanCapturePayload).draft, same(payloadDraft));
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
    expect(find.text('黑 7 · 白 3'), findsOneWidget);
    expect(find.bySemanticsLabel('待确认，2'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '请先确认 2 处'), findsOneWidget);

    await tester.tap(find.text('白'));
    await tester.pump();
    await tester.tap(find.text('空'));
    await tester.pump();
    expect(find.text('黑 5 · 白 4'), findsOneWidget);
    expect(find.bySemanticsLabel('待确认，0'), findsOneWidget);

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

    final capture = ScanCapturePayload(
      draft: fakeScanDraft(),
      originalFrame: fakeFrame(),
      inputKind: ScanInputKind.camera,
      usedBurst: false,
    );
    await pumpPhone(
      tester,
      MediaQuery(
        data: media,
        child: PhysicalBoardCorrectionScreen(capture: capture),
      ),
    );
    await tester.pump();
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final textScale in <double>[2, 3.2]) {
    testWidgets('相机动作在$textScale倍字体下完整且触控区不少于48', (tester) async {
      final locales = textScale >= 3.2
          ? AppLocalizations.supportedLocales
          : const <Locale>[Locale('zh')];
      for (final locale in locales) {
        final controller = ScanCaptureController(
          platform: FakeScanCapturePlatform(),
          vision: FakeBoardVision(),
        );
        await pumpPhone(
          tester,
          MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 800),
              textScaler: TextScaler.linear(textScale),
            ),
            child: CameraCaptureScreen(controller: controller),
          ),
          locale: locale,
        );
        await tester.pump();

        expect(find.byType(Scrollable), findsNothing);
        for (final key in <String>[
          'camera-photo-library-action',
          'camera-help-action',
        ]) {
          final action = find.byKey(Key(key));
          final size = tester.getSize(action);
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
          expectTextIsComplete(
            tester,
            action,
            reason: '${locale.toLanguageTag()} $key',
          );
        }
        expectTextIsComplete(
          tester,
          find.byKey(const Key('camera-alignment-status')),
          reason: '${locale.toLanguageTag()} alignment status',
        );
        expect(tester.takeException(), isNull, reason: locale.toLanguageTag());
      }
    });
  }
}

final class _CompletingBoardVision implements domain.BoardVision {
  final Completer<domain.ScanDraft> _completer = Completer<domain.ScanDraft>();
  int recognizeCalls = 0;

  @override
  Future<domain.ScanDraft> recognize(domain.FrameBundle frames) {
    recognizeCalls++;
    return _completer.future;
  }

  void complete(domain.ScanDraft draft) => _completer.complete(draft);
}
