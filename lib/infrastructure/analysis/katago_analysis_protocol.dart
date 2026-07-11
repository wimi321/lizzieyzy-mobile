import 'dart:math' as math;

import '../../domain/domain.dart';
import 'katago_analysis_exception.dart';
import 'katago_wss_config.dart';

final class KataGoProtocolRequest {
  const KataGoProtocolRequest({
    required this.request,
    required this.initialPosition,
    required this.moves,
    required this.firstPlayer,
    required this.json,
  });

  final AnalysisRequest request;
  final BoardPosition initialPosition;
  final List<Move> moves;
  final StoneColor firstPlayer;
  final Map<String, Object> json;

  int get totalPositions => moves.length + 1;

  StoneColor playerAtTurn(int turnNumber) =>
      turnNumber.isEven ? firstPlayer : firstPlayer.opponent;
}

final class KataGoCandidateResult {
  const KataGoCandidateResult({required this.order, required this.candidate});

  final int order;
  final Candidate candidate;
}

final class KataGoTurnResult {
  const KataGoTurnResult({
    required this.turnNumber,
    required this.currentPlayer,
    required this.blackWinRate,
    required this.currentPlayerWinRate,
    required this.blackScoreLead,
    required this.visits,
    required this.candidates,
    required this.ownership,
  });

  final int turnNumber;
  final StoneColor currentPlayer;
  final double blackWinRate;
  final double currentPlayerWinRate;
  final double blackScoreLead;
  final int visits;
  final List<KataGoCandidateResult> candidates;
  final List<double> ownership;

  KataGoCandidateResult get bestCandidate {
    for (final result in candidates) {
      if (result.order == 0) return result;
    }
    throw StateError('KataGo result has no order-0 candidate.');
  }

  bool containsMove(Move move) =>
      candidates.any((result) => result.candidate.move == move);

  MoveAnalysis toDomain({
    required int maxCandidates,
    required Move? playedMove,
    double? pointLoss,
    double? winRateLoss,
  }) => MoveAnalysis(
    moveNumber: turnNumber,
    toPlay: currentPlayer,
    playedMove: playedMove,
    blackWinRate: blackWinRate,
    scoreLead: blackScoreLead,
    visits: visits,
    candidates: candidates
        .take(maxCandidates)
        .map((result) => result.candidate)
        .toList(growable: false),
    playedMovePointLoss: pointLoss,
    playedMoveWinRateLoss: winRateLoss,
    ownership: ownership,
  );
}

final class KataGoAnalysisProtocol {
  const KataGoAnalysisProtocol(this.config);

  final KataGoWssConfig config;

  KataGoProtocolRequest prepare(AnalysisRequest request) {
    final document = request.document;
    final BoardPosition initialPosition;
    final List<Move> moves;
    final StoneColor firstPlayer;

    switch (document) {
      case PositionSnapshot():
        initialPosition = document.position;
        moves = const [];
        firstPlayer =
            document.playerToMove ??
            (throw KataGoRequestException(
              'A position snapshot must declare playerToMove before analysis.',
              requestId: request.requestId,
              field: 'playerToMove',
            ));
      case PartialGameRecord():
        initialPosition = document.initialPosition;
        moves = document.moves;
        firstPlayer = document.firstPlayer;
      case VerifiedGameRecord():
        initialPosition = document.initialPosition;
        moves = document.moves;
        firstPlayer = document.firstPlayer;
    }

    final dimension = document.boardSize.dimension;
    final initialStones = initialPosition.stones.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));

    final json = <String, Object>{
      'id': request.requestId,
      'initialStones': [
        for (final entry in initialStones)
          [entry.value.sgfValue, entry.key.toGtp(document.boardSize)],
      ],
      'initialPlayer': firstPlayer.sgfValue,
      'moves': [
        for (final move in moves)
          [move.color.sgfValue, _moveLocation(move, document.boardSize)],
      ],
      'rules': _rulesName(document.rules.ruleSet),
      'komi': document.rules.komi,
      'boardXSize': dimension,
      'boardYSize': dimension,
      'analyzeTurns': List<int>.generate(moves.length + 1, (index) => index),
      'maxVisits': request.settings.visitsPerMove,
      'analysisPVLen': config.analysisPvLength,
      'includeOwnership': request.settings.includeOwnership,
      'includePolicy': true,
    };

    return KataGoProtocolRequest(
      request: request,
      initialPosition: initialPosition,
      moves: List.unmodifiable(moves),
      firstPlayer: firstPlayer,
      json: Map.unmodifiable(json),
    );
  }

  KataGoTurnResult parseFinalResult(
    Map<String, dynamic> json,
    KataGoProtocolRequest prepared,
  ) {
    final requestId = prepared.request.requestId;
    final turnNumber = _requiredInteger(
      json,
      'turnNumber',
      requestId: requestId,
      min: 0,
    );
    if (turnNumber >= prepared.totalPositions) {
      throw KataGoProtocolException(
        'turnNumber is outside the requested analyzeTurns range.',
        requestId: requestId,
        field: 'turnNumber',
      );
    }

    final rootInfo = _requiredMap(json, 'rootInfo', requestId: requestId);
    final currentPlayer = _parseColor(
      _requiredString(rootInfo, 'currentPlayer', requestId: requestId),
      requestId: requestId,
      field: 'rootInfo.currentPlayer',
    );
    final expectedPlayer = prepared.playerAtTurn(turnNumber);
    if (currentPlayer != expectedPlayer) {
      throw KataGoProtocolException(
        'rootInfo.currentPlayer does not match the submitted move sequence.',
        requestId: requestId,
        field: 'rootInfo.currentPlayer',
      );
    }

    final rawRootWinRate = _requiredProbability(
      rootInfo,
      'winrate',
      requestId: requestId,
    );
    final rawRootScore = _requiredFiniteNumber(
      rootInfo,
      'scoreLead',
      requestId: requestId,
    );
    final visits = _requiredInteger(
      rootInfo,
      'visits',
      requestId: requestId,
      min: 0,
    );
    final outputIsBlack = _outputPerspectiveIsBlack(currentPlayer);
    final blackWinRate = outputIsBlack ? rawRootWinRate : 1 - rawRootWinRate;
    final currentPlayerWinRate =
        outputIsBlack == (currentPlayer == StoneColor.black)
        ? rawRootWinRate
        : 1 - rawRootWinRate;
    final blackScoreLead = outputIsBlack ? rawRootScore : -rawRootScore;

    final rawPolicy = _optionalPolicy(
      json['policy'],
      boardSize: prepared.request.document.boardSize,
      requestId: requestId,
    );
    final moveInfoValues = json['moveInfos'];
    if (moveInfoValues is! List) {
      throw KataGoProtocolException(
        'moveInfos must be a JSON array.',
        requestId: requestId,
        field: 'moveInfos',
      );
    }

    final candidates = <KataGoCandidateResult>[];
    final orders = <int>{};
    final moves = <Move>{};
    for (var index = 0; index < moveInfoValues.length; index++) {
      final value = moveInfoValues[index];
      if (value is! Map) {
        throw KataGoProtocolException(
          'Each moveInfos entry must be a JSON object.',
          requestId: requestId,
          field: 'moveInfos[$index]',
        );
      }
      final info = value.cast<String, dynamic>();
      final order = _requiredInteger(
        info,
        'order',
        requestId: requestId,
        min: 0,
      );
      if (!orders.add(order)) {
        throw KataGoProtocolException(
          'moveInfos contains a duplicate order.',
          requestId: requestId,
          field: 'moveInfos[$index].order',
        );
      }
      final location = _requiredString(info, 'move', requestId: requestId);
      final move = _parseMove(
        location,
        currentPlayer,
        prepared.request.document.boardSize,
        requestId: requestId,
        field: 'moveInfos[$index].move',
      );
      if (!moves.add(move)) {
        throw KataGoProtocolException(
          'moveInfos contains a duplicate move.',
          requestId: requestId,
          field: 'moveInfos[$index].move',
        );
      }
      final rawWinRate = _requiredProbability(
        info,
        'winrate',
        requestId: requestId,
      );
      final rawScoreLead = _requiredFiniteNumber(
        info,
        'scoreLead',
        requestId: requestId,
      );
      final candidateVisits = _requiredInteger(
        info,
        'visits',
        requestId: requestId,
        min: 0,
      );
      final prior = info.containsKey('prior')
          ? _requiredProbability(info, 'prior', requestId: requestId)
          : _policyForMove(
              rawPolicy,
              move,
              prepared.request.document.boardSize,
            );
      if (prior == null) {
        throw KataGoProtocolException(
          'A moveInfo must contain prior, or the response must contain policy.',
          requestId: requestId,
          field: 'moveInfos[$index].prior',
        );
      }
      final rawPv = info['pv'];
      if (rawPv is! List) {
        throw KataGoProtocolException(
          'pv must be a JSON array.',
          requestId: requestId,
          field: 'moveInfos[$index].pv',
        );
      }
      final pv = <Move>[];
      var pvPlayer = currentPlayer;
      for (var pvIndex = 0; pvIndex < rawPv.length; pvIndex++) {
        final pvLocation = rawPv[pvIndex];
        if (pvLocation is! String) {
          throw KataGoProtocolException(
            'PV locations must be strings.',
            requestId: requestId,
            field: 'moveInfos[$index].pv[$pvIndex]',
          );
        }
        pv.add(
          _parseMove(
            pvLocation,
            pvPlayer,
            prepared.request.document.boardSize,
            requestId: requestId,
            field: 'moveInfos[$index].pv[$pvIndex]',
          ),
        );
        pvPlayer = pvPlayer.opponent;
      }

      final candidateCurrentWinRate =
          outputIsBlack == (currentPlayer == StoneColor.black)
          ? rawWinRate
          : 1 - rawWinRate;
      candidates.add(
        KataGoCandidateResult(
          order: order,
          candidate: Candidate(
            move: move,
            winRate: candidateCurrentWinRate,
            scoreLead: outputIsBlack ? rawScoreLead : -rawScoreLead,
            visits: candidateVisits,
            policy: prior,
            principalVariation: pv,
          ),
        ),
      );
    }
    candidates.sort((left, right) => left.order.compareTo(right.order));
    if (candidates.isEmpty || candidates.first.order != 0) {
      throw KataGoProtocolException(
        'A final result must contain an order-0 candidate.',
        requestId: requestId,
        field: 'moveInfos',
      );
    }

    final ownership = _parseOwnership(
      json['ownership'],
      required: prepared.request.settings.includeOwnership,
      boardSize: prepared.request.document.boardSize,
      outputIsBlack: outputIsBlack,
      requestId: requestId,
    );

    return KataGoTurnResult(
      turnNumber: turnNumber,
      currentPlayer: currentPlayer,
      blackWinRate: blackWinRate,
      currentPlayerWinRate: currentPlayerWinRate,
      blackScoreLead: blackScoreLead,
      visits: visits,
      candidates: List.unmodifiable(candidates),
      ownership: List.unmodifiable(ownership),
    );
  }

  bool _outputPerspectiveIsBlack(StoneColor currentPlayer) =>
      switch (config.reportAnalysisWinratesAs) {
        KataGoReportPerspective.black => true,
        KataGoReportPerspective.white => false,
        KataGoReportPerspective.sideToMove => currentPlayer == StoneColor.black,
      };
}

String _moveLocation(Move move, BoardSize boardSize) =>
    move.isPass ? 'pass' : move.point!.toGtp(boardSize);

String _rulesName(RuleSet rules) => switch (rules) {
  RuleSet.chinese => 'chinese',
  RuleSet.japanese => 'japanese',
  RuleSet.korean => 'korean',
  RuleSet.aga => 'aga',
  RuleSet.newZealand => 'new-zealand',
  RuleSet.trompTaylor => 'tromp-taylor',
};

StoneColor _parseColor(
  String value, {
  required String requestId,
  required String field,
}) => switch (value.toUpperCase()) {
  'B' => StoneColor.black,
  'W' => StoneColor.white,
  _ => throw KataGoProtocolException(
    'Player must be B or W.',
    requestId: requestId,
    field: field,
  ),
};

Move _parseMove(
  String value,
  StoneColor color,
  BoardSize boardSize, {
  required String requestId,
  required String field,
}) {
  if (value.toLowerCase() == 'pass') return Move.pass(color: color);
  final match = RegExp(
    r'^([A-HJ-Z])(\d{1,2})$',
    caseSensitive: false,
  ).firstMatch(value.trim());
  if (match == null) {
    throw KataGoProtocolException(
      'Move is not a supported GTP coordinate.',
      requestId: requestId,
      field: field,
    );
  }
  final letter = match.group(1)!.toUpperCase().codeUnitAt(0);
  var column = letter - 'A'.codeUnitAt(0);
  if (letter > 'I'.codeUnitAt(0)) column -= 1;
  final gtpRow = int.parse(match.group(2)!);
  final point = BoardPoint(column, boardSize.dimension - gtpRow);
  if (!point.isOn(boardSize)) {
    throw KataGoProtocolException(
      'Move lies outside the board.',
      requestId: requestId,
      field: field,
    );
  }
  return Move.play(color: color, point: point);
}

Map<String, dynamic> _requiredMap(
  Map<String, dynamic> json,
  String field, {
  required String requestId,
}) {
  final value = json[field];
  if (value is! Map) {
    throw KataGoProtocolException(
      '$field must be a JSON object.',
      requestId: requestId,
      field: field,
    );
  }
  return value.cast<String, dynamic>();
}

String _requiredString(
  Map<String, dynamic> json,
  String field, {
  required String requestId,
}) {
  final value = json[field];
  if (value is! String || value.isEmpty) {
    throw KataGoProtocolException(
      '$field must be a non-empty string.',
      requestId: requestId,
      field: field,
    );
  }
  return value;
}

int _requiredInteger(
  Map<String, dynamic> json,
  String field, {
  required String requestId,
  required int min,
}) {
  final value = json[field];
  if (value is! num || !value.isFinite || value != value.roundToDouble()) {
    throw KataGoProtocolException(
      '$field must be an integer.',
      requestId: requestId,
      field: field,
    );
  }
  final integer = value.toInt();
  if (integer < min) {
    throw KataGoProtocolException(
      '$field must be at least $min.',
      requestId: requestId,
      field: field,
    );
  }
  return integer;
}

double _requiredFiniteNumber(
  Map<String, dynamic> json,
  String field, {
  required String requestId,
}) {
  final value = json[field];
  if (value is! num || !value.isFinite) {
    throw KataGoProtocolException(
      '$field must be a finite number.',
      requestId: requestId,
      field: field,
    );
  }
  return value.toDouble();
}

double _requiredProbability(
  Map<String, dynamic> json,
  String field, {
  required String requestId,
}) {
  final value = _requiredFiniteNumber(json, field, requestId: requestId);
  if (value < 0 || value > 1) {
    throw KataGoProtocolException(
      '$field must be between zero and one.',
      requestId: requestId,
      field: field,
    );
  }
  return value;
}

List<double>? _optionalPolicy(
  Object? value, {
  required BoardSize boardSize,
  required String requestId,
}) {
  if (value == null) return null;
  if (value is! List ||
      value.length != boardSize.dimension * boardSize.dimension + 1) {
    throw KataGoProtocolException(
      'policy must contain one value per intersection plus pass.',
      requestId: requestId,
      field: 'policy',
    );
  }
  return List<double>.generate(value.length, (index) {
    final entry = value[index];
    if (entry is! num || !entry.isFinite || entry < -1 || entry > 1) {
      throw KataGoProtocolException(
        'policy values must be finite and between -1 and 1.',
        requestId: requestId,
        field: 'policy[$index]',
      );
    }
    return entry.toDouble();
  }, growable: false);
}

double? _policyForMove(List<double>? policy, Move move, BoardSize boardSize) {
  if (policy == null) return null;
  final index = move.isPass
      ? policy.length - 1
      : move.point!.row * boardSize.dimension + move.point!.column;
  return math.max(0, policy[index]);
}

List<double> _parseOwnership(
  Object? value, {
  required bool required,
  required BoardSize boardSize,
  required bool outputIsBlack,
  required String requestId,
}) {
  if (value == null && !required) return const [];
  final expectedLength = boardSize.dimension * boardSize.dimension;
  if (value is! List || value.length != expectedLength) {
    throw KataGoProtocolException(
      'ownership must contain one value per board intersection.',
      requestId: requestId,
      field: 'ownership',
    );
  }
  return List<double>.generate(expectedLength, (index) {
    final raw = value[index];
    if (raw is! num || !raw.isFinite || raw < -1 || raw > 1) {
      throw KataGoProtocolException(
        'ownership values must be finite and between -1 and 1.',
        requestId: requestId,
        field: 'ownership[$index]',
      );
    }
    final result = raw.toDouble();
    return outputIsBlack ? result : -result;
  }, growable: false);
}
