import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../garage/application/current_vehicle_controller.dart';
import '../../privacy/application/consent_providers.dart';
import '../../reference/application/reference_providers.dart';
import '../../service_history/application/service_history_providers.dart';
import '../../vehicles/application/garage_providers.dart';
import '../../vehicles/domain/vehicle.dart';
import '../data/backup_repository.dart';
import '../domain/account.dart';
import '../domain/backup.dart';
import 'account_providers.dart';

/// Swap for the sync-engine repository later.
final backupRepositoryProvider = Provider<BackupRepository>((ref) => MockBackupRepository());

/// What S-29 shows: this phone's garage and the account's.
@immutable
class BackupData {
  const BackupData({required this.device, required this.account, required this.records, this.names = const {}});

  final List<Vehicle> device;
  final List<Vehicle> account;

  /// Service records on this phone ("…and 22 records").
  final int records;

  /// Vehicle names in the UI language, by id.
  final Map<String, String> names;

  String nameOf(Vehicle v) => names[v.id] ?? v.nickname ?? '';

  /// The merge needs the user to pick (BR-USR-08).
  bool get overLimit => device.length > vehiclesThatFit(account: account.length);
}

/// S-29 data, vehicle names in [languageCode].
final backupDataProvider = FutureProvider.autoDispose.family<BackupData, String>((ref, languageCode) async {
  // Watch everything before the first await (Riverpod 3).
  ref.watch(garageRevisionProvider);
  final garage = ref.watch(garageRepositoryProvider);
  final backup = ref.watch(backupRepositoryProvider);
  final records = ref.watch(serviceRecordRepositoryProvider);
  final reference = ref.watch(referenceRepositoryProvider);
  final brandsFuture = ref.watch(brandsProvider.future);

  final device = await garage.vehicles();
  final account = (await backup.accountGarage()).vehicles;
  final brands = await brandsFuture;
  final names = <String, String>{};
  for (final v in [...device, ...account]) {
    final brand = brands.where((b) => b.id == v.brandId).firstOrNull;
    final model = brand == null || v.modelId == null
        ? null
        : (await reference.models(brand.id)).where((m) => m.id == v.modelId).firstOrNull;
    final generic =
        '${brand?.name(languageCode) ?? v.brandOtherName ?? ''} ${model?.name(languageCode) ?? v.modelOtherName ?? ''}'
            .trim();
    names[v.id] = v.nickname ?? generic;
  }
  return BackupData(device: device, account: account, records: (await records.all()).length, names: names);
});

/// S-29 actions.
class BackupActions {
  BackupActions(this._ref);

  final Ref _ref;

  /// Whether to show the offer automatically now; records it when so
  /// (BR-USR-06). Only Guests are offered a backup.
  Future<bool> takeAutomaticOffer() async {
    final backup = _ref.read(backupRepositoryProvider);
    final now = _ref.read(clockProvider)();
    if (await _ref.read(accountRepositoryProvider).load() is! GuestAccount) return false;
    if (!canOfferBackup(await backup.offersShown(), now: now)) return false;
    await backup.recordOfferShown(now);
    return true;
  }

  Stream<UploadState> upload() => _ref.read(backupRepositoryProvider).upload();

  /// Merge (FR-USR-15): the account's vehicles join this phone's. Vehicles
  /// not brought (over the limit) are removed from this phone.
  Future<void> merge(BackupData data, {required Set<String> bring}) async {
    final garage = _ref.read(garageRepositoryProvider);
    for (final v in data.device.where((v) => !bring.contains(v.id))) {
      await garage.deleteVehicle(v.id);
    }
    for (final v in data.account) {
      await garage.addVehicle(v, const []);
    }
    _refresh();
  }

  /// Discard (FR-USR-15): this phone's data goes; the account's loads.
  Future<void> discard(BackupData data) async {
    final garage = _ref.read(garageRepositoryProvider);
    for (final v in data.device) {
      await garage.deleteVehicle(v.id);
    }
    for (final v in data.account) {
      await garage.addVehicle(v, const []);
    }
    _refresh();
  }

  /// "Remove this copy" for a duplicate (BR-USR-08).
  Future<void> removeVehicle(String vehicleId) async {
    await _ref.read(garageRepositoryProvider).deleteVehicle(vehicleId);
    _refresh();
  }

  void _refresh() {
    _ref.read(garageRevisionProvider.notifier).bump();
    _ref.invalidate(garageVehiclesProvider);
    _ref.invalidate(currentVehicleProvider);
  }
}

final backupActionsProvider = Provider<BackupActions>(BackupActions.new);
