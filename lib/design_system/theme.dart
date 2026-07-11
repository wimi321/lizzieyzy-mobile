import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class LizzieTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: GoPrimitiveColors.jade,
      onPrimary: Colors.white,
      primaryContainer: GoPrimitiveColors.jadeLight,
      onPrimaryContainer: GoPrimitiveColors.jadeDark,
      secondary: GoPrimitiveColors.gold,
      onSecondary: Colors.white,
      secondaryContainer: GoPrimitiveColors.goldLight,
      onSecondaryContainer: Color(0xFF47300C),
      tertiary: GoPrimitiveColors.cinnabar,
      onTertiary: Colors.white,
      tertiaryContainer: GoPrimitiveColors.cinnabarLight,
      onTertiaryContainer: GoPrimitiveColors.cinnabarDark,
      error: GoPrimitiveColors.cinnabar,
      onError: Colors.white,
      errorContainer: GoPrimitiveColors.cinnabarLight,
      onErrorContainer: GoPrimitiveColors.cinnabarDark,
      surface: GoPrimitiveColors.paper,
      onSurface: GoPrimitiveColors.ink,
      surfaceContainerHighest: Color(0xFFECE8DF),
      onSurfaceVariant: GoPrimitiveColors.mutedInk,
      outline: Color(0xFF777F79),
      outlineVariant: Color(0xFFD7D2C8),
      shadow: Color(0x1A18201C),
      scrim: Color(0xA6000000),
      inverseSurface: GoPrimitiveColors.ink,
      onInverseSurface: GoPrimitiveColors.paper,
      inversePrimary: Color(0xFF83D9BB),
    ),
    semantics: GoSemanticColors.light,
    scaffold: GoPrimitiveColors.porcelain,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: GoPrimitiveColors.jadeNight,
      onPrimary: Color(0xFF08291F),
      primaryContainer: Color(0xFF1B5948),
      onPrimaryContainer: Color(0xFFC4F4E3),
      secondary: GoPrimitiveColors.goldNight,
      onSecondary: Color(0xFF342305),
      secondaryContainer: Color(0xFF554019),
      onSecondaryContainer: Color(0xFFF6E1B7),
      tertiary: GoPrimitiveColors.cinnabarNight,
      onTertiary: Color(0xFF411006),
      tertiaryContainer: Color(0xFF71281B),
      onTertiaryContainer: Color(0xFFFFDAD2),
      error: GoPrimitiveColors.cinnabarNight,
      onError: Color(0xFF411006),
      errorContainer: Color(0xFF71281B),
      onErrorContainer: Color(0xFFFFDAD2),
      surface: GoPrimitiveColors.nightSurface,
      onSurface: GoPrimitiveColors.nightText,
      surfaceContainerHighest: GoPrimitiveColors.nightRaised,
      onSurfaceVariant: GoPrimitiveColors.nightMutedText,
      outline: Color(0xFF95A29A),
      outlineVariant: Color(0xFF3B4840),
      shadow: Colors.black,
      scrim: Color(0xB8000000),
      inverseSurface: GoPrimitiveColors.nightText,
      onInverseSurface: GoPrimitiveColors.night,
      inversePrimary: GoPrimitiveColors.jade,
    ),
    semantics: GoSemanticColors.dark,
    scaffold: GoPrimitiveColors.night,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required GoSemanticColors semantics,
    required Color scaffold,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    final textTheme = _textTheme(base.textTheme, scheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shadowColor: semantics.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoRadii.card),
          side: BorderSide(color: semantics.softDivider),
        ),
      ),
      dividerColor: semantics.softDivider,
      dividerTheme: DividerThemeData(
        color: semantics.softDivider,
        thickness: GoSizes.hairline,
        space: GoSpacing.s4,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            GoSizes.minimumTouchTarget,
            GoSizes.minimumTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: GoSpacing.s5,
            vertical: GoSpacing.s3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoRadii.card),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            GoSizes.minimumTouchTarget,
            GoSizes.minimumTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: GoSpacing.s4,
            vertical: GoSpacing.s3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoRadii.card),
          ),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size(GoSizes.minimumTouchTarget, GoSizes.minimumTouchTarget),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: semantics.softDivider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoRadii.pill),
        ),
        labelStyle: textTheme.labelMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(GoRadii.pill),
      ),
      extensions: <ThemeExtension<dynamic>>[semantics],
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle style(
      TextStyle? source, {
      required double size,
      required FontWeight weight,
      required double height,
      double letterSpacing = 0,
      Color? color,
    }) {
      return (source ?? const TextStyle()).copyWith(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? scheme.onSurface,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      );
    }

    return base.copyWith(
      displaySmall: style(
        base.displaySmall,
        size: 36,
        weight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.5,
      ),
      headlineLarge: style(
        base.headlineLarge,
        size: 30,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.4,
      ),
      headlineMedium: style(
        base.headlineMedium,
        size: 26,
        weight: FontWeight.w600,
        height: 1.22,
        letterSpacing: -0.3,
      ),
      headlineSmall: style(
        base.headlineSmall,
        size: 22,
        weight: FontWeight.w600,
        height: 1.28,
      ),
      titleLarge: style(
        base.titleLarge,
        size: 20,
        weight: FontWeight.w600,
        height: 1.3,
      ),
      titleMedium: style(
        base.titleMedium,
        size: 17,
        weight: FontWeight.w600,
        height: 1.35,
      ),
      titleSmall: style(
        base.titleSmall,
        size: 15,
        weight: FontWeight.w600,
        height: 1.4,
      ),
      bodyLarge: style(
        base.bodyLarge,
        size: 16,
        weight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: style(
        base.bodyMedium,
        size: 14,
        weight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: style(
        base.bodySmall,
        size: 12,
        weight: FontWeight.w400,
        height: 1.45,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: style(
        base.labelLarge,
        size: 15,
        weight: FontWeight.w600,
        height: 1.3,
      ),
      labelMedium: style(
        base.labelMedium,
        size: 13,
        weight: FontWeight.w600,
        height: 1.3,
      ),
      labelSmall: style(
        base.labelSmall,
        size: 12,
        weight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}
