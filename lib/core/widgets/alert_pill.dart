import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

enum AlertPillTone { danger, warning, info, success }

/// Alert pill (UI/UX spec 1.7, S-09): 36 pt high, radius full, 16 pt
/// horizontal padding, a 16 pt icon and `label` text. Always icon + text,
/// never colour alone (BR-MNT-10).
class AlertPill extends StatelessWidget {
  const AlertPill({super.key, required this.label, required this.tone, this.icon, this.onTap});

  final String label;
  final AlertPillTone tone;

  /// Defaults to the tone's icon.
  final IconData? icon;

  /// Makes the pill a button with a 44 pt tap area (the dashboard pill).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground, defaultIcon) = switch (tone) {
      AlertPillTone.danger => (colors.dangerContainer, colors.onDangerContainer, Icons.error_outline),
      AlertPillTone.warning => (colors.warningContainer, colors.onWarningContainer, Icons.schedule),
      AlertPillTone.info => (colors.infoContainer, colors.onInfoContainer, Icons.info_outline),
      AlertPillTone.success => (colors.successContainer, colors.onSuccessContainer, Icons.check_circle_outline),
    };
    final pill = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: Material(
        color: background,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon ?? defaultIcon, size: 16, color: foreground),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(label, style: context.text.label.copyWith(color: foreground)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (onTap == null) return pill;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Center(widthFactor: 1, child: pill),
      ),
    );
  }
}
