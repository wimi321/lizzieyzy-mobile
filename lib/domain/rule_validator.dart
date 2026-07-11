import 'go_values.dart';

enum RuleViolationCode { wrongTurn, outOfBounds, occupied, suicide, ko }

final class RuleViolation {
  const RuleViolation({
    required this.moveIndex,
    required this.code,
    required this.message,
  });

  /// Zero-based index into the submitted move sequence.
  final int moveIndex;
  final RuleViolationCode code;
  final String message;
}

final class RuleValidationResult {
  RuleValidationResult({
    required this.finalPosition,
    required List<RuleViolation> violations,
    required this.blackCaptured,
    required this.whiteCaptured,
  }) : violations = List.unmodifiable(violations);

  final BoardPosition finalPosition;
  final List<RuleViolation> violations;

  /// Number of stones of each color removed from the board.
  final int blackCaptured;
  final int whiteCaptured;

  bool get isValid => violations.isEmpty;
}

final class RuleValidationException implements FormatException {
  RuleValidationException(this.result);

  final RuleValidationResult result;

  @override
  String get message => result.violations
      .map(
        (violation) => 'Move ${violation.moveIndex + 1}: ${violation.message}',
      )
      .join('; ');

  @override
  dynamic get source => null;

  @override
  int? get offset => null;

  @override
  String toString() => 'RuleValidationException: $message';
}

abstract final class GoRuleValidator {
  static RuleValidationResult validate({
    required BoardPosition initialPosition,
    required List<Move> moves,
    required GoRules rules,
    StoneColor firstPlayer = StoneColor.black,
  }) {
    var board = Map<BoardPoint, StoneColor>.of(initialPosition.stones);
    var expectedColor = firstPlayer;
    var blackCaptured = 0;
    var whiteCaptured = 0;

    final positionHistory = <String>[initialPosition.signature];
    final situationHistory = <String>{
      '${initialPosition.signature}|${firstPlayer.name}',
    };

    RuleValidationResult invalid(
      int moveIndex,
      RuleViolationCode code,
      String message,
    ) => RuleValidationResult(
      finalPosition: BoardPosition(size: initialPosition.size, stones: board),
      violations: [
        RuleViolation(moveIndex: moveIndex, code: code, message: message),
      ],
      blackCaptured: blackCaptured,
      whiteCaptured: whiteCaptured,
    );

    for (var index = 0; index < moves.length; index++) {
      final move = moves[index];
      if (move.color != expectedColor) {
        return invalid(
          index,
          RuleViolationCode.wrongTurn,
          'Expected ${expectedColor.name}, received ${move.color.name}.',
        );
      }

      if (move.isPass) {
        expectedColor = expectedColor.opponent;
        final signature = _signature(initialPosition.size, board);
        positionHistory.add(signature);
        situationHistory.add('$signature|${expectedColor.name}');
        continue;
      }

      final point = move.point!;
      if (!point.isOn(initialPosition.size)) {
        return invalid(
          index,
          RuleViolationCode.outOfBounds,
          '$point is outside the board.',
        );
      }
      if (board.containsKey(point)) {
        return invalid(
          index,
          RuleViolationCode.occupied,
          '$point is already occupied.',
        );
      }

      final candidate = Map<BoardPoint, StoneColor>.of(board)
        ..[point] = move.color;
      var capturedThisMove = 0;
      final inspectedOpponent = <BoardPoint>{};
      for (final neighbor in _neighbors(point, initialPosition.size)) {
        if (candidate[neighbor] != move.color.opponent ||
            inspectedOpponent.contains(neighbor)) {
          continue;
        }
        final group = _groupAt(neighbor, candidate, initialPosition.size);
        inspectedOpponent.addAll(group);
        if (!_hasLiberty(group, candidate, initialPosition.size)) {
          capturedThisMove += group.length;
          for (final capturedPoint in group) {
            candidate.remove(capturedPoint);
          }
        }
      }

      final ownGroup = _groupAt(point, candidate, initialPosition.size);
      if (!_hasLiberty(ownGroup, candidate, initialPosition.size)) {
        if (!rules.allowSuicide) {
          return invalid(
            index,
            RuleViolationCode.suicide,
            'The move has no liberties and captures no adjacent group.',
          );
        }
        for (final ownPoint in ownGroup) {
          candidate.remove(ownPoint);
        }
      }

      final signature = _signature(initialPosition.size, candidate);
      final nextPlayer = expectedColor.opponent;
      final repeats = switch (rules.koRule) {
        KoRule.simple =>
          positionHistory.length >= 2 &&
              signature == positionHistory[positionHistory.length - 2],
        KoRule.positionalSuperko => positionHistory.contains(signature),
        KoRule.situationalSuperko => situationHistory.contains(
          '$signature|${nextPlayer.name}',
        ),
      };
      if (repeats) {
        return invalid(
          index,
          RuleViolationCode.ko,
          'The move repeats a forbidden earlier board position.',
        );
      }

      board = candidate;
      if (move.color == StoneColor.black) {
        whiteCaptured += capturedThisMove;
      } else {
        blackCaptured += capturedThisMove;
      }
      expectedColor = nextPlayer;
      positionHistory.add(signature);
      situationHistory.add('$signature|${expectedColor.name}');
    }

    return RuleValidationResult(
      finalPosition: BoardPosition(size: initialPosition.size, stones: board),
      violations: const [],
      blackCaptured: blackCaptured,
      whiteCaptured: whiteCaptured,
    );
  }

  static Set<BoardPoint> _groupAt(
    BoardPoint start,
    Map<BoardPoint, StoneColor> board,
    BoardSize size,
  ) {
    final color = board[start];
    if (color == null) return const {};
    final group = <BoardPoint>{};
    final pending = <BoardPoint>[start];
    while (pending.isNotEmpty) {
      final point = pending.removeLast();
      if (!group.add(point)) continue;
      for (final neighbor in _neighbors(point, size)) {
        if (board[neighbor] == color && !group.contains(neighbor)) {
          pending.add(neighbor);
        }
      }
    }
    return group;
  }

  static bool _hasLiberty(
    Set<BoardPoint> group,
    Map<BoardPoint, StoneColor> board,
    BoardSize size,
  ) => group.any(
    (point) =>
        _neighbors(point, size).any((neighbor) => board[neighbor] == null),
  );

  static Iterable<BoardPoint> _neighbors(
    BoardPoint point,
    BoardSize size,
  ) sync* {
    if (point.column > 0) yield BoardPoint(point.column - 1, point.row);
    if (point.column + 1 < size.dimension) {
      yield BoardPoint(point.column + 1, point.row);
    }
    if (point.row > 0) yield BoardPoint(point.column, point.row - 1);
    if (point.row + 1 < size.dimension) {
      yield BoardPoint(point.column, point.row + 1);
    }
  }

  static String _signature(BoardSize size, Map<BoardPoint, StoneColor> board) =>
      BoardPosition(size: size, stones: board).signature;
}
