import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/core/l10n/generated/app_localizations.dart';
import 'package:tdc_garage/core/theme/app_theme.dart';
import 'package:tdc_garage/features/notifications/application/reminder_primer_service.dart';
import 'package:tdc_garage/features/notifications/data/notification_permission_repository.dart';
import 'package:tdc_garage/features/notifications/domain/notification_permission.dart';
import 'package:tdc_garage/features/notifications/presentation/reminder_primer_trigger.dart';
import 'package:tdc_garage/features/notifications/presentation/reminders_primer_sheet.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/application/preferences_providers.dart';
import 'package:tdc_garage/features/settings/data/preferences_repository.dart';
import 'package:tdc_garage/features/settings/domain/regional_preferences.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/application/vehicle_draft_controller.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';
import 'package:tdc_garage/features/vehicles/domain/body_type.dart';
import 'package:tdc_garage/features/vehicles/domain/fuel_type.dart';
import 'package:tdc_garage/features/vehicles/domain/paint_color.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle_details.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle_draft.dart';

import '../../helpers/test_app.dart';

const _camry = VehicleDraft(
  brandId: 'toyota',
  modelId: 'toyota-camry',
  bodyType: BodyType.sedan,
  details: VehicleDetails(
    fuelType: FuelType.petrol,
    odometerKm: 54320,
    paint: PaintColor.silver,
    bodyType: BodyType.sedan,
  ),
);

class _SeededDraft extends VehicleDraftController {
  @override
  VehicleDraft build() => _camry;
}

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

/// Opens S-07 with the Camry draft, ready to save.
Future<MockNotificationPermissionRepository> _openBaseline(
  WidgetTester tester, {
  NotificationPermission initial = NotificationPermission.notDetermined,
  NotificationPermission answer = NotificationPermission.granted,
  String? language,
}) async {
  usePhoneScreen(tester);
  final permission = MockNotificationPermissionRepository(initial: initial, answer: answer);
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'baselineStep'),
      overrides: [
        vehicleDraftProvider.overrideWith(_SeededDraft.new),
        preferencesRepositoryProvider.overrideWithValue(
          MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA')),
        ),
        garageRepositoryProvider.overrideWithValue(MockGarageRepository()),
        notificationPermissionRepositoryProvider.overrideWithValue(permission),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  return permission;
}

/// Saves the car on S-07 (optionally with an oil mileage, which creates a
/// reminder) and waits for the dashboard and the primer delay.
Future<void> _saveAndArrive(WidgetTester tester, {String? oilKm = '49800'}) async {
  if (oilKm != null) {
    await tester.enterText(find.widgetWithText(TextFormField, 'Mileage').first, oilKm);
    await tester.pumpAndSettle();
  }
  final save = find.widgetWithText(TextButton, tester.any(find.text('Save vehicle')) ? 'Save vehicle' : 'حفظ السيارة');
  await tester.tap(save);
  await tester.pumpAndSettle();
  expect(find.byType(DashboardScreen), findsOneWidget);
  await tester.pump(ReminderPrimerTrigger.delay);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('after setup with a reminder, the primer explains and shows an example', (tester) async {
    await _openBaseline(tester);
    await _saveAndArrive(tester);

    expect(find.text('Never miss a service'), findsOneWidget);
    expect(find.textContaining('30, 7 and 1 day before'), findsOneWidget);
    expect(find.bySemanticsLabel('Example notification: Toyota Camry · Engine oil due in 7 days'), findsOneWidget);
    expect(find.text('Turn on reminders'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('not before the 800 ms delay', (tester) async {
    await _openBaseline(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Mileage').first, '49800');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Save vehicle'));
    await tester.pumpAndSettle();
    expect(find.text('Never miss a service'), findsNothing);
    await tester.pump(ReminderPrimerTrigger.delay);
    await tester.pumpAndSettle();
    expect(find.text('Never miss a service'), findsOneWidget);
  });

  testWidgets('Turn on reminders: allowed shows the toast', (tester) async {
    final permission = await _openBaseline(tester);
    await _saveAndArrive(tester);
    await tester.tap(find.text('Turn on reminders'));
    await tester.pumpAndSettle();

    expect(find.text('Never miss a service'), findsNothing);
    expect(find.text('Reminders are on'), findsOneWidget);
    expect(await permission.status(), NotificationPermission.granted);
  });

  testWidgets('declined in the system prompt: the sheet just closes', (tester) async {
    await _openBaseline(tester, answer: NotificationPermission.denied);
    await _saveAndArrive(tester);
    await tester.tap(find.text('Turn on reminders'));
    await tester.pumpAndSettle();
    expect(find.text('Never miss a service'), findsNothing);
    expect(find.text('Reminders are on'), findsNothing);
  });

  testWidgets('Not now closes without asking and is remembered', (tester) async {
    final permission = await _openBaseline(tester);
    await _saveAndArrive(tester);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Never miss a service'), findsNothing);
    expect(permission.requestCount, 0);
    expect(await permission.hasShownPrimer(), isTrue);
  });

  testWidgets('with every item Unknown there is no reminder, so no primer', (tester) async {
    await _openBaseline(tester);
    await _saveAndArrive(tester, oilKm: null);
    expect(find.text('Never miss a service'), findsNothing);
  });

  testWidgets('permission declined earlier: no automatic primer', (tester) async {
    await _openBaseline(tester, initial: NotificationPermission.denied);
    await _saveAndArrive(tester);
    expect(find.text('Never miss a service'), findsNothing);
  });

  testWidgets('Arabic primer, right to left', (tester) async {
    await _openBaseline(tester, language: 'ar');
    await tester.enterText(find.widgetWithText(TextFormField, 'المسافة').first, '49800');
    await tester.pumpAndSettle();
    await _saveAndArrive(tester, oilKm: null);
    expect(find.text('لا تفوّت أي صيانة'), findsOneWidget);
    expect(find.text('تفعيل التذكيرات'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(RemindersPrimerSheet))), TextDirection.rtl);
  });

  group('the sheet on its own', () {
    Future<MockNotificationPermissionRepository> openSheet(
      WidgetTester tester, {
      NotificationPermission initial = NotificationPermission.notDetermined,
    }) async {
      usePhoneScreen(tester);
      final permission = MockNotificationPermissionRepository(initial: initial);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [notificationPermissionRepositoryProvider.overrideWithValue(permission)],
          child: MaterialApp(
            theme: AppTheme.dark(arabic: false),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => Center(
                  child: TextButton(
                    onPressed: () => showRemindersPrimer(
                      context,
                      ref,
                      ReminderPrimerOffer(vehicleName: 'Family Camry', itemName: null, permission: initial),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return permission;
    }

    testWidgets('declined before: "Open Settings" opens the system Settings', (tester) async {
      final permission = await openSheet(tester, initial: NotificationPermission.denied);
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.textContaining('Turn them on in Settings'), findsOneWidget);
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(permission.settingsOpened, 1);
      expect(permission.requestCount, 0);
    });

    testWidgets('without a known item the example uses "Oil change"', (tester) async {
      await openSheet(tester);
      expect(find.bySemanticsLabel('Example notification: Family Camry · Oil change due in 7 days'), findsOneWidget);
    });

    testWidgets('swiping it away counts as Not now', (tester) async {
      final permission = await openSheet(tester);
      await tester.tapAt(const Offset(195, 40)); // the scrim
      await tester.pumpAndSettle();
      expect(find.text('Never miss a service'), findsNothing);
      expect(await permission.hasShownPrimer(), isTrue);
    });

    testWidgets('large text does not overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openSheet(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Turn on reminders'), findsOneWidget);
    });

    testWidgets('meets tap-target and contrast guidelines', (tester) async {
      await openSheet(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });
}
