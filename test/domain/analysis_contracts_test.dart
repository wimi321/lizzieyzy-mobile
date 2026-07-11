import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

import 'test_fixtures.dart';

void main() {
  group('analysis values', () {
    test('bundle indexes sorted move analyses', () {
      final bundle = analysisFixture();

      expect(bundle.analysisAt(0), isNotNull);
      expect(bundle.analysisAt(1)?.playedMovePointLoss, 0.3);
      expect(bundle.analysisAt(999), isNull);
    });

    test('bundle rejects unsorted moves and malformed ownership', () {
      final valid = analysisFixture();
      expect(
        () => AnalysisBundle(
          requestId: 'bad-order',
          documentId: 'game-1',
          boardSize: BoardSize.nineteen,
          model: valid.model,
          settings: valid.settings,
          moves: valid.moves.reversed.toList(),
          completedAt: valid.completedAt,
        ),
        throwsArgumentError,
      );
      expect(
        () => AnalysisBundle(
          requestId: 'bad-ownership',
          documentId: 'game-1',
          boardSize: BoardSize.nineteen,
          model: valid.model,
          settings: valid.settings,
          moves: [
            MoveAnalysis(
              moveNumber: 0,
              toPlay: StoneColor.black,
              playedMove: null,
              blackWinRate: 0.5,
              scoreLead: 0,
              visits: 1,
              candidates: const [],
              ownership: const [0],
            ),
          ],
          completedAt: valid.completedAt,
        ),
        throwsArgumentError,
      );
    });

    test('model manifest requires a reproducible hash and license', () {
      expect(
        () => ModelManifest(
          id: 'model',
          displayName: 'Model',
          sha256: 'not-a-hash',
          engineVersion: '1',
          modelVersion: '1',
          license: 'CC-BY-4.0',
        ),
        throwsFormatException,
      );
      expect(modelFixture().sha256, hasLength(64));
    });
  });

  group('performance report', () {
    const metrics = PerformanceMetrics(
      averagePointLoss: 1.2,
      medianPointLoss: 0.8,
      topOneRate: 0.42,
      topThreeRate: 0.7,
      topFiveRate: 0.82,
      severeMistakeRate: 0.05,
      humanStyleLogLikelihood: -123.4,
    );

    test('rank ordering crosses the kyu/dan boundary', () {
      expect(GoRank.kyu(3).compareTo(GoRank.kyu(1)), lessThan(0));
      expect(GoRank.kyu(1).compareTo(GoRank.dan(1)), lessThan(0));
      expect(GoRank.dan(1).label, '1d');
    });

    test('requires 40 decisions and a correctly ordered interval', () {
      expect(
        () => GamePerformanceReport(
          weakerBound: GoRank.kyu(3),
          strongerBound: GoRank.kyu(1),
          confidence: PerformanceConfidence.medium,
          effectiveDecisions: 86,
          metrics: metrics,
          calibrationModelId: 'calibration-v1',
        ),
        returnsNormally,
      );
      expect(
        () => GamePerformanceReport(
          weakerBound: GoRank.kyu(3),
          strongerBound: GoRank.kyu(1),
          confidence: PerformanceConfidence.low,
          effectiveDecisions: 39,
          metrics: metrics,
          calibrationModelId: 'calibration-v1',
        ),
        throwsArgumentError,
      );
      expect(
        () => GamePerformanceReport(
          weakerBound: GoRank.dan(1),
          strongerBound: GoRank.kyu(1),
          confidence: PerformanceConfidence.low,
          effectiveDecisions: 40,
          metrics: metrics,
          calibrationModelId: 'calibration-v1',
        ),
        throwsArgumentError,
      );
    });
  });
}
