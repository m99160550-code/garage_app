import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../privacy/application/consent_providers.dart';
import '../../vehicles/application/garage_providers.dart';
import '../../vehicles/domain/fuel_type.dart';
import '../domain/schedule_item.dart';
import 'maintenance_providers.dart';

/// The actions on S-15 (FR-MNT-05, FR-MNT-06, FR-MNT-10). Each saves the
/// item and refreshes every screen that shows the garage.
class ScheduleItemActions {
  ScheduleItemActions(this._ref);

  final Ref _ref;

  DateTime get _today {
    final now = _ref.read(clockProvider)();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _save(ScheduleItem item) async {
    await _ref.read(garageRepositoryProvider).updateScheduleItem(item);
    _ref.read(garageRevisionProvider.notifier).bump();
  }

  /// Pauses reminders (and a due-soon deduction) for [days] (BR-HLT-05,
  /// BR-NOT-06). Returns the end date.
  Future<DateTime> snooze(ScheduleItem item, int days) async {
    final until = _today.add(Duration(days: days));
    await _save(item.copyWith(snoozedUntil: until));
    return until;
  }

  Future<void> undoSnooze(ScheduleItem item) => _save(item.copyWith(clearSnooze: true));

  /// Moves the due date for this cycle only (BR-MNT-06).
  Future<void> reschedule(ScheduleItem item, DateTime date) => _save(item.copyWith(rescheduledDueDate: date));

  /// "Not applicable to my car" (FR-MNT-05).
  Future<void> setNotApplicable(ScheduleItem item, bool value) => _save(item.copyWith(notApplicable: value));

  /// "Set last done" for an Unknown item. Starts a new cycle, so any
  /// reschedule or snooze ends.
  Future<void> setLastDone(ScheduleItem item, {DateTime? date, int? km}) => _save(
    item.copyWith(
      lastDoneDate: date,
      lastDoneKm: km,
      lastDoneSource: LastDoneSource.manual,
      clearReschedule: true,
      clearSnooze: true,
    ),
  );

  /// "Reset to typical" restores the intervals of the vehicle's template
  /// version (FR-MNT-06).
  Future<void> resetToTypical(ScheduleItem item, FuelType fuelType, int templateVersion) async {
    final template = await _ref.read(templateRepositoryProvider).versionFor(fuelType, templateVersion);
    final typical = template.items.where((t) => t.code == item.code).firstOrNull;
    if (typical == null) return;
    await _save(
      item.copyWith(
        severity: typical.severity,
        intervalMonths: typical.intervalMonths,
        clearIntervalMonths: typical.intervalMonths == null,
        intervalKm: typical.intervalKm,
        clearIntervalKm: typical.intervalKm == null,
        intervalEdited: false,
      ),
    );
  }

  /// Deletes a custom item (FR-MNT-05).
  Future<void> delete(ScheduleItem item) async {
    await _ref.read(garageRepositoryProvider).deleteScheduleItem(item.vehicleId, item.id);
    _ref.read(garageRevisionProvider.notifier).bump();
  }
}

final scheduleItemActionsProvider = Provider<ScheduleItemActions>(ScheduleItemActions.new);
