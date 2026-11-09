import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/mileage/domain/mileage_rules.dart';
import 'package:tdc_garage/features/mileage/domain/odometer_reading.dart';
import 'package:tdc_garage/features/mileage/presentation/mileage_review_sheet.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
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

OdometerReading _r(String id, int daysAgo, int km, {bool review = false, bool correction = false}) => OdometerReading(
  id: id,
  vehicleId: 'v',
  date: DateTime(2026, 11, 7).subtract(Duration(days: daysAgo)),
  km: km,
  needsReview: review,
  isCorrection: correction,
);

Future<MockGarageRepository> _launch(
  WidgetTester tester, {
  Size? screen,
  String? language,
  double textScale = 1,
}) async {
  final garage = MockGarageRepository.forScenario('returning', now: _now, mileageReview: true);
  useScreen(tester, screen ?? const Size(390, 1000));
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(garage),
        clockProvider.overrideWithValue(() => _now),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  return garage;
}

Future<void> _openFromPill(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Check a mileage reading'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Check a mileage reading'));
  await tester.pumpAndSettle();
  expect(find.byType(MileageReviewSheet), findsOneWidget);
}

Future<List<OdometerReading>> _readings(WidgetTester tester, MockGarageRepository garage) async =>
    (await tester.runAsync(() => garage.readings('veh-camry')))!;

void main() {
  group('S-33 rules (BR-SYN-03)', () {
    final readings = [_r('a', 10, 50000), _r('b', 3, 54900), _r('c', 2, 54800, review: true)];

    test('a reading waiting for review is never the current value', () {
      expect(currentReading(readings)!.id, 'b');
      expect(currentReading([_r('x', 1, 100, review: true)]), isNull);
    });

    test('a synced reading is flagged when lower than one with an earlier date', () {
      expect(needsReviewOnSync(readings.take(2).toList(), _r('n', 1, 54000)), isTrue);
      expect(needsReviewOnSync(readings.take(2).toList(), _r('n', 1, 55000)), isFalse);
      // Lower, but only than a reading on the same day: not a sync conflict.
      expect(needsReviewOnSync([_r('s', 1, 60000)], _r('n', 1, 59000)), isFalse);
    });

    test('each flagged reading is paired with the highest earlier one', () {
      final conflicts = readingConflicts([...readings, _r('d', 5, 55000)]);
      expect(conflicts.single.flagged.id, 'c');
      expect(conflicts.single.earlier.id, 'd');
    });

    test('the average ignores readings waiting for review', () {
      final today = DateTime(2026, 11, 7);
      final base = [_r('a', 60, 50000), _r('b', 1, 53000)];
      expect(
        averageDailyKm([...base, _r('c', 0, 1000, review: true)], today: today),
        averageDailyKm(base, today: today),
      );
    });
  });

  testWidgets('the alert pill "Check a mileage reading" ranks above due soon', (tester) async {
    await _launch(tester);
    expect(find.text('Check a mileage reading'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Mileage, 54,900')), findsOneWidget, reason: 'the flagged 54,800 waits');
  });

  testWidgets('the sheet: title, body, both readings and the two choices', (tester) async {
    await _launch(tester);
    await _openFromPill(tester);
    expect(find.text('Check this reading'), findsOneWidget);
    expect(find.text('A reading from your other device is lower than an earlier one.'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^54,900 km, .+, iPhone$')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^54,800 km, .+, iPad, Needs review$')), findsOneWidget);
    expect(find.text('Use 54,800 km as a correction'), findsOneWidget);
    expect(find.text('Delete 54,800 km'), findsOneWidget);
  });

  testWidgets('"Use as a correction": it becomes the current value, marked Correction', (tester) async {
    final garage = await _launch(tester);
    await _openFromPill(tester);
    await tester.tap(find.text('Use 54,800 km as a correction'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Saved as a correction'), findsOneWidget);
    await tester.pumpAndSettle();

    final r6 = (await _readings(tester, garage)).firstWhere((r) => r.id == 'veh-camry-r6');
    expect((r6.needsReview, r6.isCorrection), (false, true));
    expect((await tester.runAsync(garage.vehicles))!.first.odometerKm, 54800);
    expect(find.text('Check a mileage reading'), findsNothing);
  });

  testWidgets('"Delete": the reading goes; 54,900 stays current', (tester) async {
    final garage = await _launch(tester);
    await _openFromPill(tester);
    await tester.tap(find.text('Delete 54,800 km'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Reading deleted'), findsOneWidget);
    await tester.pumpAndSettle();

    expect((await _readings(tester, garage)).any((r) => r.id == 'veh-camry-r6'), isFalse);
    expect((await tester.runAsync(garage.vehicles))!.first.odometerKm, 54900);
  });

  testWidgets('Mileage history: the "Needs review" badge opens the sheet', (tester) async {
    await _launch(tester, screen: const Size(390, 1600));
    GoRouter.of(tester.element(find.byType(DashboardScreen))).push('/garage/mileage');
    await tester.pumpAndSettle();
    expect(find.text('Needs review'), findsOneWidget);
    await tester.tap(find.text('Needs review'));
    await tester.pumpAndSettle();
    expect(find.byType(MileageReviewSheet), findsOneWidget);
  });

  testWidgets('side by side normally; stacked with large text', (tester) async {
    await _launch(tester, screen: const Size(390, 1600));
    await _openFromPill(tester);
    var a = tester.getTopLeft(find.text('54,900 km').last);
    var b = tester.getTopLeft(find.text('54,800 km').last);
    expect(a.dy, b.dy);

    Navigator.of(tester.element(find.byType(MileageReviewSheet))).pop();
    await tester.pumpAndSettle();
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    await tester.pumpAndSettle();
    await _openFromPill(tester);
    a = tester.getTopLeft(find.text('54,900 km').last);
    b = tester.getTopLeft(find.text('54,800 km').last);
    expect(b.dy, greaterThan(a.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic: translated, no overflow', (tester) async {
    await _launch(tester, language: 'ar');
    await tester.tap(find.text('تحقق من قراءة العداد'));
    await tester.pumpAndSettle();
    expect(find.text('تحقق من هذه القراءة'), findsOneWidget);
    expect(find.text('بحاجة إلى مراجعة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _launch(tester);
    await _openFromPill(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
