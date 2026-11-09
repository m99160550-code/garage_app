import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_item.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_rules.dart';
import 'package:tdc_garage/features/onboarding/presentation/baseline/service_baseline_screen.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/distance_unit.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/application/vehicle_draft_controller.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';
import 'package:tdc_garage/features/vehicles/domain/body_type.dart';
import 'package:tdc_garage/features/vehicles/domain/fuel_type.dart';
import 'package:tdc_garage/features/vehicles/domain/paint_color.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle_details.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle_draft.dart';

import '../../helpers/test_app.dart';

const _camry = VehicleDraft(
  brandId: 'toyota',
  modelId: 'toyota-camry',
  bodyType: BodyType.sedan,
  details: VehicleDetails(
    fuelType: FuelType.petrol,
    odometerKm: 54320,
    paint: PaintColor.silver,
    bodyType: BodyType.sedan,
  ),
);

class _SeededDraft extends VehicleDraftController {
  _SeededDraft(this.seed);

  final VehicleDraft seed;

  @override
  VehicleDraft build() => seed;
}

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

class _Opened {
  _Opened(this.session, this.garage, this.container);

  final MockSessionRepository session;
  final MockGarageRepository garage;
  final ProviderContainer container;

  VehicleDraft get draft => container.read(vehicleDraftProvider);
}

Future<_Opened> _openBaseline(
  WidgetTester tester, {
  VehicleDraft draft = _camry,
  Size? screen,
  String? language,
  DateTime Function()? clock,
}) async {
  screen == null ? usePhoneScreen(tester) : useScreen(tester, screen);
  final session = MockSessionRepository(scenario: 'baselineStep');
  final garage = MockGarageRepository();
  await tester.pumpWidget(
    buildTestApp(
      session,
      overrides: [
        vehicleDraftProvider.overrideWith(() => _SeededDraft(draft)),
        preferencesRepositoryProvider.overrideWithValue(
          MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA', distanceUnit: DistanceUnit.km)),
        ),
        garageRepositoryProvider.overrideWithValue(garage),
        if (clock != null) clockProvider.overrideWithValue(clock),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  expect(find.byType(ServiceBaselineScreen), findsOneWidget);
  final container = ProviderScope.containerOf(tester.element(find.byType(ServiceBaselineScreen)));
  return _Opened(session, garage, container);
}

Finder get _save => find.widgetWithText(TextButton, 'Save vehicle');

/// The mileage field inside the card for [item].
Finder _mileageIn(String item) => find.descendant(
  of: find.bySemanticsLabel('$item, last done'),
  matching: find.widgetWithText(TextFormField, 'Mileage'),
);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _saveVehicle(WidgetTester tester) async {
  await tester.tap(_save);
  await tester.pumpAndSettle();
}

Future<List<ScheduleItem>> _savedSchedule(WidgetTester tester, _Opened opened) async {
  final vehicles = (await tester.runAsync(opened.garage.vehicles))!;
  expect(vehicles, hasLength(1));
  return (await tester.runAsync(() => opened.garage.schedule(vehicles.single.id)))!;
}

void main() {
  testWidgets('shows the question, the new-car card and the four items', (tester) async {
    await _openBaseline(tester);
    expect(find.text('When were these last done?'), findsOneWidget);
    expect(find.text('My car is new'), findsOneWidget);
    for (final item in ['Oil change or service', 'Brakes', 'Tires', 'Battery']) {
      expect(find.text(item), findsOneWidget);
    }
    expect(tester.widget<TextButton>(_save).onPressed, isNotNull, reason: 'always enabled (UC-01 8a)');
  });

  testWidgets('saving with nothing filled in makes every item Unknown and opens the dashboard', (tester) async {
    final opened = await _openBaseline(tester);
    await _saveVehicle(tester);

    expect(find.byType(DashboardScreen), findsOneWidget);
    final schedule = await _savedSchedule(tester, opened);
    expect(schedule.every((item) => item.isUnknown), isTrue);
    final session = (await tester.runAsync(opened.session.load))!;
    expect(session.vehicleCount, 1);
    expect(session.setupDraftStep, isNull, reason: 'setup finished');
    expect(opened.draft.hasBrand, isFalse, reason: 'draft cleared');
  });

  testWidgets('a mileage above the current odometer is an error and blocks saving', (tester) async {
    await _openBaseline(tester);
    await tester.enterText(_mileageIn('Brakes'), '60000');
    await tester.pumpAndSettle();
    expect(find.text("Can't be more than your current mileage (54,320 km)."), findsOneWidget);

    await _saveVehicle(tester);
    expect(find.byType(ServiceBaselineScreen), findsOneWidget);
  });

  testWidgets('a date and mileage are saved for the items in that group', (tester) async {
    final opened = await _openBaseline(tester);
    await tester.enterText(_mileageIn('Oil change or service'), '49800');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextFormField, 'Date').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    await _saveVehicle(tester);
    final schedule = await _savedSchedule(tester, opened);
    final oil = schedule.firstWhere((i) => i.code == 'engine_oil');
    expect(oil.lastDoneKm, 49800);
    expect(oil.lastDoneDate, DateUtils.dateOnly(DateTime.now()));
    expect(schedule.firstWhere((i) => i.code == 'oil_filter').lastDoneKm, 49800);
    expect(schedule.firstWhere((i) => i.code == 'brake_pads').isUnknown, isTrue);
  });

  testWidgets('"I don\'t know" disables the fields, shows Unknown and wins over typed values', (tester) async {
    final opened = await _openBaseline(tester);
    await tester.enterText(_mileageIn('Battery'), '40000');
    await tester.pumpAndSettle();
    final battery = find.bySemanticsLabel('Battery, last done');
    await _tapVisible(tester, find.descendant(of: battery, matching: find.text("I don't know")));

    expect(find.descendant(of: battery, matching: find.text('Unknown')), findsOneWidget);
    final field = tester.widget<TextField>(
      find.descendant(of: _mileageIn('Battery'), matching: find.byType(TextField)),
    );
    expect(field.enabled, isFalse);

    await _saveVehicle(tester);
    final schedule = await _savedSchedule(tester, opened);
    expect(schedule.firstWhere((i) => i.code == 'battery').isUnknown, isTrue);
  });

  testWidgets('My car is new: needs a delivery date, then starts everything fresh', (tester) async {
    final opened = await _openBaseline(tester);
    await tester.tap(find.text('My car is new'));
    await tester.pumpAndSettle();

    expect(find.text('All items start from your delivery date. Your score starts at 100.'), findsOneWidget);
    expect(find.text('Brakes'), findsNothing, reason: 'item cards are replaced');
    expect(find.text('54,320'), findsOneWidget, reason: 'starting mileage prefilled (BR-MNT-12)');

    await _saveVehicle(tester);
    expect(find.text('Choose your delivery date'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextFormField, 'Delivery date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Starting mileage'), '54000');
    await tester.pumpAndSettle();
    await _saveVehicle(tester);

    expect(find.byType(DashboardScreen), findsOneWidget);
    final vehicle = (await tester.runAsync(opened.garage.vehicles))!.single;
    final today = DateUtils.dateOnly(DateTime.now());
    expect(vehicle.setupMode, SetupMode.newCar);
    expect(vehicle.purchaseDate, today, reason: 'purchase date defaults to delivery (BR-MNT-12)');
    final schedule = await _savedSchedule(tester, opened);
    expect(schedule.any((i) => i.isUnknown), isFalse);
    expect(schedule.every((i) => i.lastDoneKm == 54000 && i.lastDoneDate == today), isTrue);
  });

  testWidgets('starting mileage above the odometer is an error (BR-MNT-12)', (tester) async {
    await _openBaseline(tester);
    await tester.tap(find.text('My car is new'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Starting mileage'), '99999');
    await tester.pumpAndSettle();
    expect(find.text("Can't be more than your current mileage (54,320 km)."), findsOneWidget);
  });

  testWidgets('an old delivery date asks first, and Keep this date saves (BR-MNT-13)', (tester) async {
    // "Today" in the picker is the real date; the app's clock is 37 months
    // later, so that delivery is 3 years ago.
    final later = addMonths(DateTime.now(), 37);
    final opened = await _openBaseline(tester, clock: () => later);
    await tester.tap(find.text('My car is new'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextFormField, 'Delivery date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    await _saveVehicle(tester);
    expect(find.text('Some items may already be due'), findsOneWidget);
    expect(find.textContaining('3 years ago'), findsOneWidget);

    await tester.tap(find.text('Keep this date'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect((await tester.runAsync(opened.garage.vehicles))!, hasLength(1));
  });

  testWidgets('Change date reopens the calendar instead of saving', (tester) async {
    final opened = await _openBaseline(tester);
    await tester.tap(find.text('My car is new'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextFormField, 'Delivery date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    // Driven 54,320 km since delivery: the distance intervals are past.
    await tester.enterText(find.widgetWithText(TextFormField, 'Starting mileage'), '0');
    await tester.pumpAndSettle();

    await _saveVehicle(tester);
    expect(find.textContaining('driven past some intervals'), findsOneWidget);
    await tester.tap(find.text('Change date'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    expect((await tester.runAsync(opened.garage.vehicles))!, isEmpty);
  });

  testWidgets('without the car details it sends the user back', (tester) async {
    await _openBaseline(tester, draft: const VehicleDraft(brandId: 'toyota'));
    expect(find.text("Add your car's details first"), findsOneWidget);
  });

  testWidgets('Arabic: right to left with translated items', (tester) async {
    await _openBaseline(tester, language: 'ar');
    expect(find.text('متى تمت هذه آخر مرة؟'), findsOneWidget);
    expect(find.text('الفرامل'), findsOneWidget);
    expect(find.text('حفظ السيارة'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(ServiceBaselineScreen))), TextDirection.rtl);
  });

  testWidgets('tablets show the items in a 2 × 2 grid', (tester) async {
    await _openBaseline(tester, screen: const Size(1024, 768));
    final oil = tester.getTopLeft(find.bySemanticsLabel('Oil change or service, last done'));
    final brakes = tester.getTopLeft(find.bySemanticsLabel('Brakes, last done'));
    final tires = tester.getTopLeft(find.bySemanticsLabel('Tires, last done'));
    expect(brakes.dy, oil.dy, reason: 'same row');
    expect(brakes.dx, greaterThan(oil.dx));
    expect(tires.dy, greaterThan(oil.dy), reason: 'next row');
  });

  testWidgets('large text does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openBaseline(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('My car is new'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    await _openBaseline(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
