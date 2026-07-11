import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:lizzieyzy_mobile/domain/domain.dart';

/// A hash-verified, versioned calibration artifact kept with an analysis
/// service profile. The parsed calibration is immutable and the canonical
/// payload is retained only so persistence can reproduce the verified bytes.
final class GamePerformanceCalibrationArtifact {
  const GamePerformanceCalibrationArtifact._({
    required this.schemaVersion,
    required this.sha256,
    required this.calibration,
    required String canonicalPayload,
  }) : _canonicalPayload = canonicalPayload;

  final int schemaVersion;
  final String sha256;
  final GamePerformanceCalibration calibration;
  final String _canonicalPayload;
}

/// Strict codec for the optional single-game performance calibration JSON.
///
/// The envelope hash covers the canonical JSON representation of `payload`,
/// excluding the envelope itself. This avoids a self-referential digest while
/// still authenticating every model-card, weight, bucket, rank, and profile
/// field used to produce a rank interval.
final class GamePerformanceCalibrationCodec {
  const GamePerformanceCalibrationCodec({this.maximumBytes = 64 * 1024});

  static const schemaVersion = 1;
  final int maximumBytes;

  GamePerformanceCalibrationArtifact decode(List<int> bytes) {
    _checkSize(bytes.length);
    final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
    return decodeObject(decoded);
  }

  GamePerformanceCalibrationArtifact decodeObject(Object? value) {
    final envelope = _strictObject(
      value,
      path: 'performanceCalibration',
      keys: const <String>{'schemaVersion', 'payloadSha256', 'payload'},
    );
    _checkSize(utf8.encode(_canonicalJson(envelope)).length);
    final version = _requiredInt(envelope, 'schemaVersion');
    if (version != schemaVersion) {
      throw const FormatException(
        'Unsupported performance calibration schemaVersion.',
      );
    }
    final declaredHash = _requiredSha256(envelope, 'payloadSha256');
    final payload = _strictObject(
      envelope['payload'],
      path: 'performanceCalibration.payload',
      keys: _payloadKeys,
    );
    final canonicalPayload = _canonicalJson(payload);
    final actualHash = crypto.sha256
        .convert(utf8.encode(canonicalPayload))
        .toString();
    if (actualHash != declaredHash) {
      throw const FormatException(
        'Performance calibration payload SHA-256 does not match.',
      );
    }
    final GamePerformanceCalibration calibration;
    try {
      calibration = _parsePayload(payload);
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid performance calibration payload: $error');
    }
    return GamePerformanceCalibrationArtifact._(
      schemaVersion: version,
      sha256: actualHash,
      calibration: calibration,
      canonicalPayload: canonicalPayload,
    );
  }

  GamePerformanceCalibrationArtifact encode(
    GamePerformanceCalibration calibration,
  ) {
    final payload = _payloadFromCalibration(calibration);
    final canonicalPayload = _canonicalJson(payload);
    final digest = crypto.sha256
        .convert(utf8.encode(canonicalPayload))
        .toString();
    final artifact = GamePerformanceCalibrationArtifact._(
      schemaVersion: schemaVersion,
      sha256: digest,
      calibration: calibration,
      canonicalPayload: canonicalPayload,
    );
    _checkSize(utf8.encode(jsonEncode(encodeObject(artifact))).length);
    return artifact;
  }

  Map<String, Object?> encodeObject(
    GamePerformanceCalibrationArtifact artifact,
  ) {
    final actualHash = crypto.sha256
        .convert(utf8.encode(artifact._canonicalPayload))
        .toString();
    if (artifact.schemaVersion != schemaVersion ||
        artifact.sha256 != actualHash) {
      throw const FormatException(
        'Performance calibration artifact is not internally consistent.',
      );
    }
    return <String, Object?>{
      'schemaVersion': artifact.schemaVersion,
      'payloadSha256': artifact.sha256,
      'payload': jsonDecode(artifact._canonicalPayload),
    };
  }

  void _checkSize(int length) {
    if (length < 1 || length > maximumBytes) {
      throw FormatException(
        'Performance calibration JSON must be between 1 and $maximumBytes bytes.',
      );
    }
  }
}

const _payloadKeys = <String>{
  'model',
  'modelCard',
  'intercept',
  'featureWeights',
  'buckets',
  'allowedAnalysisModelSha256',
  'allowedHumanModelSha256',
  'allowedProfiles',
  'minimumVisitsPerPosition',
  'mediumConfidenceDecisions',
  'severeMistakePointLoss',
  'policyFloor',
  'requiresHumanStyleRanks',
  'humanStyleProfile',
  'coverage',
};

GamePerformanceCalibration _parsePayload(Map<String, dynamic> payload) {
  final modelJson = _strictObject(
    payload['model'],
    path: 'performanceCalibration.payload.model',
    keys: const <String>{
      'id',
      'version',
      'sha256',
      'minimumDecisions',
      'minimumRank',
      'maximumRank',
    },
  );
  final model = PerformanceModelManifest(
    id: _requiredString(modelJson, 'id', maximumLength: 128),
    version: _requiredString(modelJson, 'version', maximumLength: 64),
    sha256: _requiredSha256(modelJson, 'sha256'),
    minimumDecisions: _requiredInt(modelJson, 'minimumDecisions'),
    minimumRank: _requiredRank(modelJson, 'minimumRank'),
    maximumRank: _requiredRank(modelJson, 'maximumRank'),
  );
  final cardJson = _strictObject(
    payload['modelCard'],
    path: 'performanceCalibration.payload.modelCard',
    keys: const <String>{
      'modelId',
      'intendedUse',
      'datasetDescription',
      'limitations',
      'trainingGames',
      'heldOutGames',
      'distinctPlayers',
    },
  );
  final card = CalibrationModelCard(
    modelId: _requiredString(cardJson, 'modelId', maximumLength: 128),
    intendedUse: _requiredString(cardJson, 'intendedUse'),
    datasetDescription: _requiredString(cardJson, 'datasetDescription'),
    limitations: _requiredString(cardJson, 'limitations'),
    trainingGames: _requiredInt(cardJson, 'trainingGames'),
    heldOutGames: _requiredInt(cardJson, 'heldOutGames'),
    distinctPlayers: _requiredInt(cardJson, 'distinctPlayers'),
  );

  final rawWeights = _requiredList(payload, 'featureWeights');
  if (rawWeights.isEmpty ||
      rawWeights.length > PerformanceFeature.values.length) {
    throw const FormatException(
      'featureWeights must contain one to seven unique transforms.',
    );
  }
  final weights = <CalibrationFeatureWeight>[
    for (var index = 0; index < rawWeights.length; index++)
      _parseWeight(rawWeights[index], index),
  ];

  final rawBuckets = _requiredList(payload, 'buckets');
  if (rawBuckets.isEmpty || rawBuckets.length > 128) {
    throw const FormatException(
      'buckets must contain between 1 and 128 items.',
    );
  }
  final buckets = <CalibrationBucket>[
    for (var index = 0; index < rawBuckets.length; index++)
      _parseBucket(rawBuckets[index], index),
  ];

  final hashes = _requiredStringSet(
    payload,
    'allowedAnalysisModelSha256',
    parser: (value) {
      if (!_sha256Pattern.hasMatch(value)) {
        throw const FormatException(
          'allowedAnalysisModelSha256 contains a non-SHA-256 value.',
        );
      }
      return value.toLowerCase();
    },
  );
  final humanModelHashes = _requiredStringSet(
    payload,
    'allowedHumanModelSha256',
    allowEmpty: true,
    parser: (value) {
      if (!_sha256Pattern.hasMatch(value)) {
        throw const FormatException(
          'allowedHumanModelSha256 contains a non-SHA-256 value.',
        );
      }
      return value.toLowerCase();
    },
  );
  final profiles = _requiredStringSet(
    payload,
    'allowedProfiles',
    parser: (value) => switch (value) {
      'standard' => AnalysisProfile.standard,
      'deep' => AnalysisProfile.deep,
      _ => throw const FormatException(
        'allowedProfiles supports only standard and deep.',
      ),
    },
  );
  final humanProfileValue = payload['humanStyleProfile'];
  final humanProfile = humanProfileValue == null
      ? null
      : _parseRankValue(humanProfileValue, 'humanStyleProfile');

  try {
    return GamePerformanceCalibration(
      model: model,
      modelCard: card,
      intercept: _requiredFiniteNumber(payload, 'intercept'),
      featureWeights: weights,
      buckets: buckets,
      allowedAnalysisModelSha256: hashes,
      allowedHumanModelSha256: humanModelHashes,
      allowedProfiles: profiles,
      minimumVisitsPerPosition: _requiredInt(
        payload,
        'minimumVisitsPerPosition',
      ),
      mediumConfidenceDecisions: _requiredInt(
        payload,
        'mediumConfidenceDecisions',
      ),
      severeMistakePointLoss: _requiredFiniteNumber(
        payload,
        'severeMistakePointLoss',
      ),
      policyFloor: _requiredFiniteNumber(payload, 'policyFloor'),
      requiresHumanStyleRanks: _requiredBool(
        payload,
        'requiresHumanStyleRanks',
      ),
      humanStyleProfile: humanProfile,
      coverage: _requiredFiniteNumber(payload, 'coverage'),
    );
  } on FormatException {
    rethrow;
  } on Object catch (error) {
    throw FormatException('Invalid performance calibration payload: $error');
  }
}

CalibrationFeatureWeight _parseWeight(Object? value, int index) {
  final json = _strictObject(
    value,
    path: 'performanceCalibration.payload.featureWeights[$index]',
    keys: const <String>{'feature', 'weight', 'center', 'scale'},
  );
  final featureName = _requiredString(json, 'feature', maximumLength: 64);
  final feature = PerformanceFeature.values
      .cast<PerformanceFeature?>()
      .firstWhere(
        (candidate) => candidate?.name == featureName,
        orElse: () => null,
      );
  if (feature == null) {
    throw FormatException('Unknown performance feature: $featureName');
  }
  return CalibrationFeatureWeight(
    feature: feature,
    weight: _requiredFiniteNumber(json, 'weight'),
    center: _requiredFiniteNumber(json, 'center'),
    scale: _requiredFiniteNumber(json, 'scale'),
  );
}

CalibrationBucket _parseBucket(Object? value, int index) {
  final json = _strictObject(
    value,
    path: 'performanceCalibration.payload.buckets[$index]',
    keys: const <String>{
      'minimumScore',
      'maximumScore',
      'weakerBound',
      'strongerBound',
    },
  );
  return CalibrationBucket(
    minimumScore: _scoreBoundary(json['minimumScore'], 'minimumScore'),
    maximumScore: _scoreBoundary(json['maximumScore'], 'maximumScore'),
    weakerBound: _requiredRank(json, 'weakerBound'),
    strongerBound: _requiredRank(json, 'strongerBound'),
  );
}

Map<String, Object?> _payloadFromCalibration(
  GamePerformanceCalibration calibration,
) => <String, Object?>{
  'model': <String, Object?>{
    'id': calibration.model.id,
    'version': calibration.model.version,
    'sha256': calibration.model.sha256.toLowerCase(),
    'minimumDecisions': calibration.model.minimumDecisions,
    'minimumRank': calibration.model.minimumRank.label,
    'maximumRank': calibration.model.maximumRank.label,
  },
  'modelCard': <String, Object?>{
    'modelId': calibration.modelCard.modelId,
    'intendedUse': calibration.modelCard.intendedUse,
    'datasetDescription': calibration.modelCard.datasetDescription,
    'limitations': calibration.modelCard.limitations,
    'trainingGames': calibration.modelCard.trainingGames,
    'heldOutGames': calibration.modelCard.heldOutGames,
    'distinctPlayers': calibration.modelCard.distinctPlayers,
  },
  'intercept': calibration.intercept,
  'featureWeights': <Object?>[
    for (final weight in calibration.featureWeights)
      <String, Object?>{
        'feature': weight.feature.name,
        'weight': weight.weight,
        'center': weight.center,
        'scale': weight.scale,
      },
  ],
  'buckets': <Object?>[
    for (final bucket in calibration.buckets)
      <String, Object?>{
        'minimumScore': _encodeBoundary(bucket.minimumScore),
        'maximumScore': _encodeBoundary(bucket.maximumScore),
        'weakerBound': bucket.weakerBound.label,
        'strongerBound': bucket.strongerBound.label,
      },
  ],
  'allowedAnalysisModelSha256': <String>[
    ...calibration.allowedAnalysisModelSha256.toList()..sort(),
  ],
  'allowedHumanModelSha256': <String>[
    ...calibration.allowedHumanModelSha256.toList()..sort(),
  ],
  'allowedProfiles': <String>[
    ...calibration.allowedProfiles.map((profile) => profile.name).toList()
      ..sort(),
  ],
  'minimumVisitsPerPosition': calibration.minimumVisitsPerPosition,
  'mediumConfidenceDecisions': calibration.mediumConfidenceDecisions,
  'severeMistakePointLoss': calibration.severeMistakePointLoss,
  'policyFloor': calibration.policyFloor,
  'requiresHumanStyleRanks': calibration.requiresHumanStyleRanks,
  'humanStyleProfile': calibration.humanStyleProfile?.label,
  'coverage': calibration.coverage,
};

Map<String, dynamic> _strictObject(
  Object? value, {
  required String path,
  required Set<String> keys,
}) {
  if (value is! Map) throw FormatException('$path must be an object.');
  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$path contains a non-string key.');
    }
    result[entry.key! as String] = entry.value;
  }
  final actual = result.keys.toSet();
  if (actual.length != keys.length || !actual.containsAll(keys)) {
    final missing = keys.difference(actual).toList()..sort();
    final unknown = actual.difference(keys).toList()..sort();
    throw FormatException(
      '$path has an invalid schema; missing=$missing unknown=$unknown.',
    );
  }
  return result;
}

String _requiredString(
  Map<String, dynamic> json,
  String key, {
  int maximumLength = 4096,
}) {
  final value = json[key];
  if (value is! String ||
      value.trim().isEmpty ||
      value.length > maximumLength) {
    throw FormatException('$key must be a bounded non-empty string.');
  }
  return value.trim();
}

String _requiredSha256(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key, maximumLength: 64);
  if (!_sha256Pattern.hasMatch(value)) {
    throw FormatException('$key must contain 64 hexadecimal characters.');
  }
  return value.toLowerCase();
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('$key must be a boolean.');
  return value;
}

double _requiredFiniteNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num || !value.isFinite) {
    throw FormatException('$key must be a finite number.');
  }
  return value.toDouble();
}

List<dynamic> _requiredList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('$key must be an array.');
  return value;
}

Set<T> _requiredStringSet<T>(
  Map<String, dynamic> json,
  String key, {
  required T Function(String) parser,
  bool allowEmpty = false,
}) {
  final values = _requiredList(json, key);
  if ((!allowEmpty && values.isEmpty) || values.length > 64) {
    throw FormatException(
      '$key must contain between ${allowEmpty ? 0 : 1} and 64 items.',
    );
  }
  final result = <T>{};
  for (final value in values) {
    if (value is! String || !result.add(parser(value))) {
      throw FormatException('$key must contain unique strings.');
    }
  }
  return result;
}

GoRank _requiredRank(Map<String, dynamic> json, String key) =>
    _parseRankValue(json[key], key);

GoRank _parseRankValue(Object? value, String key) {
  if (value is! String || value != value.toLowerCase()) {
    throw FormatException('$key must be a lowercase Go rank such as 3k or 1d.');
  }
  final match = RegExp(r'^(\d{1,2})([kd])$').firstMatch(value);
  if (match == null) throw FormatException('$key is not a valid Go rank.');
  final number = int.parse(match.group(1)!);
  try {
    return match.group(2) == 'k' ? GoRank.kyu(number) : GoRank.dan(number);
  } on RangeError {
    throw FormatException('$key is outside the supported amateur rank range.');
  }
}

double _scoreBoundary(Object? value, String key) {
  if (value == '-Infinity') return double.negativeInfinity;
  if (value == 'Infinity') return double.infinity;
  if (value is! num || !value.isFinite) {
    throw FormatException('$key must be finite, -Infinity, or Infinity.');
  }
  return value.toDouble();
}

Object _encodeBoundary(double value) {
  if (value == double.negativeInfinity) return '-Infinity';
  if (value == double.infinity) return 'Infinity';
  return value;
}

String _canonicalJson(Object? value) => jsonEncode(_canonicalize(value));

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final keys = <String>[];
    for (final key in value.keys) {
      if (key is! String) {
        throw const FormatException(
          'Canonical JSON objects require string keys.',
        );
      }
      keys.add(key);
    }
    keys.sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  if (value is List) {
    return <Object?>[for (final item in value) _canonicalize(item)];
  }
  if (value == null || value is String || value is bool || value is int) {
    return value;
  }
  if (value is double && value.isFinite) return value;
  if (value is num && value.isFinite) return value.toDouble();
  throw const FormatException(
    'Calibration JSON contains an unsupported value.',
  );
}

final _sha256Pattern = RegExp(r'^[a-fA-F0-9]{64}$');
