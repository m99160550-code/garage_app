import '../../maintenance/domain/schedule_item.dart';
import 'service_record.dart';

/// The items whose last-done values came from [record] (they change if it
/// is deleted, BR-SVC-04).
List<ScheduleItem> itemsSetBy(ServiceRecord record, List<ScheduleItem> schedule) =>
    schedule.where((i) => i.lastDoneRecordId == record.id).toList();

/// The items to save after deleting [record] (BR-SVC-04). Each item it had
/// set falls back to the next most recent record that covers it, then to
/// its baseline, then to Unknown. A reschedule for the old cycle ends.
/// Items it didn't set are unchanged and not returned.
List<ScheduleItem> itemsAfterDeleting(
  ServiceRecord record, {
  required List<ScheduleItem> schedule,
  required List<ServiceRecord> remaining,
}) => [
  for (final item in itemsSetBy(record, schedule))
    switch (_latestCovering(item.code, remaining.where((r) => r.id != record.id))) {
      final ServiceRecord previous => item.copyWith(
        clearLastDone: true,
        lastDoneDate: previous.date,
        lastDoneKm: previous.odometerKm,
        lastDoneSource: LastDoneSource.service,
        lastDoneRecordId: previous.id,
        clearReschedule: true,
      ),
      null when item.baselineDate != null || item.baselineKm != null => item.copyWith(
        clearLastDone: true,
        lastDoneDate: item.baselineDate,
        lastDoneKm: item.baselineKm,
        lastDoneSource: LastDoneSource.baseline,
        clearReschedule: true,
      ),
      null => item.copyWith(clearLastDone: true, clearReschedule: true),
    },
];

ServiceRecord? _latestCovering(String code, Iterable<ServiceRecord> records) {
  final covering = records.where((r) => r.itemCodes.contains(code)).toList()
    ..sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
    });
  return covering.firstOrNull;
}
