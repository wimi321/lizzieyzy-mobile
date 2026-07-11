import 'package:lizzieyzy_mobile/domain/domain.dart';

import 'game_performance_calibration_codec.dart';

enum AppThemePreference { system, light, dark }

enum AppLocalePreference {
  system,
  simplifiedChinese,
  traditionalChinese,
  english,
  japanese,
  korean,
}

enum AnalysisWinRatePerspective { black, white, sideToMove }

final class AnalysisServiceProfile {
  AnalysisServiceProfile({
    required this.endpoint,
    required this.model,
    required this.winRatePerspective,
    this.bearerToken,
    this.performanceCalibration,
  }) {
    if (endpoint.scheme.toLowerCase() != 'wss' || endpoint.host.isEmpty) {
      throw ArgumentError.value(
        endpoint,
        'endpoint',
        'Analysis service endpoints must use wss://.',
      );
    }
    if (endpoint.userInfo.isNotEmpty) {
      throw ArgumentError.value(
        endpoint,
        'endpoint',
        'Credentials must not be embedded in the endpoint URI.',
      );
    }
    if (endpoint.fragment.isNotEmpty) {
      throw ArgumentError.value(
        endpoint,
        'endpoint',
        'Analysis service endpoints cannot contain fragments.',
      );
    }
    if (endpoint.query.isNotEmpty) {
      throw ArgumentError.value(
        endpoint,
        'endpoint',
        'Analysis service endpoints cannot contain query parameters.',
      );
    }
    if (bearerToken != null && bearerToken!.trim().isEmpty) {
      throw ArgumentError.value(
        bearerToken,
        'bearerToken',
        'Bearer tokens cannot be blank.',
      );
    }
    final calibration = performanceCalibration?.calibration;
    if (calibration != null &&
        !calibration.allowedAnalysisModelSha256.contains(
          model.sha256.toLowerCase(),
        )) {
      throw ArgumentError.value(
        performanceCalibration,
        'performanceCalibration',
        'The calibration does not allow the configured analysis model hash.',
      );
    }
    final humanProfile = calibration?.humanStyleProfile;
    if (humanProfile != null && !model.humanStyleRanks.contains(humanProfile)) {
      throw ArgumentError.value(
        performanceCalibration,
        'performanceCalibration',
        'The calibration HumanSL profile is not declared by the model.',
      );
    }
    if (calibration?.requiresHumanStyleRanks ?? false) {
      final humanModelHash = model.humanModelSha256?.toLowerCase();
      if (humanModelHash == null ||
          !calibration!.allowedHumanModelSha256.contains(humanModelHash)) {
        throw ArgumentError.value(
          performanceCalibration,
          'performanceCalibration',
          'The calibration does not allow the configured HumanSL model hash.',
        );
      }
    }
  }

  final Uri endpoint;
  final ModelManifest model;
  final AnalysisWinRatePerspective winRatePerspective;
  final GamePerformanceCalibrationArtifact? performanceCalibration;

  /// The exact HumanSL rank requested from KataGo. It exists only when a
  /// verified calibration artifact pins one, so ordinary analysis never opts
  /// into a rank profile accidentally.
  GoRank? get humanStyleProfile =>
      performanceCalibration?.calibration.humanStyleProfile;

  /// Kept in memory only. Persistent implementations must write it to the
  /// platform Keychain/Keystore and never to preferences or review bundles.
  final String? bearerToken;

  AnalysisServiceProfile copyWith({
    Uri? endpoint,
    ModelManifest? model,
    AnalysisWinRatePerspective? winRatePerspective,
    Object? bearerToken = _unset,
    Object? performanceCalibration = _unset,
  }) => AnalysisServiceProfile(
    endpoint: endpoint ?? this.endpoint,
    model: model ?? this.model,
    winRatePerspective: winRatePerspective ?? this.winRatePerspective,
    bearerToken: identical(bearerToken, _unset)
        ? this.bearerToken
        : bearerToken as String?,
    performanceCalibration: identical(performanceCalibration, _unset)
        ? this.performanceCalibration
        : performanceCalibration as GamePerformanceCalibrationArtifact?,
  );
}

final class AppSettings {
  const AppSettings({
    this.theme = AppThemePreference.system,
    this.locale = AppLocalePreference.system,
    this.analysisProfile = AnalysisProfile.standard,
    this.analysisService,
    this.confirmRemoteAnalysis = true,
  });

  final AppThemePreference theme;
  final AppLocalePreference locale;
  final AnalysisProfile analysisProfile;
  final AnalysisServiceProfile? analysisService;

  /// Remote analysis sends the complete record to the configured endpoint.
  /// This flag keeps a per-install consent gate rather than silently uploading.
  final bool confirmRemoteAnalysis;

  AppSettings copyWith({
    AppThemePreference? theme,
    AppLocalePreference? locale,
    AnalysisProfile? analysisProfile,
    Object? analysisService = _unset,
    bool? confirmRemoteAnalysis,
  }) => AppSettings(
    theme: theme ?? this.theme,
    locale: locale ?? this.locale,
    analysisProfile: analysisProfile ?? this.analysisProfile,
    analysisService: identical(analysisService, _unset)
        ? this.analysisService
        : analysisService as AnalysisServiceProfile?,
    confirmRemoteAnalysis: confirmRemoteAnalysis ?? this.confirmRemoteAnalysis,
  );
}

extension AppSettingsAnalysisRequest on AppSettings {
  /// Versioned product defaults. The service manifest controls which model is
  /// used; this mapping controls only the bounded amount of analysis work.
  AnalysisSettings get analysisRequestSettings => switch (analysisProfile) {
    AnalysisProfile.quick => const AnalysisSettings(
      profile: AnalysisProfile.quick,
      visitsPerMove: 1000,
    ),
    AnalysisProfile.standard => const AnalysisSettings(
      profile: AnalysisProfile.standard,
      visitsPerMove: 5000,
    ),
    AnalysisProfile.deep => const AnalysisSettings(
      profile: AnalysisProfile.deep,
      visitsPerMove: 20000,
    ),
  };
}

const Object _unset = Object();
