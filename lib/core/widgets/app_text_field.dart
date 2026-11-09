import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Text input (UI/UX spec 1.7): 56 pt, radius 14, `surface.card` fill,
/// floating label, optional suffix ("km", "SAR"), helper, warning or error.
///
/// * Errors: red border, icon and text. They block saving.
/// * Warnings: amber border, icon and text. They don't block (for example
///   an unusual VIN length).
/// Neither relies on colour alone.
///
/// Set [onTap] with [readOnly] for picker fields (year, dates).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.helper,
    this.error,
    this.warning,
    this.suffixText,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofocus = false,
    this.focusNode,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
    this.trailingIcon,
    this.textDirection,
    this.valueStyle,
    this.enabled = true,
    this.minLines,
    this.maxLines = 1,
    this.obscureText = false,
    this.autofillHints,
    this.trailing,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? helper;
  final String? error;
  final String? warning;
  final String? suffixText;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final VoidCallback? onTap;

  /// Icon at the end when there is no error, for example a calendar.
  final IconData? trailingIcon;

  /// Force a direction, for example left to right for VINs and plates.
  final TextDirection? textDirection;

  /// Extra style for the value, for example tabular digits.
  final TextStyle? valueStyle;

  /// Disabled fields are greyed out and skipped by screen-reader focus,
  /// for example when "I don't know" is selected.
  final bool enabled;

  /// For multiline fields (notes): grows from [minLines] to [maxLines].
  final int? minLines;
  final int? maxLines;

  /// Passwords (S-28).
  final bool obscureText;
  final Iterable<String>? autofillHints;

  /// A button at the end, for example show/hide password. Replaced by the
  /// error icon while there is an error.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final radius = BorderRadius.circular(AppRadii.input);
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: color, width: width),
    );

    final hasWarning = error == null && warning != null;
    final restBorder = hasWarning ? colors.warning : colors.borderSubtle;

    final Widget? suffixIcon = error != null
        ? Icon(Icons.error_outline, color: colors.danger)
        : hasWarning
        ? Icon(Icons.warning_amber_rounded, color: colors.warning)
        : trailing ??
              (trailingIcon == null
                  ? null
                  : Icon(trailingIcon, color: enabled ? colors.textSecondary : colors.textDisabled));

    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      autofocus: autofocus,
      focusNode: focusNode,
      readOnly: readOnly,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      textDirection: textDirection,
      minLines: minLines,
      maxLines: obscureText ? 1 : maxLines,
      obscureText: obscureText,
      autofillHints: autofillHints,
      inputFormatters: [...?inputFormatters, if (maxLength != null) LengthLimitingTextInputFormatter(maxLength)],
      style: text.body.copyWith(color: enabled ? colors.textPrimary : colors.textDisabled).merge(valueStyle),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: text.body.copyWith(color: enabled ? colors.textSecondary : colors.textDisabled),
        floatingLabelStyle: text.bodyS.copyWith(color: colors.textSecondary),
        helperText: error == null ? (warning ?? helper) : null,
        helperStyle: text.caption.copyWith(color: hasWarning ? colors.warning : colors.textTertiary),
        helperMaxLines: 3,
        errorText: error,
        errorStyle: text.caption.copyWith(color: colors.danger),
        errorMaxLines: 3,
        suffixText: suffixText,
        suffixStyle: text.body.copyWith(color: enabled ? colors.textSecondary : colors.textDisabled),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? colors.surfaceCard : colors.bgBase,
        constraints: const BoxConstraints(minHeight: 56),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: border(restBorder),
        enabledBorder: border(restBorder),
        disabledBorder: border(colors.borderSubtle),
        focusedBorder: border(hasWarning ? colors.warning : colors.accentPrimary, 2),
        errorBorder: border(colors.danger),
        focusedErrorBorder: border(colors.danger, 2),
      ),
    );
  }
}
