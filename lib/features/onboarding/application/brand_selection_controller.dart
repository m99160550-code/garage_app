import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reference/application/reference_providers.dart';
import '../../reference/domain/brand.dart';
import '../../session/application/session_providers.dart';
import '../../session/domain/app_session.dart';
import '../../vehicles/application/vehicle_draft_controller.dart';
import 'brand_filter.dart';

/// State of S-04 Brand selection.
@immutable
class BrandSelectionState {
  const BrandSelectionState({
    required this.brands,
    required this.popularRanking,
    this.tab = BrandTab.popular,
    this.query = '',
    this.selectedBrand,
    this.otherSelected = false,
    this.otherName = '',
  });

  final List<Brand> brands;
  final List<String> popularRanking;
  final BrandTab tab;
  final String query;

  /// A dataset brand, or `null`.
  final Brand? selectedBrand;

  /// "Other brand" chosen, with the typed name in [otherName].
  final bool otherSelected;
  final String otherName;

  bool get canContinue => selectedBrand != null || (otherSelected && otherName.trim().isNotEmpty);

  BrandSelectionState copyWith({
    BrandTab? tab,
    String? query,
    Brand? Function()? selectedBrand,
    bool? otherSelected,
    String? otherName,
  }) => BrandSelectionState(
    brands: brands,
    popularRanking: popularRanking,
    tab: tab ?? this.tab,
    query: query ?? this.query,
    selectedBrand: selectedBrand == null ? this.selectedBrand : selectedBrand(),
    otherSelected: otherSelected ?? this.otherSelected,
    otherName: otherName ?? this.otherName,
  );
}

class BrandSelectionController extends AsyncNotifier<BrandSelectionState> {
  @override
  Future<BrandSelectionState> build() async {
    final brands = await ref.watch(brandsProvider.future);
    final ranking = await ref.watch(activePopularRankingProvider.future);
    // Coming back to this step keeps the earlier answer.
    final draft = ref.read(vehicleDraftProvider);
    return BrandSelectionState(
      brands: brands,
      popularRanking: ranking,
      selectedBrand: brands.where((b) => b.id == draft.brandId).firstOrNull,
      otherSelected: draft.brandOtherName != null,
      otherName: draft.brandOtherName ?? '',
    );
  }

  BrandSelectionState get _current => state.requireValue;

  void setTab(BrandTab tab) => state = AsyncData(_current.copyWith(tab: tab));

  void setQuery(String query) => state = AsyncData(_current.copyWith(query: query));

  /// Selecting is reversible: tapping the selected brand clears it (F2).
  void toggleBrand(Brand brand) {
    final alreadySelected = _current.selectedBrand == brand;
    state = AsyncData(_current.copyWith(selectedBrand: () => alreadySelected ? null : brand, otherSelected: false));
  }

  /// Chooses "Other brand", optionally prefilled from the search text.
  void toggleOther({String? prefill}) {
    final turningOn = prefill != null || !_current.otherSelected;
    state = AsyncData(
      _current.copyWith(selectedBrand: () => null, otherSelected: turningOn, otherName: prefill ?? _current.otherName),
    );
  }

  void setOtherName(String name) => state = AsyncData(_current.copyWith(otherName: name));

  /// Saves the brand into the draft. For the first vehicle, setup now
  /// resumes at Model selection if the app is closed.
  Future<void> submit({required bool addingVehicle}) async {
    final current = _current;
    if (!current.canContinue) throw StateError('No brand chosen.');
    final draft = ref.read(vehicleDraftProvider.notifier);
    if (current.selectedBrand case final brand?) {
      draft.setBrand(brandId: brand.id);
    } else {
      draft.setBrand(otherName: current.otherName);
    }
    if (!addingVehicle) {
      await ref.read(sessionRepositoryProvider).saveSetupDraftStep(SetupStep.model);
    }
  }
}

final brandSelectionControllerProvider =
    AsyncNotifierProvider.autoDispose<BrandSelectionController, BrandSelectionState>(BrandSelectionController.new);
