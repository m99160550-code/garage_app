import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Choice chip (UI/UX spec 1.7): 36 pt pill (44 pt tap area).
/// Unselected: `surface.card` with a border. Selected: white fill with a
/// check at the start. Screen readers hear it as a selectable button.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.multiSelect = false,
    this.semanticLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Optional small visual before the label, for example a silhouette.
  final Widget? leading;

  /// Several chips can be on at once (S-22 items): screen readers hear a
  /// toggle button rather than one of a group.
  final bool multiSelect;

  /// Spoken instead of [label], for example "Engine oil, due soon".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.textOnLight : colors.textPrimary;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: !multiSelect,
      toggled: multiSelect ? selected : null,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Center(
          widthFactor: 1,
          child: Material(
            color: selected ? colors.buttonPrimaryBg : colors.surfaceCard,
            shape: StadiumBorder(side: BorderSide(color: selected ? colors.buttonPrimaryBg : colors.borderSubtle)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 36),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        Icon(Icons.check, size: 14, color: foreground),
                        const SizedBox(width: AppSpacing.xxs),
                      ],
                      if (leading != null) ...[leading!, const SizedBox(width: 6)],
                      // Wraps instead of overflowing at large text sizes.
                      Flexible(
                        child: Text(label, style: context.text.label.copyWith(color: foreground)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
