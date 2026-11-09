import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/maintenance/presentation/schedule_item_detail.dart';
import 'package:tdc_garage/features/maintenance/presentation/schedule_screen.dart';
import 'package:tdc_garage/features/garage/presentation/health_detail_screen.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_item.dart';
import 'package:tdc_garage/features/maintenance/domain/severity.dart';
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

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

/// One car whose only item is the given one (plus nothing Unknown).
Future<MockGarageRepository> _singleItemGarage(ScheduleItem item) async {
  final garage = MockGarageRepository();
  await garage.addVehicle(
    Vehicle(
      id: 'veh-camry',
      brandId: 'toyota',
      modelId: 'toyota-camry',
      fuelType: FuelType.petrol,
      bodyType: BodyType.sedan,
      odometerKm: 30000,
      odometerUpdatedAt: _now,
    ),
    [item],
  );
  return garage;
}

ScheduleItem _oil({DateTime? done, DateTime? snoozedUntil}) => ScheduleItem(
  id: 'oil',
  vehicleId: 'veh-camry',
  code: 'engine_oil',
  nameEn: 'Engine oil',
  nameAr: 'زيت المحرك',
  severity: Severity.major,
  intervalMonths: 12,
  lastDoneDate: done,
  snoozedUntil: snoozedUntil,
);

/// Opens the dashboard, then the score detail.
Future<void> _openHealth(WidgetTester tester, {MockGarageRepository? garage, Size? screen, String? language}) async {
  screen == null ? usePhoneScreen(tester) : useScreen(tester, screen);
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
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
  await tester.tap(find.bySemanticsLabel(RegExp(r'^(Health score|مؤشر الحالة) \d+')).first);
  await tester.pumpAndSettle();
  expect(find.byType(HealthDetailScreen), findsOneWidget);
}

void main() {
  testWidgets('explains the score: summary, due-soon rows and what is not counted', (tester) async {
    await _openHealth(tester);
    expect(
      find.bySemanticsLabel(RegExp(r'^Health score 96 percent, Excellent\. 2 items are due within 30 days\.$')),
      findsOneWidget,
    );
    expect(find.text('Lowering your score'), findsOneWidget);
    expect(find.text('DUE SOON'), findsOneWidget);
    expect(find.bySemanticsLabel('Engine oil, Due in 20 days, minus 2 points'), findsOneWidget);
    expect(find.bySemanticsLabel('Oil filter, Due in 20 days, minus 2 points'), findsOneWidget);
    expect(find.text('Not counted'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Battery, Unknown: set last done$'), skipOffstage: false), findsOneWidget);
  });

  testWidgets('a row opens its item (S-15)', (tester) async {
    await _openHealth(tester);
    await tester.tap(find.bySemanticsLabel('Engine oil, Due in 20 days, minus 2 points'));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleItemScreen), findsOneWidget);
  });

  testWidgets('overdue items: reason by distance, doubled points with ×2', (tester) async {
    final garage = MockGarageRepository.forScenario('returning', now: _now);
    await garage.deleteVehicle('veh-camry');
    await _openHealth(tester, garage: garage);

    expect(find.bySemanticsLabel(RegExp(r'^Health score 70 percent, Good\. 2 items are overdue\.$')), findsOneWidget);
    expect(find.text('OVERDUE'), findsOneWidget);
    expect(find.bySemanticsLabel('Engine oil, Overdue by 2,400 km, minus 20 points, counts double'), findsOneWidget);
    expect(find.text('×2'), findsNWidgets(2));
  });

  testWidgets('nothing deducted: the empty state', (tester) async {
    await _openHealth(tester, garage: await _singleItemGarage(_oil(done: DateTime(2026, 6, 1))));
    expect(find.text('Nothing is lowering your score'), findsOneWidget);
    expect(find.text('Lowering your score'), findsNothing);
    expect(find.text('Not counted'), findsNothing);
  });

  testWidgets('a snoozed item is listed under Not counted (BR-HLT-05)', (tester) async {
    await _openHealth(
      tester,
      garage: await _singleItemGarage(_oil(done: DateTime(2025, 11, 20), snoozedUntil: DateTime(2026, 11, 20))),
    );
    expect(find.bySemanticsLabel(RegExp(r'^Health score 100 percent')), findsOneWidget);
    expect(find.bySemanticsLabel('Engine oil, Snoozed until Nov 20'), findsOneWidget);
  });

  testWidgets('"How the score works" expands and links to the schedule', (tester) async {
    await _openHealth(tester);
    final how = find.text('How the score works');
    await tester.scrollUntilVisible(how, 300);
    await tester.tap(how);
    await tester.pumpAndSettle();
    expect(find.textContaining('Your score starts at 100.'), findsOneWidget);
    expect(find.text('Typical intervals for Hybrid · template v1'), findsOneWidget);

    await tester.ensureVisible(find.text('See your schedule'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See your schedule'));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleScreen), findsOneWidget);
  });

  testWidgets('tablet: a 420 pt side sheet with a close button', (tester) async {
    await _openHealth(tester, screen: const Size(1024, 768));
    expect(tester.getSize(find.byType(HealthDetailScreen)).width, 420);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(HealthDetailScreen), findsNothing);
  });

  testWidgets('Arabic: translated, right to left', (tester) async {
    await _openHealth(tester, language: 'ar');
    expect(find.text('ما يخفض مؤشرك'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(HealthDetailScreen))), TextDirection.rtl);
  });

  testWidgets('large text does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openHealth(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    await _openHealth(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
