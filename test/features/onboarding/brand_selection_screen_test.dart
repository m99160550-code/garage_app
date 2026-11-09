import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/core/routing/app_router.dart';
import 'package:tdc_garage/core/routing/app_routes.dart';
import 'package:tdc_garage/features/onboarding/presentation/brand/brand_selection_screen.dart';
import 'package:tdc_garage/features/onboarding/presentation/model/model_selection_screen.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/session/domain/app_session.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/vehicles/application/vehicle_draft_controller.dart';

import '../../helpers/test_app.dart';

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

class _Opened {
  _Opened(this.session);

  final MockSessionRepository session;

  late ProviderContainer container;
}

Future<_Opened> _openBrand(WidgetTester tester, {String country = 'SA', Size? screen, String? language}) async {
  screen == null ? usePhoneScreen(tester) : useScreen(tester, screen);
  final opened = _Opened(MockSessionRepository(scenario: 'brandStep'));
  await tester.pumpWidget(
    buildTestApp(
      opened.session,
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(
          MockPreferencesRepository(RegionalPreferences(countryCode: country)),
        ),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  expect(find.byType(BrandSelectionScreen), findsOneWidget);
  opened.container = ProviderScope.containerOf(tester.element(find.byType(BrandSelectionScreen)));
  return opened;
}

/// The tappable row for a brand. `.last` skips the monogram, whose letters
/// can equal the name (for example "MG").
Finder _row(String name) => find.ancestor(of: find.text(name).last, matching: find.byType(InkWell)).first;

Future<void> _search(WidgetTester tester, String query) async {
  await tester.tap(find.bySemanticsLabel('Search brand…'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the title, prompt and the Gulf Popular list in rank order', (tester) async {
    await _openBrand(tester, country: 'SA');
    expect(find.text('Garage'), findsWidgets);
    expect(find.text('Select your car brand'), findsOneWidget);

    final toyota = tester.getTopLeft(_row('Toyota'));
    final hyundai = tester.getTopLeft(_row('Hyundai'));
    expect(toyota.dy, lessThan(hyundai.dy), reason: 'Gulf list starts Toyota, Hyundai');
    expect(find.text('Popular'), findsOneWidget);
  });

  testWidgets('Egypt gets the Egypt Popular list', (tester) async {
    await _openBrand(tester, country: 'EG');
    final nissan = tester.getTopLeft(_row('Nissan'));
    final mg = tester.getTopLeft(_row('MG'));
    expect(nissan.dy, lessThan(mg.dy));
  });

  testWidgets('selecting shows the badge and Continue, tapping again undoes it', (tester) async {
    await _openBrand(tester);
    expect(find.text('Continue with Toyota'), findsNothing);

    await tester.tap(_row('Toyota'));
    await tester.pumpAndSettle();
    expect(find.text('Selected'), findsOneWidget);
    expect(find.text('Continue with Toyota'), findsOneWidget);

    await tester.tap(_row('Toyota'));
    await tester.pumpAndSettle();
    expect(find.text('Selected'), findsNothing);
    expect(find.text('Continue with Toyota'), findsNothing);
  });

  testWidgets('Continue saves the brand and opens Model selection', (tester) async {
    final opened = await _openBrand(tester);
    await tester.tap(_row('Kia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Kia'));
    await tester.pumpAndSettle();

    expect(find.byType(ModelSelectionScreen), findsOneWidget);
    expect(opened.container.read(vehicleDraftProvider).brandId, 'kia');
    expect((await tester.runAsync(opened.session.load))!.setupDraftStep, SetupStep.model);
  });

  testWidgets('tabs switch the list and keep the selection', (tester) async {
    await _openBrand(tester);
    await tester.tap(_row('Toyota'));
    await tester.pumpAndSettle();

    // The Chinese tab is past the screen edge on phones: scroll to it.
    await tester.ensureVisible(find.text('Chinese'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chinese'));
    await tester.pumpAndSettle();
    expect(find.text('BYD'), findsWidgets);
    expect(find.text('Changan'), findsOneWidget, reason: 'alphabetical: BYD, Changan, …');
    expect(find.text('Toyota'), findsNothing);
    expect(find.text('Continue with Toyota'), findsOneWidget);
  });

  testWidgets('search matches Arabic names from the English UI', (tester) async {
    await _openBrand(tester);
    await tester.tap(find.text('Japanese'));
    await tester.pumpAndSettle();
    await _search(tester, 'تويوتا');
    expect(find.text('Toyota'), findsOneWidget);
    expect(find.text('تويوتا'), findsWidgets, reason: 'the matched Arabic name is shown as a hint');
    expect(find.text('Nissan'), findsNothing);
  });

  testWidgets('no match shows the empty state and jumps to the tab that matches', (tester) async {
    await _openBrand(tester);
    await _search(tester, 'byd');
    // BYD is not on the Gulf Popular list.
    expect(find.text('No brands found'), findsOneWidget);
    expect(find.text('Chinese (1)'), findsOneWidget);

    await tester.tap(find.text('Chinese (1)'));
    await tester.pumpAndSettle();
    expect(find.text('BYD'), findsWidgets);
    expect(find.text('No brands found'), findsNothing);
  });

  testWidgets('"Add … as other brand" prefills Other brand and enables Continue', (tester) async {
    final opened = await _openBrand(tester);
    await _search(tester, 'Proton');
    await tester.tap(find.text('Add “Proton” as other brand'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Proton'), findsOneWidget);
    await tester.tap(find.text('Continue with Proton'));
    await tester.pumpAndSettle();
    expect(opened.container.read(vehicleDraftProvider).brandOtherName, 'Proton');
  });

  testWidgets('Other brand needs a name before Continue appears', (tester) async {
    await _openBrand(tester);
    final brandList = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Other brand'), 200, scrollable: brandList);
    await tester.tap(find.text('Other brand'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Continue with'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'Proton');
    await tester.pumpAndSettle();
    expect(find.text('Continue with Proton'), findsOneWidget);
  });

  testWidgets('Arabic UI: Arabic names, Arabic title and right-to-left', (tester) async {
    await _openBrand(tester, language: 'ar');
    expect(find.text('كراجي'), findsWidgets);
    expect(find.text('تويوتا'), findsOneWidget);
    expect(find.text('الشائعة'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(BrandSelectionScreen))), TextDirection.rtl);
  });

  testWidgets('tablet landscape: split layout with tabs above a two-column grid', (tester) async {
    await _openBrand(tester, screen: const Size(1024, 768));
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    final toyota = tester.getTopLeft(_row('Toyota'));
    final hyundai = tester.getTopLeft(_row('Hyundai'));
    expect(toyota.dy, closeTo(hyundai.dy, 1), reason: 'side by side in the grid');
    expect(toyota.dx, lessThan(hyundai.dx));
    final tabs = tester.getTopLeft(find.text('Popular'));
    expect(tabs.dy, lessThan(toyota.dy), reason: 'tabs sit above the list');
  });

  testWidgets('largest text hides the decorative title and opens the sheet high', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openBrand(tester);
    expect(find.text('Garage'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding another vehicle: close button, no steps, discard prompt', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      buildTestApp(
        MockSessionRepository(scenario: 'returning'),
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(
            MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA')),
          ),
        ],
      ),
    );
    await finishLaunch(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(DashboardScreen)));
    unawaited(container.read(appRouterProvider).push('${AppRoutes.setupBrand}?add=1'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Close'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Step')), findsNothing);

    await tester.tap(_row('Toyota'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Discard this vehicle?'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('announces the selected state to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await _openBrand(tester);
    await tester.tap(_row('Toyota'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Toyota')),
      isSemantics(label: 'Toyota', isButton: true, isSelected: true),
    );
    semantics.dispose();
  });

  testWidgets('meets tap-target guidelines', (tester) async {
    await _openBrand(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
