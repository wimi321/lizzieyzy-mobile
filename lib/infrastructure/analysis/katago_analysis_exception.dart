import '../../domain/domain.dart';

sealed class KataGoAnalysisException implements Exception {
  const KataGoAnalysisException(this.message, {this.requestId, this.field});

  final String message;
  final String? requestId;
  final String? field;

  @override
  String toString() {
    final context = <String>[
      if (requestId != null) 'request=$requestId',
      if (field != null) 'field=$field',
    ];
    return '${runtimeType.toString()}: $message'
        '${context.isEmpty ? '' : ' (${context.join(', ')})'}';
  }
}

final class KataGoConnectionException extends KataGoAnalysisException {
  const KataGoConnectionException(super.message, {super.requestId});
}

final class KataGoProtocolException extends KataGoAnalysisException {
  const KataGoProtocolException(super.message, {super.requestId, super.field});
}

final class KataGoRequestException extends KataGoAnalysisException {
  const KataGoRequestException(super.message, {super.requestId, super.field});
}

final class KataGoMissingPlayedMoveException extends KataGoAnalysisException {
  const KataGoMissingPlayedMoveException({
    required String requestId,
    required this.turnNumber,
    required this.playedMove,
  }) : super(
         'The previous position did not contain the played move in moveInfos; '
         'loss cannot be verified.',
         requestId: requestId,
         field: 'moveInfos',
       );

  final int turnNumber;
  final Move playedMove;

  @override
  String toString() =>
      '${super.toString()} (turn=$turnNumber, move=$playedMove)';
}

final class KataGoAnalysisCancelledException extends KataGoAnalysisException {
  const KataGoAnalysisCancelledException(String requestId)
    : super('Analysis was cancelled.', requestId: requestId);
}
