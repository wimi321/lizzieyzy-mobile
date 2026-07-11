import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/inbound_kifu_controller.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';

class KifuHomeScreen extends StatelessWidget {
  const KifuHomeScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = const KifuHomeView();
    if (embedded) return content;
    return Scaffold(body: content);
  }
}

class KifuHomeView extends StatelessWidget {
  const KifuHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxWidth = MediaQuery.sizeOf(context).width >= 840 ? 760.0 : 680.0;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final largeTextMode = textScale >= 1.75;
    final imported =
        KifuWorkspace.maybeOf(context)?.notifier?.documents ??
        const <domain.KifuDocument>[];
    final inbound = InboundKifuScope.maybeOf(context);
    final showInboundNotice =
        inbound?.status == InboundKifuStatus.imported ||
        inbound?.status == InboundKifuStatus.failed;
    final inboundDocumentId = inbound?.status == InboundKifuStatus.imported
        ? inbound?.lastDocument?.id
        : null;
    final recent = <({_KifuSummary item, domain.KifuDocument document})>[
      for (final document in imported)
        if (document.id != inboundDocumentId)
          (item: _summaryFor(context, document, l10n), document: document),
    ];
    return Column(
      key: const Key('kifu-home-viewport'),
      children: <Widget>[
        FeatureTopBar(
          title: l10n.kifuTab,
          subtitle: l10n.homeSubtitle,
          actions: <Widget>[
            IconButton(
              tooltip: l10n.importKifuTooltip,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.importKifu),
              icon: const Icon(Icons.file_download_outlined),
            ),
            IconButton(
              tooltip: l10n.settingsTooltip,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.settingsHome),
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // At accessibility text sizes, reserve the saved vertical space
                // for complete (unclamped) glyphs and full-size touch targets.
                // The ordinary layout continues to show two recent games.
                final dense = constraints.maxHeight < 600 || largeTextMode;
                final recentCount = showInboundNotice
                    ? (largeTextMode ? 0 : 1)
                    : (largeTextMode ? 1 : 2);
                final gap = dense ? GoSpacing.s2 : GoSpacing.s3;
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    GoSpacing.s4,
                    dense ? GoSpacing.s1 : GoSpacing.s2,
                    GoSpacing.s4,
                    dense ? GoSpacing.s2 : GoSpacing.s3,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _ScanHeroCard(
                            dense: dense,
                            onTap: () =>
                                Navigator.pushNamed(context, AppRoutes.camera),
                          ),
                          SizedBox(height: gap),
                          SectionHeading(title: l10n.recentKifu),
                          const SizedBox(height: GoSpacing.s1),
                          if (showInboundNotice) ...<Widget>[
                            _InboundKifuNotice(
                              controller: inbound!,
                              onOpen: inbound.lastDocument == null
                                  ? null
                                  : () {
                                      final document = inbound.lastDocument!;
                                      KifuWorkspace.of(
                                        context,
                                      ).select(document);
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.routeForDocument(document),
                                        arguments: document,
                                      );
                                    },
                            ),
                            if (recentCount > 0 && recent.isNotEmpty)
                              const SizedBox(height: GoSpacing.s2),
                          ],
                          if (recent.isEmpty &&
                              inbound?.status != InboundKifuStatus.imported)
                            _EmptyKifuLibrary(dense: dense)
                          else
                            for (final entry in recent.take(
                              recentCount,
                            )) ...<Widget>[
                              _KifuTile(
                                dense: dense,
                                item: entry.item,
                                onTap: () {
                                  KifuWorkspace.of(
                                    context,
                                  ).select(entry.document);
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.routeForDocument(entry.document),
                                    arguments: entry.document,
                                  );
                                },
                              ),
                              const SizedBox(height: GoSpacing.s2),
                            ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  static _KifuSummary _summaryFor(
    BuildContext context,
    domain.KifuDocument document,
    AppLocalizations l10n,
  ) {
    final metadata = document.metadata;
    final (moves, status) = switch (document) {
      domain.VerifiedGameRecord(:final moves) => (
        moves.length,
        l10n.statusVerified,
      ),
      domain.PartialGameRecord(:final moves) => (
        moves.length,
        l10n.statusNeedsConfirmation,
      ),
      domain.PositionSnapshot() => (0, l10n.statusCurrentPosition),
    };
    final playedAt = metadata.playedAt;
    return _KifuSummary(
      blackPlayer: metadata.blackPlayer ?? l10n.blackPlayerFallback,
      whitePlayer: metadata.whitePlayer ?? l10n.whitePlayerFallback,
      result: switch (document) {
        domain.VerifiedGameRecord() => l10n.completeKifu,
        domain.PartialGameRecord() => l10n.partialKifu,
        domain.PositionSnapshot() => l10n.photoPosition,
      },
      // A persisted record is not necessarily newly imported. Only display a
      // date when the source actually supplied one instead of inventing a
      // relative timestamp.
      playedAt: playedAt == null
          ? null
          : MaterialLocalizations.of(
              context,
            ).formatCompactDate(playedAt.toLocal()),
      moveCount: moves,
      status: status,
    );
  }
}

class _InboundKifuNotice extends StatelessWidget {
  const _InboundKifuNotice({required this.controller, required this.onOpen});

  final InboundKifuController controller;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final imported = controller.status == InboundKifuStatus.imported;
    final fileName = controller.lastFileName ?? l10n.sharedKifuFallback;
    final textEncoding = controller.lastTextEncoding;
    final legacyEncoding =
        textEncoding != null && textEncoding != KifuTextEncoding.utf8
        ? l10n.legacyGibEncodingDetected(textEncoding.label)
        : null;
    final warningSummary = <String>[
      ?legacyEncoding,
      if (controller.warnings.isNotEmpty)
        l10n.warningCount(controller.warnings.length),
    ].join(' · ');
    final message = imported
        ? warningSummary.isEmpty
              ? l10n.inboundImported(fileName)
              : l10n.inboundImportedWithWarnings(fileName, warningSummary)
        : switch (controller.failureCode) {
            InboundKifuFailureCode.invalidFile => l10n.inboundInvalidFile,
            InboundKifuFailureCode.storage => l10n.inboundStorageFailure,
            InboundKifuFailureCode.platform ||
            null => l10n.inboundPlatformFailure,
          };
    final foreground = imported
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onErrorContainer;
    return SurfacePanel(
      padding: EdgeInsets.zero,
      color: imported
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.errorContainer,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              liveRegion: true,
              button: onOpen != null,
              label: onOpen == null ? message : l10n.inboundOpen(fileName),
              excludeSemantics: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpen,
                  borderRadius: BorderRadius.circular(GoRadii.card),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: GoSizes.comfortableTouchTarget,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GoSpacing.s3,
                        vertical: GoSpacing.s2,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            imported
                                ? Icons.check_circle_outline_rounded
                                : Icons.error_outline_rounded,
                            color: foreground,
                            size: 20,
                          ),
                          const SizedBox(width: GoSpacing.s2),
                          Expanded(
                            child: Text(
                              message,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: foreground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.dismissNotice,
            onPressed: controller.clearNotice,
            color: foreground,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _ScanHeroCard extends StatelessWidget {
  const _ScanHeroCard({required this.dense, required this.onTap});

  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = dense ? 44.0 : 48.0;
    return Semantics(
      button: true,
      label: context.l10n.photoScanSemantics,
      child: Material(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(GoRadii.large),
        child: InkWell(
          borderRadius: BorderRadius.circular(GoRadii.large),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(dense ? GoSpacing.s3 : GoSpacing.s4),
            child: Row(
              children: <Widget>[
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(GoRadii.card),
                  ),
                  child: Icon(
                    Icons.document_scanner_outlined,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: GoSpacing.s3),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.l10n.photoScanTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      Text(
                        context.l10n.photoScanSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.82,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyKifuLibrary extends StatelessWidget {
  const _EmptyKifuLibrary({required this.dense});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    return SurfacePanel(
      padding: EdgeInsets.all(dense ? GoSpacing.s3 : GoSpacing.s4),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.description_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: GoSpacing.s3),
          Expanded(
            child: Text(
              context.l10n.emptyKifuLibrary,
              maxLines: largeText ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: GoSpacing.s2),
          IconButton(
            tooltip: context.l10n.importFirstKifu,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.importKifu),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _KifuTile extends StatelessWidget {
  const _KifuTile({
    required this.dense,
    required this.item,
    required this.onTap,
  });

  final bool dense;
  final _KifuSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: context.l10n.kifuCardSemantics(
        item.blackPlayer,
        item.whitePlayer,
        item.result,
        context.l10n.moveCount(item.moveCount),
        item.status,
      ),
      child: SurfacePanel(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(GoRadii.card),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(dense ? GoSpacing.s3 : GoSpacing.s4),
            child: Row(
              children: <Widget>[
                _StoneAvatar(
                  black: true,
                  label: item.blackPlayer.characters.first,
                  size: dense ? 38 : 42,
                ),
                const SizedBox(width: GoSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.l10n.playerPair(
                          item.blackPlayer,
                          item.whitePlayer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: GoSpacing.s1),
                      Text(
                        item.playedAt == null
                            ? '${item.result} · ${context.l10n.moveCount(item.moveCount)}'
                            : context.l10n.kifuCardDetail(
                                item.result,
                                context.l10n.moveCount(item.moveCount),
                                item.playedAt!,
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GoSpacing.s2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      item.status,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: GoSpacing.s2),
                    const Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
final class _KifuSummary {
  const _KifuSummary({
    required this.blackPlayer,
    required this.whitePlayer,
    required this.result,
    required this.playedAt,
    required this.moveCount,
    required this.status,
  });

  final String blackPlayer;
  final String whitePlayer;
  final String result;
  final String? playedAt;
  final int moveCount;
  final String status;
}

class _StoneAvatar extends StatelessWidget {
  const _StoneAvatar({
    required this.black,
    required this.label,
    required this.size,
  });

  final bool black;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.goColors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: black ? colors.blackStone : colors.whiteStone,
          shape: BoxShape.circle,
          border: Border.all(color: colors.whiteStoneOutline),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: black ? colors.whiteStone : colors.blackStone,
          ),
        ),
      ),
    );
  }
}
