import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/onboarding/presentation/baseline/service_baseline_screen.dart';
import 'package:tdc_garage/features/onboarding/presentation/details/vehicle_details_screen.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/session/domain/app_session.dart';
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
import 'package:tdc_garage/features/vehicles/domain/vehicle_details.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle_draft.dart';

import '../../helpers/test_app.dart';

const _camryDraft = VehicleDraft(brandId: 'toyota', modelId: 'toyota-camry', bodyType: BodyType.sedan);

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
  _Opened(this.session, this.container);

  final MockSessionRepository session;
  final ProviderContainer container;

  VehicleDraft get draft => container.read(vehicleDraftProvider);
}

Future<_Opened> _openDetails(
  WidgetTester tester, {
  VehicleDraft draft = _camryDraft,
  DistanceUnit unit = DistanceUnit.km,
  bool withGarage = false,
  Size? screen,
  String? language,
}) async {
  screen == null ? usePhoneScreen(tester) : useScreen(tester, screen);
  final session = MockSessionRepository(scenario: 'detailsStep');
  await tester.pumpWidget(
    buildTestApp(
      session,
      overrides: [
        vehicleDraftProvider.overrideWith(() => _SeededDraft(draft)),
        preferencesRepositoryProvider.overrideWithValue(
          MockPreferencesRepository(RegionalPreferences(countryCode: 'SA', distanceUnit: unit)),
        ),
        garageRepositoryProvider.overrideWithValue(
          MockGarageRepository(withGarage ? MockGarageRepository.sampleVehicles : const []),
        ),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  expect(find.byType(VehicleDetailsScreen), findsOneWidget);
  return _Opened(session, ProviderScope.containerOf(tester.element(find.byType(VehicleDetailsScreen))));
}

Finder get _continue => find.widgetWithText(TextButton, 'Continue');
bool _canContinue(WidgetTester tester) => tester.widget<TextButton>(_continue).onPressed != null;
Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _enterOdometer(WidgetTester tester, String value) async {
  await tester.enterText(_field('Current odometer'), value);
  await tester.pumpAndSettle();
}

Future<void> _openMoreDetails(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Add nickname, year, VIN and more'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add nickname, year, VIN and more'));
  await tester.pumpAndSettle();
}

Future<void> _enterVin(WidgetTester tester, String vin) async {
  await tester.ensureVisible(_field('VIN'));
  await tester.pumpAndSettle();
  await tester.enterText(_field('VIN'), vin);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the car title and preselects the model\'s usual fuel', (tester) async {
    await _openDetails(tester);
    expect(find.text('Toyota Camry'), findsOneWidget);
    expect(find.text('Tell us about your car'), findsOneWidget);
    final hybrid = find.bySemanticsLabel(RegExp('Fuel type, Hybrid'));
    expect(tester.getSemantics(hybrid), isSemantics(isSelected: true));
  });

  testWidgets('Continue waits for the odometer, then saves kilometres', (tester) async {
    final opened = await _openDetails(tester);
    expect(_canContinue(tester), isFalse);

    await _enterOdometer(tester, '54320');
    expect(find.text('54,320'), findsOneWidget, reason: 'grouped while typing');
    expect(_canContinue(tester), isTrue);

    await tester.tap(_continue);
    await tester.pumpAndSettle();
    expect(find.byType(ServiceBaselineScreen), findsOneWidget);
    final details = opened.draft.details!;
    expect(details.odometerKm, 54320);
    expect(details.fuelType, FuelType.hybrid);
    expect(details.bodyType, BodyType.sedan);
    expect((await tester.runAsync(opened.session.load))!.setupDraftStep, SetupStep.baseline);
  });

  testWidgets('miles are converted to kilometres', (tester) async {
    final opened = await _openDetails(tester, unit: DistanceUnit.mi);
    expect(find.text('mi'), findsOneWidget);
    await _enterOdometer(tester, '10000');
    await tester.tap(_continue);
    await tester.pumpAndSettle();
    expect(opened.draft.details!.odometerKm, 16093);
  });

  testWidgets('an impossible odometer shows an error and blocks Continue', (tester) async {
    await _openDetails(tester);
    await _enterOdometer(tester, '3000000');
    expect(find.text('That looks too high. Check the number.'), findsOneWidget);
    expect(_canContinue(tester), isFalse);
  });

  testWidgets('paint colour and body type update the preview and are saved', (tester) async {
    final opened = await _openDetails(tester);
    // Racing Red is past the edge of the swatch row (built but off-screen),
    // so find the swatch widget including off-screen ones, then scroll to it.
    final racingRed = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == 'Racing Red',
      skipOffstage: false,
    );
    await tester.ensureVisible(racingRed);
    await tester.pumpAndSettle();
    await tester.tap(racingRed);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Wagon'));
    await tester.tap(find.text('Wagon'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Racing Red Wagon'), findsOneWidget, reason: 'preview description');

    await tester.ensureVisible(_field('Current odometer'));
    await _enterOdometer(tester, '1000');
    await tester.tap(_continue);
    await tester.pumpAndSettle();
    expect(opened.draft.details!.paint, PaintColor.racingRed);
    expect(opened.draft.details!.bodyType, BodyType.wagon);
  });

  testWidgets('a VIN with I, O or Q is an error and blocks Continue', (tester) async {
    await _openDetails(tester);
    await _enterOdometer(tester, '1000');
    await _openMoreDetails(tester);
    await _enterVin(tester, 'ABCIOQ');
    expect(find.text("VINs don't use the letters I, O or Q."), findsOneWidget);
    expect(_canContinue(tester), isFalse);
  });

  testWidgets('a short VIN only warns and can be saved', (tester) async {
    final opened = await _openDetails(tester);
    await _enterOdometer(tester, '1000');
    await _openMoreDetails(tester);
    await _enterVin(tester, 'WDB12345678');
    expect(find.textContaining('usually 17 characters'), findsOneWidget);
    expect(_canContinue(tester), isTrue);
    await tester.tap(_continue);
    await tester.pumpAndSettle();
    expect(opened.draft.details!.vin, 'WDB12345678');
  });

  testWidgets('a duplicate VIN asks before adding (BR-VEH-03)', (tester) async {
    final opened = await _openDetails(tester, withGarage: true);
    await _enterOdometer(tester, '1000');
    await _openMoreDetails(tester);
    await _enterVin(tester, '4T1C11AK5NU123456');

    await tester.tap(_continue);
    await tester.pumpAndSettle();
    expect(find.text('You already have a car with this VIN'), findsOneWidget);
    expect(find.text('Family Camry has the same VIN. Add anyway?'), findsOneWidget);

    await tester.tap(find.text('Change VIN'));
    await tester.pumpAndSettle();
    expect(find.byType(VehicleDetailsScreen), findsOneWidget);
    expect(opened.draft.details, isNull);

    await tester.tap(_continue);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add anyway'));
    await tester.pumpAndSettle();
    expect(find.byType(ServiceBaselineScreen), findsOneWidget);
  });

  testWidgets('coming back restores the earlier answers', (tester) async {
    await _openDetails(
      tester,
      draft: const VehicleDraft(
        brandId: 'toyota',
        modelId: 'toyota-camry',
        bodyType: BodyType.sedan,
        details: VehicleDetails(
          fuelType: FuelType.petrol,
          odometerKm: 77000,
          paint: PaintColor.forestGreen,
          bodyType: BodyType.sedan,
          nickname: 'Weekend car',
        ),
      ),
    );
    expect(find.text('77,000'), findsOneWidget);
    expect(find.text('Weekend car'), findsOneWidget, reason: 'More details opens when it has values');
    expect(_canContinue(tester), isTrue);
  });

  testWidgets('without a model it sends the user back to the start', (tester) async {
    await _openDetails(tester, draft: const VehicleDraft(brandId: 'toyota'));
    expect(find.text('Choose a model first'), findsOneWidget);
  });

  testWidgets('Arabic: title, labels and right to left', (tester) async {
    await _openDetails(tester, language: 'ar');
    expect(find.text('تويوتا كامري'), findsOneWidget);
    expect(find.text('نوع الوقود'), findsOneWidget);
    expect(find.text('كم'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(VehicleDetailsScreen))), TextDirection.rtl);
  });

  testWidgets('tablet landscape puts the preview beside the form', (tester) async {
    await _openDetails(tester, screen: const Size(1024, 768));
    expect(find.byType(SliverPersistentHeader), findsNothing);
    final preview = tester.getCenter(find.bySemanticsLabel('Silver Sedan'));
    final title = tester.getCenter(find.text('Toyota Camry'));
    expect(preview.dx, lessThan(title.dx));
  });

  testWidgets('large text does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openDetails(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    await _openDetails(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
