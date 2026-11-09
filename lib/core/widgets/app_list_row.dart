import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// List row (UI/UX spec 1.7): at least 64 pt high, optional leading tile,
/// title and subtitle stacked, optional trailing widget.
///
/// [card] rows sit in a list of cards (radius 18, `surface.card`). Selected
/// card rows are raised with a strong border. Non-card rows are flat, for
/// grouped lists and sheets.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.card = true,
    this.minHeight = 64,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final bool card;
  final double minHeight;

  /// Replaces the spoken label built from title and subtitle.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final radius = BorderRadius.circular(card ? AppRadii.row : 0);

    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.sm)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: text.titleM),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: text.bodyS.copyWith(color: colors.textSecondary)),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: AppSpacing.sm), trailing!],
          ],
        ),
      ),
    );

    return Semantics(
      selected: selected,
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: AnimatedContainer(
        duration: AppMotion.standard,
        decoration: BoxDecoration(
          color: !card ? Colors.transparent : (selected ? colors.surfaceRaised : colors.surfaceCard),
          borderRadius: radius,
          border: card ? Border.all(color: selected ? colors.borderStrong : colors.borderSubtle) : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: onTap, borderRadius: radius, child: content),
        ),
      ),
    );
  }
}
