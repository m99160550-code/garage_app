import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/core/widgets/app_text_field.dart';
import 'package:tdc_garage/features/account/application/account_providers.dart';
import 'package:tdc_garage/features/account/data/account_repository.dart';
import 'package:tdc_garage/features/account/data/auth_repository.dart';
import 'package:tdc_garage/features/account/domain/account.dart';
import 'package:tdc_garage/features/account/domain/auth.dart';
import 'package:tdc_garage/features/account/presentation/backup_screen.dart';
import 'package:tdc_garage/features/account/presentation/sign_in_screen.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/help/presentation/legal_page_screen.dart';
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

class _Setup {
  _Setup({bool online = true}) : auth = MockAuthRepository(online: online);

  final MockAuthRepository auth;
  final accounts = MockAccountRepository();
  final mail = MailLauncher();
}

Future<void> _open(
  WidgetTester tester,
  _Setup setup, {
  String location = '/account/sign-in',
  Size? screen,
  String? language,
}) async {
  useScreen(tester, screen ?? const Size(390, 1000));
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(MockGarageRepository.forScenario('returning', now: _now)),
        authRepositoryProvider.overrideWithValue(setup.auth),
        accountRepositoryProvider.overrideWithValue(setup.accounts),
        mailLauncherProvider.overrideWithValue(setup.mail),
        clockProvider.overrideWithValue(() => _now),
        preferencesRepositoryProvider.overrideWithValue(
          MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA', currency: 'SAR')),
        ),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  GoRouter.of(tester.element(find.byType(DashboardScreen))).push(location);
  await tester.pumpAndSettle();
  expect(find.byType(SignInScreen), findsOneWidget);
}

Finder _field(String label) =>
    find.descendant(of: find.widgetWithText(AppTextField, label), matching: find.byType(EditableText));

/// Types into a field and lets the form rebuild (buttons enable on input).
Future<void> _type(WidgetTester tester, String label, String value) async {
  await tester.enterText(_field(label), value);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _toPassword(WidgetTester tester, String email) async {
  await _tap(tester, 'Continue with email');
  await _type(tester, 'Email', email);
  await _tap(tester, 'Continue');
}

String? _backupStep(WidgetTester tester) {
  final screen = find.byType(BackupScreen);
  if (screen.evaluate().isEmpty) return null;
  return GoRouterState.of(tester.element(screen)).uri.queryParameters['step'];
}

void main() {
  test('after signing in (spec S-28): upload, merge or discard, or back', () {
    expect(afterSignIn(isNewAccount: true, hasDeviceData: true), AfterSignIn.upload);
    expect(afterSignIn(isNewAccount: false, hasDeviceData: true), AfterSignIn.mergeOrDiscard);
    expect(afterSignIn(isNewAccount: true, hasDeviceData: false), AfterSignIn.back);
    expect(afterSignIn(isNewAccount: false, hasDeviceData: false), AfterSignIn.back);
    expect(looksLikeEmail(' sara@example.com '), isTrue);
    expect(looksLikeEmail('sara@example'), isFalse);
  });

  testWidgets('the method choice: Apple, Google, email and the legal links', (tester) async {
    await _open(tester, _Setup());
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Use your account on any device. Your data stays private.'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);
    await _tap(tester, 'Terms');
    expect(find.byType(LegalPageScreen), findsOneWidget);
  });

  testWidgets('from "Back up your garage": the backup title', (tester) async {
    await _open(tester, _Setup(), location: '/account/sign-in?from=backup');
    expect(find.text('Back up and sync your garage'), findsOneWidget);
  });

  testWidgets('Google, existing account, garage on this phone: merge or discard (FR-USR-15)', (tester) async {
    final setup = _Setup();
    await _open(tester, setup);
    await _tap(tester, 'Continue with Google');
    expect(find.byType(SignInScreen), findsNothing);
    expect(_backupStep(tester), 'merge');
    expect(await setup.accounts.load(), isA<OwnerAccount>());
  });

  testWidgets('Apple, new account: upload this phone\'s garage (FR-USR-14)', (tester) async {
    await _open(tester, _Setup());
    await _tap(tester, 'Continue with Apple');
    expect(_backupStep(tester), 'upload');
  });

  testWidgets('no connection: the banner, and nothing changes', (tester) async {
    final setup = _Setup(online: false);
    await _open(tester, setup);
    await _tap(tester, 'Continue with Apple');
    expect(find.text('You need a connection to sign in.'), findsOneWidget);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(await setup.accounts.load(), isA<GuestAccount>());
  });

  testWidgets('email sign-in: invalid email, wrong password, too many tries, then success', (tester) async {
    final setup = _Setup();
    await _open(tester, setup);
    await _tap(tester, 'Continue with email');
    await _type(tester, 'Email', 'sara@');
    await _tap(tester, 'Continue');
    expect(find.text('Enter a valid email address.'), findsOneWidget);

    await _type(tester, 'Email', 'sara@example.com');
    await _tap(tester, 'Continue');
    expect(find.text('Enter your password'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await _type(tester, 'Password', 'wrong$i');
      await _tap(tester, 'Sign in');
      expect(find.text("That password doesn't match."), findsOneWidget);
    }
    await _type(tester, 'Password', 'wrong5');
    await _tap(tester, 'Sign in');
    expect(find.text('Too many tries. Try again in 5 minutes.'), findsOneWidget);
    expect(await setup.accounts.load(), isA<GuestAccount>());
  });

  testWidgets('email sign-in with the right password', (tester) async {
    await _open(tester, _Setup());
    await _toPassword(tester, 'sara@example.com');
    await _type(tester, 'Password', 'password123');
    await _tap(tester, 'Sign in');
    expect(_backupStep(tester), 'merge');
  });

  testWidgets('show and hide the password', (tester) async {
    await _open(tester, _Setup());
    await _toPassword(tester, 'sara@example.com');
    expect(tester.widget<EditableText>(_field('Password')).obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(_field('Password')).obscureText, isFalse);
  });

  testWidgets('email sign-up: 8 characters, then verify with a 30 s resend wait (FR-USR-02)', (tester) async {
    final setup = _Setup();
    await _open(tester, setup);
    await _toPassword(tester, 'new@example.com');
    expect(find.text('Create a password'), findsOneWidget);
    expect(find.text('At least 8 characters'), findsOneWidget);

    await _type(tester, 'Password', 'short');
    await tester.pumpAndSettle();
    await _tap(tester, 'Create account');
    expect(find.text('Create a password'), findsOneWidget, reason: 'disabled under 8 characters');

    await _type(tester, 'Password', 'long-enough');
    await _tap(tester, 'Create account');
    expect(find.text('Check your email to verify your account.'), findsOneWidget);
    final account = await setup.accounts.load() as OwnerAccount;
    expect((account.email, account.emailVerified), ('new@example.com', false));

    expect(find.text('Resend in 30 s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    await _tap(tester, 'Resend');
    expect(setup.auth.verificationEmails, 2);

    await _tap(tester, 'Open Mail app');
    expect(setup.mail.opened, 1);
    await _tap(tester, 'Continue');
    expect(_backupStep(tester), 'upload');
  });

  testWidgets('forgot password: send the link, then "Check your inbox" (FR-USR-03)', (tester) async {
    final setup = _Setup();
    await _open(tester, setup);
    await _toPassword(tester, 'sara@example.com');
    await _tap(tester, 'Forgot password?');
    expect(find.text("We'll email you a reset link at sara@example.com."), findsOneWidget);
    await _tap(tester, 'Send link');
    expect(find.text('Check your inbox'), findsOneWidget);
    expect(setup.auth.resetLinks, 1);
  });

  testWidgets('back goes one step back; close leaves', (tester) async {
    await _open(tester, _Setup());
    await _tap(tester, 'Continue with email');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsNothing);
  });

  testWidgets('tablet: a card at most 440 wide', (tester) async {
    await _open(tester, _Setup(), screen: const Size(1024, 768));
    expect(tester.getSize(find.byType(SignInScreen)).width, lessThanOrEqualTo(440));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic: translated, no overflow', (tester) async {
    await _open(tester, _Setup(), language: 'ar');
    expect(find.text('مرحبًا بعودتك'), findsOneWidget);
    expect(find.text('المتابعة باستخدام Apple'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, _Setup());
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
