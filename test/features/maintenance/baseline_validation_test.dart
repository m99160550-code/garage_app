import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/maintenance/domain/baseline_validation.dart';
import 'package:tdc_garage/features/settings/domain/distance_unit.dart';

void main() {
  test('empty is fine: mileage is optional', () {
    expect(checkBaselineKm('', DistanceUnit.km, 54320), isNull);
    expect(baselineKmFrom('', DistanceUnit.km, 54320), isNull);
  });

  test('cannot be more than the current odometer (UC-01 8b, BR-MNT-12)', () {
    expect(checkBaselineKm('54,320', DistanceUnit.km, 54320), isNull);
    expect(checkBaselineKm('54,321', DistanceUnit.km, 54320), BaselineKmIssue.aboveOdometer);
  });

  test('miles compare in miles, and the odometer itself maps back exactly', () {
    // 16,093 km is shown as 10,000 mi on S-06.
    expect(checkBaselineKm('10,000', DistanceUnit.mi, 16093), isNull);
    expect(checkBaselineKm('10,001', DistanceUnit.mi, 16093), BaselineKmIssue.aboveOdometer);
    expect(baselineKmFrom('10,000', DistanceUnit.mi, 16093), 16093);
    expect(baselineKmFrom('5,000', DistanceUnit.mi, 16093), 8047);
  });
}
