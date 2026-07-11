import 'package:flutter/widgets.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

final class KifuWorkspaceController extends ChangeNotifier {
  final List<KifuDocument> _documents = <KifuDocument>[];
  KifuDocument? _selected;

  List<KifuDocument> get documents =>
      List<KifuDocument>.unmodifiable(_documents);
  KifuDocument? get selected => _selected;

  void add(KifuDocument document) {
    final index = _documents.indexWhere(
      (candidate) => candidate.id == document.id,
    );
    if (index < 0) {
      _documents.insert(0, document);
    } else {
      _documents[index] = document;
    }
    _selected = document;
    notifyListeners();
  }

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
