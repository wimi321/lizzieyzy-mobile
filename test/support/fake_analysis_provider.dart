import 'package:lizzieyzy_mobile/domain/domain.dart';

typedef AnalysisFixtureFactory =
    AnalysisBundle Function(AnalysisRequest request);

final class FakeAnalysisCancelledException implements Exception {
  const FakeAnalysisCancelledException(this.requestId);

  final String requestId;
}

/// Test-only deterministic provider. Production code must never depend on it.
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
    if (bundle.documentId != request.document.id ||
        bundle.requestId != request.requestId) {
      throw StateError('Fixture identity does not match the request.');
    }
    return bundle;
  }
}
