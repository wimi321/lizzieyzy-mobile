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
    this.bearerToken,
    this.connectionTimeout = const Duration(seconds: 10),
    this.analysisPvLength = 20,
  }) {
    if (endpoint.scheme.toLowerCase() != 'wss' || endpoint.host.isEmpty) {
      throw ArgumentError.value(
        endpoint,
        'endpoint',
        'KataGo remote analysis requires a valid wss:// endpoint.',
      );
    }
    if (connectionTimeout <= Duration.zero) {
      throw ArgumentError.value(
        connectionTimeout,
        'connectionTimeout',
        'Connection timeout must be positive.',
      );
    }
    if (analysisPvLength < 1) {
      throw ArgumentError.value(
        analysisPvLength,
        'analysisPvLength',
        'PV length must be at least one.',
      );
    }
    if (bearerToken != null && bearerToken!.trim().isEmpty) {
      throw ArgumentError.value(
        bearerToken,
        'bearerToken',
        'Bearer token cannot be blank.',
      );
    }
  }

  final Uri endpoint;
  final KataGoReportPerspective reportAnalysisWinratesAs;
  final ModelManifest model;
  final String? bearerToken;
  final Duration connectionTimeout;
  final int analysisPvLength;

  Map<String, dynamic>? get connectionHeaders => bearerToken == null
      ? null
      : <String, dynamic>{'Authorization': 'Bearer ${bearerToken!.trim()}'};
}
