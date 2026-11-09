import '../application/reminder_notifications.dart';

/// Schedules notifications on this phone (a local-notifications plugin
/// later). Only Guests use it; Owners get theirs from the server
/// (BR-NOT-02).
abstract interface class LocalNotificationScheduler {
  /// Replaces every pending reminder with [notifications] (BR-NOT-04).
  Future<void> replaceAll(List<ReminderNotification> notifications);

  Future<void> cancelAll();
}

/// Keeps the schedule in memory.
class MockLocalNotificationScheduler implements LocalNotificationScheduler {
  List<ReminderNotification> pending = const [];
  int updates = 0;

  @override
  Future<void> replaceAll(List<ReminderNotification> notifications) async {
    pending = List.unmodifiable(notifications);
    updates++;
  }

  @override
  Future<void> cancelAll() async {
    pending = const [];
    updates++;
  }
}
