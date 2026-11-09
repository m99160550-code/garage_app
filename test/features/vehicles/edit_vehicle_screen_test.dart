import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/core/widgets/app_button.dart';
import 'package:tdc_garage/core/widgets/app_text_field.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/maintenance/data/template_repository.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_item.dart';
import 'package:tdc_garage/features/maintenance/domain/severity.dart';
import 'package:tdc_garage/features/onboarding/presentation/brand/brand_selection_screen.dart';
import 'package:tdc_garage/features/onboarding/presentation/model/model_selection_screen.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/service_history/application/service_history_providers.dart';
import 'package:tdc_garage/features/service_history/data/service_record_repository.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';
import 'package:tdc_garage/features/vehicles/domain/fuel_type.dart';
import 'package:tdc_garage/features/vehicles/domain/paint_color.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle_edit.dart';
import 'package:tdc_garage/features/vehicles/presentation/edit_vehicle_screen.dart';
import 'package:tdc_garage/features/vehicles/presentation/vehicles_screen.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

class _Setup {
  final garage = MockGarageRepository.forScenario('returning', now: _now);
  final records = MockServiceRecordRepository.forScenario('returning', now: _now);
}

Future<void> _launch(WidgetTester tester, _Setup setup, {Size? screen, String? language}) async {
  useScreen(tester, screen ?? const Size(390, 2000));
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(setup.garage),
        serviceRecordRepositoryProvider.overrideWithValue(setup.records),
        clockProvider.overrideWithValue(() => _now),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
}

/// Profile → Vehicles → a vehicle.
Future<void> _openEdit(WidgetTester tester, _Setup setup, {String vehicle = 'Family Camry', String? language}) async {
  await _launch(tester, setup, language: language);
  GoRouter.of(tester.element(find.byType(DashboardScreen))).go('/profile/vehicles');
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining(vehicle).first);
  await tester.pumpAndSettle();
  expect(find.byType(EditVehicleScreen), findsOneWidget);
}

Finder _field(String label) =>
    find.descendant(of: find.widgetWithText(AppTextField, label), matching: find.byType(EditableText));

String _text(WidgetTester tester, String label) => tester.widget<EditableText>(_field(label)).controller.text;

AppButton _save(WidgetTester tester) => tester.widget<AppButton>(find.widgetWithText(AppButton, 'Save'));

Future<void> _tapSave(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(AppButton, 'Save'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<Vehicle> _camry(WidgetTester tester, _Setup setup) async =>
    (await tester.runAsync(setup.garage.vehicles))!.firstWhere((v) => v.id == 'veh-camry');

void main() {
  group('S-32 rules', () {
    test('fuel change (BR-MNT-08): new template items, custom kept, edited intervals optional', () async {
      final ev = await const MockTemplateRepository().currentFor(FuelType.ev);
      final schedule = MockGarageRepository.sampleSchedulesAt(_now)['veh-camry']!;
      final brakes = schedule.firstWhere((i) => i.code == 'brake_pads');
      final edited = [
        for (final i in schedule)
          if (i.code == 'brake_pads') i.copyWith(intervalMonths: 18, intervalEdited: true) else i,
        const ScheduleItem(
          id: 'custom-1',
          vehicleId: 'veh-camry',
          code: 'custom_tint',
          nameEn: 'Window tint',
          nameAr: 'تظليل',
          severity: Severity.minor,
          intervalMonths: 24,
          isCustom: true,
        ),
      ];

      final kept = scheduleForFuelChange(
        vehicleId: 'veh-camry',
        schedule: edited,
        template: ev,
        keepEditedIntervals: true,
      );
      final codes = kept.map((i) => i.code).toSet();
      expect(codes.contains('engine_oil'), isFalse, reason: 'EVs have no engine oil');
      expect(codes.containsAll(ev.items.map((t) => t.code)), isTrue);
      expect(codes.contains('custom_tint'), isTrue);
      final keptBrakes = kept.firstWhere((i) => i.code == 'brake_pads');
      expect(keptBrakes.intervalMonths, 18);
      expect(keptBrakes.lastDoneDate, brakes.lastDoneDate, reason: 'history stays');
      expect(kept.firstWhere((i) => i.code == 'coolant').nameEn, 'Battery coolant');

      final replaced = scheduleForFuelChange(
        vehicleId: 'veh-camry',
        schedule: edited,
        template: ev,
        keepEditedIntervals: false,
      );
      final replacedBrakes = replaced.firstWhere((i) => i.code == 'brake_pads');
      expect((replacedBrakes.intervalMonths, replacedBrakes.intervalEdited), (36, false));
    });
  });

  testWidgets('the list: S-10 rows and Add vehicle; a row opens the prefilled form', (tester) async {
    final setup = _Setup();
    await _launch(tester, setup);
    GoRouter.of(tester.element(find.byType(DashboardScreen))).go('/profile/vehicles');
    await tester.pumpAndSettle();
    expect(find.byType(VehiclesScreen), findsOneWidget);
    expect(find.textContaining('Family Camry'), findsWidgets);
    expect(find.textContaining('Patrol'), findsWidgets);
    expect(find.text('Add vehicle'), findsOneWidget);

    await tester.tap(find.textContaining('Family Camry').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit vehicle'), findsOneWidget);
    expect(find.bySemanticsLabel('Brand, Toyota'), findsOneWidget);
    expect(find.bySemanticsLabel('Model, Camry'), findsOneWidget);
    expect(_text(tester, 'Current odometer'), '54,320');
    expect(_text(tester, 'Nickname'), 'Family Camry');
    expect(find.text('Delete vehicle'), findsOneWidget);
    expect(_save(tester).onPressed, isNull, reason: 'nothing changed yet');
  });

  testWidgets('save: nickname and paint change, toast, back to the list', (tester) async {
    final setup = _Setup();
    await _openEdit(tester, setup);
    await tester.enterText(_field('Nickname'), 'Weekend Camry');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(RegExp('^Polar White')).first);
    await tester.pump();
    await _tapSave(tester);

    expect(find.text('Changes saved'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(VehiclesScreen), findsOneWidget);
    final camry = await _camry(tester, setup);
    expect((camry.nickname, camry.paint, camry.vin), ('Weekend Camry', PaintColor.polarWhite, '4T1C11AK5NU123456'));
  });

  testWidgets('odometer: lower is refused; higher becomes a new reading', (tester) async {
    final setup = _Setup();
    await _openEdit(tester, setup);
    await tester.enterText(_field('Current odometer'), '50,000');
    await tester.pump();
    expect(
      find.text("Can't be lower than the last reading (‎54,320 km‎). Correct it in Mileage history."),
      findsOneWidget,
    );
    expect(_save(tester).onPressed, isNull);

    await tester.enterText(_field('Current odometer'), '55,000');
    await tester.pump();
    await _tapSave(tester);
    await tester.pumpAndSettle();
    expect((await _camry(tester, setup)).odometerKm, 55000);
    final readings = (await tester.runAsync(() => setup.garage.readings('veh-camry')))!;
    expect(readings.last.km, 55000);
  });

  testWidgets('a new fuel type asks; "Update schedule" regenerates it (BR-MNT-08)', (tester) async {
    final setup = _Setup();
    await _openEdit(tester, setup);
    await tester.tap(find.text('EV'));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Update the schedule for EV?'), findsOneWidget);
    expect(find.text("We'll replace the typical items. Your custom items and history stay."), findsOneWidget);
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isTrue);
    await tester.tap(find.text('Update schedule'));
    await tester.pumpAndSettle();

    expect((await _camry(tester, setup)).fuelType, FuelType.ev);
    final schedule = (await tester.runAsync(() => setup.garage.schedule('veh-camry')))!;
    expect(schedule.any((i) => i.code == 'engine_oil'), isFalse);
  });

  testWidgets('"Keep current schedule" changes only the fuel type', (tester) async {
    final setup = _Setup();
    final before = (await tester.runAsync(() => setup.garage.schedule('veh-camry')))!;
    await _openEdit(tester, setup);
    await tester.tap(find.text('EV'));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep current schedule'));
    await tester.pumpAndSettle();

    expect((await _camry(tester, setup)).fuelType, FuelType.ev);
    final after = (await tester.runAsync(() => setup.garage.schedule('veh-camry')))!;
    expect(after.map((i) => i.code), before.map((i) => i.code));
  });

  testWidgets('the Model row opens S-05 in edit mode and brings back the new model', (tester) async {
    final setup = _Setup();
    await _openEdit(tester, setup);
    await tester.tap(find.bySemanticsLabel('Model, Camry'));
    await tester.pumpAndSettle();
    expect(find.byType(ModelSelectionScreen), findsOneWidget);
    await tester.tap(find.text('Corolla'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(EditVehicleScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Model, Corolla'), findsOneWidget);
    await _tapSave(tester);
    await tester.pumpAndSettle();
    expect((await _camry(tester, setup)).modelId, 'toyota-corolla');
  });

  testWidgets('the Brand row opens S-04, then S-05, then returns', (tester) async {
    final setup = _Setup();
    await _openEdit(tester, setup);
    await tester.tap(find.bySemanticsLabel('Brand, Toyota'));
    await tester.pumpAndSettle();
    expect(find.byType(BrandSelectionScreen), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(EditVehicleScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Brand, Toyota'), findsOneWidget);
  });

  testWidgets('leaving with changes asks "Discard changes?"', (tester) async {
    await _openEdit(tester, _Setup());
    await tester.enterText(_field('Nickname'), 'Changed');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(VehiclesScreen), findsOneWidget);
  });

  testWidgets('delete: "This deletes its schedule and N service records", then the list (FR-VEH-12)', (tester) async {
    final setup = _Setup();
    final count = (await tester.runAsync(() => setup.records.records('veh-camry')))!.length;
    await _openEdit(tester, setup);
    final delete = find.text('Delete vehicle');
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text('Delete Family Camry?'), findsOneWidget);
    expect(find.text("This deletes its schedule and $count service records. This can't be undone."), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Family Camry deleted'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(VehiclesScreen), findsOneWidget);
    expect((await tester.runAsync(setup.garage.vehicles))!.map((v) => v.id), ['veh-patrol']);
    expect((await tester.runAsync(() => setup.records.records('veh-camry')))!, isEmpty);
  });

  testWidgets('deleting the last vehicle goes to brand selection (BR-VEH-06)', (tester) async {
    final setup = _Setup();
    await tester.runAsync(() => setup.garage.deleteVehicle('veh-patrol'));
    await _openEdit(tester, setup);
    await tester.ensureVisible(find.text('Delete vehicle'));
    await tester.tap(find.text('Delete vehicle'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.byType(BrandSelectionScreen), findsOneWidget);
  });

  testWidgets('the dashboard menu "Edit vehicle" edits the vehicle shown', (tester) async {
    await _launch(tester, _Setup());
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit vehicle'));
    await tester.pumpAndSettle();
    expect(find.byType(EditVehicleScreen), findsOneWidget);
    expect(_text(tester, 'Nickname'), 'Family Camry');
  });

  testWidgets('Arabic: translated, no overflow', (tester) async {
    await _openEdit(tester, _Setup(), language: 'ar');
    expect(find.text('تعديل المركبة'), findsOneWidget);
    expect(find.text('حذف المركبة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _openEdit(tester, _Setup());
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
