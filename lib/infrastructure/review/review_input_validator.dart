import 'package:lizzieyzy_mobile/domain/domain.dart';

enum ReviewInputErrorCode {
  unsupportedDocument,
  documentIdMismatch,
  boardSizeMismatch,
  incompleteAnalysis,
  moveMismatch,
  turnMismatch,
  insufficientVisits,
  invalidCandidates,
}

final class ReviewInputException implements FormatException {
  const ReviewInputException(this.code, this.message);

  final ReviewInputErrorCode code;

  @override
  final String message;

  @override
  dynamic get source => null;

  @override
  int? get offset => null;

  @override
  String toString() => 'ReviewInputException(${code.name}): $message';
}

/// One played move paired with the analysis before and after that decision.
final class ReviewDecisionEvidence {
  const ReviewDecisionEvidence({
    required this.moveNumber,
    required this.playedMove,
    required this.before,
    required this.after,
    required this.candidateRank,
  });

  final int moveNumber;
  final Move playedMove;
  final MoveAnalysis before;
  final MoveAnalysis after;

  /// One-based rank in the provider-reported candidate order, or null when
  /// the move is outside the reported candidate list.
  final int? candidateRank;

  double get pointLoss => after.playedMovePointLoss!;
}

final class ValidatedReviewInput {
  ValidatedReviewInput({
    required this.record,
    required this.analysis,
    required List<ReviewDecisionEvidence> decisions,
  }) : decisions = List.unmodifiable(decisions);

  final VerifiedGameRecord record;
  final AnalysisBundle analysis;
  final List<ReviewDecisionEvidence> decisions;
}

abstract final class ReviewInputValidator {
  static ValidatedReviewInput validate(
    KifuDocument document,
    AnalysisBundle analysis,
  ) {
    if (document is! VerifiedGameRecord) {
      throw const ReviewInputException(
        ReviewInputErrorCode.unsupportedDocument,
        'A complete review requires a VerifiedGameRecord.',
      );
    }
    return validateVerified(document, analysis);
  }

  static ValidatedReviewInput validateVerified(
    VerifiedGameRecord record,
    AnalysisBundle analysis,
  ) {
    if (analysis.documentId != record.id) {
      throw ReviewInputException(
        ReviewInputErrorCode.documentIdMismatch,
        'Analysis document "${analysis.documentId}" does not match "${record.id}".',
      );
    }
    if (analysis.boardSize != record.boardSize) {
      throw ReviewInputException(
        ReviewInputErrorCode.boardSizeMismatch,
        'Analysis board size does not match the verified game.',
      );
    }

    final expectedPositions = record.moves.length + 1;
    if (analysis.moves.length != expectedPositions) {
      throw ReviewInputException(
        ReviewInputErrorCode.incompleteAnalysis,
        'Expected $expectedPositions analyzed positions, received ${analysis.moves.length}.',
      );
    }

    final decisions = <ReviewDecisionEvidence>[];
    for (var index = 0; index < expectedPositions; index++) {
      final node = analysis.moves[index];
      if (node.moveNumber != index) {
        throw ReviewInputException(
          ReviewInputErrorCode.incompleteAnalysis,
          'Analysis is missing the position at move $index.',
        );
      }
      final expectedMove = index == 0 ? null : record.moves[index - 1];
      if (node.playedMove != expectedMove) {
        throw ReviewInputException(
          ReviewInputErrorCode.moveMismatch,
          'Analysis at move $index does not match the verified sequence.',
        );
      }
      final expectedToPlay = index == 0
          ? record.firstPlayer
          : record.moves[index - 1].color.opponent;
      if (node.toPlay != expectedToPlay) {
        throw ReviewInputException(
          ReviewInputErrorCode.turnMismatch,
          'Analysis at move $index reports the wrong player to move.',
        );
      }
      if (node.visits < analysis.settings.visitsPerMove) {
        throw ReviewInputException(
          ReviewInputErrorCode.insufficientVisits,
          'Analysis at move $index has ${node.visits} visits; '
          '${analysis.settings.visitsPerMove} are required.',
        );
      }
      if (index == 0 &&
          (node.playedMovePointLoss != null ||
              node.playedMoveWinRateLoss != null ||
              node.playedMovePolicy != null ||
              node.playedMoveHumanPolicy != null)) {
        throw const ReviewInputException(
          ReviewInputErrorCode.incompleteAnalysis,
          'Root analysis cannot contain played-move evidence.',
        );
      }
      if (index > 0 &&
          (node.playedMovePointLoss == null || node.playedMovePolicy == null)) {
        throw ReviewInputException(
          ReviewInputErrorCode.incompleteAnalysis,
          'Point loss or full-policy evidence is missing at move $index.',
        );
      }
      if (index < record.moves.length && node.candidates.isEmpty) {
        throw ReviewInputException(
          ReviewInputErrorCode.incompleteAnalysis,
          'Candidate analysis is missing before move ${index + 1}.',
        );
      }
      _validateCandidates(
        node,
        record.boardSize,
        position: record.validation.positions[index],
        rules: record.rules,
        maximumCandidates: analysis.settings.maxCandidates,
      );

      if (index > 0) {
        final before = analysis.moves[index - 1];
        final playedMove = record.moves[index - 1];
        final rankIndex = before.candidates.indexWhere(
          (candidate) => candidate.move == playedMove,
        );
        decisions.add(
          ReviewDecisionEvidence(
            moveNumber: index,
            playedMove: playedMove,
            before: before,
            after: node,
            candidateRank: rankIndex < 0 ? null : rankIndex + 1,
          ),
        );
      }
    }

    return ValidatedReviewInput(
      record: record,
      analysis: analysis,
      decisions: decisions,
    );
  }

  static void _validateCandidates(
    MoveAnalysis node,
    BoardSize boardSize, {
    required BoardPosition position,
    required GoRules rules,
    required int maximumCandidates,
  }) {
    if (node.candidates.length > maximumCandidates) {
      throw ReviewInputException(
        ReviewInputErrorCode.invalidCandidates,
        'Candidate list at move ${node.moveNumber} exceeds the configured '
        'maximum of $maximumCandidates.',
      );
    }
    final uniqueMoves = <Move>{};
    var previousVisits = node.visits;
    for (final candidate in node.candidates) {
      if (candidate.move.color != node.toPlay) {
        throw ReviewInputException(
          ReviewInputErrorCode.invalidCandidates,
          'Candidate color at move ${node.moveNumber} does not match to-play.',
        );
      }
      if (!candidate.move.isPass && !candidate.move.point!.isOn(boardSize)) {
        throw ReviewInputException(
          ReviewInputErrorCode.invalidCandidates,
          'Candidate at move ${node.moveNumber} is outside the board.',
        );
      }
      if (!uniqueMoves.add(candidate.move)) {
        throw ReviewInputException(
          ReviewInputErrorCode.invalidCandidates,
          'Candidate list at move ${node.moveNumber} contains duplicates.',
        );
      }
      if (candidate.visits > node.visits) {
        throw ReviewInputException(
          ReviewInputErrorCode.invalidCandidates,
          'Candidate at move ${node.moveNumber} has more visits than its '
          'analyzed position.',
        );
      }
      if (candidate.visits > previousVisits) {
        throw ReviewInputException(
          ReviewInputErrorCode.invalidCandidates,
          'Candidates at move ${node.moveNumber} are not ordered by visits.',
        );
      }
      final pv = candidate.principalVariation;
      if (pv.isNotEmpty) {
        if (pv.length > 64) {
          throw ReviewInputException(
            ReviewInputErrorCode.invalidCandidates,
            'Candidate PV at move ${node.moveNumber} exceeds 64 moves.',
          );
        }
        if (pv.first != candidate.move) {
          throw ReviewInputException(
            ReviewInputErrorCode.invalidCandidates,
            'Candidate PV at move ${node.moveNumber} does not begin with its candidate.',
          );
        }
        var expected = node.toPlay;
        for (final move in pv) {
          if (move.color != expected) {
            throw ReviewInputException(
              ReviewInputErrorCode.invalidCandidates,
              'Candidate PV at move ${node.moveNumber} has an invalid turn order.',
            );
          }
          expected = expected.opponent;
        }
      }
      final replay = GoRuleValidator.validate(
        initialPosition: position,
        moves: pv.isEmpty ? <Move>[candidate.move] : pv,
        rules: rules,
        firstPlayer: node.toPlay,
      );
      if (!replay.isValid) {
        throw ReviewInputException(
          ReviewInputErrorCode.invalidCandidates,
          'Candidate or PV at move ${node.moveNumber} is illegal.',
        );
      }
      previousVisits = candidate.visits;
    }
  }
}
