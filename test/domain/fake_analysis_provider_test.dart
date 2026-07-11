import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

import 'test_fixtures.dart';

void main() {
  late VerifiedGameRecord document;
  late AnalysisRequest request;
  late AnalysisBundle fixture;

  setUp(() {
    document = verifiedFixture();
    request = AnalysisRequest(
      requestId: 'request-1',
      document: document,
      settings: analysisSettings,
    );
    fixture = analysisFixture();
  });

  test('analyze returns deterministic fixture and records request', () async {
    final provider = FakeAnalysisProvider(
      fixturesByDocumentId: {'game-1': fixture},
    );

    expect(await provider.analyze(request), same(fixture));
    expect(provider.requests, [request]);
  });

  test('stream emits start, per-position progress, and completion', () async {
    final provider = FakeAnalysisProvider(
      fixturesByDocumentId: {'game-1': fixture},
    );

    final events = await provider.stream(request).toList();

    expect(events.first, isA<AnalysisStarted>());
    expect(
      events.whereType<PositionAnalyzed>(),
      hasLength(fixture.moves.length),
    );
    expect(events.last, isA<AnalysisCompleted>());
    expect((events.last as AnalysisCompleted).bundle, same(fixture));
  });

  test('cancellation interrupts stream deterministically', () async {
    final provider = FakeAnalysisProvider(
      fixturesByDocumentId: {'game-1': fixture},
    );
    final events = <AnalysisEvent>[];

    await for (final event in provider.stream(request)) {
      events.add(event);
      if (event is AnalysisStarted) {
        await provider.cancel(request.requestId);
      }
    }

    expect(events, hasLength(2));
    expect(events.first, isA<AnalysisStarted>());
    expect(events.last, isA<AnalysisCancelled>());
    expect(provider.isCancelled(request.requestId), isTrue);
  });

  test(
    'analyze throws after cancellation and missing fixtures fail loudly',
    () async {
      final provider = FakeAnalysisProvider(
        fixturesByDocumentId: {'game-1': fixture},
      );
      await provider.cancel(request.requestId);

      await expectLater(
        provider.analyze(request),
        throwsA(isA<FakeAnalysisCancelledException>()),
      );
      await expectLater(
        FakeAnalysisProvider().analyze(request),
        throwsStateError,
      );
    },
  );
}
