import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Dashboard stat card (UI/UX spec 1.7 and S-09 "Stat card anatomy").
///
/// 148 × 168 pt by default. The focused card is raised with a strong border
/// and shadow. Values use tabular figures.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.sublabel,
    required this.value,
    this.unit,
    this.footer,
    this.focused = false,
    this.valueColor,
    this.onTap,
    this.semanticLabel,
    this.width = 148,
    this.height = 168,
    this.horizontal = false,
    this.sublabelIcon,
  });

  final String label;
  final String sublabel;
  final String value;

  /// Small unit after the value, for example "km".
  final String? unit;
  final String? footer;
  final bool focused;
  final Color? valueColor;
  final VoidCallback? onTap;

  /// Full spoken description, for example
  /// "Mileage, 54,320 kilometres, updated 4 days ago".
  final String? semanticLabel;
  final double? width;
  final double? height;

  /// Label and sublabel at the start, value at the end: the stacked cards
  /// on iPad landscape and with large text (spec S-09 "Responsive").
  final bool horizontal;

  /// Icon before the sublabel, for example the danger icon when overdue.
  final IconData? sublabelIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    final valueText = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: value),
          if (unit != null)
            TextSpan(
              text: ' $unit',
              style: text.label.copyWith(color: colors.textSecondary),
            ),
        ],
      ),
      style: AppTextStyles.tabular(text.displayStat).copyWith(color: valueColor ?? colors.textPrimary),
      maxLines: 1,
    );
    final sublabelRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sublabelIcon != null) ...[
          Icon(sublabelIcon, size: 14, color: valueColor ?? colors.textTertiary),
          const SizedBox(width: AppSpacing.xxs),
        ],
        Flexible(
          child: Text(
            sublabel,
            style: text.caption.copyWith(color: colors.textTertiary),
            textAlign: horizontal ? TextAlign.start : TextAlign.center,
          ),
        ),
      ],
    );

    final content = horizontal
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: text.titleM),
                      const SizedBox(height: 2),
                      sublabelRow,
                      if (footer != null && footer!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(footer!, style: text.caption.copyWith(color: colors.textTertiary)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: FittedBox(fit: BoxFit.scaleDown, child: valueText),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // One line, shrinking if needed, so the card never overflows.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: text.titleM, maxLines: 1),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    sublabelRow,
                    const SizedBox(height: AppSpacing.xxs),
                    FittedBox(fit: BoxFit.scaleDown, child: valueText),
                  ],
                ),
                Text(
                  footer ?? '',
                  style: text.caption.copyWith(color: colors.textTertiary),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          );

    final card = AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.standardCurve,
      width: width,
      // Horizontal cards grow with their text instead of overflowing.
      height: horizontal ? null : height,
      constraints: horizontal && height != null ? BoxConstraints(minHeight: height!) : null,
      decoration: BoxDecoration(
        color: focused ? colors.surfaceRaised : colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadii.statCard),
        border: Border.all(color: focused ? colors.borderStrong : colors.borderSubtle),
        boxShadow: focused ? const [BoxShadow(color: Color(0x73000000), blurRadius: 32, offset: Offset(0, 12))] : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadii.statCard), child: content),
      ),
    );

    return Semantics(button: onTap != null, label: semanticLabel, excludeSemantics: semanticLabel != null, child: card);
  }
}
