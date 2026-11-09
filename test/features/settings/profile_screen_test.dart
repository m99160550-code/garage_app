import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/vehicles/presentation/vehicles_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/features/account/application/account_providers.dart';
import 'package:tdc_garage/features/account/data/account_repository.dart';
import 'package:tdc_garage/features/account/domain/account.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/help/presentation/contact_screen.dart';
import 'package:tdc_garage/features/help/presentation/help_screen.dart';
import 'package:tdc_garage/features/help/presentation/legal_page_screen.dart';
import 'package:tdc_garage/features/notifications/application/reminder_primer_service.dart';
import 'package:tdc_garage/features/notifications/data/notification_permission_repository.dart';
import 'package:tdc_garage/features/notifications/domain/notification_permission.dart';
import 'package:tdc_garage/features/notifications/presentation/reminders_primer_sheet.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/privacy/data/consent_repository.dart';
import 'package:tdc_garage/features/privacy/domain/consent.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/settings/presentation/profile_screen.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';

import 'package:tdc_garage/features/settings/presentation/region/country_setting_screen.dart';

import 'package:tdc_garage/features/settings/presentation/language/language_screen.dart';

import 'package:tdc_garage/features/account/presentation/backup_offer_sheet.dart';
import 'package:tdc_garage/features/account/presentation/erase_screen.dart';
import 'package:tdc_garage/features/account/presentation/sign_in_screen.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

class _Setup {
  _Setup({String account = 'guest', NotificationPermission permission = NotificationPermission.notDetermined})
    : accounts = MockAccountRepository.fromConfig(account, now: _now),
      permissions = MockNotificationPermissionRepository(initial: permission);

  final MockAccountRepository accounts;
  final MockNotificationPermissionRepository permissions;
  final preferences = MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA', currency: 'SAR'));
  final consents = MockConsentRepository();
}

/// Launches the sample garage and opens the Profile tab.
Future<void> _openProfile(WidgetTester tester, _Setup setup, {Size? screen, String? language}) async {
  useScreen(tester, screen ?? const Size(390, 2600));
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(MockGarageRepository.forScenario('returning', now: _now)),
        accountRepositoryProvider.overrideWithValue(setup.accounts),
        notificationPermissionRepositoryProvider.overrideWithValue(setup.permissions),
        consentRepositoryProvider.overrideWithValue(setup.consents),
        clockProvider.overrideWithValue(() => _now),
        preferencesRepositoryProvider.overrideWithValue(setup.preferences),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  GoRouter.of(tester.element(find.byType(DashboardScreen))).go('/profile');
  await tester.pumpAndSettle();
  expect(find.byType(ProfileScreen), findsOneWidget);
}

Future<void> _tapRow(WidgetTester tester, String label) async {
  final row = find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}(,|\$)'));
  await tester.ensureVisible(row.first);
  await tester.tap(row.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Guest: the warning, "Back up your garage" and "Sign in"', (tester) async {
    await _openProfile(tester, _Setup());

    expect(find.text('Your garage is only on this phone'), findsOneWidget);
    expect(find.text('If you delete the app or lose your phone, your data is gone.'), findsOneWidget);
    expect(find.text('Erase all data'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
    expect(find.text('Delete account'), findsNothing);

    await tester.tap(find.text('Back up your garage'));
    await tester.pumpAndSettle();
    expect(find.byType(BackupOfferSheet), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('shows the current settings', (tester) async {
    await _openProfile(tester, _Setup());

    expect(find.bySemanticsLabel('Vehicles, 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Country, Saudi Arabia'), findsOneWidget);
    expect(find.bySemanticsLabel('Distance unit, Kilometres'), findsOneWidget);
    expect(find.bySemanticsLabel('Currency, SAR · Saudi Riyal'), findsOneWidget);
    expect(find.bySemanticsLabel('Language, English'), findsOneWidget);
    expect(find.bySemanticsLabel('Digits, Western 0-9'), findsOneWidget);
    expect(find.bySemanticsLabel('Reminders, Off'), findsOneWidget);
    expect(find.text('We reply within 2 business days (Sunday to Thursday, Cairo time)'), findsOneWidget);
    expect(find.text('TDC-mena Garage 0.1.0 (1)'), findsOneWidget);
  });

  testWidgets('each row opens its screen', (tester) async {
    await _openProfile(tester, _Setup());
    await _tapRow(tester, 'Vehicles');
    expect(find.byType(VehiclesScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    for (final (label, screen) in [
      ('FAQ', HelpScreen),
      ('Contact support', ContactScreen),
      ('Privacy policy', LegalPageScreen),
      ('Terms of use', LegalPageScreen),
    ]) {
      await _tapRow(tester, label);
      expect(find.byType(screen), findsOneWidget, reason: label);
      // The legal pages open in the in-app browser, closed with X.
      final close = find.byTooltip('Close');
      await (close.evaluate().isEmpty ? tester.pageBack() : tester.tap(close.last));
      await tester.pumpAndSettle();
    }
    await _tapRow(tester, 'Erase all data');
    expect(find.byType(EraseScreen), findsOneWidget);
  });

  testWidgets('the analytics switch saves and records the decision (FR-SET-09)', (tester) async {
    final setup = _Setup();
    await _openProfile(tester, setup);
    final toggle = find.byType(Switch);
    expect(tester.widget<Switch>(toggle).value, isTrue);

    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(setup.preferences.current.analyticsEnabled, isFalse);
    final record = setup.consents.records.single;
    expect((record.purpose, record.granted, record.regionCode), (ConsentPurpose.analytics, false, 'SA'));
  });

  testWidgets('"Enable reminders" opens the primer; granted shows "On" and no banner', (tester) async {
    final setup = _Setup();
    await _openProfile(tester, setup);
    await tester.tap(find.widgetWithText(TextButton, 'Enable reminders'));
    await tester.pumpAndSettle();
    expect(find.byType(RemindersPrimerSheet), findsOneWidget);

    await tester.tap(find.text('Turn on reminders'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Reminders, On'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Enable reminders'), findsNothing);
  });

  testWidgets('Owner: name, email, sync line; the card opens account details', (tester) async {
    await _openProfile(tester, _Setup(account: 'owner', permission: NotificationPermission.granted));

    expect(find.bySemanticsLabel('Sara Al-Amri, sara@example.com, Synced 2 min ago. Account details'), findsOneWidget);
    expect(find.text('SA'), findsOneWidget);
    expect(find.text('Your garage is only on this phone'), findsNothing);
    expect(find.text('Delete account'), findsOneWidget);
    expect(find.text('Erase all data'), findsNothing);

    await tester.tap(find.text('Sara Al-Amri'));
    await tester.pumpAndSettle();
    expect(find.text('Account details'), findsOneWidget);
  });

  testWidgets('Owner with an unverified email: banner and "Resend email"', (tester) async {
    final setup = _Setup(account: 'ownerUnverified');
    await _openProfile(tester, setup);
    expect(find.text('Verify your email to finish backing up'), findsOneWidget);
    await tester.tap(find.text('Resend email'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Verification email sent'), findsOneWidget);
    expect(setup.accounts.verificationEmails, 1);
  });

  testWidgets('sign out with unsynced changes: Sync now or Discard (BR-USR-04)', (tester) async {
    final setup = _Setup(account: 'ownerPending');
    await _openProfile(tester, setup);
    expect(find.textContaining('Waiting to sync (3)'), findsOneWidget);

    await _tapRow(tester, 'Sign out');
    expect(find.text("Some changes haven't synced"), findsOneWidget);
    expect(find.text("3 changes on this phone haven't reached your account yet."), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);
    await tester.tap(find.text('Discard and sign out'));
    await tester.pumpAndSettle();

    expect(await setup.accounts.load(), isA<GuestAccount>());
    expect(find.text('Your garage is only on this phone'), findsOneWidget);
  });

  testWidgets('sign out when synced: a simple confirmation; Cancel keeps you signed in', (tester) async {
    final setup = _Setup(account: 'owner');
    await _openProfile(tester, setup);
    await _tapRow(tester, 'Sign out');
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await setup.accounts.load(), isA<OwnerAccount>());
  });

  testWidgets('iPad landscape: the selected setting shows beside the list', (tester) async {
    await _openProfile(tester, _Setup(), screen: const Size(1366, 1024));
    expect(find.byType(CountrySettingScreen), findsOneWidget);
    await _tapRow(tester, 'Language');
    expect(find.byType(LanguageScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('Arabic: translated, language name in Arabic, no overflow', (tester) async {
    await _openProfile(tester, _Setup(account: 'ownerPending'), language: 'ar');
    expect(find.bySemanticsLabel('اللغة, العربية'), findsOneWidget);
    expect(find.bySemanticsLabel('العملة, SAR · ريال سعودي'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _openProfile(tester, _Setup(account: 'ownerUnverified'));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
