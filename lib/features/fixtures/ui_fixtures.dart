import 'package:lizzieyzy_mobile/design_system/design_system.dart';

import 'ui_models.dart';

abstract final class UiFixtures {
  static const scan = ScanDisplayModel(
    blackStones: 84,
    whiteStones: 82,
    pendingPoints: 2,
    recognizedMove: 87,
  );

  static const analysis = AnalysisProgressDisplayModel(
    completed: 142,
    total: 236,
    profile: '标准分析',
    elapsed: '2分18秒',
    estimatedRemaining: '约1分32秒',
  );

  static const performance = PerformanceDisplayModel(
    lowerRank: '3级',
    upperRank: '1级',
    confidence: '中等置信度',
    effectiveDecisions: 86,
    averageLoss: '1.8目',
    topThreeRate: '72%',
    severeMistakeRate: '4.7%',
  );

  static const recentKifu = <KifuSummaryModel>[
    KifuSummaryModel(
      blackPlayer: '山海一局',
      whitePlayer: '清风入弦',
      result: '白胜 3.5目',
      playedAt: '今天 14:32',
      moveCount: 236,
      status: '复盘完成',
    ),
    KifuSummaryModel(
      blackPlayer: '棋路未央',
      whitePlayer: '山海一局',
      result: '黑中盘胜',
      playedAt: '昨天 21:08',
      moveCount: 187,
      status: '分析中 60%',
      analysisProgress: 142 / 236,
    ),
    KifuSummaryModel(
      blackPlayer: '山海一局',
      whitePlayer: '松间明月',
      result: '白胜 1.5目',
      playedAt: '7月8日',
      moveCount: 264,
      status: '待复盘',
    ),
  ];

  static const stones = <BoardStone>[
    BoardStone(point: BoardPoint(3, 3), color: StoneColor.black),
    BoardStone(point: BoardPoint(15, 15), color: StoneColor.white),
    BoardStone(point: BoardPoint(15, 3), color: StoneColor.black),
    BoardStone(point: BoardPoint(3, 15), color: StoneColor.white),
    BoardStone(point: BoardPoint(16, 3), color: StoneColor.white),
    BoardStone(point: BoardPoint(15, 4), color: StoneColor.white),
    BoardStone(point: BoardPoint(14, 3), color: StoneColor.black),
    BoardStone(point: BoardPoint(14, 4), color: StoneColor.black),
    BoardStone(point: BoardPoint(16, 5), color: StoneColor.white),
    BoardStone(point: BoardPoint(13, 5), color: StoneColor.black),
    BoardStone(point: BoardPoint(3, 14), color: StoneColor.black),
    BoardStone(point: BoardPoint(4, 15), color: StoneColor.black),
    BoardStone(point: BoardPoint(4, 16), color: StoneColor.white),
    BoardStone(point: BoardPoint(2, 16), color: StoneColor.white),
    BoardStone(point: BoardPoint(2, 14), color: StoneColor.black),
    BoardStone(point: BoardPoint(5, 14), color: StoneColor.white),
    BoardStone(point: BoardPoint(3, 9), color: StoneColor.black),
    BoardStone(point: BoardPoint(4, 9), color: StoneColor.white),
    BoardStone(point: BoardPoint(5, 9), color: StoneColor.black),
    BoardStone(point: BoardPoint(5, 10), color: StoneColor.white),
    BoardStone(point: BoardPoint(6, 10), color: StoneColor.black),
    BoardStone(point: BoardPoint(6, 11), color: StoneColor.white),
    BoardStone(point: BoardPoint(7, 11), color: StoneColor.black),
    BoardStone(point: BoardPoint(8, 11), color: StoneColor.white),
    BoardStone(point: BoardPoint(9, 10), color: StoneColor.black),
    BoardStone(point: BoardPoint(10, 10), color: StoneColor.white),
    BoardStone(point: BoardPoint(11, 9), color: StoneColor.black),
    BoardStone(point: BoardPoint(12, 9), color: StoneColor.white),
    BoardStone(point: BoardPoint(12, 8), color: StoneColor.black),
    BoardStone(point: BoardPoint(13, 8), color: StoneColor.white),
    BoardStone(point: BoardPoint(3, 4), color: StoneColor.white),
    BoardStone(point: BoardPoint(4, 3), color: StoneColor.black),
    BoardStone(point: BoardPoint(4, 4), color: StoneColor.white),
    BoardStone(point: BoardPoint(2, 5), color: StoneColor.black),
    BoardStone(point: BoardPoint(5, 5), color: StoneColor.white),
    BoardStone(point: BoardPoint(7, 3), color: StoneColor.black),
    BoardStone(point: BoardPoint(8, 4), color: StoneColor.white),
    BoardStone(point: BoardPoint(9, 3), color: StoneColor.black),
    BoardStone(point: BoardPoint(10, 4), color: StoneColor.white),
    BoardStone(point: BoardPoint(15, 9), color: StoneColor.black),
    BoardStone(point: BoardPoint(16, 9), color: StoneColor.white),
    BoardStone(point: BoardPoint(15, 10), color: StoneColor.black),
    BoardStone(point: BoardPoint(14, 11), color: StoneColor.white),
    BoardStone(point: BoardPoint(16, 12), color: StoneColor.black),
    BoardStone(point: BoardPoint(10, 15), color: StoneColor.white),
    BoardStone(point: BoardPoint(11, 15), color: StoneColor.black),
    BoardStone(point: BoardPoint(10, 16), color: StoneColor.white),
    BoardStone(point: BoardPoint(12, 16), color: StoneColor.black),
    BoardStone(point: BoardPoint(13, 15), color: StoneColor.white),
    BoardStone(point: BoardPoint(8, 14), color: StoneColor.black),
    BoardStone(point: BoardPoint(8, 15), color: StoneColor.white),
    BoardStone(point: BoardPoint(7, 16), color: StoneColor.black),
  ];

  static const candidates = <BoardCandidate>[
    BoardCandidate(
      point: BoardPoint(16, 5),
      label: 'A',
      detail: '+3.1目',
      tone: CandidateTone.primary,
    ),
    BoardCandidate(
      point: BoardPoint(15, 5),
      label: 'B',
      detail: '+1.7目',
      tone: CandidateTone.secondary,
    ),
    BoardCandidate(
      point: BoardPoint(13, 3),
      label: 'C',
      detail: '+0.8目',
      tone: CandidateTone.tertiary,
    ),
  ];

  static const scoreSamples = <ScoreSample>[
    ScoreSample(move: 0, scoreLead: -0.5),
    ScoreSample(move: 18, scoreLead: 0.8),
    ScoreSample(move: 36, scoreLead: 1.2),
    ScoreSample(move: 54, scoreLead: -1.7),
    ScoreSample(move: 72, scoreLead: 2.4),
    ScoreSample(move: 87, scoreLead: -3.1),
    ScoreSample(move: 104, scoreLead: -1.8),
    ScoreSample(move: 126, scoreLead: 4.6),
    ScoreSample(move: 148, scoreLead: 2.1),
    ScoreSample(move: 178, scoreLead: 6.3),
    ScoreSample(move: 201, scoreLead: 4.1),
    ScoreSample(move: 236, scoreLead: 3.5),
  ];

  static const keyMove = KeyMoveDisplayModel(
    moveNumber: 87,
    playedMove: 'Q16',
    bestMove: 'R14',
    scoreLoss: '-5.2目',
    winRateLoss: '-18.4pp',
    winRate: '57.8%',
    scoreLead: '+3.1目',
    visits: '12,840',
    stones: stones,
    candidates: candidates,
    timelineKeyMoves: <int>[43, 87, 126, 178, 211],
  );
}
