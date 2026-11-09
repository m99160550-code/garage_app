import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

enum BadgeTone { neutral, info, success, warning, danger }

/// Small status pill, for example "Unknown" or "Due soon". Text is always
/// shown, so the meaning never relies on colour alone (BR-MNT-10).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.tone = BadgeTone.neutral, this.icon});

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (tone) {
      BadgeTone.neutral => (colors.surfaceRaised, colors.textSecondary),
      BadgeTone.info => (colors.infoContainer, colors.onInfoContainer),
      BadgeTone.success => (colors.successContainer, colors.onSuccessContainer),
      BadgeTone.warning => (colors.warningContainer, colors.onWarningContainer),
      BadgeTone.danger => (colors.dangerContainer, colors.onDangerContainer),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: foreground), const SizedBox(width: AppSpacing.xxs)],
            Flexible(
              child: Text(
                label,
                style: context.text.caption.copyWith(color: foreground, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
