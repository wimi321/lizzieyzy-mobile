import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart'
    hide StoneColor;
import 'package:lizzieyzy_mobile/domain/domain.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const FeatureTopBar(
              title: '导入棋谱',
              subtitle: 'SGF / GIB · 本地校验',
              leading: BackCircleButton(),
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
      message: _controller.errorMessage ?? '无法读取棋谱。',
      onRetry: _controller.pickAndImport,
    ),
    KifuImportStatus.imported => _ImportSuccess(
      imported: _controller.result!,
      saved: _savedDocument == _controller.result!.document,
      onSave: () {
        final document = _controller.result!.document;
        KifuWorkspace.of(context).add(document);
        setState(() => _savedDocument = document);
      },
      onPickAgain: _controller.pickAndImport,
    ),
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
        Text('选择 SGF 或 GIB 棋谱', style: theme.textTheme.titleLarge),
        const SizedBox(height: GoSpacing.s2),
        Text(
          '导入后先进行格式与围棋规则校验；有缺口的记录会明确降级，不会伪装成完整棋谱。',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: GoSpacing.s6),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('选择棋谱文件'),
          ),
        ),
      ],
    );
  }
}

class _ImportProgress extends StatelessWidget {
  const _ImportProgress();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CircularProgressIndicator(),
        SizedBox(height: GoSpacing.s4),
        Text('正在校验棋谱…'),
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
        Text('导入失败', style: theme.textTheme.titleLarge),
        const SizedBox(height: GoSpacing.s2),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: GoSpacing.s5),
        FilledButton(onPressed: onRetry, child: const Text('重新选择')),
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
  final VoidCallback onSave;
  final VoidCallback onPickAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final document = imported.document;
    final (typeLabel, detail) = switch (document) {
      VerifiedGameRecord(:final moves) => ('完整棋谱', '${moves.length}手 · 规则校验通过'),
      PartialGameRecord(:final moves) => ('片段棋谱', '${moves.length}手 · 需要人工确认'),
      PositionSnapshot(:final position) => (
        '当前局面',
        '黑${position.count(StoneColor.black)}子 · 白${position.count(StoneColor.white)}子',
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
                if (imported.warnings.isNotEmpty) ...<Widget>[
                  const SizedBox(height: GoSpacing.s3),
                  MetricPill(
                    label: '警告',
                    value: '${imported.warnings.length}项',
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
          label: Text(saved ? '已加入棋谱' : '加入棋谱'),
        ),
        const SizedBox(height: GoSpacing.s2),
        TextButton(onPressed: onPickAgain, child: const Text('导入另一份')),
      ],
    );
  }
}
