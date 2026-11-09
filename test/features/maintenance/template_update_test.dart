import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/features/garage/application/current_vehicle_controller.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/maintenance/application/template_update_controller.dart';
import 'package:tdc_garage/features/maintenance/data/template_repository.dart';
import 'package:tdc_garage/features/maintenance/domain/maintenance_template.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_item.dart';
import 'package:tdc_garage/features/maintenance/domain/severity.dart';
import 'package:tdc_garage/features/maintenance/domain/template_update.dart';
import 'package:tdc_garage/features/maintenance/presentation/schedule_screen.dart';
import 'package:tdc_garage/features/maintenance/presentation/template_update_sheet.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';
import 'package:tdc_garage/features/vehicles/domain/fuel_type.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);
final _v1 = MockTemplateRepository.templates[FuelType.petrol]!;
final _v2 = MockTemplateRepository.updates[FuelType.petrol]!;

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

Future<List<ScheduleItem>> _patrolSchedule(MockGarageRepository garage) => garage.schedule('veh-patrol');

ScheduleItem _byCode(List<ScheduleItem> items, String code) => items.firstWhere((i) => i.code == code);

/// Launches the app on the Patrol (petrol, template v1), optionally opening
/// [location] on top of the dashboard.
Future<ProviderContainer> _launch(
  WidgetTester tester,
  MockGarageRepository garage, {
  String? location,
  Size? screen,
  String? language,
  String vehicle = 'veh-patrol',
}) async {
  screen == null ? usePhoneScreen(tester) : useScreen(tester, screen);
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(garage),
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
  await container.read(currentVehicleProvider.notifier).select(vehicle);
  await tester.pumpAndSettle();
  if (location != null) {
    GoRouter.of(tester.element(find.byType(DashboardScreen))).push(location);
    await tester.pumpAndSettle();
  }
  return container;
}

/// The sheet's list builds rows lazily; scroll until [finder] is built.
Future<void> _scrollSheetTo(WidgetTester tester, Finder finder) => tester.scrollUntilVisible(
  finder,
  120,
  scrollable: find.descendant(of: find.byType(TemplateUpdateSheet), matching: find.byType(Scrollable)).first,
);

void main() {
  group('template rules (FR-REF-06, BR-REF-02)', () {
    test('lists changed items and marks edited ones as kept', () async {
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      final changes = templateChanges(schedule: await _patrolSchedule(garage), from: _v1, to: _v2);

      expect(changes.map((c) => c.code), unorderedEquals(['air_filter', 'cabin_filter', 'battery']));
      final air = changes.firstWhere((c) => c.code == 'air_filter');
      expect(air.monthsChanged, isTrue);
      expect(air.kmChanged, isTrue);
      expect(air.kept, isFalse);
      // The owner set the battery to 30 months.
      expect(changes.firstWhere((c) => c.code == 'battery').kept, isTrue);
    });

    test('a version with the same intervals offers nothing (wording only, BR-REF-08)', () async {
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      const reworded = MaintenanceTemplate(fuelType: FuelType.petrol, version: 2, items: []);
      final same = MaintenanceTemplate(fuelType: FuelType.petrol, version: 2, items: _v1.items);
      expect(templateChanges(schedule: await _patrolSchedule(garage), from: _v1, to: same), isEmpty);
      // Items dropped from the template are not listed (they stay on the car).
      expect(templateChanges(schedule: await _patrolSchedule(garage), from: _v1, to: reworded), isEmpty);
    });

    test('a new template item is listed and added as Unknown', () async {
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      const extra = TemplateItem(
        code: 'spark_plugs',
        nameEn: 'Spark plugs',
        nameAr: 'شمعات الإشعال',
        severity: Severity.major,
        intervalKm: 40000,
      );
      final to = MaintenanceTemplate(fuelType: FuelType.petrol, version: 2, items: [..._v1.items, extra]);
      final schedule = await _patrolSchedule(garage);
      final changes = templateChanges(schedule: schedule, from: _v1, to: to);
      expect(changes.single.isNew, isTrue);

      final applied = applyTemplateChanges(vehicleId: 'veh-patrol', schedule: schedule, changes: changes);
      final plugs = _byCode(applied, 'spark_plugs');
      expect(plugs.isUnknown, isTrue);
      expect(plugs.intervalKm, 40000);
      expect(applied, hasLength(schedule.length + 1));
    });

    test('Apply updates unedited items only and keeps last done, N/A and custom items', () async {
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      final schedule = [
        for (final item in await _patrolSchedule(garage))
          item.code == 'cabin_filter' ? item.copyWith(notApplicable: true) : item,
        const ScheduleItem(
          id: 'custom-1',
          vehicleId: 'veh-patrol',
          code: 'custom-1',
          nameEn: 'Roof rack',
          nameAr: 'Roof rack',
          severity: Severity.minor,
          intervalMonths: 6,
          isCustom: true,
        ),
      ];
      final changes = templateChanges(schedule: schedule, from: _v1, to: _v2);
      final applied = applyTemplateChanges(vehicleId: 'veh-patrol', schedule: schedule, changes: changes);

      final air = _byCode(applied, 'air_filter');
      expect((air.intervalMonths, air.intervalKm, air.intervalEdited), (12, 20000, false));
      final cabin = _byCode(applied, 'cabin_filter');
      expect((cabin.intervalKm, cabin.notApplicable), (10000, true));
      final battery = _byCode(applied, 'battery');
      expect((battery.intervalMonths, battery.intervalEdited), (30, true));
      expect(battery.lastDoneDate, _byCode(schedule, 'battery').lastDoneDate);
      expect(_byCode(applied, 'custom-1').intervalMonths, 6);
    });
  });

  group('template update provider', () {
    test('offers v2 to the Patrol only, and stops after Keep current', () async {
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      final container = ProviderContainer(overrides: [garageRepositoryProvider.overrideWithValue(garage)]);
      addTearDown(container.dispose);

      expect(await container.read(templateUpdateProvider('veh-camry').future), isNull);
      final update = await container.read(templateUpdateProvider('veh-patrol').future);
      expect(update?.to.version, 2);
      expect(update?.applicableCount, 2);

      await container.read(templateUpdateActionsProvider).keepCurrent(update!);
      expect(await container.read(templateUpdateProvider('veh-patrol').future), isNull);
      expect((await garage.vehicles()).last.templateVersion, 1);
    });

    test('Apply moves the vehicle to v2', () async {
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      final container = ProviderContainer(overrides: [garageRepositoryProvider.overrideWithValue(garage)]);
      addTearDown(container.dispose);

      final update = await container.read(templateUpdateProvider('veh-patrol').future);
      await container.read(templateUpdateActionsProvider).apply(update!);

      expect((await garage.vehicles()).last.templateVersion, 2);
      expect(_byCode(await _patrolSchedule(garage), 'air_filter').intervalKm, 20000);
      expect(await container.read(templateUpdateProvider('veh-patrol').future), isNull);
    });
  });

  group('S-17 Template update', () {
    testWidgets('the S-14 banner opens the sheet with the changes', (tester) async {
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      await _launch(tester, garage, location: '/garage/schedule');

      expect(find.text('Typical intervals updated'), findsOneWidget);
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();

      expect(find.byType(TemplateUpdateSheet), findsOneWidget);
      final sheet = find.byType(TemplateUpdateSheet);
      expect(find.descendant(of: sheet, matching: find.textContaining('hot, dusty')), findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('Air filter')), findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('Every 24 → 12 months')), findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.textContaining(RegExp(r'30,000.km → 20,000.km'))),
        findsOneWidget,
      );
      await _scrollSheetTo(tester, find.textContaining('template v2'));
      expect(find.descendant(of: sheet, matching: find.text('Kept: you edited this')), findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.textContaining('template v2')), findsOneWidget);
    });

    testWidgets('Apply updates the schedule, shows a toast and removes the banner', (tester) async {
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      await _launch(tester, garage, location: '/garage/schedule');
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Schedule updated'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.byType(TemplateUpdateSheet), findsNothing);
      expect(find.text('Review'), findsNothing);
      expect(_byCode(await _patrolSchedule(garage), 'air_filter').intervalMonths, 12);
      expect(_byCode(await _patrolSchedule(garage), 'battery').intervalMonths, 30);
    });

    testWidgets('Keep current hides the banner and changes nothing', (tester) async {
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      await _launch(tester, garage, location: '/garage/schedule');
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep current'));
      await tester.pumpAndSettle();

      expect(find.byType(TemplateUpdateSheet), findsNothing);
      expect(find.text('Review'), findsNothing);
      expect(find.byType(ScheduleScreen), findsOneWidget);
      expect(_byCode(await _patrolSchedule(garage), 'air_filter').intervalMonths, 24);
    });

    testWidgets('dismissing the sheet keeps the banner', (tester) async {
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      await _launch(tester, garage, location: '/garage/schedule');
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 40)); // The scrim above the sheet.
      await tester.pumpAndSettle();

      expect(find.byType(TemplateUpdateSheet), findsNothing);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('the dashboard overflow shows the badge and opens the sheet', (tester) async {
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      await _launch(tester, garage);

      expect(find.byTooltip('More options, Updated intervals'), findsOneWidget);
      await tester.tap(find.byTooltip('More options, Updated intervals'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review updated intervals'));
      await tester.pumpAndSettle();
      expect(find.byType(TemplateUpdateSheet), findsOneWidget);
    });

    testWidgets('a car on the latest template has no badge or menu item', (tester) async {
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      await _launch(tester, garage, vehicle: 'veh-camry');

      expect(find.byTooltip('More options'), findsOneWidget);
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      expect(find.text('Review updated intervals'), findsNothing);
    });

    testWidgets('Arabic: arrows point to the new value and nothing overflows', (tester) async {
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      await _launch(tester, garage, location: '/garage/schedule', language: 'ar');
      await tester.tap(find.text('مراجعة'));
      await tester.pumpAndSettle();

      final sheet = find.byType(TemplateUpdateSheet);
      expect(find.descendant(of: sheet, matching: find.text('تم تحديث الفترات المعتادة')), findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('كل 24 ← 12 شهرًا')), findsOneWidget);
      await _scrollSheetTo(tester, find.text('محفوظ: عدّلته بنفسك'));
      expect(find.descendant(of: sheet, matching: find.text('محفوظ: عدّلته بنفسك')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet: a centred dialog', (tester) async {
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      await _launch(tester, garage, location: '/garage/schedule', screen: const Size(1024, 768));
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.getSize(find.byType(TemplateUpdateSheet)).width, lessThanOrEqualTo(560));
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets tap-target and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      final garage = MockGarageRepository.forScenario('returning', now: _now);
      await _launch(tester, garage, location: '/garage/schedule', screen: const Size(390, 1600));
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
