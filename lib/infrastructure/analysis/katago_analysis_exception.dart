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

base class KataGoConnectionException extends KataGoAnalysisException {
  const KataGoConnectionException(super.message, {super.requestId});
}

/// A connection or whole-request deadline elapsed.
final class KataGoTimeoutException extends KataGoConnectionException {
  const KataGoTimeoutException(super.message, {super.requestId});
}

base class KataGoProtocolException extends KataGoAnalysisException {
  const KataGoProtocolException(super.message, {super.requestId, super.field});
}

/// An inbound frame exceeded an explicit resource or complexity budget.
final class KataGoResponseLimitException extends KataGoProtocolException {
  const KataGoResponseLimitException(
    super.message, {
    super.requestId,
    super.field,
  });
}

base class KataGoRequestException extends KataGoAnalysisException {
  const KataGoRequestException(super.message, {super.requestId, super.field});
}

/// A syntactically valid error returned by the remote KataGo service.
final class KataGoRemoteException extends KataGoRequestException {
  const KataGoRemoteException(super.message, {super.requestId, super.field});
}

final class KataGoAnalysisCancelledException extends KataGoAnalysisException {
  const KataGoAnalysisCancelledException(String requestId)
    : super('Analysis was cancelled.', requestId: requestId);
}
