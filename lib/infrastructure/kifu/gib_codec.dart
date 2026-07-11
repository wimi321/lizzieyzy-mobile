import '../../domain/domain.dart';

enum GibImportWarningCode {
  malformedMetadata,
  moveNumberGap,
  invalidMove,
  ruleViolation,
}

final class GibImportWarning {
  const GibImportWarning({required this.code, required this.message});

  final GibImportWarningCode code;
  final String message;
}

final class GibImportResult {
  GibImportResult({
    required this.document,
    required List<GibImportWarning> warnings,
    this.blackRank,
    this.whiteRank,
  }) : warnings = List.unmodifiable(warnings);

  final KifuDocument document;
  final List<GibImportWarning> warnings;
  final String? blackRank;
  final String? whiteRank;

  bool get isVerifiedGame => document is VerifiedGameRecord;
}

/// Clean-room reader for the line-oriented Tygem GIB record format.
///
/// GIB has no stable public specification, so unsupported or contradictory
/// records are downgraded to [PartialGameRecord] instead of being guessed into
/// a verified game. Text decoding is intentionally the caller's responsibility
/// because legacy files may be UTF-8, CP949, Big5, or GBK.
final class GibCodec {
  const GibCodec();

  GibImportResult decode(
    String source, {
    required String documentId,
    KifuSource kifuSource = const KifuSource(kind: KifuSourceKind.localFile),
  }) {
    if (source.trim().isEmpty) {
      throw const FormatException('A GIB record cannot be empty.');
    }
    final warnings = <GibImportWarning>[];
    final tags = <String, String>{};
    final moves = <Move>[];
    final moveNumbers = <int>[];
    var handicap = 0;

    for (final rawLine in source.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      final tagMatch = RegExp(r'^\\\[([A-Z0-9_]+)=(.*)\\\]$').firstMatch(line);
      if (tagMatch != null) {
        tags[tagMatch.group(1)!] = tagMatch.group(2)!;
        continue;
      }
      if (line.startsWith('INI ')) {
        final fields = line.split(RegExp(r'\s+'));
        if (fields.length >= 4) {
          handicap = int.tryParse(fields[3]) ?? 0;
        }
        continue;
      }
      if (!line.startsWith('STO ')) continue;
      final fields = line.split(RegExp(r'\s+'));
      if (fields.length < 6) {
        warnings.add(
          GibImportWarning(
            code: GibImportWarningCode.invalidMove,
            message: 'Ignored malformed GIB move line: $line',
          ),
        );
        continue;
      }
      final number = int.tryParse(fields[2]);
      final colorCode = int.tryParse(fields[3]);
      final column = int.tryParse(fields[4]);
      final row = int.tryParse(fields[5]);
      if (number == null ||
          (colorCode != 1 && colorCode != 2) ||
          column == null ||
          row == null) {
        warnings.add(
          GibImportWarning(
            code: GibImportWarningCode.invalidMove,
            message: 'Ignored unparseable GIB move line: $line',
          ),
        );
        continue;
      }
      final color = colorCode == 1 ? StoneColor.black : StoneColor.white;
      final move = column < 0 && row < 0
          ? Move.pass(color: color)
          : Move.play(color: color, point: BoardPoint(column, row));
      if (!move.isPass && !move.point!.isOn(BoardSize.nineteen)) {
        warnings.add(
          GibImportWarning(
            code: GibImportWarningCode.invalidMove,
            message: 'Ignored out-of-board GIB move $number.',
          ),
        );
        continue;
      }
      moveNumbers.add(number);
      moves.add(move);
    }

    var numbersAreContinuous = true;
    for (var index = 1; index < moveNumbers.length; index++) {
      if (moveNumbers[index] != moveNumbers[index - 1] + 1) {
        numbersAreContinuous = false;
        break;
      }
    }
    if (!numbersAreContinuous) {
      warnings.add(
        const GibImportWarning(
          code: GibImportWarningCode.moveNumberGap,
          message: 'The GIB record contains a move-number gap.',
        ),
      );
    }

    final gameInfo = tags['GAMEINFOMAIN'] ?? '';
    final gameTag = tags['GAMETAG'] ?? '';
    final komiTenths =
        _namedInteger(gameInfo, 'GONGJE') ?? _compactInteger(gameTag, 'G');
    final komi = komiTenths == null ? 6.5 : komiTenths / 10;
    final rules = GoRules(
      ruleSet: RuleSet.korean,
      komi: komi,
      koRule: KoRule.simple,
      allowSuicide: false,
    );
    final black = _player(tags['GAMEBLACKNAME']);
    final white = _player(tags['GAMEWHITENAME']);
    final metadata = GameMetadata(
      blackPlayer: black.name,
      whitePlayer: white.name,
      event: _emptyToNull(tags['GAMENAME']),
      playedAt: _dateFrom(tags, warnings),
      result: _resultFrom(gameInfo, gameTag),
    );
    final initialPosition = BoardPosition(
      size: BoardSize.nineteen,
      stones: _handicapStones(handicap),
    );
    final firstPlayer = moves.isEmpty
        ? (handicap >= 2 ? StoneColor.white : StoneColor.black)
        : moves.first.color;

    late final KifuDocument document;
    if (moves.isEmpty) {
      document = PositionSnapshot(
        id: documentId,
        position: initialPosition,
        rules: rules,
        source: kifuSource,
        metadata: metadata,
        playerToMove: firstPlayer,
      );
    } else {
      final validation = GoRuleValidator.validate(
        initialPosition: initialPosition,
        moves: moves,
        rules: rules,
        firstPlayer: firstPlayer,
      );
      if (validation.isValid && numbersAreContinuous) {
        document = VerifiedGameRecord(
          id: documentId,
          initialPosition: initialPosition,
          moves: moves,
          rules: rules,
          source: kifuSource,
          metadata: metadata,
          firstPlayer: firstPlayer,
        );
      } else {
        if (!validation.isValid) {
          warnings.add(
            GibImportWarning(
              code: GibImportWarningCode.ruleViolation,
              message: validation.violations.first.message,
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
          startingMoveNumber: moveNumbers.isEmpty ? 1 : moveNumbers.first,
          firstPlayer: firstPlayer,
        );
      }
    }

    return GibImportResult(
      document: document,
      warnings: warnings,
      blackRank: black.rank,
      whiteRank: white.rank,
    );
  }
}

int? _namedInteger(String source, String key) {
  final match = RegExp('(?:^|,)$key:(-?\\d+)(?:,|\$)').firstMatch(source);
  return match == null ? null : int.tryParse(match.group(1)!);
}

int? _compactInteger(String source, String key) {
  final match = RegExp('(?:^|,)$key(-?\\d+)(?:,|\$)').firstMatch(source);
  return match == null ? null : int.tryParse(match.group(1)!);
}

({String? name, String? rank}) _player(String? raw) {
  if (raw == null || raw.trim().isEmpty) return (name: null, rank: null);
  final value = raw.trim();
  final match = RegExp(r'^(.*?)\(([^()]*)\)$').firstMatch(value);
  if (match == null) return (name: value, rank: null);
  return (
    name: _emptyToNull(match.group(1)?.trim()),
    rank: _emptyToNull(match.group(2)?.trim()),
  );
}

String? _emptyToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

DateTime? _dateFrom(Map<String, String> tags, List<GibImportWarning> warnings) {
  final info = tags['GAMEINFOSUB'] ?? '';
  final structured = RegExp(
    r'GDATE:(\d{4})-\s*(\d{1,2})-\s*(\d{1,2})',
  ).firstMatch(info);
  final compact = RegExp(
    r'C(\d{4}):(\d{2}):(\d{2})',
  ).firstMatch(tags['GAMETAG'] ?? '');
  final match = structured ?? compact;
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  try {
    final parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw const FormatException();
    }
    return parsed;
  } on FormatException {
    warnings.add(
      const GibImportWarning(
        code: GibImportWarningCode.malformedMetadata,
        message: 'The GIB game date is invalid and was ignored.',
      ),
    );
    return null;
  }
}

GameResult? _resultFrom(String gameInfo, String gameTag) {
  final resultCode =
      _namedInteger(gameInfo, 'GRLT') ?? _compactInteger(gameTag, 'W');
  final scoreTenths =
      _namedInteger(gameInfo, 'ZIPSU') ?? _compactInteger(gameTag, 'Z');
  return switch (resultCode) {
    0 => GameResult(
      type: ResultType.blackWin,
      margin: scoreTenths == null ? null : scoreTenths / 10,
    ),
    1 => GameResult(
      type: ResultType.whiteWin,
      margin: scoreTenths == null ? null : scoreTenths / 10,
    ),
    3 => const GameResult(type: ResultType.blackWin, reason: 'resignation'),
    4 => const GameResult(type: ResultType.whiteWin, reason: 'resignation'),
    7 => const GameResult(type: ResultType.blackWin, reason: 'timeout'),
    8 => const GameResult(type: ResultType.whiteWin, reason: 'timeout'),
    _ => null,
  };
}

Map<BoardPoint, StoneColor> _handicapStones(int handicap) {
  if (handicap < 2 || handicap > 9) return const <BoardPoint, StoneColor>{};
  const upperLeft = BoardPoint(3, 3);
  const upperRight = BoardPoint(15, 3);
  const lowerLeft = BoardPoint(3, 15);
  const lowerRight = BoardPoint(15, 15);
  const center = BoardPoint(9, 9);
  const middleLeft = BoardPoint(3, 9);
  const middleRight = BoardPoint(15, 9);
  const upperCenter = BoardPoint(9, 3);
  const lowerCenter = BoardPoint(9, 15);
  final points = switch (handicap) {
    2 => <BoardPoint>[lowerLeft, upperRight],
    3 => <BoardPoint>[lowerLeft, upperRight, lowerRight],
    4 => <BoardPoint>[lowerLeft, upperRight, lowerRight, upperLeft],
    5 => <BoardPoint>[lowerLeft, upperRight, lowerRight, upperLeft, center],
    6 => <BoardPoint>[
      lowerLeft,
      upperRight,
      lowerRight,
      upperLeft,
      middleLeft,
      middleRight,
    ],
    7 => <BoardPoint>[
      lowerLeft,
      upperRight,
      lowerRight,
      upperLeft,
      middleLeft,
      middleRight,
      center,
    ],
    8 => <BoardPoint>[
      lowerLeft,
      upperRight,
      lowerRight,
      upperLeft,
      middleLeft,
      middleRight,
      upperCenter,
      lowerCenter,
    ],
    _ => <BoardPoint>[
      lowerLeft,
      upperRight,
      lowerRight,
      upperLeft,
      middleLeft,
      middleRight,
      upperCenter,
      lowerCenter,
      center,
    ],
  };
  return <BoardPoint, StoneColor>{
    for (final point in points) point: StoneColor.black,
  };
}
