import 'package:flutter/foundation.dart';

import 'app_settings.dart';

abstract interface class AppSettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

abstract interface class SettingsStringStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

abstract interface class SettingsSecretStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

enum AppSettingsStatus { idle, loading, ready, saving, failed }

final class AppSettingsController extends ChangeNotifier {
  AppSettingsController({required AppSettingsRepository repository})
    : _repository = repository;

  final AppSettingsRepository _repository;

  AppSettings _settings = const AppSettings();
  AppSettingsStatus _status = AppSettingsStatus.idle;
  Object? _error;
  Future<void> _pending = Future<void>.value();

  AppSettings get settings => _settings;
  AppSettingsStatus get status => _status;
  Object? get error => _error;
  bool get isReady => _status == AppSettingsStatus.ready;

  Future<void> initialize() => _serialize(() async {
    _status = AppSettingsStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _settings = await _repository.load();
      _status = AppSettingsStatus.ready;
    } on Object catch (error) {
      _error = error;
      _status = AppSettingsStatus.failed;
    }
    notifyListeners();
  });

  Future<void> update(AppSettings settings) => _serialize(() async {
    final previous = _settings;
    _settings = settings;
    _status = AppSettingsStatus.saving;
    _error = null;
    notifyListeners();
    try {
      await _repository.save(settings);
      _status = AppSettingsStatus.ready;
    } on Object catch (error) {
      _settings = previous;
      _error = error;
      _status = AppSettingsStatus.failed;
    }
    notifyListeners();
  });

  Future<void> retry() => initialize();

  Future<void> _serialize(Future<void> Function() operation) {
    final next = _pending.then((_) => operation());
    _pending = next.catchError((Object _) {});
    return next;
  }
}

final class MemoryAppSettingsRepository implements AppSettingsRepository {
  MemoryAppSettingsRepository([this.value = const AppSettings()]);

  AppSettings value;
  Object? loadError;
  Object? saveError;

  @override
  Future<AppSettings> load() async {
    if (loadError case final error?) throw error;
    return value;
  }

  @override
  Future<void> save(AppSettings settings) async {
    if (saveError case final error?) throw error;
    value = settings;
  }
}
