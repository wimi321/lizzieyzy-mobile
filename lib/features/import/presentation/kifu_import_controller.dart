import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';

typedef KifuFilePicker = Future<XFile?> Function();

enum KifuImportStatus { idle, picking, imported, failed }

enum KifuFileFormat { sgf, gib }

final class ImportedKifu {
  const ImportedKifu({
    required this.fileName,
    required this.format,
    required this.document,
    required this.warnings,
  });

  final String fileName;
  final KifuFileFormat format;
  final KifuDocument document;
  final List<String> warnings;
}

final class KifuImportController extends ChangeNotifier {
  KifuImportController({
    KifuFilePicker? picker,
    this.sgfCodec = const SgfCodec(),
    this.gibCodec = const GibCodec(),
  }) : _picker = picker ?? _openKifuFile;

  final KifuFilePicker _picker;
  final SgfCodec sgfCodec;
  final GibCodec gibCodec;

  KifuImportStatus _status = KifuImportStatus.idle;
  ImportedKifu? _result;
  String? _errorMessage;

  KifuImportStatus get status => _status;
  ImportedKifu? get result => _result;
  String? get errorMessage => _errorMessage;

  Future<void> pickAndImport() async {
    if (_status == KifuImportStatus.picking) return;
    _status = KifuImportStatus.picking;
    _result = null;
    _errorMessage = null;
    notifyListeners();
    try {
      final file = await _picker();
      if (file == null) {
        _status = KifuImportStatus.idle;
        notifyListeners();
        return;
      }
      final format = _formatFor(file.name);
      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: true);
      final documentId = 'import-${_stableId(file.name, bytes)}';
      switch (format) {
        case KifuFileFormat.sgf:
          final decoded = sgfCodec.decode(
            content,
            documentId: documentId,
            kifuSource: KifuSource(
              kind: KifuSourceKind.localFile,
              reference: file.name,
            ),
          );
          _result = ImportedKifu(
            fileName: file.name,
            format: format,
            document: decoded.document,
            warnings: <String>[
              for (final warning in decoded.warnings) warning.message,
            ],
          );
        case KifuFileFormat.gib:
          final decoded = gibCodec.decode(
            content,
            documentId: documentId,
            kifuSource: KifuSource(
              kind: KifuSourceKind.localFile,
              reference: file.name,
            ),
          );
          _result = ImportedKifu(
            fileName: file.name,
            format: format,
            document: decoded.document,
            warnings: <String>[
              for (final warning in decoded.warnings) warning.message,
            ],
          );
      }
      _status = KifuImportStatus.imported;
    } on Object catch (error) {
      _status = KifuImportStatus.failed;
      _errorMessage = switch (error) {
        FormatException(:final message) => message,
        _ => '无法读取该棋谱，请确认文件未损坏。',
      };
    }
    notifyListeners();
  }

  static KifuFileFormat _formatFor(String name) {
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'sgf' => KifuFileFormat.sgf,
      'gib' => KifuFileFormat.gib,
      _ => throw const FormatException('仅支持 .sgf 与 .gib 棋谱。'),
    };
  }

  static String _stableId(String name, List<int> bytes) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(name)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

Future<XFile?> _openKifuFile() {
  const type = XTypeGroup(
    label: '围棋棋谱',
    extensions: <String>['sgf', 'gib'],
    uniformTypeIdentifiers: <String>['public.text'],
  );
  return openFile(acceptedTypeGroups: const <XTypeGroup>[type]);
}
