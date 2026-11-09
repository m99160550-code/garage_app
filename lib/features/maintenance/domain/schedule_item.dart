import 'package:flutter/foundation.dart';

import 'severity.dart';

/// Where an item's last-done values came from (architecture 2.8).
enum LastDoneSource { baseline, newCar, service, manual }

/// One item of a vehicle's maintenance schedule (architecture 2.8
/// `schedule_items`). Due dates, status and score are derived from it by
/// the rules engine and are not stored here.
@immutable
class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.vehicleId,
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.severity,
    this.intervalMonths,
    this.intervalKm,
    this.lastDoneDate,
    this.lastDoneKm,
    this.lastDoneSource,
    this.snoozedUntil,
    this.notApplicable = false,
    this.rescheduledDueDate,
    this.intervalEdited = false,
    this.isCustom = false,
    this.lastDoneRecordId,
    this.baselineDate,
    this.baselineKm,
  });

  final String id;
  final String vehicleId;
  final String code;
  final String nameEn;
  final String nameAr;
  final Severity severity;
  final int? intervalMonths;
  final int? intervalKm;
  final DateTime? lastDoneDate;
  final int? lastDoneKm;
  final LastDoneSource? lastDoneSource;

  /// Reminders and the due-soon deduction pause until this date
  /// (BR-HLT-05, BR-MNT-06). Never pauses an overdue deduction.
  final DateTime? snoozedUntil;

  /// Marked "Not applicable to my car" (FR-MNT-05): hidden from the score
  /// and reminders (BR-HLT-03).
  final bool notApplicable;

  /// A due date chosen by the user for the current cycle only
  /// (BR-MNT-06). Cleared when the item is done again.
  final DateTime? rescheduledDueDate;

  /// The intervals differ from the template (shows "Edited", allows
  /// "Reset to typical", FR-MNT-06).
  final bool intervalEdited;

  /// Added by the user (FR-MNT-05); can be deleted.
  final bool isCustom;

  /// The service record that set the last-done values, if any. Deleting or
  /// editing that record makes the item fall back (BR-SVC-04).
  final String? lastDoneRecordId;

  /// The setup answer (baseline or new-car delivery), kept for the
  /// BR-SVC-04 fallback (architecture 2.8 `baseline_date`, `baseline_km`).
  final DateTime? baselineDate;
  final int? baselineKm;

  /// No baseline yet: the item doesn't count towards the score and shows
  /// "Set last done" (FR-MNT-04, BR-HLT-03).
  bool get isUnknown => lastDoneDate == null && lastDoneKm == null;

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  /// A copy with some fields changed. The `clear…` flags set a nullable
  /// field back to `null`.
  ScheduleItem copyWith({
    String? nameEn,
    String? nameAr,
    Severity? severity,
    int? intervalMonths,
    bool clearIntervalMonths = false,
    int? intervalKm,
    bool clearIntervalKm = false,
    DateTime? lastDoneDate,
    int? lastDoneKm,
    LastDoneSource? lastDoneSource,
    DateTime? snoozedUntil,
    bool clearSnooze = false,
    bool? notApplicable,
    DateTime? rescheduledDueDate,
    bool clearReschedule = false,
    bool? intervalEdited,
    String? lastDoneRecordId,
    bool clearLastDone = false,
    bool clearBaseline = false,
  }) => ScheduleItem(
    id: id,
    vehicleId: vehicleId,
    code: code,
    nameEn: nameEn ?? this.nameEn,
    nameAr: nameAr ?? this.nameAr,
    severity: severity ?? this.severity,
    intervalMonths: clearIntervalMonths ? null : (intervalMonths ?? this.intervalMonths),
    intervalKm: clearIntervalKm ? null : (intervalKm ?? this.intervalKm),
    // `clearLastDone` empties the last-done values first; new ones given
    // in the same call are then used (a fallback, BR-SVC-04).
    lastDoneDate: lastDoneDate ?? (clearLastDone ? null : this.lastDoneDate),
    lastDoneKm: lastDoneKm ?? (clearLastDone ? null : this.lastDoneKm),
    lastDoneSource: lastDoneSource ?? (clearLastDone ? null : this.lastDoneSource),
    snoozedUntil: clearSnooze ? null : (snoozedUntil ?? this.snoozedUntil),
    notApplicable: notApplicable ?? this.notApplicable,
    rescheduledDueDate: clearReschedule ? null : (rescheduledDueDate ?? this.rescheduledDueDate),
    intervalEdited: intervalEdited ?? this.intervalEdited,
    isCustom: isCustom,
    lastDoneRecordId: lastDoneRecordId ?? (clearLastDone ? null : this.lastDoneRecordId),
    baselineDate: clearBaseline ? null : baselineDate,
    baselineKm: clearBaseline ? null : baselineKm,
  );
}
