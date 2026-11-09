import 'dart:async';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../account/application/account_providers.dart';
import '../../account/domain/account.dart';
import '../../garage/application/vehicle_dues.dart';
import '../../privacy/application/consent_providers.dart';
import '../../reference/application/reference_providers.dart';
import '../../settings/application/locale_controller.dart';
import '../../settings/application/preferences_providers.dart';
import '../../settings/application/profile_data.dart';
import '../../vehicles/application/garage_providers.dart';
import '../data/local_notification_scheduler.dart';
import '../domain/notification_permission.dart';
import '../domain/reminder_plan.dart';
import 'notification_settings.dart';
import 'reminder_notifications.dart';
import 'reminder_primer_service.dart';

/// Swap for the local-notifications plugin later.
final localNotificationSchedulerProvider = Provider<LocalNotificationScheduler>(
  (ref) => MockLocalNotificationScheduler(),
);

/// Plans this phone's reminders (spec S-35, BR-NOT-02): for Guests with
/// reminders on and permission granted, the next 30 days are scheduled
/// locally with the same rules the server uses. Owners and anyone with
/// reminders off have none scheduled here.
class ReminderScheduler {
  ReminderScheduler(this._ref);

  final Ref _ref;

  /// How far ahead the phone schedules; replanned on every change.
  static const horizonDays = 30;

  Future<List<ReminderNotification>> plan() async {
    final garage = _ref.read(garageRepositoryProvider);
    final reference = _ref.read(referenceRepositoryProvider);
    final preferences = await _ref.read(preferencesRepositoryProvider).load();
    final today = _ref.read(clockProvider)();
    final locale = _ref.read(localeControllerProvider) ?? PlatformDispatcher.instance.locale;
    final language = locale.languageCode == 'ar' ? 'ar' : 'en';
    final l10n = lookupAppLocalizations(Locale(language));
    final brands = await reference.brands();

    final notifications = <ReminderNotification>[];
    for (final vehicle in await garage.vehicles()) {
      final readings = await garage.readings(vehicle.id);
      final dues = vehicleDues(
        vehicle,
        await garage.schedule(vehicle.id),
        readings: readings,
        unit: preferences.distanceUnit,
        today: today,
      );
      final brand = brands.where((b) => b.id == vehicle.brandId).firstOrNull;
      final model = brand == null || vehicle.modelId == null
          ? null
          : (await reference.models(brand.id)).where((m) => m.id == vehicle.modelId).firstOrNull;
      final name =
          vehicle.nickname ??
          '${brand?.name(language) ?? vehicle.brandOtherName ?? ''} ${model?.name(language) ?? vehicle.modelOtherName ?? ''}'
              .trim();
      final plan = planReminders(
        [VehicleReminderInput(vehicleId: vehicle.id, dues: dues, lastReadingDate: vehicle.odometerUpdatedAt)],
        from: today,
        days: horizonDays,
      );
      for (final reminder in plan) {
        // Today's 09:00 may have passed already.
        if (!reminder.fireAt.isAfter(today)) continue;
        notifications.add(
          buildNotification(
            reminder,
            l10n: l10n,
            languageCode: language,
            digits: preferences.digitStyle,
            vehicleName: name,
            itemName: (r) => r.due.item.name(language),
          ),
        );
      }
    }
    return notifications..sort((a, b) => a.fireAt.compareTo(b.fireAt));
  }

  /// Brings the phone's schedule in line with the garage and settings
  /// (BR-NOT-04: completing, snoozing or rescheduling replans).
  Future<void> reschedule() async {
    final scheduler = _ref.read(localNotificationSchedulerProvider);
    final account = await _ref.read(accountRepositoryProvider).load();
    final enabled = await _ref.read(reminderSettingsRepositoryProvider).enabled();
    final permission = await _ref.read(notificationPermissionRepositoryProvider).status();
    if (account is OwnerAccount || !enabled || permission != NotificationPermission.granted) {
      await scheduler.cancelAll();
      return;
    }
    await scheduler.replaceAll(await plan());
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>(ReminderScheduler.new);

/// Replans whenever the garage, the settings, the account or the language
/// change. The app watches it once, at the root.
final reminderSyncProvider = Provider<void>((ref) {
  ref
    ..watch(garageRevisionProvider)
    ..watch(profileRevisionProvider)
    ..watch(accountProvider)
    ..watch(localeControllerProvider);
  unawaited(ref.read(reminderSchedulerProvider).reschedule());
});
