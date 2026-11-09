import 'package:flutter/foundation.dart';

import 'item_due.dart';

/// Days without a new odometer reading before the dashboard asks for one
/// (BR-MNT-09, FR-NOT-03).
const staleMileageDays = 30;

/// The single alert pill on the dashboard, highest priority first
/// (BR-MNT-09).
sealed class DashboardAlert {
  const DashboardAlert();
}

/// One overdue item, or several ("3 items overdue").
final class OverdueAlert extends DashboardAlert {
  const OverdueAlert(this.items);

  /// Most severe first, then most overdue.
  final List<ItemDue> items;
}

/// The soonest item that's due soon.
final class DueSoonAlert extends DashboardAlert {
  const DueSoonAlert(this.item);

  final ItemDue item;
}

/// A synced reading waits for review (BR-SYN-03): "Check a mileage
/// reading", above due soon (spec 1.6).
final class MileageReviewAlert extends DashboardAlert {
  const MileageReviewAlert(this.readingId);

  /// The first reading to review.
  final String readingId;
}

final class UnknownItemsAlert extends DashboardAlert {
  const UnknownItemsAlert(this.count);

  final int count;
}

final class StaleMileageAlert extends DashboardAlert {
  const StaleMileageAlert(this.days);

  final int days;
}

final class AllGoodAlert extends DashboardAlert {
  const AllGoodAlert();
}

int _days(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Picks the alert pill (BR-MNT-09): overdue critical, major, minor, then
/// a mileage reading to review, due soon (soonest first), Unknown items,
/// stale mileage, "All good".
DashboardAlert pickAlert(
  List<ItemDue> dues, {
  required DateTime today,
  DateTime? odometerDate,
  String? reviewReadingId,
}) {
  final overdue = dues.where((d) => d.status == ItemStatus.overdue).toList()
    ..sort((a, b) {
      final bySeverity = a.item.severity.index.compareTo(b.item.severity.index);
      return bySeverity != 0 ? bySeverity : b.daysOverdue.compareTo(a.daysOverdue);
    });
  if (overdue.isNotEmpty) return OverdueAlert(List.unmodifiable(overdue));

  if (reviewReadingId != null) return MileageReviewAlert(reviewReadingId);

  // A snoozed item doesn't nag until the snooze ends (BR-HLT-05).
  final soon = dues.where((d) => d.status == ItemStatus.dueSoon && !d.snoozed).toList()
    ..sort((a, b) => (a.daysUntil(today) ?? 1 << 20).compareTo(b.daysUntil(today) ?? 1 << 20));
  if (soon.isNotEmpty) return DueSoonAlert(soon.first);

  final unknown = dues.where((d) => d.status == ItemStatus.unknown).length;
  if (unknown > 0) return UnknownItemsAlert(unknown);

  if (odometerDate != null) {
    final days = _days(odometerDate, today);
    if (days > staleMileageDays) return StaleMileageAlert(days);
  }
  return const AllGoodAlert();
}

/// The "Next service" stat card (spec S-09 "Next service value variants").
sealed class NextService {
  const NextService();
}

/// Nothing known yet: "—" and "Set up your schedule" (BR-MNT-11).
final class NoScheduleYet extends NextService {
  const NoScheduleYet();
}

/// The most overdue item: "5 · Days overdue".
final class NextServiceOverdue extends NextService {
  const NextServiceOverdue({required this.days, required this.itemCount});

  final int days;

  /// All overdue items.
  final int itemCount;
}

/// The next due date: "38 · Days away", or "Today".
final class NextServiceOn extends NextService {
  const NextServiceOn({required this.date, required this.days, required this.itemCount});

  final DateTime date;

  /// 0 means today.
  final int days;

  /// Items due on that date.
  final int itemCount;
}

/// Known items only have a due mileage and no prediction: "4,680 · km away".
final class NextServiceInKm extends NextService {
  const NextServiceInKm({required this.km, required this.itemCount});

  final int km;
  final int itemCount;
}

NextService computeNextService(List<ItemDue> dues, {required DateTime today}) {
  final known = dues.where((d) => d.status != ItemStatus.unknown && d.status != ItemStatus.notApplicable).toList();
  if (known.isEmpty) return const NoScheduleYet();

  final overdue = known.where((d) => d.status == ItemStatus.overdue).toList();
  if (overdue.isNotEmpty) {
    final days = overdue.map((d) => d.daysOverdue).reduce((a, b) => a > b ? a : b);
    return NextServiceOverdue(days: days, itemCount: overdue.length);
  }

  final dated = known.where((d) => d.effectiveDueDate != null).toList();
  if (dated.isNotEmpty) {
    final soonest = dated.map((d) => d.daysUntil(today)!).reduce((a, b) => a < b ? a : b);
    final group = dated.where((d) => d.daysUntil(today) == soonest).toList();
    return NextServiceOn(date: group.first.effectiveDueDate!, days: soonest, itemCount: group.length);
  }

  final km = known.map((d) => d.kmRemaining!).reduce((a, b) => a < b ? a : b);
  return NextServiceInKm(km: km, itemCount: known.where((d) => d.kmRemaining == km).length);
}

/// The next items by due point, for the tablet "Upcoming" list.
List<ItemDue> upcomingItems(List<ItemDue> dues, {required DateTime today, int count = 4}) {
  int rank(ItemDue d) => switch (d.status) {
    ItemStatus.overdue => -100000 - d.daysOverdue,
    ItemStatus.dueSoon || ItemStatus.ok => d.daysUntil(today) ?? (d.kmRemaining ?? 1 << 20),
    ItemStatus.unknown || ItemStatus.notApplicable => 1 << 30,
  };
  final known = dues.where((d) => d.status != ItemStatus.unknown && d.status != ItemStatus.notApplicable).toList()
    ..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0 ? byRank : a.item.severity.index.compareTo(b.item.severity.index);
    });
  return known.take(count).toList();
}

/// Items due within this many days of the next service date are done
/// together (spec S-18 item 2).
const nextServiceWindowDays = 30;

/// What the "Next service" sheet shows (spec S-18, US-13).
@immutable
class NextServiceGroup {
  const NextServiceGroup({required this.items, this.date, this.daysAway, this.kmAway, this.overdueDays});

  /// Overdue items first (most severe, then most overdue), then the rest
  /// by due date. Empty when nothing is known yet.
  final List<ItemDue> items;

  /// The next due date (`null` when overdue or mileage-only).
  final DateTime? date;
  final int? daysAway;

  /// Distance to the next due mileage when no item has a date.
  final int? kmAway;

  /// The most overdue item's days overdue; `null` when nothing is overdue.
  final int? overdueDays;

  bool get overdue => overdueDays != null;
}

/// The items to do at the next service (spec S-18): everything overdue,
/// plus everything due within [nextServiceWindowDays] of the next due date
/// (of today when something is overdue). Mileage-only items without a
/// prediction join when they are due soon.
NextServiceGroup nextServiceGroup(List<ItemDue> dues, {required DateTime today}) {
  final day = DateTime(today.year, today.month, today.day);
  final known = dues.where((d) => d.status != ItemStatus.unknown && d.status != ItemStatus.notApplicable).toList();
  final overdue = known.where((d) => d.status == ItemStatus.overdue).toList()
    ..sort((a, b) {
      final bySeverity = a.item.severity.index.compareTo(b.item.severity.index);
      return bySeverity != 0 ? bySeverity : b.daysOverdue.compareTo(a.daysOverdue);
    });
  final pending = known.where((d) => d.status != ItemStatus.overdue).toList();
  final dated = pending.where((d) => d.effectiveDueDate != null).toList()
    ..sort((a, b) {
      final byDate = a.effectiveDueDate!.compareTo(b.effectiveDueDate!);
      return byDate != 0 ? byDate : a.item.severity.index.compareTo(b.item.severity.index);
    });
  final kmOnly = pending.where((d) => d.effectiveDueDate == null && d.kmRemaining != null).toList()
    ..sort((a, b) => a.kmRemaining!.compareTo(b.kmRemaining!));

  final anchor = overdue.isNotEmpty ? day : dated.firstOrNull?.effectiveDueDate;
  final inWindow = anchor == null
      ? <ItemDue>[]
      : dated
            .where((d) => !d.effectiveDueDate!.isAfter(anchor.add(const Duration(days: nextServiceWindowDays))))
            .toList();
  final soonByKm = kmOnly.where((d) => d.status == ItemStatus.dueSoon).toList();

  if (overdue.isNotEmpty) {
    return NextServiceGroup(
      items: List.unmodifiable([...overdue, ...inWindow, ...soonByKm]),
      overdueDays: overdue.map((d) => d.daysOverdue).reduce((a, b) => a > b ? a : b),
    );
  }
  if (anchor != null) {
    return NextServiceGroup(
      items: List.unmodifiable([...inWindow, ...soonByKm]),
      date: anchor,
      daysAway: DateTime.utc(
        anchor.year,
        anchor.month,
        anchor.day,
      ).difference(DateTime.utc(day.year, day.month, day.day)).inDays,
    );
  }
  if (kmOnly.isNotEmpty) {
    final nearest = kmOnly.first.kmRemaining!;
    // Mileage-only: the nearest item and any due soon with it.
    final group = kmOnly.where((d) => d.kmRemaining == nearest || d.status == ItemStatus.dueSoon).toList();
    return NextServiceGroup(items: List.unmodifiable(group), kmAway: nearest);
  }
  return const NextServiceGroup(items: []);
}
