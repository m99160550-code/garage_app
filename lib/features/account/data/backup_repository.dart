import 'dart:async';

import '../../vehicles/domain/body_type.dart';
import '../../vehicles/domain/fuel_type.dart';
import '../../vehicles/domain/paint_color.dart';
import '../../vehicles/domain/vehicle.dart';
import '../domain/backup.dart';

/// The server side of backing up (sync engine later). Screens only depend
/// on this interface.
abstract interface class BackupRepository {
  /// The garage already in the signed-in account (S-29 step 3).
  Future<AccountGarage> accountGarage();

  /// Uploads this phone's garage, all or nothing (BR-SYN-06).
  Stream<UploadState> upload();

  /// When the account offer was shown automatically (BR-USR-06).
  Future<List<DateTime>> offersShown();
  Future<void> recordOfferShown(DateTime at);
}

/// Development stand-in. The account holds three cars, one with the sample
/// Camry's VIN (to show the duplicate warning). [accountVehicles] changes
/// the count (24 shows the over-limit step); [interruptOnce] pauses the
/// upload for lack of connection; [failing] never finishes.
class MockBackupRepository implements BackupRepository {
  MockBackupRepository({
    this.accountVehicles = 3,
    this.interruptOnce = false,
    this.failing = false,
    this.step = const Duration(milliseconds: 150),
  });

  final int accountVehicles;
  final bool interruptOnce;
  bool failing;
  final Duration step;
  final List<DateTime> _offers = [];
  int uploads = 0;

  static Vehicle _vehicle(int i) => Vehicle(
    id: 'acc-$i',
    brandId: i == 0 ? 'toyota' : 'hyundai',
    modelId: i == 0 ? 'toyota-camry' : 'hyundai-tucson',
    nickname: i == 0 ? 'Camry (account)' : 'Account car ${i + 1}',
    fuelType: FuelType.petrol,
    bodyType: i == 0 ? BodyType.sedan : BodyType.suv,
    paint: PaintColor.fallback,
    // The first one is the same car as the sample Camry.
    vin: i == 0 ? '4T1C11AK5NU123456' : null,
    odometerKm: 40000 + i * 1000,
  );

  @override
  Future<AccountGarage> accountGarage() async => AccountGarage([for (var i = 0; i < accountVehicles; i++) _vehicle(i)]);

  @override
  Stream<UploadState> upload() async* {
    uploads++;
    const steps = 10;
    for (var i = 0; i <= steps; i++) {
      final progress = i / steps;
      if (failing && i == 6) {
        yield const UploadFailed();
        return;
      }
      if (interruptOnce && uploads == 1 && i == 4) {
        for (var w = 0; w < 3; w++) {
          yield WaitingForConnection(progress);
          await Future<void>.delayed(step);
        }
      }
      yield Uploading(progress);
      await Future<void>.delayed(step);
    }
    yield const UploadDone();
  }

  @override
  Future<List<DateTime>> offersShown() async => List.unmodifiable(_offers);

  @override
  Future<void> recordOfferShown(DateTime at) async => _offers.add(at);
}
