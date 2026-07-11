import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/analysis/analysis.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/analysis_progress_screen.dart';
import 'package:lizzieyzy_mobile/infrastructure/review/review.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../support/review_screen_fixture.dart';

void main() {
  test('silent provider closes running and queued sessions', () async {
    final review = reviewScreenFixture();
    final profile = AnalysisServiceProfile(
      endpoint: Uri.parse('wss://analysis.example.test/v1'),
      model: review.analysis.model,
      winRatePerspective: AnalysisWinRatePerspective.black,
    );
    final coordinator = AnalysisCoordinator(
      providerFactory: _SilentProviderFactory(),
      reviewBuilder: const DefaultReviewBuilder(),
      requestIdFactory: _queueRequestId,
    );
    coordinator.start(
      document: reviewScreenFixture(id: 'silent-running').record,
      serviceProfile: profile,
      settings: review.analysis.settings,
    );
    coordinator.start(
      document: review.record,
      serviceProfile: profile,
      settings: review.analysis.settings,
    );

    await coordinator.close().timeout(const Duration(seconds: 1));
    coordinator.dispose();
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      '3.2x queued status and position remain complete in ${locale.toLanguageTag()}',
      (tester) => _verifyQueuedLocale(tester, locale),
    );
  }
}

Future<void> _verifyQueuedLocale(WidgetTester tester, Locale locale) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(393, 852);
  tester.platformDispatcher.textScaleFactorTestValue = 3.2;
  addTearDown(() {
    tester.view
      ..resetDevicePixelRatio()
      ..resetPhysicalSize();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });

  final review = reviewScreenFixture(id: 'queued-${locale.toLanguageTag()}');
  final profile = AnalysisServiceProfile(
    endpoint: Uri.parse('wss://analysis.example.test/v1'),
    model: review.analysis.model,
    winRatePerspective: AnalysisWinRatePerspective.black,
  );
  final settingsController = AppSettingsController(
    repository: MemoryAppSettingsRepository(
      AppSettings(analysisService: profile, confirmRemoteAnalysis: false),
    ),
  );
  await settingsController.initialize();
  final coordinator = AnalysisCoordinator(
    providerFactory: _SilentProviderFactory(),
    reviewBuilder: const DefaultReviewBuilder(),
    requestIdFactory: _queueRequestId,
  );
  addTearDown(() {
    coordinator.dispose();
    settingsController.dispose();
  });
  final settings = settingsController.settings.analysisRequestSettings;
  coordinator.start(
    document: reviewScreenFixture(
      id: 'blocker-${locale.toLanguageTag()}',
    ).record,
    serviceProfile: profile,
    settings: settings,
  );
  final queued = coordinator.start(
    document: review.record,
    serviceProfile: profile,
    settings: settings,
  );
  expect(queued.state.status, AnalysisSessionStatus.queued);

  await tester.pumpWidget(
    MaterialApp(
      theme: LizzieTheme.light(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: AppSettingsScope(
        controller: settingsController,
        child: AnalysisCoordinatorScope(
          coordinator: coordinator,
          child: AnalysisProgressScreen(document: review.record),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  final l10n = await AppLocalizations.delegate.load(locale);
  final queueContent = find.byKey(const Key('analysis-queue-content'));
  expect(queueContent, findsOneWidget, reason: locale.toLanguageTag());
  expect(
    find.descendant(of: queueContent, matching: find.text(l10n.statusQueued)),
    findsOneWidget,
    reason: locale.toLanguageTag(),
  );
  expect(
    find.text(l10n.analysisQueuePositionCompact(1)),
    findsOneWidget,
    reason: locale.toLanguageTag(),
  );
  final textElements = find.byType(Text).evaluate().toList();
  expect(textElements, isNotEmpty);
  for (final element in textElements) {
    final paragraph = element.renderObject;
    if (paragraph is! RenderParagraph) continue;
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: '${locale.toLanguageTag()}: ${(element.widget as Text).data}',
    );
  }
  final verticalScrollables = tester
      .widgetList<Scrollable>(find.byType(Scrollable))
      .where(
        (widget) =>
            widget.axisDirection == AxisDirection.down ||
            widget.axisDirection == AxisDirection.up,
      );
  expect(verticalScrollables, isEmpty, reason: locale.toLanguageTag());
  final rect = tester.getRect(queueContent);
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(852));
  final exception = tester.takeException();
  expect(exception, isNull, reason: locale.toLanguageTag());

  await tester.pumpWidget(const SizedBox.shrink());
}

var _requestSequence = 0;

String _queueRequestId() => 'queue-request-${++_requestSequence}';

final class _SilentProviderFactory implements AnalysisProviderFactory {
  @override
  AnalysisProvider create(AnalysisServiceProfile profile) => _SilentProvider();

  @override
  Future<void> release(AnalysisProvider provider) =>
      (provider as _SilentProvider).close();
}

final class _SilentProvider implements AnalysisProvider {
  final StreamController<AnalysisEvent> _events =
      StreamController<AnalysisEvent>();

  @override
  Future<AnalysisBundle> analyze(AnalysisRequest request) =>
      throw UnimplementedError();

  @override
  Future<void> cancel(String requestId) async {}

  @override
  Stream<AnalysisEvent> stream(AnalysisRequest request) => _events.stream;

  Future<void> close() => _events.close();
}
