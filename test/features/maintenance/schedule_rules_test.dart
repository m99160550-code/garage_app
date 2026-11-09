import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/maintenance/data/template_repository.dart';
import 'package:tdc_garage/features/maintenance/domain/baseline_group.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_item.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_rules.dart';
import 'package:tdc_garage/features/maintenance/domain/vehicle_setup.dart';
import 'package:tdc_garage/features/vehicles/domain/fuel_type.dart';

final _petrol = MockTemplateRepository.templates[FuelType.petrol]!;

ScheduleItem _item(List<ScheduleItem> schedule, String code) => schedule.firstWhere((i) => i.code == code);

void main() {
  test('addMonths clamps to the end of shorter months', () {
    expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    expect(addMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
    expect(addMonths(DateTime(2026, 11, 15), 3), DateTime(2027, 2, 15));
    expect(addMonths(DateTime(2026, 5, 10), 24), DateTime(2028, 5, 10));
  });

  test('monthsBetween counts whole months only', () {
    expect(monthsBetween(DateTime(2023, 11, 7), DateTime(2026, 11, 7)), 36);
    expect(monthsBetween(DateTime(2026, 10, 8), DateTime(2026, 11, 7)), 0);
    expect(monthsBetween(DateTime(2026, 12, 1), DateTime(2026, 11, 7)), 0);
  });

  group('baseline (FR-MNT-03, FR-MNT-04)', () {
    test('answered groups set their items; everything else is Unknown', () {
      final schedule = generateSchedule(
        vehicleId: 'v1',
        template: _petrol,
        setup: BaselineSetup({
          BaselineGroup.oilService: BaselineAnswer(date: DateTime(2026, 6, 10), km: 49800),
          BaselineGroup.brakes: const BaselineAnswer.unknown(),
          BaselineGroup.tires: BaselineAnswer(date: DateTime(2025, 11, 2)),
        }),
      );

      expect(schedule, hasLength(_petrol.items.length));
      final oil = _item(schedule, 'engine_oil');
      expect(oil.lastDoneDate, DateTime(2026, 6, 10));
      expect(oil.lastDoneKm, 49800);
      expect(oil.lastDoneSource, LastDoneSource.baseline);
      expect(_item(schedule, 'oil_filter').lastDoneKm, 49800, reason: 'same question');
      expect(_item(schedule, 'brake_pads').isUnknown, isTrue);
      expect(_item(schedule, 'tire_rotation').lastDoneKm, isNull);
      expect(_item(schedule, 'tire_rotation').isUnknown, isFalse, reason: 'a date alone is enough');
      expect(_item(schedule, 'battery').isUnknown, isTrue, reason: 'not answered');
      expect(_item(schedule, 'coolant').isUnknown, isTrue, reason: 'not asked in onboarding');
    });

    test('an answer with both fields empty counts as Unknown', () {
      expect(const BaselineAnswer().isUnknown, isTrue);
      final schedule = generateSchedule(
        vehicleId: 'v1',
        template: _petrol,
        setup: const BaselineSetup({BaselineGroup.battery: BaselineAnswer()}),
      );
      expect(_item(schedule, 'battery').isUnknown, isTrue);
    });

    test('all four unknown leaves every item Unknown (UC-01 8a)', () {
      final schedule = generateSchedule(
        vehicleId: 'v1',
        template: _petrol,
        setup: BaselineSetup({for (final g in BaselineGroup.values) g: const BaselineAnswer.unknown()}),
      );
      expect(schedule.every((i) => i.isUnknown), isTrue);
    });

    test('EVs answer "oil or service" with the general inspection', () {
      final schedule = generateSchedule(
        vehicleId: 'v1',
        template: MockTemplateRepository.templates[FuelType.ev]!,
        setup: BaselineSetup({BaselineGroup.oilService: BaselineAnswer(km: 12000)}),
      );
      expect(schedule.any((i) => i.code == 'engine_oil'), isFalse);
      expect(_item(schedule, 'inspection').lastDoneKm, 12000);
    });
  });

  group('My car is new (FR-MNT-15, BR-MNT-13)', () {
    test('every item starts from the delivery; nothing is Unknown', () {
      final schedule = generateSchedule(
        vehicleId: 'v1',
        template: _petrol,
        setup: NewCarSetup(deliveryDate: DateTime(2026, 9, 1), startingKm: 12),
      );
      expect(schedule.any((i) => i.isUnknown), isFalse);
      expect(schedule.every((i) => i.lastDoneSource == LastDoneSource.newCar), isTrue);
      expect(schedule.every((i) => i.lastDoneDate == DateTime(2026, 9, 1) && i.lastDoneKm == 12), isTrue);
    });

    test('a recent delivery has nothing due', () {
      final due = itemsDueSinceDelivery(
        template: _petrol,
        setup: NewCarSetup(deliveryDate: DateTime(2026, 9, 1), startingKm: 12),
        currentOdometerKm: 3000,
        today: DateTime(2026, 11, 7),
      );
      expect(due, isEmpty);
    });

    test('a delivery 7 months ago makes 6-month items due', () {
      final due = itemsDueSinceDelivery(
        template: _petrol,
        setup: NewCarSetup(deliveryDate: DateTime(2026, 4, 1), startingKm: 0),
        currentOdometerKm: 3000,
        today: DateTime(2026, 11, 7),
      );
      expect(due.map((i) => i.code), ['tire_rotation']);
    });

    test('distance driven since delivery also counts', () {
      final due = itemsDueSinceDelivery(
        template: _petrol,
        setup: NewCarSetup(deliveryDate: DateTime(2026, 10, 1), startingKm: 0),
        currentOdometerKm: 10000,
        today: DateTime(2026, 11, 7),
      );
      expect(due.map((i) => i.code), containsAll(['engine_oil', 'oil_filter', 'tire_rotation']));
    });
  });
}
