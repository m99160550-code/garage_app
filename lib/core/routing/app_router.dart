import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_info.dart';
import '../config/mock_config.dart';
import '../l10n/generated/app_localizations.dart';
import '../../features/account/presentation/backup_screen.dart';
import '../../features/notifications/presentation/notification_gallery_screen.dart';
import '../../features/vehicles/presentation/edit_vehicle_screen.dart';
import '../../features/vehicles/presentation/vehicles_screen.dart';
import '../../features/help/domain/help_article.dart';
import '../../features/help/presentation/contact_screen.dart';
import '../../features/help/presentation/help_article_screen.dart';
import '../../features/help/presentation/help_screen.dart';
import '../../features/help/presentation/help_topic_screen.dart';
import '../../features/help/presentation/legal_page_screen.dart';
import '../../features/account/presentation/erase_screen.dart';
import '../../features/account/presentation/sign_in_screen.dart';
import '../../features/expenses/presentation/spend_screen.dart';
import '../../features/settings/presentation/region/country_setting_screen.dart';
import '../../features/settings/presentation/region/currency_screen.dart';
import '../../features/settings/presentation/region/distance_unit_screen.dart';
import '../../features/settings/presentation/language/language_screen.dart';
import '../../features/settings/presentation/profile_screen.dart';
import '../../features/service_history/presentation/log_service_screen.dart';
import '../../features/service_history/presentation/service_record_screen.dart';
import '../../features/service_history/presentation/history_screen.dart';
import '../../features/garage/presentation/dashboard_screen.dart';
import '../../features/garage/presentation/health_detail_screen.dart';
import '../../features/launch/presentation/launch_screen.dart';
import '../../features/maintenance/presentation/item_interval_screen.dart';
import '../../features/maintenance/presentation/schedule_item_detail.dart';
import '../../features/maintenance/presentation/schedule_screen.dart';
import '../../features/mileage/presentation/mileage_history_screen.dart';
import '../../features/notifications/presentation/reminder_primer_trigger.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/baseline/service_baseline_screen.dart';
import '../../features/onboarding/presentation/brand/brand_selection_screen.dart';
import '../../features/onboarding/presentation/country/country_screen.dart';
import '../../features/onboarding/presentation/details/vehicle_details_screen.dart';
import '../../features/onboarding/presentation/intro/intro_screen.dart';
import '../../features/onboarding/presentation/model/model_selection_screen.dart';
import '../layout/window_class.dart';
import '../theme/app_tokens.dart';
import '../widgets/placeholder_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: MockConfig.notificationGallery ? '/dev/notifications' : AppRoutes.launch,
    routes: [
      GoRoute(path: AppRoutes.launch, pageBuilder: (context, state) => _fade(state, const LaunchScreen())),
      GoRoute(path: AppRoutes.intro, pageBuilder: (context, state) => _page(state, const IntroScreen())),
      GoRoute(path: AppRoutes.setupCountry, pageBuilder: (context, state) => _page(state, const CountryScreen())),
      GoRoute(
        path: AppRoutes.setupBrand,
        // `?add=1` when opened from "Add vehicle" (spec S-04 item 2).
        pageBuilder: (context, state) => _page(
          state,
          BrandSelectionScreen(
            addingVehicle: state.uri.queryParameters['add'] == '1',
            editing: state.uri.queryParameters['edit'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.setupModel,
        pageBuilder: (context, state) => _page(
          state,
          ModelSelectionScreen(
            addingVehicle: state.uri.queryParameters['add'] == '1',
            editing: state.uri.queryParameters['edit'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.setupDetails,
        pageBuilder: (context, state) =>
            _page(state, VehicleDetailsScreen(addingVehicle: state.uri.queryParameters['add'] == '1')),
      ),
      GoRoute(
        path: AppRoutes.setupBaseline,
        pageBuilder: (context, state) =>
            _page(state, ServiceBaselineScreen(addingVehicle: state.uri.queryParameters['add'] == '1')),
      ),
      // The main tabs (UI/UX spec 2.2), each with its own stack.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.garage,
                // S-08 is offered from here after setup (DashboardArrival).
                pageBuilder: (context, state) {
                  final arrival = state.extra is DashboardArrival ? state.extra! as DashboardArrival : null;
                  return _page(
                    state,
                    ReminderPrimerTrigger(
                      arrival: arrival,
                      settleTime: DashboardScreen.arrivalDuration,
                      // A reminder's deep link (spec S-35, FR-NOT-04).
                      child: DashboardScreen(arrival: arrival, deepLink: state.uri),
                    ),
                  );
                },
                routes: [
                  // Placeholders until their step is delivered.
                  GoRoute(
                    path: 'health',
                    // Tablets: a 420 pt side sheet over the dashboard.
                    pageBuilder: (context, state) => WindowClass.of(context).isCompact
                        ? _page(state, const HealthDetailScreen())
                        : _sideSheet(state, const HealthDetailScreen(sideSheet: true)),
                  ),
                  GoRoute(path: 'mileage', pageBuilder: (context, state) => _page(state, const MileageHistoryScreen())),
                  GoRoute(
                    path: 'schedule',
                    pageBuilder: (context, state) => _page(
                      state,
                      ScheduleScreen(
                        initialFilter: ScheduleFilter.fromQuery(state.uri.queryParameters['filter']),
                        highlightCode: state.uri.queryParameters['item'],
                      ),
                    ),
                  ),
                  // S-15. iPad portrait: a side sheet (spec S-14 "Responsive").
                  GoRoute(
                    path: 'item/:code',
                    pageBuilder: (context, state) {
                      final code = state.pathParameters['code']!;
                      final setLastDone = state.uri.queryParameters['setLastDone'] == '1';
                      return WindowClass.of(context).isCompact
                          ? _page(state, ScheduleItemScreen(code: code, openSetLastDone: setLastDone))
                          : _sideSheet(
                              state,
                              ScheduleItemScreen(code: code, openSetLastDone: setLastDone, sideSheet: true),
                            );
                    },
                  ),
                  GoRoute(path: 'spend', pageBuilder: (context, state) => _page(state, const SpendScreen())),
                  // S-21 from S-19 and S-15. iPad: a side sheet.
                  GoRoute(path: 'record/:id', pageBuilder: _recordPage),
                  GoRoute(path: 'vehicles', pageBuilder: (context, state) => _page(state, const VehiclesScreen())),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                pageBuilder: (context, state) => _page(state, const HistoryScreen()),
                routes: [
                  // S-21 (placeholder until its step). iPad portrait: a side
                  // sheet; iPad landscape shows records in the detail pane.
                  GoRoute(path: 'record/:id', pageBuilder: _recordPage),
                  // S-15 from a record's item chips, staying in History.
                  GoRoute(
                    path: 'item/:code',
                    pageBuilder: (context, state) {
                      final code = state.pathParameters['code']!;
                      return WindowClass.of(context).isCompact
                          ? _page(state, ScheduleItemScreen(code: code))
                          : _sideSheet(state, ScheduleItemScreen(code: code, sideSheet: true));
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) => _page(state, const ProfileScreen()),
                // Placeholders until their step is delivered (S-25 to S-32).
                routes: [
                  _placeholder('account', 'S-24', 'Account details'),
                  GoRoute(path: 'vehicles', pageBuilder: (context, state) => _page(state, const VehiclesScreen())),
                  GoRoute(path: 'country', pageBuilder: (context, state) => _page(state, const CountrySettingScreen())),
                  GoRoute(path: 'unit', pageBuilder: (context, state) => _page(state, const DistanceUnitScreen())),
                  GoRoute(path: 'currency', pageBuilder: (context, state) => _page(state, const CurrencyScreen())),
                  GoRoute(path: 'language', pageBuilder: (context, state) => _page(state, const LanguageScreen())),
                  GoRoute(
                    path: 'notifications',
                    pageBuilder: (context, state) => _page(state, const NotificationsScreen()),
                  ),
                  GoRoute(
                    path: 'help',
                    pageBuilder: (context, state) => _page(state, const HelpScreen()),
                    routes: [
                      GoRoute(path: 'contact', pageBuilder: (context, state) => _page(state, const ContactScreen())),
                      GoRoute(
                        path: 'topic/:category',
                        pageBuilder: (context, state) {
                          final category = HelpCategory.values
                              .where((c) => c.name == state.pathParameters['category'])
                              .firstOrNull;
                          return category == null
                              ? _page(state, const HelpScreen())
                              : _page(state, HelpTopicScreen(category: category));
                        },
                      ),
                      GoRoute(
                        path: 'article/:id',
                        pageBuilder: (context, state) =>
                            _page(state, HelpArticleScreen(articleId: state.pathParameters['id']!)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Full-screen forms hide the tab bar (spec 2.2).
      GoRoute(
        path: AppRoutes.garageCustomItem,
        pageBuilder: (context, state) => _modal(context, state, const ItemIntervalScreen()),
      ),
      GoRoute(
        path: '/schedule-item/:code/interval',
        pageBuilder: (context, state) => _modal(context, state, ItemIntervalScreen(code: state.pathParameters['code'])),
      ),
      // S-22: ?items=a,b preselects items; ?record=id edits a record.
      GoRoute(
        path: '/log-service',
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters;
          return _modal(
            context,
            state,
            LogServiceScreen(
              initialItems: (query['items'] ?? '').split(',').where((c) => c.isNotEmpty).toList(),
              recordId: query['record'],
              vehicleId: query['vehicle'],
            ),
            maxWidth: 600,
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          );
        },
      ),
      GoRoute(path: AppRoutes.settingsCurrency, pageBuilder: (context, state) => _page(state, const CurrencyScreen())),
      GoRoute(
        path: AppRoutes.accountBackup,
        // S-29 steps 2 and 3: full screen on phones, a card on tablets.
        pageBuilder: (context, state) => _modal(
          context,
          state,
          BackupScreen(step: state.uri.queryParameters['step'] == 'merge' ? BackupStep.merge : BackupStep.upload),
          maxWidth: 480,
        ),
      ),
      // S-35 design review: every reminder on a lock screen. Development
      // builds only.
      if (kDebugMode || MockConfig.notificationGallery)
        GoRoute(
          path: '/dev/notifications',
          pageBuilder: (context, state) => _page(state, const NotificationGalleryScreen()),
        ),
      // S-32 Edit vehicle: full screen, above the navigation bar.
      GoRoute(
        path: AppRoutes.garageEditVehicle,
        pageBuilder: (context, state) => _page(state, const EditVehicleScreen()),
      ),
      GoRoute(
        path: '/vehicle/:id/edit',
        pageBuilder: (context, state) => _page(state, EditVehicleScreen(vehicleId: state.pathParameters['id'])),
      ),
      GoRoute(
        path: AppRoutes.accountDelete,
        // S-30: full screen on phones, a 440 pt card on tablets.
        pageBuilder: (context, state) => _modal(context, state, const EraseScreen(), maxWidth: 440),
      ),
      // S-31 legal pages: the in-app browser.
      GoRoute(
        path: AppRoutes.terms,
        pageBuilder: (context, state) => _modal(
          context,
          state,
          LegalPageScreen(title: AppLocalizations.of(context).profileTerms, url: SupportInfo.terms),
          maxWidth: 720,
        ),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        // S-28: a full-screen form on phones, a 440 pt card on tablets.
        pageBuilder: (context, state) => _modal(
          context,
          state,
          SignInScreen(fromBackup: state.uri.queryParameters['from'] == 'backup'),
          maxWidth: 440,
        ),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        pageBuilder: (context, state) => _modal(
          context,
          state,
          LegalPageScreen(title: AppLocalizations.of(context).profilePrivacyPolicy, url: SupportInfo.privacyPolicy),
          maxWidth: 720,
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// S-21: full screen on phones, a side sheet on tablets.
Page<void> _recordPage(BuildContext context, GoRouterState state) {
  final id = state.pathParameters['id']!;
  return WindowClass.of(context).isCompact
      ? _page(state, ServiceRecordScreen(recordId: id))
      : _sideSheet(state, ServiceRecordScreen(recordId: id, sideSheet: true));
}

/// A route that shows [PlaceholderScreen] until the real screen is built.
GoRoute _placeholder(String path, String screenId, String title) => GoRoute(
  path: path,
  pageBuilder: (context, state) => _page(state, PlaceholderScreen(screenId: screenId, title: title)),
);

/// A full-screen form (phones) or a centred 560 pt modal (tablets), above
/// the tab bar (UI/UX spec S-16 "Responsive").
Page<void> _modal(BuildContext context, GoRouterState state, Widget child, {double maxWidth = 560, double? maxHeight}) {
  if (WindowClass.of(context).isCompact) {
    return MaterialPage<void>(key: state.pageKey, fullscreenDialog: true, child: child);
  }
  return CustomTransitionPage<void>(
    key: state.pageKey,
    opaque: false,
    barrierColor: Colors.black54,
    transitionDuration: AppMotion.standard,
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight ?? 720),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ClipRRect(borderRadius: BorderRadius.circular(AppRadii.sheet), child: child),
        ),
      ),
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: AppMotion.standardCurve),
      child: child,
    ),
  );
}

/// A 420 pt panel that slides in from the end edge over a dimmed page
/// (UI/UX spec 2.4 "side sheet"). Tapping outside closes it.
CustomTransitionPage<void> _sideSheet(GoRouterState state, Widget child) => CustomTransitionPage<void>(
  key: state.pageKey,
  opaque: false,
  barrierDismissible: true,
  barrierColor: Colors.black54,
  transitionDuration: AppMotion.standard,
  reverseTransitionDuration: AppMotion.standard,
  child: Align(
    alignment: AlignmentDirectional.centerEnd,
    child: SizedBox(width: 420, child: child),
  ),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SlideTransition(
      position: Tween(
        begin: Offset(rtl ? -1 : 1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: AppMotion.standardCurve)),
      child: child,
    );
  },
);

/// Platform page transition (iOS slide, mirrored in Arabic), except for the
/// hand-over from the launch screen, which fades.
Page<void> _page(GoRouterState state, Widget child) {
  if (state.extra is LaunchHandover) return _fade(state, child);
  return MaterialPage<void>(key: state.pageKey, child: child);
}

/// Cross-fade used when the launch screen hands over (spec S-01: 250 ms).
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.standard,
    reverseTransitionDuration: AppMotion.standard,
    transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: AppMotion.standardCurve),
      child: child,
    ),
  );
}
