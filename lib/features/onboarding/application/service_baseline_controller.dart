import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../garage/application/current_vehicle_controller.dart';
import '../../maintenance/application/maintenance_providers.dart';
import '../../maintenance/domain/maintenance_template.dart';
import '../../maintenance/domain/schedule_rules.dart';
import '../../maintenance/domain/vehicle_setup.dart';
import '../../privacy/application/consent_providers.dart';
import '../../session/application/session_providers.dart';
import '../../settings/application/preferences_providers.dart';
import '../../settings/domain/distance_unit.dart';
import '../../vehicles/application/garage_providers.dart';
import '../../vehicles/application/vehicle_draft_controller.dart';
import '../../vehicles/domain/vehicle.dart';
import '../../vehicles/domain/vehicle_draft.dart';

/// Everything S-07 needs (spec S-07).
@immutable
class ServiceBaselineSetup {
  const ServiceBaselineSetup({
    required this.hasDetails,
    this.unit = DistanceUnit.km,
    this.currentOdometerKm = 0,
    this.template,
  });

  /// False if setup resumed here without the S-06 answers.
  final bool hasDetails;

  /// The user's distance unit for every mileage field.
  final DistanceUnit unit;

  /// From S-06. No baseline mileage can be higher (UC-01 8b, BR-MNT-12).
  final int currentOdometerKm;

  /// The current template for the car's fuel type.
  final MaintenanceTemplate? template;
}

class ServiceBaselineController extends AsyncNotifier<ServiceBaselineSetup> {
  @override
  Future<ServiceBaselineSetup> build() async {
    final draft = ref.read(vehicleDraftProvider);
    final details = draft.details;
    if (!draft.hasBrand || !draft.hasModel || details == null) {
      return const ServiceBaselineSetup(hasDetails: false);
    }
    final preferences = await ref.read(preferencesRepositoryProvider).load();
    final template = await ref.read(templateRepositoryProvider).currentFor(details.fuelType);
    return ServiceBaselineSetup(
      hasDetails: true,
      unit: preferences.distanceUnit,
      currentOdometerKm: details.odometerKm,
      template: template,
    );
  }

  /// Items that are already due because the delivery date is old
  /// (BR-MNT-13). Empty means no warning is needed.
  int countItemsDueSinceDelivery(NewCarSetup setup) {
    final data = state.requireValue;
    return itemsDueSinceDelivery(
      template: data.template!,
      setup: setup,
      currentOdometerKm: data.currentOdometerKm,
      today: ref.read(clockProvider)(),
    ).length;
  }

  /// Saves the vehicle on the device with its schedule (UC-01 step 9), then
  /// clears the draft. Returns the new vehicle's id.
  Future<String> save(VehicleSetup setup) async {
    final data = state.requireValue;
    final draft = ref.read(vehicleDraftProvider);
    final vehicleId = 'veh-${ref.read(clockProvider)().microsecondsSinceEpoch}';
    final vehicle = _vehicleFrom(draft, vehicleId, setup, data.template!.version, ref.read(clockProvider)());
    final schedule = generateSchedule(vehicleId: vehicleId, template: data.template!, setup: setup);

    await ref.read(garageRepositoryProvider).addVehicle(vehicle, schedule);
    await ref.read(sessionRepositoryProvider).recordVehicleAdded(vehicleId);
    ref.read(vehicleDraftProvider.notifier).reset();
    ref
      ..invalidate(appSessionProvider)
      ..invalidate(garageVehiclesProvider);
    return vehicleId;
  }

  static Vehicle _vehicleFrom(VehicleDraft draft, String id, VehicleSetup setup, int templateVersion, DateTime now) {
    final details = draft.details!;
    final isNew = setup is NewCarSetup;
    return Vehicle(
      id: id,
      brandId: draft.brandId,
      brandOtherName: draft.brandOtherName,
      modelId: draft.modelId,
      modelOtherName: draft.modelOtherName,
      nickname: details.nickname,
      year: details.year,
      fuelType: details.fuelType,
      bodyType: details.bodyType,
      paint: details.paint,
      vin: details.vin,
      licencePlate: details.licencePlate,
      // The purchase date defaults to the delivery date (BR-MNT-12).
      purchaseDate: details.purchaseDate ?? (isNew ? setup.deliveryDate : null),
      odometerKm: details.odometerKm,
      odometerUpdatedAt: now,
      setupMode: isNew ? SetupMode.newCar : SetupMode.baseline,
      templateVersion: templateVersion,
    );
  }
}

final serviceBaselineControllerProvider =
    AsyncNotifierProvider.autoDispose<ServiceBaselineController, ServiceBaselineSetup>(ServiceBaselineController.new);
