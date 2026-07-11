enum RankKind { kyu, dan }

/// Comparable amateur Go rank. Ordering is weakest to strongest.
final class GoRank implements Comparable<GoRank> {
  const GoRank._(this.kind, this.value);

  factory GoRank.kyu(int value) {
    if (value < 1 || value > 30) {
      throw RangeError.range(value, 1, 30, 'value');
    }
    return GoRank._(RankKind.kyu, value);
  }

  factory GoRank.dan(int value) {
    if (value < 1 || value > 9) {
      throw RangeError.range(value, 1, 9, 'value');
    }
    return GoRank._(RankKind.dan, value);
  }

  final RankKind kind;
  final int value;

  int get _strength => switch (kind) {
    RankKind.kyu => 30 - value,
    RankKind.dan => 29 + value,
  };

  String get label => kind == RankKind.kyu ? '${value}k' : '${value}d';

  @override
  int compareTo(GoRank other) => _strength.compareTo(other._strength);

  @override
  bool operator ==(Object other) =>
      other is GoRank && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);

  @override
  String toString() => label;
}
