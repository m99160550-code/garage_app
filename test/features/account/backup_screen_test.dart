import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/core/widgets/app_button.dart';
import 'package:tdc_garage/core/widgets/app_text_field.dart';
import 'package:tdc_garage/features/account/application/account_providers.dart';
import 'package:tdc_garage/features/account/application/backup_controller.dart';
import 'package:tdc_garage/features/account/data/account_repository.dart';
import 'package:tdc_garage/features/account/data/backup_repository.dart';
import 'package:tdc_garage/features/account/domain/backup.dart';
import 'package:tdc_garage/features/account/presentation/backup_offer_sheet.dart';
import 'package:tdc_garage/features/account/presentation/backup_screen.dart';
import 'package:tdc_garage/features/account/presentation/sign_in_screen.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/help/presentation/contact_screen.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/service_history/application/service_history_providers.dart';
import 'package:tdc_garage/features/service_history/data/service_record_repository.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/settings/presentation/profile_screen.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';
import 'package:tdc_garage/features/vehicles/domain/body_type.dart';
import 'package:tdc_garage/features/vehicles/domain/fuel_type.dart';
import 'package:tdc_garage/features/vehicles/domain/paint_color.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

class _Setup {
  _Setup({int accountVehicles = 3, bool interruptOnce = false, bool failing = false, String account = 'guest'})
    : backup = MockBackupRepository(
        accountVehicles: accountVehicles,
        interruptOnce: interruptOnce,
        failing: failing,
        step: const Duration(milliseconds: 100),
      ),
      accounts = MockAccountRepository.fromConfig(account, now: _now);

  final MockBackupRepository backup;
  final MockAccountRepository accounts;
  final garage = MockGarageRepository.forScenario('returning', now: _now);

  List<Override> get overrides => [
    garageRepositoryProvider.overrideWithValue(garage),
    serviceRecordRepositoryProvider.overrideWithValue(MockServiceRecordRepository.forScenario('returning', now: _now)),
    backupRepositoryProvider.overrideWithValue(backup),
    accountRepositoryProvider.overrideWithValue(accounts),
    clockProvider.overrideWithValue(() => _now),
  ];
}

Future<void> _launch(WidgetTester tester, _Setup setup, {Size? screen, String? language}) async {
  useScreen(tester, screen ?? const Size(390, 1000));
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        ...setup.overrides,
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
}

Future<void> _open(WidgetTester tester, _Setup setup, String step, {Size? screen, String? language}) async {
  await _launch(tester, setup, screen: screen, language: language);
  GoRouter.of(tester.element(find.byType(DashboardScreen))).push('/account/backup?step=$step');
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byType(BackupScreen), findsOneWidget);
}

/// Runs the mock upload to its end (11 steps of 100 ms, plus pauses).
Future<void> _finishUpload(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Vehicle _car(String id, {String? vin}) => Vehicle(
  id: id,
  brandId: 'toyota',
  modelId: 'toyota-camry',
  fuelType: FuelType.petrol,
  bodyType: BodyType.sedan,
  paint: PaintColor.fallback,
  vin: vin,
  odometerKm: 1000,
);

void main() {
  group('S-29 rules', () {
    test('the automatic offer: at most 3 times, 30 days apart (BR-USR-06)', () {
      expect(canOfferBackup(const [], now: _now), isTrue);
      expect(canOfferBackup([_now.subtract(const Duration(days: 10))], now: _now), isFalse);
      expect(canOfferBackup([_now.subtract(const Duration(days: 30))], now: _now), isTrue);
      final three = [for (var i = 1; i <= 3; i++) _now.subtract(Duration(days: 40 * i))];
      expect(canOfferBackup(three, now: _now), isFalse);
    });

    test('how many vehicles fit next to the account\'s (BR-USR-08)', () {
      expect(vehiclesThatFit(account: 3), 22);
      expect(vehiclesThatFit(account: 24), 1);
      expect(vehiclesThatFit(account: 30), 0);
    });

    test('duplicates match the VIN, ignoring case and spaces; no VIN never matches', () {
      final pairs = duplicatesByVin(
        [_car('d1', vin: ' 4t1c11ak5nu123456'), _car('d2')],
        [_car('a1', vin: '4T1C11AK5NU123456'), _car('a2')],
      );
      expect([for (final (d, a) in pairs) (d.id, a.id)], [('d1', 'a1')]);
    });

    test('takeAutomaticOffer: Guests once per 30 days; never for Owners', () async {
      final guest = _Setup();
      final container = ProviderContainer(overrides: guest.overrides);
      addTearDown(container.dispose);
      expect(await container.read(backupActionsProvider).takeAutomaticOffer(), isTrue);
      expect(await container.read(backupActionsProvider).takeAutomaticOffer(), isFalse);
      expect(await guest.backup.offersShown(), hasLength(1));

      final owner = ProviderContainer(overrides: _Setup(account: 'owner').overrides);
      addTearDown(owner.dispose);
      expect(await owner.read(backupActionsProvider).takeAutomaticOffer(), isFalse);
    });
  });

  testWidgets('the offer from Profile: benefits, warning; "Back up now" opens sign-in', (tester) async {
    await _launch(tester, _Setup(), screen: const Size(390, 2600));
    GoRouter.of(tester.element(find.byType(DashboardScreen))).go('/profile');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back up your garage'));
    await tester.pumpAndSettle();

    expect(find.byType(BackupOfferSheet), findsOneWidget);
    expect(find.text('Back up and sync your garage'), findsOneWidget);
    expect(find.text('Keep your history if you lose your phone'), findsOneWidget);
    expect(find.text('Use it on your iPad too'), findsOneWidget);
    expect(find.text('Private to you. No advertising.'), findsOneWidget);
    expect(find.text('Right now your data is only on this phone.'), findsOneWidget);

    await _tap(tester, 'Back up now');
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('Back up and sync your garage'), findsOneWidget, reason: 'the S-28 backup title');
  });

  testWidgets('upload: the ring and counts, no close while running, then Done → Profile', (tester) async {
    await _open(tester, _Setup(), 'upload');
    expect(find.textContaining(RegExp(r'^Backing up 2 vehicles and \d+ records…$')), findsOneWidget);
    expect(find.byTooltip('Close'), findsNothing);

    // Back is blocked while it runs.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(BackupScreen), findsOneWidget);

    await _finishUpload(tester);
    expect(find.text('Your garage is backed up'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'Done'));
    await tester.pumpAndSettle();
    expect(find.byType(BackupScreen), findsNothing);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('a lost connection pauses it: "Waiting for connection…", then it finishes', (tester) async {
    await _open(tester, _Setup(interruptOnce: true), 'upload');
    var waited = false;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Waiting for connection… Your data is safe on this phone.').evaluate().isNotEmpty) waited = true;
    }
    await tester.pumpAndSettle();
    expect(waited, isTrue);
    expect(find.text('Your garage is backed up'), findsOneWidget);
  });

  testWidgets('repeated failures: "Backup didn\'t finish", Retry and Contact support', (tester) async {
    final setup = _Setup(failing: true);
    await _open(tester, setup, 'upload');
    await _finishUpload(tester);
    expect(find.text("Backup didn't finish"), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget, reason: 'can leave once it stops');

    setup.backup.failing = false;
    await _tap(tester, 'Try again');
    await _finishUpload(tester);
    expect(find.text('Your garage is backed up'), findsOneWidget);
    expect(setup.backup.uploads, 2);
  });

  testWidgets('"Contact support" after a failure leaves for the contact screen', (tester) async {
    await _open(tester, _Setup(failing: true), 'upload');
    await _finishUpload(tester);
    await _tap(tester, 'Contact support');
    expect(find.byType(BackupScreen), findsNothing);
    expect(find.byType(ContactScreen), findsOneWidget);
  });

  testWidgets('merge (recommended): the same-VIN warning, remove the copy, then upload', (tester) async {
    final setup = _Setup();
    await _open(tester, setup, 'merge');
    expect(find.text('This account already has a garage'), findsOneWidget);
    expect(find.text("Adds this phone's 2 vehicles to your account's 3 vehicles."), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Merge into this account, Recommended')), findsOneWidget);

    await _tap(tester, 'Continue');
    expect(find.text('These look like the same car'), findsOneWidget);
    expect(find.text('Family Camry'), findsOneWidget);
    expect(find.text('Camry (account)'), findsOneWidget);
    expect(find.text('On this phone'), findsOneWidget);
    expect((await setup.garage.vehicles()).length, 5);

    await _tap(tester, "Remove this phone's copy");
    expect(find.text('Family Camry'), findsNothing);
    final ids = [for (final v in await setup.garage.vehicles()) v.id];
    expect(ids, hasLength(4));
    expect(ids, containsAll(['acc-0', 'acc-1', 'acc-2']));

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Backing up 4 vehicles'), findsOneWidget);
    await _finishUpload(tester);
  });

  testWidgets('discard needs DISCARD typed; then the account\'s garage loads', (tester) async {
    final setup = _Setup();
    await _open(tester, setup, 'merge');
    await tester.tap(find.text("Discard this phone's data"));
    await tester.pumpAndSettle();
    await _tap(tester, 'Continue');
    expect(find.text("Discard this phone's data?"), findsOneWidget);

    final confirm = find.widgetWithText(AppButton, 'Discard');
    expect(tester.widget<AppButton>(confirm).onPressed, isNull);
    await tester.enterText(
      find.descendant(of: find.byType(AppTextField), matching: find.byType(EditableText)),
      'discard',
    );
    await tester.pumpAndSettle();
    expect(tester.widget<AppButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("This phone now shows your account's garage"), findsOneWidget);
    await tester.pumpAndSettle();
    expect([for (final v in await setup.garage.vehicles()) v.id], ['acc-0', 'acc-1', 'acc-2']);
    expect(find.byType(BackupScreen), findsNothing);
  });

  testWidgets('cancelling the discard dialog changes nothing', (tester) async {
    final setup = _Setup();
    await _open(tester, setup, 'merge');
    await tester.tap(find.text("Discard this phone's data"));
    await tester.pumpAndSettle();
    await _tap(tester, 'Continue');
    await _tap(tester, 'Cancel');
    expect(find.byType(BackupScreen), findsOneWidget);
    expect((await setup.garage.vehicles()).length, 2);
  });

  testWidgets('over the limit: "You can bring 1 of 2", Continue waits until it fits', (tester) async {
    final setup = _Setup(accountVehicles: 24);
    await _open(tester, setup, 'merge');
    expect(find.text('Choose what to bring'), findsOneWidget);
    expect(find.text('You can bring 1 of 2'), findsOneWidget);
    final continueButton = find.widgetWithText(AppButton, 'Continue');
    expect(tester.widget<AppButton>(continueButton).onPressed, isNull);

    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    expect(tester.widget<AppButton>(continueButton).onPressed, isNotNull);

    // Ticking it again goes back over the limit.
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox).last).value, isTrue);
    expect(tester.widget<AppButton>(continueButton).onPressed, isNull);
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();

    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    final vehicles = await setup.garage.vehicles();
    expect(vehicles, hasLength(25), reason: '1 brought + 24 from the account');
  });

  testWidgets('tablet: a card at most 480 wide', (tester) async {
    await _open(tester, _Setup(), 'merge', screen: const Size(1024, 768));
    expect(tester.getSize(find.byType(BackupScreen)).width, lessThanOrEqualTo(480));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic: translated, no overflow', (tester) async {
    await _open(tester, _Setup(accountVehicles: 24), 'merge', language: 'ar');
    expect(find.text('هذا الحساب لديه كراج بالفعل'), findsOneWidget);
    expect(find.text('يمكنك نقل 1 من 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines (offer, merge, upload)', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, _Setup(), 'merge');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await _tap(tester, 'Continue');
    await _tap(tester, 'Continue');
    await _finishUpload(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await tester.tap(find.widgetWithText(AppButton, 'Done'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(AppButton, 'Back up your garage'));
    await tester.tap(find.widgetWithText(AppButton, 'Back up your garage'));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
