import 'package:flutter/foundation.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';

@immutable
class KifuSummaryModel {
  const KifuSummaryModel({
    required this.blackPlayer,
    required this.whitePlayer,
    required this.result,
    required this.playedAt,
    required this.moveCount,
    required this.status,
    this.analysisProgress,
  });

  final String blackPlayer;
  final String whitePlayer;
  final String result;
  final String playedAt;
  final int moveCount;
  final String status;
  final double? analysisProgress;
}

@immutable
class ScanDisplayModel {
  const ScanDisplayModel({
    required this.blackStones,
    required this.whiteStones,
    required this.pendingPoints,
    required this.recognizedMove,
  });

  final int blackStones;
  final int whiteStones;
  final int pendingPoints;
  final int recognizedMove;
}

@immutable
class KeyMoveDisplayModel {
  const KeyMoveDisplayModel({
    required this.moveNumber,
    required this.playedMove,
    required this.bestMove,
    required this.scoreLoss,
    required this.winRateLoss,
    required this.winRate,
    required this.scoreLead,
    required this.visits,
    required this.stones,
    required this.candidates,
    required this.timelineKeyMoves,
  });

  final int moveNumber;
  final String playedMove;
  final String bestMove;
  final String scoreLoss;
  final String winRateLoss;
  final String winRate;
  final String scoreLead;
  final String visits;
  final List<BoardStone> stones;
  final List<BoardCandidate> candidates;
  final List<int> timelineKeyMoves;
}

@immutable
class AnalysisProgressDisplayModel {
  const AnalysisProgressDisplayModel({
    required this.completed,
    required this.total,
    required this.profile,
    required this.elapsed,
    required this.estimatedRemaining,
  });

  final int completed;
  final int total;
  final String profile;
  final String elapsed;
  final String estimatedRemaining;
}

@immutable
class PerformanceDisplayModel {
  const PerformanceDisplayModel({
    required this.lowerRank,
    required this.upperRank,
    required this.confidence,
    required this.effectiveDecisions,
    required this.averageLoss,
    required this.topThreeRate,
    required this.severeMistakeRate,
  });

  final String lowerRank;
  final String upperRank;
  final String confidence;
  final int effectiveDecisions;
  final String averageLoss;
  final String topThreeRate;
  final String severeMistakeRate;
}
