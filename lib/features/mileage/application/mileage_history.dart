import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../privacy/application/consent_providers.dart';
import '../../settings/application/preferences_providers.dart';
import '../../settings/domain/distance_unit.dart';
import '../../vehicles/application/garage_providers.dart';
import '../domain/mileage_rules.dart';
import '../domain/odometer_reading.dart';

/// Everything S-13 shows for one vehicle.
@immutable
class MileageHistory {
  const MileageHistory({
    required this.readings,
    required this.dailyKm,
    required this.daysUntilAverage,
    required this.unit,
  });

  /// Newest first.
  final List<OdometerReading> readings;

  /// `null` when there isn't enough data for an average (BR-MIL-05).
  final double? dailyKm;
  final int daysUntilAverage;
  final DistanceUnit unit;

  /// Only the reading entered at setup (spec S-13 "Empty state").
  bool get onlyStartingReading => readings.length <= 1;
}

final mileageHistoryProvider = FutureProvider.autoDispose.family<MileageHistory, String>((ref, vehicleId) async {
  ref.watch(garageRevisionProvider);
  final garage = ref.watch(garageRepositoryProvider);
  final preferencesRepository = ref.watch(preferencesRepositoryProvider);
  final today = ref.watch(clockProvider)();

  final readings = await garage.readings(vehicleId);
  final preferences = await preferencesRepository.load();
  return MileageHistory(
    readings: readings.reversed.toList(),
    dailyKm: averageDailyKm(readings, today: today),
    daysUntilAverage: daysUntilAverage(readings, today: today),
    unit: preferences.distanceUnit,
  );
});

/// Deletes a manual reading (spec S-13 item 5).
Future<void> deleteReading(WidgetRef ref, OdometerReading reading) async {
  await ref.read(garageRepositoryProvider).deleteReading(reading.vehicleId, reading.id);
  ref.read(garageRevisionProvider.notifier).bump();
}
