import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../garage/application/current_vehicle_controller.dart';
import '../../privacy/application/consent_providers.dart';
import '../../settings/application/preferences_providers.dart';
import '../../settings/domain/distance_unit.dart';
import '../../vehicles/application/garage_providers.dart';
import '../../vehicles/application/vehicle_names.dart';
import '../domain/mileage_rules.dart';
import '../domain/odometer_reading.dart';

/// What S-12 needs for one vehicle.
@immutable
class MileageSheetData {
  const MileageSheetData({
    required this.vehicleId,
    required this.vehicleName,
    required this.current,
    required this.unit,
    required this.today,
    required this.vehicles,
  });

  final String vehicleId;
  final String vehicleName;

  /// The current reading, for the placeholder and "Last: …".
  final OdometerReading? current;
  final DistanceUnit unit;
  final DateTime today;

  /// Every vehicle (id, name), for the vehicle picker.
  final List<(String, String)> vehicles;
}

final mileageSheetDataProvider = FutureProvider.autoDispose
    .family<MileageSheetData, ({String vehicleId, String languageCode})>((ref, key) async {
      ref.watch(garageRevisionProvider);
      final garage = ref.watch(garageRepositoryProvider);
      final preferencesRepository = ref.watch(preferencesRepositoryProvider);
      final today = ref.watch(clockProvider)();
      final vehicles = await ref.watch(garageVehiclesProvider.future);

      final readings = await garage.readings(key.vehicleId);
      final preferences = await preferencesRepository.load();
      final names = <(String, String)>[
        for (final v in vehicles)
          (v.id, await ref.read(vehicleDisplayNameProvider((vehicleId: v.id, languageCode: key.languageCode)).future)),
      ];
      return MileageSheetData(
        vehicleId: key.vehicleId,
        vehicleName: names.firstWhere((n) => n.$1 == key.vehicleId).$2,
        current: currentReading(readings),
        unit: preferences.distanceUnit,
        today: today,
        vehicles: names,
      );
    });

/// Saves odometer readings (UC-02).
class MileageController {
  MileageController(this._ref);

  final Ref _ref;

  /// Checks a new value before saving (BR-MIL-02, BR-MIL-03).
  ReadingCheck check(MileageSheetData data, int km) =>
      checkNewReading(newKm: km, current: data.current, today: data.today, unit: data.unit);

  /// Saves the reading as of today. The dashboard, score and pill
  /// recalculate straight away (UC-02 step 5).
  Future<void> save(String vehicleId, int km, {bool correction = false}) async {
    final now = _ref.read(clockProvider)();
    await _ref
        .read(garageRepositoryProvider)
        .addReading(OdometerReading(id: '', vehicleId: vehicleId, date: now, km: km, isCorrection: correction));
    _ref.read(garageRevisionProvider.notifier).bump();
  }
}

final mileageControllerProvider = Provider<MileageController>(MileageController.new);
