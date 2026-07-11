import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:lizzieyzy_mobile/application/kifu_repository.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/io/io.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';

typedef KifuFilePicker = Future<XFile?> Function();

enum KifuImportStatus { idle, picking, imported, failed }

enum KifuFileFormat { sgf, gib }

enum KifuImportFailureCode {
  resourceLimit,
  invalidEncoding,
  unsupportedFormat,
  invalidRecord,
  unknown,
}

final class _UnsupportedKifuFormatException implements Exception {
  const _UnsupportedKifuFormatException();
}

final class ImportedKifu {
  const ImportedKifu({
    required this.fileName,
    required this.format,
    required this.document,
    required this.warnings,
    required this.textEncoding,
  });

  final String fileName;
  final KifuFileFormat format;
  final KifuDocument document;
  final List<String> warnings;
  final KifuTextEncoding textEncoding;
}

final class KifuImportController extends ChangeNotifier {
  KifuImportController({
    KifuFilePicker? picker,
    this.limits = const KifuResourceLimits(),
    SgfCodec? sgfCodec,
    GibCodec? gibCodec,
    KifuTextDecoder? textDecoder,
  }) : _picker = picker ?? _openKifuFile,
       sgfCodec =
           sgfCodec ?? SgfCodec(syntaxParser: SgfSyntaxParser(limits: limits)),
       gibCodec = gibCodec ?? GibCodec(limits: limits),
       textDecoder =
           textDecoder ??
           KifuTextDecoder(
             limits: limits,
             gibCodec: gibCodec ?? GibCodec(limits: limits),
           );

  final KifuFilePicker _picker;
  final KifuResourceLimits limits;
  final SgfCodec sgfCodec;
  final GibCodec gibCodec;
  final KifuTextDecoder textDecoder;

  KifuImportStatus _status = KifuImportStatus.idle;
  ImportedKifu? _result;
  KifuImportFailureCode? _failureCode;

  KifuImportStatus get status => _status;
  ImportedKifu? get result => _result;
  KifuImportFailureCode? get failureCode => _failureCode;

  Future<void> pickAndImport() async {
    if (_status == KifuImportStatus.picking) return;
    _status = KifuImportStatus.picking;
    _result = null;
    _failureCode = null;
    notifyListeners();
    try {
      final file = await _picker();
      if (file == null) {
        _status = KifuImportStatus.idle;
        notifyListeners();
        return;
      }
      final format = _formatFor(file.name);
      final bytes = await readBoundedXFile(
        file,
        maximumBytes: limits.maxInputBytes,
      );
      final decodedText = switch (format) {
        KifuFileFormat.sgf => textDecoder.decodeSgf(bytes),
        KifuFileFormat.gib => textDecoder.decodeGib(bytes),
      };
      final content = decodedText.text;
      final documentId = 'import-${KifuContentIdentity.sha256Bytes(bytes)}';
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
            textEncoding: decodedText.encoding,
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
            textEncoding: decodedText.encoding,
          );
      }
      _status = KifuImportStatus.imported;
    } on Object catch (error) {
      _status = KifuImportStatus.failed;
      _failureCode = switch (error) {
        BoundedReadLimitException() ||
        KifuResourceLimitException() => KifuImportFailureCode.resourceLimit,
        AmbiguousKifuTextEncodingException() ||
        KifuTextDecodingException() => KifuImportFailureCode.invalidEncoding,
        _UnsupportedKifuFormatException() =>
          KifuImportFailureCode.unsupportedFormat,
        FormatException() => KifuImportFailureCode.invalidRecord,
        _ => KifuImportFailureCode.unknown,
      };
    }
    notifyListeners();
  }

  static KifuFileFormat _formatFor(String name) {
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'sgf' => KifuFileFormat.sgf,
      'gib' => KifuFileFormat.gib,
      _ => throw const _UnsupportedKifuFormatException(),
    };
  }
}

Future<XFile?> _openKifuFile() {
  const type = XTypeGroup(
    label: 'SGF / GIB',
    extensions: <String>['sgf', 'gib'],
    uniformTypeIdentifiers: <String>['public.text'],
  );
  return openFile(acceptedTypeGroups: const <XTypeGroup>[type]);
}
