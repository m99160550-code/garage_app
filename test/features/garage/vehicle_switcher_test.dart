import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/vehicles/presentation/vehicles_screen.dart';
import 'package:tdc_garage/features/garage/application/vehicle_switcher_data.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/garage/presentation/vehicle_switcher_sheet.dart';
import 'package:tdc_garage/features/maintenance/domain/item_due.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_item.dart';
import 'package:tdc_garage/features/maintenance/domain/severity.dart';
import 'package:tdc_garage/features/onboarding/presentation/brand/brand_selection_screen.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/distance_unit.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';
import 'package:tdc_garage/features/vehicles/domain/body_type.dart';
import 'package:tdc_garage/features/vehicles/domain/fuel_type.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

/// A garage of [count] simple cars after the two sample ones.
MockGarageRepository _bigGarage(int count) {
  final garage = MockGarageRepository.forScenario('returning', now: _now);
  for (var i = 0; i < count - 2; i++) {
    garage.addVehicle(
      Vehicle(
        id: 'veh-$i',
        brandOtherName: 'Car',
        modelOtherName: '$i',
        fuelType: FuelType.petrol,
        bodyType: BodyType.hatchback,
        odometerKm: 1000,
      ),
      const [],
    );
  }
  return garage;
}

Future<MockSessionRepository> _openSwitcher(
  WidgetTester tester, {
  MockGarageRepository? garage,
  Size? screen,
  String? language,
}) async {
  screen == null ? usePhoneScreen(tester) : useScreen(tester, screen);
  final session = MockSessionRepository(scenario: 'returning');
  await tester.pumpWidget(
    buildTestApp(
      session,
      overrides: [
        garageRepositoryProvider.overrideWithValue(garage ?? MockGarageRepository.forScenario('returning', now: _now)),
        clockProvider.overrideWithValue(() => _now),
        preferencesRepositoryProvider.overrideWithValue(
          MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA', currency: 'SAR')),
        ),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  await tester.tap(find.bySemanticsLabel(RegExp(r'switch vehicle$|تبديل السيارة$')));
  await tester.pumpAndSettle();
  expect(find.byType(VehicleSwitcherSheet), findsOneWidget);
  return session;
}

ScheduleItem _item(String code, {DateTime? done}) => ScheduleItem(
  id: code,
  vehicleId: 'v',
  code: code,
  nameEn: code,
  nameAr: code,
  severity: Severity.major,
  intervalMonths: 12,
  lastDoneDate: done,
);

ItemDue _due(ScheduleItem item) => computeItemDue(item, currentKm: 0, today: _now, unit: DistanceUnit.km);

void main() {
  group('the badge shows the worst state', () {
    test('overdue count, then due soon, then all good; nothing known is "not set up"', () {
      final overdue = _due(_item('a', done: DateTime(2025, 9, 1)));
      final soon = _due(_item('b', done: DateTime(2025, 11, 20)));
      final ok = _due(_item('c', done: DateTime(2026, 6, 1)));
      final unknown = _due(_item('d'));
      expect((vehicleStatusFrom([overdue, soon, overdue]) as VehicleOverdue).count, 2);
      expect(vehicleStatusFrom([ok, soon, unknown]), isA<VehicleDueSoon>());
      expect(vehicleStatusFrom([ok, unknown]), isA<VehicleAllGood>());
      expect(vehicleStatusFrom([unknown]), isA<VehicleNotSetUp>());
    });
  });

  testWidgets('lists the cars with their state; the current one is marked', (tester) async {
    await _openSwitcher(tester);
    expect(find.text('Your garage'), findsOneWidget);
    expect(find.textContaining('of 25 vehicles'), findsNothing, reason: 'count only above 10');
    expect(find.bySemanticsLabel('Family Camry, Camry · 2022, Due soon, Current vehicle'), findsOneWidget);
    expect(find.bySemanticsLabel('Nissan Patrol, Patrol · 2019, 2 overdue'), findsOneWidget);
    expect(find.text('Add vehicle'), findsOneWidget);
    expect(find.text('Manage vehicles'), findsOneWidget);
  });

  testWidgets('tapping a car shows it and remembers it (BR-VEH-05)', (tester) async {
    final session = await _openSwitcher(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Nissan Patrol')));
    await tester.pumpAndSettle();

    expect(find.byType(VehicleSwitcherSheet), findsNothing);
    expect(find.text('Patrol · 2019'), findsOneWidget);
    expect((await tester.runAsync(session.load))!.lastVehicleId, 'veh-patrol');
  });

  testWidgets('Add vehicle opens brand selection in "adding" mode', (tester) async {
    await _openSwitcher(tester);
    await tester.tap(find.text('Add vehicle'));
    await tester.pumpAndSettle();
    final brand = tester.widget<BrandSelectionScreen>(find.byType(BrandSelectionScreen));
    expect(brand.addingVehicle, isTrue);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('Manage vehicles opens the vehicle list (S-32)', (tester) async {
    await _openSwitcher(tester);
    await tester.tap(find.text('Manage vehicles'));
    await tester.pumpAndSettle();
    expect(find.byType(VehiclesScreen), findsOneWidget);
  });

  testWidgets('above 10 cars the count shows', (tester) async {
    await _openSwitcher(tester, garage: _bigGarage(12));
    expect(find.text('12 of 25 vehicles'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Car 0, 0, Not set up$')), findsOneWidget);
  });

  testWidgets('at 25 cars, Add is disabled with an explanation (BR-VEH-01)', (tester) async {
    await _openSwitcher(tester, garage: _bigGarage(25));
    final add = find.bySemanticsLabel('Add vehicle, Limit reached. Contact support.');
    await tester.scrollUntilVisible(
      find.text('Add vehicle'),
      300,
      scrollable: find.descendant(of: find.byType(VehicleSwitcherSheet), matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
    expect(add, findsOneWidget);
    await tester.tap(add, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(BrandSelectionScreen), findsNothing);
  });

  testWidgets('tablet: a 400 pt panel', (tester) async {
    await _openSwitcher(tester, screen: const Size(1024, 768));
    expect(tester.getSize(find.byType(VehicleSwitcherSheet)).width, lessThanOrEqualTo(400));
  });

  testWidgets('Arabic: translated, right to left', (tester) async {
    await _openSwitcher(tester, language: 'ar');
    expect(find.text('كراجك'), findsOneWidget);
    expect(find.text('إضافة سيارة'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(VehicleSwitcherSheet))), TextDirection.rtl);
  });

  testWidgets('large text does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openSwitcher(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    await _openSwitcher(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
