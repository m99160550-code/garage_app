import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../maintenance/domain/item_due.dart';
import '../../privacy/application/consent_providers.dart';
import '../../reference/application/reference_providers.dart';
import '../../settings/application/preferences_providers.dart';
import '../../vehicles/application/garage_providers.dart';
import '../../vehicles/domain/body_type.dart';
import '../../vehicles/domain/paint_color.dart';
import 'vehicle_dues.dart';

/// The worst state of a vehicle, for its badge in the switcher (spec S-10).
sealed class VehicleStatus {
  const VehicleStatus();
}

final class VehicleOverdue extends VehicleStatus {
  const VehicleOverdue(this.count);

  final int count;
}

final class VehicleDueSoon extends VehicleStatus {
  const VehicleDueSoon();
}

final class VehicleAllGood extends VehicleStatus {
  const VehicleAllGood();
}

/// Every item is still Unknown, so "All good" would be misleading.
final class VehicleNotSetUp extends VehicleStatus {
  const VehicleNotSetUp();
}

VehicleStatus vehicleStatusFrom(List<ItemDue> dues) {
  final overdue = dues.where((d) => d.status == ItemStatus.overdue).length;
  if (overdue > 0) return VehicleOverdue(overdue);
  if (dues.any((d) => d.status == ItemStatus.dueSoon)) return const VehicleDueSoon();
  if (dues.every((d) => d.status == ItemStatus.unknown || d.status == ItemStatus.notApplicable)) {
    return const VehicleNotSetUp();
  }
  return const VehicleAllGood();
}

/// One row of the vehicle switcher.
@immutable
class VehicleSummary {
  const VehicleSummary({
    required this.id,
    required this.name,
    required this.subline,
    required this.bodyType,
    required this.paint,
    required this.status,
  });

  final String id;

  /// Nickname, or brand and model ("Toyota Camry").
  final String name;

  /// "Camry · 2022" (model, and year when known).
  final String subline;
  final BodyType bodyType;
  final PaintColor paint;
  final VehicleStatus status;
}

/// The garage as the switcher lists it, in the UI language.
final vehicleSummariesProvider = FutureProvider.autoDispose.family<List<VehicleSummary>, String>((
  ref,
  languageCode,
) async {
  // Every dependency is watched before the first await.
  ref.watch(garageRevisionProvider);
  final garage = ref.watch(garageRepositoryProvider);
  final preferencesRepository = ref.watch(preferencesRepositoryProvider);
  final reference = ref.watch(referenceRepositoryProvider);
  final brandsFuture = ref.watch(brandsProvider.future);
  final today = ref.watch(clockProvider)();

  final vehicles = await garage.vehicles();
  final preferences = await preferencesRepository.load();
  final brands = await brandsFuture;

  return [
    for (final vehicle in vehicles)
      await () async {
        final brand = brands.where((b) => b.id == vehicle.brandId).firstOrNull;
        final model = brand == null || vehicle.modelId == null
            ? null
            : (await reference.models(brand.id)).where((m) => m.id == vehicle.modelId).firstOrNull;
        final brandName = brand?.name(languageCode) ?? vehicle.brandOtherName ?? '';
        final modelName = model?.name(languageCode) ?? vehicle.modelOtherName ?? '';
        final nickname = vehicle.nickname?.trim();
        final schedule = await garage.schedule(vehicle.id);
        final readings = await garage.readings(vehicle.id);
        return VehicleSummary(
          id: vehicle.id,
          name: nickname != null && nickname.isNotEmpty ? nickname : '$brandName $modelName'.trim(),
          subline: [modelName, if (vehicle.year != null) '${vehicle.year}'].where((s) => s.isNotEmpty).join(' · '),
          bodyType: vehicle.bodyType,
          paint: vehicle.paint,
          status: vehicleStatusFrom(
            vehicleDues(vehicle, schedule, readings: readings, unit: preferences.distanceUnit, today: today),
          ),
        );
      }(),
  ];
});
