import 'package:flutter/foundation.dart';

import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../domain/notification_target.dart';
import '../domain/reminder_plan.dart';

/// A notification as the phone shows it (spec S-35): the title, the body,
/// the thread (one per vehicle, iOS `threadIdentifier`), the time and the
/// deep link. No emoji; the app icon is the only image.
@immutable
class ReminderNotification {
  const ReminderNotification({
    required this.id,
    required this.threadId,
    required this.title,
    required this.body,
    required this.fireAt,
    required this.target,
  });

  /// The dedupe key (BR-NOT-08).
  final String id;
  final String threadId;
  final String title;
  final String body;
  final DateTime fireAt;
  final NotificationTarget target;

  String get deepLink => target.link(stamp: '${fireAt.millisecondsSinceEpoch}');
}

/// The text of [reminder] in the app language, with numbers in the user's
/// digit style (spec S-35 rules). [itemName] names a schedule item by
/// code in that language.
ReminderNotification buildNotification(
  PlannedReminder reminder, {
  required AppLocalizations l10n,
  required String languageCode,
  required DigitStyle digits,
  required String vehicleName,
  required String Function(ItemReminder) itemName,
}) {
  final numbers = AppFormatters(languageCode: languageCode, digits: digits);
  String days(int count) => l10n.notifDays(count, numbers.integer(count));

  String itemLine(ItemReminder r) => switch (r) {
    DueInReminder(:final days) => l10n.notifDueIn(itemName(r), _days(l10n, numbers, days)),
    DueTomorrowReminder() => l10n.notifDueTomorrow(itemName(r)),
    OverdueReminder(:final days) => l10n.notifOverdue(itemName(r), _days(l10n, numbers, days)),
  };

  final (String title, String body, NotificationTarget target) = switch (reminder) {
    SingleItemReminder(:final reminder, :final vehicleId) => (
      vehicleName,
      itemLine(reminder),
      OpenItem(vehicleId, reminder.due.item.code),
    ),
    BundleReminder(:final reminders, :final vehicleId) => (
      vehicleName,
      l10n.notifBundle(reminders.length, numbers.integer(reminders.length)),
      OpenBundle(vehicleId, [for (final r in reminders) r.due.item.code]),
    ),
    MileageNudge(:final daysSinceReading, :final vehicleId) => (
      l10n.notifMileageTitle,
      l10n.notifMileageBody(days(daysSinceReading), numbers.integer(5)),
      OpenMileage(vehicleId),
    ),
  };
  return ReminderNotification(
    id: reminder.key,
    threadId: reminder.vehicleId,
    title: title,
    body: body,
    fireAt: reminder.fireAt,
    target: target,
  );
}

String _days(AppLocalizations l10n, AppFormatters numbers, int count) => l10n.notifDays(count, numbers.integer(count));
