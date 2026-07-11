import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/analysis/analysis.dart';
// The public WebSocketChannel interface inherits this mixin; the test fake
// uses it to implement the interface exactly without a network socket.
// ignore: depend_on_referenced_packages
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('KataGoWssConfig', () {
    test('requires WSS and an explicit engine output perspective', () {
      expect(
        () => KataGoWssConfig(
          endpoint: Uri.parse('ws://analysis.example.test'),
          reportAnalysisWinratesAs: KataGoReportPerspective.black,
          model: _model,
        ),
        throwsArgumentError,
      );
      final config = _config(KataGoReportPerspective.sideToMove);
      expect(config.endpoint.scheme, 'wss');
      expect(config.reportAnalysisWinratesAs.configValue, 'SIDETOMOVE');
    });
  });

  group('WssKataGoAnalysisProvider protocol', () {
    late _FakeWebSocketChannel socket;
    late WssKataGoAnalysisProvider provider;
    late _ConnectorSpy connector;

    tearDown(() async {
      await provider.close();
      await socket.serverClose();
    });

    test('sends the official whole-game query and bearer header', () async {
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(
        socket,
        connector: connector,
        bearerToken: 'secret-token',
      );
      final request = _request(_record());
      final sent = socket.nextClientMessage;
      final eventsFuture = provider.stream(request).toList();
      final query = jsonDecode(await sent) as Map<String, dynamic>;

      expect(connector.calls, 1);
      expect(connector.endpoint, Uri.parse('wss://analysis.example.test/v1'));
      expect(connector.headers, {'Authorization': 'Bearer secret-token'});
      expect(query, containsPair('id', 'request-1'));
      expect(query['initialStones'], isEmpty);
      expect(query['initialPlayer'], 'B');
      expect(query['moves'], [
        ['B', 'D16'],
        ['W', 'Q4'],
      ]);
      expect(query['rules'], 'japanese');
      expect(query['komi'], 6.5);
      expect(query['boardXSize'], 19);
      expect(query['boardYSize'], 19);
      expect(query['analyzeTurns'], [0, 1, 2]);
      expect(query['maxVisits'], 1000);
      expect(query['analysisPVLen'], 12);
      expect(query['includeOwnership'], isTrue);
      expect(query['includePolicy'], isTrue);

      _sendStandardGame(socket, id: 'request-1');
      await eventsFuture;
    });

    test(
      'sends a static setup as initialStones without invented moves',
      () async {
        socket = _FakeWebSocketChannel();
        connector = _ConnectorSpy(socket);
        provider = _provider(socket, connector: connector);
        final snapshot = PositionSnapshot(
          id: 'setup',
          position: BoardPosition(
            size: BoardSize.nineteen,
            stones: {
              const BoardPoint(15, 15): StoneColor.white,
              const BoardPoint(3, 3): StoneColor.black,
            },
          ),
          rules: const GoRules.chinese(),
          source: _source,
          playerToMove: StoneColor.white,
        );
        final sent = socket.nextClientMessage;
        final bundleFuture = provider.analyze(
          _request(snapshot, requestId: 'setup-request'),
        );
        final query = jsonDecode(await sent) as Map<String, dynamic>;

        expect(query['initialStones'], [
          ['B', 'D16'],
          ['W', 'Q4'],
        ]);
        expect(query['initialPlayer'], 'W');
        expect(query['moves'], isEmpty);
        expect(query['analyzeTurns'], [0]);
        socket.sendServer(
          _response(
            id: 'setup-request',
            turn: 0,
            currentPlayer: 'W',
            rootWinRate: .45,
            rootScore: -1,
            candidates: [_candidate('D4', order: 0, winRate: .44)],
          ),
        );
        expect((await bundleFuture).moves, hasLength(1));
      },
    );

    test(
      'handles out-of-order turns, ignores interim results, and parses loss',
      () async {
        socket = _FakeWebSocketChannel();
        connector = _ConnectorSpy(socket);
        provider = _provider(socket, connector: connector);
        final sent = socket.nextClientMessage;
        final eventsFuture = provider.stream(_request(_record())).toList();
        await sent;

        socket.sendServer(
          _response(
            id: 'request-1',
            turn: 2,
            currentPlayer: 'B',
            rootWinRate: .55,
            rootScore: -1,
            candidates: [_candidate('D4', order: 0, winRate: .56)],
          ),
        );
        socket.sendServer(
          _response(
            id: 'request-1',
            turn: 0,
            currentPlayer: 'B',
            rootWinRate: .50,
            rootScore: 0,
            isDuringSearch: true,
            candidates: [_candidate('Q16', order: 0, winRate: .60)],
          ),
        );
        socket.sendServer(
          _response(
            id: 'request-1',
            turn: 1,
            currentPlayer: 'W',
            rootWinRate: .52,
            rootScore: 0,
            candidates: [
              _candidate(
                'Q4',
                order: 0,
                winRate: .45,
                scoreLead: -2,
                pv: ['Q4', 'D4'],
              ),
              _candidate('C3', order: 1, winRate: .46),
            ],
          ),
        );
        socket.sendServer(
          _response(
            id: 'request-1',
            turn: 0,
            currentPlayer: 'B',
            rootWinRate: .50,
            rootScore: 0,
            candidates: [
              _candidate(
                'Q16',
                order: 0,
                winRate: .60,
                scoreLead: 3,
                pv: ['Q16', 'D4', 'pass'],
              ),
              _candidate('D16', order: 1, winRate: .54, scoreLead: 1),
            ],
          ),
        );

        final events = await eventsFuture;
        expect(events.first, isA<AnalysisStarted>());
        final positions = events.whereType<PositionAnalyzed>().toList();
        expect(positions.map((event) => event.analysis.moveNumber), [0, 1, 2]);
        expect(positions.map((event) => event.completedPositions), [1, 2, 3]);
        expect(
          positions[0].analysis.candidates.first.move.point,
          const BoardPoint(15, 3),
        );
        expect(positions[0].analysis.candidates.first.principalVariation, [
          const Move.play(color: StoneColor.black, point: BoardPoint(15, 3)),
          const Move.play(color: StoneColor.white, point: BoardPoint(3, 15)),
          const Move.pass(color: StoneColor.black),
        ]);
        expect(positions[0].analysis.ownership.first, .25);
        expect(positions[1].analysis.playedMovePointLoss, 3);
        expect(positions[1].analysis.playedMoveWinRateLoss, closeTo(.08, 1e-9));
        expect(positions[2].analysis.playedMovePointLoss, 1);
        expect(positions[2].analysis.playedMoveWinRateLoss, closeTo(.10, 1e-9));
        expect(
          positions[1].analysis.candidates.first.winRate,
          closeTo(.55, 1e-9),
        );
        final completed = events.last as AnalysisCompleted;
        expect(completed.bundle.moves.map((move) => move.moveNumber), [
          0,
          1,
          2,
        ]);
        expect(completed.bundle.completedAt, DateTime.utc(2026, 7, 11, 8));
      },
    );

    test(
      'normalizes WHITE winrate, score, candidates, and ownership',
      () async {
        socket = _FakeWebSocketChannel();
        connector = _ConnectorSpy(socket);
        provider = _provider(
          socket,
          connector: connector,
          perspective: KataGoReportPerspective.white,
        );
        final snapshot = PositionSnapshot(
          id: 'snapshot',
          position: BoardPosition.empty(BoardSize.nineteen),
          rules: const GoRules.chinese(),
          source: _source,
          playerToMove: StoneColor.black,
        );
        final sent = socket.nextClientMessage;
        final bundleFuture = provider.analyze(
          _request(snapshot, requestId: 'white-view'),
        );
        await sent;
        socket.sendServer(
          _response(
            id: 'white-view',
            turn: 0,
            currentPlayer: 'B',
            rootWinRate: .25,
            rootScore: 4,
            ownership: .5,
            candidates: [
              _candidate('D16', order: 0, winRate: .30, scoreLead: 5),
            ],
          ),
        );

        final root = (await bundleFuture).moves.single;
        expect(root.blackWinRate, .75);
        expect(root.scoreLead, -4);
        expect(root.candidates.single.winRate, .70);
        expect(root.candidates.single.scoreLead, -5);
        expect(root.ownership.first, -.5);
      },
    );

    test('normalizes SIDETOMOVE separately on alternating turns', () async {
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(
        socket,
        connector: connector,
        perspective: KataGoReportPerspective.sideToMove,
      );
      final record = _record(
        moves: const [
          Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
        ],
      );
      final sent = socket.nextClientMessage;
      final bundleFuture = provider.analyze(_request(record));
      await sent;
      socket.sendServer(
        _response(
          id: 'request-1',
          turn: 1,
          currentPlayer: 'W',
          rootWinRate: .65,
          rootScore: 2,
          candidates: [_candidate('Q4', order: 0, winRate: .60)],
        ),
      );
      socket.sendServer(
        _response(
          id: 'request-1',
          turn: 0,
          currentPlayer: 'B',
          rootWinRate: .60,
          rootScore: 3,
          candidates: [
            _candidate('Q16', order: 0, winRate: .70, scoreLead: 4),
            _candidate('D16', order: 1, winRate: .62, scoreLead: 3),
          ],
        ),
      );

      final bundle = await bundleFuture;
      expect(bundle.moves[0].blackWinRate, .60);
      expect(bundle.moves[1].blackWinRate, .35);
      expect(bundle.moves[1].scoreLead, -2);
      expect(bundle.moves[1].candidates.single.winRate, .60);
      expect(bundle.moves[1].candidates.single.scoreLead, 0);
      expect(bundle.moves[1].ownership.first, -.25);
      expect(bundle.moves[1].playedMovePointLoss, 6);
      expect(bundle.moves[1].playedMoveWinRateLoss, closeTo(.35, 1e-9));
    });

    test('multiplexes concurrent request ids on one connection', () async {
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(socket, connector: connector);
      final first = _request(
        _record(
          id: 'game-a',
          moves: const [
            Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
          ],
        ),
        requestId: 'a',
      );
      final second = _request(
        _record(
          id: 'game-b',
          moves: const [
            Move.play(color: StoneColor.black, point: BoardPoint(15, 3)),
          ],
        ),
        requestId: 'b',
      );
      final aFuture = provider.analyze(first);
      final bFuture = provider.analyze(second);
      await socket.waitForClientMessages(2);
      var aCompleted = false;
      unawaited(aFuture.then((_) => aCompleted = true));

      _sendOneMove(socket, id: 'b', actual: 'Q16');
      final bBundle = await bFuture;
      expect(bBundle.requestId, 'b');
      expect(aCompleted, isFalse);
      _sendOneMove(socket, id: 'a', actual: 'D16');
      expect((await aFuture).requestId, 'a');
      expect(connector.calls, 1);
    });

    test(
      'missing played move is a verifiable error, never zero loss',
      () async {
        socket = _FakeWebSocketChannel();
        connector = _ConnectorSpy(socket);
        provider = _provider(socket, connector: connector);
        final sent = socket.nextClientMessage;
        final future = provider.analyze(
          _request(
            _record(
              moves: const [
                Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
              ],
            ),
          ),
        );
        await sent;
        socket.sendServer(
          _response(
            id: 'request-1',
            turn: 0,
            currentPlayer: 'B',
            rootWinRate: .5,
            rootScore: 0,
            candidates: [_candidate('Q16', order: 0, winRate: .6)],
          ),
        );
        socket.sendServer(
          _response(
            id: 'request-1',
            turn: 1,
            currentPlayer: 'W',
            rootWinRate: .4,
            rootScore: -2,
            candidates: [_candidate('Q4', order: 0, winRate: .6)],
          ),
        );

        await expectLater(
          future,
          throwsA(
            isA<KataGoMissingPlayedMoveException>()
                .having((error) => error.turnNumber, 'turnNumber', 1)
                .having(
                  (error) => error.playedMove.point,
                  'point',
                  const BoardPoint(3, 3),
                ),
          ),
        );
      },
    );

    test('routes server protocol errors only to their request id', () async {
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(socket, connector: connector);
      final a = provider.analyze(
        _request(
          _record(
            id: 'a-game',
            moves: const [
              Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
            ],
          ),
          requestId: 'a',
        ),
      );
      final b = provider.analyze(
        _request(
          _record(
            id: 'b-game',
            moves: const [
              Move.play(color: StoneColor.black, point: BoardPoint(15, 3)),
            ],
          ),
          requestId: 'b',
        ),
      );
      await socket.waitForClientMessages(2);
      socket.sendServer({
        'id': 'a',
        'error': 'unsupported rules',
        'field': 'rules',
      });
      await expectLater(
        a,
        throwsA(
          isA<KataGoProtocolException>()
              .having((error) => error.requestId, 'requestId', 'a')
              .having((error) => error.field, 'field', 'rules'),
        ),
      );
      _sendOneMove(socket, id: 'b', actual: 'Q16');
      expect((await b).requestId, 'b');
    });

    test(
      'cancel sends terminate, emits cancelled, and closes the stream',
      () async {
        socket = _FakeWebSocketChannel();
        connector = _ConnectorSpy(socket);
        provider = _provider(socket, connector: connector);
        final querySent = socket.nextClientMessage;
        final eventsFuture = provider.stream(_request(_record())).toList();
        await querySent.timeout(const Duration(seconds: 1));
        final terminateSent = socket.nextClientMessage;
        await provider.cancel('request-1').timeout(const Duration(seconds: 1));
        final terminate =
            jsonDecode(await terminateSent.timeout(const Duration(seconds: 1)))
                as Map<String, dynamic>;

        expect(terminate['action'], 'terminate');
        expect(terminate['terminateId'], 'request-1');
        expect(terminate['id'], startsWith('__lizzieyzy_terminate_'));
        final events = await eventsFuture.timeout(const Duration(seconds: 1));
        expect(events, [isA<AnalysisStarted>(), isA<AnalysisCancelled>()]);
      },
    );

    test('surfaces connection timeout and premature socket close', () async {
      socket = _FakeWebSocketChannel(ready: Completer<void>().future);
      connector = _ConnectorSpy(socket);
      provider = _provider(
        socket,
        connector: connector,
        timeout: const Duration(milliseconds: 1),
      );
      await expectLater(
        provider.analyze(_request(_record())),
        throwsA(isA<KataGoConnectionException>()),
      );
      await provider.close();
      await socket.serverClose();

      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(socket, connector: connector);
      final sent = socket.nextClientMessage;
      final future = provider.analyze(_request(_record()));
      final closedExpectation = expectLater(
        future,
        throwsA(isA<KataGoConnectionException>()),
      );
      await sent;
      await socket.serverClose();
      await closedExpectation;
    });
  });
}

const _source = KifuSource(kind: KifuSourceKind.fixture);

final _model = ModelManifest(
  id: 'kata-b18',
  displayName: 'KataGo b18',
  sha256: List.filled(64, 'a').join(),
  engineVersion: '1.16.5',
  modelVersion: 'b18-test',
  license: 'CC-BY-4.0',
);

KataGoWssConfig _config(
  KataGoReportPerspective perspective, {
  String? bearerToken,
  Duration timeout = const Duration(seconds: 1),
}) => KataGoWssConfig(
  endpoint: Uri.parse('wss://analysis.example.test/v1'),
  reportAnalysisWinratesAs: perspective,
  model: _model,
  bearerToken: bearerToken,
  connectionTimeout: timeout,
  analysisPvLength: 12,
);

WssKataGoAnalysisProvider _provider(
  _FakeWebSocketChannel socket, {
  required _ConnectorSpy connector,
  KataGoReportPerspective perspective = KataGoReportPerspective.black,
  String? bearerToken,
  Duration timeout = const Duration(seconds: 1),
}) => WssKataGoAnalysisProvider(
  config: _config(perspective, bearerToken: bearerToken, timeout: timeout),
  connector: connector.call,
  clock: () => DateTime.utc(2026, 7, 11, 8),
);

VerifiedGameRecord _record({
  String id = 'game-1',
  List<Move> moves = const [
    Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
    Move.play(color: StoneColor.white, point: BoardPoint(15, 15)),
  ],
}) => VerifiedGameRecord(
  id: id,
  initialPosition: BoardPosition.empty(BoardSize.nineteen),
  moves: moves,
  rules: const GoRules.japanese(),
  source: _source,
);

AnalysisRequest _request(
  KifuDocument document, {
  String requestId = 'request-1',
}) => AnalysisRequest(
  requestId: requestId,
  document: document,
  settings: const AnalysisSettings(
    profile: AnalysisProfile.standard,
    visitsPerMove: 1000,
    maxCandidates: 3,
    includeOwnership: true,
  ),
);

Map<String, dynamic> _candidate(
  String move, {
  required int order,
  required double winRate,
  double scoreLead = 0,
  int visits = 500,
  double prior = .2,
  List<String>? pv,
}) => {
  'move': move,
  'order': order,
  'visits': visits,
  'winrate': winRate,
  'scoreLead': scoreLead,
  'prior': prior,
  'pv': pv ?? [move],
};

Map<String, dynamic> _response({
  required String id,
  required int turn,
  required String currentPlayer,
  required double rootWinRate,
  required double rootScore,
  required List<Map<String, dynamic>> candidates,
  bool isDuringSearch = false,
  double ownership = .25,
}) => {
  'id': id,
  'isDuringSearch': isDuringSearch,
  'turnNumber': turn,
  'rootInfo': {
    'currentPlayer': currentPlayer,
    'winrate': rootWinRate,
    'scoreLead': rootScore,
    'visits': 1000,
  },
  'moveInfos': candidates,
  'ownership': List<double>.filled(19 * 19, ownership),
};

void _sendStandardGame(_FakeWebSocketChannel socket, {required String id}) {
  socket.sendServer(
    _response(
      id: id,
      turn: 0,
      currentPlayer: 'B',
      rootWinRate: .5,
      rootScore: 0,
      candidates: [
        _candidate('Q16', order: 0, winRate: .6, scoreLead: 3),
        _candidate('D16', order: 1, winRate: .54, scoreLead: 1),
      ],
    ),
  );
  socket.sendServer(
    _response(
      id: id,
      turn: 1,
      currentPlayer: 'W',
      rootWinRate: .52,
      rootScore: 0,
      candidates: [_candidate('Q4', order: 0, winRate: .45, scoreLead: -2)],
    ),
  );
  socket.sendServer(
    _response(
      id: id,
      turn: 2,
      currentPlayer: 'B',
      rootWinRate: .55,
      rootScore: -1,
      candidates: [_candidate('D4', order: 0, winRate: .56)],
    ),
  );
}

void _sendOneMove(
  _FakeWebSocketChannel socket, {
  required String id,
  required String actual,
}) {
  socket.sendServer(
    _response(
      id: id,
      turn: 1,
      currentPlayer: 'W',
      rootWinRate: .52,
      rootScore: 0,
      candidates: [_candidate('Q4', order: 0, winRate: .45)],
    ),
  );
  socket.sendServer(
    _response(
      id: id,
      turn: 0,
      currentPlayer: 'B',
      rootWinRate: .5,
      rootScore: 0,
      candidates: [
        _candidate('Q4', order: 0, winRate: .6),
        _candidate(actual, order: 1, winRate: .54),
      ],
    ),
  );
}

final class _ConnectorSpy {
  _ConnectorSpy(this.socket);

  final _FakeWebSocketChannel socket;
  int calls = 0;
  Uri? endpoint;
  Map<String, dynamic>? headers;
  Duration? timeout;

  WebSocketChannel call(
    Uri endpoint, {
    Map<String, dynamic>? headers,
    Duration? connectTimeout,
  }) {
    calls += 1;
    this.endpoint = endpoint;
    this.headers = headers;
    timeout = connectTimeout;
    return socket;
  }
}

final class _FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  _FakeWebSocketChannel({Future<void>? ready})
    : ready = ready ?? Future<void>.value(),
      sink = _FakeWebSocketSink() {
    _attach();
  }

  final StreamController<dynamic> _server = StreamController<dynamic>(
    sync: true,
  );
  final StreamController<String> _client = StreamController<String>.broadcast();

  @override
  final Future<void> ready;

  @override
  final _FakeWebSocketSink sink;

  @override
  Stream<dynamic> get stream => _server.stream;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  Future<String> get nextClientMessage => _client.stream.first;

  void sendServer(Map<String, dynamic> json) {
    _server.add(jsonEncode(json));
  }

  Future<void> serverClose() async {
    if (!_server.isClosed) {
      final hadListener = _server.hasListener;
      final closed = _server.close();
      if (hadListener) await closed;
    }
    if (!_client.isClosed) await _client.close();
  }

  Future<void> waitForClientMessages(int count) async {
    while (sink.messages.length < count) {
      await _client.stream.first;
    }
  }

  void _attach() {
    sink.onMessage = _client.add;
  }
}

final class _FakeWebSocketSink implements WebSocketSink {
  final List<String> messages = [];
  final Completer<void> _done = Completer<void>();
  void Function(String message)? onMessage;
  int? closeCode;
  String? closeReason;

  @override
  void add(dynamic data) {
    if (data is! String) throw ArgumentError('Fake accepts text only.');
    messages.add(data);
    onMessage?.call(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (!_done.isCompleted) _done.completeError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await for (final value in stream) {
      add(value);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    this.closeCode = closeCode;
    this.closeReason = closeReason;
    if (!_done.isCompleted) _done.complete();
  }

  @override
  Future<void> get done => _done.future;
}
