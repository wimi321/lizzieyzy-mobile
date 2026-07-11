import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

import 'analysis_provider_factory.dart';
import 'analysis_provider_scheduler.dart';

enum AnalysisSessionStatus {
  configurationRequired,
  queued,
  running,
  completed,
  failed,
  cancelled,
}

final class AnalysisSessionFailure {
  const AnalysisSessionFailure({
    required this.code,
    required this.message,
    required this.isRetryable,
    this.cause,
    this.stackTrace,
  });

  final String code;
  final String message;
  final bool isRetryable;

  /// Diagnostic-only cause. Presentation code should render [message], not the
  /// raw cause, which may contain implementation details.
  final Object? cause;
  final StackTrace? stackTrace;
}

@immutable
final class AnalysisSessionState {
  const AnalysisSessionState({
    required this.status,
    required this.documentId,
    required this.attempt,
    this.requestId,
    this.queuePosition,
    this.completedPositions = 0,
    this.totalPositions = 0,
    this.latestAnalysis,
    this.bundle,
    this.reviewReport,
    this.performanceReport,
    this.failure,
  });

  final AnalysisSessionStatus status;
  final String documentId;
  final int attempt;
  final String? requestId;
  final int? queuePosition;
  final int completedPositions;
  final int totalPositions;
  final MoveAnalysis? latestAnalysis;
  final AnalysisBundle? bundle;
  final ReviewReport? reviewReport;
  final GamePerformanceReport? performanceReport;
  final AnalysisSessionFailure? failure;

  double? get progress => totalPositions <= 0
      ? null
      : (completedPositions / totalPositions).clamp(0, 1);

  bool get canCancel =>
      status == AnalysisSessionStatus.queued ||
      status == AnalysisSessionStatus.running;

  bool get canRetry => switch (status) {
    AnalysisSessionStatus.configurationRequired ||
    AnalysisSessionStatus.failed ||
    AnalysisSessionStatus.cancelled => true,
    AnalysisSessionStatus.queued ||
    AnalysisSessionStatus.running ||
    AnalysisSessionStatus.completed => false,
  };
}

typedef AnalysisRequestIdFactory = String Function();
typedef GamePerformanceEstimatorFactory =
    GamePerformanceEstimator Function(GamePerformanceCalibration calibration);

/// App-owned controller for one document's analysis lifecycle.
///
/// Widgets may add and remove listeners freely. They do not own this
/// controller and therefore cannot accidentally cancel analysis when disposed.
final class AnalysisSessionController extends ChangeNotifier {
  AnalysisSessionController({
    required this.document,
    required AnalysisProviderFactory providerFactory,
    required AnalysisProviderScheduler providerScheduler,
    required ReviewBuilder reviewBuilder,
    required AnalysisSettings settings,
    required AnalysisServiceProfile? serviceProfile,
    required AnalysisRequestIdFactory requestIdFactory,
    GamePerformanceEstimatorFactory? performanceEstimatorFactory,
  }) : _providerFactory = providerFactory,
       _providerScheduler = providerScheduler,
       _reviewBuilder = reviewBuilder,
       _settings = settings,
       _serviceProfile = serviceProfile,
       _requestIdFactory = requestIdFactory,
       _performanceEstimatorFactory = performanceEstimatorFactory,
       _state = AnalysisSessionState(
         status: serviceProfile == null
             ? AnalysisSessionStatus.configurationRequired
             : AnalysisSessionStatus.queued,
         documentId: document.id,
         attempt: 0,
       ) {
    if (serviceProfile != null) _beginAttempt();
  }

  final KifuDocument document;
  final AnalysisProviderFactory _providerFactory;
  final AnalysisProviderScheduler _providerScheduler;
  final ReviewBuilder _reviewBuilder;
  final AnalysisRequestIdFactory _requestIdFactory;
  final GamePerformanceEstimatorFactory? _performanceEstimatorFactory;

  AnalysisSettings _settings;
  AnalysisServiceProfile? _serviceProfile;
  AnalysisSessionState _state;
  AnalysisProvider? _provider;
  StreamSubscription<AnalysisEvent>? _subscription;
  AnalysisProviderLeaseRequest? _leaseRequest;
  AnalysisProviderLease? _lease;
  Future<void>? _activation;
  Future<void>? _cleanup;
  var _generation = 0;
  var _closed = false;

  AnalysisSessionState get state => _state;
  AnalysisSettings get settings => _settings;
  AnalysisServiceProfile? get serviceProfile => _serviceProfile;

  Future<void> retry({
    AnalysisServiceProfile? serviceProfile,
    AnalysisSettings? settings,
  }) async {
    if (_closed) throw StateError('Analysis session is closed.');
    if (!_state.canRetry) {
      throw StateError(
        'Only configuration, failed, or cancelled sessions retry.',
      );
    }
    await _stopAttempt(cancelRemote: false);
    _serviceProfile = serviceProfile ?? _serviceProfile;
    _settings = settings ?? _settings;
    if (_serviceProfile == null) {
      _replaceState(
        AnalysisSessionState(
          status: AnalysisSessionStatus.configurationRequired,
          documentId: document.id,
          attempt: _state.attempt,
        ),
      );
      return;
    }
    _beginAttempt();
  }

  Future<void> cancel() async {
    if (_closed || !_state.canCancel) return;
    final generation = _generation;
    final requestId = _state.requestId;
    final wasRunning = _state.status == AnalysisSessionStatus.running;
    _replaceState(
      AnalysisSessionState(
        status: AnalysisSessionStatus.cancelled,
        documentId: document.id,
        attempt: _state.attempt,
        requestId: requestId,
        completedPositions: _state.completedPositions,
        totalPositions: _state.totalPositions,
        latestAnalysis: _state.latestAnalysis,
      ),
    );
    try {
      // The stop future owns remote cancellation, stream shutdown, provider
      // release, and lease release as one serialized operation. A retry invoked
      // in the same event-loop turn awaits this exact future.
      await _stopAttempt(cancelRemote: wasRunning, generation: generation);
    } on Object catch (error, stackTrace) {
      if (!_closed && _state.status == AnalysisSessionStatus.cancelled) {
        _replaceState(
          AnalysisSessionState(
            status: AnalysisSessionStatus.failed,
            documentId: document.id,
            attempt: _state.attempt,
            requestId: requestId,
            completedPositions: _state.completedPositions,
            totalPositions: _state.totalPositions,
            latestAnalysis: _state.latestAnalysis,
            failure: AnalysisSessionFailure(
              code: 'cancel_failed',
              message: 'The analysis request could not be cancelled.',
              isRetryable: true,
              cause: error,
              stackTrace: stackTrace,
            ),
          ),
        );
      }
    }
  }

  Future<void> close() async {
    if (_closed) return;
    final cancelRemote = _state.status == AnalysisSessionStatus.running;
    _closed = true;
    await _stopAttempt(cancelRemote: cancelRemote);
  }

  @override
  void dispose() {
    close().ignore();
    super.dispose();
  }

  void _beginAttempt() {
    final profile = _serviceProfile;
    if (profile == null) return;
    final generation = ++_generation;
    final attempt = _state.attempt + 1;
    final requestId = _requestIdFactory().trim();
    if (requestId.isEmpty) {
      throw StateError('Analysis request ids cannot be empty.');
    }

    final leaseRequest = _providerScheduler.acquire(
      profile,
      onQueuePositionChanged: (position) =>
          _onQueuePositionChanged(generation, position),
    );
    final immediateLease = leaseRequest.immediateLease;
    if (immediateLease != null) {
      _lease = immediateLease;
      _replaceState(
        AnalysisSessionState(
          status: AnalysisSessionStatus.running,
          documentId: document.id,
          attempt: attempt,
          requestId: requestId,
        ),
      );
      _activateProvider(generation, profile, requestId);
      return;
    }

    _leaseRequest = leaseRequest;
    _replaceState(
      AnalysisSessionState(
        status: AnalysisSessionStatus.queued,
        documentId: document.id,
        attempt: attempt,
        requestId: requestId,
        queuePosition: leaseRequest.initialQueuePosition,
      ),
    );
    late final Future<void> activation;
    activation = _waitForLease(generation, profile, requestId, leaseRequest)
        .whenComplete(() {
          if (identical(_activation, activation)) _activation = null;
        });
    _activation = activation;
    // [_activation] remains owned and is awaited by every stop/retry/close.
    activation.ignore();
  }

  Future<void> _waitForLease(
    int generation,
    AnalysisServiceProfile profile,
    String requestId,
    AnalysisProviderLeaseRequest request,
  ) async {
    final lease = await request.granted;
    if (lease == null) return;
    if (!_isCurrent(generation)) {
      lease.release();
      return;
    }
    _leaseRequest = null;
    _lease = lease;
    _replaceState(
      AnalysisSessionState(
        status: AnalysisSessionStatus.running,
        documentId: document.id,
        attempt: _state.attempt,
        requestId: requestId,
      ),
    );
    _activateProvider(generation, profile, requestId);
  }

  void _onQueuePositionChanged(int generation, int position) {
    if (!_isCurrent(generation) ||
        _state.status != AnalysisSessionStatus.queued) {
      return;
    }
    _replaceState(
      AnalysisSessionState(
        status: AnalysisSessionStatus.queued,
        documentId: document.id,
        attempt: _state.attempt,
        requestId: _state.requestId,
        queuePosition: position,
      ),
    );
  }

  void _activateProvider(
    int generation,
    AnalysisServiceProfile profile,
    String requestId,
  ) {
    if (!_isCurrent(generation)) return;
    try {
      final provider = _providerFactory.create(profile);
      _provider = provider;
      final request = AnalysisRequest(
        requestId: requestId,
        document: document,
        settings: _settings,
      );
      final subscription = provider
          .stream(request)
          .listen(
            (event) => _onEvent(generation, event),
            onError: (Object error, StackTrace stackTrace) =>
                _onError(generation, error, stackTrace),
            onDone: () => _onDone(generation),
            cancelOnError: false,
          );
      if (_isCurrent(generation)) {
        _subscription = subscription;
      } else {
        subscription.cancel().ignore();
      }
    } on Object catch (error, stackTrace) {
      _fail(
        generation,
        AnalysisSessionFailure(
          code: 'provider_creation_failed',
          message: 'The analysis provider could not be created.',
          isRetryable: true,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  void _onEvent(int generation, AnalysisEvent event) {
    if (!_isCurrent(generation) || event.requestId != _state.requestId) return;
    try {
      switch (event) {
        case AnalysisStarted(:final totalPositions):
          if (totalPositions <= 0 || _state.completedPositions != 0) {
            throw StateError('Analysis total must be positive.');
          }
          _replaceState(
            AnalysisSessionState(
              status: AnalysisSessionStatus.running,
              documentId: document.id,
              attempt: _state.attempt,
              requestId: _state.requestId,
              completedPositions: 0,
              totalPositions: totalPositions,
            ),
          );
        case PositionAnalyzed(
          :final analysis,
          :final completedPositions,
          :final totalPositions,
        ):
          if (totalPositions <= 0 ||
              completedPositions < _state.completedPositions ||
              completedPositions < 1 ||
              completedPositions > totalPositions ||
              analysis.moveNumber + 1 != completedPositions ||
              (_state.totalPositions > 0 &&
                  totalPositions != _state.totalPositions)) {
            throw StateError('Analysis provider emitted invalid progress.');
          }
          _replaceState(
            AnalysisSessionState(
              status: AnalysisSessionStatus.running,
              documentId: document.id,
              attempt: _state.attempt,
              requestId: _state.requestId,
              completedPositions: completedPositions,
              totalPositions: totalPositions,
              latestAnalysis: analysis,
            ),
          );
        case AnalysisCompleted(:final bundle):
          if (bundle.requestId != _state.requestId ||
              bundle.documentId != document.id ||
              (_state.totalPositions > 0 &&
                  bundle.moves.length != _state.totalPositions)) {
            throw StateError('Completed analysis does not match this session.');
          }
          final verifiedRecord = switch (document) {
            final VerifiedGameRecord record => record,
            _ => null,
          };
          final report = verifiedRecord == null
              ? null
              : _reviewBuilder.build(verifiedRecord, bundle);
          final performanceReport = verifiedRecord == null
              ? null
              : _estimatePerformance(verifiedRecord, bundle);
          _replaceState(
            AnalysisSessionState(
              status: AnalysisSessionStatus.completed,
              documentId: document.id,
              attempt: _state.attempt,
              requestId: _state.requestId,
              completedPositions: bundle.moves.length,
              totalPositions: bundle.moves.length,
              latestAnalysis: bundle.moves.isEmpty ? null : bundle.moves.last,
              bundle: bundle,
              reviewReport: report,
              performanceReport: performanceReport,
            ),
          );
          _scheduleStop(cancelRemote: false, generation: generation);
        case AnalysisCancelled():
          _replaceState(
            AnalysisSessionState(
              status: AnalysisSessionStatus.cancelled,
              documentId: document.id,
              attempt: _state.attempt,
              requestId: _state.requestId,
              completedPositions: _state.completedPositions,
              totalPositions: _state.totalPositions,
              latestAnalysis: _state.latestAnalysis,
            ),
          );
          _scheduleStop(cancelRemote: false, generation: generation);
        case AnalysisFailed(:final code, :final message, :final isRetryable):
          _fail(
            generation,
            AnalysisSessionFailure(
              code: code,
              message: message,
              isRetryable: isRetryable,
            ),
          );
      }
    } on Object catch (error, stackTrace) {
      _fail(
        generation,
        AnalysisSessionFailure(
          code: 'invalid_analysis_result',
          message: 'The analysis result failed validation.',
          isRetryable: false,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  GamePerformanceReport? _estimatePerformance(
    VerifiedGameRecord record,
    AnalysisBundle bundle,
  ) {
    final calibration = _serviceProfile?.performanceCalibration?.calibration;
    final configuredModel = _serviceProfile?.model;
    final factory = _performanceEstimatorFactory;
    if (calibration == null || configuredModel == null || factory == null) {
      return null;
    }
    try {
      return factory(calibration).estimate(record, bundle, configuredModel);
    } on Object {
      // Rank output is optional and fail-closed. An ineligible game, missing
      // HumanSL evidence, or any calibration mismatch must never fabricate a
      // report or turn an otherwise valid numeric review into a failed session.
      return null;
    }
  }

  void _onError(int generation, Object error, StackTrace stackTrace) {
    if (!_isCurrent(generation)) return;
    _fail(
      generation,
      AnalysisSessionFailure(
        code: 'provider_error',
        message: 'The analysis provider failed.',
        isRetryable: true,
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  void _onDone(int generation) {
    if (!_isCurrent(generation)) return;
    if (_state.status == AnalysisSessionStatus.running) {
      _fail(
        generation,
        const AnalysisSessionFailure(
          code: 'stream_ended',
          message: 'The analysis stream ended before completion.',
          isRetryable: true,
        ),
      );
    } else {
      _scheduleStop(cancelRemote: false, generation: generation);
    }
  }

  void _fail(int generation, AnalysisSessionFailure failure) {
    if (!_isCurrent(generation)) return;
    _replaceState(
      AnalysisSessionState(
        status: AnalysisSessionStatus.failed,
        documentId: document.id,
        attempt: _state.attempt,
        requestId: _state.requestId,
        completedPositions: _state.completedPositions,
        totalPositions: _state.totalPositions,
        latestAnalysis: _state.latestAnalysis,
        failure: failure,
      ),
    );
    _scheduleStop(cancelRemote: false, generation: generation);
  }

  Future<void> _stopAttempt({required bool cancelRemote, int? generation}) {
    final activeCleanup = _cleanup;
    if (activeCleanup != null) return activeCleanup;
    if (generation != null && generation != _generation) {
      return Future<void>.value();
    }
    if (_provider == null &&
        _subscription == null &&
        _leaseRequest == null &&
        _lease == null &&
        _activation == null) {
      return Future<void>.value();
    }

    late final Future<void> cleanup;
    cleanup = _performStop(cancelRemote: cancelRemote).whenComplete(() {
      if (identical(_cleanup, cleanup)) _cleanup = null;
    });
    _cleanup = cleanup;
    return cleanup;
  }

  Future<void> _performStop({required bool cancelRemote}) async {
    final provider = _provider;
    final subscription = _subscription;
    final leaseRequest = _leaseRequest;
    final lease = _lease;
    final activation = _activation;
    final requestId = _state.requestId;
    _provider = null;
    _subscription = null;
    _leaseRequest = null;
    _lease = null;
    _generation += 1;
    leaseRequest?.cancel();

    Object? firstError;
    StackTrace? firstStackTrace;
    Future<void> guard(Future<void> Function() operation) async {
      try {
        await operation();
      } on Object catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    if (activation != null) {
      await guard(() => activation);
    }
    if (cancelRemote && provider != null && requestId != null) {
      await guard(() => provider.cancel(requestId));
    }
    if (subscription != null) {
      await guard(subscription.cancel);
    }
    if (provider != null) {
      await guard(() => _providerFactory.release(provider));
    }
    // A queued successor may create its provider only after the previous
    // provider's release has completed, even when release itself reported an
    // error. This prevents a permanent busy lane while preserving the error.
    lease?.release();
    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStackTrace!);
    }
  }

  void _scheduleStop({required bool cancelRemote, required int generation}) {
    // The cleanup future is retained in [_cleanup]. Retry and close await the
    // exact same future, so provider release is never a detached operation.
    _stopAttempt(cancelRemote: cancelRemote, generation: generation).ignore();
  }

  bool _isCurrent(int generation) => !_closed && generation == _generation;

  void _replaceState(AnalysisSessionState next) {
    _state = next;
    if (!_closed) notifyListeners();
  }
}
