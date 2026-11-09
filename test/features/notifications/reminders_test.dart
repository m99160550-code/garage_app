import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/core/format/app_formatters.dart';
import 'package:tdc_garage/core/l10n/generated/app_localizations.dart';
import 'package:tdc_garage/features/account/application/account_providers.dart';
import 'package:tdc_garage/features/account/data/account_repository.dart';
import 'package:tdc_garage/features/garage/application/current_vehicle_controller.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/maintenance/domain/item_due.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_item.dart';
import 'package:tdc_garage/features/maintenance/domain/severity.dart';
import 'package:tdc_garage/features/maintenance/presentation/schedule_item_detail.dart';
import 'package:tdc_garage/features/mileage/presentation/update_mileage_sheet.dart';
import 'package:tdc_garage/features/notifications/application/notification_settings.dart';
import 'package:tdc_garage/features/notifications/application/reminder_notifications.dart';
import 'package:tdc_garage/features/notifications/application/reminder_primer_service.dart';
import 'package:tdc_garage/features/notifications/application/reminder_scheduler.dart';
import 'package:tdc_garage/features/notifications/data/local_notification_scheduler.dart';
import 'package:tdc_garage/features/notifications/data/notification_permission_repository.dart';
import 'package:tdc_garage/features/notifications/data/reminder_settings_repository.dart';
import 'package:tdc_garage/features/notifications/domain/notification_permission.dart';
import 'package:tdc_garage/features/notifications/domain/notification_target.dart';
import 'package:tdc_garage/features/notifications/domain/reminder_plan.dart';
import 'package:tdc_garage/features/notifications/presentation/notification_gallery_screen.dart';
import 'package:tdc_garage/features/notifications/presentation/reminder_bundle_sheet.dart';
import 'package:tdc_garage/features/notifications/presentation/widgets/lock_screen_notification.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/application/locale_controller.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';

import '../../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);
final _day = DateTime(2026, 11, 7);

ItemDue _due(
  String code, {
  required int dueInDays,
  Severity severity = Severity.major,
  ItemStatus? status,
  DateTime? snoozedUntil,
}) {
  final dueDate = _day.add(Duration(days: dueInDays));
  final s = status ?? (dueInDays < 0 ? ItemStatus.overdue : ItemStatus.dueSoon);
  return ItemDue(
    item: ScheduleItem(
      id: 'i-$code',
      vehicleId: 'v',
      code: code,
      nameEn: code == 'engine_oil' ? 'Engine oil' : (code == 'brake_fluid' ? 'Brake fluid' : 'Brake pads'),
      nameAr: code == 'engine_oil' ? 'زيت المحرك' : (code == 'brake_fluid' ? 'زيت الفرامل' : 'تيل الفرامل'),
      severity: severity,
      intervalMonths: 12,
      snoozedUntil: snoozedUntil,
    ),
    status: s,
    nextDueDate: dueDate,
    overdueSince: s == ItemStatus.overdue ? dueDate : null,
  );
}

/// The stage [due] gets [offset] days after its due date (negative before).
String? _stageAt(ItemDue due, int offset) => itemReminderOn(due, due.nextDueDate!.add(Duration(days: offset)))?.stage;

class _FixedLocale extends LocaleController {
  _FixedLocale(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

void main() {
  group('when reminders go out (FR-NOT-01, FR-NOT-02)', () {
    test('30, 7 and 1 day before; nothing on other days or on the due day', () {
      final oil = _due('engine_oil', dueInDays: 40);
      expect(_stageAt(oil, -30), 'before-30');
      expect(_stageAt(oil, -7), 'before-7');
      expect(_stageAt(oil, -1), 'before-1');
      expect(_stageAt(oil, -2), isNull);
      expect(_stageAt(oil, 0), isNull);
    });

    test('overdue on days 1, 3, 7 and 14, then stop; critical items every 30 days', () {
      final major = _due('engine_oil', dueInDays: -1);
      for (final d in [1, 3, 7, 14]) {
        expect(_stageAt(major, d), 'overdue-$d');
      }
      expect(_stageAt(major, 2), isNull);
      expect(_stageAt(major, 44), isNull);

      final critical = _due('brake_pads', dueInDays: -1, severity: Severity.critical);
      expect(_stageAt(critical, 44), 'overdue-44');
      expect(_stageAt(critical, 74), 'overdue-74');
      expect(_stageAt(critical, 45), isNull);
    });

    test('nothing while snoozed (BR-NOT-06), for Unknown or not applicable', () {
      final snoozed = _due('engine_oil', dueInDays: -1, snoozedUntil: _day.add(const Duration(days: 5)));
      expect(itemReminderOn(snoozed, _day.add(const Duration(days: 2))), isNull);
      expect(itemReminderOn(snoozed, _day.add(const Duration(days: 6))), isNotNull, reason: 'day 7 after the snooze');
      expect(itemReminderOn(_due('engine_oil', dueInDays: 7, status: ItemStatus.unknown), _day), isNull);
      expect(itemReminderOn(_due('engine_oil', dueInDays: 7, status: ItemStatus.notApplicable), _day), isNull);
    });

    test('several items on one day become one bundle (BR-NOT-03), most urgent first, at 09:00', () {
      final plan = planReminders(
        [
          VehicleReminderInput(
            vehicleId: 'v',
            dues: [
              _due('engine_oil', dueInDays: 7),
              _due('brake_pads', dueInDays: -3, severity: Severity.critical),
            ],
          ),
        ],
        from: _day,
        days: 1,
      );
      final bundle = plan.single as BundleReminder;
      expect(bundle.reminders.first, isA<OverdueReminder>());
      expect(bundle.fireAt, DateTime(2026, 11, 7, 9));
    });

    test('the mileage nudge on day 31 without a reading, then every 30 days (FR-NOT-03)', () {
      final plan = planReminders(
        [
          VehicleReminderInput(
            vehicleId: 'v',
            dues: const [],
            lastReadingDate: _day.subtract(const Duration(days: 20)),
          ),
        ],
        from: _day,
        days: 60,
      );
      expect([for (final r in plan.whereType<MileageNudge>()) r.daysSinceReading], [31, 61]);
    });

    test('every reminder has its own stable key (BR-NOT-08)', () {
      final oil = _due('engine_oil', dueInDays: 30);
      final plan = planReminders(
        [
          VehicleReminderInput(vehicleId: 'v', dues: [oil]),
        ],
        from: _day,
        days: 60,
      );
      final keys = [for (final r in plan) r.key];
      expect(keys.toSet().length, keys.length);
      final again = planReminders(
        [
          VehicleReminderInput(vehicleId: 'v', dues: [oil]),
        ],
        from: _day,
        days: 60,
      );
      expect([for (final r in again) r.key], keys);
    });
  });

  group('what they say (spec S-35)', () {
    List<ReminderNotification> build(String language, DigitStyle digits) => [
      for (final r in sampleReminders)
        buildNotification(
          r,
          l10n: lookupAppLocalizations(Locale(language)),
          languageCode: language,
          digits: digits,
          vehicleName: 'Family Camry',
          itemName: (i) => i.due.item.name(language),
        ),
    ];

    test('English: title is the vehicle; the body says what and when', () {
      final n = build('en', DigitStyle.western);
      expect(
        [for (final x in n) x.body],
        [
          'Engine oil due in 7 days',
          'Brake fluid due tomorrow',
          'Brake pads overdue by 3 days',
          '3 items need attention',
          "It's been 34 days. It takes 5 seconds.",
        ],
      );
      expect([for (final x in n) x.title], [...List.filled(4, 'Family Camry'), 'Update your mileage']);
      expect(n.every((x) => x.threadId == 'veh-camry'), isTrue, reason: 'one thread per vehicle');
    });

    test('Arabic with Arabic-Indic digits, as in the spec', () {
      final bodies = [for (final x in build('ar', DigitStyle.arabicIndic)) x.body];
      expect(bodies, [
        'زيت المحرك مستحق خلال ٧ أيام',
        'زيت الفرامل مستحق غدًا',
        'تيل الفرامل متأخر ٣ أيام',
        '٣ عناصر تحتاج انتباهك',
        'مرّ ٣٤ يومًا. يستغرق التحديث ٥ ثوانٍ.',
      ]);
    });

    test('no emoji', () {
      final emoji = RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
      for (final n in [...build('en', DigitStyle.western), ...build('ar', DigitStyle.arabicIndic)]) {
        expect(emoji.hasMatch('${n.title}${n.body}'), isFalse);
      }
    });

    test('deep links: item, bundle sheet, mileage; they read back the same', () {
      final targets = [for (final n in build('en', DigitStyle.western)) n.target];
      expect(targets[0], const OpenItem('veh-camry', 'engine_oil'));
      expect(targets[3], const OpenBundle('veh-camry', ['brake_pads', 'brake_fluid', 'engine_oil']));
      expect(targets[4], const OpenMileage('veh-camry'));
      for (final n in build('en', DigitStyle.western)) {
        expect(NotificationTarget.fromQuery(Uri.parse(n.deepLink).queryParameters), n.target);
      }
      expect(NotificationTarget.fromQuery(const {}), isNull);
    });
  });

  group('the local schedule (BR-NOT-02)', () {
    Future<MockLocalNotificationScheduler> reschedule({
      String account = 'guest',
      NotificationPermission permission = NotificationPermission.granted,
      bool enabled = true,
    }) async {
      final scheduler = MockLocalNotificationScheduler();
      final container = ProviderContainer(
        overrides: [
          garageRepositoryProvider.overrideWithValue(MockGarageRepository.forScenario('returning', now: _now)),
          accountRepositoryProvider.overrideWithValue(MockAccountRepository.fromConfig(account, now: _now)),
          notificationPermissionRepositoryProvider.overrideWithValue(
            MockNotificationPermissionRepository(initial: permission),
          ),
          reminderSettingsRepositoryProvider.overrideWithValue(MockReminderSettingsRepository(enabled)),
          localNotificationSchedulerProvider.overrideWithValue(scheduler),
          clockProvider.overrideWithValue(() => _now),
          localeControllerProvider.overrideWith(() => _FixedLocale(const Locale('en'))),
        ],
      );
      addTearDown(container.dispose);
      await container.read(reminderSchedulerProvider).reschedule();
      return scheduler;
    }

    test('a Guest with reminders on: the next 30 days, at 09:00, threaded per vehicle', () async {
      final scheduler = await reschedule();
      expect(scheduler.pending, isNotEmpty);
      for (final n in scheduler.pending) {
        expect((n.fireAt.hour, n.fireAt.minute), (9, 0));
        expect(n.fireAt.isAfter(_now), isTrue);
        expect(['veh-camry', 'veh-patrol'], contains(n.threadId));
      }
      // The Camry's oil and oil filter are due on the same day: one bundle
      // 7 days before (BR-NOT-03).
      final bundle = scheduler.pending.firstWhere((n) => n.target is OpenBundle);
      expect((bundle.title, bundle.body), ('Family Camry', '2 items need attention'));
      expect((bundle.target as OpenBundle).codes, containsAll(['engine_oil', 'oil_filter']));
      // In time order.
      final times = [for (final n in scheduler.pending) n.fireAt];
      expect(times, [...times]..sort());
    });

    test('nothing on the phone for Owners (the server sends theirs)', () async {
      expect((await reschedule(account: 'owner')).pending, isEmpty);
    });

    test('nothing with reminders off or permission declined', () async {
      expect((await reschedule(enabled: false)).pending, isEmpty);
      expect((await reschedule(permission: NotificationPermission.denied)).pending, isEmpty);
    });
  });

  group('tapping a reminder (FR-NOT-04)', () {
    Future<void> openLink(WidgetTester tester, String link) async {
      useScreen(tester, const Size(390, 1000));
      await tester.pumpWidget(
        buildTestApp(
          MockSessionRepository(scenario: 'returning'),
          overrides: [
            garageRepositoryProvider.overrideWithValue(MockGarageRepository.forScenario('returning', now: _now)),
            clockProvider.overrideWithValue(() => _now),
          ],
        ),
      );
      await finishLaunch(tester);
      GoRouter.of(tester.element(find.byType(DashboardScreen))).go(link);
      await tester.pumpAndSettle();
    }

    String? current(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first)).read(currentVehicleProvider).value;

    testWidgets('an item reminder shows its vehicle, then the item', (tester) async {
      await openLink(tester, const OpenItem('veh-patrol', 'engine_oil').link(stamp: '1'));
      expect(current(tester), 'veh-patrol');
      expect(find.byType(ScheduleItemScreen), findsOneWidget);
    });

    testWidgets('a bundle opens the bundle sheet with its items', (tester) async {
      await openLink(tester, const OpenBundle('veh-camry', ['engine_oil', 'brake_fluid']).link(stamp: '2'));
      expect(find.byType(ReminderBundleSheet), findsOneWidget);
      expect(find.text('2 items need attention'), findsOneWidget);
      expect(find.text('Engine oil'), findsWidgets);
      expect(find.text('Log service'), findsOneWidget);
    });

    testWidgets('the mileage nudge opens Update mileage', (tester) async {
      await openLink(tester, const OpenMileage('veh-patrol').link(stamp: '3'));
      expect(find.byType(UpdateMileageSheet), findsOneWidget);
      expect(current(tester), 'veh-patrol');
    });

    testWidgets('a link to a deleted vehicle just shows the dashboard', (tester) async {
      await openLink(tester, const OpenItem('veh-gone', 'engine_oil').link(stamp: '4'));
      expect(find.byType(ScheduleItemScreen), findsNothing);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });

  testWidgets('the lock-screen gallery: five reminders, readable', (tester) async {
    final handle = tester.ensureSemantics();
    useScreen(tester, const Size(390, 1200));
    await tester.pumpWidget(
      buildTestApp(
        MockSessionRepository(scenario: 'returning'),
        overrides: [clockProvider.overrideWithValue(() => _now)],
      ),
    );
    await finishLaunch(tester);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/dev/notifications');
    await tester.pumpAndSettle();
    expect(find.byType(LockScreenNotification), findsNWidgets(5));
    expect(find.bySemanticsLabel('TDC Garage, Family Camry, Engine oil due in 7 days'), findsOneWidget);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
