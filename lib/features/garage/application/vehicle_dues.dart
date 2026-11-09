import '../../maintenance/domain/item_due.dart';
import '../../maintenance/domain/schedule_item.dart';
import '../../mileage/domain/mileage_rules.dart';
import '../../mileage/domain/odometer_reading.dart';
import '../../settings/domain/distance_unit.dart';
import '../../vehicles/domain/vehicle.dart';

/// Where each of a vehicle's schedule items stands today. Shared by the
/// dashboard (S-09) and the vehicle switcher (S-10).
List<ItemDue> vehicleDues(
  Vehicle vehicle,
  List<ScheduleItem> schedule, {
  required List<OdometerReading> readings,
  required DistanceUnit unit,
  required DateTime today,
}) {
  final dailyKm = averageDailyKm(readings, today: today);
  return [
    for (final item in schedule)
      computeItemDue(
        item,
        currentKm: vehicle.odometerKm,
        today: today,
        unit: unit,
        odometerDate: vehicle.odometerUpdatedAt,
        // From the mileage history; `null` means no prediction (BR-MIL-05).
        dailyKm: dailyKm,
      ),
  ];
}
