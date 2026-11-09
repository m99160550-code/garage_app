import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../garage/application/current_vehicle_controller.dart';
import '../../notifications/application/notification_settings.dart';
import '../../service_history/application/history_view.dart';
import '../../service_history/application/service_history_providers.dart';
import '../../session/application/session_providers.dart';
import '../../settings/application/language_settings.dart';
import '../../settings/application/locale_controller.dart';
import '../../settings/application/preferences_providers.dart';
import '../../settings/application/profile_data.dart';
import '../../settings/domain/regional_preferences.dart';
import '../../vehicles/application/garage_providers.dart';
import '../../vehicles/application/vehicle_draft_controller.dart';
import '../domain/erase.dart';
import 'account_providers.dart';

/// S-30: deletes the account or erases this phone, then leaves the app in
/// its first-launch state (S-01 → S-02).
class DataEraser {
  DataEraser(this._ref);

  final Ref _ref;

  /// Owner (FR-USR-06): the server deletes the account first. Without a
  /// connection nothing changes on this phone either.
  Future<EraseOutcome> deleteAccount() async {
    if (!await _ref.read(accountRepositoryProvider).deleteAccount()) return EraseOutcome.offline;
    await eraseDevice();
    return EraseOutcome.done;
  }

  /// Guest (FR-USR-16), and the local part of deleting an account:
  /// vehicles (with their schedules and readings), records, settings and
  /// the session. The consent log stays: it records what was agreed.
  Future<void> eraseDevice() async {
    final garage = _ref.read(garageRepositoryProvider);
    final records = _ref.read(serviceRecordRepositoryProvider);
    for (final record in await records.all()) {
      await records.delete(record.id);
    }
    for (final vehicle in await garage.vehicles()) {
      await garage.deleteVehicle(vehicle.id);
    }
    await _ref.read(preferencesRepositoryProvider).save(const RegionalPreferences());
    await _ref.read(reminderSettingsRepositoryProvider).setEnabled(true);
    await _ref.read(accountRepositoryProvider).signOut();
    await _ref.read(sessionRepositoryProvider).reset();
    _ref.read(localeControllerProvider.notifier).setLanguage(null);
    _refresh();
  }

  /// Every screen reloads from the now empty stores.
  void _refresh() {
    _ref.read(garageRevisionProvider.notifier).bump();
    _ref.read(profileRevisionProvider.notifier).bump();
    _ref
      ..invalidate(appSessionProvider)
      ..invalidate(accountProvider)
      ..invalidate(garageVehiclesProvider)
      ..invalidate(currentVehicleProvider)
      ..invalidate(digitStyleProvider)
      ..invalidate(historyVehicleChoiceProvider)
      ..invalidate(vehicleDraftProvider);
  }
}

final dataEraserProvider = Provider<DataEraser>(DataEraser.new);
