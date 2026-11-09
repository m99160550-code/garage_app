import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/account/presentation/backup_offer_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/core/widgets/app_choice_chip.dart';
import 'package:tdc_garage/core/widgets/app_text_field.dart';
import 'package:tdc_garage/features/garage/application/current_vehicle_controller.dart';
import 'package:tdc_garage/features/garage/application/vehicle_dues.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/maintenance/domain/item_due.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_item.dart';
import 'package:tdc_garage/features/maintenance/domain/severity.dart';
import 'package:tdc_garage/features/maintenance/presentation/item_interval_screen.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/service_history/application/service_history_providers.dart';
import 'package:tdc_garage/features/service_history/data/service_record_repository.dart';
import 'package:tdc_garage/features/service_history/domain/log_service_rules.dart';
import 'package:tdc_garage/features/service_history/domain/service_record.dart';
import 'package:tdc_garage/features/service_history/presentation/log_service_screen.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/distance_unit.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);
final _today = DateTime(2026, 11, 7);

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

ScheduleItem _item(String code, {DateTime? done, String? setBy, bool notApplicable = false}) => ScheduleItem(
  id: 'v-$code',
  vehicleId: 'v',
  code: code,
  nameEn: code,
  nameAr: code,
  severity: Severity.minor,
  intervalMonths: 12,
  lastDoneDate: done,
  lastDoneSource: done == null ? null : LastDoneSource.service,
  lastDoneRecordId: setBy,
  notApplicable: notApplicable,
  rescheduledDueDate: done == null ? null : DateTime(2027, 9, 1),
  snoozedUntil: done == null ? null : DateTime(2026, 11, 20),
);

ServiceRecord _record(String id, DateTime date, List<String> items) => ServiceRecord(
  id: id,
  vehicleId: 'v',
  date: date,
  type: ServiceType.maintenance,
  odometerKm: 50000,
  itemCodes: items,
  createdAt: date,
);

class _Data {
  _Data({List<ServiceRecord>? records})
    : garage = MockGarageRepository.forScenario('returning', now: _now),
      records = records == null
          ? MockServiceRecordRepository.forScenario('returning', now: _now)
          : MockServiceRecordRepository(records);

  final MockGarageRepository garage;
  final MockServiceRecordRepository records;
}

/// Launches the sample garage, then opens [location] from the dashboard.
Future<ProviderContainer> _open(
  WidgetTester tester,
  _Data data,
  String location, {
  String? vehicle,
  Size? screen,
  String? language,
}) async {
  screen == null ? useScreen(tester, const Size(390, 1400)) : useScreen(tester, screen);
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
  final container = ProviderScope.containerOf(tester.element(find.byType(DashboardScreen)));
  if (vehicle != null) {
    await container.read(currentVehicleProvider.notifier).select(vehicle);
    await tester.pumpAndSettle();
  }
  GoRouter.of(tester.element(find.byType(DashboardScreen))).push(location);
  await tester.pumpAndSettle();
  expect(find.byType(LogServiceScreen), findsOneWidget);
  return container;
}

Finder _field(String label) =>
    find.descendant(of: find.widgetWithText(AppTextField, label), matching: find.byType(EditableText));

String _fieldText(WidgetTester tester, String label) => tester.widget<EditableText>(_field(label)).controller.text;

AppChoiceChip _chip(WidgetTester tester, String label) =>
    tester.widget<AppChoiceChip>(find.widgetWithText(AppChoiceChip, label));

Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.widgetWithText(AppChoiceChip, label));
  await tester.tap(find.widgetWithText(AppChoiceChip, label));
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Save service'));
  await tester.tap(find.text('Save service'));
  // The mock repositories answer after a short delay.
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('S-22 rules', () {
    test('a record resets covered items, ending reschedule and snooze (FR-SVC-03, BR-SVC-07)', () {
      final record = _record('r', _today, ['oil', 'filter']);
      final result = applyRecord(record, [_item('oil', done: DateTime(2025, 11, 1)), _item('filter'), _item('wipers')]);
      expect(result.kept, isEmpty);
      expect(result.updated.map((i) => i.code), ['oil', 'filter']);
      final oil = result.updated.first;
      expect((oil.lastDoneDate, oil.lastDoneKm, oil.lastDoneRecordId), (_today, 50000, 'r'));
      expect((oil.rescheduledDueDate, oil.snoozedUntil), (null, null));
      expect(result.updated.last.isUnknown, isFalse, reason: 'an Unknown item becomes known');
    });

    test('a backdated record keeps a newer last done (BR-SVC-02)', () {
      final record = _record('r', DateTime(2026, 1, 1), ['oil']);
      final result = applyRecord(record, [_item('oil', done: DateTime(2026, 6, 1))]);
      expect(result.updated, isEmpty);
      expect(result.kept.single.code, 'oil');
    });

    test('editing: items removed from the record fall back, added ones reset (BR-SVC-04)', () {
      final older = _record('old', DateTime(2025, 6, 1), ['oil']);
      final before = _record('r', DateTime(2026, 5, 1), ['oil']);
      final after = _record('r', DateTime(2026, 5, 1), ['filter']);
      final result = applyEdit(
        before,
        after,
        schedule: [
          _item('oil', done: DateTime(2026, 5, 1), setBy: 'r'),
          _item('filter'),
        ],
        otherRecords: [older],
      );
      final byCode = {for (final i in result.updated) i.code: i};
      expect(byCode['oil']!.lastDoneRecordId, 'old');
      expect(byCode['filter']!.lastDoneRecordId, 'r');
    });

    test('chip order: preselected, overdue, due soon, then the rest; not N/A', () {
      final dues = vehicleDues(
        MockGarageRepository.sampleVehicles.last,
        [
          _item('ok', done: _today.subtract(const Duration(days: 30))),
          _item('soon', done: _today.subtract(const Duration(days: 350))),
          _item('late', done: _today.subtract(const Duration(days: 400))),
          _item('na', notApplicable: true),
          _item('picked'),
        ].map((i) => i.copyWith(clearReschedule: true, clearSnooze: true)).toList(),
        readings: const [],
        unit: DistanceUnit.km,
        today: _today,
      );
      expect(dues.firstWhere((d) => d.item.code == 'late').status, ItemStatus.overdue);
      expect(chipOrder(dues, {'picked'}).map((d) => d.item.code), ['picked', 'late', 'soon', 'ok']);
    });

    test('cost parsing follows the currency (BR-EXP-04, BR-SVC-05)', () {
      expect(parseCost('', 'SAR'), (minor: null, issue: null));
      expect(parseCost('120', 'SAR').minor, 12000);
      expect(parseCost('120.5', 'SAR').minor, 12050);
      expect(parseCost('1,200.50', 'SAR').minor, 120050);
      expect(parseCost('120٫5', 'SAR').minor, 12050);
      expect(parseCost('12.5', 'KWD').minor, 12500);
      expect(parseCost('12.345', 'SAR').issue, CostIssue.tooManyDecimals);
      expect(parseCost('-5', 'SAR').issue, CostIssue.negative);
      expect(parseCost('1.2.3', 'SAR').issue, CostIssue.notANumber);
      expect(costText(12050, 'SAR'), '120.50');
      expect(costText(35000, 'SAR'), '350');
      expect(costText(1200, 'JPY'), '1200');
    });

    test('shop suggestions: newest first, no repeats', () {
      final records = MockServiceRecordRepository.sampleRecordsAt(_now);
      final shops = shopSuggestions(records);
      expect(shops.first, 'Fahas');
      expect(shops.where((s) => s == 'Al Futtaim Service'), hasLength(1));
    });
  });

  group('S-22 Log service', () {
    testWidgets('opens with today, the current odometer and the item preselected', (tester) async {
      await _open(tester, _Data(), '/log-service?items=engine_oil');

      expect(find.text('Log service'), findsOneWidget);
      expect(_fieldText(tester, 'Date'), 'Nov 7, 2026');
      expect(_fieldText(tester, 'Odometer'), '54,320');
      expect(find.text('Current: 54,320\u00A0km'), findsOneWidget);
      expect(find.text('For: Family Camry'), findsOneWidget);
      expect(_chip(tester, 'Engine oil').selected, isTrue);
      expect(_chip(tester, 'Oil filter').selected, isFalse);
      expect(_chip(tester, 'Engine oil').semanticLabel, 'Engine oil, Due soon');
      // Preselected first, then due soon (oil filter).
      final chips = tester.widgetList<AppChoiceChip>(find.byType(AppChoiceChip)).map((c) => c.label).toList();
      expect(chips.take(2), ['Engine oil', 'Oil filter']);
      expect(chips.last, 'Add custom item');
      expect(find.text('SAR'), findsOneWidget);
    });

    testWidgets('type follows the items until picked: Repair without items', (tester) async {
      await _open(tester, _Data(), '/log-service');
      expect(find.bySemanticsLabel(RegExp(r'^Type, Repair')), findsOneWidget);
      await _tapChip(tester, 'Engine oil');
      expect(find.bySemanticsLabel(RegExp(r'^Type, Maintenance')), findsOneWidget);
    });

    testWidgets('save resets the items, adds the record and reading, and confirms the score', (tester) async {
      final data = _Data();
      await _open(tester, data, '/log-service?items=engine_oil');
      await _tapChip(tester, 'Oil filter');
      await tester.enterText(_field('Odometer'), '55000');
      await tester.enterText(_field('Cost (optional)'), '350');
      await tester.enterText(_field('Shop (optional)'), 'Al Futtaim Service');
      await tester.pumpAndSettle();
      await _save(tester);

      expect(find.textContaining(RegExp(r'^Service saved · score now \d+$')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(LogServiceScreen), findsNothing);

      final record = (await data.records.records('veh-camry')).first;
      expect((record.date, record.odometerKm, record.costMinor, record.currency), (_today, 55000, 35000, 'SAR'));
      expect(record.itemCodes, ['engine_oil', 'oil_filter']);
      expect(record.type, ServiceType.maintenance);
      final oil = (await data.garage.schedule('veh-camry')).firstWhere((i) => i.code == 'engine_oil');
      expect((oil.lastDoneDate, oil.lastDoneKm, oil.lastDoneRecordId), (_today, 55000, record.id));
      // The higher odometer is the new reading (BR-SVC-03).
      expect((await data.garage.vehicles()).first.odometerKm, 55000);
    });

    testWidgets('a lower odometer today asks for a correction', (tester) async {
      final data = _Data();
      await _open(tester, data, '/log-service?items=engine_oil');
      await tester.enterText(_field('Odometer'), '54000');
      await tester.pumpAndSettle();
      await _save(tester);
      await tester.pumpAndSettle();

      expect(find.text('This is lower than your last reading'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.byType(LogServiceScreen), findsOneWidget);
      expect(await data.records.records('veh-camry'), hasLength(5), reason: 'nothing saved');

      await _save(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save as correction'));
      await tester.pumpAndSettle();
      final readings = await data.garage.readings('veh-camry');
      expect(readings.last.isCorrection, isTrue);
      expect((await data.garage.vehicles()).first.odometerKm, 54000);
    });

    testWidgets('invalid cost: inline error and Save disabled', (tester) async {
      await _open(tester, _Data(), '/log-service?items=engine_oil');
      await tester.enterText(_field('Cost (optional)'), '12.345');
      await tester.pumpAndSettle();
      expect(find.text('SAR uses 2 decimal places.'), findsOneWidget);
      final save = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
      expect(save.onPressed, isNull);
    });

    testWidgets('leaving with changes asks "Discard this service?"', (tester) async {
      await _open(tester, _Data(), '/log-service');
      await _tapChip(tester, 'Engine oil');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Discard this service?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.byType(LogServiceScreen), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.byType(LogServiceScreen), findsNothing);
    });

    testWidgets('edit: prefilled, saved over the same record', (tester) async {
      final data = _Data();
      await _open(tester, data, '/log-service?record=rec-camry-1');

      expect(find.text('Edit service'), findsOneWidget);
      expect(find.textContaining('For:'), findsNothing, reason: 'a record stays with its vehicle');
      expect(_fieldText(tester, 'Date'), 'Nov 27, 2025');
      expect(_fieldText(tester, 'Odometer'), '45,000');
      expect(_fieldText(tester, 'Cost (optional)'), '350');
      expect(_fieldText(tester, 'Shop (optional)'), 'Al Futtaim Service');
      expect(_chip(tester, 'Oil filter').selected, isTrue);

      await tester.enterText(_field('Cost (optional)'), '400');
      await tester.pumpAndSettle();
      await _save(tester);
      await tester.pumpAndSettle();
      final record = await data.records.record('rec-camry-1');
      expect(record!.costMinor, 40000);
      expect(record.createdAt, DateTime(2025, 11, 27, 18));
      expect(await data.records.records('veh-camry'), hasLength(5));
    });

    testWidgets('"Add custom item" creates the item and selects it', (tester) async {
      await _open(tester, _Data(), '/log-service');
      await _tapChip(tester, 'Add custom item');
      expect(find.byType(ItemIntervalScreen), findsOneWidget);
      await tester.enterText(
        find.descendant(of: find.widgetWithText(AppTextField, 'Name'), matching: find.byType(EditableText)),
        'Roof rack',
      );
      await tester.enterText(
        find.descendant(of: find.widgetWithText(AppTextField, 'Every … months'), matching: find.byType(EditableText)),
        '6',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(LogServiceScreen), findsOneWidget);
      expect(_chip(tester, 'Roof rack').selected, isTrue);
    });

    testWidgets('another vehicle: its odometer and items', (tester) async {
      await _open(tester, _Data(), '/log-service');
      await tester.tap(find.text('For: Family Camry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nissan Patrol').last);
      await tester.pumpAndSettle();
      expect(find.text('For: Nissan Patrol'), findsOneWidget);
      expect(_fieldText(tester, 'Odometer'), '121,400');
      expect(_chip(tester, 'Engine oil').semanticLabel, 'Engine oil, Overdue');
    });

    testWidgets('shop names used before are suggested', (tester) async {
      await _open(tester, _Data(), '/log-service');
      await tester.ensureVisible(_field('Shop (optional)'));
      await tester.enterText(_field('Shop (optional)'), 'futt');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Al Futtaim Service').last);
      await tester.pumpAndSettle();
      expect(_fieldText(tester, 'Shop (optional)'), 'Al Futtaim Service');
    });

    testWidgets('first service: the backup offer follows 600 ms later', (tester) async {
      await _open(tester, _Data(records: []), '/log-service?items=engine_oil');
      await _save(tester);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.byType(BackupOfferSheet), findsOneWidget);
    });

    testWidgets('tablet: a centred modal at most 600 wide', (tester) async {
      await _open(tester, _Data(), '/log-service', screen: const Size(1024, 768));
      expect(tester.getSize(find.byType(LogServiceScreen)).width, lessThanOrEqualTo(600));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arabic: translated, no overflow', (tester) async {
      await _open(tester, _Data(), '/log-service?items=engine_oil', language: 'ar');
      expect(find.text('تسجيل صيانة'), findsOneWidget);
      expect(find.text('ما الذي تم إنجازه؟'), findsOneWidget);
      expect(find.text('حفظ الصيانة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets tap-target and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _Data(), '/log-service?items=engine_oil', screen: const Size(390, 1800));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
