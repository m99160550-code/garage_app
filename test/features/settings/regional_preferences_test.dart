import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/reference/domain/country.dart';
import 'package:tdc_garage/features/settings/domain/distance_unit.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';

const _saudi = Country(
  code: 'SA',
  nameEn: 'Saudi Arabia',
  nameAr: 'السعودية',
  defaultCurrency: 'SAR',
  defaultDistanceUnit: DistanceUnit.km,
  popularList: PopularListCode.gulf,
);

const _uk = Country(
  code: 'GB',
  nameEn: 'United Kingdom',
  nameAr: 'المملكة المتحدة',
  defaultCurrency: 'GBP',
  defaultDistanceUnit: DistanceUnit.mi,
);

void main() {
  test('a country presets currency and distance unit', () {
    final prefs = const RegionalPreferences().withCountry(_uk);
    expect(prefs.countryCode, 'GB');
    expect(prefs.currency, 'GBP');
    expect(prefs.distanceUnit, DistanceUnit.mi);
  });

  test('"Other / not set" falls back to USD and km (BR-SET-01)', () {
    final prefs = const RegionalPreferences().withCountry(_uk).withCountry(null);
    expect(prefs.countryCode, isNull);
    expect(prefs.currency, 'USD');
    expect(prefs.distanceUnit, DistanceUnit.km);
  });

  test('values set by hand are never overwritten (BR-SET-09)', () {
    const handSet = RegionalPreferences(
      currency: 'EGP',
      currencySetByUser: true,
      distanceUnit: DistanceUnit.mi,
      distanceUnitSetByUser: true,
    );
    final prefs = handSet.withCountry(_saudi);
    expect(prefs.countryCode, 'SA');
    expect(prefs.currency, 'EGP');
    expect(prefs.distanceUnit, DistanceUnit.mi);
  });

  test('only the value set by hand is kept', () {
    const handSet = RegionalPreferences(currency: 'EGP', currencySetByUser: true);
    final prefs = handSet.withCountry(_uk);
    expect(prefs.currency, 'EGP');
    expect(prefs.distanceUnit, DistanceUnit.mi);
  });
}
