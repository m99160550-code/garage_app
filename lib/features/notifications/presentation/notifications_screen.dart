import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../settings/presentation/widgets/settings_list.dart';
import '../../settings/presentation/widgets/settings_page.dart';
import '../application/notification_settings.dart';
import '../domain/notification_permission.dart';

/// S-27 Notifications (UI/UX spec S-27, FR-NOT-05, FR-NOT-06): the
/// permission banner when the system permission is off, the "Service
/// reminders" switch, and how the schedule works. The v1.1 category,
/// time and quiet-hours rows are not shown in the MVP.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final data = ref.watch(notificationSettingsProvider).value;
    final actions = ref.read(notificationActionsProvider);

    return SettingsPage(
      title: l10n.profileNotifications,
      embedded: embedded,
      body: data == null
          ? const DelayedSkeleton()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              children: [
                // 1. The system permission (FR-NOT-06).
                if (data.permission == NotificationPermission.denied) ...[
                  AppBanner(
                    tone: BannerTone.warning,
                    message: l10n.notifOffInSettings,
                    action: AppButton.text(label: l10n.notifOpenSettings, onPressed: actions.openSystemSettings),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ] else if (data.permission == NotificationPermission.notDetermined && data.enabled) ...[
                  AppBanner(
                    message: l10n.notifNotAsked,
                    action: AppButton.text(label: l10n.notifAllow, onPressed: actions.requestPermission),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                // 2. The master switch (FR-NOT-05).
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: BorderRadius.circular(AppRadii.row),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: SettingsSwitchRow(
                    title: l10n.notifServiceReminders,
                    subline: l10n.notifServiceRemindersSub,
                    icon: Icons.notifications_outlined,
                    value: data.enabled,
                    onChanged: actions.setEnabled,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // 3. How the schedule works (FR-NOT-01, FR-NOT-02, BR-NOT-01).
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: BorderRadius.circular(AppRadii.row),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.schedule, size: 20, color: colors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(l10n.notifSchedule, style: text.bodyS.copyWith(color: colors.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
