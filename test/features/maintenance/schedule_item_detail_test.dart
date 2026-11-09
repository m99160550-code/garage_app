import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_item.dart';
import 'package:tdc_garage/features/maintenance/domain/severity.dart';
import 'package:tdc_garage/features/maintenance/presentation/schedule_item_detail.dart';
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

import 'package:tdc_garage/features/service_history/presentation/log_service_screen.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

/// Opens the dashboard of [garage] and then S-15 for [code].
Future<MockGarageRepository> _openItem(
  WidgetTester tester,
  String code, {
  MockGarageRepository? garage,
  bool setLastDone = false,
  Size? screen,
  String? language,
}) async {
  screen == null ? usePhoneScreen(tester) : useScreen(tester, screen);
  final repository = garage ?? MockGarageRepository.forScenario('returning', now: _now);
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => _now),
        preferencesRepositoryProvider.overrideWithValue(
          MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA', currency: 'SAR')),
        ),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  GoRouter.of(tester.element(find.byType(DashboardScreen)))
      .push('/garage/item/$code${setLastDone ? '?setLastDone=1' : ''}');
  await tester.pumpAndSettle();
  expect(find.byType(ScheduleItemDetail), findsOneWidget);
  return repository;
}

/// A Camry (hybrid) garage with one [item].
Future<MockGarageRepository> _garageWith(ScheduleItem item) async {
  final garage = MockGarageRepository();
  await garage.addVehicle(
    Vehicle(
      id: 'veh-camry',
      brandId: 'toyota',
      modelId: 'toyota-camry',
      fuelType: FuelType.hybrid,
      bodyType: BodyType.sedan,
      odometerKm: 30000,
      odometerUpdatedAt: _now,
    ),
    [item],
  );
  return garage;
}

Finder _fact(String pattern) => find.bySemanticsLabel(RegExp(pattern), skipOffstage: false);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the status, the facts and the score impact', (tester) async {
    await _openItem(tester, 'engine_oil');
    expect(find.text('Engine oil'), findsOneWidget);
    expect(find.text('Due in 20 days'), findsOneWidget);
    expect(_fact(r'^Interval, Every 12 months or 15,000.km$'), findsOneWidget);
    expect(_fact(r'^Last done, Nov 27, 2025 · 45,000.km, Baseline$'), findsOneWidget);
    expect(_fact(r'^Next due, Nov 27, 2026 or 60,000.km$'), findsOneWidget);
    expect(_fact(r'^Predicted, Around .* at your usual mileage$'), findsOneWidget);
    expect(_fact(r'^Score impact, .?−2.? points$'), findsOneWidget);
  });

  testWidgets('Mark as done opens Log service (S-22)', (tester) async {
    await _openItem(tester, 'engine_oil');
    await tester.tap(find.text('Mark as done'));
    await tester.pumpAndSettle();
    expect(find.byType(LogServiceScreen), findsOneWidget);
  });

  testWidgets('snooze: pick 14 days, then undo from the banner', (tester) async {
    await _openItem(tester, 'engine_oil');
    await tester.tap(find.widgetWithText(TextButton, 'Snooze'));
    await tester.pumpAndSettle();
    expect(find.text('Snooze reminders'), findsOneWidget);
    expect(find.textContaining('score still counts'), findsNothing, reason: 'not overdue');
    await tester.tap(find.text('14 days'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Snooze').last);
    await tester.pumpAndSettle();

    expect(find.text('Snoozed until Nov 21, 2026'), findsWidgets);
    expect(_fact(r'^Score impact, None$'), findsOneWidget, reason: 'due-soon deduction paused (BR-HLT-05)');
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_fact(r'^Score impact, .?−2.? points$'), findsOneWidget);
  });

  testWidgets('snoozing an overdue item explains the score still counts it', (tester) async {
    final garage = MockGarageRepository.forScenario('returning', now: _now);
    await garage.deleteVehicle('veh-camry');
    await _openItem(tester, 'engine_oil', garage: garage);
    await tester.tap(find.widgetWithText(TextButton, 'Snooze'));
    await tester.pumpAndSettle();
    expect(find.text('Reminders pause, but the score still counts this as overdue.'), findsOneWidget);
  });

  testWidgets('reschedule moves the due date for this cycle (BR-MNT-06)', (tester) async {
    await _openItem(tester, 'engine_oil');
    await tester.tap(find.widgetWithText(TextButton, 'Reschedule'));
    await tester.pumpAndSettle();
    expect(find.text('Only this time. Later reminders use the normal interval.'), findsOneWidget);
    await tester.tap(find.text('30'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Due date moved to Nov 30, 2026'), findsOneWidget);
    expect(_fact(r'^Next due, Nov 30, 2026 or 60,000.km$'), findsOneWidget);
  });

  testWidgets('not applicable greys out the item and stops it counting', (tester) async {
    await _openItem(tester, 'engine_oil');
    await _tapVisible(tester, find.text('Not applicable to my car'));
    expect(find.text('Not applicable'), findsWidgets);
    expect(_fact(r'^Score impact, None$'), findsOneWidget);
    final ignore = tester.widget<IgnorePointer>(
      find.ancestor(of: find.text('Mark as done'), matching: find.byType(IgnorePointer)).first,
    );
    expect(ignore.ignoring, isTrue);
  });

  testWidgets('an Unknown item opens with "Set last done" and saves it', (tester) async {
    await _openItem(tester, 'battery', setLastDone: true);
    expect(find.text('Unknown'), findsWidgets);
    final save = find.widgetWithText(TextButton, 'Save');
    await _tapVisible(tester, save);
    expect(find.text('Enter a date or a mileage'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Mileage'), '60000');
    await tester.pumpAndSettle();
    expect(find.textContaining("Can't be more than your current mileage"), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Mileage'), '');
    await _tapVisible(tester, find.widgetWithText(TextFormField, 'Date'));
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.widgetWithText(TextButton, 'Save'));

    expect(find.text('Last done saved'), findsOneWidget);
    expect(_fact(r'^Last done, Nov 7, 2026, Set by you$'), findsOneWidget);
  });

  testWidgets('an edited interval shows "Edited" and resets to typical', (tester) async {
    await _openItem(
      tester,
      'engine_oil',
      garage: await _garageWith(
        ScheduleItem(
          id: 'oil',
          vehicleId: 'veh-camry',
          code: 'engine_oil',
          nameEn: 'Engine oil',
          nameAr: 'زيت المحرك',
          severity: Severity.major,
          intervalMonths: 6,
          lastDoneDate: DateTime(2026, 9, 1),
          intervalEdited: true,
        ),
      ),
    );
    expect(_fact(r'^Interval, Every 6 months, Edited$'), findsOneWidget);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset to typical'));
    await tester.pumpAndSettle();
    expect(_fact(r'^Interval, Every 12 months or 15,000.km$'), findsOneWidget);
  });

  testWidgets('a custom item can be deleted', (tester) async {
    final garage = await _garageWith(
      ScheduleItem(
        id: 'custom-1',
        vehicleId: 'veh-camry',
        code: 'custom-1',
        nameEn: 'Car wash',
        nameAr: 'غسيل',
        severity: Severity.minor,
        intervalMonths: 1,
        isCustom: true,
      ),
    );
    await _openItem(tester, 'custom-1', garage: garage);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete item'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Car wash?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleItemDetail), findsNothing);
    expect((await tester.runAsync(() => garage.schedule('veh-camry')))!, isEmpty);
  });

  testWidgets('an item that no longer exists says so', (tester) async {
    await _openItem(tester, 'nothing_here');
    expect(find.text('This item no longer exists'), findsOneWidget);
  });

  testWidgets('iPad landscape: the schedule shows the detail beside the list', (tester) async {
    useScreen(tester, const Size(1024, 768));
    await tester.pumpWidget(
      buildTestApp(
        MockSessionRepository(scenario: 'returning'),
        overrides: [
          garageRepositoryProvider.overrideWithValue(MockGarageRepository.forScenario('returning', now: _now)),
          clockProvider.overrideWithValue(() => _now),
          preferencesRepositoryProvider.overrideWithValue(
            MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA', currency: 'SAR')),
          ),
        ],
      ),
    );
    await finishLaunch(tester);
    GoRouter.of(tester.element(find.byType(DashboardScreen))).push('/garage/schedule');
    await tester.pumpAndSettle();
    final detail = find.byType(ScheduleItemDetail);
    expect(detail, findsOneWidget);
    expect(find.descendant(of: detail, matching: find.text('Mark as done')), findsOneWidget);
    expect(find.descendant(of: detail, matching: find.byType(BackButton)), findsNothing);
  });

  testWidgets('Arabic: translated, right to left', (tester) async {
    await _openItem(tester, 'engine_oil', language: 'ar');
    expect(find.text('تحديد كمنجز'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(ScheduleItemDetail))), TextDirection.rtl);
  });

  testWidgets('large text does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openItem(tester, 'engine_oil');
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    // A tall phone, so no content sits under the translucent floating bar
    // (text scrolled behind it isn't meant to be read there).
    await _openItem(tester, 'engine_oil', screen: const Size(390, 1600));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
