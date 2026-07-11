import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/kifu_export_scope.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/features/review/presentation/review_screen_data.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';
import '../../common/presentation/share_anchor.dart';

class PartialRecordScreen extends StatefulWidget {
  const PartialRecordScreen({super.key, this.record});

  final domain.PartialGameRecord? record;

  @override
  State<PartialRecordScreen> createState() => _PartialRecordScreenState();
}

class _PartialRecordScreenState extends State<PartialRecordScreen> {
  bool _saving = false;
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    if (record == null) {
      return Scaffold(
        body: Center(child: Text(context.l10n.partialRecordExpired)),
      );
    }
    final l10n = context.l10n;
    final validation = domain.GoRuleValidator.validate(
      initialPosition: record.initialPosition,
      moves: record.moves,
      rules: record.rules,
      firstPlayer: record.firstPlayer,
    );
    final validMoves = validation.positions.length - 1;
    final violation = validation.violations.firstOrNull;
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: l10n.partialKifu,
            subtitle: l10n.partialTrustBoundary,
            leading: const BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  GoSpacing.s4,
                  GoSpacing.s1,
                  GoSpacing.s4,
                  GoSpacing.s3,
                ),
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: GoBoard(
                            boardSize: record.boardSize.dimension,
                            stones: boardStones(validation.finalPosition),
                            semanticLabel: l10n.partialBoardSemantics(
                              validMoves,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: GoSpacing.s2),
                    SurfacePanel(
                      padding: const EdgeInsets.all(GoSpacing.s2),
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.rule_folder_outlined),
                          const SizedBox(width: GoSpacing.s2),
                          Expanded(
                            child: Text(
                              violation == null
                                  ? l10n.partialUnproven(
                                      record.startingMoveNumber,
                                    )
                                  : l10n.partialIllegalMove(
                                      violation.moveIndex +
                                          record.startingMoveNumber,
                                      _ruleViolationLabel(l10n, violation.code),
                                    ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: GoSpacing.s2),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Builder(
                            builder: (buttonContext) => OutlinedButton.icon(
                              onPressed: _sharing
                                  ? null
                                  : () => _shareOriginal(buttonContext),
                              icon: const Icon(Icons.ios_share_outlined),
                              label: Text(
                                _sharing
                                    ? l10n.preparing
                                    : l10n.exportOriginalRecord,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: GoSpacing.s2),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _savePosition,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(
                              _saving ? l10n.saving : l10n.saveCurrentPosition,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareOriginal(BuildContext buttonContext) async {
    final service = KifuExportScope.maybeOf(context);
    if (service == null) return;
    setState(() => _sharing = true);
    try {
      await service.share(
        widget.record!,
        anchor: resolveShareAnchor(buttonContext),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.shareUnavailable)));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _savePosition() async {
    final record = widget.record!;
    final validation = domain.GoRuleValidator.validate(
      initialPosition: record.initialPosition,
      moves: record.moves,
      rules: record.rules,
      firstPlayer: record.firstPlayer,
    );
    final snapshot = domain.PositionSnapshot(
      id: '${record.id}-position',
      position: validation.finalPosition,
      rules: record.rules,
      source: record.source,
      metadata: record.metadata,
      playerToMove: null,
    );
    setState(() => _saving = true);
    try {
      await KifuWorkspace.of(context).addPersisted(snapshot);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.root, (_) => false);
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.saveKifuFailed)));
      }
    }
  }
}

String _ruleViolationLabel(
  AppLocalizations l10n,
  domain.RuleViolationCode code,
) => switch (code) {
  domain.RuleViolationCode.wrongTurn => l10n.ruleViolationWrongTurn,
  domain.RuleViolationCode.outOfBounds => l10n.ruleViolationOutOfBounds,
  domain.RuleViolationCode.occupied => l10n.ruleViolationOccupied,
  domain.RuleViolationCode.suicide => l10n.ruleViolationSuicide,
  domain.RuleViolationCode.ko => l10n.ruleViolationKo,
};
