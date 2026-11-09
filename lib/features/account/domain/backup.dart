import 'package:flutter/foundation.dart';

import '../../vehicles/domain/garage_limits.dart';
import '../../vehicles/domain/vehicle.dart';

/// The Guest-to-Owner upload (UC-05, BR-SYN-06), as the S-29 progress
/// screen shows it.
sealed class UploadState {
  const UploadState();
}

final class Uploading extends UploadState {
  const Uploading(this.progress);

  /// 0–1.
  final double progress;
}

/// No connection: paused, resumes on its own (UC-05 5a). Nothing is lost.
final class WaitingForConnection extends UploadState {
  const WaitingForConnection(this.progress);

  final double progress;
}

/// Gave up after repeated failures (UC-05 5b). The device keeps its copy
/// (BR-USR-09).
final class UploadFailed extends UploadState {
  const UploadFailed();
}

/// Every record confirmed; the data is live in the account (BR-SYN-06).
final class UploadDone extends UploadState {
  const UploadDone();
}

/// The account offer may appear automatically after the first service, then
/// at most once every 30 days, and no more than 3 times (BR-USR-06). The
/// Profile entry is always available.
bool canOfferBackup(List<DateTime> shown, {required DateTime now}) {
  if (shown.length >= 3) return false;
  if (shown.isEmpty) return true;
  final last = shown.reduce((a, b) => a.isAfter(b) ? a : b);
  return now.difference(last) >= const Duration(days: 30);
}

/// How many of this phone's vehicles fit next to the account's (BR-USR-08).
int vehiclesThatFit({required int account}) => (maxGarageVehicles - account).clamp(0, maxGarageVehicles);

/// Pairs (this phone, account) that share a VIN: "These look like the same
/// car" after a merge (BR-USR-08). Both are kept unless the user removes one.
List<(Vehicle, Vehicle)> duplicatesByVin(List<Vehicle> device, List<Vehicle> account) {
  String? key(Vehicle v) => v.vin?.trim().toUpperCase().nullIfEmpty;
  return [
    for (final d in device)
      for (final a in account)
        if (key(d) != null && key(d) == key(a)) (d, a),
  ];
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

/// What the account already holds (S-29 step 3).
@immutable
class AccountGarage {
  const AccountGarage(this.vehicles);

  final List<Vehicle> vehicles;
}
