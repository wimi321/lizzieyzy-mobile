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

    test('rejects endpoint-embedded credentials and invalid budgets', () {
      for (final endpoint in <String>[
        'wss://user:secret@analysis.example.test/v1',
        'wss://analysis.example.test/v1?token=secret',
        'wss://analysis.example.test/v1#secret',
      ]) {
        expect(
          () => KataGoWssConfig(
            endpoint: Uri.parse(endpoint),
            reportAnalysisWinratesAs: KataGoReportPerspective.black,
            model: _model,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => KataGoWssConfig(
          endpoint: Uri.parse('wss://analysis.example.test/v1'),
          reportAnalysisWinratesAs: KataGoReportPerspective.black,
          model: _model,
          maxInboundMessageBytes: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => KataGoWssConfig(
          endpoint: Uri.parse('wss://analysis.example.test/v1'),
          reportAnalysisWinratesAs: KataGoReportPerspective.black,
          model: _model,
          analysisPvLength: 129,
        ),
        throwsArgumentError,
      );
    });

    test('exposes bearer headers as an immutable map', () {
      final headers = _config(
        KataGoReportPerspective.black,
        bearerToken: ' secret ',
      ).connectionHeaders!;
      expect(headers, {'Authorization': 'Bearer secret'});
      expect(() => headers['Authorization'] = 'leak', throwsUnsupportedError);
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
      'pins HumanSL override history and fails closed when humanPolicy is absent',
      () async {
        socket = _FakeWebSocketChannel();
        connector = _ConnectorSpy(socket);
        provider = _provider(
          socket,
          connector: connector,
          model: _humanModel,
          humanStyleProfile: GoRank.kyu(1),
        );
        final sent = socket.nextClientMessage;
        final eventsFuture = provider.stream(_request(_record())).toList();
        final query = jsonDecode(await sent) as Map<String, dynamic>;

        expect(query['includePolicy'], isTrue);
        expect(query['overrideSettings'], {
          'humanSLProfile': 'rank_1k',
          'ignorePreRootHistory': false,
        });

        // A normal policy is present, but it must never be substituted for the
        // missing HumanSL policy required by the calibration.
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
        await expectLater(
          eventsFuture,
          throwsA(
            isA<KataGoProtocolException>().having(
              (error) => error.field,
              'field',
              'humanPolicy',
            ),
          ),
        );
      },
    );

    test(
      'stores HumanSL played-move policy without substituting main policy',
      () async {
        socket = _FakeWebSocketChannel();
        connector = _ConnectorSpy(socket);
        provider = _provider(
          socket,
          connector: connector,
          model: _humanModel,
          humanStyleProfile: GoRank.kyu(1),
        );
        final record = _record(
          moves: const <Move>[
            Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
          ],
        );
        final sent = socket.nextClientMessage;
        final eventsFuture = provider.stream(_request(record)).toList();
        await sent;

        socket.sendServer(
          _response(
            id: 'request-1',
            turn: 0,
            currentPlayer: 'B',
            rootWinRate: .5,
            rootScore: 0,
            candidates: [_candidate('Q16', order: 0, winRate: .6)],
            policyOverrides: const <String, double>{'D16': .25},
            humanPolicyOverrides: const <String, double>{'D16': .004},
          ),
        );
        socket.sendServer(
          _response(
            id: 'request-1',
            turn: 1,
            currentPlayer: 'W',
            rootWinRate: .48,
            rootScore: 1,
            candidates: [_candidate('Q4', order: 0, winRate: .52)],
            humanPolicyOverrides: const <String, double>{},
          ),
        );

        final positions = (await eventsFuture)
            .whereType<PositionAnalyzed>()
            .toList(growable: false);
        expect(positions[1].analysis.playedMovePolicy, .25);
        expect(positions[1].analysis.playedMoveHumanPolicy, .004);
      },
    );

    test('rejects illegal sentinels for rule-checked played moves', () async {
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(socket, connector: connector);
      final record = _record(
        moves: const <Move>[
          Move.play(color: StoneColor.black, point: BoardPoint(3, 3)),
        ],
      );
      var sent = socket.nextClientMessage;
      var future = provider.analyze(_request(record));
      await sent;
      socket.sendServer(
        _response(
          id: 'request-1',
          turn: 0,
          currentPlayer: 'B',
          rootWinRate: .5,
          rootScore: 0,
          candidates: [_candidate('Q16', order: 0, winRate: .6)],
          policyOverrides: const <String, double>{'D16': -1},
        ),
      );
      socket.sendServer(
        _response(
          id: 'request-1',
          turn: 1,
          currentPlayer: 'W',
          rootWinRate: .48,
          rootScore: 1,
          candidates: [_candidate('Q4', order: 0, winRate: .52)],
        ),
      );
      await expectLater(
        future,
        throwsA(
          isA<KataGoProtocolException>().having(
            (error) => error.field,
            'field',
            startsWith('policy['),
          ),
        ),
      );

      await provider.close();
      await socket.serverClose();
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(
        socket,
        connector: connector,
        model: _humanModel,
        humanStyleProfile: GoRank.kyu(1),
      );
      sent = socket.nextClientMessage;
      future = provider.analyze(_request(record));
      await sent;
      socket.sendServer(
        _response(
          id: 'request-1',
          turn: 0,
          currentPlayer: 'B',
          rootWinRate: .5,
          rootScore: 0,
          candidates: [_candidate('Q16', order: 0, winRate: .6)],
          humanPolicyOverrides: const <String, double>{'D16': -1},
        ),
      );
      socket.sendServer(
        _response(
          id: 'request-1',
          turn: 1,
          currentPlayer: 'W',
          rootWinRate: .48,
          rootScore: 1,
          candidates: [_candidate('Q4', order: 0, winRate: .52)],
          humanPolicyOverrides: const <String, double>{},
        ),
      );
      await expectLater(
        future,
        throwsA(
          isA<KataGoProtocolException>().having(
            (error) => error.field,
            'field',
            startsWith('humanPolicy['),
          ),
        ),
      );
    });

    test(
      'rejects an illegal policy fallback for a reported candidate',
      () async {
        socket = _FakeWebSocketChannel();
        connector = _ConnectorSpy(socket);
        provider = _provider(socket, connector: connector);
        final sent = socket.nextClientMessage;
        final future = provider.analyze(
          _request(
            PositionSnapshot(
              id: 'candidate-policy',
              position: BoardPosition.empty(BoardSize.nineteen),
              rules: const GoRules.chinese(),
              source: _source,
              playerToMove: StoneColor.black,
            ),
          ),
        );
        await sent;
        final candidate = _candidate('D16', order: 0, winRate: .5)
          ..remove('prior');
        socket.sendServer(
          _response(
            id: 'request-1',
            turn: 0,
            currentPlayer: 'B',
            rootWinRate: .5,
            rootScore: 0,
            candidates: <Map<String, dynamic>>[candidate],
            policyOverrides: const <String, double>{'D16': -1},
          ),
        );
        await expectLater(
          future,
          throwsA(
            isA<KataGoProtocolException>().having(
              (error) => error.field,
              'field',
              startsWith('policy['),
            ),
          ),
        );
      },
    );

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
            policyOverrides: const {'Q4': .013},
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
            policyOverrides: const {'D16': .007},
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
        expect(positions[1].analysis.playedMovePolicy, .007);
        expect(positions[2].analysis.playedMovePointLoss, 1);
        expect(positions[2].analysis.playedMoveWinRateLoss, closeTo(.10, 1e-9));
        expect(positions[2].analysis.playedMovePolicy, .013);
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
      'uses full policy and adjacent positions when played move is not Top-N',
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
            policyOverrides: const {'D16': .007},
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

        final bundle = await future;
        expect(
          bundle.moves.first.candidates.any(
            (candidate) => candidate.move.point == const BoardPoint(3, 3),
          ),
          isFalse,
        );
        expect(bundle.moves[1].playedMovePointLoss, 2);
        expect(bundle.moves[1].playedMoveWinRateLoss, closeTo(.2, 1e-9));
        expect(bundle.moves[1].playedMovePolicy, .007);
      },
    );

    test('requires full policy when it was requested', () async {
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
      final response = _response(
        id: 'request-1',
        turn: 0,
        currentPlayer: 'B',
        rootWinRate: .5,
        rootScore: 0,
        candidates: [_candidate('Q16', order: 0, winRate: .6)],
      )..remove('policy');
      socket.sendServer(response);

      await expectLater(
        future,
        throwsA(
          isA<KataGoProtocolException>().having(
            (error) => error.field,
            'field',
            'policy',
          ),
        ),
      );
    });

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
          isA<KataGoRemoteException>()
              .having((error) => error.requestId, 'requestId', 'a')
              .having((error) => error.field, 'field', 'rules')
              .having(
                (error) => error.toString(),
                'sanitized message',
                isNot(contains('unsupported rules')),
              ),
        ),
      );
      _sendOneMove(socket, id: 'b', actual: 'Q16');
      expect((await b).requestId, 'b');
    });

    test(
      'rejects a duplicate turn after its heavy buffer was released',
      () async {
        socket = _FakeWebSocketChannel();
        connector = _ConnectorSpy(socket);
        provider = _provider(socket, connector: connector);
        final sent = socket.nextClientMessage;
        final future = provider.analyze(_request(_record()));
        await sent;
        final root = _response(
          id: 'request-1',
          turn: 0,
          currentPlayer: 'B',
          rootWinRate: .5,
          rootScore: 0,
          candidates: [_candidate('D16', order: 0, winRate: .6)],
        );
        socket.sendServer(root);
        socket.sendServer(
          _response(
            id: 'request-1',
            turn: 1,
            currentPlayer: 'W',
            rootWinRate: .5,
            rootScore: 0,
            candidates: [_candidate('Q4', order: 0, winRate: .6)],
          ),
        );
        socket.sendServer(root);

        await expectLater(
          future,
          throwsA(
            isA<KataGoProtocolException>().having(
              (error) => error.field,
              'field',
              'turnNumber',
            ),
          ),
        );
      },
    );

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

    test(
      'close terminates requests and closes an in-flight handshake',
      () async {
        final ready = Completer<void>();
        socket = _FakeWebSocketChannel(ready: ready.future);
        connector = _ConnectorSpy(socket);
        provider = _provider(socket, connector: connector);
        final eventsFuture = provider.stream(_request(_record())).toList();
        await Future<void>.delayed(Duration.zero);

        await provider.close();

        expect(socket.sink.closeCode, 1000);
        expect(await eventsFuture, [
          isA<AnalysisStarted>(),
          isA<AnalysisCancelled>(),
        ]);
        ready.complete();
        await Future<void>.delayed(Duration.zero);
      },
    );

    test('rejects unsafe, repeated, and over-budget requests', () async {
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(
        socket,
        connector: connector,
        maxPositionsPerRequest: 2,
      );

      await expectLater(
        provider.analyze(_request(_record(), requestId: 'unsafe id')),
        throwsA(
          isA<KataGoRequestException>().having(
            (error) => error.field,
            'field',
            'requestId',
          ),
        ),
      );
      await expectLater(
        provider.analyze(_request(_record(), requestId: 'too-many')),
        throwsA(
          isA<KataGoRequestException>().having(
            (error) => error.field,
            'field',
            'moves',
          ),
        ),
      );

      final snapshot = PositionSnapshot(
        id: 'once',
        position: BoardPosition.empty(BoardSize.nineteen),
        rules: const GoRules.chinese(),
        source: _source,
        playerToMove: StoneColor.black,
      );
      final sent = socket.nextClientMessage;
      final first = provider.analyze(_request(snapshot, requestId: 'once'));
      await sent;
      socket.sendServer(
        _response(
          id: 'once',
          turn: 0,
          currentPlayer: 'B',
          rootWinRate: .5,
          rootScore: 0,
          candidates: [_candidate('D16', order: 0, winRate: .5)],
        ),
      );
      await first;
      await expectLater(
        provider.analyze(_request(snapshot, requestId: 'once')),
        throwsA(isA<KataGoRequestException>()),
      );
    });

    test('aborts oversized, deeply nested, and invalid UTF-8 frames', () async {
      Future<void> expectRejectedFrame({
        required dynamic frame,
        required KataGoWssConfig config,
      }) async {
        await provider.close();
        await socket.serverClose();
        socket = _FakeWebSocketChannel();
        connector = _ConnectorSpy(socket);
        provider = WssKataGoAnalysisProvider(
          config: config,
          connector: connector.call,
        );
        final sent = socket.nextClientMessage;
        final future = provider.analyze(
          _request(
            PositionSnapshot(
              id: 'frame-test',
              position: BoardPosition.empty(BoardSize.nineteen),
              rules: const GoRules.chinese(),
              source: _source,
              playerToMove: StoneColor.black,
            ),
          ),
        );
        await sent;
        socket.sendRaw(frame);
        await expectLater(future, throwsA(isA<KataGoAnalysisException>()));
        expect(socket.sink.closeCode, 1002);
      }

      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(socket, connector: connector);

      await expectRejectedFrame(
        frame: 'x' * 65,
        config: _config(
          KataGoReportPerspective.black,
          maxInboundMessageBytes: 64,
        ),
      );
      await expectRejectedFrame(
        frame: '{"a":[[[]]]}',
        config: _config(KataGoReportPerspective.black, maxJsonNestingDepth: 3),
      );
      await expectRejectedFrame(
        frame: <int>[0xFF],
        config: _config(KataGoReportPerspective.black),
      );
    });

    test('bounds candidates, PV, and response-message volume', () async {
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(
        socket,
        connector: connector,
        maxResponseCandidates: 3,
      );
      var sent = socket.nextClientMessage;
      var future = provider.analyze(
        _request(
          PositionSnapshot(
            id: 'candidate-limit',
            position: BoardPosition.empty(BoardSize.nineteen),
            rules: const GoRules.chinese(),
            source: _source,
            playerToMove: StoneColor.black,
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
          candidates: [
            _candidate('D16', order: 0, winRate: .5),
            _candidate('Q16', order: 1, winRate: .5),
            _candidate('C3', order: 2, winRate: .5),
            _candidate('R17', order: 3, winRate: .5),
          ],
        ),
      );
      await expectLater(future, throwsA(isA<KataGoResponseLimitException>()));
      expect(socket.sink.closeCode, 1002);

      await provider.close();
      await socket.serverClose();
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(socket, connector: connector, analysisPvLength: 1);
      sent = socket.nextClientMessage;
      future = provider.analyze(
        _request(
          PositionSnapshot(
            id: 'pv-limit',
            position: BoardPosition.empty(BoardSize.nineteen),
            rules: const GoRules.chinese(),
            source: _source,
            playerToMove: StoneColor.black,
          ),
          requestId: 'pv-limit',
        ),
      );
      await sent;
      socket.sendServer(
        _response(
          id: 'pv-limit',
          turn: 0,
          currentPlayer: 'B',
          rootWinRate: .5,
          rootScore: 0,
          candidates: [
            _candidate('D16', order: 0, winRate: .5, pv: ['D16', 'Q4']),
          ],
        ),
      );
      await expectLater(future, throwsA(isA<KataGoResponseLimitException>()));

      await provider.close();
      await socket.serverClose();
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(
        socket,
        connector: connector,
        maxResponseMessagesPerRequest: 1,
      );
      sent = socket.nextClientMessage;
      future = provider.analyze(
        _request(
          PositionSnapshot(
            id: 'message-limit',
            position: BoardPosition.empty(BoardSize.nineteen),
            rules: const GoRules.chinese(),
            source: _source,
            playerToMove: StoneColor.black,
          ),
          requestId: 'message-limit',
        ),
      );
      await sent;
      socket.sendServer(
        _response(
          id: 'message-limit',
          turn: 0,
          currentPlayer: 'B',
          rootWinRate: .5,
          rootScore: 0,
          isDuringSearch: true,
          candidates: [_candidate('D16', order: 0, winRate: .5)],
        ),
      );
      socket.sendServer(
        _response(
          id: 'message-limit',
          turn: 0,
          currentPlayer: 'B',
          rootWinRate: .5,
          rootScore: 0,
          candidates: [_candidate('D16', order: 0, winRate: .5)],
        ),
      );
      await expectLater(future, throwsA(isA<KataGoResponseLimitException>()));

      await provider.close();
      await socket.serverClose();
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(
        socket,
        connector: connector,
        maxBufferedResponseBytesPerRequest: 512,
      );
      sent = socket.nextClientMessage;
      future = provider.analyze(
        _request(
          PositionSnapshot(
            id: 'buffer-limit',
            position: BoardPosition.empty(BoardSize.nineteen),
            rules: const GoRules.chinese(),
            source: _source,
            playerToMove: StoneColor.black,
          ),
          requestId: 'buffer-limit',
        ),
      );
      await sent;
      socket.sendServer(
        _response(
          id: 'buffer-limit',
          turn: 0,
          currentPlayer: 'B',
          rootWinRate: .5,
          rootScore: 0,
          candidates: [_candidate('D16', order: 0, winRate: .5)],
        ),
      );
      await expectLater(future, throwsA(isA<KataGoResponseLimitException>()));
    });

    test('warnings consume request budgets and must be scoped', () async {
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(
        socket,
        connector: connector,
        maxResponseMessagesPerRequest: 1,
      );
      var sent = socket.nextClientMessage;
      var future = provider.analyze(
        _request(
          PositionSnapshot(
            id: 'warning-budget',
            position: BoardPosition.empty(BoardSize.nineteen),
            rules: const GoRules.chinese(),
            source: _source,
            playerToMove: StoneColor.black,
          ),
          requestId: 'warning-budget',
        ),
      );
      await sent;
      socket.sendServer(<String, dynamic>{
        'id': 'warning-budget',
        'warning': 'rules normalized',
        'field': 'rules',
      });
      socket.sendServer(
        _response(
          id: 'warning-budget',
          turn: 0,
          currentPlayer: 'B',
          rootWinRate: .5,
          rootScore: 0,
          candidates: [_candidate('D16', order: 0, winRate: .5)],
        ),
      );
      await expectLater(future, throwsA(isA<KataGoResponseLimitException>()));

      await provider.close();
      await socket.serverClose();
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(socket, connector: connector);
      sent = socket.nextClientMessage;
      future = provider.analyze(
        _request(
          PositionSnapshot(
            id: 'unscoped-warning',
            position: BoardPosition.empty(BoardSize.nineteen),
            rules: const GoRules.chinese(),
            source: _source,
            playerToMove: StoneColor.black,
          ),
        ),
      );
      await sent;
      socket.sendServer(<String, dynamic>{'warning': 'unscoped'});
      await expectLater(future, throwsA(isA<KataGoProtocolException>()));
      expect(socket.sink.closeCode, 1002);

      await provider.close();
      await socket.serverClose();
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(
        socket,
        connector: connector,
        maxResponseBytesPerRequest: 80,
      );
      sent = socket.nextClientMessage;
      future = provider.analyze(
        _request(
          PositionSnapshot(
            id: 'warning-bytes',
            position: BoardPosition.empty(BoardSize.nineteen),
            rules: const GoRules.chinese(),
            source: _source,
            playerToMove: StoneColor.black,
          ),
          requestId: 'warning-bytes',
        ),
      );
      await sent;
      socket.sendServer(<String, dynamic>{
        'id': 'warning-bytes',
        'warning': 'normalized',
        'field': 'rules',
      });
      socket.sendServer(
        _response(
          id: 'warning-bytes',
          turn: 0,
          currentPlayer: 'B',
          rootWinRate: .5,
          rootScore: 0,
          candidates: [_candidate('D16', order: 0, winRate: .5)],
        ),
      );
      await expectLater(future, throwsA(isA<KataGoResponseLimitException>()));
    });

    test('rejects unsolicited or replayed action acknowledgements', () async {
      socket = _FakeWebSocketChannel();
      connector = _ConnectorSpy(socket);
      provider = _provider(socket, connector: connector);
      final sent = socket.nextClientMessage;
      final future = provider.analyze(
        _request(
          PositionSnapshot(
            id: 'action-ack',
            position: BoardPosition.empty(BoardSize.nineteen),
            rules: const GoRules.chinese(),
            source: _source,
            playerToMove: StoneColor.black,
          ),
        ),
      );
      await sent;
      socket.sendServer(<String, dynamic>{
        'id': '__lizzieyzy_terminate_999',
        'action': 'terminate',
        'terminateId': 'request-1',
      });
      await expectLater(future, throwsA(isA<KataGoProtocolException>()));
      expect(socket.sink.closeCode, 1002);
    });

    test(
      'unknown ids abort the socket while late cancelled ids are ignored',
      () async {
        socket = _FakeWebSocketChannel();
        connector = _ConnectorSpy(socket);
        provider = _provider(socket, connector: connector);
        var sent = socket.nextClientMessage;
        var future = provider.analyze(
          _request(
            PositionSnapshot(
              id: 'unknown-test',
              position: BoardPosition.empty(BoardSize.nineteen),
              rules: const GoRules.chinese(),
              source: _source,
              playerToMove: StoneColor.black,
            ),
            requestId: 'known',
          ),
        );
        await sent;
        socket.sendServer(
          _response(
            id: 'unknown',
            turn: 0,
            currentPlayer: 'B',
            rootWinRate: .5,
            rootScore: 0,
            candidates: [_candidate('D16', order: 0, winRate: .5)],
          ),
        );
        await expectLater(future, throwsA(isA<KataGoProtocolException>()));
        expect(socket.sink.closeCode, 1002);

        await provider.close();
        await socket.serverClose();
        socket = _FakeWebSocketChannel();
        connector = _ConnectorSpy(socket);
        provider = _provider(socket, connector: connector);
        final lateSnapshot = PositionSnapshot(
          id: 'late-snapshot',
          position: BoardPosition.empty(BoardSize.nineteen),
          rules: const GoRules.chinese(),
          source: _source,
          playerToMove: StoneColor.black,
        );
        sent = socket.nextClientMessage;
        final cancelled = provider
            .stream(_request(lateSnapshot, requestId: 'cancelled'))
            .toList();
        await sent;
        await provider.cancel('cancelled');
        await cancelled;

        sent = socket.nextClientMessage;
        future = provider.analyze(_request(lateSnapshot, requestId: 'active'));
        await sent;
        socket.sendServer(
          _response(
            id: 'cancelled',
            turn: 0,
            currentPlayer: 'B',
            rootWinRate: .5,
            rootScore: 0,
            candidates: [_candidate('D16', order: 0, winRate: .5)],
          ),
        );
        socket.sendServer(
          _response(
            id: 'active',
            turn: 0,
            currentPlayer: 'B',
            rootWinRate: .5,
            rootScore: 0,
            candidates: [_candidate('D16', order: 0, winRate: .5)],
          ),
        );
        expect((await future).requestId, 'active');
      },
    );

    test(
      'times out analysis, terminates it, and redacts connector errors',
      () async {
        socket = _FakeWebSocketChannel();
        connector = _ConnectorSpy(socket);
        provider = _provider(
          socket,
          connector: connector,
          analysisTimeout: const Duration(milliseconds: 10),
        );
        final sent = socket.nextClientMessage;
        final future = provider.analyze(_request(_record()));
        await sent;
        await expectLater(future, throwsA(isA<KataGoTimeoutException>()));
        expect(
          jsonDecode(socket.sink.messages.last),
          containsPair('terminateId', 'request-1'),
        );

        await provider.close();
        await socket.serverClose();
        socket = _FakeWebSocketChannel();
        const secret = 'do-not-leak-token';
        provider = WssKataGoAnalysisProvider(
          config: _config(KataGoReportPerspective.black, bearerToken: secret),
          connector: (_, {headers, connectTimeout}) =>
              throw KataGoConnectionException(
                '$secret ${headers?['Authorization']}',
              ),
        );
        try {
          await provider.analyze(_request(_record()));
          fail('Expected a connection exception.');
        } on KataGoConnectionException catch (error) {
          expect(error.toString(), isNot(contains(secret)));
          expect(error.toString(), isNot(contains('Bearer')));
        }
      },
    );
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

final _humanModel = ModelManifest(
  id: 'human-sl-b10',
  displayName: 'HumanSL b10',
  sha256: List.filled(64, 'b').join(),
  engineVersion: '1.16.5',
  modelVersion: 'b10-human-sl-test',
  license: 'CC-BY-4.0',
  humanModelSha256: List.filled(64, 'c').join(),
  humanStyleRanks: <GoRank>[GoRank.kyu(1)],
);

KataGoWssConfig _config(
  KataGoReportPerspective perspective, {
  ModelManifest? model,
  GoRank? humanStyleProfile,
  String? bearerToken,
  Duration timeout = const Duration(seconds: 1),
  Duration analysisTimeout = const Duration(minutes: 45),
  int analysisPvLength = 12,
  int maxInboundMessageBytes = 8 * 1024 * 1024,
  int maxJsonNestingDepth = 32,
  int maxPositionsPerRequest = 1000,
  int maxResponseCandidates = 362,
  int maxResponseMessagesPerRequest = 16384,
  int maxResponseBytesPerRequest = 128 * 1024 * 1024,
  int maxBufferedResponseBytesPerRequest = 16 * 1024 * 1024,
}) => KataGoWssConfig(
  endpoint: Uri.parse('wss://analysis.example.test/v1'),
  reportAnalysisWinratesAs: perspective,
  model: model ?? _model,
  humanStyleProfile: humanStyleProfile,
  bearerToken: bearerToken,
  connectionTimeout: timeout,
  analysisTimeout: analysisTimeout,
  analysisPvLength: analysisPvLength,
  maxInboundMessageBytes: maxInboundMessageBytes,
  maxJsonNestingDepth: maxJsonNestingDepth,
  maxPositionsPerRequest: maxPositionsPerRequest,
  maxResponseCandidates: maxResponseCandidates,
  maxResponseMessagesPerRequest: maxResponseMessagesPerRequest,
  maxResponseBytesPerRequest: maxResponseBytesPerRequest,
  maxBufferedResponseBytesPerRequest: maxBufferedResponseBytesPerRequest,
);

WssKataGoAnalysisProvider _provider(
  _FakeWebSocketChannel socket, {
  required _ConnectorSpy connector,
  KataGoReportPerspective perspective = KataGoReportPerspective.black,
  ModelManifest? model,
  GoRank? humanStyleProfile,
  String? bearerToken,
  Duration timeout = const Duration(seconds: 1),
  Duration analysisTimeout = const Duration(minutes: 45),
  int analysisPvLength = 12,
  int maxPositionsPerRequest = 1000,
  int maxResponseCandidates = 362,
  int maxResponseMessagesPerRequest = 16384,
  int maxResponseBytesPerRequest = 128 * 1024 * 1024,
  int maxBufferedResponseBytesPerRequest = 16 * 1024 * 1024,
}) => WssKataGoAnalysisProvider(
  config: _config(
    perspective,
    model: model,
    humanStyleProfile: humanStyleProfile,
    bearerToken: bearerToken,
    timeout: timeout,
    analysisTimeout: analysisTimeout,
    analysisPvLength: analysisPvLength,
    maxPositionsPerRequest: maxPositionsPerRequest,
    maxResponseCandidates: maxResponseCandidates,
    maxResponseMessagesPerRequest: maxResponseMessagesPerRequest,
    maxResponseBytesPerRequest: maxResponseBytesPerRequest,
    maxBufferedResponseBytesPerRequest: maxBufferedResponseBytesPerRequest,
  ),
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
  Map<String, double> policyOverrides = const {},
  Map<String, double>? humanPolicyOverrides,
}) {
  final policy = List<double>.filled(19 * 19 + 1, .001);
  for (final entry in policyOverrides.entries) {
    policy[_policyIndex(entry.key)] = entry.value;
  }
  List<double>? humanPolicy;
  if (humanPolicyOverrides case final overrides?) {
    humanPolicy = List<double>.filled(19 * 19 + 1, .001);
    for (final entry in overrides.entries) {
      humanPolicy[_policyIndex(entry.key)] = entry.value;
    }
  }
  return {
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
    'policy': policy,
    'humanPolicy': ?humanPolicy,
    'ownership': List<double>.filled(19 * 19, ownership),
  };
}

int _policyIndex(String move) {
  if (move.toLowerCase() == 'pass') return 19 * 19;
  const columns = 'ABCDEFGHJKLMNOPQRST';
  final column = columns.indexOf(move[0].toUpperCase());
  final row = 19 - int.parse(move.substring(1));
  if (column < 0 || row < 0 || row >= 19) {
    throw ArgumentError.value(move, 'move');
  }
  return row * 19 + column;
}

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

  void sendRaw(dynamic data) {
    _server.add(data);
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
