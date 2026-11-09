import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../garage/application/current_vehicle_controller.dart';
import '../../garage/application/dashboard_data.dart';
import '../../settings/application/preferences_providers.dart';
import '../../settings/domain/distance_unit.dart';
import '../../vehicles/domain/garage_limits.dart';

/// One vehicle as the Add menu shows it.
@immutable
class AddMenuVehicle {
  const AddMenuVehicle({required this.id, required this.name, required this.monogram, required this.odometerKm});

  final String id;
  final String name;
  final String monogram;
  final int odometerKm;
}

/// What S-23 needs.
@immutable
class AddMenuData {
  const AddMenuData({required this.vehicles, required this.defaultVehicleId, required this.unit});

  final List<AddMenuVehicle> vehicles;

  /// The dashboard's vehicle (FR-ADD-02 starts there).
  final String? defaultVehicleId;
  final DistanceUnit unit;

  /// "Add vehicle" is disabled at the garage limit (BR-VEH-01).
  bool get atLimit => vehicles.length >= maxGarageVehicles;
}

/// S-23 data in the UI language.
final addMenuDataProvider = FutureProvider.autoDispose.family<AddMenuData, String>((ref, languageCode) async {
  // Watch everything before the first await (Riverpod 3).
  final vehiclesFuture = ref.watch(garageVehiclesProvider.future);
  final currentFuture = ref.watch(currentVehicleProvider.future);
  final preferences = ref.watch(preferencesRepositoryProvider);

  final vehicles = await vehiclesFuture;
  final details = <AddMenuVehicle>[];
  for (final v in vehicles) {
    final data = await ref.read(dashboardDataProvider(v.id).future);
    details.add(
      AddMenuVehicle(
        id: v.id,
        name: v.nickname ?? '${data.brandName(languageCode)} ${data.modelName(languageCode)}'.trim(),
        monogram: data.monogram,
        odometerKm: v.odometerKm,
      ),
    );
  }
  return AddMenuData(
    vehicles: details,
    defaultVehicleId: await currentFuture,
    unit: (await preferences.load()).distanceUnit,
  );
});
