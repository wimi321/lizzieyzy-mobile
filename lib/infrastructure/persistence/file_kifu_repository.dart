import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lizzieyzy_mobile/application/kifu_repository.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/io/io.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';
import 'package:path_provider/path_provider.dart';

typedef ApplicationSupportDirectoryProvider = Future<Directory> Function();
typedef KifuRepositoryClock = DateTime Function();
typedef KifuRepositoryAtomicWriteHook =
    FutureOr<void> Function(File destination);

/// A versioned, content-addressed local kifu store.
///
/// SGF payloads are written before a redundant two-slot index is committed.
/// The first durable index slot commits a mutation; the second slot is healed
/// best-effort and again during load. A crash can therefore expose either the
/// old complete generation or the new complete generation, never an index that
/// points at a partially written SGF.
final class FileKifuRepository implements KifuRepository {
  FileKifuRepository({
    ApplicationSupportDirectoryProvider? supportDirectoryProvider,
    this.codec = const SgfCodec(),
    KifuRepositoryClock? clock,
    KifuRepositoryAtomicWriteHook? atomicWriteHook,
  }) : _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory,
       _clock = clock ?? DateTime.now,
       _atomicWriteHook = atomicWriteHook;

  static const schemaVersion = 1;
  static const _storeDirectoryName = 'lizzieyzy-mobile';
  static const _kifuDirectoryName = 'kifu';
  static const _versionDirectoryName = 'v1';
  static const _documentsDirectoryName = 'documents';
  static const _quarantineDirectoryName = 'quarantine';
  static const _maximumIndexBytes = 16 * 1024 * 1024;
  static const _indexNames = <String>['index.0.json', 'index.1.json'];

  final ApplicationSupportDirectoryProvider _supportDirectoryProvider;
  final KifuRepositoryClock _clock;
  final KifuRepositoryAtomicWriteHook? _atomicWriteHook;
  final SgfCodec codec;

  Future<void> _tail = Future<void>.value();
  _IndexState? _state;
  List<_IndexState?> _slots = <_IndexState?>[null, null];
  Map<String, KifuDocument> _documents = <String, KifuDocument>{};
  Directory? _root;
  Directory? _documentsDirectory;
  Directory? _quarantineDirectory;
  var _uniqueFileSequence = 0;

  @override
  Future<KifuLoadResult> load() => _exclusive(_loadFromDisk);

  @override
  Future<KifuWriteResult> add(KifuDocument document) => _exclusive(() async {
    await _ensureLoaded();
    final bytes = _encodeWithinLimits(document);
    final digest = KifuContentIdentity.sha256Bytes(bytes);
    final duplicate = _firstWhereOrNull(
      _state!.entries.values,
      (entry) => entry.contentSha256 == digest,
    );
    if (duplicate != null) {
      return KifuWriteResult(
        disposition: KifuWriteDisposition.duplicate,
        requestedDocumentId: document.id,
        persistedDocumentId: duplicate.documentId,
        contentSha256: digest,
      );
    }
    if (_state!.entries.containsKey(document.id)) {
      throw KifuAlreadyExistsException(document.id);
    }

    final contentCreated = await _writeContentIfAbsent(digest, bytes);
    final now = _clock().toUtc();
    final entry = _IndexEntry.fromDocument(
      document,
      contentSha256: digest,
      createdAt: now,
      updatedAt: now,
    );
    final candidate = _state!.withEntry(entry);
    try {
      await _persistRedundantly(candidate);
    } on Object {
      if (contentCreated) await _deleteContentBestEffort(digest);
      rethrow;
    }
    _documents[document.id] = document;
    return KifuWriteResult(
      disposition: KifuWriteDisposition.added,
      requestedDocumentId: document.id,
      persistedDocumentId: document.id,
      contentSha256: digest,
    );
  });

  @override
  Future<KifuWriteResult> update(KifuDocument document) => _exclusive(() async {
    await _ensureLoaded();
    final previous = _state!.entries[document.id];
    if (previous == null) throw KifuNotFoundException(document.id);

    final bytes = _encodeWithinLimits(document);
    final digest = KifuContentIdentity.sha256Bytes(bytes);
    final duplicate = _firstWhereOrNull(
      _state!.entries.values,
      (entry) =>
          entry.documentId != document.id && entry.contentSha256 == digest,
    );
    if (duplicate != null) {
      throw KifuDuplicateContentException(
        documentId: document.id,
        existingDocumentId: duplicate.documentId,
      );
    }

    final sourceChanged =
        previous.sourceKind != document.source.kind ||
        previous.sourceReference != document.source.reference;
    if (previous.contentSha256 == digest && !sourceChanged) {
      return KifuWriteResult(
        disposition: KifuWriteDisposition.unchanged,
        requestedDocumentId: document.id,
        persistedDocumentId: document.id,
        contentSha256: digest,
      );
    }

    final contentCreated = await _writeContentIfAbsent(digest, bytes);
    final entry = _IndexEntry.fromDocument(
      document,
      contentSha256: digest,
      createdAt: previous.createdAt,
      updatedAt: _clock().toUtc(),
    );
    final candidate = _state!.withEntry(entry);
    try {
      await _persistRedundantly(candidate);
    } on Object {
      if (contentCreated) await _deleteContentBestEffort(digest);
      rethrow;
    }
    _documents[document.id] = document;
    await _deleteContentBestEffort(previous.contentSha256);
    return KifuWriteResult(
      disposition: KifuWriteDisposition.updated,
      requestedDocumentId: document.id,
      persistedDocumentId: document.id,
      contentSha256: digest,
    );
  });

  @override
  Future<bool> delete(String documentId) => _exclusive(() async {
    await _ensureLoaded();
    final previous = _state!.entries[documentId];
    if (previous == null) return false;

    final candidate = _state!.withoutEntry(documentId);
    await _persistRedundantly(candidate);
    _documents.remove(documentId);
    await _deleteContentBestEffort(previous.contentSha256);
    return true;
  });

  Future<T> _exclusive<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _ensureLoaded() async {
    if (_state == null) await _loadFromDisk();
  }

  Future<KifuLoadResult> _loadFromDisk() async {
    await _ensureDirectories();
    final quarantined = <KifuQuarantineItem>[];
    var recovered = await _quarantineStaleAtomicWrites(quarantined);

    final slotReads = <_SlotRead>[];
    for (var index = 0; index < _indexNames.length; index++) {
      slotReads.add(await _readSlot(index, quarantined));
    }
    if (slotReads.any((read) => read.wasCorrupt)) recovered = true;
    _slots = <_IndexState?>[for (final read in slotReads) read.state];

    final available = _slots.whereType<_IndexState>().toList()
      ..sort((left, right) => right.generation.compareTo(left.generation));
    final hadAnyIndexFile = slotReads.any((read) => read.existed);
    var selected = available.isEmpty
        ? const _IndexState(generation: 0, entries: <String, _IndexEntry>{})
        : available.first;
    if (hadAnyIndexFile && available.length < 2) recovered = true;
    if (available.length == 2 &&
        available[0].entriesFingerprint != available[1].entriesFingerprint) {
      recovered = true;
    }

    final loadedDocuments = <String, KifuDocument>{};
    final healthyEntries = <String, _IndexEntry>{};
    for (final entry in selected.entries.values) {
      final content = _contentFile(entry.contentSha256);
      if (!await content.exists()) {
        quarantined.add(
          KifuQuarantineItem(
            itemName: entry.documentId,
            reason: KifuQuarantineReason.missingContent,
          ),
        );
        recovered = true;
        continue;
      }

      late final List<int> bytes;
      try {
        bytes = await readBoundedFile(
          content,
          maximumBytes: codec.syntaxParser.limits.maxInputBytes,
        );
      } on BoundedReadLimitException {
        await _quarantineFile(
          content,
          KifuQuarantineReason.resourceLimitExceeded,
          quarantined,
        );
        recovered = true;
        continue;
      } on FileSystemException {
        await _quarantineFile(
          content,
          KifuQuarantineReason.invalidSgf,
          quarantined,
        );
        recovered = true;
        continue;
      }
      if (KifuContentIdentity.sha256Bytes(bytes) != entry.contentSha256) {
        await _quarantineFile(
          content,
          KifuQuarantineReason.contentHashMismatch,
          quarantined,
        );
        recovered = true;
        continue;
      }

      late final String sgf;
      try {
        sgf = utf8.decode(bytes, allowMalformed: false);
      } on FormatException {
        await _quarantineFile(
          content,
          KifuQuarantineReason.invalidUtf8,
          quarantined,
        );
        recovered = true;
        continue;
      }

      late final KifuDocument document;
      try {
        document = codec.importDocument(
          sgf,
          documentId: entry.documentId,
          kifuSource: KifuSource(
            kind: entry.sourceKind,
            reference: entry.sourceReference,
          ),
        );
      } on Object {
        await _quarantineFile(
          content,
          KifuQuarantineReason.invalidSgf,
          quarantined,
        );
        recovered = true;
        continue;
      }
      if (_trustTypeOf(document) != entry.trustType) {
        await _quarantineFile(
          content,
          KifuQuarantineReason.trustTypeMismatch,
          quarantined,
        );
        recovered = true;
        continue;
      }
      healthyEntries[entry.documentId] = entry;
      loadedDocuments[entry.documentId] = document;
    }

    selected = selected.copyWith(entries: healthyEntries);
    _state = selected;
    _documents = loadedDocuments;

    final referencedDigests = healthyEntries.values
        .map((entry) => entry.contentSha256)
        .toSet();
    await for (final entity in _documentsDirectory!.list()) {
      if (entity is! File || !entity.path.endsWith('.sgf')) continue;
      final name = _basename(entity.path);
      final digest = name.substring(0, name.length - '.sgf'.length);
      if (!referencedDigests.contains(digest)) {
        await _quarantineFile(
          entity,
          KifuQuarantineReason.unindexedContent,
          quarantined,
        );
        recovered = true;
      }
    }

    final isFreshStore = !hadAnyIndexFile && quarantined.isEmpty;
    final needsHealing =
        isFreshStore ||
        recovered ||
        _slots.any((slot) => slot == null) ||
        _slots.whereType<_IndexState>().any(
          (slot) => slot.entriesFingerprint != selected.entriesFingerprint,
        );
    if (needsHealing) await _persistRedundantly(selected);

    final orderedEntries = _state!.entries.values.toList()
      ..sort((left, right) {
        final byTime = right.updatedAt.compareTo(left.updatedAt);
        return byTime != 0
            ? byTime
            : left.documentId.compareTo(right.documentId);
      });
    return KifuLoadResult(
      documents: <KifuDocument>[
        for (final entry in orderedEntries) _documents[entry.documentId]!,
      ],
      quarantined: quarantined,
      recoveredFromRedundantIndex: recovered,
    );
  }

  Future<void> _ensureDirectories() async {
    if (_root != null) return;
    final support = await _supportDirectoryProvider();
    final root = Directory(
      _joinAll(<String>[
        support.path,
        _storeDirectoryName,
        _kifuDirectoryName,
        _versionDirectoryName,
      ]),
    );
    final documents = Directory(_join(root.path, _documentsDirectoryName));
    final quarantine = Directory(_join(root.path, _quarantineDirectoryName));
    await documents.create(recursive: true);
    await quarantine.create(recursive: true);
    _root = root;
    _documentsDirectory = documents;
    _quarantineDirectory = quarantine;
  }

  Future<_SlotRead> _readSlot(
    int slot,
    List<KifuQuarantineItem> quarantined,
  ) async {
    final file = _indexFile(slot);
    if (!await file.exists()) return const _SlotRead();
    try {
      final bytes = await readBoundedFile(
        file,
        maximumBytes: _maximumIndexBytes,
      );
      final source = utf8.decode(bytes, allowMalformed: false);
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('The index root must be an object.');
      }
      return _SlotRead(existed: true, state: _IndexState.fromJson(decoded));
    } on KifuRepositoryUpgradeRequiredException {
      rethrow;
    } on Object {
      await _quarantineFile(
        file,
        KifuQuarantineReason.corruptIndex,
        quarantined,
      );
      return const _SlotRead(existed: true, wasCorrupt: true);
    }
  }

  Future<bool> _quarantineStaleAtomicWrites(
    List<KifuQuarantineItem> quarantined,
  ) async {
    var found = false;
    for (final directory in <Directory>[_root!, _documentsDirectory!]) {
      await for (final entity in directory.list()) {
        if (entity is File && entity.path.endsWith('.tmp')) {
          await _quarantineFile(
            entity,
            KifuQuarantineReason.staleAtomicWrite,
            quarantined,
          );
          found = true;
        }
      }
    }
    return found;
  }

  Future<void> _persistRedundantly(_IndexState candidate) async {
    // The first durable slot is the transaction commit point. Until it exists,
    // callers must continue to observe the previous in-memory state.
    final committed = await _commitIndexOnce(candidate);
    _state = committed;

    try {
      final healed = await _commitIndexOnce(committed);
      _state = healed;
    } on FileSystemException {
      // The mutation is already durable. Reporting a failure here would invite
      // a retry that appears duplicate/absent despite the operation having
      // committed. A later load heals the lagging redundant slot.
    }
  }

  Future<_IndexState> _commitIndexOnce(_IndexState candidate) async {
    final generations = <int>[
      for (final slot in _slots) slot?.generation ?? -1,
    ];
    final target = generations[0] <= generations[1] ? 0 : 1;
    final maxGeneration = <int>[
      candidate.generation,
      ...generations,
    ].reduce((left, right) => left > right ? left : right);
    final next = _IndexState(
      generation: maxGeneration + 1,
      entries: candidate.entries,
    );
    final bytes = utf8.encode('${jsonEncode(next.toJson())}\n');
    await _writeAtomically(_indexFile(target), bytes);
    _slots[target] = next;
    return next;
  }

  Future<bool> _writeContentIfAbsent(String digest, List<int> bytes) async {
    final file = _contentFile(digest);
    if (await file.exists()) {
      final existing = await readBoundedFile(
        file,
        maximumBytes: codec.syntaxParser.limits.maxInputBytes,
      );
      if (KifuContentIdentity.sha256Bytes(existing) == digest) return false;
      throw StateError(
        'A content-addressed SGF file failed its SHA-256 check.',
      );
    }
    await _writeAtomically(file, bytes);
    return true;
  }

  List<int> _encodeWithinLimits(KifuDocument document) {
    final encoded = codec.encode(document);
    codec.syntaxParser.limits.enforceInputCharacters(encoded.length);
    final bytes = utf8.encode(encoded);
    codec.syntaxParser.limits.enforceInputBytes(bytes.length);
    return bytes;
  }

  Future<void> _deleteContentIfUnreferenced(String digest) async {
    if (_state!.entries.values.any((entry) => entry.contentSha256 == digest)) {
      return;
    }
    final file = _contentFile(digest);
    if (await file.exists()) await file.delete();
  }

  Future<void> _deleteContentBestEffort(String digest) async {
    try {
      await _deleteContentIfUnreferenced(digest);
    } on Object {
      // Unindexed content is harmless and is quarantined during the next load.
      // Cleanup must never turn a failed rollback or a committed mutation into
      // a false transactional result.
    }
  }

  Future<void> _writeAtomically(File destination, List<int> bytes) async {
    final hook = _atomicWriteHook;
    if (hook != null) await hook(destination);
    final suffix =
        '${_clock().toUtc().microsecondsSinceEpoch}'
        '-${_uniqueFileSequence++}';
    final temporary = File('${destination.path}.$suffix.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    try {
      await temporary.rename(destination.path);
    } on FileSystemException {
      // POSIX rename replaces an existing file atomically. The fallback keeps
      // the other index slot valid on platforms whose rename rejects replace.
      if (await destination.exists()) await destination.delete();
      await temporary.rename(destination.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<void> _quarantineFile(
    File file,
    KifuQuarantineReason reason,
    List<KifuQuarantineItem> quarantined,
  ) async {
    final name = _basename(file.path);
    quarantined.add(KifuQuarantineItem(itemName: name, reason: reason));
    if (!await file.exists()) return;
    final stamp = _clock().toUtc().microsecondsSinceEpoch;
    final target = File(
      _join(
        _quarantineDirectory!.path,
        '$stamp-${_uniqueFileSequence++}-${reason.name}-$name',
      ),
    );
    try {
      await file.rename(target.path);
    } on FileSystemException {
      await file.copy(target.path);
      await file.delete();
    }
  }

  File _indexFile(int slot) => File(_join(_root!.path, _indexNames[slot]));

  File _contentFile(String digest) =>
      File(_join(_documentsDirectory!.path, '$digest.sgf'));
}

final class _SlotRead {
  const _SlotRead({this.existed = false, this.wasCorrupt = false, this.state});

  final bool existed;
  final bool wasCorrupt;
  final _IndexState? state;
}

final class _IndexState {
  const _IndexState({required this.generation, required this.entries});

  factory _IndexState.fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version is int && version != FileKifuRepository.schemaVersion) {
      throw KifuRepositoryUpgradeRequiredException(
        foundVersion: version,
        supportedVersion: FileKifuRepository.schemaVersion,
      );
    }
    if (version != FileKifuRepository.schemaVersion) {
      throw const FormatException('Invalid storage schema version.');
    }
    final generation = json['generation'];
    if (generation is! int || generation < 1) {
      throw const FormatException('Invalid index generation.');
    }
    final rawEntries = json['entries'];
    if (rawEntries is! List<Object?>) {
      throw const FormatException('Index entries must be an array.');
    }
    final entries = <String, _IndexEntry>{};
    final digests = <String>{};
    for (final value in rawEntries) {
      if (value is! Map<String, Object?>) {
        throw const FormatException('An index entry must be an object.');
      }
      final entry = _IndexEntry.fromJson(value);
      if (entries.containsKey(entry.documentId) ||
          !digests.add(entry.contentSha256)) {
        throw const FormatException('Duplicate index id or content digest.');
      }
      entries[entry.documentId] = entry;
    }
    final state = _IndexState(generation: generation, entries: entries);
    final declaredHash = json['indexSha256'];
    if (declaredHash is! String ||
        !KifuContentIdentity.isSha256(declaredHash) ||
        declaredHash != state._payloadSha256) {
      throw const FormatException('Index integrity check failed.');
    }
    return state;
  }

  final int generation;
  final Map<String, _IndexEntry> entries;

  _IndexState copyWith({Map<String, _IndexEntry>? entries}) => _IndexState(
    generation: generation,
    entries: Map<String, _IndexEntry>.unmodifiable(entries ?? this.entries),
  );

  _IndexState withEntry(_IndexEntry entry) {
    final next = Map<String, _IndexEntry>.of(entries);
    next[entry.documentId] = entry;
    return copyWith(entries: next);
  }

  _IndexState withoutEntry(String documentId) {
    final next = Map<String, _IndexEntry>.of(entries)..remove(documentId);
    return copyWith(entries: next);
  }

  String get entriesFingerprint =>
      KifuContentIdentity.sha256Bytes(utf8.encode(jsonEncode(_entriesJson)));

  String get _payloadSha256 =>
      KifuContentIdentity.sha256Bytes(utf8.encode(jsonEncode(_payloadJson)));

  List<Map<String, Object?>> get _entriesJson {
    final ordered = entries.values.toList()
      ..sort((left, right) => left.documentId.compareTo(right.documentId));
    return <Map<String, Object?>>[for (final entry in ordered) entry.toJson()];
  }

  Map<String, Object?> get _payloadJson => <String, Object?>{
    'schemaVersion': FileKifuRepository.schemaVersion,
    'generation': generation,
    'entries': _entriesJson,
  };

  Map<String, Object?> toJson() => <String, Object?>{
    ..._payloadJson,
    'indexSha256': _payloadSha256,
  };
}

final class _IndexEntry {
  const _IndexEntry({
    required this.documentId,
    required this.contentSha256,
    required this.trustType,
    required this.sourceKind,
    required this.createdAt,
    required this.updatedAt,
    this.sourceReference,
  });

  factory _IndexEntry.fromDocument(
    KifuDocument document, {
    required String contentSha256,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) => _IndexEntry(
    documentId: document.id,
    contentSha256: contentSha256,
    trustType: _trustTypeOf(document),
    sourceKind: document.source.kind,
    sourceReference: document.source.reference,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  factory _IndexEntry.fromJson(Map<String, Object?> json) {
    final documentId = json['documentId'];
    final contentSha256 = json['contentSha256'];
    final trustType = json['trustType'];
    final sourceKindName = json['sourceKind'];
    final sourceReference = json['sourceReference'];
    final createdAtValue = json['createdAt'];
    final updatedAtValue = json['updatedAt'];
    if (documentId is! String ||
        documentId.isEmpty ||
        documentId.length > 512 ||
        documentId.contains('\u0000')) {
      throw const FormatException('Invalid document id.');
    }
    if (contentSha256 is! String ||
        !KifuContentIdentity.isSha256(contentSha256)) {
      throw const FormatException('Invalid content SHA-256.');
    }
    if (trustType is! String || !_trustTypes.contains(trustType)) {
      throw const FormatException('Invalid document trust type.');
    }
    if (sourceKindName is! String) {
      throw const FormatException('Invalid source kind.');
    }
    final sourceKind = _firstWhereOrNull(
      KifuSourceKind.values,
      (value) => value.name == sourceKindName,
    );
    if (sourceKind == null ||
        (sourceReference != null && sourceReference is! String)) {
      throw const FormatException('Invalid source metadata.');
    }
    if (sourceReference is String && sourceReference.length > 4096) {
      throw const FormatException('Source reference is too long.');
    }
    if (createdAtValue is! String || updatedAtValue is! String) {
      throw const FormatException('Invalid persistence timestamp.');
    }
    final createdAt = DateTime.tryParse(createdAtValue)?.toUtc();
    final updatedAt = DateTime.tryParse(updatedAtValue)?.toUtc();
    if (createdAt == null ||
        updatedAt == null ||
        updatedAt.isBefore(createdAt)) {
      throw const FormatException('Invalid persistence timestamp.');
    }
    return _IndexEntry(
      documentId: documentId,
      contentSha256: contentSha256,
      trustType: trustType,
      sourceKind: sourceKind,
      sourceReference: sourceReference as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  final String documentId;
  final String contentSha256;
  final String trustType;
  final KifuSourceKind sourceKind;
  final String? sourceReference;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'documentId': documentId,
    'contentSha256': contentSha256,
    'trustType': trustType,
    'sourceKind': sourceKind.name,
    'sourceReference': sourceReference,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

const _trustTypes = <String>{'position', 'partial', 'verified'};

String _trustTypeOf(KifuDocument document) => switch (document) {
  PositionSnapshot() => 'position',
  PartialGameRecord() => 'partial',
  VerifiedGameRecord() => 'verified',
};

String _join(String parent, String child) =>
    '$parent${Platform.pathSeparator}$child';

String _joinAll(List<String> segments) => segments.reduce(_join);

String _basename(String path) => path.split(Platform.pathSeparator).last;

T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T value) matches) {
  for (final value in values) {
    if (matches(value)) return value;
  }
  return null;
}
