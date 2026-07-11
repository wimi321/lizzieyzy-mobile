import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/features/home/presentation/kifu_home_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/key_move_review_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/tablet_review_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/variation_comparison_screen.dart';

import 'support/golden_test_harness.dart';

void main() {
  group('Visual Benchmark v1', () {
    testWidgets('core kifu home · phone light', (tester) async {
      await pumpGoldenSurface(
        tester,
        size: GoldenViewport.phone,
        screen: const KifuHomeScreen(),
      );

      await expectLater(
        find.byKey(goldenSurfaceKey),
        matchesGoldenFile('goldens/reference/home_phone_light.png'),
      );
    });

    testWidgets('key move review · phone light', (tester) async {
      await pumpGoldenSurface(
        tester,
        size: GoldenViewport.phone,
        screen: const KeyMoveReviewScreen(),
      );

      await expectLater(
        find.byKey(goldenSurfaceKey),
        matchesGoldenFile('goldens/reference/key_move_phone_light.png'),
      );
    });

    testWidgets('variation comparison · phone dark', (tester) async {
      await pumpGoldenSurface(
        tester,
        size: GoldenViewport.phone,
        themeMode: ThemeMode.dark,
        screen: const VariationComparisonScreen(),
      );

      await expectLater(
        find.byKey(goldenSurfaceKey),
        matchesGoldenFile('goldens/reference/variation_phone_dark.png'),
      );
    });

    testWidgets('review workspace · tablet landscape dark', (tester) async {
      await pumpGoldenSurface(
        tester,
        size: GoldenViewport.tabletLandscape,
        themeMode: ThemeMode.dark,
        screen: const TabletReviewScreen(),
      );

      await expectLater(
        find.byKey(goldenSurfaceKey),
        matchesGoldenFile('goldens/reference/review_tablet_dark.png'),
      );
    });
  });
}
