import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reference/application/reference_providers.dart';
import 'garage_providers.dart';

/// A vehicle's name as shown across the app: its nickname, or brand and
/// model ("Toyota Camry") in the UI language. Typed "Other" names are used
/// as entered (BR-VEH-07).
final vehicleDisplayNameProvider = FutureProvider.autoDispose.family<String, ({String vehicleId, String languageCode})>(
  (ref, key) async {
    final vehicles = await ref.read(garageRepositoryProvider).vehicles();
    final vehicle = vehicles.where((v) => v.id == key.vehicleId).firstOrNull;
    if (vehicle == null) return '';
    final nickname = vehicle.nickname?.trim();
    if (nickname != null && nickname.isNotEmpty) return nickname;

    final reference = ref.read(referenceRepositoryProvider);
    final brand = vehicle.brandId == null
        ? null
        : (await ref.read(brandsProvider.future)).where((b) => b.id == vehicle.brandId).firstOrNull;
    final model = brand == null || vehicle.modelId == null
        ? null
        : (await reference.models(brand.id)).where((m) => m.id == vehicle.modelId).firstOrNull;

    return [
      brand?.name(key.languageCode) ?? vehicle.brandOtherName,
      model?.name(key.languageCode) ?? vehicle.modelOtherName,
    ].whereType<String>().join(' ');
  },
);
