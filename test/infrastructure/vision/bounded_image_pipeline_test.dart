import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lizzieyzy_mobile/infrastructure/vision/vision.dart';

void main() {
  test('grayscale conversion respects side and pixel budgets', () {
    final image = img.Image(width: 1600, height: 900);
    img.fill(image, color: img.ColorRgb8(210, 180, 120));
    final gray = GrayImagePlane.fromImage(
      image,
      maxSide: 320,
      maxPixels: 50000,
    );

    expect(gray.width, lessThanOrEqualTo(320));
    expect(gray.height, lessThanOrEqualTo(320));
    expect(gray.width * gray.height, lessThanOrEqualTo(50000));
    expect(gray.luminance, hasLength(gray.width * gray.height));
  });

  test('bounded Sobel extraction finds a grid cross and caps evidence', () {
    final image = img.Image(width: 256, height: 256);
    img.fill(image, color: img.ColorRgb8(220, 185, 120));
    img.drawLine(
      image,
      x1: 16,
      y1: 128,
      x2: 239,
      y2: 128,
      thickness: 3,
      color: img.ColorRgb8(45, 35, 25),
    );
    img.drawLine(
      image,
      x1: 128,
      y1: 16,
      x2: 128,
      y2: 239,
      thickness: 3,
      color: img.ColorRgb8(45, 35, 25),
    );
    final gray = GrayImagePlane.fromImage(image);
    final edges = gray.sobel(maxPoints: 256);

    expect(edges.points, isNotEmpty);
    expect(edges.points.length, lessThanOrEqualTo(256));
  });

  test('darkness projections preserve vertical and horizontal line peaks', () {
    final image = img.Image(width: 101, height: 101);
    img.fill(image, color: img.ColorRgb8(230, 200, 145));
    img.drawLine(
      image,
      x1: 25,
      y1: 0,
      x2: 25,
      y2: 100,
      color: img.ColorRgb8(20, 20, 20),
    );
    img.drawLine(
      image,
      x1: 0,
      y1: 75,
      x2: 100,
      y2: 75,
      color: img.ColorRgb8(20, 20, 20),
    );
    final projections = GrayImagePlane.fromImage(image).darknessProjections();

    expect(projections.vertical[25], greaterThan(projections.vertical[50]));
    expect(projections.horizontal[75], greaterThan(projections.horizontal[50]));
  });
}
