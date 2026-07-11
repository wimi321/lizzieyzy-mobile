import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

/// Creates a provider for one configured service profile and owns its release.
///
/// Keeping lifecycle management beside construction lets application sessions
/// remain provider-agnostic while still closing sockets deterministically.
abstract interface class AnalysisProviderFactory {
  AnalysisProvider create(AnalysisServiceProfile profile);

  Future<void> release(AnalysisProvider provider);
}
