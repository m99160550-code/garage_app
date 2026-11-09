import '../domain/notification_permission.dart';

/// Talks to the platform notification permission (iOS prompt, Android 13+
/// runtime permission). Screens only depend on this interface.
abstract interface class NotificationPermissionRepository {
  Future<NotificationPermission> status();

  /// Shows the system prompt (only works while [status] is
  /// [NotificationPermission.notDetermined]) and returns the answer.
  Future<NotificationPermission> request();

  /// Opens this app's page in the system Settings app.
  Future<void> openSystemSettings();

  /// Whether the S-08 primer was already offered after setup, so it isn't
  /// offered again automatically.
  Future<bool> hasShownPrimer();

  Future<void> markPrimerShown();
}

/// In-memory permission for development. [answer] is what the simulated
/// system prompt returns. The real implementation uses the local
/// notifications plugin chosen in the architecture.
class MockNotificationPermissionRepository implements NotificationPermissionRepository {
  MockNotificationPermissionRepository({
    NotificationPermission initial = NotificationPermission.notDetermined,
    this.answer = NotificationPermission.granted,
  }) : _status = initial;

  factory MockNotificationPermissionRepository.fromConfig({required String status, required String answer}) =>
      MockNotificationPermissionRepository(
        initial: switch (status) {
          'granted' => NotificationPermission.granted,
          'denied' => NotificationPermission.denied,
          _ => NotificationPermission.notDetermined,
        },
        answer: answer == 'deny' ? NotificationPermission.denied : NotificationPermission.granted,
      );

  final NotificationPermission answer;
  NotificationPermission _status;
  bool _primerShown = false;
  int requestCount = 0;
  int settingsOpened = 0;

  @override
  Future<NotificationPermission> status() async => _status;

  @override
  Future<NotificationPermission> request() async {
    requestCount++;
    if (_status == NotificationPermission.notDetermined) _status = answer;
    return _status;
  }

  @override
  Future<void> openSystemSettings() async => settingsOpened++;

  @override
  Future<bool> hasShownPrimer() async => _primerShown;

  @override
  Future<void> markPrimerShown() async => _primerShown = true;
}
