import 'package:lizzieyzy_mobile/domain/domain.dart';

enum SequenceSolveErrorCode {
  empty,
  tooManyMoves,
  duplicateMoveNumber,
  missingMoveNumber,
  uncertainToken,
  wrongColor,
  illegalSequence,
}

final class SequenceSolveException implements FormatException {
  const SequenceSolveException(this.code, this.message, {this.moveNumber});

  final SequenceSolveErrorCode code;
  @override
  final String message;
  final int? moveNumber;

  @override
  dynamic get source => null;

  @override
  int? get offset => null;

  @override
  String toString() =>
      'SequenceSolveException(${code.name}${moveNumber == null ? '' : ', move $moveNumber'}): $message';
}

/// Promotes OCR tokens to a verified game only after strict numbering, color,
/// and Go-rule validation. No heuristic can bypass the document trust type.
final class RuleCheckedSequenceSolver implements SequenceSolver {
  const RuleCheckedSequenceSolver({
    this.maximumMoves = 999,
    this.minimumTokenConfidence = 0.9,
  });

  final int maximumMoves;
  final double minimumTokenConfidence;

  @override
  Future<KifuDocument> solve(
    List<SequenceToken> tokens,
    GoRules rules, {
    required String documentId,
    required BoardSize boardSize,
    required KifuSource source,
    BoardPosition? initialPosition,
  }) async {
    if (maximumMoves < 40 || maximumMoves > 9999) {
      throw ArgumentError.value(maximumMoves, 'maximumMoves');
    }
    if (!minimumTokenConfidence.isFinite ||
        minimumTokenConfidence < 0 ||
        minimumTokenConfidence > 1) {
      throw RangeError.range(minimumTokenConfidence, 0, 1);
    }
    if (tokens.isEmpty) {
      throw const SequenceSolveException(
        SequenceSolveErrorCode.empty,
        'No numbered moves were recognized.',
      );
    }
    if (tokens.length > maximumMoves) {
      throw SequenceSolveException(
        SequenceSolveErrorCode.tooManyMoves,
        'The diagram exceeds the $maximumMoves-move safety limit.',
      );
    }
    final sorted = List<SequenceToken>.of(tokens)
      ..sort((left, right) => left.moveNumber.compareTo(right.moveNumber));
    final numbers = <int>{};
    for (final token in sorted) {
      token.validate();
      if (!numbers.add(token.moveNumber)) {
        throw SequenceSolveException(
          SequenceSolveErrorCode.duplicateMoveNumber,
          'Move ${token.moveNumber} appears more than once.',
          moveNumber: token.moveNumber,
        );
      }
      if (token.confidence < minimumTokenConfidence) {
        throw SequenceSolveException(
          SequenceSolveErrorCode.uncertainToken,
          'Move ${token.moveNumber} requires confirmation.',
          moveNumber: token.moveNumber,
        );
      }
    }
    for (var index = 0; index < sorted.length; index++) {
      final expectedNumber = index + 1;
      final token = sorted[index];
      if (token.moveNumber != expectedNumber) {
        throw SequenceSolveException(
          SequenceSolveErrorCode.missingMoveNumber,
          'Move $expectedNumber is missing.',
          moveNumber: expectedNumber,
        );
      }
      final expectedColor = expectedNumber.isOdd
          ? StoneColor.black
          : StoneColor.white;
      if (token.move.color != expectedColor) {
        throw SequenceSolveException(
          SequenceSolveErrorCode.wrongColor,
          'Move $expectedNumber has the wrong stone color.',
          moveNumber: expectedNumber,
        );
      }
    }
    final root = initialPosition ?? BoardPosition.empty(boardSize);
    if (root.size != boardSize) {
      throw ArgumentError('Initial position and declared board size differ.');
    }
    final moves = sorted.map((token) => token.move).toList(growable: false);
    final validation = GoRuleValidator.validate(
      initialPosition: root,
      moves: moves,
      rules: rules,
    );
    if (!validation.isValid) {
      final violation = validation.violations.first;
      throw SequenceSolveException(
        SequenceSolveErrorCode.illegalSequence,
        violation.message,
        moveNumber: violation.moveIndex + 1,
      );
    }
    return VerifiedGameRecord(
      id: documentId,
      initialPosition: root,
      moves: moves,
      rules: rules,
      source: source,
    );
  }
}
