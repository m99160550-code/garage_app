import 'package:flutter/foundation.dart';

import 'maintenance_template.dart';
import 'schedule_item.dart';

/// One item that differs between the vehicle's template version and the
/// latest one (FR-REF-06, spec S-17 item 2).
@immutable
class TemplateItemChange {
  const TemplateItemChange({required this.before, required this.after, required this.kept});

  /// The item in the vehicle's version; `null` for an item new in [after].
  final TemplateItem? before;
  final TemplateItem after;

  /// The user edited this item, so Apply leaves it alone (BR-REF-02).
  final bool kept;

  String get code => after.code;
  bool get isNew => before == null;
  bool get monthsChanged => before != null && before!.intervalMonths != after.intervalMonths;
  bool get kmChanged => before != null && before!.intervalKm != after.intervalKm;
  bool get severityChanged => before != null && before!.severity != after.severity;
}

/// A newer template is available for a vehicle (FR-REF-06).
@immutable
class TemplateUpdate {
  const TemplateUpdate({required this.vehicleId, required this.from, required this.to, required this.changes});

  final String vehicleId;
  final MaintenanceTemplate from;
  final MaintenanceTemplate to;
  final List<TemplateItemChange> changes;

  /// Changes Apply will make (not the kept ones).
  int get applicableCount => changes.where((c) => !c.kept).length;
}

/// The items whose interval, severity or presence changed between [from]
/// and [to]. Wording-only changes don't count (BR-REF-08). Items removed
/// from the template stay on the vehicle, with their history, so they are
/// not listed.
List<TemplateItemChange> templateChanges({
  required List<ScheduleItem> schedule,
  required MaintenanceTemplate from,
  required MaintenanceTemplate to,
}) {
  final byCode = {for (final item in schedule) item.code: item};
  final changes = <TemplateItemChange>[];
  for (final after in to.items) {
    final current = byCode[after.code];
    final before = from.item(after.code);
    if (current == null) {
      changes.add(TemplateItemChange(before: null, after: after, kept: false));
      continue;
    }
    if (before == null) continue; // Already on the vehicle (never expected).
    final differs =
        before.intervalMonths != after.intervalMonths ||
        before.intervalKm != after.intervalKm ||
        before.severity != after.severity;
    if (differs) changes.add(TemplateItemChange(before: before, after: after, kept: current.intervalEdited));
  }
  return changes;
}

/// The schedule after "Apply" (BR-REF-02): unedited items take the new
/// intervals and severity; edited items, not-applicable flags, last-done
/// values and custom items are kept; new template items are added as
/// Unknown.
List<ScheduleItem> applyTemplateChanges({
  required String vehicleId,
  required List<ScheduleItem> schedule,
  required List<TemplateItemChange> changes,
}) {
  final byCode = {for (final c in changes) c.code: c};
  final updated = [
    for (final item in schedule)
      switch (byCode[item.code]) {
        final TemplateItemChange c when !c.kept && !item.isCustom => item.copyWith(
          severity: c.after.severity,
          intervalMonths: c.after.intervalMonths,
          clearIntervalMonths: c.after.intervalMonths == null,
          intervalKm: c.after.intervalKm,
          clearIntervalKm: c.after.intervalKm == null,
          intervalEdited: false,
        ),
        _ => item,
      },
  ];
  for (final c in changes.where((c) => c.isNew)) {
    updated.add(
      ScheduleItem(
        id: '$vehicleId-${c.code}',
        vehicleId: vehicleId,
        code: c.code,
        nameEn: c.after.nameEn,
        nameAr: c.after.nameAr,
        severity: c.after.severity,
        intervalMonths: c.after.intervalMonths,
        intervalKm: c.after.intervalKm,
      ),
    );
  }
  return updated;
}
