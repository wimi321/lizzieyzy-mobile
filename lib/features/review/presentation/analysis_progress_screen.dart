import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/analysis/analysis.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';
import 'review_screen_data.dart';

class AnalysisProgressScreen extends StatefulWidget {
  const AnalysisProgressScreen({super.key, this.document});

  final domain.KifuDocument? document;

  @override
  State<AnalysisProgressScreen> createState() => _AnalysisProgressScreenState();
}

class _AnalysisProgressScreenState extends State<AnalysisProgressScreen> {
  domain.KifuDocument? _resolvedDocument;
  domain.StoneColor? _snapshotPlayer;
  bool _snapshotChoiceSaving = false;
  String? _snapshotChoiceError;
  bool _remoteApproved = false;
  bool _startScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolvedDocument ??=
        widget.document ?? KifuWorkspace.maybeOf(context)?.notifier?.selected;
    final document = _resolvedDocument;
    if (document is domain.PositionSnapshot) {
      _snapshotPlayer ??= document.playerToMove;
    }
    _scheduleAutomaticStart();
  }

  void _scheduleAutomaticStart() {
    if (_startScheduled) return;
    if (_snapshotChoiceSaving) return;
    final document = _analysisDocument;
    final settings = AppSettingsScope.maybeOf(context)?.settings;
    final coordinator = AnalysisCoordinatorScope.maybeOf(context);
    if (document == null ||
        document is domain.PartialGameRecord ||
        settings == null ||
        coordinator == null ||
        settings.analysisService == null ||
        settings.confirmRemoteAnalysis ||
        coordinator.sessionForRequest(
              document: document,
              serviceProfile: settings.analysisService,
              settings: settings.analysisRequestSettings,
            ) !=
            null) {
      return;
    }
    _startScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScheduled = false;
      if (mounted) _startAnalysis();
    });
  }

  domain.KifuDocument? get _analysisDocument {
    final document = _resolvedDocument;
    if (document is! domain.PositionSnapshot || document.playerToMove != null) {
      return document;
    }
    final player = _snapshotPlayer;
    if (player == null) return null;
    return domain.PositionSnapshot(
      id: document.id,
      position: document.position,
      playerToMove: player,
      rules: document.rules,
      source: document.source,
      metadata: document.metadata,
      sourceSgf: document.sourceSgf,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final document = _resolvedDocument;
    if (document == null) {
      return _AnalysisMessage(
        icon: Icons.find_in_page_outlined,
        title: l10n.noAnalyzableKifu,
        detail: l10n.selectAnalyzableKifu,
      );
    }
    if (document is domain.PartialGameRecord) {
      return _AnalysisMessage(
        icon: Icons.rule_folder_outlined,
        title: l10n.kifuNeedsConfirmation,
        detail: l10n.completeBeforeAnalysis,
      );
    }
    if (document is domain.PositionSnapshot && _snapshotPlayer == null) {
      return _PlayerToMoveGate(
        errorText: _snapshotChoiceError,
        onSelected: _selectSnapshotPlayer,
      );
    }

    final settings = AppSettingsScope.of(context).settings;
    final coordinator = AnalysisCoordinatorScope.of(context);
    final analysisDocument = _analysisDocument!;
    final session = coordinator.sessionForRequest(
      document: analysisDocument,
      serviceProfile: settings.analysisService,
      settings: settings.analysisRequestSettings,
    );
    if (settings.analysisService == null && session == null) {
      return const _AnalysisConfigurationRequired();
    }
    if (settings.confirmRemoteAnalysis && !_remoteApproved && session == null) {
      return _RemoteConsent(
        endpointHost: settings.analysisService!.endpoint.host,
        document: analysisDocument,
        onApprove: () {
          setState(() => _remoteApproved = true);
          _startAnalysis();
        },
      );
    }
    if (session == null) {
      _scheduleAutomaticStart();
      return const _AnalysisStarting();
    }
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => _AnalysisSessionView(
        document: analysisDocument,
        session: session,
        onCancel: () => _confirmCancel(session),
        onRetry: () => session.retry(
          serviceProfile: settings.analysisService,
          settings: settings.analysisRequestSettings,
        ),
      ),
    );
  }

  void _startAnalysis() {
    final document = _analysisDocument;
    if (document == null) return;
    final settings = AppSettingsScope.of(context).settings;
    final profile = settings.analysisService;
    if (profile == null) return;
    AnalysisCoordinatorScope.of(context).start(
      document: document,
      serviceProfile: profile,
      settings: settings.analysisRequestSettings,
    );
    if (mounted) setState(() {});
  }

  Future<void> _selectSnapshotPlayer(domain.StoneColor color) async {
    if (_snapshotChoiceSaving) return;
    setState(() {
      _snapshotPlayer = color;
      _snapshotChoiceSaving = true;
      _snapshotChoiceError = null;
    });
    final resolved = _analysisDocument! as domain.PositionSnapshot;
    final workspace = KifuWorkspace.maybeOf(context)?.notifier;
    try {
      if (workspace != null &&
          workspace.documents.any((document) => document.id == resolved.id)) {
        await workspace.updatePersisted(resolved);
      }
      if (!mounted) return;
      setState(() {
        _resolvedDocument = resolved;
        _snapshotChoiceSaving = false;
      });
      _scheduleAutomaticStart();
    } on Object {
      if (!mounted) return;
      setState(() {
        _snapshotPlayer = null;
        _snapshotChoiceSaving = false;
        _snapshotChoiceError = context.l10n.savePlayerToMoveFailed;
      });
    }
  }

  Future<void> _confirmCancel(AnalysisSessionController session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.cancelAnalysisTitle),
        content: Text(context.l10n.cancelAnalysisBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.continueAnalysis),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.cancelAction),
          ),
        ],
      ),
    );
    if (confirmed == true) await session.cancel();
  }
}

class _AnalysisSessionView extends StatelessWidget {
  const _AnalysisSessionView({
    required this.document,
    required this.session,
    required this.onCancel,
    required this.onRetry,
  });

  final domain.KifuDocument document;
  final AnalysisSessionController session;
  final VoidCallback onCancel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final state = session.state;
    final position = _positionFor(document, state.latestAnalysis?.moveNumber);
    final stones = boardStones(position);
    final l10n = context.l10n;
    final title = _documentTitle(document, l10n);
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    final extraLargeText = MediaQuery.textScalerOf(context).scale(1) >= 2.5;
    return Scaffold(
      body: Column(
        children: <Widget>[
          if (extraLargeText && state.status == AnalysisSessionStatus.queued)
            const SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  GoSpacing.s4,
                  GoSpacing.s2,
                  GoSpacing.s2,
                  GoSpacing.s1,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: BackCircleButton(),
                ),
              ),
            )
          else
            FeatureTopBar(
              title: l10n.analyzeKifuTitle,
              subtitle: title,
              leading: const BackCircleButton(),
            ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final reserved =
                      extraLargeText &&
                          state.status == AnalysisSessionStatus.queued
                      ? 268.0
                      : largeText
                      ? 252.0
                      : 236.0;
                  final side = math.min<double>(
                    constraints.maxWidth - GoSpacing.s6,
                    math.max<double>(120, constraints.maxHeight - reserved),
                  );
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      GoSpacing.s3,
                      GoSpacing.s1,
                      GoSpacing.s3,
                      GoSpacing.s2,
                    ),
                    child: Column(
                      children: <Widget>[
                        SizedBox.square(
                          dimension: side,
                          child: GoBoard(
                            boardSize: document.boardSize.dimension,
                            stones: stones,
                            lastMove: _lastMove(document, state),
                            semanticLabel: _boardSemanticLabel(
                              document,
                              state,
                              l10n,
                            ),
                          ),
                        ),
                        const SizedBox(height: GoSpacing.s2),
                        Expanded(
                          child: _SessionPanel(
                            document: document,
                            state: state,
                            onCancel: onCancel,
                            onRetry: onRetry,
                            extraLargeText: extraLargeText,
                          ),
                        ),
                      ],
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
}

class _SessionPanel extends StatelessWidget {
  const _SessionPanel({
    required this.document,
    required this.state,
    required this.onCancel,
    required this.onRetry,
    required this.extraLargeText,
  });

  final domain.KifuDocument document;
  final AnalysisSessionState state;
  final VoidCallback onCancel;
  final Future<void> Function() onRetry;
  final bool extraLargeText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final progress = state.progress;
    final completed = state.completedPositions;
    final total = state.totalPositions;
    final (title, detail, tone) = switch (state.status) {
      AnalysisSessionStatus.queued => (
        l10n.analysisQueuedTitle,
        l10n.analysisQueuePosition(state.queuePosition ?? 1),
        MetricTone.gold,
      ),
      AnalysisSessionStatus.running => (
        l10n.globalAnalysisRunning,
        total == 0
            ? l10n.connectingAnalysisService
            : l10n.analyzedPositionProgress(completed, total),
        MetricTone.primary,
      ),
      AnalysisSessionStatus.completed => (
        document is domain.VerifiedGameRecord
            ? l10n.reviewGenerated
            : l10n.positionAnalysisComplete,
        l10n.analyzedPositionsWithModel(
          completed,
          state.bundle!.model.displayName,
        ),
        MetricTone.positive,
      ),
      AnalysisSessionStatus.failed => (
        l10n.analysisFailed,
        _analysisFailureMessage(l10n, state.failure?.code),
        MetricTone.negative,
      ),
      AnalysisSessionStatus.cancelled => (
        l10n.analysisCancelled,
        completed == 0
            ? l10n.incompleteResultsDiscarded
            : l10n.completedPositions(completed),
        MetricTone.gold,
      ),
      AnalysisSessionStatus.configurationRequired => (
        l10n.analysisServiceRequired,
        l10n.addWssServiceRetry,
        MetricTone.gold,
      ),
    };
    final continuation = state.status == AnalysisSessionStatus.running
        ? ', ${l10n.analysisContinuesInApp}'
        : '';
    final queuePosition = state.queuePosition ?? 1;
    final visibleTitle =
        state.status == AnalysisSessionStatus.queued && extraLargeText
        ? l10n.statusQueued
        : title;
    final visibleDetail =
        state.status == AnalysisSessionStatus.queued && extraLargeText
        ? l10n.analysisQueuePositionCompact(queuePosition)
        : detail;
    return Semantics(
      liveRegion: true,
      label: '$title，$detail$continuation',
      child: SurfacePanel(
        key: state.status == AnalysisSessionStatus.queued
            ? const Key('analysis-queue-content')
            : null,
        padding: EdgeInsets.all(extraLargeText ? GoSpacing.s2 : GoSpacing.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (extraLargeText)
              state.status == AnalysisSessionStatus.queued
                  ? Text(visibleTitle, style: theme.textTheme.titleMedium)
                  : Text(
                      visibleTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    )
            else
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                  MetricPill(
                    label: _statusLabel(state.status, l10n),
                    tone: tone,
                  ),
                ],
              ),
            const SizedBox(height: GoSpacing.s1),
            if (state.status == AnalysisSessionStatus.running)
              LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                semanticsLabel: l10n.analysisProgressLabel,
                semanticsValue: progress == null
                    ? null
                    : '${(progress * 100).round()}',
              ),
            const SizedBox(height: GoSpacing.s1),
            state.status == AnalysisSessionStatus.queued
                ? Text(visibleDetail, style: theme.textTheme.bodySmall)
                : Text(
                    visibleDetail,
                    maxLines: extraLargeText ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
            const Spacer(),
            if (state.canCancel)
              extraLargeText
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Semantics(
                        button: true,
                        label: state.status == AnalysisSessionStatus.queued
                            ? l10n.cancelQueuedAnalysisSemantics
                            : l10n.cancelAnalysisSemantics,
                        excludeSemantics: true,
                        child: state.status == AnalysisSessionStatus.queued
                            ? IconButton(
                                onPressed: onCancel,
                                tooltip: l10n.cancelAction,
                                icon: const Icon(Icons.close_rounded),
                              )
                            : TextButton.icon(
                                onPressed: onCancel,
                                icon: const Icon(Icons.close_rounded),
                                label: Text(l10n.cancelAction),
                              ),
                      ),
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            state.status == AnalysisSessionStatus.queued
                                ? l10n.analysisQueuePosition(
                                    state.queuePosition ?? 1,
                                  )
                                : l10n.analysisContinuesInApp,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.close_rounded),
                          label: Text(l10n.cancelAction),
                        ),
                      ],
                    )
            else if (state.status == AnalysisSessionStatus.completed)
              FilledButton.icon(
                onPressed: () => _openCompleted(context, document, state),
                icon: const Icon(Icons.analytics_outlined),
                label: Text(
                  document is domain.VerifiedGameRecord
                      ? extraLargeText
                            ? l10n.openReview
                            : l10n.openKeyMoveReview
                      : extraLargeText
                      ? l10n.viewCandidates
                      : l10n.viewPositionCandidates,
                ),
              )
            else
              FilledButton.icon(
                onPressed: state.canRetry ? onRetry : null,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.reanalyze),
              ),
          ],
        ),
      ),
    );
  }

  void _openCompleted(
    BuildContext context,
    domain.KifuDocument document,
    AnalysisSessionState state,
  ) {
    final bundle = state.bundle!;
    if (document is domain.VerifiedGameRecord) {
      final report = state.reviewReport;
      if (report == null) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.keyMoveReview,
        arguments: ReviewScreenData(
          record: document,
          analysis: bundle,
          report: report,
          performanceReport: state.performanceReport,
        ),
      );
      return;
    }
    if (document is domain.PositionSnapshot) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.positionAnalysis,
        arguments: PositionAnalysisData(snapshot: document, analysis: bundle),
      );
    }
  }
}

class _RemoteConsent extends StatelessWidget {
  const _RemoteConsent({
    required this.endpointHost,
    required this.document,
    required this.onApprove,
  });

  final String endpointHost;
  final domain.KifuDocument document;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _AnalysisGate(
      icon: Icons.cloud_upload_outlined,
      title: l10n.sendBeforeConfirm,
      detail: document is domain.PositionSnapshot
          ? l10n.sendPositionToHost(endpointHost)
          : l10n.sendRecordToHost(endpointHost),
      primaryLabel: l10n.confirmAndStart,
      onPrimary: onApprove,
      secondaryLabel: l10n.viewPrivacyBoundary,
      onSecondary: () =>
          Navigator.pushNamed(context, AppRoutes.privacySettings),
    );
  }
}

class _AnalysisConfigurationRequired extends StatelessWidget {
  const _AnalysisConfigurationRequired();

  @override
  Widget build(BuildContext context) => _AnalysisGate(
    icon: Icons.dns_outlined,
    title: context.l10n.katagoUnconfigured,
    detail: context.l10n.katagoConfigDetail,
    primaryLabel: context.l10n.configureAnalysisService,
    onPrimary: () =>
        Navigator.pushNamed(context, AppRoutes.analysisServiceSettings),
  );
}

class _PlayerToMoveGate extends StatelessWidget {
  const _PlayerToMoveGate({required this.onSelected, this.errorText});

  final ValueChanged<domain.StoneColor> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) => _AnalysisGate(
    icon: Icons.radio_button_checked_rounded,
    title: context.l10n.nextPlayerQuestion,
    detail: errorText ?? context.l10n.photoNoTimingPlayerDetail,
    customAction: SegmentedButton<domain.StoneColor>(
      segments: <ButtonSegment<domain.StoneColor>>[
        ButtonSegment(
          value: domain.StoneColor.black,
          label: Text(context.l10n.blackPlayerFallback),
        ),
        ButtonSegment(
          value: domain.StoneColor.white,
          label: Text(context.l10n.whitePlayerFallback),
        ),
      ],
      selected: const <domain.StoneColor>{},
      emptySelectionAllowed: true,
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) onSelected(selection.single);
      },
    ),
  );
}

class _AnalysisStarting extends StatelessWidget {
  const _AnalysisStarting();

  @override
  Widget build(BuildContext context) => _AnalysisGate(
    icon: Icons.pending_rounded,
    title: context.l10n.creatingAnalysisTask,
    detail: context.l10n.validatingConfigKifu,
    customAction: const LinearProgressIndicator(),
  );
}

class _AnalysisGate extends StatelessWidget {
  const _AnalysisGate({
    required this.icon,
    required this.title,
    required this.detail,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.customAction,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Widget? customAction;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        FeatureTopBar(
          title: context.l10n.analyzeKifuTitle,
          subtitle: context.l10n.analysisDataDestinationSubtitle,
          leading: const BackCircleButton(),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(GoSpacing.s4),
                  child: SurfacePanel(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          icon,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: GoSpacing.s3),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: GoSpacing.s2),
                        Text(
                          detail,
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: GoSpacing.s4),
                        ?customAction,
                        if (primaryLabel case final label?)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: onPrimary,
                              child: Text(label),
                            ),
                          ),
                        if (secondaryLabel case final label?)
                          TextButton(
                            onPressed: onSecondary,
                            child: Text(label),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AnalysisMessage extends StatelessWidget {
  const _AnalysisMessage({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => _AnalysisGate(
    icon: icon,
    title: title,
    detail: detail,
    primaryLabel: context.l10n.returnToKifu,
    onPrimary: () => Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.root,
      (_) => false,
    ),
  );
}

domain.BoardPosition _positionFor(
  domain.KifuDocument document,
  int? moveNumber,
) => switch (document) {
  domain.PositionSnapshot(:final position) => position,
  domain.VerifiedGameRecord() => domain.GameReplayTimeline.fromRecord(
    document,
  ).positionAt((moveNumber ?? 0).clamp(0, document.moves.length)),
  domain.PartialGameRecord(:final initialPosition) => initialPosition,
};

BoardPoint? _lastMove(
  domain.KifuDocument document,
  AnalysisSessionState state,
) {
  if (document is! domain.VerifiedGameRecord) return null;
  final number = state.latestAnalysis?.moveNumber ?? 0;
  if (number < 1 || number > document.moves.length) return null;
  final point = document.moves[number - 1].point;
  return point == null ? null : BoardPoint(point.column, point.row);
}

String _documentTitle(domain.KifuDocument document, AppLocalizations l10n) {
  final black = document.metadata.blackPlayer ?? l10n.blackPlayerFallback;
  final white = document.metadata.whitePlayer ?? l10n.whitePlayerFallback;
  return document is domain.PositionSnapshot
      ? l10n.statusCurrentPosition
      : l10n.playerVersus(black, white);
}

String _boardSemanticLabel(
  domain.KifuDocument document,
  AnalysisSessionState state,
  AppLocalizations l10n,
) {
  if (document is domain.PositionSnapshot) return l10n.analyzingPositionBoard;
  return l10n.analyzingRecordBoard(
    document.boardSize.dimension,
    state.completedPositions,
  );
}

String _statusLabel(AnalysisSessionStatus status, AppLocalizations l10n) =>
    switch (status) {
      AnalysisSessionStatus.configurationRequired =>
        l10n.statusNeedsConfiguration,
      AnalysisSessionStatus.queued => l10n.statusQueued,
      AnalysisSessionStatus.running => l10n.analysisRunning,
      AnalysisSessionStatus.completed => l10n.analysisCompleted,
      AnalysisSessionStatus.failed => l10n.statusFailed,
      AnalysisSessionStatus.cancelled => l10n.statusCancelled,
    };

String _analysisFailureMessage(AppLocalizations l10n, String? code) =>
    switch (code) {
      'cancel_failed' => l10n.analysisFailureCancel,
      'provider_creation_failed' => l10n.analysisFailureProviderCreation,
      'invalid_analysis_result' => l10n.analysisFailureInvalidResult,
      'provider_error' => l10n.analysisFailureProvider,
      'stream_ended' => l10n.analysisFailureStreamEnded,
      _ => l10n.analysisFailureRemote,
    };
