import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/profile_data.dart';
import '../data/reminder_settings_repository.dart';
import '../domain/notification_permission.dart';
import 'reminder_primer_service.dart';

/// Swap for the settings-backed repository later.
final reminderSettingsRepositoryProvider = Provider<ReminderSettingsRepository>(
  (ref) => MockReminderSettingsRepository(),
);

/// What S-27 shows.
@immutable
class NotificationSettings {
  const NotificationSettings({required this.permission, required this.enabled});

  final NotificationPermission permission;

  /// The in-app switch (FR-NOT-05).
  final bool enabled;

  /// Reminders actually arrive only with both on.
  bool get remindersOn => enabled && permission == NotificationPermission.granted;
}

final notificationSettingsProvider = FutureProvider.autoDispose<NotificationSettings>((ref) async {
  ref.watch(profileRevisionProvider);
  final permission = ref.watch(notificationPermissionRepositoryProvider);
  final settings = ref.watch(reminderSettingsRepositoryProvider);
  return NotificationSettings(permission: await permission.status(), enabled: await settings.enabled());
});

/// The S-27 actions. Each refreshes S-27 and Profile.
class NotificationActions {
  NotificationActions(this._ref);

  final Ref _ref;

  void _refresh() => _ref.read(profileRevisionProvider.notifier).bump();

  /// Turning reminders on asks for the system permission if it was never
  /// asked (FR-USR-08). Declined earlier, only Settings can change it.
  Future<void> setEnabled(bool enabled) async {
    await _ref.read(reminderSettingsRepositoryProvider).setEnabled(enabled);
    final permission = _ref.read(notificationPermissionRepositoryProvider);
    if (enabled && await permission.status() == NotificationPermission.notDetermined) {
      await permission.request();
    }
    _refresh();
  }

  Future<void> requestPermission() async {
    await _ref.read(notificationPermissionRepositoryProvider).request();
    _refresh();
  }

  Future<void> openSystemSettings() => _ref.read(notificationPermissionRepositoryProvider).openSystemSettings();
}

final notificationActionsProvider = Provider<NotificationActions>(NotificationActions.new);
