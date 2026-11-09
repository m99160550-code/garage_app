import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/core/widgets/app_button.dart';
import 'package:tdc_garage/core/widgets/app_text_field.dart';
import 'package:tdc_garage/features/account/application/account_providers.dart';
import 'package:tdc_garage/features/account/data/account_repository.dart';
import 'package:tdc_garage/features/account/data/auth_repository.dart';
import 'package:tdc_garage/features/account/domain/account.dart';
import 'package:tdc_garage/features/account/domain/erase.dart';
import 'package:tdc_garage/features/account/presentation/erase_screen.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/onboarding/presentation/intro/intro_screen.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/service_history/application/service_history_providers.dart';
import 'package:tdc_garage/features/service_history/data/service_record_repository.dart';
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

class _Setup {
  _Setup({String account = 'guest', DateTime? signedInAt, bool online = true})
    : accounts = signedInAt == null
          ? MockAccountRepository.fromConfig(account, now: _now)
          : MockAccountRepository(
              OwnerAccount(name: 'Sara Al-Amri', email: 'sara@example.com', sync: Synced(_now), signedInAt: signedInAt),
            ),
      auth = MockAuthRepository(online: online) {
    accounts.online = online;
  }

  final MockAccountRepository accounts;
  final MockAuthRepository auth;
  final session = MockSessionRepository(scenario: 'returning');
  final garage = MockGarageRepository.forScenario('returning', now: _now);
  final records = MockServiceRecordRepository.forScenario('returning', now: _now);
  final preferences = MockPreferencesRepository(
    const RegionalPreferences(countryCode: 'SA', currency: 'SAR', analyticsEnabled: false),
  );

  List<Override> get overrides => [
    garageRepositoryProvider.overrideWithValue(garage),
    serviceRecordRepositoryProvider.overrideWithValue(records),
    accountRepositoryProvider.overrideWithValue(accounts),
    authRepositoryProvider.overrideWithValue(auth),
    preferencesRepositoryProvider.overrideWithValue(preferences),
    clockProvider.overrideWithValue(() => _now),
  ];
}

Future<void> _open(WidgetTester tester, _Setup setup, {Size? screen, String? language}) async {
  useScreen(tester, screen ?? const Size(390, 1000));
  await tester.pumpWidget(
    buildTestApp(
      setup.session,
      overrides: [
        ...setup.overrides,
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  GoRouter.of(tester.element(find.byType(DashboardScreen))).push('/account/delete');
  await tester.pumpAndSettle();
  expect(find.byType(EraseScreen), findsOneWidget);
}

Finder _field(String label) =>
    find.descendant(of: find.widgetWithText(AppTextField, label), matching: find.byType(EditableText));

Future<void> _type(WidgetTester tester, String label, String value) async {
  await tester.enterText(_field(label), value);
  await tester.pumpAndSettle();
}

AppButton _button(WidgetTester tester, String label) => tester.widget<AppButton>(find.widgetWithText(AppButton, label));

/// Taps the red button and lets the app restart at S-01 → S-02. The
/// intro animates without end, so time is pumped rather than settled.
Future<void> _confirm(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(AppButton, label));
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('S-30 rules', () {
    test('re-authentication after 5 minutes, or when the sign-in time is unknown', () {
      expect(needsReauthentication(_now.subtract(const Duration(minutes: 4)), now: _now), isFalse);
      expect(needsReauthentication(_now.subtract(const Duration(minutes: 5)), now: _now), isFalse);
      expect(needsReauthentication(_now.subtract(const Duration(minutes: 6)), now: _now), isTrue);
      expect(needsReauthentication(null, now: _now), isTrue);
    });

    test('the typed word ignores case and surrounding spaces', () {
      expect(confirmationMatches(' delete ', 'DELETE'), isTrue);
      expect(confirmationMatches('DELET', 'DELETE'), isFalse);
      expect(confirmationMatches('حذف', 'حذف'), isTrue);
    });
  });

  testWidgets('Guest: "Erase all data", typed ERASE, then a fresh start at the intro (FR-USR-16)', (tester) async {
    final setup = _Setup();
    await _open(tester, setup);
    expect(find.text('Erase all data'), findsWidgets);
    expect(find.text('Everything on this phone is erased immediately.'), findsOneWidget);
    expect(find.text('Backups are cleared within 30 days.'), findsNothing);
    expect(_button(tester, 'Erase all data').onPressed, isNull);

    await _type(tester, 'Type ERASE to confirm', 'eras');
    expect(_button(tester, 'Erase all data').onPressed, isNull);
    await _type(tester, 'Type ERASE to confirm', 'erase');
    expect(_button(tester, 'Erase all data').onPressed, isNotNull);

    await _confirm(tester, 'Erase all data');
    expect(find.byType(IntroScreen), findsOneWidget);
    expect(await setup.garage.vehicles(), isEmpty);
    expect(await setup.records.all(), isEmpty);
    expect(setup.preferences.current, const RegionalPreferences());
    // load() waits on a timer, which needs real async here.
    final session = (await tester.runAsync(setup.session.load))!;
    expect((session.hasCompletedIntro, session.vehicleCount, session.lastVehicleId), (false, 0, null));
  });

  testWidgets('Owner signed in yesterday: sign in again first; a wrong password is refused', (tester) async {
    final setup = _Setup(account: 'owner');
    await _open(tester, setup);
    expect(find.text("Confirm it's you"), findsOneWidget);
    expect(find.text('Signed in as ‎sara@example.com‎'), findsOneWidget);
    expect(find.text('Delete account'), findsNothing);
    expect(_button(tester, 'Confirm').onPressed, isNull);

    await _type(tester, 'Password', 'nope');
    await tester.tap(find.widgetWithText(AppButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(find.text("That password doesn't match."), findsOneWidget);

    await _type(tester, 'Password', 'password123');
    await tester.tap(find.widgetWithText(AppButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Delete account'), findsWidgets);
    final account = await setup.accounts.load() as OwnerAccount;
    expect((account.email, account.signedInAt), ('sara@example.com', _now), reason: 'same account, renewed time');
  });

  testWidgets('Owner: Google re-authentication, typed DELETE, the account is deleted (FR-USR-06)', (tester) async {
    final setup = _Setup(account: 'owner');
    await _open(tester, setup);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Your vehicles, history and settings are deleted from all devices.'), findsOneWidget);
    expect(find.text('Backups are cleared within 30 days.'), findsOneWidget);
    expect(find.text("This can't be undone."), findsOneWidget);
    await _type(tester, 'Type DELETE to confirm', 'DELETE');
    await _confirm(tester, 'Delete account');

    expect(setup.accounts.deleted, isTrue);
    expect(await setup.accounts.load(), isA<GuestAccount>());
    expect(await setup.garage.vehicles(), isEmpty);
    expect(find.byType(IntroScreen), findsOneWidget);
  });

  testWidgets('Owner signed in 1 minute ago: straight to the confirmation', (tester) async {
    await _open(tester, _Setup(signedInAt: _now.subtract(const Duration(minutes: 1))));
    expect(find.text("Confirm it's you"), findsNothing);
    expect(find.text('Type DELETE to confirm'), findsOneWidget);
  });

  testWidgets('no connection: a banner, and nothing is deleted', (tester) async {
    final setup = _Setup(signedInAt: _now, online: false);
    await _open(tester, setup);
    await _type(tester, 'Type DELETE to confirm', 'delete');
    await tester.tap(find.widgetWithText(AppButton, 'Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('You need a connection to delete your account.'), findsOneWidget);
    expect(find.byType(EraseScreen), findsOneWidget);
    expect(setup.accounts.deleted, isFalse);
    expect(await setup.garage.vehicles(), hasLength(2));
  });

  testWidgets('no connection while signing in again: the sign-in banner', (tester) async {
    await _open(tester, _Setup(account: 'owner', online: false));
    await tester.tap(find.text('Continue with Apple'));
    await tester.pumpAndSettle();
    expect(find.text('You need a connection to sign in.'), findsOneWidget);
    expect(find.text("Confirm it's you"), findsOneWidget);
  });

  testWidgets('close leaves without changing anything', (tester) async {
    final setup = _Setup();
    await _open(tester, setup);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(EraseScreen), findsNothing);
    expect(await setup.garage.vehicles(), hasLength(2));
  });

  testWidgets('Arabic: the word is «مسح»; translated, no overflow', (tester) async {
    await _open(tester, _Setup(), language: 'ar');
    expect(find.text('اكتب مسح للتأكيد'), findsOneWidget);
    await _type(tester, 'اكتب مسح للتأكيد', 'مسح');
    expect(_button(tester, 'مسح كل البيانات').onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet: a card at most 440 wide', (tester) async {
    await _open(tester, _Setup(account: 'owner'), screen: const Size(1024, 768));
    expect(tester.getSize(find.byType(EraseScreen)).width, lessThanOrEqualTo(440));
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines (re-authentication and the red button)', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, _Setup(account: 'owner'));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    await _type(tester, 'Type DELETE to confirm', 'DELETE');
    // Close the keyboard without submitting.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
