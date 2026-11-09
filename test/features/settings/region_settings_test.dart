import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/reference/data/mock_reference_repository.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/distance_unit.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/settings/presentation/profile_screen.dart';
import 'package:tdc_garage/features/settings/presentation/region/country_setting_screen.dart';
import 'package:tdc_garage/features/settings/presentation/region/currency_screen.dart';
import 'package:tdc_garage/features/settings/presentation/region/distance_unit_screen.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);
const _saudi = RegionalPreferences(countryCode: 'SA', currency: 'SAR');

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

/// Opens Profile, then [row] (unless null).
Future<MockPreferencesRepository> _open(
  WidgetTester tester, {
  RegionalPreferences preferences = _saudi,
  String? row,
  Size? screen,
  String? language,
}) async {
  final repository = MockPreferencesRepository(preferences);
  useScreen(tester, screen ?? const Size(390, 2600));
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(MockGarageRepository.forScenario('returning', now: _now)),
        clockProvider.overrideWithValue(() => _now),
        preferencesRepositoryProvider.overrideWithValue(repository),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  GoRouter.of(tester.element(find.byType(DashboardScreen))).go('/profile');
  await tester.pumpAndSettle();
  if (row != null) await _tapRow(tester, row);
  return repository;
}

Future<void> _tapRow(WidgetTester tester, String label) async {
  final finder = find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}(,|\$)')).first;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200, scrollable: find.byType(Scrollable).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  group('country presets (FR-SET-16, BR-SET-09)', () {
    final countries = {for (final c in MockReferenceRepository.allCountries) c.code: c};

    test('only values not set by hand and different are offered', () {
      expect(_saudi.switchesFor(countries['US']), (currency: 'USD', unit: DistanceUnit.mi));
      expect(_saudi.switchesFor(countries['AE']), (currency: 'AED', unit: null));
      expect(_saudi.switchesFor(countries['SA']), (currency: null, unit: null));
      expect(_saudi.switchesFor(null), (currency: 'USD', unit: null), reason: 'Other: USD and km (BR-SET-01)');
      const byHand = RegionalPreferences(countryCode: 'SA', currency: 'SAR', currencySetByUser: true);
      expect(byHand.switchesFor(countries['US']), (currency: null, unit: DistanceUnit.mi));
    });

    test('Switch, Keep current and picks by hand', () {
      final uae = countries['AE'];
      expect(_saudi.withCountry(uae).currency, 'AED');
      final kept = _saudi.withCountryOnly(uae);
      expect((kept.countryCode, kept.currency), ('AE', 'SAR'));
      expect(_saudi.withCountryOnly(null).countryCode, isNull);
      final unit = _saudi.withDistanceUnit(DistanceUnit.mi);
      expect((unit.distanceUnit, unit.distanceUnitSetByUser), (DistanceUnit.mi, true));
      final currency = _saudi.withCurrency('EUR');
      expect((currency.currency, currency.currencySetByUser), ('EUR', true));
    });
  });

  group('S-25 Country', () {
    testWidgets('a new country offers to switch the currency; Switch applies it', (tester) async {
      final repository = await _open(tester, row: 'Country');
      expect(find.byType(CountrySettingScreen), findsOneWidget);

      await _tapText(tester, 'United Arab Emirates');
      expect(find.text('Also switch currency?'), findsOneWidget);
      expect(find.text('Switch currency to AED?'), findsOneWidget);
      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();

      expect(find.text('Popular brands updated for United Arab Emirates'), findsOneWidget);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect((repository.current.countryCode, repository.current.currency), ('AE', 'AED'));
      expect(find.bySemanticsLabel('Currency, AED · UAE Dirham'), findsOneWidget);
    });

    testWidgets('Keep current changes only the country', (tester) async {
      final repository = await _open(tester, row: 'Country');
      await _tapText(tester, 'United States');
      expect(find.text('Also switch currency and units?'), findsOneWidget);
      expect(find.text('Switch currency to USD and distance to mi?'), findsOneWidget);
      await tester.tap(find.text('Keep current'));
      await tester.pumpAndSettle();
      expect(
        (repository.current.countryCode, repository.current.currency, repository.current.distanceUnit),
        ('US', 'SAR', DistanceUnit.km),
      );
    });

    testWidgets('nothing to switch: no dialog, just the toast', (tester) async {
      final repository = await _open(
        tester,
        preferences: const RegionalPreferences(countryCode: 'SA', currency: 'SAR', currencySetByUser: true),
        row: 'Country',
      );
      await _tapText(tester, 'Egypt');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Popular brands updated for Egypt'), findsOneWidget);
      expect((repository.current.countryCode, repository.current.currency), ('EG', 'SAR'));
    });

    testWidgets('search by alias', (tester) async {
      await _open(tester, row: 'Country');
      await tester.enterText(find.byType(EditableText), 'UAE');
      await tester.pumpAndSettle();
      expect(find.text('United Arab Emirates'), findsOneWidget);
      expect(find.text('Egypt'), findsNothing);
    });
  });

  group('S-25 Distance unit', () {
    testWidgets('Miles: saved as set by hand, Profile shows it', (tester) async {
      final repository = await _open(tester, row: 'Distance unit');
      expect(find.byType(DistanceUnitScreen), findsOneWidget);
      expect(find.text('Your readings are converted exactly. Nothing is lost when you switch.'), findsOneWidget);
      await tester.tap(find.text('Miles (mi)'));
      await tester.pumpAndSettle();
      expect((repository.current.distanceUnit, repository.current.distanceUnitSetByUser), (DistanceUnit.mi, true));

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Distance unit, Miles'), findsOneWidget);
    });
  });

  group('S-25 Currency', () {
    testWidgets('suggested first, search by name, pick saves as set by hand', (tester) async {
      final repository = await _open(tester, row: 'Currency');
      expect(find.byType(CurrencyScreen), findsOneWidget);
      expect(find.text('New records use this currency. Existing records keep theirs.'), findsOneWidget);
      expect(find.text('SUGGESTED'), findsOneWidget);
      expect(tester.getTopLeft(find.text('SAR')).dy, lessThan(tester.getTopLeft(find.text('ALL CURRENCIES')).dy));

      await tester.enterText(find.byType(EditableText), 'dirham');
      await tester.pumpAndSettle();
      expect(find.text('AED'), findsOneWidget);
      expect(find.text('MAD'), findsOneWidget);
      expect(find.text('SAR'), findsNothing);

      await tester.tap(find.text('AED'));
      await tester.pumpAndSettle();
      expect((repository.current.currency, repository.current.currencySetByUser), ('AED', true));
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('no match message', (tester) async {
      await _open(tester, row: 'Currency');
      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No currencies match "zzz"'), findsOneWidget);
    });

    testWidgets('Arabic: names and search in Arabic', (tester) async {
      await _open(tester, row: 'العملة', language: 'ar');
      await tester.enterText(find.byType(EditableText), 'دينار');
      await tester.pumpAndSettle();
      expect(find.text('دينار كويتي'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('iPad landscape: the pickers open in the detail pane and stay there', (tester) async {
    final repository = await _open(tester, screen: const Size(1366, 1024));
    expect(find.byType(CountrySettingScreen), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await _tapRow(tester, 'Currency');
    expect(find.byType(CurrencyScreen), findsOneWidget);
    await tester.tap(find.text('EUR'));
    await tester.pumpAndSettle();
    expect(repository.current.currency, 'EUR');
    expect(find.byType(CurrencyScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Currency, EUR · Euro'), findsOneWidget);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, row: 'Distance unit');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
