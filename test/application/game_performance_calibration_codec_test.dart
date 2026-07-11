import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

import '../infrastructure/review/review_test_fixtures.dart';

void main() {
  const codec = GamePerformanceCalibrationCodec();

  test(
    'round-trips every trusted calibration field through versioned JSON',
    () {
      final source = calibrationFixture();
      final encoded = codec.encode(source);
      final envelope = codec.encodeObject(encoded);
      final decoded = codec.decode(utf8.encode(jsonEncode(envelope)));

      expect(
        decoded.schemaVersion,
        GamePerformanceCalibrationCodec.schemaVersion,
      );
      expect(decoded.sha256, encoded.sha256);
      expect(decoded.calibration.calibrationModelId, source.calibrationModelId);
      expect(decoded.calibration.modelCard.modelId, source.modelCard.modelId);
      expect(
        decoded.calibration.modelCard.datasetDescription,
        source.modelCard.datasetDescription,
      );
      expect(
        decoded.calibration.featureWeights.single.feature,
        PerformanceFeature.topOneRate,
      );
      expect(decoded.calibration.buckets, hasLength(3));
      expect(
        decoded.calibration.buckets.first.minimumScore,
        double.negativeInfinity,
      );
      expect(decoded.calibration.buckets.last.maximumScore, double.infinity);
      expect(decoded.calibration.humanStyleProfile, GoRank.kyu(1));
      expect(decoded.calibration.allowedHumanModelSha256, {'d' * 64});
      expect(decoded.calibration.allowedProfiles, {
        AnalysisProfile.standard,
        AnalysisProfile.deep,
      });
    },
  );

  test('rejects a payload changed after its SHA-256 was issued', () {
    final envelope = codec.encodeObject(codec.encode(calibrationFixture()));
    final payload = (envelope['payload']! as Map).cast<String, dynamic>();
    payload['intercept'] = 999;

    expect(() => codec.decodeObject(envelope), throwsFormatException);
  });

  test('rejects unknown fields and the 64KiB boundary', () {
    final envelope = codec.encodeObject(codec.encode(calibrationFixture()));
    final payload = (envelope['payload']! as Map).cast<String, dynamic>();
    payload['unreviewedCoefficient'] = 1;
    envelope['payloadSha256'] = crypto.sha256
        .convert(utf8.encode(jsonEncode(payload)))
        .toString();
    expect(() => codec.decodeObject(envelope), throwsFormatException);

    expect(
      () => codec.decode(List<int>.filled(64 * 1024 + 1, 0x20)),
      throwsFormatException,
    );
  });

  test(
    'service profile rejects a calibration pinned to an unavailable rank',
    () {
      final artifact = codec.encode(calibrationFixture());
      final noHumanProfile = analysisModelFixture(includeHumanRanks: false);

      expect(
        () => AnalysisServiceProfile(
          endpoint: Uri.parse('wss://analysis.example.test/v1'),
          model: noHumanProfile,
          winRatePerspective: AnalysisWinRatePerspective.black,
          performanceCalibration: artifact,
        ),
        throwsArgumentError,
      );

      expect(
        () => AnalysisServiceProfile(
          endpoint: Uri.parse('wss://analysis.example.test/v1'),
          model: analysisModelFixture(humanHashCharacter: 'e'),
          winRatePerspective: AnalysisWinRatePerspective.black,
          performanceCalibration: artifact,
        ),
        throwsArgumentError,
      );

      final wrongModelArtifact = codec.encode(
        calibrationFixture(allowedHashCharacter: 'b'),
      );
      expect(
        () => AnalysisServiceProfile(
          endpoint: Uri.parse('wss://analysis.example.test/v1'),
          model: analysisModelFixture(),
          winRatePerspective: AnalysisWinRatePerspective.black,
          performanceCalibration: wrongModelArtifact,
        ),
        throwsArgumentError,
      );
    },
  );

  test('service manifest imports an optional verified calibration', () {
    final model = analysisModelFixture();
    final artifact = codec.encode(calibrationFixture());
    final manifest = <String, Object?>{
      'schemaVersion': 1,
      'endpoint': 'wss://analysis.example.test/v1',
      'reportAnalysisWinratesAs': 'BLACK',
      'model': <String, Object?>{
        'id': model.id,
        'displayName': model.displayName,
        'sha256': model.sha256,
        'engineVersion': model.engineVersion,
        'modelVersion': model.modelVersion,
        'license': model.license,
        'humanModelSha256': model.humanModelSha256,
        'humanStyleRanks': [
          for (final rank in model.humanStyleRanks) rank.label,
        ],
      },
      'performanceCalibration': codec.encodeObject(artifact),
    };

    final profile = const AnalysisServiceManifestCodec().decode(
      utf8.encode(jsonEncode(manifest)),
    );

    expect(profile.performanceCalibration?.sha256, artifact.sha256);
    expect(profile.humanStyleProfile, GoRank.kyu(1));
  });
}
