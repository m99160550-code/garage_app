import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../garage/application/current_vehicle_controller.dart';
import '../../garage/application/dashboard_data.dart';
import '../../settings/domain/distance_unit.dart';
import '../domain/service_record.dart';
import 'service_history_providers.dart';

/// The vehicle the History tab shows. It starts as the dashboard's
/// vehicle (spec S-20 item 2); picking another one here doesn't change
/// the dashboard.
class HistoryVehicle extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String vehicleId) => state = vehicleId;
}

final historyVehicleChoiceProvider = NotifierProvider<HistoryVehicle, String?>(HistoryVehicle.new);

/// The chosen vehicle, or the dashboard's when none was chosen (or the
/// chosen one was deleted).
final historyVehicleIdProvider = Provider.autoDispose<String?>((ref) {
  final chosen = ref.watch(historyVehicleChoiceProvider);
  final vehicles = ref.watch(garageVehiclesProvider).value ?? const [];
  if (chosen != null && vehicles.any((v) => v.id == chosen)) return chosen;
  return ref.watch(currentVehicleProvider).value;
});

/// Everything S-20 shows for one vehicle.
@immutable
class HistoryView {
  const HistoryView({
    required this.vehicleName,
    required this.monogram,
    required this.records,
    required this.itemNames,
    required this.unit,
  });

  final String vehicleName;
  final String monogram;

  /// Every record, newest first.
  final List<ServiceRecord> records;

  /// Schedule item names by code: (English, Arabic).
  final Map<String, (String, String)> itemNames;
  final DistanceUnit unit;
}

/// S-20 data for (vehicle id, language).
final historyViewProvider = FutureProvider.autoDispose.family<HistoryView, (String, String)>((ref, key) async {
  final (vehicleId, language) = key;
  // Watch everything before the first await (Riverpod 3).
  final dataFuture = ref.watch(dashboardDataProvider(vehicleId).future);
  final repository = ref.watch(serviceRecordRepositoryProvider);

  final data = await dataFuture;
  final name = data.vehicle.nickname ?? '${data.brandName(language)} ${data.modelName(language)}'.trim();
  return HistoryView(
    vehicleName: name,
    monogram: data.monogram,
    records: await repository.records(vehicleId),
    itemNames: {for (final d in data.dues) d.item.code: (d.item.nameEn, d.item.nameAr)},
    unit: data.unit,
  );
});
