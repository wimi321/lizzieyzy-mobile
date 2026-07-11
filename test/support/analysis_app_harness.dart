import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';
import 'package:lizzieyzy_mobile/application/analysis/analysis.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/review_screen_data.dart';
import 'package:lizzieyzy_mobile/infrastructure/review/review.dart';

import 'review_screen_fixture.dart';

final class AnalysisAppHarness {
  AnalysisAppHarness({
    required this.review,
    required int emittedPositions,
    this.complete = false,
  }) : provider = ScriptedAnalysisProvider(
         bundle: review.analysis,
         emittedPositions: emittedPositions,
         complete: complete,
       ),
       workspace = KifuWorkspaceController(),
       settings = AppSettingsController(
         repository: MemoryAppSettingsRepository(
           AppSettings(
             locale: AppLocalePreference.simplifiedChinese,
             analysisService: AnalysisServiceProfile(
               endpoint: Uri.parse('wss://analysis.example.test/v1'),
               model: review.analysis.model,
               winRatePerspective: AnalysisWinRatePerspective.black,
             ),
             confirmRemoteAnalysis: false,
           ),
         ),
       ) {
    coordinator = AnalysisCoordinator(
      providerFactory: _SingleProviderFactory(provider),
      reviewBuilder: const DefaultReviewBuilder(),
      requestIdFactory: () => 'widget-analysis-request',
    );
  }

  factory AnalysisAppHarness.standard({
    int emittedPositions = 42,
    bool complete = false,
  }) => AnalysisAppHarness(
    review: reviewScreenFixture(),
    emittedPositions: emittedPositions,
    complete: complete,
  );

  final ReviewScreenData review;
  final ScriptedAnalysisProvider provider;
  final KifuWorkspaceController workspace;
  final AppSettingsController settings;
  late final AnalysisCoordinator coordinator;
  final bool complete;

  Future<void> initialize() async {
    await Future.wait(<Future<void>>[
      workspace.initialize(),
      settings.initialize(),
    ]);
    workspace.add(review.record);
  }

  Widget app({String route = AppRoutes.analysisProgress}) => LizzieYzyApp(
    initialRoute: route,
    workspaceController: workspace,
    settingsController: settings,
    analysisCoordinator: coordinator,
  );

  void dispose() {
    coordinator.dispose();
    workspace.dispose();
    settings.dispose();
  }
}

final class ScriptedAnalysisProvider implements AnalysisProvider {
  ScriptedAnalysisProvider({
    required this.bundle,
    required this.emittedPositions,
    required this.complete,
  });

  final AnalysisBundle bundle;
  final int emittedPositions;
  final bool complete;
  StreamController<AnalysisEvent>? _controller;

  @override
  Future<AnalysisBundle> analyze(AnalysisRequest request) async {
    await for (final event in stream(request)) {
      if (event is AnalysisCompleted) return event.bundle;
    }
    throw StateError('Scripted analysis ended without completion.');
  }

  @override
  Stream<AnalysisEvent> stream(AnalysisRequest request) {
    late final StreamController<AnalysisEvent> controller;
    // Keep delivery asynchronous like a real socket. Synchronous completion
    // can re-enter session teardown before `listen` has returned.
    controller = StreamController<AnalysisEvent>(
      onListen: () {
        controller.add(
          AnalysisStarted(
            request.requestId,
            totalPositions: bundle.moves.length,
          ),
        );
        final count = emittedPositions.clamp(0, bundle.moves.length);
        for (var index = 0; index < count; index++) {
          controller.add(
            PositionAnalyzed(
              request.requestId,
              analysis: bundle.moves[index],
              completedPositions: index + 1,
              totalPositions: bundle.moves.length,
            ),
          );
        }
        if (complete) {
          final completedBundle = AnalysisBundle(
            requestId: request.requestId,
            documentId: bundle.documentId,
            boardSize: bundle.boardSize,
            model: bundle.model,
            settings: bundle.settings,
            moves: bundle.moves,
            completedAt: bundle.completedAt,
          );
          controller
            ..add(AnalysisCompleted(request.requestId, bundle: completedBundle))
            ..close();
        }
      },
    );
    _controller = controller;
    return controller.stream;
  }

  @override
  Future<void> cancel(String requestId) async {
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    controller
      ..add(AnalysisCancelled(requestId))
      ..close();
  }

  Future<void> close() async {
    await _controller?.close();
  }
}

final class _SingleProviderFactory implements AnalysisProviderFactory {
  const _SingleProviderFactory(this.provider);

  final ScriptedAnalysisProvider provider;

  @override
  AnalysisProvider create(AnalysisServiceProfile profile) => provider;

  @override
  Future<void> release(AnalysisProvider provider) =>
      (provider as ScriptedAnalysisProvider).close();
}

Future<void> configureTestView(
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
}
