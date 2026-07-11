import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class PlatformAppSettingsRepository extends JsonAppSettingsRepository {
  factory PlatformAppSettingsRepository() {
    final preferences = _PlatformSettingsStringStore(SharedPreferencesAsync());
    final secrets = _PlatformSettingsSecretStore(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(migrateWithBackup: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.unlocked_this_device,
        ),
      ),
    );
    return PlatformAppSettingsRepository._(
      preferences: preferences,
      secrets: secrets,
      clearInstallScopedSecretsOnMissingMarker: Platform.isIOS,
    );
  }

  PlatformAppSettingsRepository._({
    required super.preferences,
    required super.secrets,
    required super.clearInstallScopedSecretsOnMissingMarker,
  });
}

class JsonAppSettingsRepository implements AppSettingsRepository {
  JsonAppSettingsRepository({
    required SettingsStringStore preferences,
    required SettingsSecretStore secrets,
    bool clearInstallScopedSecretsOnMissingMarker = false,
  }) : _preferences = preferences,
       _secrets = secrets,
       _clearInstallScopedSecretsOnMissingMarker =
           clearInstallScopedSecretsOnMissingMarker;

  static const _settingsKey = 'app_settings_v1';
  static const _analysisTokenKey = 'analysis_service_bearer_token_v1';
  static const _installMarkerKey = 'nonsecure_install_marker_v1';
  static const _installMarkerValue = 'present';
  static const _calibrationCodec = GamePerformanceCalibrationCodec();

  final SettingsStringStore _preferences;
  final SettingsSecretStore _secrets;
  final bool _clearInstallScopedSecretsOnMissingMarker;
  Future<void>? _installPreparation;

  @override
  Future<AppSettings> load() async {
    await _prepareInstallScopedSecrets();
    final encoded = await _preferences.read(_settingsKey);
    if (encoded == null) return const AppSettings();
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException('Stored app settings are not an object.');
    }
    final json = decoded.cast<String, dynamic>();
    final serviceJson = json['analysisService'];
    AnalysisServiceProfile? service;
    if (serviceJson != null) {
      if (serviceJson is! Map) {
        throw const FormatException('Stored analysis service is invalid.');
      }
      final serviceMap = serviceJson.cast<String, dynamic>();
      final token = await _secrets.read(_analysisTokenKey);
      service = _serviceFromJson(serviceMap, token: token);
    }
    return AppSettings(
      theme: _enumByName(
        AppThemePreference.values,
        json['theme'],
        fallback: AppThemePreference.system,
      ),
      locale: _enumByName(
        AppLocalePreference.values,
        json['locale'],
        fallback: AppLocalePreference.system,
      ),
      analysisProfile: _enumByName(
        AnalysisProfile.values,
        json['analysisProfile'],
        fallback: AnalysisProfile.standard,
      ),
      analysisService: service,
      confirmRemoteAnalysis: json['confirmRemoteAnalysis'] is bool
          ? json['confirmRemoteAnalysis']! as bool
          : true,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prepareInstallScopedSecrets();
    final service = settings.analysisService;
    final previousToken = await _secrets.read(_analysisTokenKey);
    final json = <String, Object?>{
      'schemaVersion': 1,
      'theme': settings.theme.name,
      'locale': settings.locale.name,
      'analysisProfile': settings.analysisProfile.name,
      'confirmRemoteAnalysis': settings.confirmRemoteAnalysis,
      'analysisService': service == null ? null : _serviceToJson(service),
    };
    try {
      if (service?.bearerToken case final token?) {
        await _secrets.write(_analysisTokenKey, token.trim());
      } else {
        await _secrets.delete(_analysisTokenKey);
      }
      await _preferences.write(_settingsKey, jsonEncode(json));
    } on Object {
      // A settings update is one logical transaction. Do not leave a newly
      // entered credential behind when the public settings write fails.
      try {
        if (previousToken == null) {
          await _secrets.delete(_analysisTokenKey);
        } else {
          await _secrets.write(_analysisTokenKey, previousToken);
        }
      } on Object {
        // Preserve the original failure. Secure-store recovery remains best
        // effort because platform stores do not expose transactions.
      }
      rethrow;
    }
  }

  /// iOS Keychain entries can outlive the application container after an
  /// uninstall. UserDefaults does not: its non-secret marker therefore
  /// identifies this installation. A missing marker must clear the old token
  /// before the new installation becomes initialized, so a reinstall cannot
  /// silently inherit credentials from a previous installation.
  ///
  /// The platform repository enables this only on iOS. Android continues to
  /// use its existing Keystore-backed storage path without this marker.
  Future<void> _prepareInstallScopedSecrets() async {
    if (!_clearInstallScopedSecretsOnMissingMarker) return;
    final pending = _installPreparation;
    if (pending != null) {
      await pending;
      return;
    }

    final operation = _clearOrphanedSecretsIfNeeded();
    _installPreparation = operation;
    try {
      await operation;
    } on Object {
      if (identical(_installPreparation, operation)) {
        _installPreparation = null;
      }
      rethrow;
    }
  }

  Future<void> _clearOrphanedSecretsIfNeeded() async {
    final marker = await _preferences.read(_installMarkerKey);
    if (marker != null) return;
    // Delete first. If marker persistence fails, the next launch repeats a
    // safe deletion instead of treating a potentially stale token as current.
    await _secrets.delete(_analysisTokenKey);
    await _preferences.write(_installMarkerKey, _installMarkerValue);
  }
}

final class _PlatformSettingsStringStore implements SettingsStringStore {
  const _PlatformSettingsStringStore(this._preferences);

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

final class _PlatformSettingsSecretStore implements SettingsSecretStore {
  const _PlatformSettingsSecretStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

Map<String, Object?> _serviceToJson(AnalysisServiceProfile service) =>
    <String, Object?>{
      'endpoint': service.endpoint.toString(),
      'winRatePerspective': service.winRatePerspective.name,
      'model': <String, Object?>{
        'id': service.model.id,
        'displayName': service.model.displayName,
        'sha256': service.model.sha256,
        'engineVersion': service.model.engineVersion,
        'modelVersion': service.model.modelVersion,
        'license': service.model.license,
        'source': service.model.source?.toString(),
        'humanModelSha256': service.model.humanModelSha256,
        'humanStyleRanks': [
          for (final rank in service.model.humanStyleRanks) rank.label,
        ],
      },
      if (service.performanceCalibration case final calibration?)
        'performanceCalibration': const GamePerformanceCalibrationCodec()
            .encodeObject(calibration),
    };

AnalysisServiceProfile _serviceFromJson(
  Map<String, dynamic> json, {
  required String? token,
}) {
  final modelValue = json['model'];
  if (modelValue is! Map) {
    throw const FormatException('Stored analysis model is invalid.');
  }
  final model = modelValue.cast<String, dynamic>();
  final sourceValue = model['source'];
  final ranksValue = model['humanStyleRanks'];
  final calibrationValue = json['performanceCalibration'];
  return AnalysisServiceProfile(
    endpoint: Uri.parse(_requiredString(json, 'endpoint')),
    winRatePerspective: _enumByName(
      AnalysisWinRatePerspective.values,
      json['winRatePerspective'],
      fallback: AnalysisWinRatePerspective.sideToMove,
    ),
    bearerToken: token,
    model: ModelManifest(
      id: _requiredString(model, 'id'),
      displayName: _requiredString(model, 'displayName'),
      sha256: _requiredString(model, 'sha256'),
      engineVersion: _requiredString(model, 'engineVersion'),
      modelVersion: _requiredString(model, 'modelVersion'),
      license: _requiredString(model, 'license'),
      source: sourceValue is String && sourceValue.isNotEmpty
          ? Uri.parse(sourceValue)
          : null,
      humanModelSha256: model['humanModelSha256'] as String?,
      humanStyleRanks: ranksValue is List
          ? ranksValue.whereType<String>().map(_rankFromLabel).toList()
          : const <GoRank>[],
    ),
    performanceCalibration: calibrationValue == null
        ? null
        : JsonAppSettingsRepository._calibrationCodec.decodeObject(
            calibrationValue,
          ),
  );
}

T _enumByName<T extends Enum>(
  List<T> values,
  Object? name, {
  required T fallback,
}) {
  if (name is! String) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Stored setting $key is missing.');
  }
  return value.trim();
}

GoRank _rankFromLabel(String label) {
  final match = RegExp(r'^(\d{1,2})([kd])$').firstMatch(label.toLowerCase());
  if (match == null) throw FormatException('Invalid HumanSL rank: $label');
  final value = int.parse(match.group(1)!);
  return match.group(2) == 'k' ? GoRank.kyu(value) : GoRank.dan(value);
}
