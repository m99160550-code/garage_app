import 'package:flutter/foundation.dart';

import '../../../core/format/app_formatters.dart';

import '../../reference/domain/country.dart';
import 'distance_unit.dart';

/// Country, currency and distance unit, plus whether the user set each one
/// by hand (architecture `user_settings`, BR-SET-08 and BR-SET-09).
@immutable
class RegionalPreferences {
  const RegionalPreferences({
    this.countryCode,
    this.currency = fallbackCurrency,
    this.currencySetByUser = false,
    this.distanceUnit = DistanceUnit.km,
    this.distanceUnitSetByUser = false,
    this.analyticsEnabled = true,
    this.digitStyle = DigitStyle.western,
  });

  /// Defaults when no country is set (BR-SET-01).
  static const fallbackCurrency = 'USD';

  /// `null` means "Not set" (BR-SET-07).
  final String? countryCode;
  final String currency;
  final bool currencySetByUser;
  final DistanceUnit distanceUnit;
  final bool distanceUnitSetByUser;

  /// Analytics on/off. Off until consent where consent is required,
  /// otherwise on with an opt-out (BR-PRV-01).
  final bool analyticsEnabled;

  /// Western (default) or Arabic-Indic digits (FR-SET-13).
  final DigitStyle digitStyle;

  /// Applies a country's presets. Values the user set by hand are never
  /// overwritten (BR-SET-09). Passing `null` means "Other / not set".
  RegionalPreferences withCountry(Country? country) => RegionalPreferences(
    countryCode: country?.code,
    currency: currencySetByUser ? currency : (country?.defaultCurrency ?? fallbackCurrency),
    currencySetByUser: currencySetByUser,
    distanceUnit: distanceUnitSetByUser ? distanceUnit : (country?.defaultDistanceUnit ?? DistanceUnit.km),
    distanceUnitSetByUser: distanceUnitSetByUser,
    analyticsEnabled: analyticsEnabled,
    digitStyle: digitStyle,
  );

  RegionalPreferences withAnalytics({required bool enabled}) => RegionalPreferences(
    countryCode: countryCode,
    currency: currency,
    currencySetByUser: currencySetByUser,
    distanceUnit: distanceUnit,
    distanceUnitSetByUser: distanceUnitSetByUser,
    analyticsEnabled: enabled,
    digitStyle: digitStyle,
  );

  RegionalPreferences _copy({
    String? countryCode,
    bool clearCountry = false,
    String? currency,
    bool? currencySetByUser,
    DistanceUnit? distanceUnit,
    bool? distanceUnitSetByUser,
    DigitStyle? digitStyle,
  }) => RegionalPreferences(
    countryCode: clearCountry ? null : (countryCode ?? this.countryCode),
    currency: currency ?? this.currency,
    currencySetByUser: currencySetByUser ?? this.currencySetByUser,
    distanceUnit: distanceUnit ?? this.distanceUnit,
    distanceUnitSetByUser: distanceUnitSetByUser ?? this.distanceUnitSetByUser,
    analyticsEnabled: analyticsEnabled,
    digitStyle: digitStyle ?? this.digitStyle,
  );

  /// The values a country change would switch (FR-SET-16, BR-SET-09):
  /// only those not set by hand and different from now. Both `null`
  /// means no prompt is needed.
  ({String? currency, DistanceUnit? unit}) switchesFor(Country? country) {
    final newCurrency = country?.defaultCurrency ?? fallbackCurrency;
    final newUnit = country?.defaultDistanceUnit ?? DistanceUnit.km;
    return (
      currency: !currencySetByUser && newCurrency != currency ? newCurrency : null,
      unit: !distanceUnitSetByUser && newUnit != distanceUnit ? newUnit : null,
    );
  }

  /// "Keep current": the country changes, currency and unit stay.
  RegionalPreferences withCountryOnly(Country? country) =>
      country == null ? _copy(clearCountry: true) : _copy(countryCode: country.code);

  /// Picked on S-25: marked as set by hand, so a country change never
  /// overrides it (BR-SET-09).
  RegionalPreferences withDistanceUnit(DistanceUnit unit) => _copy(distanceUnit: unit, distanceUnitSetByUser: true);

  RegionalPreferences withCurrency(String code) => _copy(currency: code, currencySetByUser: true);

  RegionalPreferences withDigitStyle(DigitStyle style) => _copy(digitStyle: style);
}
