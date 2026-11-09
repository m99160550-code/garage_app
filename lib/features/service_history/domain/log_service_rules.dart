import '../../../core/format/app_formatters.dart';
import '../../maintenance/domain/item_due.dart';
import '../../maintenance/domain/schedule_item.dart';
import 'record_rules.dart';
import 'service_record.dart';

/// What saving a record does to the schedule (FR-SVC-03).
typedef ScheduleChanges = ({List<ScheduleItem> updated, List<ScheduleItem> kept});

/// Resets the last-done values of the items [record] covers
/// (FR-SVC-03, BR-SVC-07: an Unknown item becomes known). An item whose
/// last done is newer than the record keeps it (BR-SVC-02), and is
/// returned in `kept` so the toast can say so.
ScheduleChanges applyRecord(ServiceRecord record, List<ScheduleItem> schedule) {
  final updated = <ScheduleItem>[];
  final kept = <ScheduleItem>[];
  for (final item in schedule.where((i) => record.itemCodes.contains(i.code))) {
    final last = item.lastDoneDate;
    if (last != null && record.date.isBefore(last)) {
      kept.add(item);
      continue;
    }
    updated.add(
      item.copyWith(
        clearLastDone: true,
        lastDoneDate: record.date,
        lastDoneKm: record.odometerKm,
        lastDoneSource: LastDoneSource.service,
        lastDoneRecordId: record.id,
        // A new cycle starts: the old reschedule and snooze end.
        clearReschedule: true,
        clearSnooze: true,
      ),
    );
  }
  return (updated: updated, kept: kept);
}

/// Editing [before] into [after] (FR-SVC-06, BR-SVC-04): the items
/// [before] had set fall back first, then [after] applies as if new.
/// Returns every changed item once, in its final state.
ScheduleChanges applyEdit(
  ServiceRecord before,
  ServiceRecord after, {
  required List<ScheduleItem> schedule,
  required List<ServiceRecord> otherRecords,
}) {
  final fallback = itemsAfterDeleting(before, schedule: schedule, remaining: otherRecords);
  final byId = {for (final item in schedule) item.id: item, for (final item in fallback) item.id: item};
  final applied = applyRecord(after, byId.values.toList());
  final changed = {for (final item in fallback) item.id: item, for (final item in applied.updated) item.id: item};
  return (updated: changed.values.toList(), kept: applied.kept);
}

/// The item chips (spec S-22 item 4): everything except Not applicable,
/// preselected first, then overdue, due soon, and the rest in schedule
/// order.
List<ItemDue> chipOrder(List<ItemDue> dues, Set<String> preselected) {
  int rank(ItemDue d) {
    if (preselected.contains(d.item.code)) return 0;
    return switch (d.status) {
      ItemStatus.overdue => 1,
      ItemStatus.dueSoon => 2,
      _ => 3,
    };
  }

  final indexed =
      [
        for (final (i, d) in dues.indexed)
          if (d.status != ItemStatus.notApplicable) (i, d),
      ]..sort((a, b) {
        final byRank = rank(a.$2).compareTo(rank(b.$2));
        return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
      });
  return [for (final (_, d) in indexed) d];
}

/// Why a typed cost can't be saved.
enum CostIssue { notANumber, negative, tooManyDecimals }

/// Parses a cost typed in [currency] into the smallest unit (AD-07).
/// Empty is fine (`null` cost, BR-SVC-05). Accepts "120", "120.5",
/// "1,200.50" and an Arabic decimal comma ("120٫5").
({int? minor, CostIssue? issue}) parseCost(String input, String currency) {
  final text = input.trim().replaceAll(',', '').replaceAll('٫', '.');
  if (text.isEmpty) return (minor: null, issue: null);
  if (text.startsWith('-')) return (minor: null, issue: CostIssue.negative);
  final match = RegExp(r'^(\d+)(?:\.(\d*))?$').firstMatch(text);
  if (match == null) return (minor: null, issue: CostIssue.notANumber);
  final places = AppFormatters.minorUnitsOf(currency);
  final decimals = match.group(2) ?? '';
  if (decimals.length > places) return (minor: null, issue: CostIssue.tooManyDecimals);
  final whole = int.parse(match.group(1)!);
  final fraction = decimals.isEmpty ? 0 : int.parse(decimals.padRight(places, '0'));
  var factor = 1;
  for (var i = 0; i < places; i++) {
    factor *= 10;
  }
  return (minor: whole * factor + fraction, issue: null);
}

/// The cost as the user would type it back ("120", "120.50").
String costText(int minor, String currency) {
  final places = AppFormatters.minorUnitsOf(currency);
  if (places == 0) return '$minor';
  var factor = 1;
  for (var i = 0; i < places; i++) {
    factor *= 10;
  }
  final fraction = minor % factor;
  return fraction == 0 ? '${minor ~/ factor}' : '${minor ~/ factor}.${'$fraction'.padLeft(places, '0')}';
}

/// Shop names used before, most recent first, without repeats (spec S-22
/// item 7).
List<String> shopSuggestions(List<ServiceRecord> records) {
  final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
  final seen = <String>{};
  return [
    for (final r in sorted)
      if (r.shopName case final shop? when shop.trim().isNotEmpty && seen.add(shop.trim().toLowerCase())) shop.trim(),
  ];
}
