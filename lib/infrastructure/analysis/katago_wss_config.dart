import 'package:web_socket_channel/web_socket_channel.dart';

import '../../domain/domain.dart';

/// The perspective configured by `reportAnalysisWinratesAs` in KataGo's
/// Analysis Engine configuration.
///
/// KataGo does not echo this setting in responses, so a client must declare it
/// explicitly and use the same value as the remote engine configuration.
enum KataGoReportPerspective {
  black('BLACK'),
  white('WHITE'),
  sideToMove('SIDETOMOVE');

  const KataGoReportPerspective(this.configValue);

  final String configValue;
}

typedef KataGoWebSocketConnector =
    WebSocketChannel Function(
      Uri endpoint, {
      Map<String, dynamic>? headers,
      Duration? connectTimeout,
    });

final class KataGoWssConfig {
  KataGoWssConfig({
    required this.endpoint,
    required this.reportAnalysisWinratesAs,
    required this.model,
    this.humanStyleProfile,
    this.bearerToken,
    this.connectionTimeout = const Duration(seconds: 10),
    this.analysisTimeout = const Duration(minutes: 45),
    this.analysisPvLength = 20,
    this.maxInboundMessageBytes = 8 * 1024 * 1024,
    this.maxLinesPerMessage = 1024,
    this.maxJsonNestingDepth = 32,
    this.maxJsonStructuralTokens = 250000,
    this.maxPositionsPerRequest = 1000,
    this.maxResponseCandidates = 362,
    this.maxResponseMessagesPerRequest = 16384,
    this.maxResponseBytesPerRequest = 128 * 1024 * 1024,
    this.maxBufferedResponseBytesPerRequest = 16 * 1024 * 1024,
    this.maxConcurrentRequests = 4,
    this.maxRequestsPerProvider = 4096,
    this.maxRequestIdLength = 128,
    this.maxVisitsPerMove = 20000,
  }) {
    if (endpoint.scheme.toLowerCase() != 'wss' ||
        endpoint.host.isEmpty ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.query.isNotEmpty ||
        endpoint.fragment.isNotEmpty) {
      throw ArgumentError(
        'KataGo remote analysis requires a valid wss:// endpoint without '
        'userinfo, query parameters, or a fragment.',
      );
    }
    if (connectionTimeout <= Duration.zero) {
      throw ArgumentError.value(
        connectionTimeout,
        'connectionTimeout',
        'Connection timeout must be positive.',
      );
    }
    if (analysisTimeout <= Duration.zero) {
      throw ArgumentError.value(
        analysisTimeout,
        'analysisTimeout',
        'Analysis timeout must be positive.',
      );
    }
    if (analysisPvLength < 1 || analysisPvLength > 128) {
      throw ArgumentError.value(
        analysisPvLength,
        'analysisPvLength',
        'PV length must be between 1 and 128.',
      );
    }
    if (bearerToken != null && bearerToken!.trim().isEmpty) {
      throw ArgumentError.value(
        bearerToken,
        'bearerToken',
        'Bearer token cannot be blank.',
      );
    }
    if (humanStyleProfile != null &&
        !model.humanStyleRanks.contains(humanStyleProfile)) {
      throw ArgumentError.value(
        humanStyleProfile,
        'humanStyleProfile',
        'The pinned HumanSL profile must be declared by the model manifest.',
      );
    }
    _requirePositive(maxInboundMessageBytes, 'maxInboundMessageBytes');
    _requirePositive(maxLinesPerMessage, 'maxLinesPerMessage');
    _requirePositive(maxJsonNestingDepth, 'maxJsonNestingDepth');
    _requirePositive(maxJsonStructuralTokens, 'maxJsonStructuralTokens');
    _requirePositive(maxPositionsPerRequest, 'maxPositionsPerRequest');
    _requirePositive(maxResponseCandidates, 'maxResponseCandidates');
    _requirePositive(
      maxResponseMessagesPerRequest,
      'maxResponseMessagesPerRequest',
    );
    _requirePositive(maxResponseBytesPerRequest, 'maxResponseBytesPerRequest');
    _requirePositive(
      maxBufferedResponseBytesPerRequest,
      'maxBufferedResponseBytesPerRequest',
    );
    _requirePositive(maxConcurrentRequests, 'maxConcurrentRequests');
    _requirePositive(maxRequestsPerProvider, 'maxRequestsPerProvider');
    _requirePositive(maxRequestIdLength, 'maxRequestIdLength');
    _requirePositive(maxVisitsPerMove, 'maxVisitsPerMove');
  }

  final Uri endpoint;
  final KataGoReportPerspective reportAnalysisWinratesAs;
  final ModelManifest model;
  final GoRank? humanStyleProfile;
  final String? bearerToken;
  final Duration connectionTimeout;
  final Duration analysisTimeout;
  final int analysisPvLength;
  final int maxInboundMessageBytes;
  final int maxLinesPerMessage;
  final int maxJsonNestingDepth;
  final int maxJsonStructuralTokens;
  final int maxPositionsPerRequest;
  final int maxResponseCandidates;
  final int maxResponseMessagesPerRequest;

  /// Cumulative wire-byte budget, including interim reports and warnings.
  final int maxResponseBytesPerRequest;
  final int maxBufferedResponseBytesPerRequest;
  final int maxConcurrentRequests;
  final int maxRequestsPerProvider;
  final int maxRequestIdLength;
  final int maxVisitsPerMove;

  Map<String, dynamic>? get connectionHeaders => bearerToken == null
      ? null
      : Map<String, dynamic>.unmodifiable(<String, dynamic>{
          'Authorization': 'Bearer ${bearerToken!.trim()}',
        });
}

void _requirePositive(int value, String name) {
  if (value <= 0) {
    throw ArgumentError.value(value, name, '$name must be positive.');
  }
}
