import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../garage/application/current_vehicle_controller.dart';
import '../../maintenance/application/maintenance_providers.dart';
import '../../mileage/domain/odometer_reading.dart';
import '../../privacy/application/consent_providers.dart';
import '../../reference/application/reference_providers.dart';
import '../../service_history/application/service_history_providers.dart';
import '../../settings/application/preferences_providers.dart';
import '../../settings/domain/distance_unit.dart';
import '../domain/vehicle.dart';
import '../domain/vehicle_details.dart';
import '../domain/vehicle_draft.dart';
import '../domain/vehicle_edit.dart';
import 'garage_providers.dart';

/// What S-32 Edit vehicle needs.
@immutable
class EditVehicleData {
  const EditVehicleData({required this.vehicle, required this.others, required this.unit, required this.recordCount});

  final Vehicle vehicle;

  /// The rest of the garage, for the duplicate-VIN warning (BR-VEH-03).
  final List<Vehicle> others;
  final DistanceUnit unit;

  /// Service records deleted with the vehicle ("…and 7 service records").
  final int recordCount;
}

/// `null` when the vehicle no longer exists.
final editVehicleDataProvider = FutureProvider.autoDispose.family<EditVehicleData?, String>((ref, vehicleId) async {
  // Watch everything before the first await (Riverpod 3).
  ref.watch(garageRevisionProvider);
  final garage = ref.watch(garageRepositoryProvider);
  final preferences = ref.watch(preferencesRepositoryProvider);
  final records = ref.watch(serviceRecordRepositoryProvider);

  final vehicles = await garage.vehicles();
  final vehicle = vehicles.where((v) => v.id == vehicleId).firstOrNull;
  if (vehicle == null) return null;
  return EditVehicleData(
    vehicle: vehicle,
    others: [
      for (final v in vehicles)
        if (v.id != vehicleId) v,
    ],
    unit: (await preferences.load()).distanceUnit,
    recordCount: (await records.records(vehicleId)).length,
  );
});

/// Brand and model names for the S-32 rows, in the UI language. Typed
/// "Other" names are shown as entered.
typedef VehicleIdentityKey = ({
  String? brandId,
  String? brandOtherName,
  String? modelId,
  String? modelOtherName,
  String languageCode,
});

VehicleIdentityKey identityKey(VehicleDraft draft, String languageCode) => (
  brandId: draft.brandId,
  brandOtherName: draft.brandOtherName,
  modelId: draft.modelId,
  modelOtherName: draft.modelOtherName,
  languageCode: languageCode,
);

final vehicleIdentityNamesProvider = FutureProvider.autoDispose
    .family<({String brand, String model}), VehicleIdentityKey>((ref, key) async {
      final reference = ref.watch(referenceRepositoryProvider);
      final brands = await ref.watch(brandsProvider.future);
      final brand = brands.where((b) => b.id == key.brandId).firstOrNull;
      final model = brand == null || key.modelId == null
          ? null
          : (await reference.models(brand.id)).where((m) => m.id == key.modelId).firstOrNull;
      return (
        brand: brand?.name(key.languageCode) ?? key.brandOtherName ?? '',
        model: model?.name(key.languageCode) ?? key.modelOtherName ?? '',
      );
    });

/// S-32 actions.
class VehicleEditor {
  VehicleEditor(this._ref);

  final Ref _ref;

  /// Saves the edit (FR-VEH-11). A new fuel type with "Update schedule"
  /// regenerates the template items (BR-MNT-08). A higher odometer becomes
  /// a new reading.
  Future<void> save(
    EditVehicleData data, {
    required VehicleDetails details,
    VehicleDraft? identity,
    FuelChangeChoice? fuelChange,
  }) async {
    final garage = _ref.read(garageRepositoryProvider);
    final vehicle = data.vehicle;
    final today = _ref.read(clockProvider)();

    if (details.fuelType != vehicle.fuelType && (fuelChange?.updateSchedule ?? false)) {
      final template = await _ref.read(templateRepositoryProvider).currentFor(details.fuelType);
      final schedule = scheduleForFuelChange(
        vehicleId: vehicle.id,
        schedule: await garage.schedule(vehicle.id),
        template: template,
        keepEditedIntervals: fuelChange!.keepEditedIntervals,
      );
      await garage.updateVehicle(
        editedVehicle(vehicle, details, identity: identity, templateVersion: template.version),
      );
      await garage.applyTemplateUpdate(vehicle.id, template.version, schedule);
    } else {
      await garage.updateVehicle(editedVehicle(vehicle, details, identity: identity));
    }

    if (details.odometerKm > vehicle.odometerKm) {
      await garage.addReading(OdometerReading(id: '', vehicleId: vehicle.id, date: today, km: details.odometerKm));
    }
    _ref.read(garageRevisionProvider.notifier).bump();
    _ref.invalidate(garageVehiclesProvider);
  }

  /// Deletes the vehicle, its schedule and its records (FR-VEH-12).
  /// Returns the vehicle shown next, or `null` when the garage is empty
  /// (BR-VEH-06: back to brand selection).
  Future<String?> delete(String vehicleId) => _ref.read(currentVehicleProvider.notifier).delete(vehicleId);
}

final vehicleEditorProvider = Provider<VehicleEditor>(VehicleEditor.new);
