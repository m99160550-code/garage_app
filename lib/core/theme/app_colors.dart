import 'package:flutter/material.dart';

/// "Graphite & Chrome" colour tokens (UI/UX spec 1.2).
///
/// Widgets read colours through `context.colors` and never use raw hex
/// values, so the light theme (v2) can swap the whole set.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bgBase,
    required this.bgSheet,
    required this.surfaceCard,
    required this.surfaceRaised,
    required this.surfacePressed,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.textOnLight,
    required this.accentPrimary,
    required this.accentPressed,
    required this.buttonPrimaryBg,
    required this.destructiveText,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.chromeText,
    required this.chromeSpotlight,
    required this.chromeFloor,
  });

  // Neutrals
  final Color bgBase;
  final Color bgSheet;
  final Color surfaceCard;
  final Color surfaceRaised;
  final Color surfacePressed;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color textOnLight;

  // Accent and interaction
  final Color accentPrimary;
  final Color accentPressed;
  final Color buttonPrimaryBg;
  final Color destructiveText;

  // Status
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color onDangerContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;

  // Chrome signature
  final Gradient chromeText;
  final Gradient chromeSpotlight;
  final Gradient chromeFloor;

  /// The default (and, until v2, only) theme.
  static const AppColors dark = AppColors(
    bgBase: Color(0xFF0B0C0E),
    bgSheet: Color(0xFF121417),
    surfaceCard: Color(0xFF181B20),
    surfaceRaised: Color(0xFF22262D),
    surfacePressed: Color(0xFF2A2F37),
    borderSubtle: Color(0xFF2A2E35),
    borderStrong: Color(0xFF3A404A),
    textPrimary: Color(0xFFF3F5F7),
    textSecondary: Color(0xFFB4BBC5),
    textTertiary: Color(0xFF8A929E),
    textDisabled: Color(0xFF5C636E),
    textOnLight: Color(0xFF0B0C0E),
    accentPrimary: Color(0xFF4D9FFF),
    accentPressed: Color(0xFF3A86E6),
    buttonPrimaryBg: Color(0xFFF3F5F7),
    destructiveText: Color(0xFFFF6B60),
    success: Color(0xFF34C77B),
    successContainer: Color(0xFF12301F),
    onSuccessContainer: Color(0xFF9BEBC0),
    warning: Color(0xFFF0A23B),
    warningContainer: Color(0xFF6E3A17),
    onWarningContainer: Color(0xFFFFE7CF),
    danger: Color(0xFFFF5A4E),
    dangerContainer: Color(0xFF3D1512),
    onDangerContainer: Color(0xFFFFB4AC),
    info: Color(0xFF8FB3E6),
    infoContainer: Color(0xFF16243A),
    onInfoContainer: Color(0xFFC8DBF7),
    chromeText: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFC9CED6), Color(0xFF7E8590)],
      stops: [0, 0.55, 1],
    ),
    chromeSpotlight: RadialGradient(
      center: Alignment.topCenter,
      radius: 1.2,
      colors: [Color(0xFFD9DDE2), Color(0xFF5A616B), Color(0xFF0B0C0E)],
      stops: [0, 0.45, 1],
    ),
    // Fades fully to bg.base within half the shortest side, so the glow
    // never shows the edges of the box it's painted in.
    chromeFloor: RadialGradient(radius: 0.5, colors: [Color(0xFF262A31), Color(0xFF0B0C0E)], stops: [0, 1]),
  );

  @override
  AppColors copyWith() => this;

  /// Only one theme exists until v2, so there is nothing to interpolate.
  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) => other is AppColors && t >= 0.5 ? other : this;
}
