import 'maintenance_template.dart';
import 'schedule_item.dart';
import 'vehicle_setup.dart';

/// Adds calendar months, clamping the day to the end of shorter months
/// (31 Jan + 1 month = 28 or 29 Feb).
DateTime addMonths(DateTime date, int months) {
  final monthIndex = date.month - 1 + months;
  final year = date.year + (monthIndex ~/ 12);
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, date.day > lastDay ? lastDay : date.day);
}

/// Builds a vehicle's schedule from its template and setup (FR-MNT-01,
/// FR-MNT-03, FR-MNT-04, FR-MNT-15).
///
/// * Baseline: items in an answered group take its date and mileage.
///   Every other item is Unknown.
/// * New car: every item starts from the delivery date and mileage.
List<ScheduleItem> generateSchedule({
  required String vehicleId,
  required MaintenanceTemplate template,
  required VehicleSetup setup,
}) {
  return [
    for (final item in template.items)
      () {
        DateTime? date;
        int? km;
        LastDoneSource? source;
        switch (setup) {
          case NewCarSetup(:final deliveryDate, :final startingKm):
            date = deliveryDate;
            km = startingKm;
            source = LastDoneSource.newCar;
          case BaselineSetup():
            final group = item.baselineGroup;
            final answer = group == null ? null : setup.answerFor(group);
            if (answer != null && !answer.isUnknown) {
              date = answer.date;
              km = answer.km;
              source = LastDoneSource.baseline;
            }
        }
        return ScheduleItem(
          id: '$vehicleId-${item.code}',
          vehicleId: vehicleId,
          code: item.code,
          nameEn: item.nameEn,
          nameAr: item.nameAr,
          severity: item.severity,
          intervalMonths: item.intervalMonths,
          intervalKm: item.intervalKm,
          lastDoneDate: date,
          lastDoneKm: km,
          lastDoneSource: source,
          // Kept for the fallback when a service record is deleted (BR-SVC-04).
          baselineDate: date,
          baselineKm: km,
        );
      }(),
  ];
}

/// Items that are already due on a new car because the delivery was longer
/// ago than their interval, by time or by distance driven since (BR-MNT-13).
/// A non-empty result means the user is warned before saving.
List<TemplateItem> itemsDueSinceDelivery({
  required MaintenanceTemplate template,
  required NewCarSetup setup,
  required int currentOdometerKm,
  required DateTime today,
}) {
  final day = DateTime(today.year, today.month, today.day);
  return [
    for (final item in template.items)
      if ((item.intervalMonths != null && !addMonths(setup.deliveryDate, item.intervalMonths!).isAfter(day)) ||
          (item.intervalKm != null && setup.startingKm + item.intervalKm! <= currentOdometerKm))
        item,
  ];
}

/// Whole months between two dates, for "3 years ago" / "8 months ago".
int monthsBetween(DateTime from, DateTime to) {
  var months = (to.year - from.year) * 12 + to.month - from.month;
  if (to.day < from.day) months--;
  return months < 0 ? 0 : months;
}
