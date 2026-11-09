import 'package:flutter/foundation.dart';

import '../../maintenance/domain/item_due.dart';
import '../../maintenance/domain/severity.dart';

/// Reminders go out at 09:00 local time (BR-NOT-01).
const reminderHour = 9;

/// Days before the due date with a reminder (FR-NOT-01).
const dueSoonOffsets = [30, 7];

/// Days after the item becomes overdue with a reminder (FR-NOT-02).
const overdueOffsets = [1, 3, 7, 14];

/// After day 14, critical items keep a reminder every 30 days (FR-NOT-02).
const criticalRepeatDays = 30;

/// No reading for this long: the mileage nudge, at most once a month
/// (FR-NOT-03).
const mileageNudgeDays = 30;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
int _days(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// One item's reminder on one day.
sealed class ItemReminder {
  const ItemReminder(this.due, this.dueDate);

  final ItemDue due;

  /// The due date it counts from; with the stage, the dedupe key
  /// (BR-NOT-08).
  final DateTime dueDate;

  String get stage;
  String get key => '${due.item.id}|$stage|${_day(dueDate).toIso8601String().substring(0, 10)}';
}

/// "Engine oil due in 7 days" (30 and 7 days before).
final class DueInReminder extends ItemReminder {
  const DueInReminder(super.due, super.dueDate, this.days);

  final int days;

  @override
  String get stage => 'before-$days';
}

/// "Brake fluid due tomorrow".
final class DueTomorrowReminder extends ItemReminder {
  const DueTomorrowReminder(super.due, super.dueDate);

  @override
  String get stage => 'before-1';
}

/// "Brake pads overdue by 3 days".
final class OverdueReminder extends ItemReminder {
  const OverdueReminder(super.due, super.dueDate, this.days);

  final int days;

  @override
  String get stage => 'overdue-$days';
}

/// The reminder [due] gets on [day], if any (FR-NOT-01, FR-NOT-02):
///
/// * 30, 7 and 1 day before the due (or predicted) date;
/// * 1, 3, 7 and 14 days after it, then every 30 days for critical items;
/// * nothing while snoozed (BR-NOT-06), for "not applicable", or without
///   a due date (Unknown, or mileage-only with no prediction).
ItemReminder? itemReminderOn(ItemDue due, DateTime day) {
  if (due.status == ItemStatus.notApplicable || due.status == ItemStatus.unknown) return null;
  final snoozedUntil = due.item.snoozedUntil;
  if (snoozedUntil != null && _day(day).isBefore(_day(snoozedUntil))) return null;
  // Overdue by mileage counts from when the odometer passed the due point.
  final dueDate = due.status == ItemStatus.overdue ? (due.overdueSince ?? due.effectiveDueDate) : due.effectiveDueDate;
  if (dueDate == null) return null;

  final offset = _days(dueDate, day);
  if (offset < 0) {
    final before = -offset;
    if (before == 1) return DueTomorrowReminder(due, dueDate);
    if (dueSoonOffsets.contains(before)) return DueInReminder(due, dueDate, before);
    return null;
  }
  if (overdueOffsets.contains(offset)) return OverdueReminder(due, dueDate, offset);
  final critical = due.item.severity == Severity.critical;
  if (critical && offset > overdueOffsets.last && (offset - overdueOffsets.last) % criticalRepeatDays == 0) {
    return OverdueReminder(due, dueDate, offset);
  }
  return null;
}

/// What one vehicle gets on one day: a single item, or a bundle of several
/// (BR-NOT-03), plus the mileage nudge.
sealed class PlannedReminder {
  const PlannedReminder(this.vehicleId, this.day);

  final String vehicleId;
  final DateTime day;

  /// 09:00 local time (BR-NOT-01).
  DateTime get fireAt => DateTime(day.year, day.month, day.day, reminderHour);

  /// Never sent twice (BR-NOT-08).
  String get key;
}

final class SingleItemReminder extends PlannedReminder {
  const SingleItemReminder(super.vehicleId, super.day, this.reminder);

  final ItemReminder reminder;

  @override
  String get key => '$vehicleId|${reminder.key}';
}

/// "3 items need attention", opening the bundle sheet.
final class BundleReminder extends PlannedReminder {
  const BundleReminder(super.vehicleId, super.day, this.reminders);

  final List<ItemReminder> reminders;

  @override
  String get key => '$vehicleId|bundle|${[for (final r in reminders) r.key].join(',')}';
}

/// "Update your mileage. It's been 34 days."
final class MileageNudge extends PlannedReminder {
  const MileageNudge(super.vehicleId, super.day, this.daysSinceReading);

  final int daysSinceReading;

  @override
  String get key => '$vehicleId|mileage|${_day(day).toIso8601String().substring(0, 10)}';
}

/// One vehicle's state for planning.
@immutable
class VehicleReminderInput {
  const VehicleReminderInput({required this.vehicleId, required this.dues, this.lastReadingDate});

  final String vehicleId;
  final List<ItemDue> dues;
  final DateTime? lastReadingDate;
}

/// The reminders for [days] days from [from] (the local schedule for
/// Guests, BR-NOT-02). Several items for a vehicle on one day become one
/// bundle (BR-NOT-03). The mileage nudge goes out on day 31 without a
/// reading, then every 30 days (FR-NOT-03). Items are listed most urgent
/// first: overdue, then due tomorrow, then due soon.
List<PlannedReminder> planReminders(List<VehicleReminderInput> vehicles, {required DateTime from, int days = 30}) {
  final plan = <PlannedReminder>[];
  for (var i = 0; i < days; i++) {
    final day = _day(from).add(Duration(days: i));
    for (final vehicle in vehicles) {
      final reminders = [for (final due in vehicle.dues) ?itemReminderOn(due, day)]..sort(_byUrgency);
      if (reminders.length == 1) plan.add(SingleItemReminder(vehicle.vehicleId, day, reminders.single));
      if (reminders.length > 1) plan.add(BundleReminder(vehicle.vehicleId, day, reminders));

      final last = vehicle.lastReadingDate;
      if (last != null) {
        final since = _days(last, day);
        if (since > mileageNudgeDays && (since - mileageNudgeDays - 1) % mileageNudgeDays == 0) {
          plan.add(MileageNudge(vehicle.vehicleId, day, since));
        }
      }
    }
  }
  return plan;
}

int _urgency(ItemReminder r) => switch (r) {
  OverdueReminder() => 0,
  DueTomorrowReminder() => 1,
  DueInReminder() => 2,
};

int _byUrgency(ItemReminder a, ItemReminder b) {
  final byKind = _urgency(a).compareTo(_urgency(b));
  return byKind != 0 ? byKind : a.due.item.severity.index.compareTo(b.due.item.severity.index);
}
