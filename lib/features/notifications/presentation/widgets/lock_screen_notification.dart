import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_mark.dart';
import '../../application/reminder_notifications.dart';

/// A reminder as it appears on the lock screen (spec S-35): the app icon
/// (the only image), the app name and time, the title in bold and the
/// body. Read aloud as one item.
class LockScreenNotification extends StatelessWidget {
  const LockScreenNotification({super.key, required this.notification, this.time});

  final ReminderNotification notification;

  /// "now", "09:00"…
  final String? time;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    return Semantics(
      container: true,
      label: '${l10n.primerPreviewApp}, ${notification.title}, ${notification.body}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surfaceRaised.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadii.row),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppMark(size: 38),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: text.bodyS.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(time ?? l10n.primerPreviewTime, style: text.caption.copyWith(color: colors.textTertiary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(notification.body, style: text.bodyS.copyWith(color: colors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
