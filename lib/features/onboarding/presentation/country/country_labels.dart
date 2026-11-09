import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../reference/domain/country.dart';
import '../../../settings/domain/distance_unit.dart';
import '../../../settings/domain/regional_preferences.dart';

/// "Popular brands" / "Gulf brands" / "Egypt brands".
String popularListLabel(AppLocalizations l10n, PopularListCode code) => switch (code) {
  PopularListCode.standard => l10n.popularListStandard,
  PopularListCode.gulf => l10n.popularListGulf,
  PopularListCode.egypt => l10n.popularListEgypt,
};

String distanceUnitLabel(AppLocalizations l10n, DistanceUnit unit) => switch (unit) {
  DistanceUnit.km => l10n.unitKm,
  DistanceUnit.mi => l10n.unitMi,
};

/// The presets line under the country, for example "SAR · km · Gulf brands"
/// (spec S-03, item 3).
String countryPresetsLine(AppLocalizations l10n, RegionalPreferences preferences, Country? country) => [
  preferences.currency,
  distanceUnitLabel(l10n, preferences.distanceUnit),
  popularListLabel(l10n, country?.popularList ?? PopularListCode.standard),
].join(' · ');
