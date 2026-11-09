import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/maintenance/data/template_repository.dart';
import 'package:tdc_garage/features/maintenance/domain/baseline_group.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_rules.dart';
import 'package:tdc_garage/features/maintenance/domain/vehicle_setup.dart';
import 'package:tdc_garage/features/notifications/application/reminder_primer_service.dart';
import 'package:tdc_garage/features/notifications/data/notification_permission_repository.dart';
import 'package:tdc_garage/features/notifications/domain/notification_permission.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/application/vehicle_names.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';
import 'package:tdc_garage/features/vehicles/domain/body_type.dart';
import 'package:tdc_garage/features/vehicles/domain/fuel_type.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle.dart';

const _camry = Vehicle(
  id: 'v1',
  brandId: 'toyota',
  modelId: 'toyota-camry',
  fuelType: FuelType.petrol,
  bodyType: BodyType.sedan,
  odometerKm: 54320,
);

Future<GarageRepository> _garageWith(Vehicle vehicle, VehicleSetup setup) async {
  final garage = MockGarageRepository();
  await garage.addVehicle(
    vehicle,
    generateSchedule(vehicleId: vehicle.id, template: MockTemplateRepository.templates[FuelType.petrol]!, setup: setup),
  );
  return garage;
}

final _oilKnown = BaselineSetup({BaselineGroup.oilService: BaselineAnswer(km: 49800)});
const _allUnknown = BaselineSetup({});

void main() {
  late MockNotificationPermissionRepository permission;

  Future<ProviderContainer> containerWith(
    VehicleSetup setup, {
    Vehicle vehicle = _camry,
    NotificationPermission initial = NotificationPermission.notDetermined,
    NotificationPermission answer = NotificationPermission.granted,
  }) async {
    permission = MockNotificationPermissionRepository(initial: initial, answer: answer);
    final garage = await _garageWith(vehicle, setup);
    final container = ProviderContainer(
      overrides: [
        notificationPermissionRepositoryProvider.overrideWithValue(permission),
        garageRepositoryProvider.overrideWithValue(garage),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('when the primer is offered after setup (FR-USR-08)', () {
    test('a vehicle with a reminder and an unasked permission gets the offer', () async {
      final container = await containerWith(_oilKnown);
      final offer = await container.read(reminderPrimerServiceProvider).offerAfterSetup('v1', 'en');
      expect(offer, isNotNull);
      expect(offer!.vehicleName, 'Toyota Camry');
      expect(offer.itemName, 'Engine oil');
      expect(offer.permission, NotificationPermission.notDetermined);
    });

    test('nothing to remind about: no offer', () async {
      final container = await containerWith(_allUnknown);
      expect(await container.read(reminderPrimerServiceProvider).offerAfterSetup('v1', 'en'), isNull);
    });

    test('permission already granted or declined: no automatic offer', () async {
      for (final state in [NotificationPermission.granted, NotificationPermission.denied]) {
        final container = await containerWith(_oilKnown, initial: state);
        expect(await container.read(reminderPrimerServiceProvider).offerAfterSetup('v1', 'en'), isNull);
      }
    });

    test('offered only once', () async {
      final container = await containerWith(_oilKnown);
      final service = container.read(reminderPrimerServiceProvider);
      await service.dismiss();
      expect(await service.offerAfterSetup('v1', 'en'), isNull);
    });

    test('the Profile entry works even with nothing known yet', () async {
      final container = await containerWith(_allUnknown, initial: NotificationPermission.denied);
      final offer = await container.read(reminderPrimerServiceProvider).offerFor('v1', 'ar');
      expect(offer!.itemName, isNull, reason: 'the sheet uses its fallback example');
      expect(offer.vehicleName, 'تويوتا كامري');
      expect(offer.permission, NotificationPermission.denied);
    });
  });

  group('Turn on reminders', () {
    test('asks the system once and reports the answer', () async {
      final container = await containerWith(_oilKnown);
      expect(await container.read(reminderPrimerServiceProvider).turnOn(), PrimerResult.granted);
      expect(permission.requestCount, 1);
      expect(await permission.status(), NotificationPermission.granted);
    });

    test('a declined prompt is reported as denied', () async {
      final container = await containerWith(_oilKnown, answer: NotificationPermission.denied);
      expect(await container.read(reminderPrimerServiceProvider).turnOn(), PrimerResult.denied);
    });

    test('declined before: opens Settings instead of prompting', () async {
      final container = await containerWith(_oilKnown, initial: NotificationPermission.denied);
      expect(await container.read(reminderPrimerServiceProvider).turnOn(), PrimerResult.openedSettings);
      expect(permission.requestCount, 0);
      expect(permission.settingsOpened, 1);
    });
  });

  group('vehicle names', () {
    test('nickname first, then brand and model, then typed names', () async {
      final named = await containerWith(
        _allUnknown,
        vehicle: const Vehicle(
          id: 'v1',
          nickname: 'Family Camry',
          brandId: 'toyota',
          modelId: 'toyota-camry',
          fuelType: FuelType.petrol,
          bodyType: BodyType.sedan,
          odometerKm: 0,
        ),
      );
      expect(
        await named.read(vehicleDisplayNameProvider((vehicleId: 'v1', languageCode: 'en')).future),
        'Family Camry',
      );

      final typed = await containerWith(
        _allUnknown,
        vehicle: const Vehicle(
          id: 'v1',
          brandOtherName: 'Proton',
          modelOtherName: 'Saga',
          fuelType: FuelType.petrol,
          bodyType: BodyType.sedan,
          odometerKm: 0,
        ),
      );
      expect(await typed.read(vehicleDisplayNameProvider((vehicleId: 'v1', languageCode: 'en')).future), 'Proton Saga');
    });
  });
}
