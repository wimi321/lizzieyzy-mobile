import '../../domain/domain.dart';
import 'kifu_resource_limits.dart';
import 'sgf_parser.dart';

enum SgfImportWarningCode {
  additionalGamesIgnored,
  unknownRules,
  moveNumberGap,
  midGameSetup,
  turnOverride,
  handicapMismatch,
  ruleViolation,
  duplicateOccupiedPoint,
}

final class SgfImportWarning {
  const SgfImportWarning({required this.code, required this.message});

  final SgfImportWarningCode code;
  final String message;
}

final class SgfImportResult {
  SgfImportResult({
    required this.document,
    required this.tree,
    required List<SgfImportWarning> warnings,
    this.blackRank,
    this.whiteRank,
  }) : warnings = List.unmodifiable(warnings);

  final KifuDocument document;
  final SgfGameTree tree;
  final List<SgfImportWarning> warnings;

  /// BR/WR are retained in [tree] for lossless export and surfaced here for UI.
  final String? blackRank;
  final String? whiteRank;

  bool get isVerifiedGame => document is VerifiedGameRecord;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Maps SGF FF[4] data to clean-room domain documents and back.
final class SgfCodec {
  const SgfCodec({this.syntaxParser = const SgfSyntaxParser()});

  final SgfSyntaxParser syntaxParser;

  KifuDocument importDocument(
    String source, {
    required String documentId,
    KifuSource kifuSource = const KifuSource(kind: KifuSourceKind.localFile),
  }) => decode(source, documentId: documentId, kifuSource: kifuSource).document;

  SgfImportResult decode(
    String source, {
    required String documentId,
    KifuSource kifuSource = const KifuSource(kind: KifuSourceKind.localFile),
  }) {
    final collection = syntaxParser.parseCollection(source);
    final warnings = <SgfImportWarning>[];
    if (collection.length > 1) {
      warnings.add(
        SgfImportWarning(
          code: SgfImportWarningCode.additionalGamesIgnored,
          message:
              '${collection.length - 1} additional SGF game tree(s) were ignored.',
        ),
      );
    }

    var tree = collection.first;
    final root = tree.sequence.first;
    _validateSingleValue(root, 'FF', source);
    _validateSingleValue(root, 'GM', source);
    _validateSingleValue(root, 'SZ', source);
    _validateSingleValue(root, 'HA', source);

    final fileFormat = _parseInteger(
      root['FF']?.values.single ?? '4',
      'FF',
      source,
    );
    if (fileFormat != 4) {
      throw SgfFormatException(
        'Unsupported SGF file format FF[$fileFormat]; only FF[4] is supported.',
        source,
        0,
      );
    }
    final gameType = _parseInteger(
      root['GM']?.values.single ?? '1',
      'GM',
      source,
    );
    if (gameType != 1) {
      throw SgfFormatException(
        'Unsupported SGF game type GM[$gameType]; only Go (GM[1]) is supported.',
        source,
        0,
      );
    }

    final sizeValue = _parseInteger(
      root['SZ']?.values.single ?? '19',
      'SZ',
      source,
    );
    final boardSize = _boardSize(sizeValue, source);
    tree = _withNormalizedRoot(tree, boardSize);
    _validateCoordinates(tree, boardSize, source);

    final normalizedRoot = tree.sequence.first;
    final handicapValue = _singleValue(normalizedRoot, 'HA', source);
    final handicap = handicapValue == null
        ? null
        : _parseInteger(handicapValue, 'HA', source);
    if (handicap != null && handicap < 0) {
      throw SgfFormatException('HA must be a non-negative integer.', source, 0);
    }
    final rulesResult = _rulesFrom(normalizedRoot, source);
    if (rulesResult.warning != null) warnings.add(rulesResult.warning!);
    final rules = rulesResult.rules;
    final metadata = _metadataFrom(normalizedRoot, source);
    final mainline = _flattenMainline(tree);
    final setup = <BoardPoint, StoneColor>{};
    final moves = <Move>[];
    var sawMove = false;
    var hasMidGameSetup = false;
    var hasTurnOverride = false;
    var numberingIsComplete = true;
    var startingMoveNumber = 1;
    var expectedMoveNumber = 1;
    StoneColor? explicitPlayerToMove;

    for (final node in mainline) {
      final hasSetup =
          node['AB'] != null || node['AW'] != null || node['AE'] != null;
      final move = _moveFrom(node, boardSize, source);

      if (!sawMove) {
        if (hasSetup) {
          _applyInitialSetup(node, setup, boardSize, source);
          if (move != null) hasMidGameSetup = true;
        }
        final player = _playerToMove(node, source);
        if (player != null) explicitPlayerToMove = player;
        if (move == null) continue;
      } else if (hasSetup) {
        hasMidGameSetup = true;
        if (_playerToMove(node, source) != null) hasTurnOverride = true;
      } else if (_playerToMove(node, source) != null) {
        hasTurnOverride = true;
      }
      if (move == null) continue;

      final moveNumberValue = _singleValue(node, 'MN', source);
      final moveNumber = moveNumberValue == null
          ? expectedMoveNumber
          : _parsePositiveInteger(moveNumberValue, 'MN', source);
      if (moves.isEmpty) startingMoveNumber = moveNumber;
      if (moveNumber != expectedMoveNumber) numberingIsComplete = false;
      expectedMoveNumber = moveNumber + 1;
      moves.add(move);
      sawMove = true;
    }
    syntaxParser.limits.enforceMoves(moves.length);

    final initialPosition = BoardPosition(size: boardSize, stones: setup);
    final handicapMismatch =
        handicap != null &&
        (setup.values.where((stone) => stone == StoneColor.black).length !=
                handicap ||
            (handicap > 0 &&
                setup.values.any((stone) => stone == StoneColor.white)) ||
            (handicap > 1 &&
                explicitPlayerToMove != null &&
                explicitPlayerToMove != StoneColor.white));
    if (handicapMismatch) {
      warnings.add(
        const SgfImportWarning(
          code: SgfImportWarningCode.handicapMismatch,
          message:
              'HA, setup stones, and the declared player to move are inconsistent.',
        ),
      );
    }
    final firstPlayer =
        explicitPlayerToMove ??
        ((handicap ?? 0) > 1 ? StoneColor.white : StoneColor.black);

    if (hasMidGameSetup) {
      warnings.add(
        const SgfImportWarning(
          code: SgfImportWarningCode.midGameSetup,
          message:
              'Setup properties after play began cannot form a verified linear record.',
        ),
      );
    }
    if (hasTurnOverride) {
      warnings.add(
        const SgfImportWarning(
          code: SgfImportWarningCode.turnOverride,
          message:
              'A PL property after play began prevents full-record verification.',
        ),
      );
    }
    if (!numberingIsComplete || startingMoveNumber != 1) {
      warnings.add(
        SgfImportWarning(
          code: SgfImportWarningCode.moveNumberGap,
          message:
              'The main line starts at or jumps to move $startingMoveNumber.',
        ),
      );
    }

    if (moves.isEmpty) {
      final snapshot = PositionSnapshot(
        id: documentId,
        position: initialPosition,
        rules: rules,
        source: kifuSource,
        metadata: metadata,
        sourceSgf: tree,
        playerToMove: explicitPlayerToMove,
      );
      return SgfImportResult(
        document: snapshot,
        tree: tree,
        warnings: warnings,
        blackRank: _singleValue(normalizedRoot, 'BR', source),
        whiteRank: _singleValue(normalizedRoot, 'WR', source),
      );
    }

    final validation = GoRuleValidator.validate(
      initialPosition: initialPosition,
      moves: moves,
      rules: rules,
      firstPlayer: firstPlayer,
    );
    warnings.addAll(
      _alternateVariationWarnings(
        tree,
        initialPosition,
        rules,
        firstPlayer,
        boardSize,
        source,
        syntaxParser.limits,
      ),
    );
    final canVerify =
        validation.isValid &&
        rulesResult.warning == null &&
        !hasMidGameSetup &&
        !hasTurnOverride &&
        !handicapMismatch &&
        numberingIsComplete &&
        startingMoveNumber == 1;

    late final KifuDocument document;
    if (canVerify) {
      document = VerifiedGameRecord(
        id: documentId,
        initialPosition: initialPosition,
        moves: moves,
        rules: rules,
        source: kifuSource,
        metadata: metadata,
        sourceSgf: tree,
        firstPlayer: firstPlayer,
      );
    } else {
      if (!validation.isValid) {
        final violation = validation.violations.first;
        warnings.add(
          SgfImportWarning(
            code: violation.code == RuleViolationCode.occupied
                ? SgfImportWarningCode.duplicateOccupiedPoint
                : SgfImportWarningCode.ruleViolation,
            message:
                'Move ${violation.moveIndex + startingMoveNumber}: ${violation.message}',
          ),
        );
      }
      document = PartialGameRecord(
        id: documentId,
        initialPosition: initialPosition,
        moves: moves,
        rules: rules,
        source: kifuSource,
        metadata: metadata,
        sourceSgf: tree,
        startingMoveNumber: startingMoveNumber,
        firstPlayer: firstPlayer,
      );
    }

    return SgfImportResult(
      document: document,
      tree: tree,
      warnings: warnings,
      blackRank: _singleValue(normalizedRoot, 'BR', source),
      whiteRank: _singleValue(normalizedRoot, 'WR', source),
    );
  }

  String encode(KifuDocument document, {bool preserveSourceTree = true}) {
    final tree = preserveSourceTree
        ? _treeForLosslessEncoding(document)
        : _treeFromDocument(document);
    return encodeTree(tree);
  }

  SgfGameTree _treeForLosslessEncoding(KifuDocument document) {
    final source = document.sourceSgf;
    if (source == null) return _treeFromDocument(document);

    // A snapshot is the one imported document users can currently amend
    // (notably PL / player-to-move). Overlay every domain-owned root property
    // while retaining comments and other unknown SGF properties verbatim.
    if (document is PositionSnapshot) {
      return _overlaySnapshotRoot(source, _treeFromDocument(document));
    }

    // Preserve a source tree, including branches and unknown properties, only
    // while it still describes the current domain document. If a future editor
    // changes moves or metadata without updating sourceSgf, canonical output is
    // safer than persisting stale state.
    try {
      final sourceDocument = decode(
        encodeTree(source),
        documentId: document.id,
        kifuSource: document.source,
      ).document;
      if (_canonicalSemanticEncoding(sourceDocument) ==
          _canonicalSemanticEncoding(document)) {
        return source;
      }
    } on Object {
      // sourceSgf is provenance, never the authority for persistence.
    }
    return _treeFromDocument(document);
  }

  String _canonicalSemanticEncoding(KifuDocument document) =>
      encodeTree(_treeFromDocument(document));

  SgfGameTree _overlaySnapshotRoot(SgfGameTree source, SgfGameTree canonical) {
    const owned = <String>{
      'FF',
      'GM',
      'SZ',
      'KM',
      'RU',
      'PB',
      'PW',
      'EV',
      'DT',
      'RE',
      'AB',
      'AW',
      'AE',
      'PL',
      'HA',
    };
    SgfGameTree scrub(SgfGameTree tree, {required bool root}) {
      final sequence = <SgfNode>[];
      for (var index = 0; index < tree.sequence.length; index++) {
        final retained = tree.sequence[index].properties.values.where(
          (property) => !owned.contains(property.identifier),
        );
        sequence.add(
          SgfNode(
            properties: <SgfProperty>[
              if (root && index == 0)
                ...canonical.sequence.first.properties.values,
              ...retained,
            ],
          ),
        );
      }
      return SgfGameTree(
        sequence: sequence,
        variations: <SgfGameTree>[
          for (final variation in tree.variations)
            scrub(variation, root: false),
        ],
      );
    }

    return scrub(source, root: true);
  }

  String encodeTree(SgfGameTree tree) => _SgfWriter().writeTree(tree);

  String encodeCollection(Iterable<SgfGameTree> trees) {
    final games = trees.toList(growable: false);
    if (games.isEmpty) {
      throw ArgumentError.value(
        trees,
        'trees',
        'An SGF collection cannot be empty.',
      );
    }
    final writer = _SgfWriter();
    return games.map(writer.writeTree).join();
  }

  SgfGameTree _treeFromDocument(KifuDocument document) {
    final rootProperties = <SgfProperty>[
      SgfProperty(identifier: 'FF', values: const ['4']),
      SgfProperty(identifier: 'GM', values: const ['1']),
      SgfProperty(
        identifier: 'SZ',
        values: [document.boardSize.dimension.toString()],
      ),
      SgfProperty(
        identifier: 'KM',
        values: [_formatNumber(document.rules.komi)],
      ),
      SgfProperty(
        identifier: 'RU',
        values: [_rulesName(document.rules.ruleSet)],
      ),
    ];
    final metadata = document.metadata;
    if (metadata.blackPlayer case final value? when value.isNotEmpty) {
      rootProperties.add(SgfProperty(identifier: 'PB', values: [value]));
    }
    if (metadata.whitePlayer case final value? when value.isNotEmpty) {
      rootProperties.add(SgfProperty(identifier: 'PW', values: [value]));
    }
    if (metadata.event case final value? when value.isNotEmpty) {
      rootProperties.add(SgfProperty(identifier: 'EV', values: [value]));
    }
    if (metadata.playedAt case final value?) {
      rootProperties.add(
        SgfProperty(identifier: 'DT', values: [_formatDate(value)]),
      );
    }
    if (metadata.result case final value?) {
      rootProperties.add(
        SgfProperty(identifier: 'RE', values: [_formatResult(value)]),
      );
    }

    final (
      initialPosition,
      moves,
      firstPlayer,
      startingMoveNumber,
    ) = switch (document) {
      PositionSnapshot(:final position, :final playerToMove) => (
        position,
        const <Move>[],
        playerToMove,
        1,
      ),
      PartialGameRecord(
        :final initialPosition,
        :final moves,
        :final firstPlayer,
        :final startingMoveNumber,
      ) =>
        (initialPosition, moves, firstPlayer, startingMoveNumber),
      VerifiedGameRecord(
        :final initialPosition,
        :final moves,
        :final firstPlayer,
      ) =>
        (initialPosition, moves, firstPlayer, 1),
    };

    final black =
        initialPosition.stones.entries
            .where((entry) => entry.value == StoneColor.black)
            .map((entry) => entry.key)
            .toList()
          ..sort();
    final white =
        initialPosition.stones.entries
            .where((entry) => entry.value == StoneColor.white)
            .map((entry) => entry.key)
            .toList()
          ..sort();
    if (black.isNotEmpty) {
      rootProperties.add(
        SgfProperty(
          identifier: 'AB',
          values: black
              .map(
                (point) =>
                    SgfCoordinate.fromPoint(point, document.boardSize).value,
              )
              .toList(),
        ),
      );
    }
    if (white.isNotEmpty) {
      rootProperties.add(
        SgfProperty(
          identifier: 'AW',
          values: white
              .map(
                (point) =>
                    SgfCoordinate.fromPoint(point, document.boardSize).value,
              )
              .toList(),
        ),
      );
    }
    if (firstPlayer == StoneColor.white) {
      rootProperties.add(SgfProperty(identifier: 'PL', values: const ['W']));
    }

    final nodes = <SgfNode>[SgfNode(properties: rootProperties)];
    for (var index = 0; index < moves.length; index++) {
      final move = moves[index];
      final properties = <SgfProperty>[
        SgfProperty(
          identifier: move.color.sgfValue,
          values: [
            move.isPass
                ? ''
                : SgfCoordinate.fromPoint(
                    move.point!,
                    document.boardSize,
                  ).value,
          ],
        ),
      ];
      if (index == 0 && startingMoveNumber != 1) {
        properties.add(
          SgfProperty(
            identifier: 'MN',
            values: [startingMoveNumber.toString()],
          ),
        );
      }
      nodes.add(SgfNode(properties: properties));
    }
    return SgfGameTree(sequence: nodes);
  }
}

final class _RulesResult {
  const _RulesResult(this.rules, this.warning);

  final GoRules rules;
  final SgfImportWarning? warning;
}

_RulesResult _rulesFrom(SgfNode root, String source) {
  final rulesName = _singleValue(root, 'RU', source)?.trim().toLowerCase();
  final (
    ruleSet,
    koRule,
    allowSuicide,
    defaultKomi,
    warning,
  ) = switch (rulesName) {
    null || '' => (RuleSet.japanese, KoRule.simple, false, 6.5, null),
    'chinese' ||
    'china' => (RuleSet.chinese, KoRule.positionalSuperko, false, 7.5, null),
    'japanese' ||
    'japan' => (RuleSet.japanese, KoRule.simple, false, 6.5, null),
    'korean' || 'korea' => (RuleSet.korean, KoRule.simple, false, 6.5, null),
    'aga' => (RuleSet.aga, KoRule.situationalSuperko, false, 7.5, null),
    'new zealand' ||
    'nz' => (RuleSet.newZealand, KoRule.situationalSuperko, true, 7.0, null),
    'tromp-taylor' || 'tromp taylor' => (
      RuleSet.trompTaylor,
      KoRule.positionalSuperko,
      true,
      7.5,
      null,
    ),
    _ => (
      RuleSet.japanese,
      KoRule.simple,
      false,
      6.5,
      SgfImportWarning(
        code: SgfImportWarningCode.unknownRules,
        message:
            'Unknown rules "$rulesName"; Japanese rules were used for validation.',
      ),
    ),
  };

  final komiValue = _singleValue(root, 'KM', source);
  final komi = komiValue == null
      ? defaultKomi
      : _parseFiniteDouble(komiValue, 'KM', source);
  return _RulesResult(
    GoRules(
      ruleSet: ruleSet,
      komi: komi,
      koRule: koRule,
      allowSuicide: allowSuicide,
    ),
    warning,
  );
}

GameMetadata _metadataFrom(SgfNode root, String source) => GameMetadata(
  blackPlayer: _singleValue(root, 'PB', source),
  whitePlayer: _singleValue(root, 'PW', source),
  event: _singleValue(root, 'EV', source),
  playedAt: _parseDate(_singleValue(root, 'DT', source)),
  result: _parseResult(_singleValue(root, 'RE', source)),
);

GameResult? _parseResult(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final result = value.trim();
  final lower = result.toLowerCase();
  if (lower == '0' || lower == 'draw' || lower == 'jigo') {
    return const GameResult(type: ResultType.draw);
  }
  if (lower == 'void') return const GameResult(type: ResultType.voided);
  if (lower == '?') return const GameResult(type: ResultType.unknown);

  final match = RegExp(r'^([BWbw])\+(.+)$').firstMatch(result);
  if (match == null) {
    return GameResult(type: ResultType.unknown, reason: result);
  }
  final type = match.group(1)!.toUpperCase() == 'B'
      ? ResultType.blackWin
      : ResultType.whiteWin;
  final detail = match.group(2)!;
  final margin = double.tryParse(detail);
  if (margin != null && margin.isFinite && margin >= 0) {
    return GameResult(type: type, margin: margin);
  }
  final reason = switch (detail.toUpperCase()) {
    'R' || 'RESIGN' => 'resign',
    'T' || 'TIME' => 'time',
    'F' || 'FORFEIT' => 'forfeit',
    _ => detail,
  };
  return GameResult(type: type, reason: reason);
}

DateTime? _parseDate(String? value) {
  if (value == null) return null;
  final firstDate = value.split(',').first.trim();
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(firstDate)) return null;
  final parts = firstDate.split('-').map(int.parse).toList(growable: false);
  final parsed = DateTime.utc(parts[0], parts[1], parts[2]);
  if (parsed.year != parts[0] ||
      parsed.month != parts[1] ||
      parsed.day != parts[2]) {
    return null;
  }
  return parsed;
}

List<SgfImportWarning> _alternateVariationWarnings(
  SgfGameTree root,
  BoardPosition initialPosition,
  GoRules rules,
  StoneColor firstPlayer,
  BoardSize size,
  String source,
  KifuResourceLimits limits,
) {
  final warnings = <SgfImportWarning>[];
  var replayWork = 0;

  void walk(
    SgfGameTree tree,
    List<Move> prefix,
    bool isMainline,
    String path,
    bool inheritedMidGameSetup,
  ) {
    replayWork += prefix.length + tree.sequence.length;
    limits.enforceReplayWork(replayWork);
    final moves = List<Move>.of(prefix);
    var containsMidGameSetup = inheritedMidGameSetup;
    for (final node in tree.sequence) {
      final hasSetup =
          node['AB'] != null || node['AW'] != null || node['AE'] != null;
      if (hasSetup && moves.isNotEmpty) containsMidGameSetup = true;
      final move = _moveFrom(node, size, source);
      if (move != null) moves.add(move);
    }

    if (tree.variations.isNotEmpty) {
      for (var index = 0; index < tree.variations.length; index++) {
        walk(
          tree.variations[index],
          moves,
          isMainline && index == 0,
          '$path.${index + 1}',
          containsMidGameSetup,
        );
      }
      return;
    }
    if (isMainline) return;

    replayWork += moves.length;
    limits.enforceReplayWork(replayWork);

    if (containsMidGameSetup) {
      warnings.add(
        SgfImportWarning(
          code: SgfImportWarningCode.midGameSetup,
          message:
              'Variation $path contains setup properties after play began.',
        ),
      );
    }
    final validation = GoRuleValidator.validate(
      initialPosition: initialPosition,
      moves: moves,
      rules: rules,
      firstPlayer: firstPlayer,
    );
    if (!validation.isValid) {
      final violation = validation.violations.first;
      warnings.add(
        SgfImportWarning(
          code: violation.code == RuleViolationCode.occupied
              ? SgfImportWarningCode.duplicateOccupiedPoint
              : SgfImportWarningCode.ruleViolation,
          message:
              'Variation $path, move ${violation.moveIndex + 1}: ${violation.message}',
        ),
      );
    }
  }

  walk(root, const [], true, '1', false);
  return warnings;
}

SgfGameTree _withNormalizedRoot(SgfGameTree tree, BoardSize size) {
  final original = tree.sequence.first;
  final normalizedProperties = <SgfProperty>[
    SgfProperty(identifier: 'FF', values: const ['4']),
    SgfProperty(identifier: 'GM', values: const ['1']),
    SgfProperty(identifier: 'SZ', values: [size.dimension.toString()]),
    ...original.properties.values.where(
      (property) => !const {'FF', 'GM', 'SZ'}.contains(property.identifier),
    ),
  ];
  return SgfGameTree(
    sequence: [
      SgfNode(properties: normalizedProperties),
      ...tree.sequence.skip(1),
    ],
    variations: tree.variations,
  );
}

List<SgfNode> _flattenMainline(SgfGameTree tree) {
  final nodes = <SgfNode>[];
  var current = tree;
  while (true) {
    nodes.addAll(current.sequence);
    if (current.variations.isEmpty) break;
    current = current.variations.first;
  }
  return nodes;
}

void _validateCoordinates(SgfGameTree tree, BoardSize size, String source) {
  for (final node in tree.sequence) {
    final blackMove = node['B'];
    final whiteMove = node['W'];
    if (blackMove != null && whiteMove != null) {
      throw SgfFormatException(
        'An SGF node cannot contain both B and W moves.',
        source,
        0,
      );
    }
    for (final property in [blackMove, whiteMove]) {
      if (property == null) continue;
      if (property.values.length != 1) {
        throw SgfFormatException(
          'A move property must contain exactly one value.',
          source,
          0,
        );
      }
      if (property.values.single.isNotEmpty) {
        _point(property.values.single, size, source, property.identifier);
      }
    }
    for (final identifier in const ['AB', 'AW', 'AE']) {
      final property = node[identifier];
      if (property != null) {
        _expandedPoints(property.values, size, source, identifier);
      }
    }
    _playerToMove(node, source);
    _validateSingleValue(node, 'MN', source);
  }
  for (final variation in tree.variations) {
    _validateCoordinates(variation, size, source);
  }
}

void _applyInitialSetup(
  SgfNode node,
  Map<BoardPoint, StoneColor> setup,
  BoardSize size,
  String source,
) {
  final black = _expandedPoints(
    node['AB']?.values ?? const [],
    size,
    source,
    'AB',
  );
  final white = _expandedPoints(
    node['AW']?.values ?? const [],
    size,
    source,
    'AW',
  );
  final empty = _expandedPoints(
    node['AE']?.values ?? const [],
    size,
    source,
    'AE',
  );

  final overlaps = <BoardPoint>{
    ...black.where(white.contains),
    ...black.where(empty.contains),
    ...white.where(empty.contains),
  };
  if (overlaps.isNotEmpty) {
    throw SgfFormatException(
      'Conflicting setup properties at ${overlaps.first}.',
      source,
      0,
    );
  }
  for (final point in empty) {
    setup.remove(point);
  }
  for (final entry in [
    for (final point in black) MapEntry(point, StoneColor.black),
    for (final point in white) MapEntry(point, StoneColor.white),
  ]) {
    if (setup.containsKey(entry.key)) {
      throw SgfFormatException(
        'Duplicate occupied setup point ${entry.key}.',
        source,
        0,
      );
    }
    setup[entry.key] = entry.value;
  }
}

Set<BoardPoint> _expandedPoints(
  List<String> values,
  BoardSize size,
  String source,
  String property,
) {
  final result = <BoardPoint>{};
  for (final value in values) {
    if (value.isEmpty) {
      throw SgfFormatException(
        '$property setup coordinates cannot be empty.',
        source,
        0,
      );
    }
    final parts = value.split(':');
    if (parts.length == 1) {
      final point = _point(value, size, source, property);
      if (!result.add(point)) {
        throw SgfFormatException(
          'Duplicate coordinate $value in $property.',
          source,
          0,
        );
      }
      continue;
    }
    if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
      throw SgfFormatException(
        'Invalid compressed point list "$value".',
        source,
        0,
      );
    }
    final from = _point(parts.first, size, source, property);
    final to = _point(parts.last, size, source, property);
    final minColumn = from.column < to.column ? from.column : to.column;
    final maxColumn = from.column > to.column ? from.column : to.column;
    final minRow = from.row < to.row ? from.row : to.row;
    final maxRow = from.row > to.row ? from.row : to.row;
    for (var row = minRow; row <= maxRow; row++) {
      for (var column = minColumn; column <= maxColumn; column++) {
        final point = BoardPoint(column, row);
        if (!result.add(point)) {
          throw SgfFormatException(
            'Overlapping coordinate $point in $property.',
            source,
            0,
          );
        }
      }
    }
  }
  return result;
}

Move? _moveFrom(SgfNode node, BoardSize size, String source) {
  final property = node['B'] ?? node['W'];
  if (property == null) return null;
  final color = property.identifier == 'B'
      ? StoneColor.black
      : StoneColor.white;
  final value = property.values.single;
  return value.isEmpty
      ? Move.pass(color: color)
      : Move.play(
          color: color,
          point: _point(value, size, source, property.identifier),
        );
}

StoneColor? _playerToMove(SgfNode node, String source) {
  final value = _singleValue(node, 'PL', source);
  if (value == null) return null;
  return switch (value.toUpperCase()) {
    'B' => StoneColor.black,
    'W' => StoneColor.white,
    _ => throw SgfFormatException(
      'PL must be B or W, found "$value".',
      source,
      0,
    ),
  };
}

BoardPoint _point(
  String value,
  BoardSize size,
  String source,
  String property,
) {
  try {
    return SgfCoordinate(value).toPoint(size);
  } on Object catch (error) {
    throw SgfFormatException(
      'Invalid $property coordinate "$value" for a ${size.dimension} line board: $error',
      source,
      0,
    );
  }
}

String? _singleValue(SgfNode node, String identifier, String source) {
  final property = node[identifier];
  if (property == null) return null;
  if (property.values.length != 1) {
    throw SgfFormatException(
      '$identifier must contain exactly one value.',
      source,
      0,
    );
  }
  return property.values.single;
}

void _validateSingleValue(SgfNode node, String identifier, String source) {
  _singleValue(node, identifier, source);
}

int _parseInteger(String value, String property, String source) {
  final parsed = int.tryParse(value);
  if (parsed == null) {
    throw SgfFormatException(
      '$property must be an integer, found "$value".',
      source,
      0,
    );
  }
  return parsed;
}

int _parsePositiveInteger(String value, String property, String source) {
  final parsed = _parseInteger(value, property, source);
  if (parsed < 1) {
    throw SgfFormatException(
      '$property must be positive, found "$value".',
      source,
      0,
    );
  }
  return parsed;
}

double _parseFiniteDouble(String value, String property, String source) {
  final parsed = double.tryParse(value);
  if (parsed == null || !parsed.isFinite) {
    throw SgfFormatException(
      '$property must be finite, found "$value".',
      source,
      0,
    );
  }
  return parsed;
}

BoardSize _boardSize(int value, String source) {
  try {
    return BoardSize.fromDimension(value);
  } on ArgumentError catch (error) {
    throw SgfFormatException(
      error.message?.toString() ?? 'Unsupported board size.',
      source,
      0,
    );
  }
}

String _rulesName(RuleSet rules) => switch (rules) {
  RuleSet.chinese => 'Chinese',
  RuleSet.japanese => 'Japanese',
  RuleSet.korean => 'Korean',
  RuleSet.aga => 'AGA',
  RuleSet.newZealand => 'New Zealand',
  RuleSet.trompTaylor => 'Tromp-Taylor',
};

String _formatNumber(double value) {
  final integer = value.toInt();
  return value == integer ? integer.toString() : value.toString();
}

String _formatDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _formatResult(GameResult result) => switch (result.type) {
  ResultType.draw => '0',
  ResultType.voided => 'Void',
  ResultType.unknown => '?',
  ResultType.blackWin || ResultType.whiteWin =>
    '${result.type == ResultType.blackWin ? 'B' : 'W'}+'
        '${result.margin != null ? _formatNumber(result.margin!) : _resultReason(result.reason)}',
};

String _resultReason(String? reason) => switch (reason?.toLowerCase()) {
  'resign' => 'R',
  'time' => 'T',
  'forfeit' => 'F',
  final value? when value.isNotEmpty => value,
  _ => '?',
};

final class _SgfWriter {
  String writeTree(SgfGameTree tree) {
    final buffer = StringBuffer('(');
    for (final node in tree.sequence) {
      buffer.write(';');
      for (final property in node.properties.values) {
        buffer.write(property.identifier);
        for (final value in property.values) {
          buffer
            ..write('[')
            ..write(_escape(value))
            ..write(']');
        }
      }
    }
    for (final variation in tree.variations) {
      buffer.write(writeTree(variation));
    }
    buffer.write(')');
    return buffer.toString();
  }

  String _escape(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll(']', '\\]')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');
}
