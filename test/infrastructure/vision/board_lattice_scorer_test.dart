import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';
import 'package:lizzieyzy_mobile/infrastructure/vision/vision.dart';

void main() {
  LatticeAxisEvidence evidenceFor(BoardSize size, {double phase = 0}) {
    final peaks = <LatticePeak>[
      for (var index = 0; index < size.dimension; index++)
        LatticePeak(
          position:
              0.05 +
              0.9 * index / (size.dimension - 1) +
              math.sin(index * 1.7 + phase) * 0.0008,
          strength: 0.94,
        ),
      LatticePeak(position: 0.015, strength: 0.08),
      LatticePeak(position: 0.985, strength: 0.07),
    ];
    return LatticeAxisEvidence(peaks);
  }

  for (final size in BoardSize.values) {
    test('selects a jittered ${size.dimension}-line lattice', () {
      final result = const BoardSizeLatticeScorer().score(
        horizontal: evidenceFor(size),
        vertical: evidenceFor(size, phase: 0.4),
      );

      expect(result.best.boardSize, size);
      expect(result.best.score, greaterThan(0.9));
      expect(result.isDecisive(), isTrue);
      expect(result.decisiveSize(), size);
    });
  }

  test('does not make a decisive size claim from only two outer lines', () {
    final sparse = LatticeAxisEvidence(<LatticePeak>[
      LatticePeak(position: 0.1, strength: 1),
      LatticePeak(position: 0.9, strength: 1),
    ]);
    final result = const BoardSizeLatticeScorer().score(
      horizontal: sparse,
      vertical: sparse,
    );

    expect(result.isDecisive(), isFalse);
    expect(result.decisiveSize(), isNull);
  });

  test('extracts one normalized peak per thick projection line', () {
    final projection = List<double>.filled(101, 1);
    for (final center in <int>[10, 50, 90]) {
      projection[center] = 10;
      projection[center + 1] = 8;
    }
    final evidence = LatticeAxisEvidence.fromProjection(projection);

    expect(evidence.peaks, hasLength(3));
    expect(evidence.peaks[0].position, closeTo(0.104, 0.01));
    expect(evidence.peaks[1].position, closeTo(0.504, 0.01));
    expect(evidence.peaks[2].position, closeTo(0.904, 0.01));
  });

  test(
    'rejects non-finite projection data and unsafe scorer configuration',
    () {
      expect(
        () => LatticeAxisEvidence.fromProjection(<double>[0, double.nan, 1]),
        throwsA(isA<LatticeScoringException>()),
      );
      expect(
        () => LatticeAxisEvidence.fromProjection(
          List<double>.filled(
            LatticeAxisEvidence.maximumProjectionSamples + 1,
            0,
          ),
        ),
        throwsA(isA<LatticeScoringException>()),
      );
      expect(
        () => LatticeAxisEvidence(<LatticePeak>[
          for (
            var index = 0;
            index <= LatticeAxisEvidence.maximumPeakCount;
            index++
          )
            LatticePeak(
              position: index / LatticeAxisEvidence.maximumPeakCount,
              strength: 1,
            ),
        ]),
        throwsA(isA<LatticeScoringException>()),
      );
      final empty = LatticeAxisEvidence(const <LatticePeak>[]);
      expect(
        () => const BoardSizeLatticeScorer(
          matchToleranceInSpacings: 0.75,
        ).score(horizontal: empty, vertical: empty),
        throwsA(isA<LatticeScoringException>()),
      );
    },
  );
}
