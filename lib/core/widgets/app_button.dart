import 'package:flutter/material.dart';

import '../layout/window_class.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

enum AppButtonVariant { primary, secondary, destructive, text, destructiveText }

/// Buttons from the design system (UI/UX spec 1.7).
///
/// * Primary: 52 pt, white chrome fill. One per screen.
/// * Secondary: 52 pt, raised graphite fill with a border.
/// * Destructive: 52 pt, red fill with near-black text (S-30).
/// * Text / destructive text: 44 pt, no fill.
///
/// Primary and secondary buttons fill the available width on phones and cap
/// at 400 pt on tablets. Focus shows a 2 pt Signal Blue ring. Disabled
/// buttons are 40% opacity and can't be focused.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.leading,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.leading,
  }) : variant = AppButtonVariant.secondary;

  /// A filled red button for a permanent action (S-30): `status.danger`
  /// with near-black text, 6.4:1.
  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.destructive,
       leading = null;

  const AppButton.text({super.key, required this.label, required this.onPressed, this.icon, this.isLoading = false})
    : variant = AppButtonVariant.text,
      expand = false,
      leading = null;

  const AppButton.destructiveText({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  }) : variant = AppButtonVariant.destructiveText,
       expand = false,
       leading = null;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  /// A mark drawn before the label instead of [icon], for example the
  /// Google "G" (S-28).
  final Widget? leading;
  final bool isLoading;

  /// Primary and secondary only: stretch to the available width.
  final bool expand;

  bool get _isFilled =>
      variant == AppButtonVariant.primary ||
      variant == AppButtonVariant.secondary ||
      variant == AppButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    final (Color background, Color foreground, BorderSide side) = switch (variant) {
      AppButtonVariant.primary => (colors.buttonPrimaryBg, colors.textOnLight, BorderSide.none),
      AppButtonVariant.secondary => (colors.surfaceRaised, colors.textPrimary, BorderSide(color: colors.borderStrong)),
      AppButtonVariant.destructive => (colors.danger, colors.textOnLight, BorderSide.none),
      AppButtonVariant.text => (
        Colors.transparent,
        ButtonForeground.maybeOf(context) ?? colors.accentPrimary,
        BorderSide.none,
      ),
      AppButtonVariant.destructiveText => (Colors.transparent, colors.destructiveText, BorderSide.none),
    };

    final enabled = onPressed != null && !isLoading;

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(_isFilled ? 64 : AppSpacing.minTouchTarget, _isFilled ? 52 : AppSpacing.minTouchTarget),
      ),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: _isFilled ? AppSpacing.xl : AppSpacing.sm)),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (!_isFilled) return Colors.transparent;
        // Disabled keeps its colour; opacity is applied to the whole button.
        if (states.contains(WidgetState.pressed)) {
          return switch (variant) {
            AppButtonVariant.primary => colors.buttonPrimaryBg.withValues(alpha: 0.85),
            AppButtonVariant.destructive => colors.danger.withValues(alpha: 0.85),
            _ => colors.surfacePressed,
          };
        }
        return background;
      }),
      foregroundColor: WidgetStatePropertyAll(foreground),
      overlayColor: WidgetStatePropertyAll(
        _isFilled ? Colors.transparent : colors.surfacePressed.withValues(alpha: 0.6),
      ),
      textStyle: WidgetStatePropertyAll(_isFilled ? text.button : text.label.copyWith(fontSize: 15)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button))),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return BorderSide(color: colors.accentPrimary, width: 2);
        }
        return side;
      }),
      elevation: const WidgetStatePropertyAll(0),
      tapTargetSize: MaterialTapTargetSize.padded,
      animationDuration: AppMotion.quick,
    );

    final child = isLoading
        ? SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: foreground))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.xs),
              ] else if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center, maxLines: 2)),
            ],
          );

    Widget button = Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: TextButton(onPressed: enabled ? onPressed : null, style: style, child: child),
    );

    if (isLoading) {
      // Keep announcing the label while the spinner shows.
      button = Semantics(
        label: label,
        button: true,
        enabled: false,
        child: ExcludeSemantics(child: button),
      );
    }

    if (_isFilled && expand) {
      final maxWidth = WindowClass.of(context).isCompact ? double.infinity : 400.0;
      button = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: button),
      );
    }
    return button;
  }
}

/// Overrides the colour of text buttons below it, for example a banner
/// action on an amber background, where the accent blue would fail the
/// contrast minimum (NFR-ACC).
class ButtonForeground extends InheritedWidget {
  const ButtonForeground({super.key, required this.color, required super.child});

  final Color color;

  static Color? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ButtonForeground>()?.color;

  @override
  bool updateShouldNotify(ButtonForeground oldWidget) => color != oldWidget.color;
}
