import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart'
    hide StoneColor;
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../common/presentation/feature_chrome.dart';
import 'kifu_import_controller.dart';

class KifuImportScreen extends StatefulWidget {
  const KifuImportScreen({super.key, this.controller});

  final KifuImportController? controller;

  @override
  State<KifuImportScreen> createState() => _KifuImportScreenState();
}

class _KifuImportScreenState extends State<KifuImportScreen> {
  late final KifuImportController _controller =
      widget.controller ?? KifuImportController();
  late final bool _ownsController = widget.controller == null;
  KifuDocument? _savedDocument;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            FeatureTopBar(
              title: l10n.importKifuTitle,
              subtitle: l10n.importKifuSubtitle,
              leading: const BackCircleButton(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  GoSpacing.s4,
                  GoSpacing.s2,
                  GoSpacing.s4,
                  GoSpacing.s4,
                ),
                child: _body(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) => switch (_controller.status) {
    KifuImportStatus.idle => _ImportIdle(onPick: _controller.pickAndImport),
    KifuImportStatus.picking => const _ImportProgress(),
    KifuImportStatus.failed => _ImportFailure(
      message: _failureMessage(context, _controller.failureCode),
      onRetry: _controller.pickAndImport,
    ),
    KifuImportStatus.imported => _ImportSuccess(
      imported: _controller.result!,
      saved: _savedDocument == _controller.result!.document,
      onSave: () async {
        final document = _controller.result!.document;
        try {
          await KifuWorkspace.of(context).addPersisted(document);
          if (mounted) setState(() => _savedDocument = document);
        } on Object {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.saveKifuFailed)));
        }
      },
      onPickAgain: _controller.pickAndImport,
    ),
  };

  String _failureMessage(BuildContext context, KifuImportFailureCode? code) =>
      switch (code) {
        KifuImportFailureCode.resourceLimit =>
          context.l10n.importErrorResourceLimit,
        KifuImportFailureCode.invalidEncoding =>
          context.l10n.importErrorInvalidEncoding,
        KifuImportFailureCode.unsupportedFormat =>
          context.l10n.importErrorUnsupportedFormat,
        KifuImportFailureCode.invalidRecord =>
          context.l10n.importErrorInvalidRecord,
        KifuImportFailureCode.unknown => context.l10n.importErrorUnknown,
        null => context.l10n.kifuReadFailed,
      };
}

class _ImportIdle extends StatelessWidget {
  const _ImportIdle({required this.onPick});
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.description_outlined,
            size: 40,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: GoSpacing.s5),
        Text(context.l10n.chooseKifuTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: GoSpacing.s2),
        Text(
          context.l10n.chooseKifuBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: GoSpacing.s6),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.folder_open_outlined),
            label: Text(context.l10n.chooseKifuFile),
          ),
        ),
      ],
    );
  }
}

class _ImportProgress extends StatelessWidget {
  const _ImportProgress();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const CircularProgressIndicator(),
        const SizedBox(height: GoSpacing.s4),
        Text(context.l10n.validatingKifu),
      ],
    ),
  );
}

class _ImportFailure extends StatelessWidget {
  const _ImportFailure({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.error_outline_rounded,
          size: 52,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: GoSpacing.s4),
        Text(context.l10n.importFailed, style: theme.textTheme.titleLarge),
        const SizedBox(height: GoSpacing.s2),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: GoSpacing.s5),
        FilledButton(onPressed: onRetry, child: Text(context.l10n.chooseAgain)),
      ],
    );
  }
}

class _ImportSuccess extends StatelessWidget {
  const _ImportSuccess({
    required this.imported,
    required this.saved,
    required this.onSave,
    required this.onPickAgain,
  });

  final ImportedKifu imported;
  final bool saved;
  final Future<void> Function() onSave;
  final VoidCallback onPickAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final document = imported.document;
    final (typeLabel, detail) = switch (document) {
      VerifiedGameRecord(:final moves) => (
        l10n.completeKifu,
        l10n.verifiedRecordDetail(l10n.moveCount(moves.length)),
      ),
      PartialGameRecord(:final moves) => (
        l10n.partialKifu,
        l10n.partialRecordDetail(l10n.moveCount(moves.length)),
      ),
      PositionSnapshot(:final position) => (
        l10n.statusCurrentPosition,
        l10n.stoneCounts(
          position.count(StoneColor.black),
          position.count(StoneColor.white),
        ),
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SurfacePanel(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: GoSpacing.s4),
                Text(typeLabel, style: theme.textTheme.headlineSmall),
                const SizedBox(height: GoSpacing.s1),
                Text(detail, style: theme.textTheme.bodyMedium),
                const SizedBox(height: GoSpacing.s3),
                Text(
                  imported.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: GoSpacing.s3),
                MetricPill(
                  label: l10n.fileEncoding,
                  value: imported.textEncoding.label,
                  tone: imported.textEncoding == KifuTextEncoding.utf8
                      ? MetricTone.neutral
                      : MetricTone.gold,
                ),
                if (imported.warnings.isNotEmpty ||
                    imported.textEncoding != KifuTextEncoding.utf8) ...<Widget>[
                  const SizedBox(height: GoSpacing.s3),
                  MetricPill(
                    label: l10n.warning,
                    value: l10n.warningCount(
                      imported.warnings.length +
                          (imported.textEncoding == KifuTextEncoding.utf8
                              ? 0
                              : 1),
                    ),
                    tone: MetricTone.gold,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: GoSpacing.s3),
        FilledButton.icon(
          onPressed: saved ? null : onSave,
          icon: Icon(saved ? Icons.check_rounded : Icons.save_outlined),
          label: Text(saved ? l10n.addedToKifu : l10n.addToKifu),
        ),
        const SizedBox(height: GoSpacing.s2),
        TextButton(onPressed: onPickAgain, child: Text(l10n.importAnother)),
      ],
    );
  }
}
