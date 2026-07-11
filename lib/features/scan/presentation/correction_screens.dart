import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/infrastructure/kifu/kifu.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';

enum _CorrectionChoice { black, white, empty, uncertain }

enum _SequenceIssueKind {
  noFirst,
  missing,
  ocr,
  color,
  finalMismatch,
  tooMany,
  duplicate,
  illegal,
  failed,
}

class PhysicalBoardCorrectionScreen extends StatefulWidget {
  const PhysicalBoardCorrectionScreen({super.key, this.capture});

  final ScanCapturePayload? capture;

  @override
  State<PhysicalBoardCorrectionScreen> createState() =>
      _PhysicalBoardCorrectionScreenState();
}

class _PhysicalBoardCorrectionScreenState
    extends State<PhysicalBoardCorrectionScreen> {
  _CorrectionChoice _selected = _CorrectionChoice.black;
  final Map<domain.BoardPoint, domain.StoneColor> _stones =
      <domain.BoardPoint, domain.StoneColor>{};
  final Set<domain.BoardPoint> _pending = <domain.BoardPoint>{};
  domain.BoardPoint? _selectedPoint;

  @override
  void initState() {
    super.initState();
    final draft = widget.capture?.draft;
    if (draft == null) return;
    _stones.addAll(_stonesFromDraft(draft));
    final byPoint = <domain.BoardPoint, domain.IntersectionPrediction>{
      for (final prediction in draft.intersections)
        prediction.point: prediction,
    };
    for (var row = 0; row < draft.boardSize.dimension; row++) {
      for (var column = 0; column < draft.boardSize.dimension; column++) {
        final point = domain.BoardPoint(column, row);
        final prediction = byPoint[point];
        if (prediction == null || prediction.confidence < 0.9) {
          _pending.add(point);
        }
      }
    }
    _selectedPoint = _pending.firstOrNull;
  }

  int get _blackCount =>
      _stones.values.where((stone) => stone == domain.StoneColor.black).length;
  int get _whiteCount =>
      _stones.values.where((stone) => stone == domain.StoneColor.white).length;

  @override
  Widget build(BuildContext context) {
    final capture = widget.capture;
    if (capture == null) {
      return _MissingCorrectionData(title: context.l10n.boardCorrectionExpired);
    }
    final l10n = context.l10n;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: l10n.correctBoardTitle,
            subtitle: l10n.autoRectifiedSubtitle(
              l10n.boardDimension(capture.draft.boardSize.dimension),
            ),
            leading: const BackCircleButton(),
            actions: <Widget>[
              IconButton(
                tooltip: l10n.viewOriginal,
                onPressed: _showOriginal,
                icon: const Icon(Icons.image_outlined),
              ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final reserved = largeText ? 250.0 : 220.0;
                  final side = math.min<double>(
                    math.min(constraints.maxWidth, 560) - GoSpacing.s8,
                    math.max<double>(128, constraints.maxHeight - reserved),
                  );
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        key: const Key('board-correction-viewport'),
                        padding: const EdgeInsets.fromLTRB(
                          GoSpacing.s4,
                          GoSpacing.s1,
                          GoSpacing.s4,
                          GoSpacing.s2,
                        ),
                        child: Column(
                          children: <Widget>[
                            SizedBox.square(
                              dimension: side,
                              child: GoBoard(
                                boardSize: capture.draft.boardSize.dimension,
                                stones: _uiStones(_stones),
                                candidates: <BoardCandidate>[
                                  for (final point in _pending.take(12))
                                    BoardCandidate(
                                      point: _uiPoint(point),
                                      label: '?',
                                      detail: l10n.pendingLabel,
                                      tone: CandidateTone.tertiary,
                                    ),
                                ],
                                selectedPoint: _selectedPoint == null
                                    ? null
                                    : _uiPoint(_selectedPoint!),
                                onIntersectionTap: _selectPoint,
                                semanticLabel: l10n.boardCorrectionSemantics(
                                  _blackCount,
                                  _whiteCount,
                                  _pending.length,
                                ),
                              ),
                            ),
                            const SizedBox(height: GoSpacing.s1),
                            Semantics(
                              container: true,
                              explicitChildNodes: true,
                              liveRegion: true,
                              label:
                                  '${l10n.stoneCounts(_blackCount, _whiteCount)}, '
                                  '${l10n.pendingConfirmation(_pending.length)}'
                                  '${_selectedPoint == null ? '' : ', ${l10n.intersectionCoordinate(_selectedPoint!.toGtp(capture.draft.boardSize))}'}',
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      l10n.stoneCountsCompact(
                                        _blackCount,
                                        _whiteCount,
                                      ),
                                    ),
                                  ),
                                  MetricPill(
                                    label: l10n.pendingLabel,
                                    value: '${_pending.length}',
                                    tone: _pending.isEmpty
                                        ? MetricTone.positive
                                        : MetricTone.negative,
                                    compact: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: GoSpacing.s1),
                            SurfacePanel(
                              padding: const EdgeInsets.all(GoSpacing.s1),
                              child: Row(
                                children: <Widget>[
                                  for (final choice in _CorrectionChoice.values)
                                    Expanded(
                                      child: _CorrectionChoiceButton(
                                        choice: choice,
                                        selected: choice == _selected,
                                        onTap: () => _applyChoice(choice),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _pending.isEmpty ? _finish : null,
                                icon: const Icon(Icons.check_rounded),
                                label: Text(
                                  _pending.isEmpty
                                      ? l10n.confirmCurrentPosition
                                      : l10n.confirmRemaining(_pending.length),
                                ),
                              ),
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

  void _selectPoint(BoardPoint point) {
    final selected = domain.BoardPoint(point.x, point.y);
    setState(() {
      _selectedPoint = selected;
      _selected = switch (_stones[selected]) {
        domain.StoneColor.black => _CorrectionChoice.black,
        domain.StoneColor.white => _CorrectionChoice.white,
        null => _CorrectionChoice.empty,
      };
    });
  }

  void _applyChoice(_CorrectionChoice choice) {
    final point = _selectedPoint;
    if (point == null) return;
    setState(() {
      _selected = choice;
      switch (choice) {
        case _CorrectionChoice.black:
          _stones[point] = domain.StoneColor.black;
          _pending.remove(point);
        case _CorrectionChoice.white:
          _stones[point] = domain.StoneColor.white;
          _pending.remove(point);
        case _CorrectionChoice.empty:
          _stones.remove(point);
          _pending.remove(point);
        case _CorrectionChoice.uncertain:
          _pending.add(point);
      }
      _selectedPoint = _pending.firstOrNull ?? point;
      _selected = switch (_stones[_selectedPoint]) {
        domain.StoneColor.black => _CorrectionChoice.black,
        domain.StoneColor.white => _CorrectionChoice.white,
        null => _CorrectionChoice.empty,
      };
    });
  }

  void _finish() {
    final capture = widget.capture!;
    if (_pending.isNotEmpty) return;
    final snapshot = domain.PositionSnapshot(
      id: _scanDocumentId(capture, 'position'),
      position: domain.BoardPosition(
        size: capture.draft.boardSize,
        stones: _stones,
      ),
      rules: const domain.GoRules.chinese(),
      source: _scanSource(capture),
    );
    Navigator.pushNamed(
      context,
      AppRoutes.scanResult,
      arguments: ScanPositionPayload(
        snapshot: snapshot,
        originalFrame: capture.originalFrame,
        draft: capture.draft,
      ),
    );
  }

  Future<void> _showOriginal() =>
      _showOriginalFrame(context, widget.capture!.originalFrame);
}

class NumberedKifuCorrectionScreen extends StatefulWidget {
  const NumberedKifuCorrectionScreen({
    super.key,
    this.capture,
    this.solver = const RuleCheckedSequenceSolver(),
  });

  final ScanCapturePayload? capture;
  final domain.SequenceSolver solver;

  @override
  State<NumberedKifuCorrectionScreen> createState() =>
      _NumberedKifuCorrectionScreenState();
}

class _NumberedKifuCorrectionScreenState
    extends State<NumberedKifuCorrectionScreen> {
  final Map<int, domain.SequenceToken> _tokens = <int, domain.SequenceToken>{};
  domain.BoardPoint? _selectedPoint;
  int? _issueNumber;
  _SequenceIssueKind? _issueKind;
  bool _reuseSamePoint = false;
  bool _validating = false;
  bool _saving = false;
  domain.VerifiedGameRecord? _verified;

  @override
  void initState() {
    super.initState();
    final capture = widget.capture;
    if (capture == null) return;
    for (final token in capture.draft.sequenceTokens) {
      _tokens[token.moveNumber] = token;
    }
    _setNextIssue();
    if (_issueNumber == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _validateSequence());
    }
  }

  @override
  Widget build(BuildContext context) {
    final capture = widget.capture;
    if (capture == null) {
      return _MissingCorrectionData(
        title: context.l10n.sequenceCorrectionExpired,
      );
    }
    final l10n = context.l10n;
    if (_verified case final record?) {
      return _NumberedVerifiedView(
        record: record,
        saving: _saving,
        onContinue: _saveAndAnalyze,
      );
    }
    final finalStones = _stonesFromDraft(capture.draft);
    final issue = _issueNumber;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    final numberedStones = _numberedStones(finalStones);
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: l10n.correctSequenceTitle,
            subtitle: l10n.numberedDetectedMoves(_tokens.length),
            leading: const BackCircleButton(),
            actions: <Widget>[
              IconButton(
                tooltip: l10n.viewOriginal,
                onPressed: () =>
                    _showOriginalFrame(context, capture.originalFrame),
                icon: const Icon(Icons.image_outlined),
              ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final reserved = largeText ? 330.0 : 306.0;
                  final side = math.min<double>(
                    math.min(constraints.maxWidth, 520) - GoSpacing.s8,
                    math.max<double>(120, constraints.maxHeight - reserved),
                  );
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        key: const Key('numbered-correction-viewport'),
                        padding: const EdgeInsets.fromLTRB(
                          GoSpacing.s4,
                          GoSpacing.s1,
                          GoSpacing.s4,
                          GoSpacing.s2,
                        ),
                        child: Column(
                          children: <Widget>[
                            SizedBox.square(
                              dimension: side,
                              child: GoBoard(
                                boardSize: capture.draft.boardSize.dimension,
                                stones: numberedStones,
                                selectedPoint: _selectedPoint == null
                                    ? null
                                    : _uiPoint(_selectedPoint!),
                                onIntersectionTap: (point) => setState(
                                  () => _selectedPoint = domain.BoardPoint(
                                    point.x,
                                    point.y,
                                  ),
                                ),
                                semanticLabel: issue == null
                                    ? l10n.sequenceValidatingSemantics
                                    : l10n.sequenceIssueSemantics(issue),
                              ),
                            ),
                            const SizedBox(height: GoSpacing.s1),
                            _SequenceIssuePanel(
                              moveNumber: issue,
                              detail: _sequenceIssueDetail(l10n, _issueKind),
                              validating: _validating,
                            ),
                            const SizedBox(height: GoSpacing.s1),
                            if (issue != null) ...<Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: ChoiceChip(
                                      selected: _reuseSamePoint,
                                      avatar: const Icon(
                                        Icons.undo_rounded,
                                        size: 18,
                                      ),
                                      label: SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          l10n.reuseAfterCapture,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      onSelected: (value) => setState(
                                        () => _reuseSamePoint = value,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: GoSpacing.s1),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _assignIssue(pass: true),
                                      child: Text(l10n.markPassMove),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: GoSpacing.s1),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _selectedPoint == null
                                      ? null
                                      : () => _assignIssue(pass: false),
                                  child: Text(
                                    _selectedPoint == null
                                        ? l10n.selectMoveOnBoard(issue)
                                        : l10n.confirmMoveAt(
                                            issue,
                                            _selectedPoint!.toGtp(
                                              capture.draft.boardSize,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            TextButton(
                              onPressed: _saveAsPosition,
                              child: Text(l10n.saveAsPositionFallback),
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

  List<BoardStone> _numberedStones(
    Map<domain.BoardPoint, domain.StoneColor> finalStones,
  ) {
    final latestAtPoint = <domain.BoardPoint, int>{};
    for (final token in _tokens.values) {
      final point = token.move.point;
      if (point != null &&
          (latestAtPoint[point] == null ||
              token.moveNumber > latestAtPoint[point]!)) {
        latestAtPoint[point] = token.moveNumber;
      }
    }
    return <BoardStone>[
      for (final entry in finalStones.entries)
        BoardStone(
          point: _uiPoint(entry.key),
          color: entry.value == domain.StoneColor.black
              ? StoneColor.black
              : StoneColor.white,
          moveNumber: latestAtPoint[entry.key],
        ),
    ];
  }

  void _setNextIssue() {
    if (_tokens.isEmpty) {
      _issueNumber = 1;
      _issueKind = _SequenceIssueKind.noFirst;
      return;
    }
    final maximum = _tokens.keys.reduce(math.max);
    for (var number = 1; number <= maximum; number++) {
      final token = _tokens[number];
      final expectedColor = number.isOdd
          ? domain.StoneColor.black
          : domain.StoneColor.white;
      if (token == null) {
        _issueNumber = number;
        _issueKind = _SequenceIssueKind.missing;
        _selectedPoint = null;
        return;
      }
      if (token.confidence < 0.9 || token.move.color != expectedColor) {
        _issueNumber = number;
        _issueKind = token.confidence < 0.9
            ? _SequenceIssueKind.ocr
            : _SequenceIssueKind.color;
        _selectedPoint = token.move.point;
        return;
      }
    }
    _issueNumber = null;
    _issueKind = null;
  }

  void _assignIssue({required bool pass}) {
    final number = _issueNumber;
    if (number == null || (!pass && _selectedPoint == null)) return;
    final color = number.isOdd
        ? domain.StoneColor.black
        : domain.StoneColor.white;
    final selectedPoint = _selectedPoint;
    if (!pass && !_reuseSamePoint) {
      _tokens.removeWhere(
        (otherNumber, token) =>
            otherNumber != number && token.move.point == selectedPoint,
      );
    }
    _tokens[number] = domain.SequenceToken(
      moveNumber: number,
      move: pass
          ? domain.Move.pass(color: color)
          : domain.Move.play(color: color, point: selectedPoint!),
      confidence: 1,
    );
    setState(() {
      _reuseSamePoint = false;
      _setNextIssue();
    });
    if (_issueNumber == null) _validateSequence();
  }

  Future<void> _validateSequence() async {
    if (_validating || widget.capture == null) return;
    setState(() => _validating = true);
    final capture = widget.capture!;
    try {
      final document = await widget.solver.solve(
        _tokens.values.toList(growable: false),
        const domain.GoRules.chinese(),
        documentId: _scanDocumentId(capture, 'numbered'),
        boardSize: capture.draft.boardSize,
        source: _scanSource(capture),
      );
      if (document is! domain.VerifiedGameRecord) {
        throw const SequenceSolveException(
          SequenceSolveErrorCode.illegalSequence,
          'Sequence solver did not produce a verified record.',
        );
      }
      final recognizedFinal = domain.BoardPosition(
        size: capture.draft.boardSize,
        stones: _stonesFromDraft(capture.draft),
      );
      if (document.finalPosition != recognizedFinal) {
        final mismatch = _firstMismatch(
          document.finalPosition,
          recognizedFinal,
        );
        final related = _tokens.values
            .where((token) => token.move.point == mismatch)
            .map((token) => token.moveNumber)
            .fold<int?>(
              null,
              (value, number) =>
                  value == null ? number : math.max(value, number),
            );
        if (!mounted) return;
        setState(() {
          _issueNumber = related ?? _tokens.keys.reduce(math.max);
          _issueKind = _SequenceIssueKind.finalMismatch;
          _selectedPoint = _tokens[_issueNumber]?.move.point;
        });
        return;
      }
      if (!mounted) return;
      setState(() => _verified = document);
    } on SequenceSolveException catch (error) {
      if (!mounted) return;
      setState(() {
        _issueNumber = error.moveNumber ?? 1;
        _issueKind = _sequenceIssueKind(error.code);
        _selectedPoint = _tokens[_issueNumber]?.move.point;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _issueNumber ??= 1;
        _issueKind = _SequenceIssueKind.failed;
      });
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  Future<void> _saveAndAnalyze() async {
    if (_saving || _verified == null) return;
    setState(() => _saving = true);
    try {
      await KifuWorkspace.of(context).addPersisted(_verified!);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.analysisProgress,
        arguments: _verified,
      );
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.saveKifuFailed)));
      }
    }
  }

  void _saveAsPosition() {
    final capture = widget.capture!;
    final snapshot = domain.PositionSnapshot(
      id: _scanDocumentId(capture, 'position'),
      position: domain.BoardPosition(
        size: capture.draft.boardSize,
        stones: _stonesFromDraft(capture.draft),
      ),
      rules: const domain.GoRules.chinese(),
      source: _scanSource(capture),
    );
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.scanResult,
      arguments: ScanPositionPayload(
        snapshot: snapshot,
        originalFrame: capture.originalFrame,
        draft: capture.draft,
      ),
    );
  }
}

class _SequenceIssuePanel extends StatelessWidget {
  const _SequenceIssuePanel({
    required this.moveNumber,
    required this.detail,
    required this.validating,
  });

  final int? moveNumber;
  final String? detail;
  final bool validating;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: validating
        ? '${context.l10n.validatingGoRules}, '
              '${detail ?? context.l10n.checkingSequenceRules}'
        : '${context.l10n.moveCannotConfirm(moveNumber?.toString() ?? '—')}, '
              '${detail ?? context.l10n.sequenceValidationFailed}',
    excludeSemantics: true,
    child: SurfacePanel(
      padding: const EdgeInsets.all(GoSpacing.s2),
      color: validating
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: <Widget>[
          if (validating)
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.warning_amber_rounded),
          const SizedBox(width: GoSpacing.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  validating
                      ? context.l10n.validatingGoRules
                      : context.l10n.moveCannotConfirm(
                          moveNumber?.toString() ?? '—',
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  detail ?? context.l10n.checkingSequenceRules,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _NumberedVerifiedView extends StatelessWidget {
  const _NumberedVerifiedView({
    required this.record,
    required this.saving,
    required this.onContinue,
  });

  final domain.VerifiedGameRecord record;
  final bool saving;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        FeatureTopBar(
          title: context.l10n.sequenceVerifiedTitle,
          subtitle: context.l10n.sequenceVerifiedSubtitle,
          leading: const BackCircleButton(),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(GoSpacing.s4),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GoBoard(
                          boardSize: record.boardSize.dimension,
                          stones: _uiStones(record.finalPosition.stones),
                          semanticLabel: context.l10n.verifiedRecordSemantics(
                            record.boardSize.dimension,
                            record.moves.length,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: GoSpacing.s3),
                  MetricPill(
                    label: context.l10n.completeKifu,
                    value: context.l10n.moveCount(record.moves.length),
                    tone: MetricTone.positive,
                    icon: Icons.verified_outlined,
                  ),
                  const SizedBox(height: GoSpacing.s3),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: saving ? null : onContinue,
                      icon: saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.analytics_outlined),
                      label: Text(
                        saving
                            ? context.l10n.saving
                            : context.l10n.saveAndStartReview,
                      ),
                    ),
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

class _CorrectionChoiceButton extends StatelessWidget {
  const _CorrectionChoiceButton({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _CorrectionChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _correctionChoiceLabel(context.l10n, choice);
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.markStone(label),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GoRadii.small),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(GoRadii.small),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(switch (choice) {
                _CorrectionChoice.black => Icons.circle,
                _CorrectionChoice.white => Icons.circle_outlined,
                _CorrectionChoice.empty => Icons.close_rounded,
                _CorrectionChoice.uncertain => Icons.help_outline_rounded,
              }, size: 19),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingCorrectionData extends StatelessWidget {
  const _MissingCorrectionData({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.root,
          (_) => false,
        ),
        child: Text(context.l10n.rescanWithReason(title)),
      ),
    ),
  );
}

Future<void> _showOriginalFrame(
  BuildContext context,
  domain.CapturedFrame frame,
) => showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: 520,
      height: math.min(560, MediaQuery.sizeOf(context).height - 96),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ColoredBox(
              color: GoPrimitiveColors.night,
              child: Image.memory(
                frame.encodedBytes,
                fit: BoxFit.contain,
                errorBuilder: (context, _, _) => Center(
                  child: Text(
                    context.l10n.originalImageUnavailable,
                    style: const TextStyle(color: GoCameraColors.foreground),
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.closeAction),
          ),
        ],
      ),
    ),
  ),
);

String _correctionChoiceLabel(
  AppLocalizations l10n,
  _CorrectionChoice choice,
) => switch (choice) {
  _CorrectionChoice.black => l10n.blackStoneShort,
  _CorrectionChoice.white => l10n.whiteStoneShort,
  _CorrectionChoice.empty => l10n.emptyPoint,
  _CorrectionChoice.uncertain => l10n.unclearPoint,
};

_SequenceIssueKind _sequenceIssueKind(SequenceSolveErrorCode code) =>
    switch (code) {
      SequenceSolveErrorCode.empty => _SequenceIssueKind.noFirst,
      SequenceSolveErrorCode.tooManyMoves => _SequenceIssueKind.tooMany,
      SequenceSolveErrorCode.duplicateMoveNumber =>
        _SequenceIssueKind.duplicate,
      SequenceSolveErrorCode.missingMoveNumber => _SequenceIssueKind.missing,
      SequenceSolveErrorCode.uncertainToken => _SequenceIssueKind.ocr,
      SequenceSolveErrorCode.wrongColor => _SequenceIssueKind.color,
      SequenceSolveErrorCode.illegalSequence => _SequenceIssueKind.illegal,
    };

String? _sequenceIssueDetail(AppLocalizations l10n, _SequenceIssueKind? kind) =>
    switch (kind) {
      null => null,
      _SequenceIssueKind.noFirst => l10n.sequenceIssueNoFirst,
      _SequenceIssueKind.missing => l10n.sequenceIssueMissing,
      _SequenceIssueKind.ocr => l10n.sequenceIssueOcr,
      _SequenceIssueKind.color => l10n.sequenceIssueColor,
      _SequenceIssueKind.finalMismatch => l10n.sequenceIssueFinalMismatch,
      _SequenceIssueKind.tooMany => l10n.sequenceIssueTooMany,
      _SequenceIssueKind.duplicate => l10n.sequenceIssueDuplicate,
      _SequenceIssueKind.illegal => l10n.sequenceIssueIllegal,
      _SequenceIssueKind.failed => l10n.sequenceValidationFailed,
    };

Map<domain.BoardPoint, domain.StoneColor> _stonesFromDraft(
  domain.ScanDraft draft,
) => <domain.BoardPoint, domain.StoneColor>{
  for (final prediction in draft.intersections)
    prediction.point: ?prediction.predictedStone,
};

List<BoardStone> _uiStones(Map<domain.BoardPoint, domain.StoneColor> stones) =>
    <BoardStone>[
      for (final entry in stones.entries)
        BoardStone(
          point: _uiPoint(entry.key),
          color: entry.value == domain.StoneColor.black
              ? StoneColor.black
              : StoneColor.white,
        ),
    ];

BoardPoint _uiPoint(domain.BoardPoint point) =>
    BoardPoint(point.column, point.row);

domain.KifuSource _scanSource(ScanCapturePayload capture) => domain.KifuSource(
  kind: capture.inputKind == ScanInputKind.camera
      ? domain.KifuSourceKind.camera
      : domain.KifuSourceKind.photoLibrary,
);

String _scanDocumentId(ScanCapturePayload capture, String suffix) =>
    'scan-$suffix-${sha256.convert(capture.originalFrame.encodedBytes)}';

domain.BoardPoint _firstMismatch(
  domain.BoardPosition left,
  domain.BoardPosition right,
) {
  for (var row = 0; row < left.size.dimension; row++) {
    for (var column = 0; column < left.size.dimension; column++) {
      final point = domain.BoardPoint(column, row);
      if (left.stoneAt(point) != right.stoneAt(point)) return point;
    }
  }
  throw StateError('Positions were equal.');
}
