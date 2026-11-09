import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/mock_config.dart';
import '../domain/body_type.dart';
import '../domain/fuel_type.dart';
import '../domain/paint_color.dart';
import '../domain/vehicle_details.dart';
import '../domain/vehicle_draft.dart';

/// Holds the vehicle being set up while the user moves between steps.
/// Kept in memory for now. The local database will persist it so an
/// interrupted setup resumes with its answers (UC-01 "app closed mid-flow").
class VehicleDraftController extends Notifier<VehicleDraft> {
  @override
  VehicleDraft build() {
    // Previews that start part-way through setup need earlier answers.
    const brand = MockConfig.draftBrand;
    return switch (MockConfig.scenario) {
      'modelStep' =>
        brand.startsWith('other:')
            ? VehicleDraft(brandOtherName: brand.substring(6))
            : const VehicleDraft(brandId: brand),
      'detailsStep' => const VehicleDraft(brandId: 'toyota', modelId: 'toyota-camry', bodyType: BodyType.sedan),
      'baselineStep' => const VehicleDraft(
        brandId: 'toyota',
        modelId: 'toyota-camry',
        bodyType: BodyType.sedan,
        details: VehicleDetails(
          fuelType: FuelType.hybrid,
          odometerKm: 54320,
          paint: PaintColor.midnightBlue,
          bodyType: BodyType.sedan,
          nickname: 'Family Camry',
        ),
      ),
      _ => const VehicleDraft(),
    };
  }

  /// Sets the brand. Choosing a different brand clears the model, which
  /// may belong to the old brand.
  void setBrand({String? brandId, String? otherName}) {
    assert((brandId == null) != (otherName == null), 'Exactly one brand source');
    final trimmed = otherName?.trim();
    final sameBrand = brandId == state.brandId && trimmed == state.brandOtherName;
    state = sameBrand ? state : VehicleDraft(brandId: brandId, brandOtherName: trimmed);
  }

  /// Sets the model. Answers already given on S-06 are kept, but a new
  /// model brings its own body type.
  void setModel({String? modelId, String? otherName, required BodyType bodyType}) {
    assert((modelId == null) != (otherName == null), 'Exactly one model source');
    final sameModel = modelId == state.modelId && otherName?.trim() == state.modelOtherName;
    state = VehicleDraft(
      brandId: state.brandId,
      brandOtherName: state.brandOtherName,
      modelId: modelId,
      modelOtherName: otherName?.trim(),
      bodyType: bodyType,
      details: sameModel ? state.details : state.details?.withBodyType(bodyType),
    );
  }

  void setDetails(VehicleDetails details) {
    state = VehicleDraft(
      brandId: state.brandId,
      brandOtherName: state.brandOtherName,
      modelId: state.modelId,
      modelOtherName: state.modelOtherName,
      bodyType: details.bodyType,
      details: details,
    );
  }

  void reset() => state = const VehicleDraft();

  /// [reset] after a screen closes; nothing to do if the app is shutting
  /// down.
  void resetIfAlive() {
    if (ref.mounted) reset();
  }

  /// Starts editing an existing vehicle's brand and model (S-32).
  void edit(VehicleDraft draft) => state = draft;
}

final vehicleDraftProvider = NotifierProvider<VehicleDraftController, VehicleDraft>(VehicleDraftController.new);
