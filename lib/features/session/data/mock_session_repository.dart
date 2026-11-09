import '../domain/app_session.dart';
import 'session_repository.dart';

/// In-memory session with a few named starting states for development.
class MockSessionRepository implements SessionRepository {
  MockSessionRepository({required this.scenario, this.latency = Duration.zero})
    : _introCompleted = scenario != 'firstRun',
      _setupDraftStep = switch (scenario) {
        'setupDraft' => SetupStep.details,
        'countryStep' => SetupStep.country,
        'brandStep' => SetupStep.brand,
        'modelStep' => SetupStep.model,
        'detailsStep' => SetupStep.details,
        'baselineStep' => SetupStep.baseline,
        _ => null,
      },
      _vehicleCount = scenario == 'returning' ? 2 : 0,
      _lastVehicleId = scenario == 'returning' ? 'veh-camry' : null;

  final String scenario;
  final Duration latency;
  bool _introCompleted;
  SetupStep? _setupDraftStep;
  int _vehicleCount;
  String? _lastVehicleId;

  @override
  Future<AppSession> load() async {
    await Future<void>.delayed(latency);
    if (scenario == 'loadError') throw const SessionLoadException();
    return AppSession(
      hasCompletedIntro: _introCompleted,
      vehicleCount: _vehicleCount,
      setupDraftStep: _setupDraftStep,
      lastVehicleId: _lastVehicleId,
    );
  }

  @override
  Future<void> markIntroCompleted() async => _introCompleted = true;

  @override
  Future<void> saveSetupDraftStep(SetupStep? step) async => _setupDraftStep = step;

  @override
  Future<void> recordVehicleAdded(String vehicleId) async {
    _vehicleCount++;
    _lastVehicleId = vehicleId;
    _setupDraftStep = null;
  }

  @override
  Future<void> saveLastVehicle(String vehicleId) async => _lastVehicleId = vehicleId;

  @override
  Future<void> reset() async {
    _introCompleted = false;
    _setupDraftStep = null;
    _vehicleCount = 0;
    _lastVehicleId = null;
  }

  @override
  Future<void> recordVehicleDeleted(String vehicleId, {String? nextVehicleId}) async {
    if (_vehicleCount > 0) _vehicleCount--;
    _lastVehicleId = nextVehicleId;
  }
}

class SessionLoadException implements Exception {
  const SessionLoadException();

  @override
  String toString() => 'SessionLoadException: local data could not be read';
}
