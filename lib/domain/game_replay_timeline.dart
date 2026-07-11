import 'go_values.dart';
import 'kifu_document.dart';

/// Immutable, capture-correct board positions for a verified game.
///
/// Position zero is the initial board and position N is the board after N
/// moves. The timeline reuses the rule validation performed when the verified
/// record was constructed, avoiding a second rules implementation drifting
/// from the trust boundary.
final class GameReplayTimeline {
  GameReplayTimeline.fromRecord(VerifiedGameRecord record)
    : recordId = record.id,
      moves = List<Move>.unmodifiable(record.moves),
      positions = List<BoardPosition>.unmodifiable(
        record.validation.positions,
      ) {
    if (positions.length != moves.length + 1) {
      throw StateError(
        'A verified game timeline must contain the root and every move.',
      );
    }
    if (positions.first != record.initialPosition ||
        positions.last != record.finalPosition) {
      throw StateError('Verified timeline endpoints do not match the record.');
    }
  }

  final String recordId;
  final List<Move> moves;
  final List<BoardPosition> positions;

  int get totalMoves => moves.length;

  /// Returns the position after [moveNumber] moves, where zero is the root.
  BoardPosition positionAt(int moveNumber) {
    if (moveNumber < 0 || moveNumber > totalMoves) {
      throw RangeError.range(moveNumber, 0, totalMoves, 'moveNumber');
    }
    return positions[moveNumber];
  }

  /// Returns the position in which the one-based [moveNumber] was selected.
  BoardPosition positionBeforeMove(int moveNumber) {
    if (moveNumber < 1 || moveNumber > totalMoves) {
      throw RangeError.range(moveNumber, 1, totalMoves, 'moveNumber');
    }
    return positions[moveNumber - 1];
  }

  /// Returns the one-based move at [moveNumber].
  Move moveAt(int moveNumber) {
    if (moveNumber < 1 || moveNumber > totalMoves) {
      throw RangeError.range(moveNumber, 1, totalMoves, 'moveNumber');
    }
    return moves[moveNumber - 1];
  }
}
