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
      onSecondary: GoPrimitiveColors.ink,
      secondaryContainer: GoPrimitiveColors.goldLight,
      onSecondaryContainer: Color(0xFF47300C),
      tertiary: GoPrimitiveColors.cinnabar,
      onTertiary: Color(0xFF2A0A05),
      tertiaryContainer: GoPrimitiveColors.cinnabarLight,
      onTertiaryContainer: GoPrimitiveColors.cinnabarDark,
      error: GoPrimitiveColors.cinnabar,
      onError: Color(0xFF2A0A05),
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

  static ThemeData highContrastLight() => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: GoPrimitiveColors.jadeDark,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFCBE8DC),
      onPrimaryContainer: Color(0xFF071E16),
      secondary: Color(0xFF725019),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF3E2BF),
      onSecondaryContainer: Color(0xFF251800),
      tertiary: GoPrimitiveColors.cinnabarDark,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFF5D4CC),
      onTertiaryContainer: Color(0xFF2B0803),
      error: GoPrimitiveColors.cinnabarDark,
      onError: Colors.white,
      errorContainer: Color(0xFFF5D4CC),
      onErrorContainer: Color(0xFF2B0803),
      surface: Colors.white,
      onSurface: Color(0xFF090D0B),
      surfaceContainerHighest: Color(0xFFE3E0D8),
      onSurfaceVariant: Color(0xFF303632),
      outline: Color(0xFF242A26),
      outlineVariant: Color(0xFF59605B),
      shadow: Colors.black,
      scrim: Color(0xCC000000),
      inverseSurface: Color(0xFF090D0B),
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFF8DE2C4),
    ),
    semantics: GoSemanticColors.light.copyWith(
      softDivider: const Color(0xFF707771),
      shadow: const Color(0x33000000),
    ),
    scaffold: Colors.white,
  );

  static ThemeData highContrastDark() => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF9CE8CD),
      onPrimary: Color(0xFF001B13),
      primaryContainer: Color(0xFF145542),
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFFF0C77E),
      onSecondary: Color(0xFF211400),
      secondaryContainer: Color(0xFF5B4212),
      onSecondaryContainer: Colors.white,
      tertiary: Color(0xFFFFA08D),
      onTertiary: Color(0xFF2A0702),
      tertiaryContainer: Color(0xFF74291D),
      onTertiaryContainer: Colors.white,
      error: Color(0xFFFFA08D),
      onError: Color(0xFF2A0702),
      errorContainer: Color(0xFF74291D),
      onErrorContainer: Colors.white,
      surface: Color(0xFF0B0F0C),
      onSurface: Colors.white,
      surfaceContainerHighest: Color(0xFF252C27),
      onSurfaceVariant: Color(0xFFD5DDD7),
      outline: Color(0xFFF0F4F1),
      outlineVariant: Color(0xFFADB6B0),
      shadow: Colors.black,
      scrim: Color(0xE6000000),
      inverseSurface: Colors.white,
      onInverseSurface: Color(0xFF090D0B),
      inversePrimary: GoPrimitiveColors.jadeDark,
    ),
    semantics: GoSemanticColors.dark.copyWith(
      softDivider: const Color(0xFFAAB4AD),
      shadow: Colors.black,
    ),
    scaffold: Colors.black,
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
          side: BorderSide(color: scheme.outline),
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
