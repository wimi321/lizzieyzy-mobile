import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/settings/settings.dart';

void main() {
  group('iOS install-scoped secret lifecycle', () {
    late List<String> events;
    late _StringStore preferences;
    late _SecretStore secrets;

    setUp(() {
      events = <String>[];
      preferences = _StringStore(events);
      secrets = _SecretStore(events);
    });

    test(
      'deletes an orphan token before writing the first-install marker',
      () async {
        secrets.values[_tokenKey] = 'token-from-uninstalled-copy';
        final repository = _repository(preferences, secrets, cleanup: true);

        final settings = await repository.load();

        expect(settings.analysisService, isNull);
        expect(secrets.values, isNot(contains(_tokenKey)));
        expect(preferences.values[_markerKey], _markerValue);
        expect(events.take(3), <String>[
          'preferences.read:$_markerKey',
          'secrets.delete:$_tokenKey',
          'preferences.write:$_markerKey=$_markerValue',
        ]);
      },
    );

    test('serializes concurrent first-launch cleanup', () async {
      secrets.values[_tokenKey] = 'orphan';
      final repository = _repository(preferences, secrets, cleanup: true);

      await Future.wait(<Future<AppSettings>>[
        repository.load(),
        repository.load(),
      ]);

      expect(
        events.where((event) => event == 'secrets.delete:$_tokenKey'),
        hasLength(1),
      );
      expect(
        events.where(
          (event) => event == 'preferences.write:$_markerKey=$_markerValue',
        ),
        hasLength(1),
      );
    });

    test(
      'preserves the current installation token after marker creation',
      () async {
        final firstLaunch = _repository(preferences, secrets, cleanup: true);
        await firstLaunch.save(_settingsWithToken('current-install-token'));
        events.clear();

        final subsequentLaunch = _repository(
          preferences,
          secrets,
          cleanup: true,
        );
        final settings = await subsequentLaunch.load();

        expect(settings.analysisService?.bearerToken, 'current-install-token');
        expect(events, isNot(contains('secrets.delete:$_tokenKey')));
        expect(preferences.values[_markerKey], _markerValue);
      },
    );

    test(
      'retries safely when Keychain cleanup fails before marker write',
      () async {
        secrets.values[_tokenKey] = 'orphan';
        secrets.deleteError = StateError('Keychain unavailable');
        final repository = _repository(preferences, secrets, cleanup: true);

        await expectLater(repository.load(), throwsStateError);
        expect(preferences.values, isNot(contains(_markerKey)));
        expect(secrets.values[_tokenKey], 'orphan');

        secrets.deleteError = null;
        await repository.load();
        expect(secrets.values, isNot(contains(_tokenKey)));
        expect(preferences.values[_markerKey], _markerValue);
        expect(
          events.where((event) => event == 'secrets.delete:$_tokenKey'),
          hasLength(2),
        );
      },
    );

    test('retries cleanup when the non-secret marker write fails', () async {
      secrets.values[_tokenKey] = 'orphan';
      preferences.writeError = StateError('UserDefaults unavailable');
      final repository = _repository(preferences, secrets, cleanup: true);

      await expectLater(repository.load(), throwsStateError);
      expect(secrets.values, isNot(contains(_tokenKey)));
      expect(preferences.values, isNot(contains(_markerKey)));

      preferences.writeError = null;
      await repository.load();
      expect(preferences.values[_markerKey], _markerValue);
      expect(
        events.where((event) => event == 'secrets.delete:$_tokenKey'),
        hasLength(2),
      );
    });

    test(
      'leaves the Android-style storage path unchanged when disabled',
      () async {
        secrets.values[_tokenKey] = 'keystore-value';
        final repository = _repository(preferences, secrets, cleanup: false);

        await repository.load();

        expect(secrets.values[_tokenKey], 'keystore-value');
        expect(preferences.values, isNot(contains(_markerKey)));
        expect(events, isNot(contains('secrets.delete:$_tokenKey')));
      },
    );
  });
}

JsonAppSettingsRepository _repository(
  SettingsStringStore preferences,
  SettingsSecretStore secrets, {
  required bool cleanup,
}) => JsonAppSettingsRepository(
  preferences: preferences,
  secrets: secrets,
  clearInstallScopedSecretsOnMissingMarker: cleanup,
);

AppSettings _settingsWithToken(String token) => AppSettings(
  analysisService: AnalysisServiceProfile(
    endpoint: Uri.parse('wss://analysis.example.test/v1'),
    model: _model,
    winRatePerspective: AnalysisWinRatePerspective.black,
    bearerToken: token,
  ),
);

const _tokenKey = 'analysis_service_bearer_token_v1';
const _markerKey = 'nonsecure_install_marker_v1';
const _markerValue = 'present';

final _model = ModelManifest(
  id: 'katago-test',
  displayName: 'KataGo Test',
  sha256: 'a' * 64,
  engineVersion: '1.16.5',
  modelVersion: 'b18-test',
  license: 'CC-BY-4.0',
);

final class _StringStore implements SettingsStringStore {
  _StringStore(this.events);

  final List<String> events;
  final values = <String, String>{};
  Object? writeError;

  @override
  Future<String?> read(String key) async {
    events.add('preferences.read:$key');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    events.add('preferences.write:$key=$value');
    if (writeError case final error?) throw error;
    values[key] = value;
  }
}

final class _SecretStore implements SettingsSecretStore {
  _SecretStore(this.events);

  final List<String> events;
  final values = <String, String>{};
  Object? deleteError;

  @override
  Future<void> delete(String key) async {
    events.add('secrets.delete:$key');
    if (deleteError case final error?) throw error;
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    events.add('secrets.read:$key');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    events.add('secrets.write:$key=$value');
    values[key] = value;
  }
}
