import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/settings/settings.dart';

import '../infrastructure/review/review_test_fixtures.dart';

void main() {
  test('analysis profile labels match the visits actually requested', () {
    const expected = <AnalysisProfile, int>{
      AnalysisProfile.quick: 1000,
      AnalysisProfile.standard: 5000,
      AnalysisProfile.deep: 20000,
    };
    for (final entry in expected.entries) {
      final settings = AppSettings(
        analysisProfile: entry.key,
      ).analysisRequestSettings;
      expect(settings.visitsPerMove, entry.value);
      expect(settings.criticalMoveVisits, isNull);
    }
  });

  group('AnalysisServiceProfile trust boundary', () {
    test('requires WSS and rejects credentials embedded in the URI', () {
      expect(
        () => AnalysisServiceProfile(
          endpoint: Uri.parse('ws://example.com/analysis'),
          model: _model,
          winRatePerspective: AnalysisWinRatePerspective.black,
        ),
        throwsArgumentError,
      );
      expect(
        () => AnalysisServiceProfile(
          endpoint: Uri.parse('wss://token@example.com/analysis'),
          model: _model,
          winRatePerspective: AnalysisWinRatePerspective.black,
        ),
        throwsArgumentError,
      );
      expect(
        () => AnalysisServiceProfile(
          endpoint: Uri.parse(
            'wss://analysis.example.test/v1?token=must-not-be-here',
          ),
          model: _model,
          winRatePerspective: AnalysisWinRatePerspective.black,
        ),
        throwsArgumentError,
      );
    });
  });

  group('JsonAppSettingsRepository', () {
    late _StringStore strings;
    late _SecretStore secrets;
    late JsonAppSettingsRepository repository;

    setUp(() {
      strings = _StringStore();
      secrets = _SecretStore();
      repository = JsonAppSettingsRepository(
        preferences: strings,
        secrets: secrets,
      );
    });

    test(
      'round-trips settings while keeping bearer token out of preferences',
      () async {
        final calibration = const GamePerformanceCalibrationCodec().encode(
          calibrationFixture(requiresHumanStyleRanks: false),
        );
        final expected = AppSettings(
          theme: AppThemePreference.dark,
          locale: AppLocalePreference.japanese,
          analysisProfile: AnalysisProfile.deep,
          confirmRemoteAnalysis: false,
          analysisService: AnalysisServiceProfile(
            endpoint: Uri.parse('wss://analysis.example.test/v1'),
            model: _model,
            winRatePerspective: AnalysisWinRatePerspective.sideToMove,
            bearerToken: 'top-secret-token',
            performanceCalibration: calibration,
          ),
        );

        await repository.save(expected);

        expect(
          strings.values.values.single,
          isNot(contains('top-secret-token')),
        );
        expect(secrets.values.values.single, 'top-secret-token');

        final actual = await repository.load();
        expect(actual.theme, expected.theme);
        expect(actual.locale, expected.locale);
        expect(actual.analysisProfile, expected.analysisProfile);
        expect(actual.confirmRemoteAnalysis, isFalse);
        expect(
          actual.analysisService!.endpoint,
          expected.analysisService!.endpoint,
        );
        expect(actual.analysisService!.model.sha256, _model.sha256);
        expect(actual.analysisService!.model.humanStyleRanks, [GoRank.kyu(3)]);
        expect(actual.analysisService!.model.humanModelSha256, 'd' * 64);
        expect(
          actual.analysisService!.performanceCalibration?.sha256,
          calibration.sha256,
        );
        expect(
          actual
              .analysisService!
              .performanceCalibration
              ?.calibration
              .calibrationModelId,
          'game-strength-calibration@1.0.0',
        );
        expect(actual.analysisService!.bearerToken, 'top-secret-token');
      },
    );

    test('removing analysis service deletes its secret', () async {
      await repository.save(
        AppSettings(
          analysisService: AnalysisServiceProfile(
            endpoint: Uri.parse('wss://analysis.example.test'),
            model: _model,
            winRatePerspective: AnalysisWinRatePerspective.black,
            bearerToken: 'secret',
          ),
        ),
      );
      await repository.save(const AppSettings());
      expect(secrets.values, isEmpty);
      expect((await repository.load()).analysisService, isNull);
    });

    test('failed preferences write restores the previous secret', () async {
      await repository.save(
        AppSettings(
          analysisService: AnalysisServiceProfile(
            endpoint: Uri.parse('wss://analysis.example.test'),
            model: _model,
            winRatePerspective: AnalysisWinRatePerspective.black,
            bearerToken: 'previous-secret',
          ),
        ),
      );
      strings.writeError = StateError('preferences unavailable');

      await expectLater(
        repository.save(
          AppSettings(
            analysisService: AnalysisServiceProfile(
              endpoint: Uri.parse('wss://analysis.example.test'),
              model: _model,
              winRatePerspective: AnalysisWinRatePerspective.black,
              bearerToken: 'new-secret',
            ),
          ),
        ),
        throwsStateError,
      );

      expect(secrets.values.values.single, 'previous-secret');
      expect(strings.values.values.single, isNot(contains('new-secret')));
    });

    test('rejects a persisted calibration whose hash was tampered', () async {
      final artifact = const GamePerformanceCalibrationCodec().encode(
        calibrationFixture(requiresHumanStyleRanks: false),
      );
      await repository.save(
        AppSettings(
          analysisService: AnalysisServiceProfile(
            endpoint: Uri.parse('wss://analysis.example.test/v1'),
            model: _model,
            winRatePerspective: AnalysisWinRatePerspective.black,
            performanceCalibration: artifact,
          ),
        ),
      );
      final entry = strings.values.entries.single;
      final stored = (jsonDecode(entry.value) as Map).cast<String, dynamic>();
      final service = (stored['analysisService'] as Map)
          .cast<String, dynamic>();
      final calibration = (service['performanceCalibration'] as Map)
          .cast<String, dynamic>();
      calibration['payloadSha256'] = '0' * 64;
      strings.values[entry.key] = jsonEncode(stored);

      await expectLater(repository.load(), throwsFormatException);
    });
  });

  group('AppSettingsController', () {
    test('loads, saves, and rolls back a failed update', () async {
      final repository = MemoryAppSettingsRepository(
        const AppSettings(theme: AppThemePreference.light),
      );
      final controller = AppSettingsController(repository: repository);

      await controller.initialize();
      expect(controller.status, AppSettingsStatus.ready);
      expect(controller.settings.theme, AppThemePreference.light);

      await controller.update(
        controller.settings.copyWith(theme: AppThemePreference.dark),
      );
      expect(controller.settings.theme, AppThemePreference.dark);
      expect(repository.value.theme, AppThemePreference.dark);

      repository.saveError = StateError('disk full');
      await controller.update(
        controller.settings.copyWith(theme: AppThemePreference.system),
      );
      expect(controller.status, AppSettingsStatus.failed);
      expect(controller.settings.theme, AppThemePreference.dark);
      expect(controller.error, isA<StateError>());
    });
  });
}

final _model = ModelManifest(
  id: 'katago-test',
  displayName: 'KataGo Test',
  sha256: 'a' * 64,
  engineVersion: '1.16.5',
  modelVersion: 'b18-test',
  license: 'CC-BY-4.0',
  source: Uri.parse('https://example.test/model'),
  humanModelSha256: 'd' * 64,
  humanStyleRanks: [GoRank.kyu(3)],
);

final class _StringStore implements SettingsStringStore {
  final values = <String, String>{};
  Object? writeError;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (writeError case final error?) throw error;
    values[key] = value;
  }
}

final class _SecretStore implements SettingsSecretStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
