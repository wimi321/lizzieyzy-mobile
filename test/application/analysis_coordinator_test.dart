import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/analysis/analysis.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/review/review.dart';

import '../infrastructure/review/review_test_fixtures.dart';

void main() {
  late _ControlledProviderFactory factory;
  late AnalysisCoordinator coordinator;
  var requestSequence = 0;
  var coordinatorDisposed = false;

  setUp(() {
    factory = _ControlledProviderFactory();
    coordinator = AnalysisCoordinator(
      providerFactory: factory,
      reviewBuilder: const DefaultReviewBuilder(),
      performanceEstimatorFactory: (calibration) =>
          CalibratedGamePerformanceEstimator(calibration: calibration),
      requestIdFactory: () => 'request-${++requestSequence}',
    );
  });

  tearDown(() async {
    await coordinator.close();
    if (!coordinatorDisposed) coordinator.dispose();
  });

  test('requires configuration before creating a provider', () async {
    final fixture = reviewFixture(moveCount: 4);

    final session = coordinator.start(
      document: fixture.record,
      serviceProfile: null,
      settings: fixture.analysis.settings,
    );

    expect(session.state.status, AnalysisSessionStatus.configurationRequired);
    expect(session.state.canRetry, isTrue);
    expect(factory.providers, isEmpty);

    await session.retry(serviceProfile: _profile(fixture.model));

    expect(session.state.status, AnalysisSessionStatus.running);
    expect(session.state.attempt, 1);
    expect(factory.providers, hasLength(1));
  });

  test(
    'reports provider progress and completes after the view listener is removed',
    () async {
      final fixture = reviewFixture(
        moveCount: 4,
        pointLossForMove: (moveNumber) => moveNumber.toDouble(),
      );
      final session = coordinator.start(
        document: fixture.record,
        serviceProfile: _profile(fixture.model),
        settings: fixture.analysis.settings,
      );
      final provider = factory.providers.single;
      var notifications = 0;
      void viewListener() => notifications += 1;
      session.addListener(viewListener);

      provider.emit(
        AnalysisStarted(
          provider.request!.requestId,
          totalPositions: fixture.analysis.moves.length,
        ),
      );
      provider.emit(
        PositionAnalyzed(
          provider.request!.requestId,
          analysis: fixture.analysis.moves.first,
          completedPositions: 1,
          totalPositions: fixture.analysis.moves.length,
        ),
      );

      expect(session.state.completedPositions, 1);
      expect(session.state.totalPositions, 5);
      expect(session.state.progress, .2);
      expect(session.state.latestAnalysis?.moveNumber, 0);

      // This models route/widget disposal: only the listener goes away. The
      // coordinator still owns the live session and provider.
      session.removeListener(viewListener);
      final notificationsAtDisposal = notifications;
      provider.emit(
        AnalysisCompleted(
          provider.request!.requestId,
          bundle: _withRequest(fixture.analysis, provider.request!.requestId),
        ),
      );

      expect(notifications, notificationsAtDisposal);
      expect(session.state.status, AnalysisSessionStatus.completed);
      expect(session.state.progress, 1);
      expect(session.state.bundle?.documentId, fixture.record.id);
      expect(session.state.reviewReport, isNotNull);
      expect(
        session.state.reviewReport?.analysisRequestId,
        provider.request!.requestId,
      );
      expect(session.state.reviewReport?.keyMoments.first.moveNumber, 4);
      expect(session.state.performanceReport, isNull);
      expect(coordinator.sessionFor(fixture.record.id), same(session));
    },
  );

  test('stores a real performance report only with a verified artifact', () {
    final fixture = reviewFixture(
      documentId: 'calibrated-session',
      moveCount: 90,
    );
    final artifact = const GamePerformanceCalibrationCodec().encode(
      calibrationFixture(),
    );
    final session = coordinator.start(
      document: fixture.record,
      serviceProfile: _profile(fixture.model, performanceCalibration: artifact),
      settings: fixture.analysis.settings,
    );
    final provider = factory.providers.single;

    provider.emit(
      AnalysisCompleted(
        provider.request!.requestId,
        bundle: _withRequest(fixture.analysis, provider.request!.requestId),
      ),
    );

    expect(session.state.status, AnalysisSessionStatus.completed);
    expect(session.state.reviewReport, isNotNull);
    expect(session.state.performanceReport, isNotNull);
    expect(
      session.state.performanceReport?.calibrationModelId,
      'game-strength-calibration@1.0.0',
    );
    expect(session.state.performanceReport?.effectiveDecisions, 90);
  });

  test('missing HumanSL evidence keeps review but refuses a rank interval', () {
    final fixture = reviewFixture(
      documentId: 'missing-human-policy',
      moveCount: 90,
    );
    final withoutHumanPolicy = copyAnalysis(
      fixture.analysis,
      moves: <MoveAnalysis>[
        for (final node in fixture.analysis.moves)
          copyMoveAnalysis(node, removePlayedMoveHumanPolicy: true),
      ],
    );
    final artifact = const GamePerformanceCalibrationCodec().encode(
      calibrationFixture(),
    );
    final session = coordinator.start(
      document: fixture.record,
      serviceProfile: _profile(fixture.model, performanceCalibration: artifact),
      settings: fixture.analysis.settings,
    );
    final provider = factory.providers.single;

    provider.emit(
      AnalysisCompleted(
        provider.request!.requestId,
        bundle: _withRequest(withoutHumanPolicy, provider.request!.requestId),
      ),
    );

    expect(session.state.status, AnalysisSessionStatus.completed);
    expect(session.state.reviewReport, isNotNull);
    expect(session.state.performanceReport, isNull);
  });

  test(
    'cancel is real and retry creates a fresh provider and request',
    () async {
      final fixture = reviewFixture(documentId: 'retry-game', moveCount: 4);
      final session = coordinator.start(
        document: fixture.record,
        serviceProfile: _profile(fixture.model),
        settings: fixture.analysis.settings,
      );
      final first = factory.providers.single;
      first.emit(
        AnalysisStarted(
          first.request!.requestId,
          totalPositions: fixture.analysis.moves.length,
        ),
      );
      final firstRequestId = first.request!.requestId;

      await session.cancel();

      expect(first.cancelledRequestIds, [firstRequestId]);
      expect(session.state.status, AnalysisSessionStatus.cancelled);
      expect(session.state.canRetry, isTrue);

      await session.retry();
      final second = factory.providers.last;
      expect(second, isNot(same(first)));
      expect(second.request!.requestId, isNot(firstRequestId));
      expect(session.state.status, AnalysisSessionStatus.running);
      expect(session.state.attempt, 2);

      second.emit(
        AnalysisFailed(
          second.request!.requestId,
          code: 'temporary_capacity',
          message: 'Service is temporarily at capacity.',
          isRetryable: true,
        ),
      );
      expect(session.state.status, AnalysisSessionStatus.failed);
      expect(session.state.failure?.code, 'temporary_capacity');
      expect(session.state.failure?.isRetryable, isTrue);

      await session.retry();
      final third = factory.providers.last;
      third.emit(
        AnalysisCompleted(
          third.request!.requestId,
          bundle: _withRequest(fixture.analysis, third.request!.requestId),
        ),
      );
      expect(session.state.status, AnalysisSessionStatus.completed);
      expect(session.state.attempt, 3);
    },
  );

  test('a provider stream error becomes an explicit failed state', () {
    final fixture = reviewFixture(documentId: 'error-game', moveCount: 4);
    final session = coordinator.start(
      document: fixture.record,
      serviceProfile: _profile(fixture.model),
      settings: fixture.analysis.settings,
    );

    factory.providers.single.emitError(StateError('socket failed'));

    expect(session.state.status, AnalysisSessionStatus.failed);
    expect(session.state.failure?.code, 'provider_error');
    expect(session.state.failure?.cause, isA<StateError>());
  });

  test('completed non-game analysis never creates a review report', () {
    final model = analysisModelFixture();
    final snapshot = PositionSnapshot(
      id: 'position',
      position: BoardPosition.empty(BoardSize.nineteen),
      rules: const GoRules.chinese(),
      source: const KifuSource(kind: KifuSourceKind.fixture),
      playerToMove: StoneColor.black,
    );
    const settings = AnalysisSettings(
      profile: AnalysisProfile.standard,
      visitsPerMove: 1000,
    );
    final session = coordinator.start(
      document: snapshot,
      serviceProfile: _profile(model),
      settings: settings,
    );
    final provider = factory.providers.single;
    final bundle = AnalysisBundle(
      requestId: provider.request!.requestId,
      documentId: snapshot.id,
      boardSize: snapshot.boardSize,
      model: model,
      settings: settings,
      moves: <MoveAnalysis>[
        MoveAnalysis(
          moveNumber: 0,
          toPlay: StoneColor.black,
          playedMove: null,
          blackWinRate: .5,
          scoreLead: 0,
          visits: 1000,
          candidates: <Candidate>[
            Candidate(
              move: const Move.play(
                color: StoneColor.black,
                point: BoardPoint(3, 3),
              ),
              winRate: .5,
              scoreLead: 0,
              visits: 500,
              policy: .1,
            ),
          ],
        ),
      ],
      completedAt: DateTime.utc(2026, 7, 11),
    );

    provider.emit(
      AnalysisCompleted(provider.request!.requestId, bundle: bundle),
    );

    expect(session.state.status, AnalysisSessionStatus.completed);
    expect(session.state.bundle, same(bundle));
    expect(session.state.reviewReport, isNull);
  });

  test('coordinator returns one app-owned session per document', () {
    final fixture = reviewFixture(moveCount: 4);
    final first = coordinator.start(
      document: fixture.record,
      serviceProfile: _profile(fixture.model),
      settings: fixture.analysis.settings,
    );
    final second = coordinator.start(
      document: fixture.record,
      serviceProfile: _profile(fixture.model),
      settings: fixture.analysis.settings,
    );

    expect(second, same(first));
    expect(coordinator.sessions, [same(first)]);
    expect(factory.providers, hasLength(1));
  });

  test('same id replacement waits for the old provider release', () async {
    final firstFixture = reviewFixture(
      documentId: 'corrected-game',
      moveCount: 2,
    );
    final correctedFixture = reviewFixture(
      documentId: 'corrected-game',
      moveCount: 4,
    );
    final first = coordinator.start(
      document: firstFixture.record,
      serviceProfile: _profile(firstFixture.model),
      settings: firstFixture.analysis.settings,
    );
    final firstProvider = factory.providers.single;

    expect(coordinator.sessionForDocument(correctedFixture.record), isNull);
    final corrected = coordinator.start(
      document: correctedFixture.record,
      serviceProfile: _profile(correctedFixture.model),
      settings: correctedFixture.analysis.settings,
    );

    expect(corrected, isNot(same(first)));
    expect(corrected.document, same(correctedFixture.record));
    expect(coordinator.sessionFor('corrected-game'), same(corrected));
    expect(corrected.state.status, AnalysisSessionStatus.queued);
    expect(corrected.state.queuePosition, 1);
    expect(factory.providers, hasLength(1));

    await _flushAsyncCleanup();

    expect(firstProvider.cancelledRequestIds, isNotEmpty);
    expect(factory.released, contains(firstProvider));
    expect(factory.providers, hasLength(2));
    expect(corrected.state.status, AnalysisSessionStatus.running);
    expect(factory.maximumObservedActive, 1);
  });

  test('changed analysis depth cannot reuse an incompatible result', () async {
    final fixture = reviewFixture(documentId: 'depth-game', moveCount: 4);
    final profile = _profile(fixture.model);
    final standard = coordinator.start(
      document: fixture.record,
      serviceProfile: profile,
      settings: fixture.analysis.settings,
    );
    const deep = AnalysisSettings(
      profile: AnalysisProfile.deep,
      visitsPerMove: 5000,
      criticalMoveVisits: 20000,
    );

    expect(
      coordinator.sessionForRequest(
        document: fixture.record,
        serviceProfile: profile,
        settings: deep,
      ),
      isNull,
    );
    final replacement = coordinator.start(
      document: fixture.record,
      serviceProfile: profile,
      settings: deep,
    );

    expect(replacement, isNot(same(standard)));
    expect(replacement.settings.profile, AnalysisProfile.deep);
    expect(replacement.state.status, AnalysisSessionStatus.queued);
    await _flushAsyncCleanup();
    expect(factory.providers, hasLength(2));
    expect(replacement.state.status, AnalysisSessionStatus.running);
  });

  test(
    'one-connection bridge queues a second game until release completes',
    () async {
      final firstFixture = reviewFixture(
        documentId: 'queue-first',
        moveCount: 4,
      );
      final secondFixture = reviewFixture(
        documentId: 'queue-second',
        moveCount: 4,
      );
      final first = coordinator.start(
        document: firstFixture.record,
        serviceProfile: _profile(firstFixture.model),
        settings: firstFixture.analysis.settings,
      );
      final firstProvider = factory.providers.single;
      final second = coordinator.start(
        document: secondFixture.record,
        serviceProfile: _profile(secondFixture.model),
        settings: secondFixture.analysis.settings,
      );

      expect(first.state.status, AnalysisSessionStatus.running);
      expect(second.state.status, AnalysisSessionStatus.queued);
      expect(second.state.queuePosition, 1);
      expect(second.state.canCancel, isTrue);
      expect(factory.providers, hasLength(1));

      final releaseBarrier = Completer<void>();
      factory.releaseBarrier = releaseBarrier;
      firstProvider.emit(
        AnalysisCompleted(
          firstProvider.request!.requestId,
          bundle: _withRequest(
            firstFixture.analysis,
            firstProvider.request!.requestId,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(first.state.status, AnalysisSessionStatus.completed);
      expect(second.state.status, AnalysisSessionStatus.queued);
      expect(factory.providers, hasLength(1));
      expect(factory.active, 1);

      releaseBarrier.complete();
      await _flushAsyncCleanup();

      expect(factory.released, contains(firstProvider));
      expect(factory.providers, hasLength(2));
      expect(second.state.status, AnalysisSessionStatus.running);
      expect(factory.active, 1);
      expect(factory.maximumObservedActive, 1);
    },
  );

  test('cancelling a queued game renumbers the remaining queue', () async {
    final first = reviewFixture(documentId: 'queue-running', moveCount: 4);
    final second = reviewFixture(documentId: 'queue-cancelled', moveCount: 4);
    final third = reviewFixture(documentId: 'queue-renumbered', moveCount: 4);
    coordinator.start(
      document: first.record,
      serviceProfile: _profile(first.model),
      settings: first.analysis.settings,
    );
    final cancelled = coordinator.start(
      document: second.record,
      serviceProfile: _profile(second.model),
      settings: second.analysis.settings,
    );
    final remaining = coordinator.start(
      document: third.record,
      serviceProfile: _profile(third.model),
      settings: third.analysis.settings,
    );
    expect(cancelled.state.queuePosition, 1);
    expect(remaining.state.queuePosition, 2);

    await cancelled.cancel();

    expect(cancelled.state.status, AnalysisSessionStatus.cancelled);
    expect(remaining.state.status, AnalysisSessionStatus.queued);
    expect(remaining.state.queuePosition, 1);
    expect(factory.providers, hasLength(1));
  });

  test('cancel then immediate retry opens only after release', () async {
    final fixture = reviewFixture(
      documentId: 'cancel-retry-serialized',
      moveCount: 4,
    );
    final session = coordinator.start(
      document: fixture.record,
      serviceProfile: _profile(fixture.model),
      settings: fixture.analysis.settings,
    );
    final firstProvider = factory.providers.single;
    final releaseBarrier = Completer<void>();
    factory.releaseBarrier = releaseBarrier;

    final cancel = session.cancel();
    expect(session.state.status, AnalysisSessionStatus.cancelled);
    final retry = session.retry();
    await Future<void>.delayed(Duration.zero);

    expect(factory.providers, hasLength(1));
    expect(factory.active, 1);

    releaseBarrier.complete();
    await Future.wait<void>(<Future<void>>[cancel, retry]);

    expect(factory.providers, hasLength(2));
    expect(factory.released, contains(firstProvider));
    expect(session.state.status, AnalysisSessionStatus.running);
    expect(factory.active, 1);
    expect(factory.maximumObservedActive, 1);
  });

  test(
    'completion cleanup releases the final provider deterministically',
    () async {
      final fixture = reviewFixture(
        documentId: 'completion-cleanup',
        moveCount: 4,
      );
      final session = coordinator.start(
        document: fixture.record,
        serviceProfile: _profile(fixture.model),
        settings: fixture.analysis.settings,
      );
      final provider = factory.providers.single;

      provider.emit(
        AnalysisCompleted(
          provider.request!.requestId,
          bundle: _withRequest(fixture.analysis, provider.request!.requestId),
        ),
      );
      await _flushAsyncCleanup();

      expect(session.state.status, AnalysisSessionStatus.completed);
      expect(factory.released, [same(provider)]);
      expect(factory.active, 0);
    },
  );

  test(
    'coordinator close cancels running and queued sessions together',
    () async {
      final first = reviewFixture(documentId: 'close-running', moveCount: 4);
      final second = reviewFixture(documentId: 'close-queued', moveCount: 4);
      coordinator.start(
        document: first.record,
        serviceProfile: _profile(first.model),
        settings: first.analysis.settings,
      );
      final queued = coordinator.start(
        document: second.record,
        serviceProfile: _profile(second.model),
        settings: second.analysis.settings,
      );
      expect(queued.state.status, AnalysisSessionStatus.queued);

      await coordinator.close().timeout(const Duration(seconds: 1));

      expect(factory.active, 0);
      expect(factory.providers, hasLength(1));
    },
  );

  test('synchronous dispose cancels and releases an active provider', () async {
    final fixture = reviewFixture(documentId: 'dispose-game', moveCount: 4);
    coordinator.start(
      document: fixture.record,
      serviceProfile: _profile(fixture.model),
      settings: fixture.analysis.settings,
    );
    final provider = factory.providers.single;
    final requestId = provider.request!.requestId;

    coordinator.dispose();
    coordinatorDisposed = true;
    await Future<void>.delayed(Duration.zero);

    expect(provider.cancelledRequestIds, [requestId]);
    expect(factory.released, contains(provider));
  });
}

Future<void> _flushAsyncCleanup() async {
  for (var turn = 0; turn < 6; turn++) {
    await Future<void>.delayed(Duration.zero);
  }
}

AnalysisServiceProfile _profile(
  ModelManifest model, {
  GamePerformanceCalibrationArtifact? performanceCalibration,
}) => AnalysisServiceProfile(
  endpoint: Uri.parse('wss://analysis.example.test/v1'),
  model: model,
  winRatePerspective: AnalysisWinRatePerspective.black,
  bearerToken: 'secret',
  performanceCalibration: performanceCalibration,
);

AnalysisBundle _withRequest(AnalysisBundle source, String requestId) =>
    AnalysisBundle(
      requestId: requestId,
      documentId: source.documentId,
      boardSize: source.boardSize,
      model: source.model,
      settings: source.settings,
      moves: source.moves,
      completedAt: source.completedAt,
    );

final class _ControlledProviderFactory implements AnalysisProviderFactory {
  final List<_ControlledProvider> providers = <_ControlledProvider>[];
  final List<AnalysisProvider> released = <AnalysisProvider>[];
  Completer<void>? releaseBarrier;
  int active = 0;
  int maximumObservedActive = 0;

  @override
  AnalysisProvider create(AnalysisServiceProfile profile) {
    if (active >= 1) {
      throw StateError('Fake one-connection bridge is busy.');
    }
    final provider = _ControlledProvider();
    providers.add(provider);
    active += 1;
    if (active > maximumObservedActive) maximumObservedActive = active;
    return provider;
  }

  @override
  Future<void> release(AnalysisProvider provider) async {
    if (released.contains(provider)) return;
    final barrier = releaseBarrier;
    releaseBarrier = null;
    if (barrier != null) await barrier.future;
    await (provider as _ControlledProvider).close();
    released.add(provider);
    active -= 1;
  }
}

final class _ControlledProvider implements AnalysisProvider {
  final StreamController<AnalysisEvent> _events =
      StreamController<AnalysisEvent>.broadcast(sync: true);
  final List<String> cancelledRequestIds = <String>[];
  AnalysisRequest? request;

  @override
  Future<AnalysisBundle> analyze(AnalysisRequest request) {
    throw UnimplementedError('Session tests use the streaming contract.');
  }

  @override
  Stream<AnalysisEvent> stream(AnalysisRequest request) {
    this.request = request;
    return _events.stream;
  }

  @override
  Future<void> cancel(String requestId) async {
    cancelledRequestIds.add(requestId);
  }

  void emit(AnalysisEvent event) => _events.add(event);

  void emitError(Object error) => _events.addError(error, StackTrace.current);

  Future<void> close() async {
    if (!_events.isClosed) await _events.close();
  }
}
