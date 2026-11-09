import '../../../core/text/digits.dart';
import '../../settings/domain/distance_unit.dart';

/// Kilometres in one mile.
const kmPerMile = 1.609344;

/// Highest believable odometer reading (architecture 2.7 CHECK 0–2,000,000).
const maxOdometerKm = 2000000;

/// Converts a distance typed in the user's unit to whole kilometres.
int toKilometres(int value, DistanceUnit unit) => unit == DistanceUnit.km ? value : (value * kmPerMile).round();

/// Converts stored kilometres back to the user's unit for display.
int fromKilometres(int km, DistanceUnit unit) => unit == DistanceUnit.km ? km : (km / kmPerMile).round();

enum OdometerIssue { missing, notANumber, tooHigh }

/// Checks the current-odometer field (spec S-06 "Validation").
OdometerIssue? checkOdometer(String input, DistanceUnit unit) {
  if (input.trim().isEmpty) return OdometerIssue.missing;
  final value = parseWholeNumber(input);
  if (value == null) return OdometerIssue.notANumber;
  if (toKilometres(value, unit) > maxOdometerKm) return OdometerIssue.tooHigh;
  return null;
}

enum VinIssue {
  /// Contains I, O or Q, which VINs never use. Blocks saving.
  invalidCharacters,

  /// Not 17 characters. A warning only: pre-1981 VINs are shorter
  /// (BR-VEH-02).
  unusualLength,
}

/// Checks an optional VIN. Empty is fine.
VinIssue? checkVin(String input) {
  final vin = input.trim().toUpperCase();
  if (vin.isEmpty) return null;
  if (RegExp('[IOQ]').hasMatch(vin) || !RegExp(r'^[A-Z0-9]+$').hasMatch(vin)) {
    return VinIssue.invalidCharacters;
  }
  if (vin.length != 17) return VinIssue.unusualLength;
  return null;
}
