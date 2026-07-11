import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

import 'kifu_repository.dart';

enum KifuWorkspaceStatus { idle, loading, ready, saving, failed }

final class KifuWorkspaceController extends ChangeNotifier {
  KifuWorkspaceController({KifuRepository? repository})
    : _repository = repository;

  final KifuRepository? _repository;
  final List<KifuDocument> _documents = <KifuDocument>[];
  KifuDocument? _selected;
  KifuWorkspaceStatus _status = KifuWorkspaceStatus.idle;
  Object? _error;
  List<KifuQuarantineItem> _quarantined = const <KifuQuarantineItem>[];
  Future<void> _tail = Future<void>.value();

  List<KifuDocument> get documents =>
      List<KifuDocument>.unmodifiable(_documents);
  KifuDocument? get selected => _selected;
  KifuWorkspaceStatus get status => _status;
  Object? get error => _error;
  List<KifuQuarantineItem> get quarantined => _quarantined;
  bool get isPersistent => _repository != null;

  Future<void> initialize() => _serialize(() async {
    if (_repository == null) {
      _status = KifuWorkspaceStatus.ready;
      notifyListeners();
      return;
    }
    _status = KifuWorkspaceStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final result = await _repository.load();
      _documents
        ..clear()
        ..addAll(result.documents);
      _selected = _documents.isEmpty ? null : _documents.first;
      _quarantined = result.quarantined;
      _status = KifuWorkspaceStatus.ready;
    } on Object catch (error) {
      _error = error;
      _status = KifuWorkspaceStatus.failed;
    }
    notifyListeners();
  });

  /// Immediate insertion retained for deterministic tests and ephemeral
  /// previews. Product save actions await [addPersisted] so failures surface.
  void add(KifuDocument document) {
    _addInMemory(document);
    final repository = _repository;
    if (repository != null) {
      _status = KifuWorkspaceStatus.saving;
      notifyListeners();
      unawaited(_persistOptimistic(document, repository));
    }
  }

  Future<KifuWriteResult?> addPersisted(KifuDocument document) =>
      _serialize(() async {
        final repository = _repository;
        if (repository == null) {
          _addInMemory(document);
          return null;
        }
        _status = KifuWorkspaceStatus.saving;
        _error = null;
        notifyListeners();
        try {
          final result = await repository.add(document);
          _applyWriteResult(document, result);
          _status = KifuWorkspaceStatus.ready;
          notifyListeners();
          return result;
        } on Object catch (error) {
          _error = error;
          _status = KifuWorkspaceStatus.failed;
          notifyListeners();
          rethrow;
        }
      });

  /// Replaces a document without changing its trust type implicitly.
  /// Callers must construct the concrete [KifuDocument] subtype they intend to
  /// persist; repositories independently verify that type on reload.
  Future<KifuWriteResult?> updatePersisted(KifuDocument document) =>
      _serialize(() async {
        final index = _documents.indexWhere(
          (candidate) => candidate.id == document.id,
        );
        if (index < 0) {
          throw KifuNotFoundException(document.id);
        }
        if (_documents[index].runtimeType != document.runtimeType) {
          throw ArgumentError.value(
            document.runtimeType,
            'document',
            'Updating a document cannot change its trust type.',
          );
        }
        final repository = _repository;
        if (repository == null) {
          _documents[index] = document;
          _selected = document;
          _status = KifuWorkspaceStatus.ready;
          _error = null;
          notifyListeners();
          return null;
        }
        _status = KifuWorkspaceStatus.saving;
        _error = null;
        notifyListeners();
        try {
          final result = await repository.update(document);
          _documents[index] = document;
          _selected = document;
          _status = KifuWorkspaceStatus.ready;
          notifyListeners();
          return result;
        } on Object catch (error) {
          _error = error;
          _status = KifuWorkspaceStatus.failed;
          notifyListeners();
          rethrow;
        }
      });

  Future<bool> deletePersisted(String documentId) => _serialize(() async {
    final repository = _repository;
    final existed = _documents.any((document) => document.id == documentId);
    final deleted = repository == null
        ? existed
        : await repository.delete(documentId);
    if (!deleted) return false;
    _documents.removeWhere((document) => document.id == documentId);
    if (_selected?.id == documentId) {
      _selected = _documents.isEmpty ? null : _documents.first;
    }
    _status = KifuWorkspaceStatus.ready;
    notifyListeners();
    return true;
  });

  void select(KifuDocument document) {
    if (!_documents.contains(document)) {
      throw ArgumentError.value(
        document.id,
        'document',
        'Document is not in this workspace.',
      );
    }
    _selected = document;
    notifyListeners();
  }

  void _addInMemory(KifuDocument document, {bool notify = true}) {
    final index = _documents.indexWhere(
      (candidate) => candidate.id == document.id,
    );
    if (index < 0) {
      _documents.insert(0, document);
    } else {
      _documents[index] = document;
    }
    _selected = document;
    if (notify) notifyListeners();
  }

  void _applyWriteResult(KifuDocument document, KifuWriteResult result) {
    if (result.disposition != KifuWriteDisposition.duplicate) {
      _addInMemory(document, notify: false);
      return;
    }
    _documents.removeWhere(
      (candidate) =>
          candidate.id == document.id &&
          candidate.id != result.persistedDocumentId,
    );
    final existing = _documents.where(
      (candidate) => candidate.id == result.persistedDocumentId,
    );
    if (existing.isNotEmpty) _selected = existing.first;
  }

  Future<void> _persistOptimistic(
    KifuDocument document,
    KifuRepository repository,
  ) async {
    try {
      final result = await repository.add(document);
      _applyWriteResult(document, result);
      _status = KifuWorkspaceStatus.ready;
    } on Object catch (error) {
      _error = error;
      _status = KifuWorkspaceStatus.failed;
    }
    notifyListeners();
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

class KifuWorkspace extends InheritedNotifier<KifuWorkspaceController> {
  const KifuWorkspace({
    required KifuWorkspaceController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static KifuWorkspaceController of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope?.notifier == null) {
      throw StateError('KifuWorkspace is missing above this context.');
    }
    return scope!.notifier!;
  }

  static KifuWorkspace? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KifuWorkspace>();
}
