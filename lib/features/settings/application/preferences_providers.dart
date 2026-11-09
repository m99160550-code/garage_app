import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/mock_config.dart';
import '../../reference/data/mock_reference_repository.dart';
import '../data/preferences_repository.dart';
import '../domain/regional_preferences.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => MockPreferencesRepository(_seedForPreviews()),
);

/// Previews that start after S-03 (for example `MOCK_SCENARIO=brandStep`)
/// behave as if the country step ran for the simulated region.
RegionalPreferences _seedForPreviews() {
  const startsAfterCountry = {'brandStep', 'modelStep', 'detailsStep', 'setupDraft', 'returning'};
  const region = MockConfig.regionOverride;
  if (!startsAfterCountry.contains(MockConfig.scenario) || region.isEmpty || region == 'none') {
    return const RegionalPreferences();
  }
  return const RegionalPreferences().withCountry(MockReferenceRepository.countryByCode(region));
}

/// The device's region setting (ISO country code), or `null` if unknown.
///
/// Used to preselect the country (never location permission, BR-SET-11)
/// and to decide whether analytics consent is required (BR-PRV-01).
/// Override for previews with `--dart-define=MOCK_REGION=DE`
/// (`MOCK_REGION=none` simulates an unknown region).
final deviceRegionProvider = Provider<String?>((ref) {
  const forced = MockConfig.regionOverride;
  if (forced == 'none') return null;
  if (forced.isNotEmpty) return forced.toUpperCase();
  return PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
});
