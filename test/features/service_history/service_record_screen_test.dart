import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tdc_garage/core/format/app_formatters.dart';
import 'package:tdc_garage/core/l10n/generated/app_localizations_ar.dart';
import 'package:tdc_garage/core/l10n/generated/app_localizations_en.dart';
import 'package:tdc_garage/features/garage/application/current_vehicle_controller.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_item.dart';
import 'package:tdc_garage/features/maintenance/domain/severity.dart';
import 'package:tdc_garage/features/maintenance/presentation/schedule_item_detail.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/service_history/application/service_history_providers.dart';
import 'package:tdc_garage/features/service_history/data/service_record_repository.dart';
import 'package:tdc_garage/features/service_history/domain/record_rules.dart';
import 'package:tdc_garage/features/service_history/domain/service_record.dart';
import 'package:tdc_garage/features/service_history/presentation/service_record_screen.dart';
import 'package:tdc_garage/features/service_history/presentation/widgets/service_record_row.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';

import 'package:tdc_garage/features/service_history/presentation/log_service_screen.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

ServiceRecord _record(String id, DateTime date, {List<String> items = const ['oil'], int? km}) => ServiceRecord(
  id: id,
  vehicleId: 'v',
  date: date,
  type: ServiceType.maintenance,
  odometerKm: km,
  itemCodes: items,
  createdAt: date,
);

ScheduleItem _oil({String? setBy, DateTime? baseline}) => ScheduleItem(
  id: 'v-oil',
  vehicleId: 'v',
  code: 'oil',
  nameEn: 'Engine oil',
  nameAr: 'زيت المحرك',
  severity: Severity.major,
  intervalMonths: 12,
  lastDoneDate: DateTime(2026, 5, 1),
  lastDoneKm: 50000,
  lastDoneSource: LastDoneSource.service,
  lastDoneRecordId: setBy,
  baselineDate: baseline,
  rescheduledDueDate: DateTime(2027, 6, 1),
);

class _Garage {
  _Garage() : garage = MockGarageRepository.forScenario('returning', now: _now);

  final MockGarageRepository garage;
  final records = MockServiceRecordRepository.forScenario('returning', now: _now);
}

/// Launches the sample garage on [vehicle] and opens [location].
Future<void> _open(
  WidgetTester tester,
  _Garage data,
  String location, {
  String vehicle = 'veh-camry',
  Size? screen,
  String? language,
  bool go = false,
}) async {
  screen == null ? usePhoneScreen(tester) : useScreen(tester, screen);
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(data.garage),
        serviceRecordRepositoryProvider.overrideWithValue(data.records),
        clockProvider.overrideWithValue(() => _now),
        preferencesRepositoryProvider.overrideWithValue(
          MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA', currency: 'SAR')),
        ),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  if (vehicle != 'veh-camry') {
    final container = ProviderScope.containerOf(tester.element(find.byType(DashboardScreen)));
    await container.read(currentVehicleProvider.notifier).select(vehicle);
    await tester.pumpAndSettle();
  }
  final router = GoRouter.of(tester.element(find.byType(DashboardScreen)));
  go ? router.go(location) : router.push(location);
  await tester.pumpAndSettle();
}

Finder _inRecord(Finder finder) => find.descendant(of: find.byType(ServiceRecordScreen), matching: finder);

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  group('BR-SVC-04 fallback', () {
    test('falls back to the next most recent record that covers the item', () {
      final older = _record('a', DateTime(2025, 12, 1), km: 40000);
      final deleted = _record('b', DateTime(2026, 5, 1), km: 50000);
      final updated = itemsAfterDeleting(
        deleted,
        schedule: [_oil(setBy: 'b')],
        remaining: [older, deleted],
      ).single;
      expect((updated.lastDoneDate, updated.lastDoneKm, updated.lastDoneRecordId), (DateTime(2025, 12, 1), 40000, 'a'));
      expect(updated.lastDoneSource, LastDoneSource.service);
      expect(updated.rescheduledDueDate, isNull, reason: 'the old cycle ended');
    });

    test('then the baseline', () {
      final deleted = _record('b', DateTime(2026, 5, 1));
      final updated = itemsAfterDeleting(
        deleted,
        schedule: [_oil(setBy: 'b', baseline: DateTime(2025, 1, 1))],
        remaining: [deleted],
      ).single;
      expect(
        (updated.lastDoneDate, updated.lastDoneKm, updated.lastDoneSource),
        (DateTime(2025, 1, 1), null, LastDoneSource.baseline),
      );
      expect(updated.lastDoneRecordId, isNull);
    });

    test('then Unknown', () {
      final deleted = _record('b', DateTime(2026, 5, 1));
      final updated = itemsAfterDeleting(
        deleted,
        schedule: [_oil(setBy: 'b')],
        remaining: const [],
      ).single;
      expect(updated.isUnknown, isTrue);
      expect(updated.lastDoneSource, isNull);
    });

    test('items the record didn\'t set are left alone', () {
      final deleted = _record('b', DateTime(2026, 5, 1));
      expect(
        itemsAfterDeleting(
          deleted,
          schedule: [_oil(setBy: 'other')],
          remaining: const [],
        ),
        isEmpty,
      );
    });

    test('lists join with "and"; the footer shows a 24-hour time', () {
      final en = AppLocalizationsEn();
      expect(joinWithAnd(en, ['Engine oil'], 'en'), 'Engine oil');
      expect(joinWithAnd(en, ['A', 'B', 'C'], 'en'), 'A, B and C');
      expect(joinWithAnd(AppLocalizationsAr(), ['أ', 'ب'], 'ar'), 'أ وب');
      expect(const AppFormatters(languageCode: 'en').dateTime(DateTime(2026, 11, 5, 10, 24)), 'Nov 5, 2026, 10:24');
    });
  });

  group('S-21 Service record', () {
    testWidgets('shows the date, type, facts, items, notes and when it was added', (tester) async {
      await _open(tester, _Garage(), '/history/record/rec-camry-1', go: true);

      expect(_inRecord(find.text('Nov 27, 2025')), findsOneWidget);
      expect(_inRecord(find.text('Maintenance')), findsOneWidget);
      expect(find.bySemanticsLabel('Odometer, 45,000\u00A0km'), findsOneWidget);
      expect(find.bySemanticsLabel('Cost, SAR\u00A0350'), findsOneWidget);
      expect(find.bySemanticsLabel('Shop, Al Futtaim Service'), findsOneWidget);
      expect(find.bySemanticsLabel('Engine oil. Open item'), findsOneWidget);
      expect(find.bySemanticsLabel('Oil filter. Open item'), findsOneWidget);
      expect(_inRecord(find.text('Synthetic 0W-20')), findsOneWidget);
      expect(_inRecord(find.text('Added Nov 27, 2025, 18:00')), findsOneWidget);
    });

    testWidgets('no items, no cost, no notes', (tester) async {
      await _open(tester, _Garage(), '/history/record/rec-camry-5', go: true);
      expect(_inRecord(find.text('Inspection')), findsOneWidget);
      expect(find.bySemanticsLabel('Cost, —'), findsOneWidget);
      expect(_inRecord(find.text('No schedule items. Nothing was reset.')), findsOneWidget);
      expect(_inRecord(find.text('No notes')), findsOneWidget);
    });

    testWidgets('an item chip opens S-15 inside History', (tester) async {
      await _open(tester, _Garage(), '/history/record/rec-camry-1', go: true);
      await tester.tap(find.bySemanticsLabel('Oil filter. Open item'));
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleItemScreen), findsOneWidget);
      expect(GoRouterState.of(tester.element(find.byType(ScheduleItemScreen))).uri.path, '/history/item/oil_filter');
    });

    testWidgets('Edit opens S-22 for this record', (tester) async {
      await _open(tester, _Garage(), '/history/record/rec-camry-1', go: true);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.byType(LogServiceScreen), findsOneWidget);
      expect(
        GoRouterState.of(tester.element(find.byType(LogServiceScreen))).uri.queryParameters['record'],
        'rec-camry-1',
      );
    });

    testWidgets('Delete names the items that go back, then Undo restores everything', (tester) async {
      final data = _Garage();
      await _open(tester, data, '/garage/record/rec-patrol-2', vehicle: 'veh-patrol');

      await tester.tap(find.byTooltip('More options').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('Delete this service?'), findsOneWidget);
      expect(find.text('Engine oil and Oil filter will go back to their previous dates.'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Service deleted'), findsOneWidget);
      expect(await data.records.record('rec-patrol-2'), isNull);
      var schedule = await data.garage.schedule('veh-patrol');
      expect(schedule.firstWhere((i) => i.code == 'engine_oil').isUnknown, isTrue);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(find.byType(ServiceRecordScreen), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(await data.records.record('rec-patrol-2'), isNotNull);
      schedule = await data.garage.schedule('veh-patrol');
      final restored = schedule.firstWhere((i) => i.code == 'engine_oil');
      expect((restored.lastDoneKm, restored.lastDoneRecordId), (109000, 'rec-patrol-2'));
    });

    testWidgets('a record that set nothing: plain message; Cancel keeps it', (tester) async {
      final data = _Garage();
      await _open(tester, data, '/garage/record/rec-camry-3');
      await tester.tap(find.byTooltip('More options').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('It will be removed from your history and spending.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(ServiceRecordScreen), findsOneWidget);
      expect(await data.records.record('rec-camry-3'), isNotNull);
    });

    testWidgets('S-15 lists the services that covered the item and opens them', (tester) async {
      await _open(tester, _Garage(), '/garage/item/engine_oil');
      final row = find.widgetWithText(ServiceRecordRow, 'Engine oil, Oil filter');
      await tester.scrollUntilVisible(row, 200, scrollable: find.byType(Scrollable).last);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(ServiceRecordScreen), findsOneWidget);
      expect(GoRouterState.of(tester.element(find.byType(ServiceRecordScreen))).uri.path, '/garage/record/rec-camry-1');
    });

    testWidgets('iPad: a side sheet with a close button', (tester) async {
      await _open(tester, _Garage(), '/garage/record/rec-camry-1', screen: const Size(768, 1024));
      expect(find.byType(CloseButton), findsOneWidget);
      expect(tester.getSize(find.byType(ServiceRecordScreen)).width, lessThanOrEqualTo(420));
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(find.byType(ServiceRecordScreen), findsNothing);
    });

    testWidgets('Arabic: translated, symbol after the amount, no overflow', (tester) async {
      await _open(tester, _Garage(), '/history/record/rec-camry-1', go: true, language: 'ar');
      expect(_inRecord(find.text('البنود المشمولة')), findsOneWidget);
      expect(find.bySemanticsLabel('التكلفة, 350\u00A0ر.س'), findsOneWidget);
      expect(_inRecord(find.text('صيانة دورية')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets tap-target and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _Garage(), '/history/record/rec-camry-1', go: true);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
