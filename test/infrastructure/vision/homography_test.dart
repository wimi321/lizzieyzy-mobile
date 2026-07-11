import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lizzieyzy_mobile/infrastructure/vision/vision.dart';

void main() {
  test('solves a perspective quadrilateral and round-trips points', () {
    final source = <ProjectivePoint>[
      ProjectivePoint(100, 50),
      ProjectivePoint(520, 80),
      ProjectivePoint(560, 480),
      ProjectivePoint(60, 440),
    ];
    final destination = <ProjectivePoint>[
      ProjectivePoint(0, 0),
      ProjectivePoint(399, 0),
      ProjectivePoint(399, 399),
      ProjectivePoint(0, 399),
    ];
    final homography = Homography.fromPointPairs(
      source: source,
      destination: destination,
    );

    for (var index = 0; index < source.length; index++) {
      final projected = homography.project(source[index]);
      expect(projected.x, closeTo(destination[index].x, 1e-8));
      expect(projected.y, closeTo(destination[index].y, 1e-8));
    }

    final interior = ProjectivePoint(247.25, 211.75);
    final restored = homography.inverse().project(homography.project(interior));
    expect(restored.x, closeTo(interior.x, 1e-8));
    expect(restored.y, closeTo(interior.y, 1e-8));
  });

  test('normalization keeps large image coordinates numerically stable', () {
    final source = <ProjectivePoint>[
      ProjectivePoint(1220, 800),
      ProjectivePoint(7420, 1110),
      ProjectivePoint(7810, 7090),
      ProjectivePoint(820, 6810),
    ];
    final destination = <ProjectivePoint>[
      ProjectivePoint(0, 0),
      ProjectivePoint(1023, 0),
      ProjectivePoint(1023, 1023),
      ProjectivePoint(0, 1023),
    ];
    final homography = Homography.fromPointPairs(
      source: source,
      destination: destination,
    );

    for (var index = 0; index < source.length; index++) {
      final projected = homography.project(source[index]);
      expect(projected.x, closeTo(destination[index].x, 1e-7));
      expect(projected.y, closeTo(destination[index].y, 1e-7));
    }
  });

  test('rejects duplicate and collinear point configurations', () {
    final square = <ProjectivePoint>[
      ProjectivePoint(0, 0),
      ProjectivePoint(10, 0),
      ProjectivePoint(10, 10),
      ProjectivePoint(0, 10),
    ];
    expect(
      () => Homography.fromPointPairs(
        source: <ProjectivePoint>[
          ProjectivePoint(0, 0),
          ProjectivePoint(0, 0),
          ProjectivePoint(10, 10),
          ProjectivePoint(0, 10),
        ],
        destination: square,
      ),
      throwsA(isA<HomographyException>()),
    );
    expect(
      () => Homography.fromPointPairs(
        source: <ProjectivePoint>[
          ProjectivePoint(0, 0),
          ProjectivePoint(1, 1),
          ProjectivePoint(2, 2),
          ProjectivePoint(3, 3),
        ],
        destination: square,
      ),
      throwsA(isA<HomographyException>()),
    );
  });

  test('identity warp preserves pixels and enforces output budget', () {
    final source = img.Image(width: 5, height: 5, numChannels: 4);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgba(x, y, x * 30, y * 40, x + y, 255);
      }
    }
    final identity = Homography.fromPointPairs(
      source: <ProjectivePoint>[
        ProjectivePoint(0, 0),
        ProjectivePoint(4, 0),
        ProjectivePoint(4, 4),
        ProjectivePoint(0, 4),
      ],
      destination: <ProjectivePoint>[
        ProjectivePoint(0, 0),
        ProjectivePoint(4, 0),
        ProjectivePoint(4, 4),
        ProjectivePoint(0, 4),
      ],
    );
    final warped = warpPerspective(
      source: source,
      sourceToDestination: identity,
      outputWidth: 5,
      outputHeight: 5,
      interpolation: img.Interpolation.nearest,
    );

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final expected = source.getPixel(x, y);
        final actual = warped.getPixel(x, y);
        expect(actual.r, expected.r);
        expect(actual.g, expected.g);
        expect(actual.b, expected.b);
        expect(actual.a, expected.a);
      }
    }

    expect(
      () => warpPerspective(
        source: source,
        sourceToDestination: identity,
        outputWidth: 100,
        outputHeight: 100,
        maxOutputPixels: 9999,
      ),
      throwsA(
        isA<HomographyException>().having(
          (error) => error.code,
          'code',
          HomographyErrorCode.outputBudgetExceeded,
        ),
      ),
    );
  });
}
