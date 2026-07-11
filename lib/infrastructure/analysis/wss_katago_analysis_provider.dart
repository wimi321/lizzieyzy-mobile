import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../domain/domain.dart';
import 'katago_analysis_exception.dart';
import 'katago_analysis_protocol.dart';
import 'katago_wss_config.dart';

/// A multiplexed WSS client for KataGo's asynchronous Analysis Engine JSON
/// protocol.
///
/// One socket is shared by active requests. KataGo may return turns and request
/// ids in any order; results are routed by id and assembled in turn order so
/// per-move loss is always derived from adjacent finalized positions.
///
/// Protocol reference:
/// https://github.com/lightvector/KataGo/blob/master/docs/Analysis_Engine.md
final class WssKataGoAnalysisProvider implements AnalysisProvider {
  WssKataGoAnalysisProvider({
    required this.config,
    KataGoWebSocketConnector? connector,
    DateTime Function()? clock,
  }) : _connector = connector ?? _defaultConnector,
       _clock = clock ?? DateTime.now,
       _protocol = KataGoAnalysisProtocol(config);

  final KataGoWssConfig config;
  final KataGoWebSocketConnector _connector;
  final DateTime Function() _clock;
  final KataGoAnalysisProtocol _protocol;

  final Map<String, _PendingAnalysis> _pending = {};
  WebSocketChannel? _channel;
  Future<WebSocketChannel>? _connectionFuture;
  StreamSubscription<dynamic>? _socketSubscription;
  var _terminateSequence = 0;
  var _closed = false;

  @override
  Future<AnalysisBundle> analyze(AnalysisRequest request) async {
    await for (final event in stream(request)) {
      if (event case AnalysisCompleted(:final bundle)) return bundle;
      if (event is AnalysisCancelled) {
        throw KataGoAnalysisCancelledException(request.requestId);
      }
    }
    throw KataGoProtocolException(
      'Analysis stream closed without a terminal event.',
      requestId: request.requestId,
    );
  }

  @override
  Stream<AnalysisEvent> stream(AnalysisRequest request) {
    late final _PendingAnalysis pending;
    late final StreamController<AnalysisEvent> controller;
    controller = StreamController<AnalysisEvent>(
      sync: true,
      onListen: () => _start(pending),
      onCancel: () => _cancelPending(pending, emitEvent: false),
    );
    pending = _PendingAnalysis(request: request, controller: controller);
    return controller.stream;
  }

  @override
  Future<void> cancel(String requestId) async {
    final pending = _pending[requestId];
    if (pending == null) return;
    await _cancelPending(pending, emitEvent: true);
  }

  /// Terminates active analyses and closes the shared socket.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final pending in _pending.values.toList(growable: false)) {
      await _cancelPending(pending, emitEvent: true);
    }
    final subscription = _socketSubscription;
    _socketSubscription = null;
    await subscription?.cancel();
    final channel = _channel;
    _channel = null;
    _connectionFuture = null;
    await channel?.sink.close(status.normalClosure, 'Provider closed');
  }

  void _start(_PendingAnalysis pending) {
    if (_closed) {
      _failPending(
        pending,
        const KataGoConnectionException('Analysis provider is closed.'),
      );
      return;
    }
    final requestId = pending.request.requestId;
    if (_pending.containsKey(requestId)) {
      _failPending(
        pending,
        KataGoRequestException(
          'An active request already uses this request id.',
          requestId: requestId,
          field: 'requestId',
        ),
      );
      return;
    }

    try {
      pending.prepared = _protocol.prepare(pending.request);
    } on Object catch (error, stackTrace) {
      _failPending(pending, error, stackTrace);
      return;
    }
    _pending[requestId] = pending;
    pending.controller.add(
      AnalysisStarted(
        requestId,
        totalPositions: pending.prepared!.totalPositions,
      ),
    );
    unawaited(_connectAndSend(pending));
  }

  Future<void> _connectAndSend(_PendingAnalysis pending) async {
    try {
      final channel = await _ensureConnection();
      if (pending.cancelled || _pending[pending.request.requestId] != pending) {
        return;
      }
      pending.querySent = true;
      channel.sink.add(jsonEncode(pending.prepared!.json));
    } on Object catch (error, stackTrace) {
      final wrapped = error is KataGoAnalysisException
          ? error
          : KataGoConnectionException(
              'Could not connect to the KataGo analysis service: $error',
              requestId: pending.request.requestId,
            );
      _failPending(pending, wrapped, stackTrace);
    }
  }

  Future<WebSocketChannel> _ensureConnection() {
    final existing = _channel;
    if (existing != null) return Future.value(existing);
    final connecting = _connectionFuture;
    if (connecting != null) return connecting;
    final created = _openConnection();
    _connectionFuture = created;
    return created;
  }

  Future<WebSocketChannel> _openConnection() async {
    WebSocketChannel? channel;
    try {
      channel = _connector(
        config.endpoint,
        headers: config.connectionHeaders,
        connectTimeout: config.connectionTimeout,
      );
      await channel.ready.timeout(config.connectionTimeout);
      if (_closed) {
        await channel.sink.close(status.normalClosure, 'Provider closed');
        throw const KataGoConnectionException('Analysis provider is closed.');
      }
      _channel = channel;
      _socketSubscription = channel.stream.listen(
        _onSocketData,
        onError: _onSocketError,
        onDone: _onSocketDone,
        cancelOnError: false,
      );
      return channel;
    } on Object catch (error) {
      _connectionFuture = null;
      _channel = null;
      if (channel != null) {
        try {
          await channel.sink.close(status.goingAway, 'Connection failed');
        } on Object {
          // Preserve the original connection error.
        }
      }
      if (error is KataGoAnalysisException) rethrow;
      throw KataGoConnectionException(
        error is TimeoutException
            ? 'Timed out connecting to the KataGo analysis service.'
            : 'Could not connect to the KataGo analysis service: $error',
      );
    }
  }

  void _onSocketData(dynamic data) {
    final String payload;
    try {
      payload = switch (data) {
        String() => data,
        List<int>() => utf8.decode(data),
        _ => throw const FormatException(
          'WebSocket messages must be text or UTF-8 bytes.',
        ),
      };
    } on Object catch (error, stackTrace) {
      _failAll(
        KataGoProtocolException('Invalid WebSocket message: $error'),
        stackTrace,
      );
      return;
    }

    for (final line in const LineSplitter().convert(payload)) {
      if (line.trim().isEmpty) continue;
      try {
        final decoded = jsonDecode(line);
        if (decoded is! Map) {
          throw const FormatException('Response must be a JSON object.');
        }
        _handleResponse(decoded.cast<String, dynamic>());
      } on Object catch (error, stackTrace) {
        if (error is KataGoAnalysisException && error.requestId != null) {
          final pending = _pending[error.requestId];
          if (pending != null) {
            _failPending(pending, error, stackTrace);
            continue;
          }
        }
        _failAll(
          error is KataGoAnalysisException
              ? error
              : KataGoProtocolException('Malformed KataGo response: $error'),
          stackTrace,
        );
      }
    }
  }

  void _handleResponse(Map<String, dynamic> json) {
    if (json.containsKey('warning')) return;

    final idValue = json['id'];
    final id = idValue is String ? idValue : null;
    if (json.containsKey('error')) {
      final error = json['error'];
      if (error is! String || error.isEmpty) {
        throw const KataGoProtocolException(
          'KataGo error responses must contain a non-empty error string.',
          field: 'error',
        );
      }
      final field = json['field'];
      final exception = KataGoProtocolException(
        error,
        requestId: id,
        field: field is String ? field : null,
      );
      if (id == null) {
        _failAll(exception);
      } else {
        final pending = _pending[id];
        if (pending != null) _failPending(pending, exception);
      }
      return;
    }

    // Special-action acknowledgements (such as terminate) are not analyses.
    if (json.containsKey('action')) return;
    if (id == null) {
      throw const KataGoProtocolException(
        'Analysis response is missing a string id.',
        field: 'id',
      );
    }
    final pending = _pending[id];
    if (pending == null) return;

    final duringSearch = json['isDuringSearch'];
    if (duringSearch is! bool) {
      throw KataGoProtocolException(
        'isDuringSearch must be a boolean.',
        requestId: id,
        field: 'isDuringSearch',
      );
    }
    if (duringSearch) return;
    if (json['noResults'] == true) {
      throw KataGoProtocolException(
        'KataGo returned noResults for a request that was not cancelled.',
        requestId: id,
        field: 'noResults',
      );
    }

    final result = _protocol.parseFinalResult(json, pending.prepared!);
    if (pending.results.containsKey(result.turnNumber)) {
      throw KataGoProtocolException(
        'Received more than one final result for a turn.',
        requestId: id,
        field: 'turnNumber',
      );
    }
    pending.results[result.turnNumber] = result;
    _emitContiguousResults(pending);
  }

  void _emitContiguousResults(_PendingAnalysis pending) {
    try {
      while (pending.results.containsKey(pending.nextTurnToEmit)) {
        final turnNumber = pending.nextTurnToEmit;
        final result = pending.results[turnNumber]!;
        Move? playedMove;
        double? pointLoss;
        double? winRateLoss;

        if (turnNumber > 0) {
          playedMove = pending.prepared!.moves[turnNumber - 1];
          final before = pending.results[turnNumber - 1]!;
          if (!before.containsMove(playedMove)) {
            throw KataGoMissingPlayedMoveException(
              requestId: pending.request.requestId,
              turnNumber: turnNumber,
              playedMove: playedMove,
            );
          }
          final best = before.bestCandidate.candidate;
          final actualPlayerWinRate = playedMove.color == StoneColor.black
              ? result.blackWinRate
              : 1 - result.blackWinRate;
          winRateLoss = math.max(0.0, best.winRate - actualPlayerWinRate);
          final signedPointDifference = playedMove.color == StoneColor.black
              ? best.scoreLead - result.blackScoreLead
              : result.blackScoreLead - best.scoreLead;
          pointLoss = math.max(0.0, signedPointDifference);
        }

        final analysis = result.toDomain(
          maxCandidates: pending.request.settings.maxCandidates,
          playedMove: playedMove,
          pointLoss: pointLoss,
          winRateLoss: winRateLoss,
        );
        pending.analyses.add(analysis);
        pending.nextTurnToEmit += 1;
        pending.controller.add(
          PositionAnalyzed(
            pending.request.requestId,
            analysis: analysis,
            completedPositions: pending.analyses.length,
            totalPositions: pending.prepared!.totalPositions,
          ),
        );
      }

      if (pending.analyses.length == pending.prepared!.totalPositions) {
        final bundle = AnalysisBundle(
          requestId: pending.request.requestId,
          documentId: pending.request.document.id,
          boardSize: pending.request.document.boardSize,
          model: config.model,
          settings: pending.request.settings,
          moves: pending.analyses,
          completedAt: _clock().toUtc(),
        );
        _pending.remove(pending.request.requestId);
        pending.controller.add(
          AnalysisCompleted(pending.request.requestId, bundle: bundle),
        );
        unawaited(pending.controller.close());
      }
    } on Object catch (error, stackTrace) {
      _failPending(pending, error, stackTrace);
    }
  }

  Future<void> _cancelPending(
    _PendingAnalysis pending, {
    required bool emitEvent,
  }) async {
    final id = pending.request.requestId;
    if (_pending[id] != pending) return;
    _pending.remove(id);
    pending.cancelled = true;
    if (pending.querySent) {
      final channel = _channel;
      if (channel != null) {
        channel.sink.add(
          jsonEncode(<String, Object>{
            'id': '__lizzieyzy_terminate_${_terminateSequence++}',
            'action': 'terminate',
            'terminateId': id,
          }),
        );
      }
    }
    if (emitEvent && !pending.controller.isClosed) {
      pending.controller.add(AnalysisCancelled(id));
    }
    if (!pending.controller.isClosed) await pending.controller.close();
  }

  void _onSocketError(Object error, StackTrace stackTrace) {
    _disconnectSocket();
    _failAll(
      KataGoConnectionException('KataGo WebSocket failed: $error'),
      stackTrace,
    );
  }

  void _onSocketDone() {
    _disconnectSocket();
    if (!_closed && _pending.isNotEmpty) {
      _failAll(
        const KataGoConnectionException(
          'KataGo WebSocket closed before analysis completed.',
        ),
      );
    }
  }

  void _disconnectSocket() {
    _channel = null;
    _connectionFuture = null;
    _socketSubscription = null;
  }

  void _failAll(Object error, [StackTrace? stackTrace]) {
    for (final pending in _pending.values.toList(growable: false)) {
      _failPending(pending, error, stackTrace);
    }
  }

  void _failPending(
    _PendingAnalysis pending,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    final id = pending.request.requestId;
    if (_pending[id] == pending) _pending.remove(id);
    if (pending.controller.isClosed || pending.cancelled) return;
    pending.controller.addError(error, stackTrace ?? StackTrace.current);
    unawaited(pending.controller.close());
  }
}

final class _PendingAnalysis {
  _PendingAnalysis({required this.request, required this.controller});

  final AnalysisRequest request;
  final StreamController<AnalysisEvent> controller;
  KataGoProtocolRequest? prepared;
  final Map<int, KataGoTurnResult> results = {};
  final List<MoveAnalysis> analyses = [];
  var nextTurnToEmit = 0;
  var querySent = false;
  var cancelled = false;
}

WebSocketChannel _defaultConnector(
  Uri endpoint, {
  Map<String, dynamic>? headers,
  Duration? connectTimeout,
}) => IOWebSocketChannel.connect(
  endpoint,
  headers: headers,
  connectTimeout: connectTimeout,
);
