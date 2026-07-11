import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/analysis/analysis.dart';

import '../review/review_test_fixtures.dart';

void main() {
  final model = ModelManifest(
    id: 'katago-test',
    displayName: 'KataGo test',
    sha256: List<String>.filled(64, 'a').join(),
    engineVersion: '1.16.5',
    modelVersion: 'b18-test',
    license: 'CC-BY-4.0',
  );

  test('maps application service profiles to WSS provider config', () async {
    const factory = WssAnalysisProviderFactory(
      connectionTimeout: Duration(seconds: 7),
      analysisPvLength: 16,
    );
    final expectedPerspectives =
        <AnalysisWinRatePerspective, KataGoReportPerspective>{
          AnalysisWinRatePerspective.black: KataGoReportPerspective.black,
          AnalysisWinRatePerspective.white: KataGoReportPerspective.white,
          AnalysisWinRatePerspective.sideToMove:
              KataGoReportPerspective.sideToMove,
        };

    for (final entry in expectedPerspectives.entries) {
      final profile = AnalysisServiceProfile(
        endpoint: Uri.parse('wss://analysis.example.test/v1'),
        model: model,
        winRatePerspective: entry.key,
        bearerToken: 'secret-token',
      );

      final provider = factory.create(profile) as WssKataGoAnalysisProvider;

      expect(provider.config.endpoint, profile.endpoint);
      expect(provider.config.model, same(model));
      expect(provider.config.reportAnalysisWinratesAs, entry.value);
      expect(provider.config.bearerToken, 'secret-token');
      expect(provider.config.connectionTimeout, const Duration(seconds: 7));
      expect(provider.config.analysisPvLength, 16);
      expect(factory.concurrencyGroup(profile), profile.endpoint.toString());
      expect(factory.maximumConcurrentProviders(profile), 1);
      await factory.release(provider);
    }
  });

  test('passes only the calibration-pinned HumanSL profile', () async {
    const factory = WssAnalysisProviderFactory();
    final humanModel = analysisModelFixture();
    final artifact = const GamePerformanceCalibrationCodec().encode(
      calibrationFixture(),
    );
    final profile = AnalysisServiceProfile(
      endpoint: Uri.parse('wss://analysis.example.test/v1'),
      model: humanModel,
      winRatePerspective: AnalysisWinRatePerspective.black,
      performanceCalibration: artifact,
    );

    final provider = factory.create(profile) as WssKataGoAnalysisProvider;

    expect(provider.config.humanStyleProfile, GoRank.kyu(1));
    await factory.release(provider);
  });
}
