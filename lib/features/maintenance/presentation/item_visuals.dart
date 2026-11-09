import 'package:flutter/material.dart';

import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/status_badge.dart';
import '../../onboarding/presentation/country/country_labels.dart';
import '../../settings/domain/distance_unit.dart';
import '../../vehicles/domain/vehicle_validation.dart';
import '../domain/item_due.dart';
import '../domain/severity.dart';

/// The icon of a schedule item, by its template code.
IconData scheduleItemIcon(String code) => switch (code) {
  'engine_oil' => Icons.oil_barrel_outlined,
  'oil_filter' || 'air_filter' || 'fuel_filter' => Icons.filter_alt_outlined,
  'cabin_filter' => Icons.air,
  'brake_pads' => Icons.album_outlined,
  'brake_fluid' => Icons.water_drop_outlined,
  'tire_rotation' => Icons.tire_repair_outlined,
  'coolant' => Icons.thermostat_outlined,
  'battery' => Icons.battery_charging_full_outlined,
  'wipers' => Icons.cleaning_services_outlined,
  'timing_belt' => Icons.settings_outlined,
  'inspection' => Icons.fact_check_outlined,
  _ => Icons.build_outlined,
};

/// The status badge of an item (spec 1.7 "Status badge").
(String, BadgeTone, IconData) scheduleStatusBadge(AppLocalizations l10n, ItemDue due) => switch (due.status) {
  ItemStatus.overdue => (l10n.statusOverdue, BadgeTone.danger, Icons.error_outline),
  ItemStatus.dueSoon when due.snoozed => (l10n.scheduleSnoozed, BadgeTone.neutral, Icons.snooze),
  ItemStatus.dueSoon => (l10n.statusDueSoon, BadgeTone.warning, Icons.schedule),
  ItemStatus.ok => (l10n.statusOk, BadgeTone.success, Icons.check),
  ItemStatus.unknown => (l10n.baselineUnknownBadge, BadgeTone.info, Icons.help_outline),
  ItemStatus.notApplicable => (l10n.scheduleNotApplicable, BadgeTone.neutral, Icons.block),
};

/// The due line of an item (spec S-14 item 5): "Due 17 Nov or at
/// 59,800 km", "Overdue by 12 days", "Unknown: set last done",
/// "Snoozed until 20 Nov".
String scheduleDueText(AppLocalizations l10n, ItemDue due, {required DistanceUnit unit, required String languageCode}) {
  final dates = AppFormatters(languageCode: languageCode);
  String distance(int km) =>
      '${const AppFormatters(languageCode: 'en').formatOdometer(fromKilometres(km, unit))} ${distanceUnitLabel(l10n, unit)}';

  switch (due.status) {
    case ItemStatus.notApplicable:
      return l10n.scheduleNotApplicable;
    case ItemStatus.unknown:
      return l10n.healthUnknownSetLastDone;
    case ItemStatus.overdue:
      return due.overdueByDate || due.kmOverdue == 0
          ? l10n.upcomingOverdueDays(due.daysOverdue)
          : l10n.healthReasonOverdueKm(distance(due.kmOverdue));
    case ItemStatus.dueSoon when due.snoozed:
      return l10n.healthSnoozedUntil(dates.shortDate(due.item.snoozedUntil!));
    case ItemStatus.dueSoon || ItemStatus.ok:
      final date = due.nextDueDate;
      final km = due.nextDueKm;
      if (date != null && km != null) return l10n.scheduleDueDateOrKm(dates.shortDate(date), distance(km));
      if (date != null) return l10n.scheduleDueDate(dates.shortDate(date));
      return l10n.scheduleDueKm(distance(km!));
  }
}

/// "Critical", "Major", "Minor" (BR-HLT-01).
String severityLabel(AppLocalizations l10n, Severity severity) => switch (severity) {
  Severity.critical => l10n.severityCritical,
  Severity.major => l10n.severityMajor,
  Severity.minor => l10n.severityMinor,
};

/// "15,000 km" in the user's unit, Western digits, non-breaking space.
String scheduleDistance(AppLocalizations l10n, int km, DistanceUnit unit) =>
    '${const AppFormatters(languageCode: 'en').formatOdometer(fromKilometres(km, unit))}\u00A0'
    '${distanceUnitLabel(l10n, unit)}';

/// "Every 12 months or 15,000 km" (either part may be missing).
String scheduleIntervalText(AppLocalizations l10n, {int? months, int? km, required DistanceUnit unit}) {
  final parts = [if (months != null) l10n.itemMonths(months), if (km != null) scheduleDistance(l10n, km, unit)];
  return l10n.itemEvery(parts.length == 2 ? l10n.itemOr(parts[0], parts[1]) : parts.join());
}
