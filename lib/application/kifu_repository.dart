import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:lizzieyzy_mobile/domain/domain.dart';

/// Persistence boundary for the local kifu library.
///
/// Implementations must preserve [KifuDocument]'s concrete trust type when a
/// document is loaded again. Storage failures must never promote a snapshot or
/// partial record to [VerifiedGameRecord].
abstract interface class KifuRepository {
  Future<KifuLoadResult> load();

  Future<KifuWriteResult> add(KifuDocument document);

  Future<KifuWriteResult> update(KifuDocument document);

  Future<bool> delete(String documentId);
}

enum KifuWriteDisposition { added, updated, unchanged, duplicate }

final class KifuWriteResult {
  const KifuWriteResult({
    required this.disposition,
    required this.requestedDocumentId,
    required this.persistedDocumentId,
    required this.contentSha256,
  });

  final KifuWriteDisposition disposition;
  final String requestedDocumentId;

  /// May differ from [requestedDocumentId] when an identical document already
  /// exists and the repository deduplicates it by content.
  final String persistedDocumentId;
  final String contentSha256;
}

enum KifuQuarantineReason {
  corruptIndex,
  staleAtomicWrite,
  missingContent,
  unindexedContent,
  contentHashMismatch,
  resourceLimitExceeded,
  invalidUtf8,
  invalidSgf,
  trustTypeMismatch,
}

final class KifuQuarantineItem {
  const KifuQuarantineItem({required this.itemName, required this.reason});

  /// A basename or document id only. Absolute user paths are deliberately not
  /// surfaced to UI or logs.
  final String itemName;
  final KifuQuarantineReason reason;
}

final class KifuLoadResult {
  KifuLoadResult({
    required List<KifuDocument> documents,
    required List<KifuQuarantineItem> quarantined,
    required this.recoveredFromRedundantIndex,
  }) : documents = List<KifuDocument>.unmodifiable(documents),
       quarantined = List<KifuQuarantineItem>.unmodifiable(quarantined);

  final List<KifuDocument> documents;
  final List<KifuQuarantineItem> quarantined;
  final bool recoveredFromRedundantIndex;
}

abstract final class KifuContentIdentity {
  static final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

  static String sha256Bytes(List<int> bytes) =>
      crypto.sha256.convert(bytes).toString();

  static String sha256Sgf(String sgf) => sha256Bytes(utf8.encode(sgf));

  static bool isSha256(String value) => _sha256Pattern.hasMatch(value);
}

sealed class KifuRepositoryException implements Exception {
  const KifuRepositoryException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class KifuAlreadyExistsException extends KifuRepositoryException {
  const KifuAlreadyExistsException(String documentId)
    : super('A different document already uses id "$documentId".');
}

final class KifuNotFoundException extends KifuRepositoryException {
  const KifuNotFoundException(String documentId)
    : super('No persisted document uses id "$documentId".');
}

final class KifuDuplicateContentException extends KifuRepositoryException {
  const KifuDuplicateContentException({
    required this.documentId,
    required this.existingDocumentId,
  }) : super(
         'Document "$documentId" duplicates persisted document '
         '"$existingDocumentId".',
       );

  final String documentId;
  final String existingDocumentId;
}

final class KifuRepositoryUpgradeRequiredException
    extends KifuRepositoryException {
  const KifuRepositoryUpgradeRequiredException({
    required this.foundVersion,
    required this.supportedVersion,
  }) : super(
         'Storage schema $foundVersion is not supported by this app '
         '(supported: $supportedVersion).',
       );

  final int foundVersion;
  final int supportedVersion;
}
