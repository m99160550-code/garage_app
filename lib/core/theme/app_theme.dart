import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Builds the Material theme from the design tokens.
///
/// Material widgets (dialogs, text fields, pickers) inherit the tokens, and
/// custom widgets read them through [AppThemeX].
abstract final class AppTheme {
  static ThemeData dark({required bool arabic}) {
    const c = AppColors.dark;
    final t = AppTextStyles.forScript(arabic: arabic);

    final scheme = const ColorScheme.dark().copyWith(
      primary: c.buttonPrimaryBg,
      onPrimary: c.textOnLight,
      secondary: c.accentPrimary,
      onSecondary: c.textOnLight,
      error: c.danger,
      onError: c.textOnLight,
      surface: c.bgBase,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.bgBase,
      surfaceContainerLow: c.bgSheet,
      surfaceContainer: c.surfaceCard,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfacePressed,
      outline: c.borderStrong,
      outlineVariant: c.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bgBase,
      canvasColor: c.bgBase,
      fontFamily: t.body.fontFamily,
      focusColor: c.accentPrimary.withValues(alpha: 0.24),
      highlightColor: c.surfacePressed.withValues(alpha: 0.6),
      splashFactory: InkRipple.splashFactory,
      textTheme: TextTheme(
        displayLarge: t.displayHero,
        displayMedium: t.displayStat,
        headlineMedium: t.headline,
        titleLarge: t.titleL,
        titleMedium: t.titleM,
        bodyLarge: t.body,
        bodyMedium: t.body,
        bodySmall: t.bodyS,
        labelLarge: t.button,
        labelMedium: t.label,
        labelSmall: t.caption,
      ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accentPrimary,
        selectionColor: c.accentPrimary.withValues(alpha: 0.35),
        selectionHandleColor: c.accentPrimary,
      ),
      // Toggle (UI/UX spec 1.7): platform switch, on colour accent.primary.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(c.textPrimary),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accentPrimary : c.surfacePressed,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accentPrimary : c.borderStrong,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accentPrimary),
      dividerTheme: DividerThemeData(color: c.borderSubtle, thickness: 1, space: 1),
      extensions: [c, t],
    );
  }
}

/// Short accessors: `context.colors.textPrimary`, `context.text.body`.
extension AppThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppTextStyles get text => Theme.of(this).extension<AppTextStyles>()!;
}
