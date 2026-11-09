import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/core/format/app_formatters.dart';
import 'package:tdc_garage/core/widgets/language_fade.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/service_history/application/service_history_providers.dart';
import 'package:tdc_garage/features/service_history/data/service_record_repository.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/settings/presentation/language/language_screen.dart';
import 'package:tdc_garage/features/settings/presentation/profile_screen.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);

/// Opens Profile → Language & digits.
Future<MockPreferencesRepository> _open(WidgetTester tester, {Size? screen}) async {
  final preferences = MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA', currency: 'SAR'));
  useScreen(tester, screen ?? const Size(390, 2600));
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(MockGarageRepository.forScenario('returning', now: _now)),
        serviceRecordRepositoryProvider.overrideWithValue(
          MockServiceRecordRepository.forScenario('returning', now: _now),
        ),
        clockProvider.overrideWithValue(() => _now),
        preferencesRepositoryProvider.overrideWithValue(preferences),
      ],
    ),
  );
  await finishLaunch(tester);
  GoRouter.of(tester.element(find.byType(DashboardScreen))).go('/profile');
  await tester.pumpAndSettle();
  if (screen == null) {
    final row = find.bySemanticsLabel(RegExp(r'^Language,')).first;
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
  }
  return preferences;
}

TextDirection _direction(WidgetTester tester) => Directionality.of(tester.element(find.byType(LanguageScreen)));

void main() {
  // The digit setting is app-wide; reset it after each test.
  tearDown(() => AppFormatters.appDigits = DigitStyle.western);

  testWidgets('lists the languages, each in its own language, and the digit styles', (tester) async {
    await _open(tester);
    expect(find.byType(LanguageScreen), findsOneWidget);
    expect(find.text('Language & digits'), findsOneWidget);
    expect(find.text('Same as device (English)'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Western (0 1 2 3)'), findsOneWidget);
    expect(find.textContaining('Arabic-Indic (٠'), findsOneWidget);
    expect(find.text('VINs, plates and mileage always use Western digits.'), findsOneWidget);
  });

  testWidgets('Arabic switches at once and mirrors the layout; device returns to English', (tester) async {
    await _open(tester);
    expect(_direction(tester), TextDirection.ltr);

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    expect(find.byType(LanguageScreen), findsOneWidget, reason: 'no restart, the screen stays');
    expect(find.text('اللغة والأرقام'), findsOneWidget);
    expect(_direction(tester), TextDirection.rtl);

    await tester.tap(find.text('مثل الجهاز (English)'));
    await tester.pumpAndSettle();
    expect(find.text('Language & digits'), findsOneWidget);
    expect(_direction(tester), TextDirection.ltr);
  });

  testWidgets('the switch fades in over 250 ms', (tester) async {
    await _open(tester);
    await tester.tap(find.text('العربية'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final fade = tester.widget<FadeTransition>(
      find.descendant(of: find.byType(LanguageFade), matching: find.byType(FadeTransition)).first,
    );
    expect(fade.opacity.value, lessThan(1));
    await tester.pumpAndSettle();
    expect(fade.opacity.value, 1);
  });

  testWidgets('Arabic-Indic digits: saved, used for money, never for mileage (BR-SET-05)', (tester) async {
    final preferences = await _open(tester);
    await tester.tap(find.textContaining('Arabic-Indic (٠'));
    await tester.pumpAndSettle();
    expect(preferences.current.digitStyle, DigitStyle.arabicIndic);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Digits, Arabic-Indic ٠-٩'), findsOneWidget);

    GoRouter.of(tester.element(find.byType(ProfileScreen))).go('/garage');
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'^This year, SAR.٤٢٠')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Mileage, 54,320')), findsOneWidget);
    // The health score and the Next service count follow the setting too.
    expect(find.text('٩٦'), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'^Next service, ٢٠ Days away')), findsOneWidget);
  });

  testWidgets('iPad landscape: in the Profile detail pane', (tester) async {
    await _open(tester, screen: const Size(1366, 1024));
    final row = find.bySemanticsLabel(RegExp(r'^Language,')).first;
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(LanguageScreen), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
