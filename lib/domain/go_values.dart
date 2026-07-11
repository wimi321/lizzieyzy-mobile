/// Core, UI-independent value objects for Go positions and records.
enum StoneColor {
  black,
  white;

  StoneColor get opponent => this == black ? white : black;

  String get sgfValue => this == black ? 'B' : 'W';
}

enum BoardSize {
  nine(9),
  thirteen(13),
  nineteen(19);

  const BoardSize(this.dimension);

  final int dimension;

  factory BoardSize.fromDimension(int dimension) => switch (dimension) {
    9 => BoardSize.nine,
    13 => BoardSize.thirteen,
    19 => BoardSize.nineteen,
    _ => throw ArgumentError.value(
      dimension,
      'dimension',
      'Only 9, 13, and 19 line boards are supported.',
    ),
  };
}

/// Zero-based board coordinate: [column] grows left-to-right and [row]
/// grows top-to-bottom.
final class BoardPoint implements Comparable<BoardPoint> {
  const BoardPoint(this.column, this.row)
    : assert(column >= 0),
      assert(row >= 0);

  final int column;
  final int row;

  bool isOn(BoardSize size) =>
      column >= 0 &&
      row >= 0 &&
      column < size.dimension &&
      row < size.dimension;

  /// Human-facing coordinates omit I, following common Go notation.
  String toGtp(BoardSize size) {
    if (!isOn(size)) {
      throw RangeError(
        'Point $this is outside a ${size.dimension}x${size.dimension} board.',
      );
    }
    final letterCode = 'A'.codeUnitAt(0) + column + (column >= 8 ? 1 : 0);
    return '${String.fromCharCode(letterCode)}${size.dimension - row}';
  }

  @override
  int compareTo(BoardPoint other) {
    final rowOrder = row.compareTo(other.row);
    return rowOrder != 0 ? rowOrder : column.compareTo(other.column);
  }

  @override
  bool operator ==(Object other) =>
      other is BoardPoint && other.column == column && other.row == row;

  @override
  int get hashCode => Object.hash(column, row);

  @override
  String toString() => 'BoardPoint($column, $row)';
}

sealed class Move {
  const Move._(this.color);

  const factory Move.play({
    required StoneColor color,
    required BoardPoint point,
  }) = _PlayMove;

  const factory Move.pass({required StoneColor color}) = _PassMove;

  final StoneColor color;
  BoardPoint? get point;

  bool get isPass => point == null;

  @override
  bool operator ==(Object other) =>
      other is Move && other.color == color && other.point == point;

  @override
  int get hashCode => Object.hash(color, point);

  @override
  String toString() => isPass ? '${color.name}:pass' : '${color.name}:$point';
}

final class _PlayMove extends Move {
  const _PlayMove({required StoneColor color, required this.point})
    : super._(color);

  @override
  final BoardPoint point;
}

final class _PassMove extends Move {
  const _PassMove({required StoneColor color}) : super._(color);

  @override
  BoardPoint? get point => null;
}

enum RuleSet { chinese, japanese, korean, aga, newZealand, trompTaylor }

enum KoRule { simple, positionalSuperko, situationalSuperko }

final class GoRules {
  const GoRules({
    required this.ruleSet,
    required this.komi,
    required this.koRule,
    required this.allowSuicide,
  });

  const GoRules.chinese({double komi = 7.5})
    : this(
        ruleSet: RuleSet.chinese,
        komi: komi,
        koRule: KoRule.positionalSuperko,
        allowSuicide: false,
      );

  const GoRules.japanese({double komi = 6.5})
    : this(
        ruleSet: RuleSet.japanese,
        komi: komi,
        koRule: KoRule.simple,
        allowSuicide: false,
      );

  final RuleSet ruleSet;
  final double komi;
  final KoRule koRule;
  final bool allowSuicide;

  @override
  bool operator ==(Object other) =>
      other is GoRules &&
      other.ruleSet == ruleSet &&
      other.komi == komi &&
      other.koRule == koRule &&
      other.allowSuicide == allowSuicide;

  @override
  int get hashCode => Object.hash(ruleSet, komi, koRule, allowSuicide);
}

final class BoardPosition {
  BoardPosition({
    required this.size,
    Map<BoardPoint, StoneColor> stones = const {},
  }) : stones = Map.unmodifiable(stones) {
    final outside = stones.keys.where((point) => !point.isOn(size));
    if (outside.isNotEmpty) {
      throw RangeError('Board contains out-of-range point ${outside.first}.');
    }
  }

  factory BoardPosition.empty(BoardSize size) => BoardPosition(size: size);

  final BoardSize size;
  final Map<BoardPoint, StoneColor> stones;

  StoneColor? stoneAt(BoardPoint point) => stones[point];

  int count(StoneColor color) =>
      stones.values.where((stone) => stone == color).length;

  /// Stable, compact identity used by the rule validator for ko checks.
  String get signature {
    final buffer = StringBuffer();
    for (var row = 0; row < size.dimension; row++) {
      for (var column = 0; column < size.dimension; column++) {
        buffer.write(switch (stoneAt(BoardPoint(column, row))) {
          StoneColor.black => 'B',
          StoneColor.white => 'W',
          null => '.',
        });
      }
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (other is! BoardPosition ||
        other.size != size ||
        other.stones.length != stones.length) {
      return false;
    }
    for (final entry in stones.entries) {
      if (other.stones[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    var entriesHash = 0;
    for (final entry in stones.entries) {
      entriesHash ^= Object.hash(entry.key, entry.value);
    }
    return Object.hash(size, entriesHash);
  }

  @override
  String toString() =>
      'BoardPosition(${size.dimension}x${size.dimension}, ${stones.length} stones)';
}

final class GameMetadata {
  const GameMetadata({
    this.blackPlayer,
    this.whitePlayer,
    this.event,
    this.playedAt,
    this.result,
  });

  final String? blackPlayer;
  final String? whitePlayer;
  final String? event;
  final DateTime? playedAt;
  final GameResult? result;
}

enum ResultType { blackWin, whiteWin, draw, voided, unknown }

final class GameResult {
  const GameResult({required this.type, this.margin, this.reason})
    : assert(margin == null || margin >= 0);

  final ResultType type;
  final double? margin;
  final String? reason;
}
