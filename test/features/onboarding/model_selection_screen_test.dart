import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/onboarding/presentation/details/vehicle_details_screen.dart';
import 'package:tdc_garage/features/onboarding/presentation/model/model_selection_screen.dart';
import 'package:tdc_garage/features/onboarding/presentation/model/widgets/model_card.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/session/domain/app_session.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/vehicles/application/vehicle_draft_controller.dart';
import 'package:tdc_garage/features/vehicles/domain/body_type.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle_draft.dart';

import '../../helpers/test_app.dart';

/// Starts the draft with a brand already chosen on S-04.
class _SeededDraft extends VehicleDraftController {
  _SeededDraft(this.seed);

  final VehicleDraft seed;

  @override
  VehicleDraft build() => seed;
}

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

class _Opened {
  _Opened(this.session, this.container);

  final MockSessionRepository session;
  final ProviderContainer container;

  VehicleDraft get draft => container.read(vehicleDraftProvider);
}

Future<_Opened> _openModel(
  WidgetTester tester, {
  VehicleDraft draft = const VehicleDraft(brandId: 'toyota'),
  Size? screen,
  String? language,
}) async {
  screen == null ? usePhoneScreen(tester) : useScreen(tester, screen);
  final session = MockSessionRepository(scenario: 'modelStep');
  await tester.pumpWidget(
    buildTestApp(
      session,
      overrides: [
        vehicleDraftProvider.overrideWith(() => _SeededDraft(draft)),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  expect(find.byType(ModelSelectionScreen), findsOneWidget);
  return _Opened(session, ProviderScope.containerOf(tester.element(find.byType(ModelSelectionScreen))));
}

Finder get _continue => find.widgetWithText(TextButton, 'Continue');

bool _continueEnabled(WidgetTester tester) => tester.widget<TextButton>(_continue).onPressed != null;

void main() {
  testWidgets('shows the brand header and its models with details', (tester) async {
    await _openModel(tester);
    expect(find.text('Toyota'), findsOneWidget);
    expect(find.text('TO'), findsOneWidget);
    expect(find.text('Choose your model'), findsOneWidget);
    expect(find.text('Land Cruiser'), findsOneWidget);
    expect(find.text('Camry'), findsOneWidget);
    expect(find.text('Sedan · Usually hybrid'), findsOneWidget);
    expect(find.text('Other model'), findsOneWidget);
    expect(_continueEnabled(tester), isFalse);
  });

  testWidgets('choosing a model enables Continue and saves model and body type', (tester) async {
    final opened = await _openModel(tester);
    await tester.tap(find.text('Hilux'));
    await tester.pumpAndSettle();
    expect(_continueEnabled(tester), isTrue);

    await tester.tap(_continue);
    await tester.pumpAndSettle();
    expect(find.byType(VehicleDetailsScreen), findsOneWidget);
    expect(opened.draft.modelId, 'toyota-hilux');
    expect(opened.draft.bodyType, BodyType.pickup);
    expect((await tester.runAsync(opened.session.load))!.setupDraftStep, SetupStep.details);
  });

  testWidgets('models are single choice', (tester) async {
    await _openModel(tester);
    await tester.tap(find.text('Camry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corolla'));
    await tester.pumpAndSettle();
    final selected = find.byWidgetPredicate((w) => w is Semantics && (w.properties.selected ?? false));
    expect(selected, findsOneWidget);
  });

  testWidgets('Other model needs a name and a body type', (tester) async {
    final opened = await _openModel(tester);
    await tester.scrollUntilVisible(find.text('Other model'), 200);
    await tester.tap(find.text('Other model'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Crown');
    await tester.pumpAndSettle();
    expect(_continueEnabled(tester), isFalse, reason: 'body type still missing');

    final page = find.descendant(of: find.byType(SingleChildScrollView), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Wagon'), 200, scrollable: page);
    await tester.tap(find.text('Wagon'));
    await tester.pumpAndSettle();
    expect(_continueEnabled(tester), isTrue);

    await tester.tap(_continue);
    await tester.pumpAndSettle();
    expect(opened.draft.modelOtherName, 'Crown');
    expect(opened.draft.bodyType, BodyType.wagon);
  });

  testWidgets('a typed brand goes straight to Other model', (tester) async {
    await _openModel(tester, draft: const VehicleDraft(brandOtherName: 'Proton'));
    expect(find.text('Proton'), findsOneWidget);
    expect(find.text('PR'), findsOneWidget, reason: 'monogram from the typed name');
    expect(find.byType(TextFormField), findsOneWidget, reason: 'Other model is already open');
    expect(find.text('Model list for this brand is coming soon.'), findsNothing);
  });

  testWidgets('a brand without models yet says so and opens Other model', (tester) async {
    await _openModel(tester, draft: const VehicleDraft(brandId: 'audi'));
    expect(find.text('Audi'), findsOneWidget);
    expect(find.text('Model list for this brand is coming soon.'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('without a brand it sends the user back to Brand selection', (tester) async {
    await _openModel(tester, draft: const VehicleDraft());
    expect(find.text('Choose a brand first'), findsOneWidget);
    await tester.tap(find.text('Choose brand'));
    await tester.pumpAndSettle();
    expect(find.text('Select your car brand'), findsOneWidget);
  });

  testWidgets('returning to the step keeps the earlier choice', (tester) async {
    await _openModel(
      tester,
      draft: const VehicleDraft(brandId: 'toyota', modelId: 'toyota-corolla', bodyType: BodyType.sedan),
    );
    expect(_continueEnabled(tester), isTrue);
  });

  testWidgets('Arabic: Arabic names and right to left', (tester) async {
    await _openModel(tester, language: 'ar');
    expect(find.text('تويوتا'), findsOneWidget);
    expect(find.text('لاند كروزر'), findsOneWidget);
    expect(find.text('سيدان · عادةً هايبرد'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(ModelSelectionScreen))), TextDirection.rtl);
  });

  testWidgets('tablets show the models in two columns', (tester) async {
    await _openModel(tester, screen: const Size(1024, 768));
    Finder card(String name) => find.ancestor(of: find.text(name), matching: find.byType(ModelCard));
    final first = tester.getTopLeft(card('Land Cruiser'));
    final second = tester.getTopLeft(card('Camry'));
    expect(first.dy, closeTo(second.dy, 1));
    expect(first.dx, lessThan(second.dx));
  });

  testWidgets('large text does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openModel(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    await _openModel(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
