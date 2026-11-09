import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../privacy/application/consent_providers.dart';
import '../../privacy/domain/consent.dart';
import '../../reference/application/reference_providers.dart';
import '../../reference/domain/country.dart';
import '../../session/application/session_providers.dart';
import '../../session/domain/app_session.dart';
import '../../settings/application/preferences_providers.dart';
import '../../settings/domain/regional_preferences.dart';

/// State of S-03 Country & consent.
@immutable
class CountryStepState {
  const CountryStepState({
    required this.countries,
    required this.selected,
    required this.preferences,
    required this.deviceRegion,
    required this.consentRequired,
    this.analyticsAllowed,
  });

  final List<Country> countries;

  /// `null` means "Other / not set".
  final Country? selected;

  /// The presets the selected country gives (shown in the country card).
  final RegionalPreferences preferences;
  final String? deviceRegion;

  /// Show the consent card (device region in EU/EEA, UK, CH, or unknown).
  final bool consentRequired;

  /// `null` until the user taps Allow or Don't allow. Neither is preselected.
  final bool? analyticsAllowed;

  /// Continue is enabled once any required consent choice is made.
  bool get canContinue => !consentRequired || analyticsAllowed != null;

  CountryStepState copyWith({
    Country? Function()? selected,
    RegionalPreferences? preferences,
    bool? analyticsAllowed,
  }) => CountryStepState(
    countries: countries,
    selected: selected == null ? this.selected : selected(),
    preferences: preferences ?? this.preferences,
    deviceRegion: deviceRegion,
    consentRequired: consentRequired,
    analyticsAllowed: analyticsAllowed ?? this.analyticsAllowed,
  );
}

class CountryStepController extends AsyncNotifier<CountryStepState> {
  @override
  Future<CountryStepState> build() async {
    final countries = await ref.watch(countriesProvider.future);
    final region = ref.watch(deviceRegionProvider);
    final saved = await ref.read(preferencesRepositoryProvider).load();

    // A country already chosen wins. Otherwise preselect from the device
    // region (never from location, BR-SET-11).
    final code = saved.countryCode ?? region;
    final selected = countries.where((c) => c.code == code).firstOrNull;

    return CountryStepState(
      countries: countries,
      selected: selected,
      preferences: saved.withCountry(selected),
      deviceRegion: region,
      consentRequired: analyticsConsentRequired(region),
    );
  }

  void selectCountry(Country? country) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(selected: () => country, preferences: current.preferences.withCountry(country)));
  }

  void setAnalyticsAllowed({required bool allowed}) {
    state = AsyncData(state.requireValue.copyWith(analyticsAllowed: allowed));
  }

  /// Saves the presets and the consent decision, and remembers that setup
  /// continues at Brand selection.
  Future<void> submit() async {
    final current = state.requireValue;
    if (!current.canContinue) {
      throw StateError('Analytics consent choice is required before continuing.');
    }

    var preferences = current.preferences;
    if (current.consentRequired) {
      final allowed = current.analyticsAllowed!;
      await ref
          .read(consentRepositoryProvider)
          .record(
            ConsentRecord(
              purpose: ConsentPurpose.analytics,
              granted: allowed,
              regionCode: current.deviceRegion,
              policyVersion: currentPolicyVersion,
              recordedAt: ref.read(clockProvider)(),
            ),
          );
      preferences = preferences.withAnalytics(enabled: allowed);
    }

    await ref.read(preferencesRepositoryProvider).save(preferences);
    await ref.read(sessionRepositoryProvider).saveSetupDraftStep(SetupStep.brand);
  }
}

final countryStepControllerProvider = AsyncNotifierProvider.autoDispose<CountryStepController, CountryStepState>(
  CountryStepController.new,
);
