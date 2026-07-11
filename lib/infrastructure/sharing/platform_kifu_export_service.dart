import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:lizzieyzy_mobile/application/kifu_export_service.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

typedef ExportTemporaryDirectoryProvider = Future<Directory> Function();
typedef ShareSheetInvoker = Future<ShareResult> Function(ShareParams params);
typedef ExportClock = DateTime Function();

final class PlatformKifuExportService
    implements KifuExportService, KifuExportArtifactMaintenance {
  PlatformKifuExportService({
    ExportTemporaryDirectoryProvider? temporaryDirectoryProvider,
    ShareSheetInvoker? shareSheetInvoker,
    ExportClock? clock,
    this.codec = const SgfCodec(),
    this.maxCleanupEntries = 256,
    this.maxCleanupDeletes = 64,
  }) : _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? getTemporaryDirectory,
       _shareSheetInvoker =
           shareSheetInvoker ?? ((params) => SharePlus.instance.share(params)),
       _clock = clock ?? DateTime.now {
    if (maxCleanupEntries < 1) {
      throw ArgumentError.value(
        maxCleanupEntries,
        'maxCleanupEntries',
        'Must be positive.',
      );
    }
    if (maxCleanupDeletes < 1 || maxCleanupDeletes > maxCleanupEntries) {
      throw ArgumentError.value(
        maxCleanupDeletes,
        'maxCleanupDeletes',
        'Must be positive and no greater than maxCleanupEntries.',
      );
    }
  }

  final ExportTemporaryDirectoryProvider _temporaryDirectoryProvider;
  final ShareSheetInvoker _shareSheetInvoker;
  final ExportClock _clock;
  final SgfCodec codec;
  final int maxCleanupEntries;
  final int maxCleanupDeletes;

  @override
  Future<void> cleanupStaleArtifacts() async {
    try {
      final temporaryRoot = await _temporaryDirectoryProvider();
      await _cleanupAtRoot(temporaryRoot);
    } on Object {
      // Lifecycle cleanup is best effort. A cache-provider or filesystem
      // failure must never prevent the app from starting or resuming.
    }
  }

  @override
  Future<KifuShareOutcome> share(
    KifuDocument document, {
    ShareAnchor? anchor,
  }) async {
    late final File file;
    try {
      final temporaryRoot = await _temporaryDirectoryProvider();
      final directory = Directory(_join(temporaryRoot.path, 'lizzieyzy-share'));
      await directory.create(recursive: true);
      await _cleanupAtRoot(temporaryRoot);
      file = File(
        _join(
          directory.path,
          '${_safeBaseName(document)}$_ownedFileMarker'
          '${_clock().toUtc().millisecondsSinceEpoch}.sgf',
        ),
      );
      await file.writeAsString(codec.encode(document), flush: true);
    } on Object {
      throw const KifuExportWriteException();
    }

    try {
      final result = await _shareSheetInvoker(
        ShareParams(
          files: <XFile>[
            XFile(
              file.path,
              mimeType: 'application/x-go-sgf',
              name: _basename(file.path),
            ),
          ],
          subject: _shareSubject(document),
          sharePositionOrigin: anchor == null
              ? null
              : Rect.fromLTWH(
                  anchor.left,
                  anchor.top,
                  anchor.width,
                  anchor.height,
                ),
        ),
      );
      return switch (result.status) {
        ShareResultStatus.success => KifuShareOutcome.success,
        ShareResultStatus.dismissed => KifuShareOutcome.dismissed,
        ShareResultStatus.unavailable => KifuShareOutcome.unavailable,
      };
    } on Object {
      throw const KifuExportShareException();
    }
  }

  Future<void> _cleanupAtRoot(Directory temporaryRoot) async {
    final cutoff = _clock().toUtc().subtract(const Duration(days: 1));
    final budget = _CleanupBudget(
      remainingEntries: maxCleanupEntries,
      remainingDeletes: maxCleanupDeletes,
    );
    await _cleanupDirectory(
      Directory(_join(temporaryRoot.path, 'lizzieyzy-share')),
      cutoff: cutoff,
      budget: budget,
      // This app-specific directory is created and written only by this
      // service, so legacy pre-marker SGF exports remain safely eligible.
      accepts: _isSgfName,
    );
    if (budget.isExhausted) return;

    // share_plus 13.x copies Android file shares into the application-private
    // <cache>/share_plus directory. iOS does not create this copy for an XFile
    // that already has a path, so the directory normally does not exist there.
    // Only our marked SGF names are eligible; unrelated plugin cache files are
    // intentionally retained.
    await _cleanupDirectory(
      Directory(_join(temporaryRoot.path, 'share_plus')),
      cutoff: cutoff,
      budget: budget,
      accepts: _isOwnedExportName,
    );
  }

  Future<void> _cleanupDirectory(
    Directory directory, {
    required DateTime cutoff,
    required _CleanupBudget budget,
    required bool Function(String name) accepts,
  }) async {
    try {
      await for (final entity in directory.list(followLinks: false)) {
        if (budget.remainingEntries == 0 || budget.remainingDeletes == 0) {
          break;
        }
        budget.remainingEntries -= 1;
        if (entity is! File || !accepts(_basename(entity.path))) continue;
        try {
          final modified = (await entity.stat()).modified.toUtc();
          if (modified.isBefore(cutoff)) {
            await entity.delete();
            budget.remainingDeletes -= 1;
          }
        } on FileSystemException {
          // A single raced, locked, or unreadable file must not stop cleanup of
          // the remaining bounded candidates.
        }
      }
    } on FileSystemException {
      // Cleanup is best effort and must not block startup or explicit export.
    }
  }
}

const _ownedFileMarker = '-LizzieYZY-';
final _ownedExportPattern = RegExp(r'-LizzieYZY-[0-9]{10,}\.sgf$');

bool _isOwnedExportName(String name) => _ownedExportPattern.hasMatch(name);
bool _isSgfName(String name) => name.endsWith('.sgf');

final class _CleanupBudget {
  _CleanupBudget({
    required this.remainingEntries,
    required this.remainingDeletes,
  });

  int remainingEntries;
  int remainingDeletes;

  bool get isExhausted => remainingEntries == 0 || remainingDeletes == 0;
}

String _safeBaseName(KifuDocument document) {
  final metadata = document.metadata;
  final players = <String>[
    if (metadata.blackPlayer case final value? when value.trim().isNotEmpty)
      value.trim(),
    if (metadata.whitePlayer case final value? when value.trim().isNotEmpty)
      value.trim(),
  ];
  final source = players.isEmpty ? 'LizzieYZY-棋谱' : players.join('-vs-');
  final sanitized = source
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final runes = sanitized.runes.take(64).toList(growable: false);
  return String.fromCharCodes(runes.isEmpty ? 'LizzieYZY-棋谱'.runes : runes);
}

String _shareSubject(KifuDocument document) {
  final black = document.metadata.blackPlayer ?? '黑方';
  final white = document.metadata.whitePlayer ?? '白方';
  return '$black vs $white · LizzieYZY Mobile';
}

String _join(String left, String right) => left.endsWith(Platform.pathSeparator)
    ? '$left$right'
    : '$left${Platform.pathSeparator}$right';

String _basename(String path) => path
    .split(Platform.pathSeparator)
    .where((segment) => segment.isNotEmpty)
    .last;
