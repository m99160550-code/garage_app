import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/core/widgets/app_banner.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/notifications/application/notification_settings.dart';
import 'package:tdc_garage/features/notifications/application/reminder_primer_service.dart';
import 'package:tdc_garage/features/notifications/data/notification_permission_repository.dart';
import 'package:tdc_garage/features/notifications/data/reminder_settings_repository.dart';
import 'package:tdc_garage/features/notifications/domain/notification_permission.dart';
import 'package:tdc_garage/features/notifications/presentation/notifications_screen.dart';
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
  _Setup(NotificationPermission permission, {bool enabled = true, NotificationPermission? answer})
    : permissions = MockNotificationPermissionRepository(
        initial: permission,
        answer: answer ?? NotificationPermission.granted,
      ),
      settings = MockReminderSettingsRepository(enabled);

  final MockNotificationPermissionRepository permissions;
  final MockReminderSettingsRepository settings;
}

/// Opens Profile → Reminders.
Future<void> _open(WidgetTester tester, _Setup setup, {String? language, Size? screen}) async {
  useScreen(tester, screen ?? const Size(390, 2600));
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(MockGarageRepository.forScenario('returning', now: _now)),
        notificationPermissionRepositoryProvider.overrideWithValue(setup.permissions),
        reminderSettingsRepositoryProvider.overrideWithValue(setup.settings),
        clockProvider.overrideWithValue(() => _now),
        preferencesRepositoryProvider.overrideWithValue(
          MockPreferencesRepository(const RegionalPreferences(countryCode: 'SA', currency: 'SAR')),
        ),
        if (language != null) localeControllerProvider.overrideWith(() => _FixedLocale(Locale(language))),
      ],
    ),
  );
  await finishLaunch(tester);
  GoRouter.of(tester.element(find.byType(DashboardScreen))).go('/profile');
  await tester.pumpAndSettle();
  final row = find.bySemanticsLabel(RegExp(language == 'ar' ? r'^التذكيرات,' : r'^Reminders,')).first;
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.byType(NotificationsScreen), findsOneWidget);
}

bool _switch(WidgetTester tester) => tester.widget<Switch>(find.byType(Switch)).value;

void main() {
  testWidgets('granted: the switch on, the schedule explained, no banner', (tester) async {
    await _open(tester, _Setup(NotificationPermission.granted));
    expect(find.text('Service reminders'), findsOneWidget);
    expect(_switch(tester), isTrue);
    expect(find.textContaining('Reminders arrive at 9:00, 30, 7 and 1 day before'), findsOneWidget);
    expect(find.byType(AppBanner), findsNothing);
  });

  testWidgets('turning reminders off shows "Off" in Profile (FR-NOT-05)', (tester) async {
    final setup = _Setup(NotificationPermission.granted);
    await _open(tester, setup);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(await setup.settings.enabled(), isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Reminders, Off'), findsOneWidget);
  });

  testWidgets('permission declined: warning banner and Open Settings (FR-NOT-06)', (tester) async {
    final setup = _Setup(NotificationPermission.denied);
    await _open(tester, setup);
    expect(find.text("Notifications are off in your phone's Settings."), findsOneWidget);
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(setup.permissions.settingsOpened, 1);
  });

  testWidgets('never asked: "Allow" asks for the permission', (tester) async {
    final setup = _Setup(NotificationPermission.notDetermined);
    await _open(tester, setup);
    expect(find.text('Allow notifications so your reminders can reach you.'), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(setup.permissions.requestCount, 1);
    expect(find.text('Allow notifications so your reminders can reach you.'), findsNothing);
  });

  testWidgets('switching on when never asked shows the system prompt', (tester) async {
    final setup = _Setup(NotificationPermission.notDetermined, enabled: false);
    await _open(tester, setup);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(setup.permissions.requestCount, 1);
    expect(_switch(tester), isTrue);
    expect(await setup.permissions.status(), NotificationPermission.granted);
  });

  testWidgets('Arabic: translated, no overflow', (tester) async {
    await _open(tester, _Setup(NotificationPermission.denied), language: 'ar');
    expect(find.text('تذكيرات الصيانة'), findsOneWidget);
    expect(find.text('فتح الإعدادات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('iPad landscape: in the Profile pane', (tester) async {
    useScreen(tester, const Size(1366, 1024));
    await _open(tester, _Setup(NotificationPermission.granted), screen: const Size(1366, 1024));
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('meets tap-target and contrast guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, _Setup(NotificationPermission.denied));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
