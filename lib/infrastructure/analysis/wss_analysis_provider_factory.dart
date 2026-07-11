import 'package:lizzieyzy_mobile/application/analysis/analysis.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

import 'katago_wss_config.dart';
import 'wss_katago_analysis_provider.dart';

final class WssAnalysisProviderFactory
    implements AnalysisProviderFactory, AnalysisProviderSchedulingPolicy {
  const WssAnalysisProviderFactory({
    this.connectionTimeout = const Duration(seconds: 10),
    this.analysisPvLength = 20,
    this.maximumConcurrentProvidersPerEndpoint = 1,
  });

  final Duration connectionTimeout;
  final int analysisPvLength;

  /// The bundled desktop bridge defaults to one active connection. A future
  /// multi-process or multiplexed WSS service can opt into a larger value
  /// without changing session lifecycle semantics.
  final int maximumConcurrentProvidersPerEndpoint;

  @override
  Object concurrencyGroup(AnalysisServiceProfile profile) =>
      profile.endpoint.toString();

  @override
  int maximumConcurrentProviders(AnalysisServiceProfile profile) =>
      maximumConcurrentProvidersPerEndpoint;

  @override
  AnalysisProvider create(AnalysisServiceProfile profile) {
    return WssKataGoAnalysisProvider(
      config: KataGoWssConfig(
        endpoint: profile.endpoint,
        reportAnalysisWinratesAs: switch (profile.winRatePerspective) {
          AnalysisWinRatePerspective.black => KataGoReportPerspective.black,
          AnalysisWinRatePerspective.white => KataGoReportPerspective.white,
          AnalysisWinRatePerspective.sideToMove =>
            KataGoReportPerspective.sideToMove,
        },
        model: profile.model,
        humanStyleProfile: profile.humanStyleProfile,
        bearerToken: profile.bearerToken,
        connectionTimeout: connectionTimeout,
        analysisPvLength: analysisPvLength,
      ),
    );
  }

  @override
  Future<void> release(AnalysisProvider provider) async {
    if (provider is! WssKataGoAnalysisProvider) {
      throw ArgumentError.value(
        provider,
        'provider',
        'WSS factory can release only providers it created.',
      );
    }
    await provider.close();
  }
}
