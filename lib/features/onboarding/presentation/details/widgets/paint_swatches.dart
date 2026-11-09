import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../vehicles/domain/paint_color.dart';
import '../../../../vehicles/presentation/vehicle_labels.dart';

/// The 12 paint colours as 40 pt circles in a horizontal row (spec S-06
/// item 5). The selected swatch has a 2 pt `text.primary` ring and a check.
/// Colour names are spoken by screen readers.
class PaintSwatches extends StatelessWidget {
  const PaintSwatches({super.key, required this.selected, required this.onSelected});

  final PaintColor selected;
  final ValueChanged<PaintColor> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: PaintColor.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xxs),
        itemBuilder: (context, i) {
          final paint = PaintColor.values[i];
          final isSelected = paint == selected;
          // Check mark colour readable on light and dark paints.
          final checkColor = paint.color.computeLuminance() > 0.4 ? colors.textOnLight : colors.textPrimary;
          return Semantics(
            button: true,
            selected: isSelected,
            inMutuallyExclusiveGroup: true,
            label: paintColorLabel(l10n, paint),
            excludeSemantics: true,
            child: InkResponse(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(paint);
              },
              radius: 26,
              child: SizedBox.square(
                dimension: 52,
                child: Center(
                  child: AnimatedContainer(
                    duration: AppMotion.quick,
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? colors.textPrimary : Colors.transparent, width: 2),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: paint.color,
                        border: Border.all(color: colors.borderStrong),
                      ),
                      child: isSelected ? Icon(Icons.check, size: 18, color: checkColor) : null,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
