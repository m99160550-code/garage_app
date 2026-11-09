import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'app_sheet.dart';

/// TEMPORARY: stands in for sheets that haven't been built yet (S-10, S-12,
/// S-18, S-23), so every tap works while screens are delivered one at a
/// time. Not localised on purpose.
Future<void> showPlaceholderSheet(BuildContext context, {required String screenId, required String title}) {
  return showAppSheet<void>(
    context: context,
    fitContent: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(screenId, style: context.text.overline.copyWith(color: context.colors.textTertiary)),
          const SizedBox(height: AppSpacing.xs),
          Text(title, style: context.text.titleL, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text('Coming in a later step', style: context.text.bodyS.copyWith(color: context.colors.textSecondary)),
        ],
      ),
    ),
  );
}
