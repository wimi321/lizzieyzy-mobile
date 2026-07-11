import 'package:lizzieyzy_mobile/domain/domain.dart';

final class ShareAnchor {
  const ShareAnchor({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

enum KifuShareOutcome { success, dismissed, unavailable }

abstract interface class KifuExportService {
  Future<KifuShareOutcome> share(KifuDocument document, {ShareAnchor? anchor});
}

/// Optional maintenance contract for export implementations that create
/// app-private temporary artifacts.
///
/// Cleanup is deliberately separate from [KifuExportService] so in-memory and
/// host-provided exporters do not need filesystem lifecycle behavior.
abstract interface class KifuExportArtifactMaintenance {
  Future<void> cleanupStaleArtifacts();
}

sealed class KifuExportException implements Exception {
  const KifuExportException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class KifuExportWriteException extends KifuExportException {
  const KifuExportWriteException() : super('Could not create the SGF export.');
}

final class KifuExportShareException extends KifuExportException {
  const KifuExportShareException() : super('Could not open the share sheet.');
}
