import 'go_values.dart';
import 'rule_validator.dart';
import 'sgf_values.dart';

enum KifuSourceKind {
  localFile,
  shareSheet,
  camera,
  photoLibrary,
  fox,
  ogs,
  fixture,
}

final class KifuSource {
  const KifuSource({required this.kind, this.reference});

  final KifuSourceKind kind;
  final String? reference;
}

/// A document's concrete subtype is a product-level trust boundary.
///
/// A still photo is a [PositionSnapshot], a recoverable fragment is a
/// [PartialGameRecord], and only a fully rule-checked sequence can become a
/// [VerifiedGameRecord].
sealed class KifuDocument {
  const KifuDocument({
    required this.id,
    required this.rules,
    required this.source,
    required this.metadata,
    this.sourceSgf,
  }) : assert(id != '');

  final String id;
  final GoRules rules;
  final KifuSource source;
  final GameMetadata metadata;
  final SgfGameTree? sourceSgf;

  BoardSize get boardSize;
}

final class PositionSnapshot extends KifuDocument {
  PositionSnapshot({
    required super.id,
    required this.position,
    required super.rules,
    required super.source,
    super.metadata = const GameMetadata(),
    super.sourceSgf,
    this.playerToMove,
  });

  final BoardPosition position;

  /// Null unless the source or user explicitly establishes who plays next.
  final StoneColor? playerToMove;

  @override
  BoardSize get boardSize => position.size;
}

final class PartialGameRecord extends KifuDocument {
  PartialGameRecord({
    required super.id,
    required this.initialPosition,
    required List<Move> moves,
    required super.rules,
    required super.source,
    super.metadata = const GameMetadata(),
    super.sourceSgf,
    this.startingMoveNumber = 1,
    this.firstPlayer = StoneColor.black,
  }) : moves = List.unmodifiable(moves) {
    if (startingMoveNumber < 1) {
      throw ArgumentError.value(
        startingMoveNumber,
        'startingMoveNumber',
        'Move numbers start at one.',
      );
    }
    for (final move in moves) {
      if (!move.isPass && !move.point!.isOn(initialPosition.size)) {
        throw RangeError(
          'Partial record contains an out-of-range move: $move.',
        );
      }
    }
  }

  final BoardPosition initialPosition;
  final List<Move> moves;
  final int startingMoveNumber;
  final StoneColor firstPlayer;

  @override
  BoardSize get boardSize => initialPosition.size;
}

final class VerifiedGameRecord extends KifuDocument {
  factory VerifiedGameRecord({
    required String id,
    required BoardPosition initialPosition,
    required List<Move> moves,
    required GoRules rules,
    required KifuSource source,
    GameMetadata metadata = const GameMetadata(),
    SgfGameTree? sourceSgf,
    StoneColor firstPlayer = StoneColor.black,
  }) {
    if (moves.isEmpty) {
      throw ArgumentError.value(
        moves,
        'moves',
        'A verified game must contain at least one move.',
      );
    }
    final immutableMoves = List<Move>.unmodifiable(moves);
    final validation = GoRuleValidator.validate(
      initialPosition: initialPosition,
      moves: immutableMoves,
      rules: rules,
      firstPlayer: firstPlayer,
    );
    if (!validation.isValid) throw RuleValidationException(validation);
    return VerifiedGameRecord._(
      id: id,
      initialPosition: initialPosition,
      moves: immutableMoves,
      rules: rules,
      source: source,
      metadata: metadata,
      sourceSgf: sourceSgf,
      firstPlayer: firstPlayer,
      validation: validation,
    );
  }

  const VerifiedGameRecord._({
    required super.id,
    required this.initialPosition,
    required this.moves,
    required super.rules,
    required super.source,
    required super.metadata,
    required this.firstPlayer,
    required this.validation,
    super.sourceSgf,
  });

  final BoardPosition initialPosition;
  final List<Move> moves;
  final StoneColor firstPlayer;
  final RuleValidationResult validation;

  BoardPosition get finalPosition => validation.finalPosition;

  @override
  BoardSize get boardSize => initialPosition.size;
}
