import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';

import 'kifu_workspace.dart';

enum InboundKifuStatus { idle, importing, imported, failed }

enum InboundKifuFailureCode { invalidFile, storage, platform }

final class InboundKifuController extends ChangeNotifier {
  InboundKifuController({
    required KifuWorkspaceController workspace,
    PlatformInboundKifuService? service,
    SgfCodec? sgfCodec,
    GibCodec? gibCodec,
  }) : _workspace = workspace,
       _service = service ?? PlatformInboundKifuService(),
       _sgfCodec = sgfCodec ?? const SgfCodec(),
       _gibCodec = gibCodec ?? const GibCodec();

  final KifuWorkspaceController _workspace;
  final PlatformInboundKifuService _service;
  final SgfCodec _sgfCodec;
  final GibCodec _gibCodec;

  InboundKifuStatus _status = InboundKifuStatus.idle;
  InboundKifuFailureCode? _failureCode;
  KifuDocument? _lastDocument;
  String? _lastFileName;
  KifuTextEncoding? _lastTextEncoding;
  List<String> _warnings = const <String>[];
  StreamSubscription<PlatformInboundKifuFile>? _subscription;
  Future<void> _tail = Future<void>.value();
  bool _disposed = false;

  InboundKifuStatus get status => _status;
  InboundKifuFailureCode? get failureCode => _failureCode;
  KifuDocument? get lastDocument => _lastDocument;
  String? get lastFileName => _lastFileName;
  KifuTextEncoding? get lastTextEncoding => _lastTextEncoding;
  List<String> get warnings => _warnings;

  Future<void> initialize() async {
    if (_disposed || _subscription != null) return;
    // Subscribe before asking for the cold-start value. On scene-based iOS,
    // UIKit can report the initial document after Dart has already called the
    // method channel; native code then safely replays it as a runtime event.
    _subscription = _service.runtimeEvents.listen(
      (file) => unawaited(_enqueue(file)),
      onError: (Object error, StackTrace _) => _recordFailure(error),
    );
    try {
      final initial = await _service.takeInitial();
      if (initial != null) await _enqueue(initial);
    } on Object catch (error) {
      _recordFailure(error);
    }
  }

  void clearNotice() {
    if (_status == InboundKifuStatus.imported ||
        _status == InboundKifuStatus.failed) {
      _status = InboundKifuStatus.idle;
      _failureCode = null;
      notifyListeners();
    }
  }

  Future<void> _enqueue(PlatformInboundKifuFile file) {
    final next = _tail.then((_) => _import(file));
    _tail = next.catchError((Object _) {});
    return next;
  }

  Future<void> _import(PlatformInboundKifuFile file) async {
    if (_disposed) return;
    _status = InboundKifuStatus.importing;
    _failureCode = null;
    notifyListeners();
    try {
      final source = KifuSource(
        kind: KifuSourceKind.shareSheet,
        reference: file.fileName,
      );
      final documentId = 'share-${file.sha256}';
      late final KifuDocument document;
      late final List<String> warnings;
      switch (file.format) {
        case PlatformInboundKifuFormat.sgf:
          final result = _sgfCodec.decode(
            file.text,
            documentId: documentId,
            kifuSource: source,
          );
          document = result.document;
          warnings = <String>[
            for (final warning in result.warnings) warning.message,
          ];
        case PlatformInboundKifuFormat.gib:
          final result = _gibCodec.decode(
            file.text,
            documentId: documentId,
            kifuSource: source,
          );
          document = result.document;
          warnings = <String>[
            for (final warning in result.warnings) warning.message,
          ];
      }
      await _workspace.addPersisted(document);
      if (_disposed) return;
      // Content-addressed storage may deduplicate this import to an existing
      // document with a different id. Keep the actual workspace object so the
      // home notice can select and route it safely.
      _lastDocument = _workspace.selected ?? document;
      _lastFileName = file.fileName;
      _lastTextEncoding = file.textEncoding;
      _warnings = List<String>.unmodifiable(warnings);
      _status = InboundKifuStatus.imported;
      notifyListeners();
    } on Object catch (error) {
      _recordFailure(error);
    }
  }

  void _recordFailure(Object error) {
    if (_disposed) return;
    _failureCode = switch (error) {
      FormatException() ||
      KifuResourceLimitException() => InboundKifuFailureCode.invalidFile,
      PlatformInboundKifuException() => InboundKifuFailureCode.platform,
      _ => InboundKifuFailureCode.storage,
    };
    _status = InboundKifuStatus.failed;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

class InboundKifuScope extends InheritedNotifier<InboundKifuController> {
  const InboundKifuScope({
    required InboundKifuController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static InboundKifuController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InboundKifuScope>()?.notifier;
}
