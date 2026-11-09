import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/config/app_info.dart';
import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/navigation/floating_nav_bar.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../../account/application/account_providers.dart';
import '../../account/domain/account.dart';
import '../../account/presentation/backup_offer_sheet.dart';
import '../../garage/application/current_vehicle_controller.dart';
import '../../help/presentation/contact_screen.dart';
import '../../vehicles/presentation/vehicles_screen.dart';
import '../../help/presentation/help_screen.dart';
import '../../notifications/application/reminder_primer_service.dart';
import '../../notifications/domain/notification_permission.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../notifications/presentation/reminders_primer_sheet.dart';
import '../../privacy/application/consent_providers.dart';
import '../../privacy/domain/consent.dart';
import '../application/preferences_providers.dart';
import '../application/profile_data.dart';
import '../domain/distance_unit.dart';
import 'currency_names.dart';
import 'language/language_screen.dart';
import 'region/country_setting_screen.dart';
import 'region/currency_screen.dart';
import 'region/distance_unit_screen.dart';
import 'widgets/settings_list.dart';

/// A setting that opens its own screen: phones push [route]; iPad
/// landscape shows it in the detail pane (screens still to come show
/// their placeholder).
enum ProfileDestination {
  account(AppRoutes.profileAccount, 'S-24', 'Account details'),
  vehicles(AppRoutes.profileVehicles, 'S-32', 'Vehicles'),
  country(AppRoutes.profileCountry, 'S-25', 'Country'),
  unit(AppRoutes.profileUnit, 'S-25', 'Distance unit'),
  currency(AppRoutes.profileCurrency, 'S-25', 'Currency'),
  language(AppRoutes.profileLanguage, 'S-26', 'Language and digits'),
  notifications(AppRoutes.profileNotifications, 'S-27', 'Notifications'),
  faq(AppRoutes.profileFaq, 'S-31', 'FAQ'),
  contact(AppRoutes.profileContact, 'S-31', 'Contact support');

  const ProfileDestination(this.route, this.screenId, this.title);

  final String route;
  final String screenId;
  final String title;
}

/// S-24 Profile & Settings (UI/UX spec S-24, FR-SET-01 to FR-SET-16):
/// the account card, preferences, notifications, privacy, help and the
/// account actions. iPad landscape: the list (40%) and the selected
/// setting (60%).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  /// The list never gets wider than this on iPad portrait.
  static const maxListWidth = 720.0;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  ProfileDestination _selected = ProfileDestination.country;

  bool get _masterDetail => WindowClass.of(context) == WindowClass.expanded;

  void _open(ProfileDestination destination) {
    if (_masterDetail) {
      setState(() => _selected = destination);
    } else {
      context.push(destination.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final data = ref.watch(profileDataProvider).value;
    final compact = WindowClass.of(context).isCompact;

    final list = CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(l10n.profileTitle),
          backgroundColor: colors.bgBase,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
        ),
        if (data == null)
          const SliverFillRemaining(child: DelayedSkeleton())
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              0,
              AppSpacing.screenMargin,
              compact ? FloatingNavBar.contentClearance + MediaQuery.paddingOf(context).bottom : AppSpacing.xl,
            ),
            sliver: SliverList.list(children: _sections(data)),
          ),
      ],
    );

    if (!_masterDetail) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ProfileScreen.maxListWidth),
            child: list,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: colors.bgBase,
      body: Row(
        children: [
          Expanded(flex: 4, child: list),
          VerticalDivider(width: 1, color: colors.borderSubtle),
          Expanded(
            flex: 6,
            child: KeyedSubtree(key: ValueKey(_selected), child: _pane(_selected)),
          ),
        ],
      ),
    );
  }

  /// The iPad landscape detail pane: the built settings screens, or the
  /// placeholder of those still to come.
  Widget _pane(ProfileDestination destination) => switch (destination) {
    ProfileDestination.country => const CountrySettingScreen(embedded: true),
    ProfileDestination.unit => const DistanceUnitScreen(embedded: true),
    ProfileDestination.currency => const CurrencyScreen(embedded: true),
    ProfileDestination.language => const LanguageScreen(embedded: true),
    ProfileDestination.notifications => const NotificationsScreen(embedded: true),
    ProfileDestination.vehicles => const VehiclesScreen(embedded: true),
    ProfileDestination.faq => const HelpScreen(embedded: true),
    ProfileDestination.contact => const ContactScreen(embedded: true),
    _ => PlaceholderScreen(screenId: destination.screenId, title: destination.title),
  };

  List<Widget> _sections(ProfileData data) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final preferences = data.preferences;
    final owner = data.account is OwnerAccount;
    bool isSelected(ProfileDestination d) => _masterDetail && _selected == d;
    SettingsRow row(ProfileDestination d, String title, {String? value, IconData? icon}) =>
        SettingsRow(title: title, value: value, icon: icon, selected: isSelected(d), onTap: () => _open(d));

    return [
      // 1. Account card.
      _AccountCard(account: data.account, onOpenDetails: () => _open(ProfileDestination.account)),
      // 2. "Enable reminders" when permission is off.
      if (!data.remindersOn) ...[
        const SizedBox(height: AppSpacing.md),
        AppBanner(
          message: l10n.profileEnableRemindersBody,
          action: AppButton.text(label: l10n.profileEnableReminders, onPressed: () => _enableReminders(data)),
        ),
      ],
      const SizedBox(height: AppSpacing.xl),
      // 3. Garage.
      SettingsGroup(
        title: l10n.profileGarage,
        children: [
          row(
            ProfileDestination.vehicles,
            l10n.profileVehicles,
            value: '${data.vehicleCount}',
            icon: Icons.directions_car_outlined,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      // 4. Preferences.
      SettingsGroup(
        title: l10n.profilePreferences,
        children: [
          row(
            ProfileDestination.country,
            l10n.profileCountry,
            value: data.country?.name(language) ?? l10n.profileNotSet,
            icon: Icons.public,
          ),
          row(
            ProfileDestination.unit,
            l10n.profileDistanceUnit,
            value: preferences.distanceUnit == DistanceUnit.km ? l10n.profileKilometres : l10n.profileMiles,
            icon: Icons.straighten,
          ),
          row(
            ProfileDestination.currency,
            l10n.profileCurrency,
            value: currencyLabel(preferences.currency, language),
            icon: Icons.payments_outlined,
          ),
          // Language names are always shown in their own language.
          row(
            ProfileDestination.language,
            l10n.profileLanguage,
            value: language == 'ar' ? 'العربية' : 'English',
            icon: Icons.translate,
          ),
          row(
            ProfileDestination.language,
            l10n.profileDigits,
            value: preferences.digitStyle == DigitStyle.western ? l10n.profileDigitsWestern : l10n.profileDigitsArabic,
            icon: Icons.pin_outlined,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      // 5. Notifications.
      SettingsGroup(
        title: l10n.profileNotifications,
        children: [
          row(
            ProfileDestination.notifications,
            l10n.profileReminders,
            value: data.remindersOn ? l10n.profileOn : l10n.profileOff,
            icon: Icons.notifications_outlined,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      // 6. Privacy.
      SettingsGroup(
        title: l10n.profilePrivacy,
        children: [
          SettingsSwitchRow(
            title: l10n.profileAnalytics,
            subline: l10n.profileAnalyticsSub,
            icon: Icons.insights_outlined,
            value: preferences.analyticsEnabled,
            onChanged: (value) => _setAnalytics(data, value),
          ),
          SettingsRow(
            title: l10n.profilePrivacyPolicy,
            icon: Icons.privacy_tip_outlined,
            external: true,
            onTap: () => context.push(AppRoutes.privacyPolicy),
          ),
          SettingsRow(
            title: l10n.profileTerms,
            icon: Icons.description_outlined,
            external: true,
            onTap: () => context.push(AppRoutes.terms),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      // 7. Help, with the support promise (NFR-SUP-03).
      SettingsGroup(
        title: l10n.profileHelp,
        footer: l10n.profileSupportPromise,
        children: [
          row(ProfileDestination.faq, l10n.profileFaq, icon: Icons.help_outline),
          row(ProfileDestination.contact, l10n.profileContact, icon: Icons.mail_outline),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      // 8. Account actions.
      SettingsGroup(
        title: l10n.profileAccountActions,
        children: [
          if (owner) ...[
            SettingsRow(
              title: l10n.profileSignOut,
              icon: Icons.logout,
              onTap: () => _signOut(data.account as OwnerAccount),
            ),
            SettingsRow(
              title: l10n.profileDeleteAccount,
              icon: Icons.delete_outline,
              destructive: true,
              onTap: () => context.push(AppRoutes.accountDelete),
            ),
          ] else
            SettingsRow(
              title: l10n.profileEraseData,
              icon: Icons.delete_outline,
              destructive: true,
              onTap: () => context.push(AppRoutes.accountDelete),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.xl),
      // 9. Version.
      Center(
        child: Text(
          l10n.profileVersion(AppInfo.name, AppInfo.version, AppInfo.build),
          style: context.text.caption.copyWith(color: context.colors.textTertiary),
        ),
      ),
    ];
  }

  /// The analytics opt-out (FR-SET-09): saved, and recorded as a consent
  /// decision (BR-PRV-01).
  Future<void> _setAnalytics(ProfileData data, bool enabled) async {
    await ref.read(preferencesRepositoryProvider).save(data.preferences.withAnalytics(enabled: enabled));
    await ref
        .read(consentRepositoryProvider)
        .record(
          ConsentRecord(
            purpose: ConsentPurpose.analytics,
            granted: enabled,
            regionCode: data.preferences.countryCode,
            policyVersion: currentPolicyVersion,
            recordedAt: ref.read(clockProvider)(),
          ),
        );
    ref.read(profileRevisionProvider.notifier).bump();
  }

  /// "Enable reminders": the S-08 primer (it opens the system Settings app
  /// when permission was declined before).
  Future<void> _enableReminders(ProfileData data) async {
    final language = Localizations.localeOf(context).languageCode;
    final vehicleId = await ref.read(currentVehicleProvider.future);
    final service = ref.read(reminderPrimerServiceProvider);
    final offer = vehicleId == null ? null : await service.offerFor(vehicleId, language);
    if (!mounted) return;
    if (offer == null) {
      if (data.permission == NotificationPermission.denied) {
        await ref.read(notificationPermissionRepositoryProvider).openSystemSettings();
      } else {
        await ref.read(notificationPermissionRepositoryProvider).request();
      }
    } else {
      await showRemindersPrimer(context, ref, offer);
    }
    ref.read(profileRevisionProvider.notifier).bump();
  }

  /// Sign out (BR-USR-04): with unsynced changes the user must choose
  /// "Sync now" or "Discard and sign out".
  Future<void> _signOut(OwnerAccount account) async {
    final l10n = AppLocalizations.of(context);
    final pending = account.sync.pendingChanges;
    final choice = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pending > 0 ? l10n.profileUnsyncedTitle : l10n.profileSignOutTitle),
        content: Text(pending > 0 ? l10n.profileUnsyncedBody(pending) : l10n.profileSignOutBody),
        actions: [
          AppButton.text(label: l10n.actionCancel, onPressed: () => Navigator.pop(context)),
          if (pending > 0) ...[
            AppButton.destructiveText(
              label: l10n.profileDiscardSignOut,
              onPressed: () => Navigator.pop(context, false),
            ),
            AppButton.text(label: l10n.profileSyncNow, onPressed: () => Navigator.pop(context, true)),
          ] else
            AppButton.destructiveText(label: l10n.profileSignOut, onPressed: () => Navigator.pop(context, false)),
        ],
      ),
    );
    if (choice == null) return;
    await ref.read(accountActionsProvider).signOut(syncFirst: choice);
    if (mounted) showAppToast(context, l10n.profileSignedOut);
  }
}

/// The account card (spec S-24 item 1): the Guest warning with "Back up
/// your garage", or the Owner's name, email and sync state.
class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account, required this.onOpenDetails});

  final AccountState account;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final decoration = BoxDecoration(
      color: colors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadii.card),
      border: Border.all(color: colors.borderSubtle),
    );
    return switch (account) {
      GuestAccount() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: decoration,
        child: const _GuestCard(),
      ),
      final OwnerAccount owner => Material(
        color: colors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: colors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: _OwnerCard(owner: owner, onOpenDetails: onOpenDetails),
      ),
    };
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cloud_off_outlined, color: colors.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(header: true, child: Text(l10n.profileGuestTitle, style: text.titleM)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(l10n.profileGuestBody, style: text.bodyS.copyWith(color: colors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(label: l10n.profileBackUp, onPressed: () => showBackupOffer(context)),
        const SizedBox(height: AppSpacing.xxs),
        AppButton.text(label: l10n.profileSignIn, onPressed: () => context.push(AppRoutes.signIn)),
      ],
    );
  }
}

class _OwnerCard extends ConsumerWidget {
  const _OwnerCard({required this.owner, required this.onOpenDetails});

  final OwnerAccount owner;
  final VoidCallback onOpenDetails;

  String _syncText(AppLocalizations l10n, DateTime now, String language) => switch (owner.sync) {
    Synced(:final at) when now.difference(at).inMinutes < 60 => l10n.profileSyncedMinutes(
      now.difference(at).inMinutes.clamp(0, 59),
    ),
    Synced(:final at) => l10n.profileSyncedAt(AppFormatters(languageCode: language).dateTime(at)),
    SyncPending(:final count) => l10n.profileWaitingSync(count),
    SyncInProgress() => l10n.syncSyncing,
    SyncOffline() => l10n.profileOffline,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final sync = _syncText(l10n, ref.watch(clockProvider)(), language);
    final (syncIcon, syncColor) = switch (owner.sync) {
      Synced() => (Icons.cloud_done_outlined, colors.success),
      SyncPending() => (Icons.sync, colors.warning),
      SyncInProgress() => (Icons.sync, colors.accentPrimary),
      SyncOffline() => (Icons.cloud_off_outlined, colors.textTertiary),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: l10n.profileAccountSemantic(owner.displayName, owner.email, sync),
          excludeSemantics: true,
          child: InkWell(
            onTap: onOpenDetails,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colors.surfaceRaised,
                    child: Text(owner.initials, style: text.titleM.copyWith(color: colors.textPrimary)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(owner.displayName, style: text.titleM),
                        // Without a name the email is already the title.
                        if (owner.name.trim().isNotEmpty)
                          Text(owner.email, style: text.bodyS.copyWith(color: colors.textSecondary)),
                        const SizedBox(height: AppSpacing.xxs),
                        Row(
                          children: [
                            Icon(syncIcon, size: 16, color: syncColor),
                            const SizedBox(width: AppSpacing.xxs),
                            Flexible(
                              child: Text(sync, style: text.caption.copyWith(color: colors.textSecondary)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.textTertiary),
                ],
              ),
            ),
          ),
        ),
        // Email not verified: the backup isn't finished yet.
        if (!owner.emailVerified)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: AppBanner(
              tone: BannerTone.warning,
              message: l10n.profileVerifyEmail,
              action: AppButton.text(
                label: l10n.profileResendEmail,
                onPressed: () async {
                  await ref.read(accountActionsProvider).resendVerificationEmail();
                  if (context.mounted) showAppToast(context, l10n.profileVerificationSent);
                },
              ),
            ),
          ),
      ],
    );
  }
}
