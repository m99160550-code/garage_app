import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reference/application/reference_providers.dart';
import '../../reference/domain/country.dart';
import '../../vehicles/application/garage_providers.dart';
import '../domain/distance_unit.dart';
import '../domain/regional_preferences.dart';
import 'preferences_providers.dart';
import 'profile_data.dart';

/// What the S-25 pickers need.
@immutable
class RegionData {
  const RegionData({required this.preferences, required this.countries});

  final RegionalPreferences preferences;
  final List<Country> countries;

  Country? get country => countries.where((c) => c.code == preferences.countryCode).firstOrNull;
}

final regionDataProvider = FutureProvider.autoDispose<RegionData>((ref) async {
  ref.watch(profileRevisionProvider);
  final preferences = ref.watch(preferencesRepositoryProvider);
  final reference = ref.watch(referenceRepositoryProvider);
  return RegionData(preferences: await preferences.load(), countries: await reference.countries());
});

/// Saves S-25 choices. Every screen showing distances or money refreshes
/// straight away (BR-SET-02).
class RegionActions {
  RegionActions(this._ref);

  final Ref _ref;

  Future<void> _save(RegionalPreferences preferences) async {
    await _ref.read(preferencesRepositoryProvider).save(preferences);
    _ref.read(profileRevisionProvider.notifier).bump();
    _ref.read(garageRevisionProvider.notifier).bump();
  }

  /// [switchValues]: also take the country's currency and unit where they
  /// weren't set by hand ("Switch"); otherwise keep them ("Keep current").
  Future<void> setCountry(RegionalPreferences current, Country? country, {required bool switchValues}) =>
      _save(switchValues ? current.withCountry(country) : current.withCountryOnly(country));

  Future<void> setDistanceUnit(RegionalPreferences current, DistanceUnit unit) => _save(current.withDistanceUnit(unit));

  Future<void> setCurrency(RegionalPreferences current, String code) => _save(current.withCurrency(code));
}

final regionActionsProvider = Provider<RegionActions>(RegionActions.new);
