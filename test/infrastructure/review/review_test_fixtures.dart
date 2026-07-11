import 'package:lizzieyzy_mobile/domain/domain.dart';

final class ReviewFixture {
  const ReviewFixture({
    required this.record,
    required this.analysis,
    required this.model,
  });

  final VerifiedGameRecord record;
  final AnalysisBundle analysis;
  final ModelManifest model;
}

ReviewFixture reviewFixture({
  String documentId = 'verified-game',
  BoardSize boardSize = BoardSize.nineteen,
  int moveCount = 90,
  StoneColor firstPlayer = StoneColor.black,
  BoardPosition? initialPosition,
  AnalysisProfile profile = AnalysisProfile.standard,
  int visitsPerMove = 1000,
  Set<int> passMoveNumbers = const <int>{},
  int Function(int moveNumber)? candidateRankForMove,
  double Function(int moveNumber)? pointLossForMove,
  double Function(int moveNumber)? playedMovePolicyForMove,
  GameMetadata metadata = const GameMetadata(),
  int? principalVariationMoveNumber,
  ModelManifest? model,
}) {
  final start = initialPosition ?? BoardPosition.empty(boardSize);
  final orderedPoints = <BoardPoint>[
    for (var row = 0; row < boardSize.dimension; row += 2)
      for (var column = 0; column < boardSize.dimension; column += 2)
        BoardPoint(column, row),
  ].where((point) => start.stoneAt(point) == null).toList();
  final stride = _coprimeStride(orderedPoints.length);
  final availablePoints = <BoardPoint>[
    for (var index = 0; index < orderedPoints.length; index++)
      orderedPoints[(index * stride) % orderedPoints.length],
  ];
  if (passMoveNumbers.any(
    (moveNumber) => moveNumber < 1 || moveNumber > moveCount,
  )) {
    throw ArgumentError('Pass move numbers must be inside the game.');
  }
  if (moveCount - passMoveNumbers.length > availablePoints.length) {
    throw ArgumentError(
      'Fixture requires more isolated points than available.',
    );
  }
  var pointIndex = 0;
  final moves = <Move>[];
  for (var index = 0; index < moveCount; index++) {
    final color = index.isEven ? firstPlayer : firstPlayer.opponent;
    if (passMoveNumbers.contains(index + 1)) {
      moves.add(Move.pass(color: color));
    } else {
      moves.add(Move.play(color: color, point: availablePoints[pointIndex++]));
    }
  }
  final record = VerifiedGameRecord(
    id: documentId,
    initialPosition: start,
    moves: moves,
    rules: const GoRules.chinese(),
    source: const KifuSource(kind: KifuSourceKind.fixture),
    metadata: metadata,
    firstPlayer: firstPlayer,
  );
  final resolvedModel = model ?? analysisModelFixture();
  final settings = AnalysisSettings(
    profile: profile,
    visitsPerMove: visitsPerMove,
    maxCandidates: 5,
    includeOwnership: false,
  );
  final rankFor = candidateRankForMove ?? (moveNumber) => (moveNumber % 6) + 1;
  final lossFor = pointLossForMove ?? (moveNumber) => (moveNumber % 7) * 0.5;
  final policyFor =
      playedMovePolicyForMove ??
      (moveNumber) {
        final rank = rankFor(moveNumber);
        return rank >= 1 && rank <= 5 ? 0.24 / rank : 0.005;
      };
  final analyses = <MoveAnalysis>[];
  for (var position = 0; position <= moveCount; position++) {
    final toPlay = position.isEven ? firstPlayer : firstPlayer.opponent;
    final candidates = position == moveCount
        ? <Candidate>[]
        : _candidatesFor(
            actualMove: moves[position],
            rank: rankFor(position + 1),
            boardSize: boardSize,
            visits: visitsPerMove,
            position: record.validation.positions[position],
            rules: record.rules,
            includePrincipalVariation:
                principalVariationMoveNumber == position + 1,
          );
    analyses.add(
      MoveAnalysis(
        moveNumber: position,
        toPlay: toPlay,
        playedMove: position == 0 ? null : moves[position - 1],
        blackWinRate: 0.45 + (position % 10) * 0.01,
        scoreLead: (position % 20 - 10) / 2,
        visits: visitsPerMove,
        candidates: candidates,
        playedMovePointLoss: position == 0 ? null : lossFor(position),
        playedMoveWinRateLoss: position == 0
            ? null
            : (lossFor(position) / 100).clamp(0, 1),
        playedMovePolicy: position == 0 ? null : policyFor(position),
        playedMoveHumanPolicy: position == 0 ? null : policyFor(position),
      ),
    );
  }

  return ReviewFixture(
    record: record,
    model: resolvedModel,
    analysis: AnalysisBundle(
      requestId: 'analysis-$documentId',
      documentId: documentId,
      boardSize: boardSize,
      model: resolvedModel,
      settings: settings,
      moves: analyses,
      completedAt: DateTime.utc(2026, 7, 11),
    ),
  );
}

int _coprimeStride(int length) {
  if (length <= 1) return 1;
  var candidate = length ~/ 3;
  while (_greatestCommonDivisor(candidate, length) != 1) {
    candidate++;
  }
  return candidate;
}

int _greatestCommonDivisor(int left, int right) {
  var a = left.abs();
  var b = right.abs();
  while (b != 0) {
    final remainder = a % b;
    a = b;
    b = remainder;
  }
  return a;
}

ModelManifest analysisModelFixture({
  String id = 'human-sl-b10',
  String hashCharacter = 'a',
  String humanHashCharacter = 'd',
  bool includeHumanRanks = true,
}) {
  return ModelManifest(
    id: id,
    displayName: 'HumanSL calibration fixture',
    sha256: List.filled(64, hashCharacter).join(),
    engineVersion: '1.16.5',
    modelVersion: 'b10-human-sl-test',
    license: 'CC-BY-4.0',
    humanModelSha256: includeHumanRanks
        ? List.filled(64, humanHashCharacter).join()
        : null,
    humanStyleRanks: includeHumanRanks
        ? <GoRank>[GoRank.kyu(20), GoRank.kyu(1), GoRank.dan(9)]
        : const <GoRank>[],
  );
}

GamePerformanceCalibration calibrationFixture({
  String allowedHashCharacter = 'a',
  String allowedHumanHashCharacter = 'd',
  int minimumDecisions = 40,
  int mediumConfidenceDecisions = 80,
  int minimumVisits = 1000,
  bool requiresHumanStyleRanks = true,
}) {
  final performanceModel = PerformanceModelManifest(
    id: 'game-strength-calibration',
    version: '1.0.0',
    sha256: List.filled(64, 'c').join(),
    minimumDecisions: minimumDecisions,
    minimumRank: GoRank.kyu(20),
    maximumRank: GoRank.dan(9),
  );
  return GamePerformanceCalibration(
    model: performanceModel,
    modelCard: CalibrationModelCard(
      modelId: performanceModel.id,
      intendedUse: 'Single-game 19-line even-game performance intervals.',
      datasetDescription: 'Player-isolated licensed calibration fixtures.',
      limitations: 'Not a persistent or association-issued rank.',
      trainingGames: 10000,
      heldOutGames: 2000,
      distinctPlayers: 1000,
    ),
    intercept: 0,
    featureWeights: const <CalibrationFeatureWeight>[
      CalibrationFeatureWeight(
        feature: PerformanceFeature.topOneRate,
        weight: 1,
        center: 0,
        scale: 1,
      ),
    ],
    buckets: <CalibrationBucket>[
      CalibrationBucket(
        minimumScore: double.negativeInfinity,
        maximumScore: 0.3,
        weakerBound: GoRank.kyu(10),
        strongerBound: GoRank.kyu(5),
      ),
      CalibrationBucket(
        minimumScore: 0.3,
        maximumScore: 0.7,
        weakerBound: GoRank.kyu(3),
        strongerBound: GoRank.kyu(1),
      ),
      CalibrationBucket(
        minimumScore: 0.7,
        maximumScore: double.infinity,
        weakerBound: GoRank.kyu(1),
        strongerBound: GoRank.dan(1),
      ),
    ],
    allowedAnalysisModelSha256: <String>{
      List.filled(64, allowedHashCharacter).join(),
    },
    allowedHumanModelSha256: requiresHumanStyleRanks
        ? <String>{List.filled(64, allowedHumanHashCharacter).join()}
        : const <String>{},
    allowedProfiles: const <AnalysisProfile>{
      AnalysisProfile.standard,
      AnalysisProfile.deep,
    },
    minimumVisitsPerPosition: minimumVisits,
    mediumConfidenceDecisions: mediumConfidenceDecisions,
    severeMistakePointLoss: 3,
    policyFloor: 1e-6,
    requiresHumanStyleRanks: requiresHumanStyleRanks,
    humanStyleProfile: requiresHumanStyleRanks ? GoRank.kyu(1) : null,
  );
}

AnalysisBundle copyAnalysis(
  AnalysisBundle source, {
  String? documentId,
  BoardSize? boardSize,
  ModelManifest? model,
  AnalysisSettings? settings,
  List<MoveAnalysis>? moves,
}) {
  return AnalysisBundle(
    requestId: source.requestId,
    documentId: documentId ?? source.documentId,
    boardSize: boardSize ?? source.boardSize,
    model: model ?? source.model,
    settings: settings ?? source.settings,
    moves: moves ?? source.moves,
    completedAt: source.completedAt,
  );
}

MoveAnalysis copyMoveAnalysis(
  MoveAnalysis source, {
  Move? playedMove,
  bool replacePlayedMove = false,
  StoneColor? toPlay,
  int? visits,
  List<Candidate>? candidates,
  double? pointLoss,
  bool removePointLoss = false,
  double? playedMovePolicy,
  bool removePlayedMovePolicy = false,
  double? playedMoveHumanPolicy,
  bool removePlayedMoveHumanPolicy = false,
}) {
  return MoveAnalysis(
    moveNumber: source.moveNumber,
    toPlay: toPlay ?? source.toPlay,
    playedMove: replacePlayedMove ? playedMove : source.playedMove,
    blackWinRate: source.blackWinRate,
    scoreLead: source.scoreLead,
    visits: visits ?? source.visits,
    candidates: candidates ?? source.candidates,
    playedMovePointLoss: removePointLoss
        ? null
        : pointLoss ?? source.playedMovePointLoss,
    playedMoveWinRateLoss: source.playedMoveWinRateLoss,
    playedMovePolicy: removePlayedMovePolicy
        ? null
        : playedMovePolicy ?? source.playedMovePolicy,
    playedMoveHumanPolicy: removePlayedMoveHumanPolicy
        ? null
        : playedMoveHumanPolicy ?? source.playedMoveHumanPolicy,
    ownership: source.ownership,
  );
}

Candidate copyCandidate(
  Candidate source, {
  Move? move,
  double? winRate,
  double? scoreLead,
  int? visits,
  double? policy,
}) {
  return Candidate(
    move: move ?? source.move,
    winRate: winRate ?? source.winRate,
    scoreLead: scoreLead ?? source.scoreLead,
    visits: visits ?? source.visits,
    policy: policy ?? source.policy,
    principalVariation: source.principalVariation,
  );
}

List<Candidate> _candidatesFor({
  required Move actualMove,
  required int rank,
  required BoardSize boardSize,
  required int visits,
  required BoardPosition position,
  required GoRules rules,
  required bool includePrincipalVariation,
}) {
  final alternatives =
      <Move>[
            for (var row = boardSize.dimension - 1; row >= 0; row--)
              for (var column = boardSize.dimension - 1; column >= 0; column--)
                Move.play(
                  color: actualMove.color,
                  point: BoardPoint(column, row),
                ),
          ]
          .where((move) {
            if (move == actualMove || position.stoneAt(move.point!) != null) {
              return false;
            }
            return GoRuleValidator.validate(
              initialPosition: position,
              moves: <Move>[move],
              rules: rules,
              firstPlayer: actualMove.color,
            ).isValid;
          })
          .take(5)
          .toList();
  if (alternatives.length < 5) {
    alternatives.add(Move.pass(color: actualMove.color));
  }
  final moves = List<Move>.of(alternatives);
  if (rank >= 1 && rank <= 5) {
    moves
      ..removeLast()
      ..insert(rank - 1, actualMove);
  }
  return <Candidate>[
    for (var index = 0; index < moves.length; index++)
      Candidate(
        move: moves[index],
        winRate: 0.6 - index * 0.03,
        scoreLead: 3 - index * 0.5,
        visits: visits - index * 50,
        policy: moves[index] == actualMove ? 0.24 / (index + 1) : 0.04,
        principalVariation: includePrincipalVariation
            ? _principalVariation(
                position: position,
                firstMove: moves[index],
                rules: rules,
                boardSize: boardSize,
              )
            : const <Move>[],
      ),
  ];
}

List<Move> _principalVariation({
  required BoardPosition position,
  required Move firstMove,
  required GoRules rules,
  required BoardSize boardSize,
}) {
  final variation = <Move>[firstMove];
  while (variation.length < 5) {
    final color = variation.last.color.opponent;
    Move? next;
    for (var row = 0; row < boardSize.dimension && next == null; row++) {
      for (var column = 0; column < boardSize.dimension; column++) {
        final candidate = Move.play(
          color: color,
          point: BoardPoint(column, row),
        );
        final trial = <Move>[...variation, candidate];
        if (GoRuleValidator.validate(
          initialPosition: position,
          moves: trial,
          rules: rules,
          firstPlayer: firstMove.color,
        ).isValid) {
          next = candidate;
          break;
        }
      }
    }
    next ??= Move.pass(color: color);
    variation.add(next);
  }
  return variation;
}
