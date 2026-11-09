import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_mark.dart';

/// A mini notification in the iOS style (spec S-08 item 4), for example
/// "Family Camry · Engine oil due in 7 days".
class NotificationPreview extends StatelessWidget {
  const NotificationPreview({super.key, required this.vehicleName, required this.itemName});

  final String vehicleName;
  final String itemName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final message = l10n.primerPreviewText(vehicleName, itemName);

    return Semantics(
      label: l10n.primerPreviewSemantic(message),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadii.row),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppMark(size: 36),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.primerPreviewApp,
                          style: text.caption.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(l10n.primerPreviewTime, style: text.caption.copyWith(color: colors.textTertiary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(message, style: text.bodyS.copyWith(color: colors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
