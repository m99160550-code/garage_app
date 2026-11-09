import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/features/onboarding/presentation/country/country_screen.dart';
import 'package:tdc_garage/features/onboarding/presentation/intro/intro_screen.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';

import 'package:tdc_garage/features/account/presentation/sign_in_screen.dart';

import '../../helpers/test_app.dart';

Future<MockSessionRepository> _openIntro(WidgetTester tester) async {
  usePhoneScreen(tester);
  final repository = MockSessionRepository(scenario: 'firstRun');
  await tester.pumpWidget(buildTestApp(repository));
  await finishLaunch(tester);
  expect(find.byType(IntroScreen), findsOneWidget);
  return repository;
}

void main() {
  testWidgets('Next walks through all three pages', (tester) async {
    await _openIntro(tester);
    expect(find.text("Your car's health at a glance"), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Never miss a service'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Start now, no account needed'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    // Skip is hidden (but keeps its space) on the last page.
    expect(find.text('Skip').hitTestable(), findsNothing);
  });

  testWidgets('swiping changes the page', (tester) async {
    await _openIntro(tester);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Never miss a service'), findsOneWidget);
  });

  testWidgets('Skip marks the intro as seen and opens Country', (tester) async {
    final repository = await _openIntro(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(CountryScreen), findsOneWidget);
    expect((await tester.runAsync(repository.load))!.hasCompletedIntro, isTrue);

    // Back from Country returns to the intro (spec S-03), as the system
    // back gesture does.
    GoRouter.of(tester.element(find.byType(CountryScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(IntroScreen), findsOneWidget);
  });

  testWidgets('Get started on the last page opens Country', (tester) async {
    await _openIntro(tester);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.byType(CountryScreen), findsOneWidget);
  });

  testWidgets('Sign in opens the sign-in screen without finishing the intro', (tester) async {
    final repository = await _openIntro(tester);
    await tester.tap(find.text('I already have an account · Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    expect((await tester.runAsync(repository.load))!.hasCompletedIntro, isFalse);
  });

  testWidgets('the language switch turns the app Arabic and right to left', (tester) async {
    await _openIntro(tester);
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(find.text('صحة سيارتك في لمحة'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    final direction = Directionality.of(tester.element(find.byType(PageView)));
    expect(direction, TextDirection.rtl);
  });

  testWidgets('announces the page position to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await _openIntro(tester);
    expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Page 2 of 3'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Reduce Motion still moves to the next page', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true, size: Size(390, 844)),
        child: buildTestApp(MockSessionRepository(scenario: 'firstRun')),
      ),
    );
    await finishLaunch(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Never miss a service'), findsOneWidget);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    await _openIntro(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('largest text size still shows the buttons without overflow', (tester) async {
    usePhoneScreen(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(buildTestApp(MockSessionRepository(scenario: 'firstRun')));
    await finishLaunch(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Next'), findsOneWidget);
  });
}
