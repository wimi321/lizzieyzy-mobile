import 'dart:convert';

import 'package:lizzieyzy_mobile/domain/domain.dart';

import 'app_settings.dart';
import 'game_performance_calibration_codec.dart';

final class AnalysisServiceManifestCodec {
  const AnalysisServiceManifestCodec({
    this.maximumBytes = 64 * 1024,
    this.calibrationCodec = const GamePerformanceCalibrationCodec(),
  });

  final int maximumBytes;
  final GamePerformanceCalibrationCodec calibrationCodec;

  AnalysisServiceProfile decode(List<int> bytes, {String? bearerToken}) {
    if (bytes.isEmpty || bytes.length > maximumBytes) {
      throw FormatException(
        'Analysis service manifest must be between 1 and $maximumBytes bytes.',
      );
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException(
        'Analysis service manifest must be an object.',
      );
    }
    final json = decoded.cast<String, dynamic>();
    _rejectUnknownKeys(json, const <String>{
      'schemaVersion',
      'endpoint',
      'reportAnalysisWinratesAs',
      'model',
      'performanceCalibration',
    }, 'Analysis service manifest');
    if (json['schemaVersion'] != 1) {
      throw const FormatException(
        'Unsupported analysis service manifest version.',
      );
    }
    for (final forbidden in const <String>[
      'token',
      'bearerToken',
      'authorization',
    ]) {
      if (json.containsKey(forbidden)) {
        throw FormatException(
          'Analysis service manifests cannot contain the secret field $forbidden.',
        );
      }
    }
    final modelValue = json['model'];
    if (modelValue is! Map) {
      throw const FormatException(
        'Analysis service manifest is missing model metadata.',
      );
    }
    final model = modelValue.cast<String, dynamic>();
    _rejectUnknownKeys(model, const <String>{
      'id',
      'displayName',
      'sha256',
      'engineVersion',
      'modelVersion',
      'license',
      'source',
      'humanModelSha256',
      'humanStyleRanks',
    }, 'Analysis service model');
    final rankValues = model['humanStyleRanks'];
    final calibrationValue = json['performanceCalibration'];
    return AnalysisServiceProfile(
      endpoint: Uri.parse(_requiredString(json, 'endpoint')),
      bearerToken: bearerToken,
      winRatePerspective: switch (_requiredString(
        json,
        'reportAnalysisWinratesAs',
      ).toUpperCase()) {
        'BLACK' => AnalysisWinRatePerspective.black,
        'WHITE' => AnalysisWinRatePerspective.white,
        'SIDETOMOVE' => AnalysisWinRatePerspective.sideToMove,
        _ => throw const FormatException(
          'reportAnalysisWinratesAs must be BLACK, WHITE, or SIDETOMOVE.',
        ),
      },
      model: ModelManifest(
        id: _requiredString(model, 'id'),
        displayName: _requiredString(model, 'displayName'),
        sha256: _requiredString(model, 'sha256'),
        engineVersion: _requiredString(model, 'engineVersion'),
        modelVersion: _requiredString(model, 'modelVersion'),
        license: _requiredString(model, 'license'),
        source: _optionalUri(model['source']),
        humanModelSha256: _optionalSha256(model['humanModelSha256']),
        humanStyleRanks: rankValues == null
            ? const <GoRank>[]
            : _parseRanks(rankValues),
      ),
      performanceCalibration: calibrationValue == null
          ? null
          : calibrationCodec.decodeObject(calibrationValue),
    );
  }
}

void _rejectUnknownKeys(
  Map<String, dynamic> value,
  Set<String> allowed,
  String path,
) {
  final unknown = value.keys.where((key) => !allowed.contains(key)).toList()
    ..sort();
  if (unknown.isNotEmpty) {
    throw FormatException(
      '$path contains unknown fields: ${unknown.join(', ')}.',
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Analysis service manifest is missing $key.');
  }
  return value.trim();
}

Uri? _optionalUri(Object? value) {
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Model source must be a non-empty URI.');
  }
  final uri = Uri.parse(value.trim());
  if (!uri.hasScheme || uri.host.isEmpty) {
    throw const FormatException('Model source must be an absolute URI.');
  }
  return uri;
}

String? _optionalSha256(Object? value) {
  if (value == null) return null;
  if (value is! String ||
      !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(value.trim())) {
    throw const FormatException(
      'HumanSL model SHA-256 must contain 64 hexadecimal characters.',
    );
  }
  return value.trim().toLowerCase();
}

List<GoRank> _parseRanks(Object value) {
  if (value is! List) {
    throw const FormatException('humanStyleRanks must be an array.');
  }
  return value
      .map((entry) {
        if (entry is! String) {
          throw const FormatException('HumanSL rank entries must be strings.');
        }
        final match = RegExp(
          r'^(\d{1,2})([kd])$',
        ).firstMatch(entry.toLowerCase());
        if (match == null) {
          throw FormatException('Invalid HumanSL rank: $entry');
        }
        final number = int.parse(match.group(1)!);
        return match.group(2) == 'k' ? GoRank.kyu(number) : GoRank.dan(number);
      })
      .toList(growable: false);
}
