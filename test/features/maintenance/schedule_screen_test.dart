import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/maintenance/presentation/schedule_item_detail.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_item.dart';
import 'package:tdc_garage/features/maintenance/domain/severity.dart';
import 'package:tdc_garage/features/maintenance/presentation/item_interval_screen.dart';
import 'package:tdc_garage/features/maintenance/presentation/schedule_screen.dart';
import 'package:tdc_garage/features/maintenance/presentation/widgets/schedule_item_row.dart';
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

/// Opens the dashboard of [garage] and then [location] (S-14 by default).
Future<void> _openSchedule(
  WidgetTester tester, {
  MockGarageRepository? garage,
  String location = '/garage/schedule',
  Size? screen,
  String? language,
}) async {
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
  GoRouter.of(tester.element(find.byType(DashboardScreen))).push(location);
  await tester.pumpAndSettle();
  expect(find.byType(ScheduleScreen), findsOneWidget);
}

/// A garage with one car and the given items.
Future<MockGarageRepository> _garageWith(List<ScheduleItem> items) async {
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
    items,
  );
  return garage;
}

ScheduleItem _item(String code, {DateTime? done, bool notApplicable = false}) => ScheduleItem(
  id: code,
  vehicleId: 'veh-camry',
  code: code,
  nameEn: code == 'wipers' ? 'Wiper blades' : 'Engine oil',
  nameAr: code,
  severity: Severity.minor,
  intervalMonths: 12,
  lastDoneDate: done,
  notApplicable: notApplicable,
);

Finder _row(String pattern) => find.bySemanticsLabel(RegExp(pattern), skipOffstage: false);

/// Rows further down are built lazily: scroll the schedule until it shows.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sections, counts, rows and the template line', (tester) async {
    await _openSchedule(tester);
    expect(find.text('Schedule'), findsWidgets);
    expect(find.text('Family Camry'), findsOneWidget);
    expect(find.text('Typical intervals for Hybrid · template v1'), findsOneWidget);
    expect(find.text('Due soon (2)'), findsOneWidget);
    expect(find.text('Unknown (7)', skipOffstage: false), findsOneWidget);
    expect(find.text('DUE SOON · 2'), findsOneWidget);
    expect(_row(r'^Engine oil, Due Nov 27 or at 60,000 km, Due soon$'), findsOneWidget);
    await _scrollTo(tester, find.bySemanticsLabel(RegExp(r'^Brakes, Critical, Due .* or at 84,000 km, OK$')));
    await _scrollTo(tester, find.bySemanticsLabel(RegExp(r'^Battery, Unknown: set last done, Unknown$')));
  });

  testWidgets('a filter chip filters instantly', (tester) async {
    await _openSchedule(tester);
    await tester.scrollUntilVisible(
      find.text('Unknown (7)'),
      120,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    await tester.tap(find.text('Unknown (7)'));
    await tester.pumpAndSettle();
    expect(find.text('DUE SOON · 2'), findsNothing);
    expect(find.text('UNKNOWN · 7'), findsOneWidget);
  });

  testWidgets('opened filtered from the alert pill', (tester) async {
    final garage = MockGarageRepository.forScenario('returning', now: _now);
    await garage.deleteVehicle('veh-camry');
    await _openSchedule(tester, garage: garage, location: '/garage/schedule?filter=overdue');
    expect(find.text('OVERDUE · 2'), findsOneWidget);
    expect(find.text('UNKNOWN · 7'), findsNothing);
    expect(_row(r'^Engine oil, Overdue by 2,400 km, Overdue$'), findsOneWidget);
  });

  testWidgets('a row opens the item (S-15)', (tester) async {
    await _openSchedule(tester);
    await tester.tap(_row(r'^Engine oil, '));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleItemScreen), findsOneWidget);
  });

  testWidgets('the template line explains the intervals', (tester) async {
    await _openSchedule(tester);
    await tester.tap(find.text('Typical intervals for Hybrid · template v1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('reviewed by a qualified mechanic'), findsOneWidget);
  });

  testWidgets('"+" opens Add custom item (S-16)', (tester) async {
    await _openSchedule(tester);
    await tester.tap(find.byTooltip('Add custom item'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemIntervalScreen), findsOneWidget);
  });

  testWidgets('everything on schedule: the "All good" banner', (tester) async {
    await _openSchedule(tester, garage: await _garageWith([_item('engine_oil', done: DateTime(2026, 6, 1))]));
    expect(find.text('All good. Everything is on schedule.'), findsOneWidget);
    expect(find.text('UPCOMING · 1'), findsOneWidget);
  });

  testWidgets('not applicable items are dimmed in their own section', (tester) async {
    await _openSchedule(
      tester,
      garage: await _garageWith([
        _item('engine_oil', done: DateTime(2026, 6, 1)),
        _item('wipers', done: DateTime(2026, 6, 1), notApplicable: true),
      ]),
    );
    expect(find.text('NOT APPLICABLE · 1'), findsOneWidget);
    expect(_row(r'^Wiper blades, Not applicable, Not applicable$'), findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find.descendant(of: find.widgetWithText(ScheduleItemRow, 'Wiper blades'), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 0.6);
  });

  testWidgets('a deep-linked item is highlighted', (tester) async {
    await _openSchedule(tester, location: '/garage/schedule?item=battery');
    await _scrollTo(tester, find.bySemanticsLabel(RegExp(r'^Battery, ')));
    final row = tester.widget<ScheduleItemRow>(
      find.byWidgetPredicate((w) => w is ScheduleItemRow && w.due.item.code == 'battery', skipOffstage: false),
    );
    expect(row.highlight, isTrue);
  });

  testWidgets('iPad portrait: an item opens in a side sheet', (tester) async {
    await _openSchedule(tester, screen: const Size(768, 1024));
    await tester.tap(_row(r'^Engine oil, '));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(ScheduleItemScreen)).width, 420);
  });

  testWidgets('iPad landscape: list and detail side by side', (tester) async {
    await _openSchedule(tester, screen: const Size(1024, 768));
    expect(find.text('Engine oil'), findsNWidgets(2), reason: 'first item selected and shown in the detail pane');
    await _scrollTo(tester, find.bySemanticsLabel(RegExp(r'^Brakes, ')));
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Brakes, ')));
    await tester.pumpAndSettle();
    expect(find.text('Brakes'), findsNWidgets(2));
  });

  testWidgets('Arabic: translated, right to left', (tester) async {
    await _openSchedule(tester, language: 'ar');
    expect(find.text('جدول الصيانة'), findsWidgets);
    expect(Directionality.of(tester.element(find.byType(ScheduleScreen))), TextDirection.rtl);
  });

  testWidgets('large text does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openSchedule(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    await _openSchedule(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
