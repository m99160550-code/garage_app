import '../../features/session/domain/app_session.dart';

/// Route paths (UI/UX spec 2.1 screen map). Screen IDs in comments.
abstract final class AppRoutes {
  static const launch = '/'; // S-01
  static const intro = '/intro'; // S-02
  static const setupCountry = '/setup/country'; // S-03
  static const setupBrand = '/setup/brand'; // S-04
  static const setupModel = '/setup/model'; // S-05
  static const setupDetails = '/setup/details'; // S-06
  static const setupBaseline = '/setup/baseline'; // S-07
  static const garage = '/garage'; // S-09
  static const garageHealth = '/garage/health'; // S-11
  static const garageMileageHistory = '/garage/mileage'; // S-13
  static const garageSchedule = '/garage/schedule'; // S-14, ?filter=overdue|unknown, ?item=code
  static const garageCustomItem = '/schedule-item/new'; // S-16 (full-screen form)
  static const garageSpend = '/garage/spend'; // S-19
  static String garageRecord(String id) => '/garage/record/$id'; // S-21 from S-19 and S-15
  static const settingsCurrency = '/settings/currency'; // S-25 currency, from S-19
  static const garageEditVehicle = '/vehicle/edit'; // S-32, the dashboard's vehicle
  static String editVehicle(String id) => '/vehicle/$id/edit'; // S-32 from the list
  static const garageManageVehicles = '/garage/vehicles'; // S-32 list
  static const history = '/history'; // S-20
  static String historyRecord(String id) => '/history/record/$id'; // S-21 from S-20
  static String historyItem(String code) => '/history/item/$code'; // S-15 from S-21 in History
  static const profile = '/profile'; // S-24
  static const profileAccount = '/profile/account'; // Account details (FR-SET-01)
  static const profileVehicles = '/profile/vehicles'; // S-32
  static const profileCountry = '/profile/country'; // S-25
  static const profileUnit = '/profile/unit'; // S-25
  static const profileCurrency = '/profile/currency'; // S-25
  static const profileLanguage = '/profile/language'; // S-26
  static const profileNotifications = '/profile/notifications'; // S-27
  static const profileFaq = '/profile/help'; // S-31
  static const profileContact = '/profile/help/contact'; // S-31 contact
  static String helpTopic(String category) => '/profile/help/topic/$category'; // S-31 category
  static String helpArticle(String id) => '/profile/help/article/$id'; // S-31 article
  static const accountBackup = '/account/backup'; // S-29
  static String accountBackupStep(String step) => '$accountBackup?step=$step'; // S-29 upload | merge
  static const signInFromBackup = '/account/sign-in?from=backup'; // S-28, "Back up and sync" title
  static const accountDelete = '/account/delete'; // S-30
  static const terms = '/help/terms'; // S-31 (legal)

  /// S-22 Log service (a full-screen form), optionally with items
  /// preselected (S-15 one item, S-18 the next service's items).
  /// With [recordId], S-22 edits that record (S-21 "Edit").
  static String logService({String? itemCode, List<String> itemCodes = const [], String? recordId}) {
    final codes = [?itemCode, ...itemCodes];
    final query = {if (codes.isNotEmpty) 'items': codes.join(','), 'record': ?recordId};
    return query.isEmpty ? '/log-service' : Uri(path: '/log-service', queryParameters: query).toString();
  }

  /// S-16 Edit interval for an item.
  static String garageItemInterval(String code) => '/schedule-item/$code/interval';

  /// S-15 Schedule item detail.
  /// With [setLastDone], the "Set last done" form opens straight away.
  static String garageItem(String code, {bool setLastDone = false}) =>
      '/garage/item/$code${setLastDone ? '?setLastDone=1' : ''}';

  /// S-14 filtered to Overdue or Unknown.
  static String garageScheduleFiltered(String filter) => '$garageSchedule?filter=$filter';
  static const signIn = '/account/sign-in'; // S-28
  static const privacyPolicy = '/help/privacy'; // S-31 (legal)

  static String forSetupStep(SetupStep step) => switch (step) {
    SetupStep.country => setupCountry,
    SetupStep.brand => setupBrand,
    SetupStep.model => setupModel,
    SetupStep.details => setupDetails,
    SetupStep.baseline => setupBaseline,
  };
}

/// Passed as `extra` when the launch screen hands over, so the first real
/// screen fades in (spec S-01) instead of sliding like a normal push.
class LaunchHandover {
  const LaunchHandover();
}

/// Passed as `extra` when setup finishes and the dashboard opens with a new
/// vehicle (spec S-07 "After save"). The dashboard may then offer the
/// reminders primer (S-08).
class DashboardArrival {
  const DashboardArrival(this.vehicleId);

  final String vehicleId;
}
