import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';

void main() {
  group('LizzieTheme', () {
    test('light theme exposes the locked palette and semantic extension', () {
      final theme = LizzieTheme.light();

      expect(theme.scaffoldBackgroundColor, GoPrimitiveColors.porcelain);
      expect(theme.colorScheme.surface, GoPrimitiveColors.paper);
      expect(theme.colorScheme.primary, GoPrimitiveColors.jade);
      expect(theme.colorScheme.onSurface, GoPrimitiveColors.ink);
      expect(
        theme.extension<GoSemanticColors>()?.boardSurface,
        GoPrimitiveColors.board,
      );
      expect(theme.textTheme.bodyLarge?.fontSize, 16);
      expect(theme.textTheme.bodySmall?.fontSize, 12);
    });

    test('dark theme uses the dedicated review surfaces', () {
      final theme = LizzieTheme.dark();

      expect(theme.scaffoldBackgroundColor, GoPrimitiveColors.night);
      expect(theme.colorScheme.surface, GoPrimitiveColors.nightSurface);
      expect(theme.colorScheme.onSurface, GoPrimitiveColors.nightText);
      expect(
        theme.extension<GoSemanticColors>()?.candidatePrimary,
        GoPrimitiveColors.jadeNight,
      );
    });

    test('core text pairs meet WCAG AA contrast', () {
      final light = LizzieTheme.light();
      final dark = LizzieTheme.dark();

      expect(
        _contrast(light.colorScheme.onSurface, light.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(
          light.colorScheme.onSurfaceVariant,
          GoPrimitiveColors.porcelain,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(dark.colorScheme.onSurface, dark.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(dark.colorScheme.onSurfaceVariant, dark.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('motion resolves to zero when reduced motion is enabled', (
      tester,
    ) async {
      late Duration resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: LizzieTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                resolved = GoMotion.resolve(context, GoMotion.standard);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(resolved, Duration.zero);
    });
  });
}

double _contrast(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground.computeLuminance()
      : background.computeLuminance();
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background.computeLuminance()
      : foreground.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}
