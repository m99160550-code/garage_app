import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/maintenance/presentation/item_interval_screen.dart';
import 'package:tdc_garage/features/maintenance/presentation/schedule_item_detail.dart';
import 'package:tdc_garage/features/maintenance/presentation/schedule_screen.dart';
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

/// Opens the dashboard, pushes [first] (S-15 or S-14), then [form].
Future<MockGarageRepository> _open(
  WidgetTester tester, {
  required String first,
  required String form,
  Size? screen,
  String? language,
}) async {
  screen == null ? usePhoneScreen(tester) : useScreen(tester, screen);
  final garage = MockGarageRepository.forScenario('returning', now: _now);
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
  final router = GoRouter.of(tester.element(find.byType(DashboardScreen)));
  router.push(first);
  await tester.pumpAndSettle();
  router.push(form);
  await tester.pumpAndSettle();
  expect(find.byType(ItemIntervalScreen), findsOneWidget);
  return garage;
}

Future<void> _editOil(WidgetTester tester, {Size? screen, String? language}) => _open(
  tester,
  first: '/garage/item/engine_oil',
  form: '/schedule-item/engine_oil/interval',
  screen: screen,
  language: language,
);

Future<MockGarageRepository> _addCustom(WidgetTester tester) =>
    _open(tester, first: '/garage/schedule', form: '/schedule-item/new');

Finder _field(String label) => find.widgetWithText(TextFormField, label);
Finder get _save => find.widgetWithText(TextButton, 'Save');

Future<void> _type(WidgetTester tester, String label, String value) async {
  await tester.enterText(_field(label), value);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('editing an interval: prefilled, typical shown, saved as edited', (tester) async {
    await _editOil(tester);
    expect(find.text('Edit interval'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('15,000'), findsOneWidget);
    expect(find.text('Typical: Every 12 months or 15,000\u00A0km'), findsOneWidget);

    await _type(tester, 'Every … months', '6');
    await tester.tap(_save);
    await tester.pumpAndSettle();

    expect(find.text('Interval updated'), findsOneWidget);
    expect(find.byType(ScheduleItemDetail), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Interval, Every 6 months or 15,000.km, Edited$')), findsOneWidget);
  });

  testWidgets('at least one interval, and above 0', (tester) async {
    await _editOil(tester);
    await _type(tester, 'Every … months', '');
    await _type(tester, 'Every … km', '');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('Set at least one interval.'), findsOneWidget);

    await _type(tester, 'Every … months', '0');
    expect(find.text('Must be more than 0'), findsOneWidget);
    expect(find.byType(ItemIntervalScreen), findsOneWidget, reason: 'not saved');
  });

  testWidgets('Reset to typical fills the template values back in', (tester) async {
    await _editOil(tester);
    await _type(tester, 'Every … months', '6');
    await tester.tap(find.text('Reset to typical'));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('importance can be changed and shows the point impact', (tester) async {
    await _editOil(tester);
    expect(find.textContaining('Overdue:'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Importance, Critical')));
    await tester.pumpAndSettle();
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('Critical'), findsOneWidget, reason: 'severity badge on S-15');
  });

  testWidgets('adding a custom item: name required, then it joins the schedule', (tester) async {
    final garage = await _addCustom(tester);
    expect(find.text('Add custom item'), findsOneWidget);
    await _type(tester, 'Every … months', '1');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('Enter a name'), findsOneWidget);

    await _type(tester, 'Name', 'Car wash');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('Car wash added'), findsOneWidget);
    expect(find.byType(ScheduleScreen), findsOneWidget);
    final added = (await tester.runAsync(() => garage.schedule('veh-camry')))!.last;
    expect(added.nameEn, 'Car wash');
    expect(added.isCustom, isTrue);
    expect(added.intervalMonths, 1);
    expect(added.isUnknown, isTrue, reason: 'no last done given');
  });

  testWidgets('a custom item can start with a last-done date', (tester) async {
    final garage = await _addCustom(tester);
    await _type(tester, 'Name', 'Car wash');
    await _type(tester, 'Every … months', '1');
    await tester.ensureVisible(_field('Date'));
    await tester.tap(_field('Date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.tap(_save);
    await tester.pumpAndSettle();
    final added = (await tester.runAsync(() => garage.schedule('veh-camry')))!.last;
    expect(added.lastDoneDate, DateTime(2026, 11, 7));
  });

  testWidgets('Cancel with changes asks first', (tester) async {
    await _editOil(tester);
    await _type(tester, 'Every … months', '6');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemIntervalScreen), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemIntervalScreen), findsNothing);
  });

  testWidgets('Cancel without changes just closes', (tester) async {
    await _editOil(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemIntervalScreen), findsNothing);
  });

  testWidgets('tablet: a centred modal at most 560 wide', (tester) async {
    await _editOil(tester, screen: const Size(1024, 768));
    expect(tester.getSize(find.byType(ItemIntervalScreen)).width, lessThanOrEqualTo(560));
  });

  testWidgets('Arabic: translated, right to left', (tester) async {
    await _editOil(tester, language: 'ar');
    expect(find.text('تعديل الفترة'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(ItemIntervalScreen))), TextDirection.rtl);
  });

  testWidgets('large text does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _addCustom(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    await _addCustom(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
