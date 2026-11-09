import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/maintenance/presentation/schedule_item_detail.dart';
import 'package:tdc_garage/features/maintenance/presentation/schedule_screen.dart';
import 'package:tdc_garage/core/widgets/navigation/app_nav_rail.dart';
import 'package:tdc_garage/core/widgets/navigation/floating_nav_bar.dart';
import 'package:tdc_garage/core/widgets/stat_card.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/garage/presentation/health_detail_screen.dart';
import 'package:tdc_garage/features/garage/presentation/widgets/stat_carousel.dart';
import 'package:tdc_garage/features/maintenance/data/template_repository.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_rules.dart';
import 'package:tdc_garage/features/maintenance/domain/vehicle_setup.dart';
import 'package:tdc_garage/features/onboarding/presentation/brand/brand_selection_screen.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';
import 'package:tdc_garage/features/vehicles/domain/body_type.dart';
import 'package:tdc_garage/features/vehicles/domain/fuel_type.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle.dart';

import 'package:tdc_garage/features/service_history/application/service_history_providers.dart';
import 'package:tdc_garage/features/service_history/data/service_record_repository.dart';

import 'package:tdc_garage/features/expenses/presentation/spend_screen.dart';
import 'package:tdc_garage/features/service_history/presentation/history_screen.dart';

import 'package:tdc_garage/features/add_menu/presentation/add_menu_sheet.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

/// Opens the dashboard of the `returning` garage (Family Camry first).
Future<MockGarageRepository> _openDashboard(
  WidgetTester tester, {
  Size? screen,
  String? language,
  MockGarageRepository? garage,
}) async {
  screen == null ? usePhoneScreen(tester) : useScreen(tester, screen);
  final repository = garage ?? MockGarageRepository.forScenario('returning', now: _now);
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => _now),
        serviceRecordRepositoryProvider.overrideWithValue(
          MockServiceRecordRepository.forScenario('returning', now: _now),
        ),
        preferencesRepositoryProvider.overrideWithValue(
          MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA', currency: 'SAR')),
        ),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  expect(find.byType(DashboardScreen), findsOneWidget);
  return repository;
}

Finder _card(String label) => find.byWidgetPredicate((w) => w is StatCard && w.label == label);

Future<void> _swipeHeroToNext(WidgetTester tester) async {
  await tester.fling(find.bySemanticsLabel('Midnight Blue Sedan'), const Offset(-300, 0), 1200);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the car, its score and the three stats (spec S-09)', (tester) async {
    await _openDashboard(tester);

    expect(find.text('Toyota'), findsWidgets, reason: 'brand in chrome');
    expect(find.text('Family Camry'), findsOneWidget, reason: 'nickname as the subline');
    expect(
      find.bySemanticsLabel(RegExp(r'^Health score 96 percent, Excellent, Based on typical intervals · 7 unknown')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'^Mileage, 54,320 kilometres, Updated 4 days ago')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Next service, \d+ Days away, .* · 2 items')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^This year, SAR.420 Spent, 3 services')), findsOneWidget);
    expect(find.text('Engine oil due soon'), findsOneWidget);
  });

  testWidgets('opens focused on Next service', (tester) async {
    await _openDashboard(tester);
    final next = tester.widget<StatCard>(_card('Next service'));
    final mileage = tester.widget<StatCard>(_card('Mileage'));
    expect(next.focused, isTrue);
    expect(mileage.focused, isFalse);
  });

  testWidgets('the alert pill opens its item; the score opens S-11', (tester) async {
    await _openDashboard(tester);
    await tester.tap(find.text('Engine oil due soon'));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleItemScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^Health score')));
    await tester.pumpAndSettle();
    expect(find.byType(HealthDetailScreen), findsOneWidget);
  });

  testWidgets('a side card scrolls into focus first, then opens', (tester) async {
    await _openDashboard(tester);
    await tester.tap(_card('This year'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.widget<StatCard>(_card('This year')).focused, isTrue);
    await tester.tap(_card('This year'));
    await tester.pumpAndSettle();
    expect(find.byType(SpendScreen), findsOneWidget);
  });

  testWidgets('swiping the hero shows the next car: overdue items first', (tester) async {
    await _openDashboard(tester);
    await _swipeHeroToNext(tester);

    expect(find.text('Nissan'), findsWidgets);
    expect(find.text('Patrol · 2019'), findsOneWidget);
    expect(find.text('2 items overdue'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Health score 70 percent, Good')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Next service, 40 Days overdue, 2 items')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Some records not included')), findsOneWidget);

    await tester.tap(find.text('2 items overdue'));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleScreen), findsOneWidget);
  });

  testWidgets('a car with every item Unknown asks to set up the schedule', (tester) async {
    final garage = MockGarageRepository();
    await garage.addVehicle(
      Vehicle(
        id: 'veh-proton',
        brandOtherName: 'Proton',
        modelOtherName: 'Saga',
        fuelType: FuelType.petrol,
        bodyType: BodyType.sedan,
        odometerKm: 12000,
        odometerUpdatedAt: _now,
      ),
      generateSchedule(
        vehicleId: 'veh-proton',
        template: MockTemplateRepository.templates[FuelType.petrol]!,
        setup: const BaselineSetup({}),
      ),
    );
    await _openDashboard(tester, garage: garage);

    expect(find.text('Proton'), findsWidgets, reason: 'typed brand name');
    expect(find.text('PR'), findsOneWidget, reason: 'monogram from the typed name');
    expect(find.bySemanticsLabel(RegExp(r'^Next service, — Set up your schedule')), findsOneWidget);
    expect(find.text('Complete your schedule · 12 unknown'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^This year, SAR.0 Spent, No costs yet')), findsOneWidget);
  });

  testWidgets('delete a vehicle: confirm, then the next one shows', (tester) async {
    final garage = await _openDashboard(tester);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete vehicle'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Family Camry?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Family Camry deleted'), findsOneWidget);
    expect(find.text('Patrol · 2019'), findsOneWidget);
    expect((await tester.runAsync(garage.vehicles))!.map((v) => v.id), ['veh-patrol']);
  });

  testWidgets('deleting the last vehicle returns to brand selection (BR-VEH-06)', (tester) async {
    final garage = await _openDashboard(tester);
    await tester.runAsync(() => garage.deleteVehicle('veh-patrol'));
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete vehicle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.byType(BrandSelectionScreen), findsOneWidget);
  });

  testWidgets('the floating bar switches tabs; Add opens the add menu', (tester) async {
    await _openDashboard(tester);
    expect(find.byType(FloatingNavBar), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Garage'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Add'));
    await tester.pumpAndSettle();
    expect(find.byType(AddMenuSheet), findsOneWidget);
  });

  testWidgets('Arabic: right to left, translated stats and pill', (tester) async {
    await _openDashboard(tester, language: 'ar');
    expect(Directionality.of(tester.element(find.byType(DashboardScreen))), TextDirection.rtl);
    expect(find.text('تويوتا'), findsWidgets);
    expect(find.text('زيت المحرك مستحق قريبًا'), findsOneWidget);
    expect(
      find.textContaining('54,320', findRichText: true),
      findsOneWidget,
      reason: 'odometer stays in Western digits',
    );
    expect(find.textContaining('420\u00A0ر.س', findRichText: true), findsOneWidget);
  });

  testWidgets('iPad portrait: rail, and the three cards in a row', (tester) async {
    await _openDashboard(tester, screen: const Size(768, 1024));
    expect(find.byType(AppNavRail), findsOneWidget);
    expect(find.byType(StatCarousel), findsNothing);
    final mileage = tester.getTopLeft(_card('Mileage'));
    final year = tester.getTopLeft(_card('This year'));
    expect(year.dy, mileage.dy);
  });

  testWidgets('iPad landscape: two columns with the Upcoming list', (tester) async {
    await _openDashboard(tester, screen: const Size(1024, 768));
    expect(find.text('Upcoming'), findsOneWidget);
    final score = tester.getCenter(find.bySemanticsLabel(RegExp('^Health score')));
    final mileage = tester.getCenter(_card('Mileage'));
    expect(mileage.dx, greaterThan(score.dx));
  });

  testWidgets('large text: scrolls and stacks the cards without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openDashboard(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(StatCarousel), findsNothing);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    await _openDashboard(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
