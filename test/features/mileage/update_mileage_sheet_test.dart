import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/core/widgets/stat_card.dart';
import 'package:tdc_garage/features/mileage/presentation/mileage_history_screen.dart';
import 'package:tdc_garage/features/mileage/presentation/update_mileage_sheet.dart';
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

Finder get _mileageCard =>
    find.byWidgetPredicate((w) => w is StatCard && (w.label == 'Mileage' || w.label == 'المسافة'), skipOffstage: false);
Finder get _save => find.widgetWithText(TextButton, 'Save');
Finder get _input => find.descendant(of: find.byType(UpdateMileageSheet), matching: find.byType(TextField));

/// Opens the dashboard (Family Camry) and the S-12 sheet from the Mileage
/// card: tap once to focus the side card, once to open.
Future<MockGarageRepository> _openSheet(WidgetTester tester, {Size? screen, String? language}) async {
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
  // Large text: the cards are further down the page.
  await tester.ensureVisible(_mileageCard);
  await tester.pumpAndSettle();
  // In the phone carousel the first tap focuses the side card.
  await tester.tap(_mileageCard, warnIfMissed: false);
  await tester.pumpAndSettle();
  if (find.byType(UpdateMileageSheet).evaluate().isEmpty) {
    await tester.tap(_mileageCard);
    await tester.pumpAndSettle();
  }
  expect(find.byType(UpdateMileageSheet), findsOneWidget);
  return garage;
}

Future<void> _type(WidgetTester tester, String value) async {
  await tester.enterText(_input, value);
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.tap(_save);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens with the keyboard, the current value as a hint and Save disabled', (tester) async {
    await _openSheet(tester);
    expect(find.text('Update mileage'), findsOneWidget);
    expect(find.text('Family Camry'), findsWidgets);
    expect(tester.widget<TextField>(_input).autofocus, isTrue);
    expect(tester.widget<TextField>(_input).decoration!.hintText, '54,320');
    expect(find.text('Last: 54,320 km · Nov 3'), findsOneWidget);
    expect(tester.widget<TextButton>(_save).onPressed, isNull, reason: 'empty (UC-02 4d)');
  });

  testWidgets('saving updates the card, adds a reading and shows a toast', (tester) async {
    final garage = await _openSheet(tester);
    await _type(tester, '54800');
    expect(find.text('54,800'), findsOneWidget, reason: 'grouped while typing');
    await _tapSave(tester);

    expect(find.byType(UpdateMileageSheet), findsNothing);
    expect(find.text('Mileage updated'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Mileage, 54,800 kilometres, Updated today')), findsOneWidget);
    final readings = (await tester.runAsync(() => garage.readings('veh-camry')))!;
    expect(readings.last.km, 54800);
  });

  testWidgets('crossing a due mileage turns the item overdue (UC-02 5a)', (tester) async {
    await _openSheet(tester);
    // The oil filter is due at 55,000 km.
    await _type(tester, '55100');
    await _tapSave(tester);
    expect(find.text('Oil filter overdue'), findsOneWidget);
  });

  testWidgets('a lower value asks first, then saves as a correction (BR-MIL-02)', (tester) async {
    final garage = await _openSheet(tester);
    await _type(tester, '53900');
    await _tapSave(tester);
    expect(find.text('This is lower than your last reading'), findsOneWidget);
    expect(find.text('Your last reading was 54,320 km on Nov 3. Save 53,900 km as a correction?'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateMileageSheet), findsOneWidget, reason: 'back to the field');

    await _tapSave(tester);
    await tester.tap(find.text('Save as correction'));
    await tester.pumpAndSettle();
    final readings = (await tester.runAsync(() => garage.readings('veh-camry')))!;
    expect(readings.last.isCorrection, isTrue);
    expect(find.bySemanticsLabel(RegExp(r'^Mileage, 53,900 kilometres')), findsOneWidget);
  });

  testWidgets('a very large jump asks "Is this correct?" (BR-MIL-03)', (tester) async {
    await _openSheet(tester);
    await _type(tester, '80000');
    await _tapSave(tester);
    expect(find.text('Is this correct?'), findsOneWidget);
    expect(find.text("That's 25,680 km in 4 days."), findsOneWidget);
    await tester.tap(find.text('Yes, save'));
    await tester.pumpAndSettle();
    expect(find.text('Mileage updated'), findsOneWidget);
  });

  testWidgets('the same value saves without asking and refreshes the date (UC-02 4c)', (tester) async {
    await _openSheet(tester);
    await _type(tester, '54320');
    await _tapSave(tester);
    expect(find.text('Is this correct?'), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'^Mileage, 54,320 kilometres, Updated today')), findsOneWidget);
  });

  testWidgets('the vehicle line picks another car', (tester) async {
    await _openSheet(tester);
    await tester.tap(find.byTooltip('Choose vehicle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nissan Patrol').last);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_input).decoration!.hintText, '121,400');
  });

  testWidgets('View history opens S-13', (tester) async {
    await _openSheet(tester);
    await tester.tap(find.text('View history'));
    await tester.pumpAndSettle();
    expect(find.byType(MileageHistoryScreen), findsOneWidget);
  });

  testWidgets('tablet: a 420 pt modal; Return saves', (tester) async {
    await _openSheet(tester, screen: const Size(1024, 768));
    expect(tester.getSize(find.byType(UpdateMileageSheet)).width, lessThanOrEqualTo(420));
    await _type(tester, '54500');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(UpdateMileageSheet), findsNothing);
  });

  testWidgets('Arabic: translated, the number stays left to right', (tester) async {
    await _openSheet(tester, language: 'ar');
    expect(find.text('تحديث المسافة'), findsOneWidget);
    expect(tester.widget<TextField>(_input).textDirection, TextDirection.ltr);
  });

  testWidgets('large text does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openSheet(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    await _openSheet(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
