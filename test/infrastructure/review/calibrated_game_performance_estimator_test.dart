import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/review/review.dart';

import 'review_test_fixtures.dart';

void main() {
  group('CalibratedGamePerformanceEstimator eligibility', () {
    test('accepts only complete 19-line even games', () {
      final estimator = _estimator();
      final smallBoard = reviewFixture(
        boardSize: BoardSize.nine,
        moveCount: 10,
      );
      final setupGame = reviewFixture(
        moveCount: 40,
        initialPosition: BoardPosition(
          size: BoardSize.nineteen,
          stones: <BoardPoint, StoneColor>{
            const BoardPoint(0, 0): StoneColor.black,
          },
        ),
      );
      final whiteFirst = reviewFixture(
        moveCount: 40,
        firstPlayer: StoneColor.white,
      );

      expect(
        () => estimator.estimate(
          smallBoard.record,
          smallBoard.analysis,
          smallBoard.model,
        ),
        _throwsPerformance(PerformanceEstimationErrorCode.unsupportedBoard),
      );
      for (final fixture in [setupGame, whiteFirst]) {
        expect(
          () => estimator.estimate(
            fixture.record,
            fixture.analysis,
            fixture.model,
          ),
          _throwsPerformance(
            PerformanceEstimationErrorCode.handicapOrSetupGame,
          ),
        );
      }
    });

    test('requires at least 40 non-pass decisions', () {
      final estimator = _estimator();
      final tooShort = reviewFixture(moveCount: 39);
      final exactlyEnough = reviewFixture(moveCount: 40);
      final passDoesNotCount = reviewFixture(
        moveCount: 40,
        passMoveNumbers: const <int>{40},
      );

      for (final fixture in [tooShort, passDoesNotCount]) {
        expect(
          () => estimator.estimate(
            fixture.record,
            fixture.analysis,
            fixture.model,
          ),
          _throwsPerformance(
            PerformanceEstimationErrorCode.insufficientDecisions,
          ),
        );
      }
      expect(
        estimator
            .estimate(
              exactlyEnough.record,
              exactlyEnough.analysis,
              exactlyEnough.model,
            )
            .effectiveDecisions,
        40,
      );
    });

    test('allows only calibration-approved standard or deep profiles', () {
      final estimator = _estimator();
      final quick = reviewFixture(
        moveCount: 40,
        profile: AnalysisProfile.quick,
      );
      final deep = reviewFixture(moveCount: 40, profile: AnalysisProfile.deep);

      expect(
        () => estimator.estimate(quick.record, quick.analysis, quick.model),
        _throwsPerformance(
          PerformanceEstimationErrorCode.disallowedAnalysisProfile,
        ),
      );
      expect(
        estimator
            .estimate(deep.record, deep.analysis, deep.model)
            .effectiveDecisions,
        40,
      );
    });

    test('enforces both configured and actual visit floors', () {
      final estimator = _estimator();
      final lowSettings = reviewFixture(moveCount: 40, visitsPerMove: 999);
      final fixture = reviewFixture(moveCount: 40);
      final underVisitedNode = copyMoveAnalysis(
        fixture.analysis.moves[20],
        visits: 999,
      );
      final nodes = List<MoveAnalysis>.of(fixture.analysis.moves);
      nodes[20] = underVisitedNode;

      expect(
        () => estimator.estimate(
          lowSettings.record,
          lowSettings.analysis,
          lowSettings.model,
        ),
        _throwsPerformance(
          PerformanceEstimationErrorCode.insufficientAnalysisQuality,
        ),
      );
      expect(
        () => estimator.estimate(
          fixture.record,
          copyAnalysis(fixture.analysis, moves: nodes),
          fixture.model,
        ),
        _throwsPerformance(
          PerformanceEstimationErrorCode.insufficientAnalysisQuality,
        ),
      );
    });
  });

  group('CalibratedGamePerformanceEstimator model trust boundary', () {
    test('requires the supplied manifest to match the analyzed model', () {
      final fixture = reviewFixture(moveCount: 40);
      final differentHash = analysisModelFixture(hashCharacter: 'b');
      final differentRanks = ModelManifest(
        id: fixture.model.id,
        displayName: fixture.model.displayName,
        sha256: fixture.model.sha256,
        engineVersion: fixture.model.engineVersion,
        modelVersion: fixture.model.modelVersion,
        license: fixture.model.license,
        humanStyleRanks: <GoRank>[GoRank.kyu(20)],
      );

      for (final manifest in [differentHash, differentRanks]) {
        expect(
          () =>
              _estimator().estimate(fixture.record, fixture.analysis, manifest),
          _throwsPerformance(
            PerformanceEstimationErrorCode.analysisModelMismatch,
          ),
        );
      }
    });

    test(
      'requires the exact model hash to be in the calibration allowlist',
      () {
        final model = analysisModelFixture(hashCharacter: 'b');
        final fixture = reviewFixture(moveCount: 40, model: model);

        expect(
          () => _estimator().estimate(
            fixture.record,
            fixture.analysis,
            fixture.model,
          ),
          _throwsPerformance(
            PerformanceEstimationErrorCode.uncalibratedAnalysisModel,
          ),
        );
      },
    );

    test('normalizes hexadecimal hash case without weakening identity', () {
      final model = analysisModelFixture(hashCharacter: 'A');
      final fixture = reviewFixture(moveCount: 40, model: model);

      final report = _estimator().estimate(
        fixture.record,
        fixture.analysis,
        fixture.model,
      );

      expect(report.effectiveDecisions, 40);
    });

    test('requires HumanSL rank metadata when calibration declares it', () {
      final model = analysisModelFixture(includeHumanRanks: false);
      final fixture = reviewFixture(moveCount: 40, model: model);

      expect(
        () => _estimator().estimate(
          fixture.record,
          fixture.analysis,
          fixture.model,
        ),
        _throwsPerformance(
          PerformanceEstimationErrorCode.missingHumanStyleModel,
        ),
      );
    });

    test('generic policy is accepted only by a calibration that opts out', () {
      final model = analysisModelFixture(includeHumanRanks: false);
      final fixture = reviewFixture(moveCount: 40, model: model);
      final estimator = CalibratedGamePerformanceEstimator(
        calibration: calibrationFixture(requiresHumanStyleRanks: false),
      );

      expect(
        estimator
            .estimate(fixture.record, fixture.analysis, fixture.model)
            .effectiveDecisions,
        40,
      );
    });
  });

  group('CalibratedGamePerformanceEstimator numeric interval', () {
    test('maps calibrated scores to the exact 80% rank bucket', () {
      final low = reviewFixture(moveCount: 40, candidateRankForMove: (_) => 2);
      final middle = reviewFixture(
        moveCount: 40,
        candidateRankForMove: (moveNumber) => moveNumber <= 20 ? 1 : 2,
      );
      final high = reviewFixture(moveCount: 40, candidateRankForMove: (_) => 1);
      final estimator = _estimator();

      final lowReport = estimator.estimate(low.record, low.analysis, low.model);
      final middleReport = estimator.estimate(
        middle.record,
        middle.analysis,
        middle.model,
      );
      final highReport = estimator.estimate(
        high.record,
        high.analysis,
        high.model,
      );

      expect(
        (lowReport.weakerBound, lowReport.strongerBound),
        (GoRank.kyu(10), GoRank.kyu(5)),
      );
      expect(
        (middleReport.weakerBound, middleReport.strongerBound),
        (GoRank.kyu(3), GoRank.kyu(1)),
      );
      expect(
        (highReport.weakerBound, highReport.strongerBound),
        (GoRank.kyu(1), GoRank.dan(1)),
      );
      for (final report in [lowReport, middleReport, highReport]) {
        expect(report.coverage, 0.8);
        expect(report.calibrationModelId, 'game-strength-calibration@1.0.0');
      }
    });

    test('reports low then medium confidence at the calibrated threshold', () {
      final low = reviewFixture(moveCount: 40);
      final medium = reviewFixture(moveCount: 80);
      final estimator = _estimator();

      expect(
        estimator.estimate(low.record, low.analysis, low.model).confidence,
        PerformanceConfidence.low,
      );
      expect(
        estimator
            .estimate(medium.record, medium.analysis, medium.model)
            .confidence,
        PerformanceConfidence.medium,
      );
    });

    test('excludes pass moves from every performance metric', () {
      final fixture = reviewFixture(
        moveCount: 41,
        passMoveNumbers: const <int>{41},
        candidateRankForMove: (moveNumber) => moveNumber == 41 ? 1 : 2,
        pointLossForMove: (moveNumber) => moveNumber == 41 ? 100 : 1,
      );

      final report = _estimator().estimate(
        fixture.record,
        fixture.analysis,
        fixture.model,
      );

      expect(report.effectiveDecisions, 40);
      expect(report.metrics.averagePointLoss, 1);
      expect(report.metrics.medianPointLoss, 1);
      expect(report.metrics.topOneRate, 0);
      expect(report.metrics.topThreeRate, 1);
      expect(report.metrics.severeMistakeRate, 0);
      expect(
        report.metrics.humanStyleLogLikelihood,
        closeTo(math.log(0.12), 1e-12),
      );
    });

    test('uses the declared policy floor when the played move is unlisted', () {
      final fixture = reviewFixture(
        moveCount: 40,
        candidateRankForMove: (_) => 6,
      );

      final report = _estimator().estimate(
        fixture.record,
        fixture.analysis,
        fixture.model,
      );

      expect(
        report.metrics.humanStyleLogLikelihood,
        closeTo(math.log(1e-6), 1e-12),
      );
      expect(report.metrics.topFiveRate, 0);
    });

    test('is deterministic for the same record, analysis, and manifests', () {
      final fixture = reviewFixture(
        moveCount: 40,
        candidateRankForMove: (moveNumber) => (moveNumber % 5) + 1,
        pointLossForMove: (moveNumber) => (moveNumber % 4) * 0.75,
      );
      final estimator = _estimator();

      final first = _performanceSnapshot(
        estimator.estimate(fixture.record, fixture.analysis, fixture.model),
      );
      final second = _performanceSnapshot(
        estimator.estimate(fixture.record, fixture.analysis, fixture.model),
      );

      expect(second, first);
    });
  });

  group('GamePerformanceCalibration manifest', () {
    test('locks interval coverage to a calibrated 80%', () {
      expect(
        () => _copyCalibration(calibrationFixture(), coverage: 0.79),
        throwsArgumentError,
      );
    });

    test('rejects quick analysis and malformed model allowlists', () {
      expect(
        () => _copyCalibration(
          calibrationFixture(),
          allowedProfiles: const <AnalysisProfile>{AnalysisProfile.quick},
        ),
        throwsArgumentError,
      );
      expect(
        () => _copyCalibration(
          calibrationFixture(),
          allowedHashes: const <String>{'not-a-sha256'},
        ),
        throwsArgumentError,
      );
    });

    test('requires ordered contiguous buckets covering all finite scores', () {
      final base = calibrationFixture();
      final gapped = <CalibrationBucket>[
        base.buckets.first,
        CalibrationBucket(
          minimumScore: 0.31,
          maximumScore: 0.7,
          weakerBound: GoRank.kyu(3),
          strongerBound: GoRank.kyu(1),
        ),
        base.buckets.last,
      ];

      expect(
        () => _copyCalibration(base, buckets: gapped),
        throwsArgumentError,
      );
    });
  });
}

CalibratedGamePerformanceEstimator _estimator() =>
    CalibratedGamePerformanceEstimator(calibration: calibrationFixture());

Matcher _throwsPerformance(PerformanceEstimationErrorCode code) => throwsA(
  isA<PerformanceEstimationException>().having(
    (exception) => exception.code,
    'code',
    code,
  ),
);

List<Object> _performanceSnapshot(GamePerformanceReport report) => <Object>[
  report.weakerBound,
  report.strongerBound,
  report.coverage,
  report.confidence,
  report.effectiveDecisions,
  report.metrics.averagePointLoss,
  report.metrics.medianPointLoss,
  report.metrics.topOneRate,
  report.metrics.topThreeRate,
  report.metrics.topFiveRate,
  report.metrics.severeMistakeRate,
  report.metrics.humanStyleLogLikelihood,
  report.calibrationModelId,
];

GamePerformanceCalibration _copyCalibration(
  GamePerformanceCalibration source, {
  Set<String>? allowedHashes,
  Set<AnalysisProfile>? allowedProfiles,
  List<CalibrationBucket>? buckets,
  double? coverage,
}) {
  return GamePerformanceCalibration(
    model: source.model,
    modelCard: source.modelCard,
    intercept: source.intercept,
    featureWeights: source.featureWeights,
    buckets: buckets ?? source.buckets,
    allowedAnalysisModelSha256:
        allowedHashes ?? source.allowedAnalysisModelSha256,
    allowedProfiles: allowedProfiles ?? source.allowedProfiles,
    minimumVisitsPerPosition: source.minimumVisitsPerPosition,
    mediumConfidenceDecisions: source.mediumConfidenceDecisions,
    severeMistakePointLoss: source.severeMistakePointLoss,
    policyFloor: source.policyFloor,
    requiresHumanStyleRanks: source.requiresHumanStyleRanks,
    coverage: coverage ?? source.coverage,
  );
}
