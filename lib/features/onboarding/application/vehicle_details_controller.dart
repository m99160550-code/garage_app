import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reference/application/reference_providers.dart';
import '../../reference/domain/brand.dart';
import '../../reference/domain/vehicle_model.dart';
import '../../session/application/session_providers.dart';
import '../../session/domain/app_session.dart';
import '../../settings/application/preferences_providers.dart';
import '../../settings/domain/distance_unit.dart';
import '../../vehicles/application/garage_providers.dart';
import '../../vehicles/application/vehicle_draft_controller.dart';
import '../../vehicles/domain/body_type.dart';
import '../../vehicles/domain/fuel_type.dart';
import '../../vehicles/domain/vehicle.dart';
import '../../vehicles/domain/vehicle_details.dart';

/// Everything S-06 needs to show the form (spec S-06).
@immutable
class VehicleDetailsSetup {
  const VehicleDetailsSetup({
    required this.hasModel,
    this.brand,
    this.brandOtherName,
    this.model,
    this.modelOtherName,
    this.bodyType = BodyType.sedan,
    this.suggestedFuel,
    this.unit = DistanceUnit.km,
    this.existing,
    this.garage = const [],
  });

  /// False if setup resumed here without a brand and model.
  final bool hasModel;
  final Brand? brand;
  final String? brandOtherName;
  final VehicleModel? model;
  final String? modelOtherName;

  /// From the model (or "Other model"), changeable here (BR-VEH-09).
  final BodyType bodyType;

  /// The model's usual fuel, preselected (BR-REF-05).
  final FuelType? suggestedFuel;

  /// The user's distance unit for the odometer field.
  final DistanceUnit unit;

  /// Answers already given, when coming back to this step.
  final VehicleDetails? existing;

  /// Other cars in the garage, for the duplicate-VIN warning (BR-VEH-03).
  final List<Vehicle> garage;

  /// "Toyota Camry", in the UI language.
  String title(String languageCode) => [
    brand?.name(languageCode) ?? brandOtherName,
    model?.name(languageCode) ?? modelOtherName,
  ].whereType<String>().join(' ');

  /// A car in the garage with the same VIN, if any (never across accounts).
  Vehicle? duplicateOf(String vin) {
    final normalized = vin.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    return garage.where((v) => v.vin?.toUpperCase() == normalized).firstOrNull;
  }
}

class VehicleDetailsController extends AsyncNotifier<VehicleDetailsSetup> {
  @override
  Future<VehicleDetailsSetup> build() async {
    final draft = ref.read(vehicleDraftProvider);
    if (!draft.hasBrand || !draft.hasModel) return const VehicleDetailsSetup(hasModel: false);

    final brands = await ref.watch(brandsProvider.future);
    final brand = brands.where((b) => b.id == draft.brandId).firstOrNull;
    final models = brand == null
        ? const <VehicleModel>[]
        : await ref.read(referenceRepositoryProvider).models(brand.id);
    final model = models.where((m) => m.id == draft.modelId).firstOrNull;
    final preferences = await ref.read(preferencesRepositoryProvider).load();
    final garage = await ref.read(garageRepositoryProvider).vehicles();

    return VehicleDetailsSetup(
      hasModel: true,
      brand: brand,
      brandOtherName: draft.brandOtherName,
      model: model,
      modelOtherName: draft.modelOtherName,
      bodyType: draft.details?.bodyType ?? draft.bodyType!,
      suggestedFuel: model?.defaultFuelType,
      unit: preferences.distanceUnit,
      existing: draft.details,
      garage: garage,
    );
  }

  /// Saves the answers into the draft. For the first vehicle, setup now
  /// resumes at the service baseline if the app is closed.
  Future<void> save(VehicleDetails details, {required bool addingVehicle}) async {
    ref.read(vehicleDraftProvider.notifier).setDetails(details);
    if (!addingVehicle) {
      await ref.read(sessionRepositoryProvider).saveSetupDraftStep(SetupStep.baseline);
    }
  }
}

final vehicleDetailsControllerProvider =
    AsyncNotifierProvider.autoDispose<VehicleDetailsController, VehicleDetailsSetup>(VehicleDetailsController.new);
