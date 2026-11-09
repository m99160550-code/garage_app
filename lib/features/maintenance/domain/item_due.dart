import 'package:flutter/foundation.dart';

import '../../settings/domain/distance_unit.dart';
import 'schedule_item.dart';
import 'schedule_rules.dart';

/// Where a schedule item stands today (architecture `item_status`).
enum ItemStatus { unknown, ok, dueSoon, overdue, notApplicable }

/// Days before the due date when an item becomes "due soon" (BR-MNT-03).
const dueSoonDays = 30;

/// Remaining distance that makes a mileage-only item "due soon" when there
/// is no prediction (BR-MNT-05): 1,000 km, or 600 mi for mile users.
int dueSoonFallbackKm(DistanceUnit unit) => unit == DistanceUnit.km ? 1000 : 966;

/// Overdue by more than this counts double (BR-HLT-02).
const doubleOverdueDays = 30;
int doubleOverdueKm(DistanceUnit unit) => unit == DistanceUnit.km ? 1000 : 966;

/// The derived due point of one schedule item (BR-MNT-01 to BR-MNT-05).
@immutable
class ItemDue {
  const ItemDue({
    required this.item,
    required this.status,
    this.nextDueDate,
    this.nextDueKm,
    this.predictedDueDate,
    this.overdueSince,
    this.daysOverdue = 0,
    this.kmOverdue = 0,
    this.kmRemaining,
    this.snoozed = false,
  });

  final ScheduleItem item;
  final ItemStatus status;

  /// Last done + interval months.
  final DateTime? nextDueDate;

  /// Last done + interval distance.
  final int? nextDueKm;

  /// When the due mileage will be reached at the usual daily distance
  /// (BR-MNT-04).
  final DateTime? predictedDueDate;

  /// The due date, or the date the odometer passed the due mileage
  /// (BR-MNT-02).
  final DateTime? overdueSince;
  final int daysOverdue;
  final int kmOverdue;

  /// Distance left before the due mileage, if it has one.
  final int? kmRemaining;

  /// Snoozed today: a due-soon item then doesn't count (BR-HLT-05).
  final bool snoozed;

  /// How much of the interval is used, 0–1, by time or distance,
  /// whichever is further (the S-14 progress bar). `null` without a due
  /// point.
  double? progress({required DateTime today, required int currentKm}) {
    final parts = <double>[];
    final done = item.lastDoneDate;
    if (done != null && nextDueDate != null) {
      final total = _days(done, nextDueDate!);
      if (total > 0) parts.add(_days(done, today) / total);
    }
    if (item.lastDoneKm != null && item.intervalKm != null && item.intervalKm! > 0) {
      parts.add((currentKm - item.lastDoneKm!) / item.intervalKm!);
    }
    if (parts.isEmpty) return null;
    return parts.reduce((a, b) => a > b ? a : b).clamp(0.0, 1.0);
  }

  /// Overdue because the due date passed (rather than only the mileage).
  bool get overdueByDate => status == ItemStatus.overdue && overdueSince != null && overdueSince == nextDueDate;

  /// The earlier of the due date and the predicted date: what "Next
  /// service" counts down to.
  DateTime? get effectiveDueDate {
    final dates = [nextDueDate, predictedDueDate].whereType<DateTime>();
    if (dates.isEmpty) return null;
    return dates.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Days from [today] to [effectiveDueDate] (0 = due today).
  int? daysUntil(DateTime today) {
    final due = effectiveDueDate;
    return due == null ? null : _days(_dateOnly(today), due);
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole calendar days from [from] to [to] (negative if [to] is earlier).
int _days(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Calculates where [item] stands (BR-MNT-01 to BR-MNT-05).
///
/// [dailyKm] is the average daily distance (BR-MIL-05), or `null` when
/// there aren't enough readings for a prediction. [odometerDate] is when
/// [currentKm] was read, used as the overdue date for mileage items.
ItemDue computeItemDue(
  ScheduleItem item, {
  required int currentKm,
  required DateTime today,
  required DistanceUnit unit,
  double? dailyKm,
  DateTime? odometerDate,
}) {
  final day = _dateOnly(today);
  if (item.notApplicable) return ItemDue(item: item, status: ItemStatus.notApplicable);
  final snoozed = item.snoozedUntil != null && _dateOnly(item.snoozedUntil!).isAfter(day);
  // A reschedule replaces the due date for this cycle only (BR-MNT-06).
  final dueDate = item.rescheduledDueDate != null
      ? _dateOnly(item.rescheduledDueDate!)
      : item.lastDoneDate != null && item.intervalMonths != null
      ? addMonths(_dateOnly(item.lastDoneDate!), item.intervalMonths!)
      : null;
  final dueKm = item.lastDoneKm != null && item.intervalKm != null ? item.lastDoneKm! + item.intervalKm! : null;

  // A baseline that gives no due point (for example a mileage for an item
  // with only a time interval) leaves the item Unknown.
  if (dueDate == null && dueKm == null) return ItemDue(item: item, status: ItemStatus.unknown);

  final kmRemaining = dueKm == null ? null : dueKm - currentKm;
  final predicted = kmRemaining != null && kmRemaining > 0 && dailyKm != null && dailyKm > 0
      ? day.add(Duration(days: (kmRemaining / dailyKm).ceil()))
      : null;

  // Overdue: past the due date, or past the due mileage (BR-MNT-02).
  final overdueByDate = dueDate != null && day.isAfter(dueDate);
  final overdueByKm = kmRemaining != null && kmRemaining < 0;
  if (overdueByDate || overdueByKm) {
    final readingDate = _dateOnly(odometerDate ?? day);
    final since = [if (overdueByDate) dueDate, if (overdueByKm) readingDate].reduce((a, b) => a.isBefore(b) ? a : b);
    return ItemDue(
      item: item,
      status: ItemStatus.overdue,
      nextDueDate: dueDate,
      nextDueKm: dueKm,
      overdueSince: since,
      daysOverdue: _days(since, day),
      kmOverdue: overdueByKm ? -kmRemaining : 0,
      kmRemaining: kmRemaining,
      snoozed: snoozed,
    );
  }

  // Due soon: within 30 days by date or prediction (BR-MNT-03), or close
  // by distance when there's no prediction (BR-MNT-05).
  final soonByDate = [dueDate, predicted].whereType<DateTime>().any((d) => _days(day, d) <= dueSoonDays);
  final soonByKm = predicted == null && kmRemaining != null && kmRemaining <= dueSoonFallbackKm(unit);
  return ItemDue(
    item: item,
    status: soonByDate || soonByKm ? ItemStatus.dueSoon : ItemStatus.ok,
    nextDueDate: dueDate,
    nextDueKm: dueKm,
    predictedDueDate: predicted,
    kmRemaining: kmRemaining,
    snoozed: snoozed,
  );
}
