import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/settings/domain/distance_unit.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle_validation.dart';

void main() {
  group('odometer (spec S-06 validation)', () {
    test('required and numeric', () {
      expect(checkOdometer('', DistanceUnit.km), OdometerIssue.missing);
      expect(checkOdometer('  ', DistanceUnit.km), OdometerIssue.missing);
      expect(checkOdometer('12x', DistanceUnit.km), OdometerIssue.notANumber);
      expect(checkOdometer('54,320', DistanceUnit.km), isNull);
      expect(checkOdometer('0', DistanceUnit.km), isNull);
    });

    test('at most 2,000,000 km, in either unit', () {
      expect(checkOdometer('2,000,000', DistanceUnit.km), isNull);
      expect(checkOdometer('2,000,001', DistanceUnit.km), OdometerIssue.tooHigh);
      expect(checkOdometer('1,242,000', DistanceUnit.mi), isNull);
      expect(checkOdometer('1,300,000', DistanceUnit.mi), OdometerIssue.tooHigh);
    });

    test('miles are stored as kilometres and shown back unchanged', () {
      expect(toKilometres(10000, DistanceUnit.mi), 16093);
      expect(toKilometres(10000, DistanceUnit.km), 10000);
      expect(fromKilometres(16093, DistanceUnit.mi), 10000);
    });
  });

  group('VIN (BR-VEH-02)', () {
    test('empty is fine because the VIN is optional', () {
      expect(checkVin(''), isNull);
    });

    test('a 17-character VIN without I, O or Q is valid', () {
      expect(checkVin('4T1C11AK5NU123456'), isNull);
      expect(checkVin('4t1c11ak5nu123456'), isNull, reason: 'case-insensitive');
    });

    test('I, O or Q block saving', () {
      expect(checkVin('4T1C11AK5NU12345O'), VinIssue.invalidCharacters);
      expect(checkVin('ABCI'), VinIssue.invalidCharacters);
    });

    test('other lengths only warn (pre-1981 VINs)', () {
      expect(checkVin('WDB12345678'), VinIssue.unusualLength);
    });
  });
}
