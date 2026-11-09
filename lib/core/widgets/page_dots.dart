import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Page indicator (UI/UX spec S-02): 8 pt dots, the active one a 24 × 8 pt
/// pill in `text.primary`. Screen readers hear [semanticLabel] (for example
/// "Page 2 of 3"), announced whenever it changes.
class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.count,
    required this.index,
    required this.semanticLabel,
    this.activeColor,
    this.inactiveColor,
  });

  final int count;
  final int index;
  final String semanticLabel;

  /// Override for light backgrounds (the S-04 spotlight).
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = activeColor ?? colors.textPrimary;
    final inactive = inactiveColor ?? colors.borderStrong;
    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: AppMotion.standard,
                curve: AppMotion.standardCurve,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                width: i == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == index ? active : inactive,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
