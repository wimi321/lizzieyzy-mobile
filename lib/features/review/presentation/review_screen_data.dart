import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:lizzieyzy_mobile/design_system/design_system.dart' as ui;
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

@immutable
final class ReviewScreenData {
  ReviewScreenData({
    required this.record,
    required this.analysis,
    required this.report,
    this.performanceReport,
  }) : timeline = domain.GameReplayTimeline.fromRecord(record) {
    if (analysis.documentId != record.id || report.documentId != record.id) {
      throw ArgumentError('Review data must belong to the same document.');
    }
    if (report.analysisRequestId != analysis.requestId) {
      throw ArgumentError('Review report and analysis request do not match.');
    }
    if (analysis.boardSize != record.boardSize) {
      throw ArgumentError('Review analysis and record board sizes differ.');
    }
    if (analysis.moves.length != record.moves.length + 1) {
      throw ArgumentError('Review analysis must contain every position.');
    }
    for (var moveNumber = 0; moveNumber < analysis.moves.length; moveNumber++) {
      final node = analysis.moves[moveNumber];
      final playedMove = moveNumber == 0 ? null : record.moves[moveNumber - 1];
      final toPlay = moveNumber == 0
          ? record.firstPlayer
          : record.moves[moveNumber - 1].color.opponent;
      if (node.moveNumber != moveNumber ||
          node.playedMove != playedMove ||
          node.toPlay != toPlay) {
        throw ArgumentError(
          'Review analysis does not match the verified move sequence.',
        );
      }
    }
    if (report.keyMoments.any(
          (moment) =>
              moment.moveNumber < 1 || moment.moveNumber > record.moves.length,
        ) ||
        report.scoreTrend.any(
          (point) =>
              point.moveNumber < 0 || point.moveNumber > record.moves.length,
        )) {
      throw ArgumentError('Review report contains out-of-range move numbers.');
    }
  }

  final domain.VerifiedGameRecord record;
  final domain.AnalysisBundle analysis;
  final domain.ReviewReport report;
  final domain.GamePerformanceReport? performanceReport;
  final domain.GameReplayTimeline timeline;

  int get totalMoves => record.moves.length;
  List<int> get keyMoveNumbers => report.keyMoments
      .map((moment) => moment.moveNumber)
      .toList(growable: false);

  domain.KeyMoment? get primaryMoment =>
      report.keyMoments.isEmpty ? null : report.keyMoments.first;

  domain.KeyMoment? momentAt(int moveNumber) {
    for (final moment in report.keyMoments) {
      if (moment.moveNumber == moveNumber) return moment;
    }
    return null;
  }

  domain.MoveAnalysis beforeMove(int moveNumber) {
    if (moveNumber < 1 || moveNumber > totalMoves) {
      throw RangeError.range(moveNumber, 1, totalMoves, 'moveNumber');
    }
    return analysis.analysisAt(moveNumber - 1)!;
  }

  domain.MoveAnalysis afterMove(int moveNumber) {
    if (moveNumber < 1 || moveNumber > totalMoves) {
      throw RangeError.range(moveNumber, 1, totalMoves, 'moveNumber');
    }
    return analysis.analysisAt(moveNumber)!;
  }

  domain.BoardPosition positionBeforeMove(int moveNumber) =>
      timeline.positionBeforeMove(moveNumber);

  List<ui.BoardStone> stonesBeforeMove(int moveNumber) =>
      boardStones(positionBeforeMove(moveNumber));

  List<ui.BoardCandidate> candidatesBeforeMove(
    int moveNumber, [
    AppLocalizations? strings,
  ]) {
    final l10n = strings ?? _zh;
    final node = beforeMove(moveNumber);
    return <ui.BoardCandidate>[
      for (var index = 0; index < node.candidates.length; index++)
        if (!node.candidates[index].move.isPass)
          ui.BoardCandidate(
            point: uiPoint(node.candidates[index].move.point!),
            label: String.fromCharCode(65 + index),
            detail: formatScore(node.candidates[index].scoreLead, l10n),
            tone: switch (index) {
              0 => ui.CandidateTone.primary,
              1 => ui.CandidateTone.secondary,
              _ => ui.CandidateTone.tertiary,
            },
          ),
    ];
  }

  String get title => localizedTitle(_zh);

  String localizedTitle(AppLocalizations l10n) {
    final black = record.metadata.blackPlayer ?? l10n.blackPlayerFallback;
    final white = record.metadata.whitePlayer ?? l10n.whitePlayerFallback;
    return l10n.playerVersus(black, white);
  }

  String get subtitle => localizedSubtitle(_zh);

  String localizedSubtitle(AppLocalizations l10n) {
    final rules = switch (record.rules.ruleSet) {
      domain.RuleSet.chinese => l10n.ruleChinese,
      domain.RuleSet.japanese => l10n.ruleJapanese,
      domain.RuleSet.korean => l10n.ruleKorean,
      domain.RuleSet.aga => l10n.ruleAga,
      domain.RuleSet.newZealand => l10n.ruleNewZealand,
      domain.RuleSet.trompTaylor => l10n.ruleTrompTaylor,
    };
    final result = formatResult(record.metadata.result, l10n);
    return l10n.reviewSubtitle(rules, result, l10n.moveCount(totalMoves));
  }
}

@immutable
final class PositionAnalysisData {
  PositionAnalysisData({required this.snapshot, required this.analysis}) {
    if (snapshot.playerToMove == null ||
        analysis.documentId != snapshot.id ||
        analysis.boardSize != snapshot.boardSize ||
        analysis.moves.length != 1 ||
        analysis.moves.single.moveNumber != 0 ||
        analysis.moves.single.playedMove != null ||
        analysis.moves.single.toPlay != snapshot.playerToMove) {
      throw ArgumentError('Position analysis must contain exactly its root.');
    }
    for (final candidate in analysis.moves.single.candidates) {
      if (candidate.move.color != snapshot.playerToMove ||
          (!candidate.move.isPass &&
              !candidate.move.point!.isOn(snapshot.boardSize))) {
        throw ArgumentError('Position analysis contains an invalid candidate.');
      }
    }
  }

  final domain.PositionSnapshot snapshot;
  final domain.AnalysisBundle analysis;

  domain.MoveAnalysis get root => analysis.moves.single;
  List<ui.BoardStone> get stones => boardStones(snapshot.position);
  List<ui.BoardCandidate> candidatesFor([AppLocalizations? strings]) {
    final l10n = strings ?? _zh;
    return <ui.BoardCandidate>[
      for (var index = 0; index < root.candidates.length; index++)
        if (!root.candidates[index].move.isPass)
          ui.BoardCandidate(
            point: uiPoint(root.candidates[index].move.point!),
            label: String.fromCharCode(65 + index),
            detail: formatScore(root.candidates[index].scoreLead, l10n),
            tone: switch (index) {
              0 => ui.CandidateTone.primary,
              1 => ui.CandidateTone.secondary,
              _ => ui.CandidateTone.tertiary,
            },
          ),
    ];
  }

  List<ui.BoardCandidate> get candidates => candidatesFor();
}

@immutable
final class ReviewMoveSelection {
  ReviewMoveSelection({required this.data, required this.moveNumber}) {
    if (moveNumber < 1 || moveNumber > data.totalMoves) {
      throw RangeError.range(moveNumber, 1, data.totalMoves, 'moveNumber');
    }
  }

  final ReviewScreenData data;
  final int moveNumber;
}

List<ui.BoardStone> boardStones(domain.BoardPosition position) =>
    <ui.BoardStone>[
      for (final entry in position.stones.entries)
        ui.BoardStone(
          point: uiPoint(entry.key),
          color: entry.value == domain.StoneColor.black
              ? ui.StoneColor.black
              : ui.StoneColor.white,
        ),
    ];

ui.BoardPoint uiPoint(domain.BoardPoint point) =>
    ui.BoardPoint(point.column, point.row);

final AppLocalizations _zh = lookupAppLocalizations(const Locale('zh'));

String formatMove(
  domain.Move move,
  domain.BoardSize size, [
  AppLocalizations? strings,
]) => move.isPass ? (strings ?? _zh).passMove : move.point!.toGtp(size);

String formatScore(double scoreLead, [AppLocalizations? strings]) {
  final l10n = strings ?? _zh;
  final prefix = scoreLead > 0 ? '+' : '';
  return l10n.pointsValue('$prefix${scoreLead.toStringAsFixed(1)}');
}

String formatPercent(double probability) =>
    '${(probability * 100).toStringAsFixed(1)}%';

String formatPercentagePointLoss(double? probability) =>
    probability == null ? '—' : '-${(probability * 100).toStringAsFixed(1)}pp';

String formatPointLoss(double? points, [AppLocalizations? strings]) =>
    points == null
    ? '—'
    : (strings ?? _zh).pointLossValue(points.toStringAsFixed(1));

String formatVisits(int visits) {
  final digits = visits.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

String formatResult(domain.GameResult? result, [AppLocalizations? strings]) {
  final l10n = strings ?? _zh;
  if (result == null || result.type == domain.ResultType.unknown) {
    return l10n.resultUnknown;
  }
  return switch (result.type) {
    domain.ResultType.blackWin =>
      result.margin == null
          ? l10n.blackWins
          : l10n.blackWinsBy(result.margin!.toStringAsFixed(1)),
    domain.ResultType.whiteWin =>
      result.margin == null
          ? l10n.whiteWins
          : l10n.whiteWinsBy(result.margin!.toStringAsFixed(1)),
    domain.ResultType.draw => l10n.drawResult,
    domain.ResultType.voided => l10n.voidedResult,
    domain.ResultType.unknown => l10n.resultUnknown,
  };
}
