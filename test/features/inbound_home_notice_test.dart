import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app_routes.dart';
import 'package:lizzieyzy_mobile/application/inbound_kifu_controller.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/features/home/presentation/kifu_home_screen.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../support/gib_encoding_fixtures.dart';

void main() {
  Future<({InboundKifuController inbound, KifuWorkspaceController workspace})>
  createControllers(Object? initial) async {
    final bridge = _InboundBridge(initial);
    addTearDown(bridge.close);
    final workspace = KifuWorkspaceController();
    await workspace.initialize();
    addTearDown(workspace.dispose);
    final inbound = InboundKifuController(
      workspace: workspace,
      service: PlatformInboundKifuService(bridge: bridge),
    );
    await inbound.initialize();
    addTearDown(inbound.dispose);
    return (inbound: inbound, workspace: workspace);
  }

  Future<void> pumpHome(
    WidgetTester tester, {
    required InboundKifuController inbound,
    required KifuWorkspaceController workspace,
    RouteFactory? onGenerateRoute,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(360, 800);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });
    await tester.pumpWidget(
      InboundKifuScope(
        controller: inbound,
        child: KifuWorkspace(
          controller: workspace,
          child: MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: LizzieTheme.light(),
            onGenerateRoute: onGenerateRoute,
            home: const KifuHomeScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('系统分享导入状态条可打开真实棋谱且全程单屏', (tester) async {
    final controllers = await createControllers(
      _payload(
        name: 'shared.sgf',
        text: '(;FF[4]GM[1]SZ[19]PB[Black]PW[White];B[dd];W[pp])',
      ),
    );
    String? routeName;
    Object? routeArguments;
    await pumpHome(
      tester,
      inbound: controllers.inbound,
      workspace: controllers.workspace,
      onGenerateRoute: (settings) {
        routeName = settings.name;
        routeArguments = settings.arguments;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SizedBox.shrink(),
        );
      },
    );

    expect(find.textContaining('已从系统分享导入 shared.sgf'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel('打开已导入的棋谱：shared.sgf'));
    await tester.pumpAndSettle();

    expect(routeName, AppRoutes.analysisProgress);
    expect(routeArguments, same(controllers.inbound.lastDocument));
    expect(
      controllers.workspace.selected,
      same(controllers.inbound.lastDocument),
    );
  });

  testWidgets('系统分享失败显示本地化错误并可关闭', (tester) async {
    final controllers = await createControllers(
      _payload(name: 'broken.sgf', text: 'not an sgf'),
    );
    await pumpHome(
      tester,
      inbound: controllers.inbound,
      workspace: controllers.workspace,
    );

    expect(find.text('分享的棋谱无效，无法导入。'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);

    await tester.tap(find.byTooltip('关闭通知'));
    await tester.pump();

    expect(find.text('分享的棋谱无效，无法导入。'), findsNothing);
    expect(controllers.inbound.status, InboundKifuStatus.idle);
    expect(tester.takeException(), isNull);
  });

  testWidgets('原生读取失败以无路径本地化通知展示', (tester) async {
    final controllers = await createControllers(<String, Object?>{
      'error': 'unreadable',
    });
    await pumpHome(
      tester,
      inbound: controllers.inbound,
      workspace: controllers.workspace,
    );

    expect(find.text('无法读取系统分享的棋谱，请重试。'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    expect(controllers.inbound.lastFileName, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('旧版 GIB 编码以本地化结构字段展示', (tester) async {
    final fixture = (await tester.runAsync(loadGibEncodingFixtures))!.last;
    final controllers = await createControllers(
      _payload(name: 'traditional.gib', bytes: fixture.bytes),
    );
    await pumpHome(
      tester,
      inbound: controllers.inbound,
      workspace: controllers.workspace,
    );

    expect(find.textContaining('检测到旧版 GIB 编码：Big5'), findsOneWidget);
    expect(controllers.inbound.lastTextEncoding, KifuTextEncoding.big5);
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Map<String, Object?> _payload({
  required String name,
  String? text,
  Uint8List? bytes,
}) => <String, Object?>{
  'name': name,
  'bytes': bytes ?? Uint8List.fromList(utf8.encode(text!)),
  'action': 'send',
};

final class _InboundBridge implements PlatformInboundKifuBridge {
  _InboundBridge(this.initial);

  final Object? initial;
  final StreamController<Object?> _events =
      StreamController<Object?>.broadcast();

  @override
  Stream<Object?> get runtimeEvents => _events.stream;

  @override
  Future<Object?> takeInitial() async => initial;

  Future<void> close() => _events.close();
}
