import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// A filter chip that opens a choice sheet, for example "Year: 2026 ▾"
/// (UI/UX spec S-20 item 3). [active] (a filter is set) uses the selected
/// chip style, so the state never relies on the label alone.
class AppDropdownChip extends StatelessWidget {
  const AppDropdownChip({super.key, required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = active ? colors.textOnLight : colors.textPrimary;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Center(
          widthFactor: 1,
          child: Material(
            color: active ? colors.buttonPrimaryBg : colors.surfaceCard,
            shape: StadiumBorder(side: BorderSide(color: active ? colors.buttonPrimaryBg : colors.borderSubtle)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 36),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm, end: AppSpacing.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(label, style: context.text.label.copyWith(color: foreground)),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_down, size: 18, color: foreground),
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
