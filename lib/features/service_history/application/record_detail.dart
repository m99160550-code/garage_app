import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../maintenance/domain/schedule_item.dart';
import '../../mileage/domain/odometer_reading.dart';
import '../../settings/application/preferences_providers.dart';
import '../../settings/domain/distance_unit.dart';
import '../../vehicles/application/garage_providers.dart';
import '../domain/record_rules.dart';
import '../domain/service_record.dart';
import 'log_service_controller.dart';
import 'service_history_providers.dart';

/// Everything S-21 shows for one record.
@immutable
class RecordDetail {
  const RecordDetail({
    required this.record,
    required this.itemNames,
    required this.itemsSetByRecord,
    required this.unit,
  });

  final ServiceRecord record;

  /// Schedule item names by code: (English, Arabic).
  final Map<String, (String, String)> itemNames;

  /// Items whose last-done values come from this record (the delete
  /// dialog names them, BR-SVC-04).
  final List<ScheduleItem> itemsSetByRecord;
  final DistanceUnit unit;
}

/// S-21 data, or `null` once the record is deleted.
final recordDetailProvider = FutureProvider.autoDispose.family<RecordDetail?, String>((ref, recordId) async {
  // Watch everything before the first await (Riverpod 3).
  ref.watch(garageRevisionProvider);
  final records = ref.watch(serviceRecordRepositoryProvider);
  final garage = ref.watch(garageRepositoryProvider);
  final preferences = ref.watch(preferencesRepositoryProvider);

  final record = await records.record(recordId);
  if (record == null) return null;
  final schedule = await garage.schedule(record.vehicleId);
  return RecordDetail(
    record: record,
    itemNames: {for (final item in schedule) item.code: (item.nameEn, item.nameAr)},
    itemsSetByRecord: itemsSetBy(record, schedule),
    unit: (await preferences.load()).distanceUnit,
  );
});

/// The records that covered one schedule item, newest first (S-15 item 7).
final itemRecordsProvider = FutureProvider.autoDispose.family<List<ServiceRecord>, (String, String)>((ref, key) async {
  final (vehicleId, code) = key;
  ref.watch(garageRevisionProvider);
  final records = ref.watch(serviceRecordRepositoryProvider);
  return (await records.records(vehicleId)).where((r) => r.itemCodes.contains(code)).toList();
});

/// A deletion that can still be undone.
@immutable
class DeletedRecord {
  const DeletedRecord({required this.record, required this.previousItems, this.reading});

  final ServiceRecord record;

  /// The odometer reading the record had added (BR-MIL-04).
  final OdometerReading? reading;

  /// The items as they were before the fallback.
  final List<ScheduleItem> previousItems;
}

/// Delete and undo on S-21 (FR-SVC-06, BR-SVC-04).
class ServiceRecordActions {
  ServiceRecordActions(this._ref);

  final Ref _ref;

  /// Deletes [record] and makes the items it had set fall back. Returns
  /// what "Undo" needs.
  Future<DeletedRecord> delete(ServiceRecord record) async {
    final records = _ref.read(serviceRecordRepositoryProvider);
    final garage = _ref.read(garageRepositoryProvider);
    final schedule = await garage.schedule(record.vehicleId);
    final updated = itemsAfterDeleting(record, schedule: schedule, remaining: await records.records(record.vehicleId));
    await records.delete(record.id);
    for (final item in updated) {
      await garage.updateScheduleItem(item);
    }
    // Its odometer reading goes too; the current odometer falls back
    // to the remaining readings (BR-MIL-01).
    final readingId = LogServiceActions.readingIdFor(record.id);
    final reading = (await garage.readings(record.vehicleId)).where((r) => r.id == readingId).firstOrNull;
    if (reading != null) await garage.deleteReading(record.vehicleId, readingId);
    _ref.read(garageRevisionProvider.notifier).bump();
    return DeletedRecord(record: record, previousItems: itemsSetBy(record, schedule), reading: reading);
  }

  /// Restores the record and the items exactly as they were.
  Future<void> undo(DeletedRecord deleted) async {
    final garage = _ref.read(garageRepositoryProvider);
    await _ref.read(serviceRecordRepositoryProvider).restore(deleted.record);
    for (final item in deleted.previousItems) {
      await garage.updateScheduleItem(item);
    }
    if (deleted.reading case final reading?) await garage.addReading(reading);
    _ref.read(garageRevisionProvider.notifier).bump();
  }
}

final serviceRecordActionsProvider = Provider<ServiceRecordActions>(ServiceRecordActions.new);
