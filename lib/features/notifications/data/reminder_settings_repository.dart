/// The in-app "Service reminders" switch (FR-NOT-05). Separate from the
/// system permission: both must be on for reminders to arrive. Stored with
/// the user's settings (synced for Owners) later.
abstract interface class ReminderSettingsRepository {
  Future<bool> enabled();
  Future<void> setEnabled(bool enabled);
}

/// In-memory switch for development. On by default.
class MockReminderSettingsRepository implements ReminderSettingsRepository {
  MockReminderSettingsRepository([this._enabled = true]);

  bool _enabled;

  @override
  Future<bool> enabled() async => _enabled;

  @override
  Future<void> setEnabled(bool enabled) async => _enabled = enabled;
}
