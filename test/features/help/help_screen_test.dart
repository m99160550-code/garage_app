import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/core/config/app_info.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/help/application/help_providers.dart';
import 'package:tdc_garage/features/help/data/help_content.dart';
import 'package:tdc_garage/features/help/data/help_repository.dart';
import 'package:tdc_garage/features/help/data/support_mailer.dart';
import 'package:tdc_garage/features/help/domain/help_article.dart';
import 'package:tdc_garage/features/help/presentation/contact_screen.dart';
import 'package:tdc_garage/features/help/presentation/help_article_screen.dart';
import 'package:tdc_garage/features/help/presentation/help_screen.dart';
import 'package:tdc_garage/features/help/presentation/help_topic_screen.dart';
import 'package:tdc_garage/features/help/presentation/legal_page_screen.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/presentation/profile_screen.dart';
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
  _Setup({bool online = true, bool mailApp = true})
    : help = MockHelpRepository(online: online),
      mailer = MockSupportMailer(available: mailApp);

  final MockHelpRepository help;
  final MockSupportMailer mailer;
}

Future<void> _open(
  WidgetTester tester,
  _Setup setup, {
  String location = '/profile/help',
  Size? screen,
  String? language,
}) async {
  useScreen(tester, screen ?? const Size(390, 2000));
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(MockGarageRepository.forScenario('returning', now: _now)),
        helpRepositoryProvider.overrideWithValue(setup.help),
        supportMailerProvider.overrideWithValue(setup.mailer),
        clockProvider.overrideWithValue(() => _now),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  GoRouter.of(tester.element(find.byType(DashboardScreen))).go(location);
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField).first, query);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  group('S-31 rules', () {
    test('every article exists in both languages; every topic has bundled answers (BR-SET-03)', () {
      for (final a in helpArticles) {
        expect([a.questionEn, a.questionAr, a.answerEn, a.answerAr].every((t) => t.trim().isNotEmpty), isTrue);
      }
      for (final category in HelpCategory.values) {
        expect(helpArticles.where((a) => a.category == category && a.bundled), isNotEmpty, reason: '$category');
      }
      expect(helpArticles.map((a) => a.id).toSet(), hasLength(helpArticles.length));
    });

    test('search: every word must match; questions first; Arabic letter variants', () {
      final en = searchHelp(helpArticles, 'delete data', 'en');
      expect(en.first.id, 'delete-data');
      expect(searchHelp(helpArticles, 'reminders', 'en').first.id, 'no-reminders');
      expect(searchHelp(helpArticles, 'zzzz', 'en'), isEmpty);
      expect(searchHelp(helpArticles, '   ', 'en'), isEmpty);
      // «احذف» typed with a bare alef still finds «أحذف».
      expect(searchHelp(helpArticles, 'احذف', 'ar').map((a) => a.id), contains('delete-data'));
    });

    test('the email body has the app version and device, and nothing personal', () {
      final body = supportEmailBody(appVersion: 'TDC-mena Garage 0.1.0 (1)', device: 'iOS, phone');
      expect(body, contains('App: TDC-mena Garage 0.1.0 (1)'));
      expect(body, contains('Device: iOS, phone'));
      expect(body.startsWith('\n'), isTrue, reason: 'space to write first');
    });
  });

  testWidgets('topics with counts, the contact card and the legal links', (tester) async {
    await _open(tester, _Setup());
    expect(find.byType(HelpScreen), findsOneWidget);
    expect(find.text('Search help'), findsOneWidget);
    expect(find.bySemanticsLabel('Getting started, 3 questions'), findsOneWidget);
    expect(find.bySemanticsLabel('Health score, 3 questions'), findsOneWidget);
    expect(find.bySemanticsLabel('Reminders, 2 questions'), findsOneWidget);
    expect(find.bySemanticsLabel('Backup & sync, 3 questions'), findsOneWidget);
    expect(find.bySemanticsLabel('Privacy, 2 questions'), findsOneWidget);
    expect(find.text('We reply within 2 business days (Sunday to Thursday, Cairo time)'), findsOneWidget);
    expect(find.text('We reply in the language you write in.'), findsOneWidget);
    expect(find.text('Showing saved answers. Connect for the full help centre.'), findsNothing);

    await _tapText(tester, 'Terms of use');
    expect(find.byType(LegalPageScreen), findsOneWidget);
    expect(find.text('‎tdc-mena.com‎'), findsOneWidget);
  });

  testWidgets('topic → question → article (max 560 wide) → contact', (tester) async {
    await _open(tester, _Setup(), screen: const Size(1024, 1366));
    await _tapText(tester, 'Health score');
    expect(find.byType(HelpTopicScreen), findsOneWidget);
    await _tapText(tester, 'How is the health score worked out?');

    expect(find.byType(HelpArticleScreen), findsOneWidget);
    expect(find.textContaining('It starts at 100.'), findsOneWidget);
    expect(find.textContaining('Tap the score on the Garage screen'), findsOneWidget, reason: 'second paragraph');
    final paragraph = find.textContaining('It starts at 100.');
    expect(tester.getSize(paragraph).width, lessThanOrEqualTo(HelpArticleScreen.maxTextWidth));

    await _tapText(tester, 'Contact support');
    expect(find.byType(ContactScreen), findsOneWidget);
  });

  testWidgets('search finds answers, or says there are none and shows the contact card', (tester) async {
    await _open(tester, _Setup());
    await _search(tester, 'new phone');
    expect(find.textContaining(RegExp(r'^\d+ ANSWERS?$')), findsOneWidget);
    expect(find.text('How do I move to a new phone?'), findsOneWidget);
    await _tapText(tester, 'How do I move to a new phone?');
    expect(find.textContaining('Sign in with the same account'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _search(tester, 'carburettor');
    expect(find.text('No answers for “carburettor”'), findsOneWidget);
    expect(find.text('Contact us'), findsOneWidget);
  });

  testWidgets('offline: the saved answers and the banner (BR-SET-03)', (tester) async {
    await _open(tester, _Setup(online: false));
    expect(find.text('Showing saved answers. Connect for the full help centre.'), findsOneWidget);
    expect(find.bySemanticsLabel('Getting started, 2 questions'), findsOneWidget);
    expect(find.bySemanticsLabel('Reminders, 1 question'), findsOneWidget);
    await _search(tester, 'unknown items');
    expect(find.text("Why don't unknown items count?"), findsNothing, reason: 'not in the saved copy');
  });

  testWidgets('email: composer with subject, version and device; no personal data', (tester) async {
    final setup = _Setup();
    await _open(tester, setup, location: '/profile/help/contact');
    expect(find.byType(ContactScreen), findsOneWidget);
    await tester.tap(find.text('\u200Esupport@tdc-mena.com\u200E'));
    await tester.pumpAndSettle();

    final mail = setup.mailer.last!;
    expect(mail.to, SupportInfo.email);
    expect(mail.subject, 'TDC-mena Garage support');
    expect(mail.body, contains('App: TDC-mena Garage 0.1.0 (1)'));
    expect(mail.body, contains('phone'));
    expect(mail.body, isNot(contains('Camry')));
  });

  testWidgets('no mail app: the address is copied instead', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await _open(tester, _Setup(mailApp: false), location: '/profile/help/contact');
    await tester.tap(find.text('\u200Esupport@tdc-mena.com\u200E'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(copied, SupportInfo.email);
    expect(find.text('Email address copied'), findsOneWidget);
  });

  testWidgets('iPad landscape: FAQ in the Profile detail pane', (tester) async {
    await _open(tester, _Setup(), location: '/profile', screen: const Size(1366, 1024));
    final list = find.descendant(of: find.byType(ProfileScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('FAQ'), 300, scrollable: list);
    // Clear of the floating navigation bar.
    await tester.drag(list, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FAQ'));
    await tester.pumpAndSettle();
    expect(find.byType(HelpScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('Arabic: translated, Arabic search, no overflow', (tester) async {
    await _open(tester, _Setup(), language: 'ar');
    expect(find.text('ابحث في المساعدة'), findsOneWidget);
    expect(find.bySemanticsLabel('نقاط الصحة, 3 أسئلة'), findsOneWidget);
    await _search(tester, 'هاتف جديد');
    expect(find.text('كيف أنتقل إلى هاتف جديد؟'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, _Setup(online: false));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
