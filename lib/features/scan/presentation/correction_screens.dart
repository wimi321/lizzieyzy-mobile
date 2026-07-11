import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;

import '../../../app/app_routes.dart';
import '../../common/presentation/feature_chrome.dart';
import '../../fixtures/ui_fixtures.dart';

enum _CorrectionChoice { black, white, empty, uncertain }

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
  late final ScanCapturePayload _capture = widget.capture ?? _fixtureCapture();
  late final Map<domain.BoardPoint, domain.StoneColor> _stones =
      _stonesFromDraft(_capture.draft);
  late final Set<domain.BoardPoint> _pending = <domain.BoardPoint>{
    for (final prediction in _capture.draft.intersections)
      if (prediction.confidence < 0.9) prediction.point,
  };
  late domain.BoardPoint? _selectedPoint = _pending.firstOrNull;

  int get _blackCount =>
      _stones.values.where((stone) => stone == domain.StoneColor.black).length;
  int get _whiteCount =>
      _stones.values.where((stone) => stone == domain.StoneColor.white).length;

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
    if (_pending.isNotEmpty) return;
    final snapshot = domain.PositionSnapshot(
      id: 'scan-${DateTime.now().toUtc().microsecondsSinceEpoch}',
      position: domain.BoardPosition(
        size: _capture.draft.boardSize,
        stones: _stones,
      ),
      rules: const domain.GoRules.chinese(),
      source: domain.KifuSource(
        kind: _capture.inputKind == ScanInputKind.camera
            ? domain.KifuSourceKind.camera
            : domain.KifuSourceKind.photoLibrary,
      ),
    );
    Navigator.pushNamed(
      context,
      AppRoutes.scanResult,
      arguments: ScanPositionPayload(
        snapshot: snapshot,
        originalFrame: _capture.originalFrame,
        draft: _capture.draft,
      ),
    );
  }

  Future<void> _showOriginal() => showDialog<void>(
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
                color: const Color(0xFF111713),
                child: Center(
                  child: Image.memory(
                    _capture.originalFrame.encodedBytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Center(
                      child: Text(
                        '测试识别图',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(GoSpacing.s3),
              child: Row(
                children: <Widget>[
                  const Expanded(child: Text('原始照片')),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: <Widget>[
          FeatureTopBar(
            title: '校对棋盘',
            subtitle: '自动拉正 · ${_capture.draft.boardSize.dimension}路',
            leading: const BackCircleButton(),
            actions: <Widget>[
              IconButton(
                tooltip: '查看原图',
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
                  final boardSide = math.min(
                    math.min(constraints.maxWidth, 560.0) - GoSpacing.s8,
                    math.max(180.0, constraints.maxHeight - 220.0),
                  );
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        key: const Key('board-correction-scroll'),
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
                                  boardSize: _capture.draft.boardSize.dimension,
                                  stones: <BoardStone>[
                                    for (final entry in _stones.entries)
                                      BoardStone(
                                        point: BoardPoint(
                                          entry.key.column,
                                          entry.key.row,
                                        ),
                                        color:
                                            entry.value ==
                                                domain.StoneColor.black
                                            ? StoneColor.black
                                            : StoneColor.white,
                                      ),
                                  ],
                                  candidates: <BoardCandidate>[
                                    for (final point in _pending.take(12))
                                      BoardCandidate(
                                        point: BoardPoint(
                                          point.column,
                                          point.row,
                                        ),
                                        label: '?',
                                        detail: '待确认',
                                        tone: CandidateTone.tertiary,
                                      ),
                                  ],
                                  selectedPoint: _selectedPoint == null
                                      ? null
                                      : BoardPoint(
                                          _selectedPoint!.column,
                                          _selectedPoint!.row,
                                        ),
                                  onIntersectionTap: _selectPoint,
                                  semanticLabel:
                                      '实体棋盘识别校对，黑$_blackCount子，白$_whiteCount子，当前有${_pending.length}个交叉点待确认',
                                ),
                              ),
                            ),
                            const SizedBox(height: GoSpacing.s2),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    '黑 $_blackCount  ·  白 $_whiteCount',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(width: GoSpacing.s2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: GoSpacing.s3,
                                    vertical: GoSpacing.s2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _pending.isEmpty
                                        ? theme.colorScheme.primaryContainer
                                        : theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(
                                      GoRadii.pill,
                                    ),
                                  ),
                                  child: Text(
                                    '待确认 ${_pending.length}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: _pending.isEmpty
                                              ? theme
                                                    .colorScheme
                                                    .onPrimaryContainer
                                              : theme
                                                    .colorScheme
                                                    .onErrorContainer,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: GoSpacing.s2),
                            SurfacePanel(
                              padding: const EdgeInsets.all(GoSpacing.s2),
                              child: Row(
                                children: _CorrectionChoice.values
                                    .map(
                                      (choice) => Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          child: _CorrectionChoiceButton(
                                            choice: choice,
                                            selected: choice == _selected,
                                            onTap: () => _applyChoice(choice),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: GoSpacing.s3),
                            FilledButton.icon(
                              onPressed: _pending.isEmpty ? _finish : null,
                              icon: const Icon(Icons.check_rounded),
                              label: Text(
                                _pending.isEmpty
                                    ? '确认当前局面'
                                    : '请先确认 ${_pending.length} 处',
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
}

ScanCapturePayload _fixtureCapture() {
  final fixtureStones = <domain.BoardPoint, domain.StoneColor>{
    for (final stone in UiFixtures.stones)
      domain.BoardPoint(
        stone.point.x,
        stone.point.y,
      ): stone.color == StoneColor.black
          ? domain.StoneColor.black
          : domain.StoneColor.white,
  };
  final pending = <domain.BoardPoint>{
    const domain.BoardPoint(7, 7),
    const domain.BoardPoint(12, 13),
  };
  final draft = domain.ScanDraft(
    kind: domain.ScanKind.physicalBoard,
    boardSize: domain.BoardSize.nineteen,
    boardBounds: const domain.BoardQuadrilateral(
      topLeft: domain.NormalizedPoint(0.05, 0.05),
      topRight: domain.NormalizedPoint(0.95, 0.05),
      bottomRight: domain.NormalizedPoint(0.95, 0.95),
      bottomLeft: domain.NormalizedPoint(0.05, 0.95),
    ),
    intersections: <domain.IntersectionPrediction>[
      for (var row = 0; row < 19; row++)
        for (var column = 0; column < 19; column++)
          _fixturePrediction(
            domain.BoardPoint(column, row),
            fixtureStones[domain.BoardPoint(column, row)],
            pending.contains(domain.BoardPoint(column, row)),
          ),
    ],
    boardConfidence: 0.94,
  );
  return ScanCapturePayload(
    draft: draft,
    originalFrame: domain.CapturedFrame(
      encodedBytes: Uint8List.fromList(<int>[0]),
      pixelWidth: 1,
      pixelHeight: 1,
      capturedAt: DateTime.utc(2026, 7, 11),
    ),
    inputKind: ScanInputKind.camera,
    usedBurst: true,
  );
}

domain.IntersectionPrediction _fixturePrediction(
  domain.BoardPoint point,
  domain.StoneColor? stone,
  bool uncertain,
) {
  if (uncertain) {
    return domain.IntersectionPrediction(
      point: point,
      blackProbability: 0.42,
      whiteProbability: 0.32,
      emptyProbability: 0.26,
    );
  }
  return switch (stone) {
    domain.StoneColor.black => domain.IntersectionPrediction(
      point: point,
      blackProbability: 0.98,
      whiteProbability: 0.01,
      emptyProbability: 0.01,
    ),
    domain.StoneColor.white => domain.IntersectionPrediction(
      point: point,
      blackProbability: 0.01,
      whiteProbability: 0.98,
      emptyProbability: 0.01,
    ),
    null => domain.IntersectionPrediction(
      point: point,
      blackProbability: 0.01,
      whiteProbability: 0.01,
      emptyProbability: 0.98,
    ),
  };
}

Map<domain.BoardPoint, domain.StoneColor> _stonesFromDraft(
  domain.ScanDraft draft,
) {
  final stones = <domain.BoardPoint, domain.StoneColor>{};
  for (final prediction in draft.intersections) {
    final stone = prediction.predictedStone;
    if (stone != null) stones[prediction.point] = stone;
  }
  return stones;
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

  String get _label => switch (choice) {
    _CorrectionChoice.black => '黑',
    _CorrectionChoice.white => '白',
    _CorrectionChoice.empty => '空',
    _CorrectionChoice.uncertain => '看不清',
  };

  IconData get _icon => switch (choice) {
    _CorrectionChoice.black => Icons.circle,
    _CorrectionChoice.white => Icons.circle_outlined,
    _CorrectionChoice.empty => Icons.close_rounded,
    _CorrectionChoice.uncertain => Icons.help_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '标记为$_label',
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(GoRadii.small),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GoRadii.small),
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  _icon,
                  size: 20,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 2),
                Text(
                  _label,
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NumberedKifuCorrectionScreen extends StatefulWidget {
  const NumberedKifuCorrectionScreen({super.key});

  @override
  State<NumberedKifuCorrectionScreen> createState() =>
      _NumberedKifuCorrectionScreenState();
}

class _NumberedKifuCorrectionScreenState
    extends State<NumberedKifuCorrectionScreen> {
  int? _selectedMove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberedStones = <BoardStone>[
      ...UiFixtures.stones.where(
        (stone) => stone.point != const BoardPoint(16, 5),
      ),
      const BoardStone(
        point: BoardPoint(16, 5),
        color: StoneColor.white,
        moveNumber: 87,
      ),
    ];
    return Scaffold(
      body: Column(
        children: <Widget>[
          const FeatureTopBar(
            title: '校对手顺',
            subtitle: '编号棋谱图 · 已识别 86 手',
            leading: BackCircleButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boardSide = math.min(
                    math.min(constraints.maxWidth, 520.0) - GoSpacing.s8,
                    math.max(180.0, constraints.maxHeight - 330.0),
                  );
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        key: const Key('numbered-correction-scroll'),
                        padding: const EdgeInsets.fromLTRB(
                          GoSpacing.s4,
                          GoSpacing.s1,
                          GoSpacing.s4,
                          GoSpacing.s2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Center(
                              child: SizedBox.square(
                                dimension: boardSide,
                                child: GoBoard(
                                  stones: numberedStones,
                                  selectedPoint: const BoardPoint(16, 5),
                                  lastMove: const BoardPoint(16, 5),
                                  semanticLabel: '编号棋谱校对，第87手位置无法确认',
                                ),
                              ),
                            ),
                            const SizedBox(height: GoSpacing.s2),
                            SurfacePanel(
                              padding: const EdgeInsets.all(GoSpacing.s3),
                              color: theme.colorScheme.errorContainer,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                  const SizedBox(width: GoSpacing.s2),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          '第87手无法确认',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onErrorContainer,
                                              ),
                                        ),
                                        Text(
                                          '可能是反色数字，或提子后的同点复用。',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onErrorContainer,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: GoSpacing.s2),
                            Text('数字候选', style: theme.textTheme.titleMedium),
                            const SizedBox(height: GoSpacing.s1),
                            Row(
                              children: <Widget>[
                                for (final move in <int>[87, 37, 81, 97]) ...[
                                  Expanded(
                                    child: ChoiceChip(
                                      label: SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          '$move',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      selected: _selectedMove == move,
                                      onSelected: (_) =>
                                          setState(() => _selectedMove = move),
                                    ),
                                  ),
                                  if (move != 97)
                                    const SizedBox(width: GoSpacing.s1),
                                ],
                              ],
                            ),
                            const SizedBox(height: GoSpacing.s1),
                            SizedBox(
                              width: double.infinity,
                              child: ChoiceChip(
                                avatar: const Icon(
                                  Icons.undo_rounded,
                                  size: 18,
                                ),
                                label: const SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    '提子后同点复用',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                selected: _selectedMove == -1,
                                onSelected: (_) =>
                                    setState(() => _selectedMove = -1),
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: GoSpacing.s2),
                            FilledButton(
                              onPressed: _selectedMove == null
                                  ? null
                                  : () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.scanResult,
                                    ),
                              child: const Text('验证手顺并继续'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.scanResult,
                              ),
                              child: const Text('无法判断，按当前局面保存'),
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
}
