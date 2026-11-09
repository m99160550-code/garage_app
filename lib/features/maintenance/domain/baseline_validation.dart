import '../../../core/text/digits.dart';
import '../../settings/domain/distance_unit.dart';
import '../../vehicles/domain/vehicle_validation.dart';

enum BaselineKmIssue { notANumber, aboveOdometer }

/// Checks a baseline or starting mileage typed in the user's unit
/// (UC-01 8b, BR-MNT-12). Empty is fine: the field is optional.
BaselineKmIssue? checkBaselineKm(String input, DistanceUnit unit, int currentOdometerKm) {
  if (input.trim().isEmpty) return null;
  final value = parseWholeNumber(input);
  if (value == null) return BaselineKmIssue.notANumber;
  // Compare in the user's unit, so a value equal to the odometer shown on
  // the previous screen is never rejected by a rounding difference.
  if (value > fromKilometres(currentOdometerKm, unit)) return BaselineKmIssue.aboveOdometer;
  return null;
}

/// The typed mileage in kilometres, or `null` when empty or invalid.
/// A value equal to the odometer in miles maps back to the exact odometer.
int? baselineKmFrom(String input, DistanceUnit unit, int currentOdometerKm) {
  final value = parseWholeNumber(input);
  if (value == null) return null;
  if (value == fromKilometres(currentOdometerKm, unit)) return currentOdometerKm;
  return toKilometres(value, unit);
}
