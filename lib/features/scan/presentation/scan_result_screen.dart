import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key, this.result});

  final ScanPositionPayload? result;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _saving = false;
  bool _startingAnalysis = false;
  domain.StoneColor? _playerToMove;

  @override
  void initState() {
    super.initState();
    _playerToMove = widget.result?.snapshot.playerToMove;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = widget.result;
    if (result == null) return const _MissingScanResult();
    final theme = Theme.of(context);
    final position = result.snapshot.position;
    final stones = <BoardStone>[
      for (final entry in position.stones.entries)
        BoardStone(
          point: BoardPoint(entry.key.column, entry.key.row),
          color: entry.value == domain.StoneColor.black
              ? StoneColor.black
              : StoneColor.white,
        ),
    ];
    final blackCount = position.count(domain.StoneColor.black);
    final whiteCount = position.count(domain.StoneColor.white);
    final dimension = position.size.dimension;
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: l10n.scanResultTitle,
            subtitle: l10n.scanResultSubtitle(l10n.boardDimension(dimension)),
            leading: const BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boardSide = math.min(
                    math.min(constraints.maxWidth, 520.0) - GoSpacing.s8,
                    math.max(160.0, constraints.maxHeight - 460.0),
                  );
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        key: const Key('scan-result-viewport'),
                        padding: const EdgeInsets.fromLTRB(
                          GoSpacing.s4,
                          GoSpacing.s1,
                          GoSpacing.s4,
                          GoSpacing.s3,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Center(
                              child: SizedBox.square(
                                dimension: boardSide,
                                child: GoBoard(
                                  boardSize: dimension,
                                  stones: stones,
                                  semanticLabel: l10n.scanResultBoardSemantics(
                                    dimension,
                                    blackCount,
                                    whiteCount,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: GoSpacing.s2),
                            SurfacePanel(
                              padding: const EdgeInsets.all(GoSpacing.s3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme
                                              .primaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 20,
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                      const SizedBox(width: GoSpacing.s2),
                                      Expanded(
                                        child: Text(
                                          l10n.boardRecognitionComplete,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ),
                                      Text(
                                        l10n.stoneCountsCompact(
                                          blackCount,
                                          whiteCount,
                                        ),
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: GoSpacing.s2),
                                  Text(
                                    l10n.recognizedPositionCounts(
                                      blackCount,
                                      whiteCount,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: GoSpacing.s1),
                                  Text(
                                    l10n.photoNoSequence,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: GoSpacing.s2),
                                  Row(
                                    children: <Widget>[
                                      Text(l10n.nextPlayerLabel),
                                      const SizedBox(width: GoSpacing.s2),
                                      Expanded(
                                        child: SegmentedButton<domain.StoneColor>(
                                          segments:
                                              <
                                                ButtonSegment<domain.StoneColor>
                                              >[
                                                ButtonSegment(
                                                  value:
                                                      domain.StoneColor.black,
                                                  label: Text(
                                                    l10n.blackPlayerFallback,
                                                  ),
                                                ),
                                                ButtonSegment(
                                                  value:
                                                      domain.StoneColor.white,
                                                  label: Text(
                                                    l10n.whitePlayerFallback,
                                                  ),
                                                ),
                                              ],
                                          selected: <domain.StoneColor>{
                                            ?_playerToMove,
                                          },
                                          emptySelectionAllowed: true,
                                          onSelectionChanged: (selection) =>
                                              setState(
                                                () => _playerToMove =
                                                    selection.firstOrNull,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: GoSpacing.s3),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: GoSpacing.s2,
                                      ),
                                    ),
                                    onPressed:
                                        _playerToMove == null ||
                                            _saving ||
                                            _startingAnalysis
                                        ? null
                                        : _saveAndAnalyze,
                                    icon: _startingAnalysis
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.analytics_outlined,
                                            size: 20,
                                          ),
                                    label: Text(
                                      _startingAnalysis
                                          ? l10n.saving
                                          : _playerToMove == null
                                          ? l10n.chooseNextPlayerFirst
                                          : l10n.analyzeCurrentPosition,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: GoSpacing.s2),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: GoSpacing.s2,
                                      ),
                                    ),
                                    onPressed: _saving || _startingAnalysis
                                        ? null
                                        : _save,
                                    icon: _saving
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.save_outlined,
                                            size: 20,
                                          ),
                                    label: Text(
                                      _saving ? l10n.saving : l10n.savePosition,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await KifuWorkspace.of(context).addPersisted(_snapshotForUse());
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.saveKifuFailed)));
    }
  }

  Future<void> _saveAndAnalyze() async {
    if (_playerToMove == null) return;
    setState(() => _startingAnalysis = true);
    try {
      final workspace = KifuWorkspace.of(context);
      final snapshot = _snapshotForUse();
      await workspace.addPersisted(snapshot);
      if (!mounted) return;
      final persisted = workspace.selected;
      Navigator.pushNamed(
        context,
        AppRoutes.analysisProgress,
        arguments: persisted is domain.PositionSnapshot ? persisted : snapshot,
      );
    } on Object {
      if (!mounted) return;
      setState(() => _startingAnalysis = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.savePositionAnalysisFailed)),
      );
    }
  }

  domain.PositionSnapshot _snapshotForUse() {
    final source = widget.result!.snapshot;
    return domain.PositionSnapshot(
      id: source.id,
      position: source.position,
      playerToMove: _playerToMove,
      rules: source.rules,
      source: source.source,
      metadata: source.metadata,
      sourceSgf: source.sourceSgf,
    );
  }
}

class _MissingScanResult extends StatelessWidget {
  const _MissingScanResult();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(GoSpacing.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: GoSpacing.s3),
              Text(
                context.l10n.scanResultExpired,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: GoSpacing.s2),
              Text(context.l10n.scanResultExpiredDetail),
              const SizedBox(height: GoSpacing.s4),
              FilledButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.root,
                  (_) => false,
                ),
                child: Text(context.l10n.returnToScan),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
