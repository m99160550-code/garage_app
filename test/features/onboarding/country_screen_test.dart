import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/onboarding/presentation/brand/brand_selection_screen.dart';
import 'package:tdc_garage/features/onboarding/presentation/country/country_screen.dart';
import 'package:tdc_garage/features/onboarding/presentation/country/widgets/country_picker_sheet.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/privacy/data/consent_repository.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';

import '../../helpers/test_app.dart';

class _Setup {
  final preferences = MockPreferencesRepository();
  final consents = MockConsentRepository();
}

Future<_Setup> _openCountry(
  WidgetTester tester, {
  required String? region,
  bool tablet = false,
  String? language,
}) async {
  tablet ? useTabletScreen(tester) : usePhoneScreen(tester);
  final setup = _Setup();
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'countryStep'),
      overrides: [
        deviceRegionProvider.overrideWithValue(region),
        preferencesRepositoryProvider.overrideWithValue(setup.preferences),
        consentRepositoryProvider.overrideWithValue(setup.consents),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  expect(find.byType(CountryScreen), findsOneWidget);
  return setup;
}

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

Future<void> _openPicker(WidgetTester tester) async {
  // At large text sizes the form scrolls, so bring the button into view.
  await tester.ensureVisible(find.text('Change'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Change'));
  await tester.pumpAndSettle();
  expect(find.byType(CountryPickerSheet), findsOneWidget);
}

void main() {
  testWidgets('preselects the device region and continues to Brand', (tester) async {
    final setup = await _openCountry(tester, region: 'SA');

    expect(find.text('Where do you drive?'), findsOneWidget);
    expect(find.text('Saudi Arabia'), findsOneWidget);
    expect(find.text('SAR · km · Gulf brands'), findsOneWidget);
    expect(find.text('Help us improve the app'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(BrandSelectionScreen), findsOneWidget);
    expect(setup.preferences.current.currency, 'SAR');
  });

  testWidgets('in a consent region, Continue waits for a choice', (tester) async {
    final setup = await _openCountry(tester, region: 'DE');

    expect(find.text('Germany'), findsOneWidget);
    expect(find.text('Help us improve the app'), findsOneWidget);
    expect(find.text("Choose Allow or Don't allow to continue."), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(CountryScreen), findsOneWidget, reason: 'disabled until a choice is made');

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(find.text("Choose Allow or Don't allow to continue."), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(BrandSelectionScreen), findsOneWidget);
    expect(setup.consents.records.single.granted, isTrue);
  });

  testWidgets('an unknown region shows Not set and the consent card', (tester) async {
    await _openCountry(tester, region: null);
    expect(find.text('Not set'), findsOneWidget);
    expect(find.text('USD · km · Popular brands'), findsOneWidget);
    expect(find.text('Help us improve the app'), findsOneWidget);
  });

  testWidgets('the picker searches and changes the country', (tester) async {
    await _openCountry(tester, region: 'SA');
    await _openPicker(tester);

    await tester.enterText(find.byType(TextField), 'egy');
    await tester.pumpAndSettle();
    expect(find.text('Egypt'), findsOneWidget);
    expect(find.text('Kuwait'), findsNothing);

    await tester.tap(find.text('Egypt'));
    await tester.pumpAndSettle();
    expect(find.byType(CountryPickerSheet), findsNothing);
    expect(find.text('EGP · km · Egypt brands'), findsOneWidget);
  });

  testWidgets('Arabic names are searchable from the English UI', (tester) async {
    await _openCountry(tester, region: 'SA');
    await _openPicker(tester);
    await tester.enterText(find.byType(TextField), 'الامارات');
    await tester.pumpAndSettle();
    expect(find.text('United Arab Emirates'), findsOneWidget);
  });

  testWidgets('Other / not set resets the presets', (tester) async {
    await _openCountry(tester, region: 'GB');
    expect(find.text('GBP · mi · Popular brands'), findsOneWidget);

    await _openPicker(tester);
    await tester.tap(find.text('Other / not set'));
    await tester.pumpAndSettle();
    expect(find.text('Not set'), findsOneWidget);
    expect(find.text('USD · km · Popular brands'), findsOneWidget);
  });

  testWidgets('no matches shows an empty state with Clear search', (tester) async {
    await _openCountry(tester, region: 'SA');
    await _openPicker(tester);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No countries found'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Saudi Arabia'), findsWidgets);
  });

  testWidgets('dismissing the picker keeps the current country', (tester) async {
    await _openCountry(tester, region: 'SA');
    await _openPicker(tester);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('SAR · km · Gulf brands'), findsOneWidget);
  });

  testWidgets('on tablets the picker is a centred dialog', (tester) async {
    await _openCountry(tester, region: 'SA', tablet: true);
    await _openPicker(tester);
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('Arabic UI shows Arabic names, presets and right-to-left layout', (tester) async {
    await _openCountry(tester, region: 'SA', language: 'ar');
    expect(find.text('أين تقود سيارتك؟'), findsOneWidget);
    expect(find.text('السعودية'), findsOneWidget);
    expect(find.text('SAR · كم · علامات الخليج'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(CountryScreen))), TextDirection.rtl);
  });

  testWidgets('announces the setup step to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await _openCountry(tester, region: 'SA');
    expect(find.bySemanticsLabel('Step 1 of 4: Country'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    await _openCountry(tester, region: 'DE');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('large text does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openCountry(tester, region: 'DE');
    expect(tester.takeException(), isNull);
    await _openPicker(tester);
    expect(tester.takeException(), isNull);
  });
}
