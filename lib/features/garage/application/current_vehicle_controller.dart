import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../service_history/application/service_history_providers.dart';
import '../../session/application/session_providers.dart';
import '../../vehicles/application/garage_providers.dart';
import '../../vehicles/domain/vehicle.dart';

/// The vehicles in the garage, in the order they were added.
final garageVehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) {
  ref.watch(garageRevisionProvider);
  return ref.watch(garageRepositoryProvider).vehicles();
});

/// The vehicle the dashboard shows: the last one viewed (BR-VEH-05), or
/// the first vehicle. `null` when the garage is empty.
class CurrentVehicleController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final session = await ref.watch(appSessionProvider.future);
    final vehicles = await ref.watch(garageVehiclesProvider.future);
    if (vehicles.isEmpty) return null;
    final last = session.lastVehicleId;
    return vehicles.any((v) => v.id == last) ? last : vehicles.first.id;
  }

  /// Shows [vehicleId] and remembers it for the next launch.
  Future<void> select(String vehicleId) async {
    state = AsyncData(vehicleId);
    await ref.read(sessionRepositoryProvider).saveLastVehicle(vehicleId);
  }

  /// The vehicle before or after the current one, for the hero swipe.
  /// Wraps around. `null` with a single vehicle.
  String? neighbour(List<Vehicle> vehicles, {required bool next}) {
    final current = state.value;
    if (vehicles.length < 2 || current == null) return null;
    final index = vehicles.indexWhere((v) => v.id == current);
    return vehicles[(index + (next ? 1 : -1)) % vehicles.length].id;
  }

  /// Deletes the vehicle with all its data (FR-VEH-12). Returns the
  /// vehicle shown next, or `null` if the garage is now empty (BR-VEH-06).
  Future<String?> delete(String vehicleId) async {
    final garage = ref.read(garageRepositoryProvider);
    final records = ref.read(serviceRecordRepositoryProvider);
    for (final record in await records.records(vehicleId)) {
      await records.delete(record.id);
    }
    await garage.deleteVehicle(vehicleId);
    final remaining = await garage.vehicles();
    final next = remaining.firstOrNull?.id;
    await ref.read(sessionRepositoryProvider).recordVehicleDeleted(vehicleId, nextVehicleId: next);
    ref.read(garageRevisionProvider.notifier).bump();
    ref
      ..invalidate(garageVehiclesProvider)
      ..invalidate(appSessionProvider);
    return next;
  }
}

final currentVehicleProvider = AsyncNotifierProvider<CurrentVehicleController, String?>(CurrentVehicleController.new);
