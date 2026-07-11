import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

import 'analysis_provider_factory.dart';
import 'analysis_provider_scheduler.dart';
import 'analysis_session.dart';

/// App-scoped owner of analysis sessions.
///
/// A route or widget only listens to a session. Removing that listener does not
/// dispose the session, its provider, or its in-flight request.
final class AnalysisCoordinator extends ChangeNotifier {
  AnalysisCoordinator({
    required AnalysisProviderFactory providerFactory,
    required ReviewBuilder reviewBuilder,
    AnalysisRequestIdFactory? requestIdFactory,
    GamePerformanceEstimatorFactory? performanceEstimatorFactory,
  }) : _providerFactory = providerFactory,
       _providerScheduler = AnalysisProviderScheduler(providerFactory),
       _reviewBuilder = reviewBuilder,
       _performanceEstimatorFactory = performanceEstimatorFactory,
       _requestIdFactory = requestIdFactory ?? _secureRequestId;

  final AnalysisProviderFactory _providerFactory;
  final AnalysisProviderScheduler _providerScheduler;
  final ReviewBuilder _reviewBuilder;
  final GamePerformanceEstimatorFactory? _performanceEstimatorFactory;
  final AnalysisRequestIdFactory _requestIdFactory;
  final Map<String, AnalysisSessionController> _sessions = {};
  final Set<Future<void>> _retiringSessions = <Future<void>>{};
  var _closed = false;

  List<AnalysisSessionController> get sessions =>
      List<AnalysisSessionController>.unmodifiable(_sessions.values);

  AnalysisSessionController? sessionFor(String documentId) =>
      _sessions[documentId];

  /// Returns a session only when it was created for the same analysis input.
  /// A document id is a storage key, not a sufficient cache key: a corrected
  /// position or move sequence may legitimately replace content under it.
  AnalysisSessionController? sessionForDocument(KifuDocument document) {
    final session = _sessions[document.id];
    return session != null && _sameAnalysisDocument(session.document, document)
        ? session
        : null;
  }

  AnalysisSessionController? sessionForRequest({
    required KifuDocument document,
    required AnalysisServiceProfile? serviceProfile,
    required AnalysisSettings settings,
  }) {
    final session = sessionForDocument(document);
    if (session == null ||
        !_sameSettings(session.settings, settings) ||
        !_sameService(session.serviceProfile, serviceProfile)) {
      return null;
    }
    return session;
  }

  AnalysisSessionController start({
    required KifuDocument document,
    required AnalysisServiceProfile? serviceProfile,
    required AnalysisSettings settings,
  }) {
    if (_closed) throw StateError('Analysis coordinator is closed.');
    final existing = _sessions[document.id];
    if (existing != null &&
        _sameAnalysisDocument(existing.document, document) &&
        _sameSettings(existing.settings, settings) &&
        _sameService(existing.serviceProfile, serviceProfile)) {
      return existing;
    }
    if (existing != null) {
      existing.removeListener(_notifySessionChanged);
      _sessions.remove(document.id);
      _retire(existing);
    }

    final session = AnalysisSessionController(
      document: document,
      providerFactory: _providerFactory,
      providerScheduler: _providerScheduler,
      reviewBuilder: _reviewBuilder,
      settings: settings,
      serviceProfile: serviceProfile,
      requestIdFactory: _requestIdFactory,
      performanceEstimatorFactory: _performanceEstimatorFactory,
    );
    session.addListener(_notifySessionChanged);
    _sessions[document.id] = session;
    notifyListeners();
    return session;
  }

  Future<void> cancel(String documentId) async {
    await _sessions[documentId]?.cancel();
  }

  Future<void> retry(
    String documentId, {
    AnalysisServiceProfile? serviceProfile,
    AnalysisSettings? settings,
  }) async {
    final session = _sessions[documentId];
    if (session == null) {
      throw StateError('No analysis session exists for "$documentId".');
    }
    await session.retry(serviceProfile: serviceProfile, settings: settings);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final sessions = _sessions.values.toList(growable: false);
    _sessions.clear();
    final closing = <Future<void>>[];
    for (final session in sessions) {
      session.removeListener(_notifySessionChanged);
      // Start every close before awaiting any of them. This cancels queued
      // leases before a running session can release its provider and wake a
      // session that the coordinator is itself shutting down.
      closing.add(_closeAndDispose(session));
    }
    await Future.wait<void>(<Future<void>>[...closing, ..._retiringSessions]);
  }

  @override
  void dispose() {
    close().ignore();
    super.dispose();
  }

  void _retire(AnalysisSessionController session) {
    late final Future<void> cleanup;
    cleanup = _closeAndDispose(
      session,
    ).whenComplete(() => _retiringSessions.remove(cleanup));
    _retiringSessions.add(cleanup);
    // The future remains owned by [_retiringSessions] and is awaited by
    // [close]. Ignore only prevents an automatic replacement failure from
    // becoming an unhandled asynchronous error before app shutdown.
    cleanup.ignore();
  }

  Future<void> _closeAndDispose(AnalysisSessionController session) async {
    try {
      await session.close();
    } finally {
      session.dispose();
    }
  }

  void _notifySessionChanged() {
    if (!_closed) notifyListeners();
  }
}

bool _sameAnalysisDocument(KifuDocument left, KifuDocument right) {
  if (left.runtimeType != right.runtimeType ||
      left.id != right.id ||
      left.rules != right.rules ||
      left.boardSize != right.boardSize) {
    return false;
  }
  return switch ((left, right)) {
    (
      PositionSnapshot(
        position: final leftPosition,
        playerToMove: final leftPlayer,
      ),
      PositionSnapshot(
        position: final rightPosition,
        playerToMove: final rightPlayer,
      ),
    ) =>
      leftPosition == rightPosition && leftPlayer == rightPlayer,
    (
      VerifiedGameRecord(
        initialPosition: final leftPosition,
        moves: final leftMoves,
        firstPlayer: final leftPlayer,
      ),
      VerifiedGameRecord(
        initialPosition: final rightPosition,
        moves: final rightMoves,
        firstPlayer: final rightPlayer,
      ),
    ) =>
      leftPosition == rightPosition &&
          leftPlayer == rightPlayer &&
          _sameMoves(leftMoves, rightMoves),
    (
      PartialGameRecord(
        initialPosition: final leftPosition,
        moves: final leftMoves,
        firstPlayer: final leftPlayer,
        startingMoveNumber: final leftStart,
      ),
      PartialGameRecord(
        initialPosition: final rightPosition,
        moves: final rightMoves,
        firstPlayer: final rightPlayer,
        startingMoveNumber: final rightStart,
      ),
    ) =>
      leftPosition == rightPosition &&
          leftPlayer == rightPlayer &&
          leftStart == rightStart &&
          _sameMoves(leftMoves, rightMoves),
    _ => false,
  };
}

bool _sameMoves(List<Move> left, List<Move> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _sameSettings(AnalysisSettings left, AnalysisSettings right) =>
    left.profile == right.profile &&
    left.visitsPerMove == right.visitsPerMove &&
    left.criticalMoveVisits == right.criticalMoveVisits &&
    left.maxCandidates == right.maxCandidates &&
    left.includeOwnership == right.includeOwnership;

bool _sameService(AnalysisServiceProfile? left, AnalysisServiceProfile? right) {
  if (left == null || right == null) return left == right;
  return left.endpoint == right.endpoint &&
      left.model.sha256 == right.model.sha256 &&
      left.model.humanModelSha256 == right.model.humanModelSha256 &&
      left.humanStyleProfile == right.humanStyleProfile &&
      left.winRatePerspective == right.winRatePerspective &&
      left.performanceCalibration?.sha256 ==
          right.performanceCalibration?.sha256 &&
      left.bearerToken == right.bearerToken;
}

String _secureRequestId() {
  final random = Random.secure();
  final buffer = StringBuffer('analysis-');
  for (var index = 0; index < 4; index++) {
    buffer.write(random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0'));
  }
  return buffer.toString();
}
