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
  final Set<String> _seenRequestIds = {};
  final Map<String, String> _pendingActions = {};
  final Map<String, _RetiredResponseBudget> _retiredResponses = {};
  WebSocketChannel? _channel;
  WebSocketChannel? _openingChannel;
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
    await _cancelSilently(subscription);
    final channel = _channel;
    _channel = null;
    final openingChannel = _openingChannel;
    _openingChannel = null;
    _connectionFuture = null;
    await _closeSilently(channel, status.normalClosure, 'Provider closed');
    if (!identical(openingChannel, channel)) {
      await _closeSilently(
        openingChannel,
        status.normalClosure,
        'Provider closed',
      );
    }
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
    if (requestId.length > config.maxRequestIdLength ||
        !_safeWireRequestId.hasMatch(requestId)) {
      _failPending(
        pending,
        const KataGoRequestException(
          'requestId is not a bounded, safe string.',
          field: 'requestId',
        ),
      );
      return;
    }
    if (_seenRequestIds.contains(requestId)) {
      _failPending(
        pending,
        KataGoRequestException(
          'A request id may be used only once for a provider instance.',
          requestId: requestId,
          field: 'requestId',
        ),
      );
      return;
    }
    if (_pending.length >= config.maxConcurrentRequests) {
      _failPending(
        pending,
        KataGoRequestException(
          'The provider has reached its concurrent-request budget.',
          requestId: requestId,
          field: 'requestId',
        ),
      );
      return;
    }
    if (_seenRequestIds.length >= config.maxRequestsPerProvider) {
      _failPending(
        pending,
        KataGoRequestException(
          'The provider has reached its lifetime request budget.',
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
    _seenRequestIds.add(requestId);
    _pending[requestId] = pending;
    pending.timeoutTimer = Timer(
      config.analysisTimeout,
      () => _timeoutPending(pending),
    );
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
      final wrapped = error is KataGoTimeoutException
          ? KataGoTimeoutException(
              'Timed out connecting to the KataGo analysis service.',
              requestId: pending.request.requestId,
            )
          : KataGoConnectionException(
              'Could not send the KataGo analysis request.',
              requestId: pending.request.requestId,
            );
      _abortForConnectionError(wrapped, stackTrace);
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
      _openingChannel = channel;
      await channel.ready.timeout(config.connectionTimeout);
      if (_closed) {
        await channel.sink.close(status.normalClosure, 'Provider closed');
        throw const KataGoConnectionException('Analysis provider is closed.');
      }
      _openingChannel = null;
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
      if (identical(_openingChannel, channel)) _openingChannel = null;
      if (channel != null) {
        try {
          await channel.sink.close(status.goingAway, 'Connection failed');
        } on Object {
          // Preserve the original connection error.
        }
      }
      if (_closed) {
        throw const KataGoConnectionException('Analysis provider is closed.');
      }
      if (error is TimeoutException) {
        throw const KataGoTimeoutException(
          'Timed out connecting to the KataGo analysis service.',
        );
      }
      // Connector errors can contain the endpoint, query parameters, or
      // headers. Keep transport internals out of the user-facing exception.
      throw const KataGoConnectionException(
        'Could not connect to the KataGo analysis service.',
      );
    }
  }

  void _onSocketData(dynamic data) {
    final String payload;
    try {
      payload = _decodeBoundedPayload(data);
      _validateLineCount(payload);
    } on Object catch (error, stackTrace) {
      _abortForProtocolError(
        error is KataGoAnalysisException
            ? error
            : const KataGoProtocolException(
                'WebSocket messages must be text or valid UTF-8 bytes.',
              ),
        stackTrace,
      );
      return;
    }

    for (final line in const LineSplitter().convert(payload)) {
      if (line.trim().isEmpty) continue;
      try {
        _validateJsonComplexity(line);
        final decoded = jsonDecode(line);
        if (decoded is! Map) {
          throw const FormatException('Response must be a JSON object.');
        }
        _handleResponse(
          decoded.cast<String, dynamic>(),
          responseBytes: utf8.encode(line).length,
        );
      } on Object catch (error, stackTrace) {
        if (error is KataGoResponseLimitException) {
          _abortForProtocolError(error, stackTrace);
          return;
        }
        if (error is KataGoAnalysisException && error.requestId != null) {
          final pending = _pending[error.requestId];
          if (pending != null) {
            if (error is KataGoProtocolException) _sendTerminate(pending);
            _failPending(pending, error, stackTrace);
            continue;
          }
        }
        _abortForProtocolError(
          error is KataGoAnalysisException
              ? error
              : const KataGoProtocolException('Malformed KataGo response.'),
          stackTrace,
        );
        return;
      }
    }
  }

  String _decodeBoundedPayload(dynamic data) {
    switch (data) {
      case String():
        // A UTF-8 byte can never consume fewer than one UTF-16 code unit for
        // the JSON protocol. This fast check avoids another large allocation.
        if (data.length > config.maxInboundMessageBytes) {
          throw const KataGoResponseLimitException(
            'WebSocket message exceeds the inbound byte budget.',
          );
        }
        final bytes = utf8.encode(data);
        if (bytes.length > config.maxInboundMessageBytes) {
          throw const KataGoResponseLimitException(
            'WebSocket message exceeds the inbound byte budget.',
          );
        }
        return data;
      case List<int>():
        if (data.length > config.maxInboundMessageBytes) {
          throw const KataGoResponseLimitException(
            'WebSocket message exceeds the inbound byte budget.',
          );
        }
        return utf8.decode(data, allowMalformed: false);
      default:
        throw const KataGoProtocolException(
          'WebSocket messages must be text or UTF-8 bytes.',
        );
    }
  }

  void _validateLineCount(String payload) {
    var lines = payload.isEmpty ? 0 : 1;
    for (final codeUnit in payload.codeUnits) {
      if (codeUnit == 0x0A) lines += 1;
      if (lines > config.maxLinesPerMessage) {
        throw const KataGoResponseLimitException(
          'WebSocket message exceeds the JSON-line budget.',
        );
      }
    }
  }

  void _validateJsonComplexity(String input) {
    var depth = 0;
    var structuralTokens = 0;
    var inString = false;
    var escaped = false;
    for (final codeUnit in input.codeUnits) {
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (codeUnit == 0x5C) {
          escaped = true;
        } else if (codeUnit == 0x22) {
          inString = false;
        }
        continue;
      }
      if (codeUnit == 0x22) {
        inString = true;
        continue;
      }
      if (codeUnit == 0x7B || codeUnit == 0x5B) {
        depth += 1;
        structuralTokens += 1;
        if (depth > config.maxJsonNestingDepth) {
          throw const KataGoResponseLimitException(
            'JSON response exceeds the nesting-depth budget.',
          );
        }
      } else if (codeUnit == 0x7D || codeUnit == 0x5D) {
        depth -= 1;
        structuralTokens += 1;
        if (depth < 0) {
          throw const KataGoProtocolException(
            'JSON response has unbalanced containers.',
          );
        }
      } else if (codeUnit == 0x2C || codeUnit == 0x3A) {
        structuralTokens += 1;
      }
      if (structuralTokens > config.maxJsonStructuralTokens) {
        throw const KataGoResponseLimitException(
          'JSON response exceeds the structural-complexity budget.',
        );
      }
    }
    if (depth != 0 || inString || escaped) {
      throw const KataGoProtocolException(
        'JSON response has unterminated content.',
      );
    }
  }

  void _handleResponse(
    Map<String, dynamic> json, {
    required int responseBytes,
  }) {
    if (json.containsKey('warning')) {
      final id = _responseId(json['id'], required: true)!;
      final pending = _pending[id];
      if (pending == null) {
        throw const KataGoProtocolException(
          'KataGo warning references an inactive request id.',
          field: 'id',
        );
      }
      _consumePendingResponseBudget(pending, responseBytes);
      final warning = json['warning'];
      if (warning is! String || warning.isEmpty || warning.length > 1024) {
        throw const KataGoProtocolException(
          'KataGo warnings must be bounded, non-empty strings.',
          field: 'warning',
        );
      }
      _responseField(json['field']);
      return;
    }

    final id = _responseId(json['id'], required: false);
    if (json.containsKey('error')) {
      final error = json['error'];
      if (error is! String || error.isEmpty || error.length > 1024) {
        throw const KataGoProtocolException(
          'KataGo error responses must contain a bounded, non-empty string.',
          field: 'error',
        );
      }
      final field = _responseField(json['field']);
      final exception = KataGoRemoteException(
        'KataGo rejected the analysis request.',
        requestId: id,
        field: field,
      );
      if (id == null) {
        _failAll(exception);
      } else {
        final pending = _pending[id];
        if (pending != null) {
          _consumePendingResponseBudget(pending, responseBytes);
          _failPending(pending, exception);
        } else {
          throw const KataGoProtocolException(
            'KataGo error references an inactive request id.',
            field: 'id',
          );
        }
      }
      return;
    }

    // Special-action acknowledgements (such as terminate) are not analyses.
    if (json.containsKey('action')) {
      final action = json['action'];
      if (action is! String ||
          action.isEmpty ||
          action.length > 64 ||
          !_safeWireAction.hasMatch(action)) {
        throw const KataGoProtocolException(
          'KataGo action must be a bounded, safe string.',
          field: 'action',
        );
      }
      final actionId = _responseId(json['id'], required: true)!;
      final expectedTerminateId = _pendingActions.remove(actionId);
      if (action != 'terminate' || expectedTerminateId == null) {
        throw const KataGoProtocolException(
          'KataGo action acknowledgement was not requested.',
          field: 'action',
        );
      }
      final terminateId = _responseId(json['terminateId'], required: true);
      if (terminateId != expectedTerminateId || json.length != 3) {
        throw const KataGoProtocolException(
          'KataGo terminate acknowledgement does not match the request.',
          field: 'terminateId',
        );
      }
      return;
    }
    if (id == null) {
      throw const KataGoProtocolException(
        'Analysis response is missing a string id.',
        field: 'id',
      );
    }
    final pending = _pending[id];
    if (pending == null) {
      final retired = _retiredResponses[id];
      if (retired != null) {
        retired.consume(json, responseBytes, config);
        if (retired.isComplete) _retiredResponses.remove(id);
        return;
      }
      throw const KataGoProtocolException(
        'KataGo response references an inactive request id.',
        field: 'id',
      );
    }
    _consumePendingResponseBudget(pending, responseBytes);

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

    if (pending.bufferedResponseBytes + responseBytes >
        config.maxBufferedResponseBytesPerRequest) {
      throw KataGoResponseLimitException(
        'Analysis exceeds the buffered-response byte budget.',
        requestId: id,
      );
    }

    final result = _protocol.parseFinalResult(json, pending.prepared!);
    if (result.turnNumber < pending.nextTurnToEmit ||
        pending.results.containsKey(result.turnNumber)) {
      throw KataGoProtocolException(
        'Received more than one final result for a turn.',
        requestId: id,
        field: 'turnNumber',
      );
    }
    pending.results[result.turnNumber] = result;
    pending.resultWireBytes[result.turnNumber] = responseBytes;
    pending.bufferedResponseBytes += responseBytes;
    _emitContiguousResults(pending);
  }

  void _consumePendingResponseBudget(
    _PendingAnalysis pending,
    int responseBytes,
  ) {
    pending.responseMessageCount += 1;
    if (pending.responseMessageCount > config.maxResponseMessagesPerRequest) {
      throw KataGoResponseLimitException(
        'Analysis exceeds the response-message budget.',
        requestId: pending.request.requestId,
      );
    }
    pending.responseByteCount += responseBytes;
    if (pending.responseByteCount > config.maxResponseBytesPerRequest) {
      throw KataGoResponseLimitException(
        'Analysis exceeds the cumulative response-byte budget.',
        requestId: pending.request.requestId,
      );
    }
  }

  String? _responseId(Object? value, {required bool required}) {
    if (value == null && !required) return null;
    if (value is! String ||
        value.isEmpty ||
        value.length > config.maxRequestIdLength ||
        !_safeWireRequestId.hasMatch(value)) {
      throw const KataGoProtocolException(
        'Response id is not a bounded, safe string.',
        field: 'id',
      );
    }
    return value;
  }

  String? _responseField(Object? value) {
    if (value == null) return null;
    if (value is! String ||
        value.isEmpty ||
        value.length > 128 ||
        !_safeWireField.hasMatch(value)) {
      throw const KataGoProtocolException(
        'Response error field is not a bounded, safe string.',
        field: 'field',
      );
    }
    return value;
  }

  void _emitContiguousResults(_PendingAnalysis pending) {
    try {
      while (pending.results.containsKey(pending.nextTurnToEmit)) {
        final turnNumber = pending.nextTurnToEmit;
        final result = pending.results[turnNumber]!;
        Move? playedMove;
        double? pointLoss;
        double? winRateLoss;
        double? playedMovePolicy;
        double? playedMoveHumanPolicy;

        if (turnNumber > 0) {
          playedMove = pending.prepared!.moves[turnNumber - 1];
          final before = pending.results[turnNumber - 1]!;
          final best = before.bestCandidate.candidate;
          playedMovePolicy = before.policyForMove(
            playedMove,
            pending.request.document.boardSize,
          );
          playedMoveHumanPolicy = before.humanPolicyForMove(
            playedMove,
            pending.request.document.boardSize,
          );
          if (config.humanStyleProfile != null &&
              playedMoveHumanPolicy == null) {
            throw KataGoProtocolException(
              'The configured HumanSL query omitted played-move humanPolicy.',
              requestId: pending.request.requestId,
              field: 'humanPolicy',
            );
          }
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
          playedMovePolicy: playedMovePolicy,
          playedMoveHumanPolicy: playedMoveHumanPolicy,
        );
        pending.analyses.add(analysis);
        pending.nextTurnToEmit += 1;
        if (turnNumber > 0) {
          pending.results.remove(turnNumber - 1);
          pending.bufferedResponseBytes -=
              pending.resultWireBytes.remove(turnNumber - 1) ?? 0;
        }
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
        pending.results.clear();
        pending.resultWireBytes.clear();
        pending.bufferedResponseBytes = 0;
        pending.timeoutTimer?.cancel();
        pending.timeoutTimer = null;
        pending.controller.add(
          AnalysisCompleted(pending.request.requestId, bundle: bundle),
        );
        unawaited(pending.controller.close());
      }
    } on Object catch (error, stackTrace) {
      _sendTerminate(pending);
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
    pending.timeoutTimer?.cancel();
    pending.timeoutTimer = null;
    _sendTerminate(pending);
    if (emitEvent && !pending.controller.isClosed) {
      pending.controller.add(AnalysisCancelled(id));
    }
    if (!pending.controller.isClosed) await pending.controller.close();
  }

  void _timeoutPending(_PendingAnalysis pending) {
    final id = pending.request.requestId;
    if (_pending[id] != pending) return;
    _sendTerminate(pending);
    _failPending(
      pending,
      KataGoTimeoutException(
        'KataGo analysis exceeded its deadline.',
        requestId: id,
      ),
    );
  }

  void _sendTerminate(_PendingAnalysis pending) {
    if (!pending.querySent) return;
    final channel = _channel;
    if (channel == null) return;
    final actionId = '__lizzieyzy_terminate_${_terminateSequence++}';
    _pendingActions[actionId] = pending.request.requestId;
    _retiredResponses.putIfAbsent(
      pending.request.requestId,
      () => _RetiredResponseBudget(pending.prepared!.totalPositions),
    );
    try {
      channel.sink.add(
        jsonEncode(<String, Object>{
          'id': actionId,
          'action': 'terminate',
          'terminateId': pending.request.requestId,
        }),
      );
    } on Object {
      _pendingActions.remove(actionId);
      // The request is already terminal locally. The socket error/done handler
      // remains responsible for any other active requests.
    }
  }

  void _onSocketError(Object _, StackTrace stackTrace) {
    _abortForConnectionError(
      const KataGoConnectionException('KataGo WebSocket transport failed.'),
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
    _pendingActions.clear();
    _retiredResponses.clear();
  }

  void _abortForProtocolError(Object error, [StackTrace? stackTrace]) {
    final subscription = _socketSubscription;
    final channel = _channel;
    _disconnectSocket();
    _failAll(error, stackTrace);
    unawaited(_cancelSilently(subscription));
    unawaited(
      _closeSilently(channel, status.protocolError, 'Invalid KataGo response'),
    );
  }

  void _abortForConnectionError(Object error, [StackTrace? stackTrace]) {
    final subscription = _socketSubscription;
    final channel = _channel;
    _disconnectSocket();
    _failAll(error, stackTrace);
    unawaited(_cancelSilently(subscription));
    unawaited(_closeSilently(channel, status.goingAway, 'Transport failed'));
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
    pending.timeoutTimer?.cancel();
    pending.timeoutTimer = null;
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
  final Map<int, int> resultWireBytes = {};
  final List<MoveAnalysis> analyses = [];
  var nextTurnToEmit = 0;
  var responseMessageCount = 0;
  var responseByteCount = 0;
  var bufferedResponseBytes = 0;
  var querySent = false;
  var cancelled = false;
  Timer? timeoutTimer;
}

final class _RetiredResponseBudget {
  _RetiredResponseBudget(this.totalPositions)
    : remainingFinalResponses = totalPositions;

  final int totalPositions;
  int remainingFinalResponses;
  final Set<int> _finalTurns = <int>{};
  var messageCount = 0;
  var responseBytes = 0;

  bool get isComplete => remainingFinalResponses == 0;

  void consume(
    Map<String, dynamic> json,
    int wireBytes,
    KataGoWssConfig config,
  ) {
    messageCount += 1;
    responseBytes += wireBytes;
    if (messageCount > config.maxResponseMessagesPerRequest ||
        responseBytes > config.maxResponseBytesPerRequest) {
      throw const KataGoResponseLimitException(
        'A terminated analysis exceeded its late-response budget.',
      );
    }
    final duringSearch = json['isDuringSearch'];
    final turnNumber = json['turnNumber'];
    if (duringSearch is! bool ||
        turnNumber is! num ||
        !turnNumber.isFinite ||
        turnNumber != turnNumber.roundToDouble() ||
        turnNumber < 0 ||
        turnNumber >= totalPositions) {
      throw const KataGoProtocolException(
        'A terminated analysis returned malformed late data.',
      );
    }
    if (!duringSearch) {
      final turn = turnNumber.toInt();
      if (remainingFinalResponses == 0 || !_finalTurns.add(turn)) {
        throw const KataGoProtocolException(
          'A terminated analysis returned too many final responses.',
        );
      }
      remainingFinalResponses -= 1;
    }
  }
}

final RegExp _safeWireRequestId = RegExp(r'^[A-Za-z0-9._:-]+$');
final RegExp _safeWireField = RegExp(r'^[A-Za-z0-9_.\[\]-]+$');
final RegExp _safeWireAction = RegExp(r'^[A-Za-z0-9_-]+$');

Future<void> _cancelSilently(StreamSubscription<dynamic>? subscription) async {
  if (subscription == null) return;
  try {
    await subscription.cancel();
  } on Object {
    // Closing is best-effort and must not surface transport internals.
  }
}

Future<void> _closeSilently(
  WebSocketChannel? channel,
  int closeCode,
  String closeReason,
) async {
  if (channel == null) return;
  try {
    await channel.sink.close(closeCode, closeReason);
  } on Object {
    // Closing is best-effort and must not surface transport internals.
  }
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
