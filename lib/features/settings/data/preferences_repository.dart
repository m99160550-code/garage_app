import '../domain/regional_preferences.dart';

/// Stores the user's regional preferences (Drift locally, synced for
/// Owners). Screens only depend on this interface.
abstract interface class PreferencesRepository {
  Future<RegionalPreferences> load();
  Future<void> save(RegionalPreferences preferences);
}

/// In-memory version used until the local database exists.
class MockPreferencesRepository implements PreferencesRepository {
  MockPreferencesRepository([this._current = const RegionalPreferences()]);

  RegionalPreferences _current;

  RegionalPreferences get current => _current;

  @override
  Future<RegionalPreferences> load() async => _current;

  @override
  Future<void> save(RegionalPreferences preferences) async => _current = preferences;
}
