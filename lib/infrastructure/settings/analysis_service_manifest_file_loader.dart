import 'package:file_selector/file_selector.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/infrastructure/io/io.dart';

/// Loads an untrusted service manifest without ever allocating the whole file
/// before its byte limit has been enforced.
final class AnalysisServiceManifestFileLoader {
  const AnalysisServiceManifestFileLoader({
    this.codec = const AnalysisServiceManifestCodec(),
  });

  final AnalysisServiceManifestCodec codec;

  Future<AnalysisServiceProfile> load(XFile file, {String? bearerToken}) async {
    final bytes = await readBoundedXFile(
      file,
      maximumBytes: codec.maximumBytes,
    );
    return codec.decode(bytes, bearerToken: bearerToken);
  }
}
