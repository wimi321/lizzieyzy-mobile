import 'go_values.dart';
import 'kifu_document.dart';
import 'rank_values.dart';

enum AnalysisProfile { quick, standard, deep }

final class AnalysisSettings {
  const AnalysisSettings({
    required this.profile,
    required this.visitsPerMove,
    this.criticalMoveVisits,
    this.maxCandidates = 3,
    this.includeOwnership = true,
  }) : assert(visitsPerMove > 0),
       assert(
         criticalMoveVisits == null || criticalMoveVisits >= visitsPerMove,
       ),
       assert(maxCandidates > 0);

  final AnalysisProfile profile;
  final int visitsPerMove;
  final int? criticalMoveVisits;
  final int maxCandidates;
  final bool includeOwnership;
}

final class ModelManifest {
  ModelManifest({
    required this.id,
    required this.displayName,
    required this.sha256,
    required this.engineVersion,
    required this.modelVersion,
    required this.license,
    this.source,
    List<GoRank> humanStyleRanks = const [],
  }) : humanStyleRanks = List.unmodifiable(humanStyleRanks) {
    if (id.trim().isEmpty || displayName.trim().isEmpty) {
      throw ArgumentError('Model id and display name cannot be empty.');
    }
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(sha256)) {
      throw const FormatException(
        'Model SHA-256 must contain 64 hexadecimal characters.',
      );
    }
    if (license.trim().isEmpty) {
      throw ArgumentError.value(
        license,
        'license',
        'A model license is required.',
      );
    }
  }

  final String id;
  final String displayName;
  final String sha256;
  final String engineVersion;
  final String modelVersion;
  final String license;
  final Uri? source;
  final List<GoRank> humanStyleRanks;
}

final class Candidate {
  Candidate({
    required this.move,
    required this.winRate,
    required this.scoreLead,
    required this.visits,
    required this.policy,
    List<Move> principalVariation = const [],
  }) : principalVariation = List.unmodifiable(principalVariation) {
    _checkProbability(winRate, 'winRate');
    _checkProbability(policy, 'policy');
    if (!scoreLead.isFinite) {
      throw ArgumentError.value(
        scoreLead,
        'scoreLead',
        'Score lead must be finite.',
      );
    }
    if (visits < 0) {
      throw ArgumentError.value(visits, 'visits', 'Visits cannot be negative.');
    }
  }

  final Move move;

  /// Win rate for the player whose turn it is in the analyzed position.
  final double winRate;

  /// Score lead in points from Black's perspective.
  final double scoreLead;
  final int visits;
  final double policy;
  final List<Move> principalVariation;
}

final class MoveAnalysis {
  MoveAnalysis({
    required this.moveNumber,
    required this.toPlay,
    required this.playedMove,
    required this.blackWinRate,
    required this.scoreLead,
    required this.visits,
    required List<Candidate> candidates,
    this.playedMovePointLoss,
    this.playedMoveWinRateLoss,
    List<double> ownership = const [],
  }) : candidates = List.unmodifiable(candidates),
       ownership = List.unmodifiable(ownership) {
    if (moveNumber < 0) {
      throw ArgumentError.value(
        moveNumber,
        'moveNumber',
        'Move number cannot be negative.',
      );
    }
    if ((moveNumber == 0) != (playedMove == null)) {
      throw ArgumentError(
        'Only root analysis (move 0) may omit the played move.',
      );
    }
    _checkProbability(blackWinRate, 'blackWinRate');
    if (!scoreLead.isFinite) {
      throw ArgumentError.value(
        scoreLead,
        'scoreLead',
        'Score lead must be finite.',
      );
    }
    if (visits < 0) {
      throw ArgumentError.value(visits, 'visits', 'Visits cannot be negative.');
    }
    if (playedMovePointLoss != null &&
        (!playedMovePointLoss!.isFinite || playedMovePointLoss! < 0)) {
      throw ArgumentError.value(
        playedMovePointLoss,
        'playedMovePointLoss',
        'Point loss must be finite and non-negative.',
      );
    }
    if (playedMoveWinRateLoss != null) {
      _checkProbability(playedMoveWinRateLoss!, 'playedMoveWinRateLoss');
    }
    for (final value in ownership) {
      if (!value.isFinite || value < -1 || value > 1) {
        throw RangeError.range(value, -1, 1, 'ownership');
      }
    }
  }

  final int moveNumber;
  final StoneColor toPlay;
  final Move? playedMove;
  final double blackWinRate;
  final double scoreLead;
  final int visits;
  final List<Candidate> candidates;
  final double? playedMovePointLoss;
  final double? playedMoveWinRateLoss;
  final List<double> ownership;
}

final class AnalysisBundle {
  AnalysisBundle({
    required this.requestId,
    required this.documentId,
    required this.boardSize,
    required this.model,
    required this.settings,
    required List<MoveAnalysis> moves,
    required this.completedAt,
  }) : moves = List.unmodifiable(moves) {
    if (requestId.trim().isEmpty || documentId.trim().isEmpty) {
      throw ArgumentError('Analysis and document ids cannot be empty.');
    }
    var previousMove = -1;
    for (final analysis in moves) {
      if (analysis.moveNumber <= previousMove) {
        throw ArgumentError(
          'Move analyses must be unique and sorted by move number.',
        );
      }
      if (analysis.ownership.isNotEmpty &&
          analysis.ownership.length !=
              boardSize.dimension * boardSize.dimension) {
        throw ArgumentError(
          'Ownership arrays must contain one value per board intersection.',
        );
      }
      previousMove = analysis.moveNumber;
    }
  }

  final String requestId;
  final String documentId;
  final BoardSize boardSize;
  final ModelManifest model;
  final AnalysisSettings settings;
  final List<MoveAnalysis> moves;
  final DateTime completedAt;

  MoveAnalysis? analysisAt(int moveNumber) {
    for (final analysis in moves) {
      if (analysis.moveNumber == moveNumber) return analysis;
    }
    return null;
  }
}

final class AnalysisRequest {
  const AnalysisRequest({
    required this.requestId,
    required this.document,
    required this.settings,
  }) : assert(requestId != '');

  final String requestId;
  final KifuDocument document;
  final AnalysisSettings settings;
}

sealed class AnalysisEvent {
  const AnalysisEvent(this.requestId);

  final String requestId;
}

final class AnalysisStarted extends AnalysisEvent {
  const AnalysisStarted(super.requestId, {required this.totalPositions});

  final int totalPositions;
}

final class PositionAnalyzed extends AnalysisEvent {
  const PositionAnalyzed(
    super.requestId, {
    required this.analysis,
    required this.completedPositions,
    required this.totalPositions,
  });

  final MoveAnalysis analysis;
  final int completedPositions;
  final int totalPositions;
}

final class AnalysisCompleted extends AnalysisEvent {
  const AnalysisCompleted(super.requestId, {required this.bundle});

  final AnalysisBundle bundle;
}

final class AnalysisCancelled extends AnalysisEvent {
  const AnalysisCancelled(super.requestId);
}

final class AnalysisFailed extends AnalysisEvent {
  const AnalysisFailed(
    super.requestId, {
    required this.code,
    required this.message,
    this.isRetryable = false,
  });

  final String code;
  final String message;
  final bool isRetryable;
}

void _checkProbability(double value, String name) {
  if (!value.isFinite || value < 0 || value > 1) {
    throw RangeError.range(value, 0, 1, name);
  }
}
