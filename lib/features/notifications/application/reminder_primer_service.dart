import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/mock_config.dart';
import '../../vehicles/application/garage_providers.dart';
import '../../vehicles/application/vehicle_names.dart';
import '../data/notification_permission_repository.dart';
import '../domain/notification_permission.dart';

/// Swap for the plugin-backed repository later.
final notificationPermissionRepositoryProvider = Provider<NotificationPermissionRepository>(
  (ref) => MockNotificationPermissionRepository.fromConfig(
    status: MockConfig.notificationStatus,
    answer: MockConfig.notificationAnswer,
  ),
);

/// What the primer shows in its example notification.
@immutable
class ReminderPrimerOffer {
  const ReminderPrimerOffer({required this.vehicleName, required this.itemName, required this.permission});

  /// "Family Camry", or "Toyota Camry" without a nickname.
  final String vehicleName;

  /// The first item with a known due point, for example "Engine oil".
  /// `null` when nothing is known yet: the example then uses "Oil change".
  final String? itemName;

  /// Decides the button: "Turn on reminders" or "Open Settings".
  final NotificationPermission permission;
}

/// Decides when the S-08 primer appears and handles its buttons
/// (FR-USR-08, FR-NOT-06, UI/UX spec S-08).
class ReminderPrimerService {
  ReminderPrimerService(this._ref);

  final Ref _ref;

  NotificationPermissionRepository get _permission => _ref.read(notificationPermissionRepositoryProvider);

  /// The primer to show after the first vehicle is saved, or `null`.
  ///
  /// Offered once, only when permission hasn't been asked yet and the
  /// vehicle has something to remind about (an item that isn't Unknown).
  Future<ReminderPrimerOffer?> offerAfterSetup(String vehicleId, String languageCode) async {
    if (await _permission.status() != NotificationPermission.notDetermined) return null;
    if (await _permission.hasShownPrimer()) return null;
    return offerFor(vehicleId, languageCode, requireReminder: true);
  }

  /// The primer for [vehicleId] whatever the permission state, for the
  /// Profile "Enable reminders" banner. `null` if the vehicle is missing,
  /// or with [requireReminder], if nothing can be reminded about yet.
  Future<ReminderPrimerOffer?> offerFor(String vehicleId, String languageCode, {bool requireReminder = false}) async {
    final garage = _ref.read(garageRepositoryProvider);
    final vehicle = (await garage.vehicles()).where((v) => v.id == vehicleId).firstOrNull;
    if (vehicle == null) return null;
    final schedule = await garage.schedule(vehicleId);
    final firstKnown = schedule.where((item) => !item.isUnknown).firstOrNull;
    if (requireReminder && firstKnown == null) return null;

    final name = await _ref.read(vehicleDisplayNameProvider((vehicleId: vehicleId, languageCode: languageCode)).future);
    return ReminderPrimerOffer(
      vehicleName: name,
      itemName: firstKnown?.name(languageCode),
      permission: await _permission.status(),
    );
  }

  /// "Turn on reminders": shows the system prompt, or opens Settings if
  /// the user declined before (the prompt can't be shown again).
  Future<PrimerResult> turnOn() async {
    await _permission.markPrimerShown();
    if (await _permission.status() == NotificationPermission.denied) {
      await _permission.openSystemSettings();
      return PrimerResult.openedSettings;
    }
    final answer = await _permission.request();
    return answer == NotificationPermission.granted ? PrimerResult.granted : PrimerResult.denied;
  }

  /// "Not now", a swipe down or a tap on the scrim. The app keeps working
  /// and Profile offers "Enable reminders" later (FR-NOT-06).
  Future<void> dismiss() => _permission.markPrimerShown();
}

final reminderPrimerServiceProvider = Provider<ReminderPrimerService>(ReminderPrimerService.new);
