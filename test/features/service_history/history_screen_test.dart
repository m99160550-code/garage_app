import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/features/garage/application/current_vehicle_controller.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/garage/presentation/vehicle_switcher_sheet.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/service_history/application/service_history_providers.dart';
import 'package:tdc_garage/features/service_history/data/service_record_repository.dart';
import 'package:tdc_garage/features/service_history/domain/history_filters.dart';
import 'package:tdc_garage/features/service_history/domain/service_record.dart';
import 'package:tdc_garage/features/service_history/presentation/history_screen.dart';
import 'package:tdc_garage/features/service_history/presentation/widgets/service_record_row.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';

import 'package:tdc_garage/features/service_history/presentation/service_record_screen.dart';

import 'package:tdc_garage/features/service_history/presentation/log_service_screen.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);
final _records = MockServiceRecordRepository.sampleRecordsAt(_now);
final _camry = _records.where((r) => r.vehicleId == 'veh-camry').toList();

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

/// Launches the sample garage and opens the History tab.
Future<ProviderContainer> _openHistory(
  WidgetTester tester, {
  Size? screen,
  String? language,
  List<ServiceRecord>? records,
}) async {
  screen == null ? usePhoneScreen(tester) : useScreen(tester, screen);
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(MockGarageRepository.forScenario('returning', now: _now)),
        serviceRecordRepositoryProvider.overrideWithValue(MockServiceRecordRepository(records ?? _records)),
        clockProvider.overrideWithValue(() => _now),
        preferencesRepositoryProvider.overrideWithValue(
          MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA', currency: 'SAR')),
        ),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  final container = ProviderScope.containerOf(tester.element(find.byType(DashboardScreen)));
  GoRouter.of(tester.element(find.byType(DashboardScreen))).go('/history');
  await tester.pumpAndSettle();
  expect(find.byType(HistoryScreen), findsOneWidget);
  return container;
}

Iterable<String> _rowIds(WidgetTester tester) =>
    tester.widgetList<ServiceRecordRow>(find.byType(ServiceRecordRow)).map((r) => r.record.id);

Future<void> _choose(WidgetTester tester, String chip, String option) async {
  await tester.ensureVisible(find.text(chip));
  await tester.pumpAndSettle();
  await tester.tap(find.text(chip));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

void main() {
  group('history rules (S-20)', () {
    test('groups by month, newest month and record first', () {
      final groups = groupByMonth(_camry);
      expect(groups.map((g) => g.$1), [
        DateTime(2026, 10),
        DateTime(2026, 9),
        DateTime(2026, 6),
        DateTime(2026, 4),
        DateTime(2025, 11),
      ]);
      expect(groups.first.$2.single.id, 'rec-camry-5');
    });

    test('filters by year and type; years newest first', () {
      expect(recordYears(_camry), [2026, 2025]);
      const filters = HistoryFilters(year: 2026, type: ServiceType.repair);
      expect(_camry.where(filters.matches).map((r) => r.id), ['rec-camry-3']);
      expect(const HistoryFilters().isSet, isFalse);
      expect(filters.withYear(null).withType(null).isSet, isFalse);
    });
  });

  group('S-20 Service history', () {
    testWidgets('the History tab lists the current car by month, costs or "—"', (tester) async {
      await _openHistory(tester);

      expect(find.text('History'), findsWidgets);
      expect(find.text('Family Camry'), findsOneWidget);
      expect(find.text('Year: All years'), findsOneWidget);
      expect(find.text('Type: All'), findsOneWidget);
      expect(find.text('Clear'), findsNothing);
      expect(find.text('OCTOBER 2026'), findsOneWidget);
      expect(find.text('SEPTEMBER 2026'), findsOneWidget);
      // A record without a cost (the inspection) is listed here, with "—".
      final inspection = find.widgetWithText(ServiceRecordRow, 'Inspection');
      expect(inspection, findsOneWidget);
      expect(find.descendant(of: inspection, matching: find.text('—')), findsOneWidget);
      expect(find.textContaining('Fahas · 53,900'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Engine oil, Oil filter'),
        200,
        scrollable: find
            .descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable))
            .hitTestable()
            .first,
      );
      expect(find.text('Engine oil, Oil filter'), findsOneWidget);
    });

    testWidgets('Year filter, then Clear', (tester) async {
      await _openHistory(tester);
      await _choose(tester, 'Year: All years', '2025');

      expect(find.text('Year: 2025'), findsOneWidget);
      expect(_rowIds(tester), ['rec-camry-1']);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Year: All years'), findsOneWidget);
      expect(_rowIds(tester).first, 'rec-camry-5');
    });

    testWidgets('Type filter', (tester) async {
      await _openHistory(tester);
      await _choose(tester, 'Type: All', 'Repair');
      expect(find.text('Type: Repair'), findsOneWidget);
      expect(_rowIds(tester), ['rec-camry-3']);
    });

    testWidgets('no match: message and Clear filters', (tester) async {
      await _openHistory(tester);
      await _choose(tester, 'Year: All years', '2025');
      await _choose(tester, 'Type: All', 'Repair');

      expect(find.text('No services match these filters'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.byType(ServiceRecordRow), findsWidgets);
    });

    testWidgets('the vehicle chip picks another car without changing the dashboard', (tester) async {
      final container = await _openHistory(tester);
      await tester.tap(find.text('Family Camry'));
      await tester.pumpAndSettle();

      expect(find.byType(VehicleSwitcherSheet), findsOneWidget);
      expect(find.text('Add vehicle'), findsNothing);
      expect(find.text('Manage vehicles'), findsNothing);
      await tester.tap(find.text('Nissan Patrol').last);
      await tester.pumpAndSettle();

      expect(find.text('Nissan Patrol'), findsOneWidget);
      expect(_rowIds(tester).first, 'rec-patrol-3');
      expect(container.read(currentVehicleProvider).value, 'veh-camry');
    });

    testWidgets('a record opens S-21; "+" opens S-22', (tester) async {
      await _openHistory(tester);
      await tester.tap(find.byType(ServiceRecordRow).first);
      await tester.pumpAndSettle();
      expect(find.byType(ServiceRecordScreen), findsOneWidget);
      expect(
        GoRouterState.of(tester.element(find.byType(ServiceRecordScreen))).uri.path,
        '/history/record/rec-camry-5',
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Log service'));
      await tester.pumpAndSettle();
      expect(find.byType(LogServiceScreen), findsOneWidget);
    });

    testWidgets('empty: "No services yet" and Log service', (tester) async {
      await _openHistory(tester, records: const []);
      expect(find.text('No services yet'), findsOneWidget);
      expect(find.text("Log your first service to build your car's history."), findsOneWidget);
      expect(find.text('Year: All years'), findsNothing, reason: 'no filters without records');
      await tester.tap(find.text('Log service'));
      await tester.pumpAndSettle();
      expect(find.byType(LogServiceScreen), findsOneWidget);
    });

    testWidgets('iPad portrait: a record opens in a side sheet, list at most 720 wide', (tester) async {
      await _openHistory(tester, screen: const Size(768, 1024));
      expect(tester.getSize(find.byType(ServiceRecordRow).first).width, lessThanOrEqualTo(720));
      await tester.tap(find.byType(ServiceRecordRow).first);
      await tester.pumpAndSettle();
      expect(find.byType(ServiceRecordScreen), findsOneWidget);
      expect(find.byType(HistoryScreen), findsOneWidget, reason: 'still visible under the sheet');
    });

    testWidgets('iPad landscape: master-detail with the first record selected', (tester) async {
      await _openHistory(tester, screen: const Size(1366, 1024));
      expect(find.byType(ServiceRecordScreen), findsOneWidget);
      final list = tester.getSize(find.byType(CustomScrollView)).width;
      expect(list / 1366, closeTo(0.4, 0.06));
      await tester.tap(find.widgetWithText(ServiceRecordRow, 'Repair'));
      await tester.pumpAndSettle();
      expect(find.byType(ServiceRecordScreen), findsOneWidget);
      expect(find.byType(HistoryScreen), findsOneWidget);
    });

    testWidgets('Arabic: month headings, translated chips, no overflow', (tester) async {
      await _openHistory(tester, language: 'ar');
      expect(find.text('السجل'), findsWidgets);
      expect(find.text('أكتوبر 2026'), findsOneWidget);
      expect(find.text('السنة: كل السنوات'), findsOneWidget);
      expect(find.text('فحص'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets tap-target and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await _openHistory(tester, screen: const Size(390, 1600));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
