import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/core/widgets/stat_card.dart';
import 'package:tdc_garage/features/garage/application/current_vehicle_controller.dart';
import 'package:tdc_garage/features/garage/application/vehicle_dues.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/maintenance/domain/dashboard_summary.dart';
import 'package:tdc_garage/features/maintenance/domain/item_due.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_item.dart';
import 'package:tdc_garage/features/maintenance/domain/severity.dart';
import 'package:tdc_garage/features/maintenance/presentation/next_service_sheet.dart';
import 'package:tdc_garage/features/maintenance/presentation/schedule_item_detail.dart';
import 'package:tdc_garage/features/maintenance/presentation/schedule_screen.dart';
import 'package:tdc_garage/features/maintenance/presentation/widgets/schedule_item_row.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/distance_unit.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';
import 'package:tdc_garage/features/vehicles/domain/body_type.dart';
import 'package:tdc_garage/features/vehicles/domain/fuel_type.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle.dart';

import 'package:tdc_garage/features/service_history/presentation/log_service_screen.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);
final _today = DateTime(2026, 11, 7);

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

/// The dues of a sample car, as the dashboard computes them.
Future<List<ItemDue>> _sampleDues(String vehicleId) async {
  final garage = MockGarageRepository.forScenario('returning', now: _now);
  final vehicle = (await garage.vehicles()).firstWhere((v) => v.id == vehicleId);
  return vehicleDues(
    vehicle,
    await garage.schedule(vehicleId),
    readings: await garage.readings(vehicleId),
    unit: DistanceUnit.km,
    today: _today,
  );
}

const _car = Vehicle(
  id: 'car',
  brandId: 'toyota',
  modelId: 'toyota-camry',
  fuelType: FuelType.petrol,
  bodyType: BodyType.sedan,
  odometerKm: 30000,
);

ScheduleItem _item(String code, {int? months, int? km, DateTime? date, int? doneKm}) => ScheduleItem(
  id: code,
  vehicleId: 'car',
  code: code,
  nameEn: code,
  nameAr: code,
  severity: Severity.minor,
  intervalMonths: months,
  intervalKm: km,
  lastDoneDate: date,
  lastDoneKm: doneKm,
);

List<ItemDue> _dues(List<ScheduleItem> items) =>
    vehicleDues(_car, items, readings: const [], unit: DistanceUnit.km, today: _today);

Future<void> _launch(WidgetTester tester, {String vehicle = 'veh-camry', Size? screen, String? language}) async {
  screen == null ? usePhoneScreen(tester) : useScreen(tester, screen);
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(MockGarageRepository.forScenario('returning', now: _now)),
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
}

Finder get _nextServiceCard =>
    find.byWidgetPredicate((w) => w is StatCard && (w.label == 'Next service' || w.label == 'الصيانة القادمة'));

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(_nextServiceCard.first);
  await tester.pumpAndSettle();
  expect(find.byType(NextServiceSheet), findsOneWidget);
}

Finder _inSheet(Finder finder) => find.descendant(of: find.byType(NextServiceSheet), matching: finder);

/// The route URI of the screen showing [finder].
Uri _uriOf(WidgetTester tester, Finder finder) => GoRouterState.of(tester.element(finder)).uri;

void main() {
  group('nextServiceGroup (S-18)', () {
    test('Camry: the next date and the items due within 30 days of it', () async {
      final group = nextServiceGroup(await _sampleDues('veh-camry'), today: _today);
      expect(group.overdue, isFalse);
      expect(group.date, DateTime(2026, 11, 27));
      expect(group.daysAway, 20);
      expect(group.items.map((d) => d.item.code), ['engine_oil', 'oil_filter']);
    });

    test('Patrol: overdue items first, with the most days overdue', () async {
      final group = nextServiceGroup(await _sampleDues('veh-patrol'), today: _today);
      expect(group.overdue, isTrue);
      expect(group.overdueDays, 40);
      expect(group.items.take(2).every((d) => d.status == ItemStatus.overdue), isTrue);
    });

    test('the 30-day window counts from the next due date', () {
      final group = nextServiceGroup(
        _dues([
          _item('a', months: 12, date: DateTime(2025, 12, 1)), // Due Dec 1.
          _item('b', months: 12, date: DateTime(2025, 12, 31)), // Dec 31: 30 days later.
          _item('c', months: 12, date: DateTime(2026, 1, 2)), // Jan 2: outside.
        ]),
        today: _today,
      );
      expect(group.date, DateTime(2026, 12, 1));
      expect(group.items.map((d) => d.item.code), ['a', 'b']);
    });

    test('mileage-only items without a prediction: distance to go', () {
      final group = nextServiceGroup(
        _dues([_item('a', km: 10000, doneKm: 25000), _item('b', km: 20000, doneKm: 25000)]),
        today: _today,
      );
      expect(group.date, isNull);
      expect(group.kmAway, 5000);
      expect(group.items.map((d) => d.item.code), ['a']);
    });

    test('nothing known: no items', () {
      final group = nextServiceGroup(_dues([_item('a', months: 12)]), today: _today);
      expect(group.items, isEmpty);
      expect(group.overdue, isFalse);
    });
  });

  group('S-18 Next service sheet', () {
    testWidgets('the Next service card opens the sheet with the date and items', (tester) async {
      await _launch(tester);
      await _openSheet(tester);

      expect(_inSheet(find.text('Next service')), findsOneWidget);
      expect(_inSheet(find.text('Fri, Nov 27')), findsOneWidget);
      expect(_inSheet(find.text('In 20 days')), findsOneWidget);
      expect(_inSheet(find.byType(ScheduleItemRow)), findsNWidgets(2));
      expect(_inSheet(find.text('Engine oil')), findsOneWidget);
      expect(_inSheet(find.text('Oil filter')), findsOneWidget);
      expect(_inSheet(find.text('Tires and rotation')), findsNothing);
      expect(tester.widget<ScheduleItemRow>(_inSheet(find.byType(ScheduleItemRow)).first).compact, isTrue);
    });

    testWidgets('Log service opens S-22 with these items preselected', (tester) async {
      await _launch(tester);
      await _openSheet(tester);
      await tester.tap(find.text('Log service'));
      await tester.pumpAndSettle();

      expect(find.byType(NextServiceSheet), findsNothing);
      expect(find.byType(LogServiceScreen), findsOneWidget);
      expect(_uriOf(tester, find.byType(LogServiceScreen)).queryParameters['items'], 'engine_oil,oil_filter');
    });

    testWidgets('See full schedule opens S-14', (tester) async {
      await _launch(tester);
      await _openSheet(tester);
      await tester.tap(find.text('See full schedule'));
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleScreen), findsOneWidget);
    });

    testWidgets('an item row opens S-15', (tester) async {
      await _launch(tester);
      await _openSheet(tester);
      await tester.tap(_inSheet(find.text('Oil filter')));
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleItemScreen), findsOneWidget);
      expect(_uriOf(tester, find.byType(ScheduleItemScreen)).path, contains('oil_filter'));
    });

    testWidgets('overdue: red "Overdue" title, days overdue, overdue items first', (tester) async {
      await _launch(tester, vehicle: 'veh-patrol');
      await _openSheet(tester);

      expect(_inSheet(find.text('Overdue')), findsWidgets);
      expect(_inSheet(find.text('40 days overdue')), findsOneWidget);
      expect(_inSheet(find.text('TO DO NOW')), findsOneWidget);
      final rows = tester.widgetList<ScheduleItemRow>(_inSheet(find.byType(ScheduleItemRow))).toList();
      expect(rows.first.due.status, ItemStatus.overdue);
    });

    testWidgets('Arabic: the date keeps Western digits and nothing overflows', (tester) async {
      await _launch(tester, language: 'ar');
      await _openSheet(tester);

      expect(_inSheet(find.textContaining('27')), findsWidgets);
      expect(_inSheet(find.text('بعد 20 يومًا')), findsOneWidget);
      expect(_inSheet(find.text('تسجيل صيانة')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet: a centred dialog', (tester) async {
      await _launch(tester, screen: const Size(1024, 768));
      await _openSheet(tester);
      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.getSize(find.byType(NextServiceSheet)).width, lessThanOrEqualTo(480));
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets tap-target and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await _launch(tester, vehicle: 'veh-patrol');
      await _openSheet(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
