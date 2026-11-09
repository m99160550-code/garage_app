import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/mileage/domain/mileage_rules.dart';
import 'package:tdc_garage/features/mileage/domain/odometer_reading.dart';
import 'package:tdc_garage/features/settings/domain/distance_unit.dart';

final _today = DateTime(2026, 11, 7);

OdometerReading _r(DateTime date, int km, {bool correction = false}) =>
    OdometerReading(id: '$date-$km', vehicleId: 'v', date: date, km: km, isCorrection: correction);

void main() {
  group('current reading (BR-MIL-01)', () {
    test('the latest date wins; on the same date the higher value', () {
      final readings = [
        _r(DateTime(2026, 11, 1), 50000),
        _r(DateTime(2026, 11, 5), 51000),
        _r(DateTime(2026, 11, 5), 51200),
      ];
      expect(currentReading(readings)!.km, 51200);
      expect(currentReading(const []), isNull);
    });

    test('a confirmed correction replaces the current value (BR-MIL-02)', () {
      final readings = [_r(DateTime(2026, 11, 7), 54320), _r(DateTime(2026, 11, 7), 53900, correction: true)];
      expect(currentReading(readings)!.km, 53900);
    });
  });

  group('checking a new reading', () {
    final current = _r(DateTime(2026, 11, 3), 54320);

    test('equal or higher at a normal pace is fine (UC-02 4c)', () {
      expect(checkNewReading(newKm: 54320, current: current, today: _today, unit: DistanceUnit.km), isA<ReadingOk>());
      expect(checkNewReading(newKm: 55000, current: current, today: _today, unit: DistanceUnit.km), isA<ReadingOk>());
    });

    test('lower asks for a correction (BR-MIL-02)', () {
      expect(
        checkNewReading(newKm: 53900, current: current, today: _today, unit: DistanceUnit.km),
        isA<ReadingLower>(),
      );
    });

    test('more than 5,000 km per day asks "Is this correct?" (BR-MIL-03)', () {
      final jump = checkNewReading(newKm: 80000, current: current, today: _today, unit: DistanceUnit.km);
      expect((jump as ReadingBigJump).km, 25680);
      expect(jump.days, 4);
      expect(checkNewReading(newKm: 74320, current: current, today: _today, unit: DistanceUnit.km), isA<ReadingOk>());
    });

    test('a reading on the same day counts as 1 day', () {
      final sameDay = _r(_today, 10000);
      final jump = checkNewReading(newKm: 16000, current: sameDay, today: _today, unit: DistanceUnit.km);
      expect((jump as ReadingBigJump).days, 1);
    });

    test('mile users get the 3,000 mi limit', () {
      final sameDay = _r(_today, 10000);
      expect(checkNewReading(newKm: 14800, current: sameDay, today: _today, unit: DistanceUnit.mi), isA<ReadingOk>());
      expect(
        checkNewReading(newKm: 14900, current: sameDay, today: _today, unit: DistanceUnit.mi),
        isA<ReadingBigJump>(),
      );
    });
  });

  group('days until an average', () {
    test('14 days after the first usable reading, or 0 once that has passed', () {
      expect(daysUntilAverage(const [], today: _today), 14);
      expect(daysUntilAverage([_r(DateTime(2026, 11, 3), 1000)], today: _today), 10);
      expect(daysUntilAverage([_r(DateTime(2026, 9, 1), 1000)], today: _today), 0);
    });
  });

  group('average daily distance (BR-MIL-05)', () {
    test('first and last readings in the last 180 days', () {
      final readings = [
        _r(DateTime(2026, 1, 1), 30000), // outside the window
        _r(DateTime(2026, 6, 1), 40000),
        _r(DateTime(2026, 11, 1), 46120),
      ];
      expect(averageDailyKm(readings, today: _today), closeTo(40, 0.01));
    });

    test('needs two readings at least 14 days apart', () {
      expect(averageDailyKm([_r(DateTime(2026, 11, 1), 1000)], today: _today), isNull);
      expect(
        averageDailyKm([_r(DateTime(2026, 10, 25), 1000), _r(DateTime(2026, 11, 7), 2000)], today: _today),
        isNull,
      );
    });

    test('a correction restarts the window', () {
      final readings = [
        _r(DateTime(2026, 8, 1), 40000),
        _r(DateTime(2026, 10, 1), 45000),
        _r(DateTime(2026, 10, 30), 44000, correction: true),
        _r(DateTime(2026, 11, 7), 44500),
      ];
      expect(averageDailyKm(readings, today: _today), isNull, reason: 'only 8 days since the correction');
    });
  });
}
