import 'package:flutter/foundation.dart';

/// Steps of the first-vehicle setup flow, in order (UI/UX spec S-03 to S-07).
enum SetupStep { country, brand, model, details, baseline }

/// What the app knows about this device's user at launch.
@immutable
class AppSession {
  const AppSession({
    required this.hasCompletedIntro,
    required this.vehicleCount,
    this.setupDraftStep,
    this.lastVehicleId,
  });

  /// True once the user has finished or skipped the intro (S-02).
  final bool hasCompletedIntro;

  /// Vehicles saved on this device (Guest) or in the account (Owner).
  final int vehicleCount;

  /// The step an unfinished vehicle setup stopped at, if any.
  final SetupStep? setupDraftStep;

  /// The vehicle the dashboard showed last (BR-VEH-05).
  final String? lastVehicleId;

  bool get hasVehicles => vehicleCount > 0;
}
