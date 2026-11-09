import 'package:flutter/material.dart';

/// Font family names declared in pubspec.yaml.
abstract final class AppFonts {
  static const inter = 'Inter';
  static const interDisplay = 'InterDisplay';
  static const plexArabic = 'IBMPlexSansArabic';
}

/// Type scale tokens (UI/UX spec 1.3).
///
/// Arabic uses the same sizes with taller line heights, no negative
/// tracking and no all-caps. Latin text falls back to Inter inside Arabic
/// strings (for brand names, units and Western digits).
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.isArabic,
    required this.displayHero,
    required this.displayScore,
    required this.displayStat,
    required this.headline,
    required this.titleL,
    required this.titleM,
    required this.body,
    required this.bodyS,
    required this.label,
    required this.button,
    required this.caption,
    required this.overline,
  });

  factory AppTextStyles.forScript({required bool arabic}) {
    TextStyle style({
      required double size,
      required double latinLine,
      required double arabicLine,
      required FontWeight weight,
      double trackingPercent = 0,
      bool display = false,
    }) {
      final family = arabic ? AppFonts.plexArabic : (display ? AppFonts.interDisplay : AppFonts.inter);
      return TextStyle(
        fontFamily: family,
        fontFamilyFallback: arabic ? const [AppFonts.inter] : const [AppFonts.plexArabic],
        fontSize: size,
        height: (arabic ? arabicLine : latinLine) / size,
        fontWeight: weight,
        // Tracking applies to Latin only (spec 1.3).
        letterSpacing: arabic ? 0 : size * trackingPercent / 100,
        leadingDistribution: TextLeadingDistribution.even,
      );
    }

    return AppTextStyles(
      isArabic: arabic,
      displayHero: style(
        size: 76,
        latinLine: 76,
        arabicLine: 88,
        weight: FontWeight.w700,
        trackingPercent: -3,
        display: true,
      ),
      displayScore: style(
        size: 88,
        latinLine: 88,
        arabicLine: 96,
        weight: FontWeight.w600,
        trackingPercent: -4,
        display: true,
      ),
      displayStat: style(
        size: 34,
        latinLine: 40,
        arabicLine: 46,
        weight: FontWeight.w600,
        trackingPercent: -1,
        display: true,
      ),
      headline: style(size: 28, latinLine: 34, arabicLine: 40, weight: FontWeight.w600, trackingPercent: -1),
      titleL: style(size: 22, latinLine: 28, arabicLine: 34, weight: FontWeight.w600),
      titleM: style(size: 17, latinLine: 22, arabicLine: 28, weight: FontWeight.w600),
      body: style(size: 15, latinLine: 22, arabicLine: 26, weight: FontWeight.w400),
      bodyS: style(size: 13, latinLine: 18, arabicLine: 22, weight: FontWeight.w400),
      label: style(size: 13, latinLine: 16, arabicLine: 20, weight: FontWeight.w500, trackingPercent: 1),
      button: style(size: 16, latinLine: 20, arabicLine: 24, weight: FontWeight.w600),
      caption: style(size: 12, latinLine: 16, arabicLine: 20, weight: FontWeight.w400, trackingPercent: 1),
      // Arabic overlines are sentence case at 12 pt (spec 1.3).
      overline: arabic
          ? style(size: 12, latinLine: 14, arabicLine: 18, weight: FontWeight.w500)
          : style(size: 11, latinLine: 14, arabicLine: 18, weight: FontWeight.w500, trackingPercent: 6),
    );
  }

  final bool isArabic;
  final TextStyle displayHero;
  final TextStyle displayScore;
  final TextStyle displayStat;
  final TextStyle headline;
  final TextStyle titleL;
  final TextStyle titleM;
  final TextStyle body;
  final TextStyle bodyS;
  final TextStyle label;
  final TextStyle button;
  final TextStyle caption;
  final TextStyle overline;

  /// Values (mileage, money, scores) use Inter tabular figures in both
  /// languages so numbers line up and don't jitter (spec 1.3).
  static TextStyle tabular(TextStyle base) => base.copyWith(
    fontFamily: base.fontSize != null && base.fontSize! >= 32 ? AppFonts.interDisplay : AppFonts.inter,
    fontFamilyFallback: const [AppFonts.plexArabic],
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  @override
  AppTextStyles copyWith() => this;

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) =>
      other is AppTextStyles && t >= 0.5 ? other : this;
}
