import '../analysis.dart';
import '../contracts.dart';

typedef AnalysisFixtureFactory =
    AnalysisBundle Function(AnalysisRequest request);

final class FakeAnalysisCancelledException implements Exception {
  const FakeAnalysisCancelledException(this.requestId);

  final String requestId;

  @override
  String toString() => 'Analysis request "$requestId" was cancelled.';
}

/// Deterministic in-memory provider for feature fixtures and domain tests.
///
/// The caller owns request ids, so cancellation, retries, and golden fixtures
/// remain repeatable without clocks, random values, or platform channels.
final class FakeAnalysisProvider implements AnalysisProvider {
  FakeAnalysisProvider({
    Map<String, AnalysisBundle> fixturesByDocumentId = const {},
    AnalysisFixtureFactory? fixtureFactory,
  }) : _fixturesByDocumentId = Map.unmodifiable(fixturesByDocumentId),
       _fixtureFactory = fixtureFactory;

  final Map<String, AnalysisBundle> _fixturesByDocumentId;
  final AnalysisFixtureFactory? _fixtureFactory;
  final Set<String> _cancelledRequestIds = {};
  final List<AnalysisRequest> _requests = [];

  List<AnalysisRequest> get requests => List.unmodifiable(_requests);

  bool isCancelled(String requestId) =>
      _cancelledRequestIds.contains(requestId);

  void resetCancellation(String requestId) =>
      _cancelledRequestIds.remove(requestId);

  @override
  Future<AnalysisBundle> analyze(AnalysisRequest request) async {
    _requests.add(request);
    if (isCancelled(request.requestId)) {
      throw FakeAnalysisCancelledException(request.requestId);
    }
    return _fixtureFor(request);
  }

  @override
  Stream<AnalysisEvent> stream(AnalysisRequest request) async* {
    _requests.add(request);
    if (isCancelled(request.requestId)) {
      yield AnalysisCancelled(request.requestId);
      return;
    }

    final bundle = _fixtureFor(request);
    yield AnalysisStarted(
      request.requestId,
      totalPositions: bundle.moves.length,
    );
    for (var index = 0; index < bundle.moves.length; index++) {
      if (isCancelled(request.requestId)) {
        yield AnalysisCancelled(request.requestId);
        return;
      }
      yield PositionAnalyzed(
        request.requestId,
        analysis: bundle.moves[index],
        completedPositions: index + 1,
        totalPositions: bundle.moves.length,
      );
    }
    if (isCancelled(request.requestId)) {
      yield AnalysisCancelled(request.requestId);
      return;
    }
    yield AnalysisCompleted(request.requestId, bundle: bundle);
  }

  @override
  Future<void> cancel(String requestId) async {
    _cancelledRequestIds.add(requestId);
  }

  AnalysisBundle _fixtureFor(AnalysisRequest request) {
    final bundle =
        _fixtureFactory?.call(request) ??
        _fixturesByDocumentId[request.document.id];
    if (bundle == null) {
      throw StateError(
        'No analysis fixture registered for document "${request.document.id}".',
      );
    }
    if (bundle.documentId != request.document.id) {
      throw StateError('Fixture document id does not match the request.');
    }
    if (bundle.requestId != request.requestId) {
      throw StateError('Fixture request id does not match the request.');
    }
    return bundle;
  }
}
