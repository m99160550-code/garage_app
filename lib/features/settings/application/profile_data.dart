import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/application/account_providers.dart';
import '../../account/domain/account.dart';
import '../../garage/application/current_vehicle_controller.dart';
import '../../notifications/application/notification_settings.dart';
import '../../notifications/application/reminder_primer_service.dart';
import '../../notifications/domain/notification_permission.dart';
import '../../reference/application/reference_providers.dart';
import '../../reference/domain/country.dart';
import '../domain/regional_preferences.dart';
import 'preferences_providers.dart';

/// Everything S-24 shows.
@immutable
class ProfileData {
  const ProfileData({
    required this.account,
    required this.preferences,
    required this.country,
    required this.vehicleCount,
    required this.permission,
    this.remindersEnabled = true,
  });

  final AccountState account;
  final RegionalPreferences preferences;

  /// `null` when not set (BR-SET-07).
  final Country? country;
  final int vehicleCount;
  final NotificationPermission permission;

  /// The in-app switch (S-27).
  final bool remindersEnabled;

  /// Reminders arrive only with the switch and the permission both on.
  bool get remindersOn => remindersEnabled && permission == NotificationPermission.granted;
}

/// Bumped after a preference changes on S-24 (the analytics switch).
class ProfileRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final profileRevisionProvider = NotifierProvider<ProfileRevision, int>(ProfileRevision.new);

final profileDataProvider = FutureProvider.autoDispose<ProfileData>((ref) async {
  // Watch everything before the first await (Riverpod 3).
  ref.watch(profileRevisionProvider);
  final accountFuture = ref.watch(accountProvider.future);
  final vehiclesFuture = ref.watch(garageVehiclesProvider.future);
  final preferencesRepository = ref.watch(preferencesRepositoryProvider);
  final reference = ref.watch(referenceRepositoryProvider);
  final permission = ref.watch(notificationPermissionRepositoryProvider);
  final reminderSettings = ref.watch(reminderSettingsRepositoryProvider);

  final preferences = await preferencesRepository.load();
  final code = preferences.countryCode;
  return ProfileData(
    account: await accountFuture,
    preferences: preferences,
    country: code == null ? null : (await reference.countries()).where((c) => c.code == code).firstOrNull,
    vehicleCount: (await vehiclesFuture).length,
    permission: await permission.status(),
    remindersEnabled: await reminderSettings.enabled(),
  );
});
