import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/mileage/domain/odometer_reading.dart';
import 'package:tdc_garage/features/mileage/presentation/mileage_history_screen.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

/// Opens the dashboard, then ⋯ → Mileage history.
Future<MockGarageRepository> _openHistory(
  WidgetTester tester, {
  MockGarageRepository? garage,
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
  await tester.tap(
    find.byType(PopupMenuButton<Object?>).evaluate().isEmpty
        ? find.byIcon(Icons.more_horiz)
        : find.byType(PopupMenuButton<Object?>),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(language == 'ar' ? 'سجل المسافة' : 'Mileage history'));
  await tester.pumpAndSettle();
  expect(find.byType(MileageHistoryScreen), findsOneWidget);
  return repository;
}

Finder _row(String pattern) => find.bySemanticsLabel(RegExp(pattern));

void main() {
  testWidgets('shows the monthly average and the readings by month', (tester) async {
    await _openHistory(tester);
    expect(find.text('Mileage'), findsWidgets);
    // 4,520 km over 146 days ≈ 31 km a day.
    expect(find.text('942 km / month'), findsOneWidget);
    expect(find.text('Based on the last 180 days'), findsOneWidget);
    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(_row(r'^54,320 km, Nov 3, 2026, Manual$'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^45,000 km, .*, From service$'), skipOffstage: false), findsOneWidget);
  });

  testWidgets('swiping a manual reading deletes it after confirming', (tester) async {
    final garage = await _openHistory(tester);
    await tester.drag(_row(r'^54,320 km'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete this reading?'), findsOneWidget);
    expect(find.text('54,320 km on Nov 3, 2026 will be removed.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Reading deleted'), findsOneWidget);
    expect(_row(r'^54,320 km'), findsNothing);
    final camry = (await tester.runAsync(garage.vehicles))!.first;
    expect(camry.odometerKm, 52100, reason: 'falls back to the previous reading');
  });

  testWidgets('cancelling keeps the reading', (tester) async {
    await _openHistory(tester);
    await tester.drag(_row(r'^54,320 km'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(_row(r'^54,320 km'), findsOneWidget);
  });

  testWidgets('a service reading explains how to remove it instead', (tester) async {
    final garage = await _openHistory(tester);
    final service = _row(r'^45,000 km');
    await tester.scrollUntilVisible(service, 200);
    await tester.drag(service, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete the service record to remove this'), findsOneWidget);
    expect((await tester.runAsync(() => garage.readings('veh-camry')))!, hasLength(4));
  });

  testWidgets('screen readers get a Delete action on manual readings', (tester) async {
    final semantics = tester.ensureSemantics();
    await _openHistory(tester);
    final data = tester.getSemantics(_row(r'^54,320 km')).getSemanticsData();
    expect(data.customSemanticsActionIds, isNotEmpty);
    expect(data.hasAction(SemanticsAction.customAction), isTrue);
    semantics.dispose();
  });

  testWidgets('a correction is marked', (tester) async {
    final garage = MockGarageRepository.forScenario('returning', now: _now);
    await garage.addReading(
      OdometerReading(id: 'c1', vehicleId: 'veh-camry', date: _now, km: 53900, isCorrection: true),
    );
    await _openHistory(tester, garage: garage);
    expect(_row(r'^53,900 km, Nov 7, 2026, Manual, Correction$'), findsOneWidget);
    expect(
      find.text('Add another reading in 14 days to see your average.'),
      findsOneWidget,
      reason: 'a correction restarts the average',
    );
  });

  testWidgets('only the starting reading: empty state with Update mileage', (tester) async {
    final garage = MockGarageRepository.forScenario('returning', now: _now);
    await garage.deleteVehicle('veh-camry');
    await _openHistory(tester, garage: garage);
    expect(find.text('Only your starting reading so far'), findsOneWidget);
    expect(find.text('Add another reading to see your average.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Update mileage'));
    await tester.pumpAndSettle();
    expect(find.text('Update mileage'), findsWidgets);
  });

  testWidgets('iPad landscape: list at the start, summary at the end', (tester) async {
    await _openHistory(tester, screen: const Size(1024, 768));
    final list = tester.getCenter(_row(r'^54,320 km'));
    final average = tester.getCenter(find.text('942 km / month'));
    expect(average.dx, greaterThan(list.dx));
  });

  testWidgets('Arabic: translated, months with Western digits', (tester) async {
    await _openHistory(tester, language: 'ar');
    expect(find.text('المتوسط'), findsOneWidget);
    expect(find.text('نوفمبر 2026'), findsOneWidget);
  });

  testWidgets('large text does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openHistory(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    await _openHistory(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
