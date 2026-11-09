import '../../maintenance/domain/maintenance_template.dart';
import '../../maintenance/domain/schedule_item.dart';
import 'vehicle.dart';
import 'vehicle_details.dart';
import 'vehicle_draft.dart';

/// What the user chose in "Update the schedule for EV?" (BR-MNT-08).
typedef FuelChangeChoice = ({bool updateSchedule, bool keepEditedIntervals});

/// The schedule after a fuel change with "Update schedule" (BR-MNT-08):
///
/// * Items of the new fuel's template take its intervals and severity,
///   except edited intervals when [keepEditedIntervals]. Last-done values,
///   snoozes and "not applicable" stay.
/// * Template items the new fuel doesn't have (engine oil on an EV) leave
///   the schedule; their service records stay in the history.
/// * Items new to this fuel are added as Unknown.
/// * Custom items are kept.
List<ScheduleItem> scheduleForFuelChange({
  required String vehicleId,
  required List<ScheduleItem> schedule,
  required MaintenanceTemplate template,
  required bool keepEditedIntervals,
}) {
  final result = <ScheduleItem>[];
  for (final item in schedule) {
    if (item.isCustom) {
      result.add(item);
      continue;
    }
    final next = template.item(item.code);
    if (next == null) continue;
    if (keepEditedIntervals && item.intervalEdited) {
      result.add(item.copyWith(severity: next.severity, nameEn: next.nameEn, nameAr: next.nameAr));
      continue;
    }
    result.add(
      item.copyWith(
        nameEn: next.nameEn,
        nameAr: next.nameAr,
        severity: next.severity,
        intervalMonths: next.intervalMonths,
        clearIntervalMonths: next.intervalMonths == null,
        intervalKm: next.intervalKm,
        clearIntervalKm: next.intervalKm == null,
        intervalEdited: false,
      ),
    );
  }
  final present = {for (final item in result) item.code};
  for (final t in template.items.where((t) => !present.contains(t.code))) {
    result.add(
      ScheduleItem(
        id: '$vehicleId-${t.code}',
        vehicleId: vehicleId,
        code: t.code,
        nameEn: t.nameEn,
        nameAr: t.nameAr,
        severity: t.severity,
        intervalMonths: t.intervalMonths,
        intervalKm: t.intervalKm,
      ),
    );
  }
  return result;
}

/// [vehicle] with the edited answers (S-32). The odometer is not changed
/// here: a higher value becomes a new reading (BR-MIL-01). [identity]
/// carries a new brand and model when the user picked them.
Vehicle editedVehicle(Vehicle vehicle, VehicleDetails details, {VehicleDraft? identity, int? templateVersion}) {
  final newIdentity = identity != null && identity.hasBrand && identity.hasModel;
  return Vehicle(
    id: vehicle.id,
    brandId: newIdentity ? identity.brandId : vehicle.brandId,
    brandOtherName: newIdentity ? identity.brandOtherName : vehicle.brandOtherName,
    modelId: newIdentity ? identity.modelId : vehicle.modelId,
    modelOtherName: newIdentity ? identity.modelOtherName : vehicle.modelOtherName,
    nickname: details.nickname,
    year: details.year,
    fuelType: details.fuelType,
    bodyType: details.bodyType,
    paint: details.paint,
    vin: details.vin,
    licencePlate: details.licencePlate,
    purchaseDate: details.purchaseDate,
    odometerKm: vehicle.odometerKm,
    odometerUpdatedAt: vehicle.odometerUpdatedAt,
    setupMode: vehicle.setupMode,
    templateVersion: templateVersion ?? vehicle.templateVersion,
  );
}

/// The vehicle's saved answers, to fill the S-32 form.
VehicleDetails detailsOf(Vehicle vehicle) => VehicleDetails(
  fuelType: vehicle.fuelType,
  odometerKm: vehicle.odometerKm,
  paint: vehicle.paint,
  bodyType: vehicle.bodyType,
  nickname: vehicle.nickname,
  year: vehicle.year,
  licencePlate: vehicle.licencePlate,
  vin: vehicle.vin,
  purchaseDate: vehicle.purchaseDate,
);

/// The draft that S-04 and S-05 edit, starting from the vehicle's brand
/// and model.
VehicleDraft draftOf(Vehicle vehicle) => VehicleDraft(
  brandId: vehicle.brandId,
  brandOtherName: vehicle.brandOtherName,
  modelId: vehicle.modelId,
  modelOtherName: vehicle.modelOtherName,
  bodyType: vehicle.bodyType,
);
