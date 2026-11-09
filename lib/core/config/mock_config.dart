/// Mock data switches (no backend yet).
///
/// Pick a starting state at build time, for example:
/// `flutter run --dart-define=MOCK_SCENARIO=returning`
abstract final class MockConfig {
  /// One of: `firstRun`, `countryStep`, `brandStep`, `modelStep`,
  /// `detailsStep`, `baselineStep`, `setupDraft`, `returning`, `loadError`.
  static const String scenario = String.fromEnvironment('MOCK_SCENARIO', defaultValue: 'firstRun');

  /// Simulated local-database load time for the launch screen.
  static const int launchLatencyMs = int.fromEnvironment('MOCK_LATENCY_MS', defaultValue: 600);

  /// Force a UI language for previews: `ar` or `en`. Empty follows the device.
  static const String localeOverride = String.fromEnvironment('MOCK_LOCALE', defaultValue: '');

  /// Force the device region for previews, for example `DE` (consent
  /// required) or `SA`. `none` simulates an unknown region.
  static const String regionOverride = String.fromEnvironment('MOCK_REGION', defaultValue: '');

  /// Brand already chosen in previews that start at `modelStep`
  /// (a brand id such as `toyota`, or `other:Proton` for a typed brand).
  static const String draftBrand = String.fromEnvironment('MOCK_BRAND', defaultValue: 'toyota');

  /// Notification permission at launch: `notDetermined`, `granted` or
  /// `denied` (S-08 shows "Open Settings" for `denied`).
  static const String notificationStatus = String.fromEnvironment('MOCK_NOTIFY', defaultValue: 'notDetermined');

  /// What the simulated system prompt answers: `allow` or `deny`.
  static const String notificationAnswer = String.fromEnvironment('MOCK_NOTIFY_ANSWER', defaultValue: 'allow');

  /// The account at launch: `guest` (default), `owner`, `ownerUnverified`
  /// (email not verified), `ownerPending` (3 changes waiting to sync),
  /// `ownerSyncing` (sending them now) or
  /// `ownerOffline`.
  static const String account = String.fromEnvironment('MOCK_ACCOUNT', defaultValue: 'guest');

  /// `true` shows the help screens as without a connection: the saved
  /// short FAQ and its banner (S-31).
  static const bool helpOffline = bool.fromEnvironment('MOCK_HELP_OFFLINE');

  /// `true` adds a mileage sync conflict to the sample Camry (S-33).
  static const bool mileageReview = bool.fromEnvironment('MOCK_MILEAGE_REVIEW');

  /// `true` makes this version unsupported: S-34 "Update required".
  static const bool updateRequired = bool.fromEnvironment('MOCK_UPDATE_REQUIRED');

  /// `true` opens the S-35 lock-screen gallery at launch (design review).
  static const bool notificationGallery = bool.fromEnvironment('MOCK_NOTIFICATION_GALLERY');
}
