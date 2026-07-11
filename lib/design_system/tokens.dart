import 'package:flutter/material.dart';

/// Raw palette values for LizzieYZY's modern Eastern minimal visual language.
///
/// Feature code should prefer [ColorScheme] and [GoSemanticColors] instead of
/// referencing these values directly.
abstract final class GoPrimitiveColors {
  static const porcelain = Color(0xFFF7F4ED);
  static const paper = Color(0xFFFFFEFA);
  static const ink = Color(0xFF18201C);
  static const mutedInk = Color(0xFF68716C);
  static const jade = Color(0xFF237B64);
  static const jadeDark = Color(0xFF185946);
  static const jadeLight = Color(0xFFDCEDE6);
  static const gold = Color(0xFFA97B32);
  static const goldLight = Color(0xFFF1E7D4);
  static const cinnabar = Color(0xFFC9503B);
  static const cinnabarDark = Color(0xFF963627);
  static const cinnabarLight = Color(0xFFF7E1DB);

  static const night = Color(0xFF111713);
  static const nightSurface = Color(0xFF19221D);
  static const nightRaised = Color(0xFF202C25);
  static const nightText = Color(0xFFE9EEE9);
  static const nightMutedText = Color(0xFFABB7AF);
  static const jadeNight = Color(0xFF73CBAE);
  static const goldNight = Color(0xFFD5AD69);
  static const cinnabarNight = Color(0xFFFF8B76);

  static const board = Color(0xFFD8B77D);
  static const boardGrid = Color(0xFF59462F);
  static const blackStone = Color(0xFF121613);
  static const whiteStone = Color(0xFFF8F7F2);
}

/// Camera/scan surfaces are intentionally theme-independent so the live
/// preview keeps stable contrast in both app themes. Feature code consumes
/// this component palette instead of embedding color literals.
abstract final class GoCameraColors {
  static const background = Color(0xFF0B100D);
  static const previewFallback = Color(0xFF090C0A);
  static const foreground = Color(0xFFFFFFFF);
  static const foregroundDisabled = Color(0x61FFFFFF);
  static const foregroundMuted = Color(0xB3FFFFFF);
  static const guide = GoPrimitiveColors.jadeNight;
  static const guideGlow = Color(0x6673CBAE);
  static const recognizing = GoPrimitiveColors.board;
  static const warning = Color(0xFFE2B35F);
  static const preparing = Color(0xFFB6C1BA);
  static const statusSurface = Color(0xE619221D);
  static const stateScrim = Color(0xB30B100D);
  static const previewWoodDark = Color(0xFF725B3E);
  static const previewWoodLight = Color(0xFFB18E5A);
  static const previewGrid = Color(0xC83F3022);
}

/// Four-point spacing scale. Names encode the multiplier to make layout
/// reviews mechanical and discourage one-off values.
abstract final class GoSpacing {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 40.0;
  static const s12 = 48.0;
  static const s16 = 64.0;
}

abstract final class GoRadii {
  static const small = 8.0;
  static const card = 12.0;
  static const large = 16.0;
  static const sheet = 20.0;
  static const pill = 999.0;
}

abstract final class GoSizes {
  /// Meets Android's 48dp minimum and exceeds the iOS 44pt minimum.
  static const minimumTouchTarget = 48.0;
  static const comfortableTouchTarget = 56.0;
  static const hairline = 1.0;
  static const boardMinimum = 240.0;
}

abstract final class GoMotion {
  static const instant = Duration(milliseconds: 80);
  static const fast = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 220);
  static const emphasized = Duration(milliseconds: 320);

  /// Resolves an animation duration while respecting reduced-motion settings.
  static Duration resolve(BuildContext context, Duration duration) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false
        ? Duration.zero
        : duration;
  }
}

/// Product-specific colors not represented by Material's [ColorScheme].
@immutable
class GoSemanticColors extends ThemeExtension<GoSemanticColors> {
  const GoSemanticColors({
    required this.boardSurface,
    required this.boardGrid,
    required this.blackStone,
    required this.whiteStone,
    required this.whiteStoneOutline,
    required this.dataGold,
    required this.candidatePrimary,
    required this.candidateSecondary,
    required this.candidateTertiary,
    required this.positive,
    required this.warning,
    required this.scrim,
    required this.softDivider,
    required this.shadow,
  });

  final Color boardSurface;
  final Color boardGrid;
  final Color blackStone;
  final Color whiteStone;
  final Color whiteStoneOutline;
  final Color dataGold;
  final Color candidatePrimary;
  final Color candidateSecondary;
  final Color candidateTertiary;
  final Color positive;
  final Color warning;
  final Color scrim;
  final Color softDivider;
  final Color shadow;

  static const light = GoSemanticColors(
    boardSurface: GoPrimitiveColors.board,
    boardGrid: GoPrimitiveColors.boardGrid,
    blackStone: GoPrimitiveColors.blackStone,
    whiteStone: GoPrimitiveColors.whiteStone,
    whiteStoneOutline: Color(0xFFB5AA98),
    dataGold: GoPrimitiveColors.gold,
    candidatePrimary: GoPrimitiveColors.jade,
    candidateSecondary: GoPrimitiveColors.gold,
    candidateTertiary: GoPrimitiveColors.cinnabar,
    positive: Color(0xFF28775F),
    warning: Color(0xFF986B22),
    scrim: Color(0xA6000000),
    softDivider: Color(0xFFE3DED3),
    shadow: Color(0x1A18201C),
  );

  static const dark = GoSemanticColors(
    boardSurface: GoPrimitiveColors.board,
    boardGrid: GoPrimitiveColors.boardGrid,
    blackStone: GoPrimitiveColors.blackStone,
    whiteStone: GoPrimitiveColors.whiteStone,
    whiteStoneOutline: Color(0xFFB5AA98),
    dataGold: GoPrimitiveColors.goldNight,
    candidatePrimary: GoPrimitiveColors.jadeNight,
    candidateSecondary: GoPrimitiveColors.goldNight,
    candidateTertiary: GoPrimitiveColors.cinnabarNight,
    positive: Color(0xFF78D5B6),
    warning: Color(0xFFE4BC72),
    scrim: Color(0xB8000000),
    softDivider: Color(0xFF334039),
    shadow: Color(0x66000000),
  );

  @override
  GoSemanticColors copyWith({
    Color? boardSurface,
    Color? boardGrid,
    Color? blackStone,
    Color? whiteStone,
    Color? whiteStoneOutline,
    Color? dataGold,
    Color? candidatePrimary,
    Color? candidateSecondary,
    Color? candidateTertiary,
    Color? positive,
    Color? warning,
    Color? scrim,
    Color? softDivider,
    Color? shadow,
  }) {
    return GoSemanticColors(
      boardSurface: boardSurface ?? this.boardSurface,
      boardGrid: boardGrid ?? this.boardGrid,
      blackStone: blackStone ?? this.blackStone,
      whiteStone: whiteStone ?? this.whiteStone,
      whiteStoneOutline: whiteStoneOutline ?? this.whiteStoneOutline,
      dataGold: dataGold ?? this.dataGold,
      candidatePrimary: candidatePrimary ?? this.candidatePrimary,
      candidateSecondary: candidateSecondary ?? this.candidateSecondary,
      candidateTertiary: candidateTertiary ?? this.candidateTertiary,
      positive: positive ?? this.positive,
      warning: warning ?? this.warning,
      scrim: scrim ?? this.scrim,
      softDivider: softDivider ?? this.softDivider,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  GoSemanticColors lerp(GoSemanticColors? other, double t) {
    if (other is! GoSemanticColors) return this;
    return GoSemanticColors(
      boardSurface: Color.lerp(boardSurface, other.boardSurface, t)!,
      boardGrid: Color.lerp(boardGrid, other.boardGrid, t)!,
      blackStone: Color.lerp(blackStone, other.blackStone, t)!,
      whiteStone: Color.lerp(whiteStone, other.whiteStone, t)!,
      whiteStoneOutline: Color.lerp(
        whiteStoneOutline,
        other.whiteStoneOutline,
        t,
      )!,
      dataGold: Color.lerp(dataGold, other.dataGold, t)!,
      candidatePrimary: Color.lerp(
        candidatePrimary,
        other.candidatePrimary,
        t,
      )!,
      candidateSecondary: Color.lerp(
        candidateSecondary,
        other.candidateSecondary,
        t,
      )!,
      candidateTertiary: Color.lerp(
        candidateTertiary,
        other.candidateTertiary,
        t,
      )!,
      positive: Color.lerp(positive, other.positive, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      softDivider: Color.lerp(softDivider, other.softDivider, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension GoThemeContext on BuildContext {
  GoSemanticColors get goColors {
    return Theme.of(this).extension<GoSemanticColors>() ??
        (Theme.of(this).brightness == Brightness.dark
            ? GoSemanticColors.dark
            : GoSemanticColors.light);
  }
}
