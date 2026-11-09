import '../domain/app_session.dart';

/// Loads and updates the session in local storage.
///
/// The real implementation will read the Drift database (architecture AD-01).
/// Screens only depend on this interface.
abstract interface class SessionRepository {
  Future<AppSession> load();

  /// Called when the user leaves the intro (S-02) by Skip or Get started,
  /// so the next launch goes straight to setup or the dashboard.
  Future<void> markIntroCompleted();

  /// Remembers where an unfinished vehicle setup stopped, so the next
  /// launch resumes there (S-01). `null` clears it once a vehicle is saved.
  Future<void> saveSetupDraftStep(SetupStep? step);

  /// Called when a vehicle is saved: counts it, makes it the vehicle the
  /// dashboard opens on (BR-VEH-05) and clears any unfinished setup.
  Future<void> recordVehicleAdded(String vehicleId);

  /// The dashboard opens on the last vehicle viewed (BR-VEH-05).
  Future<void> saveLastVehicle(String vehicleId);

  /// Called after a vehicle is deleted. [nextVehicleId] is shown next, or
  /// `null` when the garage is now empty (BR-VEH-06).
  Future<void> recordVehicleDeleted(String vehicleId, {String? nextVehicleId});

  /// Back to a first launch: intro, then setup (S-30 "fresh state").
  Future<void> reset();
}
