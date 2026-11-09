import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Empty state (UI/UX spec 1.7, S-34): a 120 pt line illustration, a
/// `title.m` heading, a `body.s` explanation and one primary action. The
/// text is screen-specific.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key, required this.icon, required this.title, this.body, this.action});

  final IconData icon;
  final String title;
  final String? body;

  /// One primary action, usually an [AppButton].
  final Widget? action;

  static const illustrationSize = 120.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: illustrationSize,
              height: illustrationSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderStrong, width: 1.5),
              ),
              child: Icon(icon, size: 52, color: colors.textTertiary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(title, style: text.titleM, textAlign: TextAlign.center),
          ),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              body!,
              style: text.bodyS.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
        ],
      ),
    );
  }
}
