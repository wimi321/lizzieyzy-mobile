import 'package:lizzieyzy_mobile/domain/domain.dart';

const testRules = GoRules.japanese();
const testSource = KifuSource(kind: KifuSourceKind.fixture);

VerifiedGameRecord verifiedFixture({String id = 'game-1'}) =>
    VerifiedGameRecord(
      id: id,
      initialPosition: BoardPosition.empty(BoardSize.nineteen),
      moves: const [
        Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
        Move.play(color: StoneColor.white, point: BoardPoint(15, 15)),
      ],
      rules: testRules,
      source: testSource,
    );

ModelManifest modelFixture() => ModelManifest(
  id: 'katago-b10',
  displayName: 'Standard',
  sha256: List.filled(64, 'a').join(),
  engineVersion: '1.16.5',
  modelVersion: 'b10-test',
  license: 'CC-BY-4.0',
  humanStyleRanks: [GoRank.kyu(3), GoRank.kyu(1)],
);

const analysisSettings = AnalysisSettings(
  profile: AnalysisProfile.standard,
  visitsPerMove: 1000,
);

AnalysisBundle analysisFixture({
  String requestId = 'request-1',
  String documentId = 'game-1',
}) => AnalysisBundle(
  requestId: requestId,
  documentId: documentId,
  boardSize: BoardSize.nineteen,
  model: modelFixture(),
  settings: analysisSettings,
  moves: [
    MoveAnalysis(
      moveNumber: 0,
      toPlay: StoneColor.black,
      playedMove: null,
      blackWinRate: 0.5,
      scoreLead: -7.5,
      visits: 1000,
      candidates: [
        Candidate(
          move: const Move.play(
            color: StoneColor.black,
            point: BoardPoint(3, 3),
          ),
          winRate: 0.51,
          scoreLead: -7.2,
          visits: 650,
          policy: 0.23,
        ),
      ],
    ),
    MoveAnalysis(
      moveNumber: 1,
      toPlay: StoneColor.white,
      playedMove: const Move.play(
        color: StoneColor.black,
        point: BoardPoint(3, 3),
      ),
      blackWinRate: 0.51,
      scoreLead: -7.2,
      visits: 1000,
      candidates: [
        Candidate(
          move: const Move.play(
            color: StoneColor.white,
            point: BoardPoint(15, 15),
          ),
          winRate: 0.5,
          scoreLead: -7.5,
          visits: 610,
          policy: 0.21,
        ),
      ],
      playedMovePointLoss: 0.3,
      playedMoveWinRateLoss: 0.01,
    ),
  ],
  completedAt: DateTime.utc(2026, 7, 11),
);
