import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reference/application/reference_providers.dart';
import '../../reference/domain/brand.dart';
import '../../reference/domain/vehicle_model.dart';
import '../../session/application/session_providers.dart';
import '../../session/domain/app_session.dart';
import '../../vehicles/application/vehicle_draft_controller.dart';
import '../../vehicles/domain/body_type.dart';

/// Why there are no models to pick from.
enum NoModelsReason {
  /// A dataset brand whose models arrive in data phase 2 (FR-REF-12).
  comingSoon,

  /// A brand typed under "Other brand" (BR-VEH-07).
  otherBrand,
}

/// State of S-05 Model selection.
@immutable
class ModelSelectionState {
  const ModelSelectionState({
    required this.hasBrand,
    this.brand,
    this.brandOtherName,
    this.models = const [],
    this.selectedModel,
    this.otherSelected = false,
    this.otherName = '',
    this.otherBodyType,
  });

  /// False if setup resumed here without a brand: send the user back.
  final bool hasBrand;
  final Brand? brand;
  final String? brandOtherName;
  final List<VehicleModel> models;
  final VehicleModel? selectedModel;
  final bool otherSelected;
  final String otherName;
  final BodyType? otherBodyType;

  NoModelsReason? get noModelsReason =>
      models.isNotEmpty ? null : (brand == null ? NoModelsReason.otherBrand : NoModelsReason.comingSoon);

  /// Monogram for the header. Typed brands use their first two letters.
  String get monogram {
    if (brand != null) return brand!.monogram;
    final letters = (brandOtherName ?? '').replaceAll(' ', '');
    return letters.isEmpty ? '?' : String.fromCharCodes(letters.runes.take(2)).toUpperCase();
  }

  bool get canContinue =>
      selectedModel != null || (otherSelected && otherName.trim().isNotEmpty && otherBodyType != null);

  ModelSelectionState copyWith({
    VehicleModel? Function()? selectedModel,
    bool? otherSelected,
    String? otherName,
    BodyType? Function()? otherBodyType,
  }) => ModelSelectionState(
    hasBrand: hasBrand,
    brand: brand,
    brandOtherName: brandOtherName,
    models: models,
    selectedModel: selectedModel == null ? this.selectedModel : selectedModel(),
    otherSelected: otherSelected ?? this.otherSelected,
    otherName: otherName ?? this.otherName,
    otherBodyType: otherBodyType == null ? this.otherBodyType : otherBodyType(),
  );
}

class ModelSelectionController extends AsyncNotifier<ModelSelectionState> {
  @override
  Future<ModelSelectionState> build() async {
    final draft = ref.read(vehicleDraftProvider);
    if (!draft.hasBrand) return const ModelSelectionState(hasBrand: false);

    final brands = await ref.watch(brandsProvider.future);
    final brand = brands.where((b) => b.id == draft.brandId).firstOrNull;
    final models = brand == null
        ? const <VehicleModel>[]
        : await ref.read(referenceRepositoryProvider).models(brand.id);

    final previous = models.where((m) => m.id == draft.modelId).firstOrNull;
    return ModelSelectionState(
      hasBrand: true,
      brand: brand,
      brandOtherName: draft.brandOtherName,
      models: models,
      selectedModel: previous,
      // With nothing to pick from, "Other model" is open from the start.
      otherSelected: models.isEmpty || draft.modelOtherName != null,
      otherName: draft.modelOtherName ?? '',
      otherBodyType: draft.modelOtherName != null ? draft.bodyType : null,
    );
  }

  ModelSelectionState get _current => state.requireValue;

  /// Models behave like radio options: choosing one closes "Other model".
  void selectModel(VehicleModel model) =>
      state = AsyncData(_current.copyWith(selectedModel: () => model, otherSelected: false));

  void toggleOther() {
    final current = _current;
    // With no models, "Other model" can't be closed.
    if (current.models.isEmpty) return;
    state = AsyncData(current.copyWith(otherSelected: !current.otherSelected, selectedModel: () => null));
  }

  void setOtherName(String name) => state = AsyncData(_current.copyWith(otherName: name));

  void setOtherBodyType(BodyType type) => state = AsyncData(_current.copyWith(otherBodyType: () => type));

  Future<void> submit({required bool addingVehicle}) async {
    final current = _current;
    if (!current.canContinue) throw StateError('No model chosen.');
    final draft = ref.read(vehicleDraftProvider.notifier);
    if (current.selectedModel case final model?) {
      draft.setModel(modelId: model.id, bodyType: model.bodyType);
    } else {
      draft.setModel(otherName: current.otherName, bodyType: current.otherBodyType!);
    }
    if (!addingVehicle) {
      await ref.read(sessionRepositoryProvider).saveSetupDraftStep(SetupStep.details);
    }
  }
}

final modelSelectionControllerProvider =
    AsyncNotifierProvider.autoDispose<ModelSelectionController, ModelSelectionState>(ModelSelectionController.new);
