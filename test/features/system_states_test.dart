import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tdc_garage/core/l10n/generated/app_localizations.dart';
import 'package:tdc_garage/core/theme/app_theme.dart';
import 'package:tdc_garage/core/widgets/app_banner.dart';
import 'package:tdc_garage/core/widgets/app_button.dart';
import 'package:tdc_garage/core/widgets/app_empty_state.dart';
import 'package:tdc_garage/core/widgets/app_skeleton.dart';
import 'package:tdc_garage/core/widgets/app_text_field.dart';
import 'package:tdc_garage/core/widgets/app_toast.dart';
import 'package:tdc_garage/features/account/application/account_providers.dart';
import 'package:tdc_garage/features/account/data/account_repository.dart';
import 'package:tdc_garage/features/account/presentation/widgets/sync_indicator.dart';
import 'package:tdc_garage/features/app_update/application/update_gate.dart';
import 'package:tdc_garage/features/app_update/data/app_version_repository.dart';
import 'package:tdc_garage/features/app_update/presentation/update_required_screen.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/privacy/application/consent_providers.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/settings/presentation/profile_screen.dart';
import 'package:tdc_garage/features/vehicles/application/garage_providers.dart';
import 'package:tdc_garage/features/vehicles/data/garage_repository.dart';
import 'package:tdc_garage/features/vehicles/domain/vehicle.dart';

import '../helpers/test_app.dart';

final _now = DateTime(2026, 11, 7, 10);

/// A garage whose saves fail, for the generic error.
class _FailingGarage extends MockGarageRepository {
  _FailingGarage()
    : super(
        MockGarageRepository.sampleVehiclesAt(_now),
        MockGarageRepository.sampleSchedulesAt(_now),
        MockGarageRepository.sampleReadingsAt(_now),
      );

  @override
  Future<void> updateVehicle(Vehicle vehicle) async => throw Exception('network');
}

/// A bare app around [child], for the shared components.
Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.dark(arabic: false),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: child),
  ),
);

Future<void> _launch(
  WidgetTester tester, {
  String account = 'guest',
  bool mileageReview = false,
  bool updateRequired = false,
  GarageRepository? garage,
  StoreLauncher? store,
}) async {
  useScreen(tester, const Size(390, 1000));
  await tester.pumpWidget(
    buildTestApp(
      MockSessionRepository(scenario: 'returning'),
      overrides: [
        garageRepositoryProvider.overrideWithValue(
          garage ?? MockGarageRepository.forScenario('returning', now: _now, mileageReview: mileageReview),
        ),
        accountRepositoryProvider.overrideWithValue(MockAccountRepository.fromConfig(account, now: _now)),
        appVersionRepositoryProvider.overrideWithValue(MockAppVersionRepository(supported: !updateRequired)),
        if (store != null) storeLauncherProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => _now),
      ],
    ),
  );
  await finishLaunch(tester);
}

void main() {
  group('skeletons', () {
    testWidgets('nothing for the first 300 ms, then the skeleton, announced as "Loading"', (tester) async {
      await tester.pumpWidget(_host(const DelayedSkeleton()));
      expect(find.byType(SkeletonList), findsNothing);
      await tester.pump(const Duration(milliseconds: 299));
      expect(find.byType(SkeletonList), findsNothing);
      await tester.pump(const Duration(milliseconds: 2));
      expect(find.byType(SkeletonList), findsOneWidget);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('a 1.2 s shimmer; none with Reduce Motion', (tester) async {
      await tester.pumpWidget(_host(const SkeletonList()));
      expect(find.byType(ShaderMask), findsOneWidget);
      await tester.pumpWidget(_host(const SkeletonList(), reduceMotion: true));
      await tester.pump();
      expect(find.byType(ShaderMask), findsNothing);
    });
  });

  testWidgets('empty state: 120 pt illustration, heading, explanation, one action', (tester) async {
    await tester.pumpWidget(
      _host(
        AppEmptyState(
          icon: Icons.timeline,
          title: 'Nothing yet',
          body: 'Add something.',
          action: AppButton(label: 'Add', onPressed: () {}),
        ),
      ),
    );
    final illustration = find.ancestor(of: find.byIcon(Icons.timeline), matching: find.byType(Container)).first;
    expect(tester.getSize(illustration), const Size.square(AppEmptyState.illustrationSize));
    expect(find.text('Nothing yet'), findsOneWidget);
    expect(find.text('Add something.'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Add'), findsOneWidget);
  });

  testWidgets('offline banner: "You\'re offline" and the reason, info tone', (tester) async {
    await tester.pumpWidget(_host(const OfflineBanner(reason: 'You need a connection to sign in.')));
    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('You need a connection to sign in.'), findsOneWidget);
    expect(tester.widget<AppBanner>(find.byType(AppBanner)).tone, BannerTone.info);
  });

  testWidgets('generic error: the plain message and Retry, which repeats the action', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showErrorToast(context, onRetry: () => retries++),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong. Try again.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(retries, 1);
  });

  testWidgets('a failing save shows the generic error, and the form stays', (tester) async {
    await _launch(tester, garage: _FailingGarage());
    GoRouter.of(tester.element(find.byType(DashboardScreen))).push('/vehicle/edit');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(of: find.widgetWithText(AppTextField, 'Nickname'), matching: find.byType(EditableText)),
      'New name',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Something went wrong. Try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Edit vehicle'), findsOneWidget);
  });

  group('sync indicator', () {
    testWidgets('nothing for Guests, nothing when synced', (tester) async {
      await _launch(tester);
      final button = find.descendant(of: find.byType(SyncIndicator), matching: find.byType(IconButton));
      expect(button, findsNothing);
      await _launch(tester, account: 'owner');
      expect(button, findsNothing);
    });

    testWidgets('pending: a count badge; tapping opens Profile', (tester) async {
      await _launch(tester, account: 'ownerPending');
      expect(find.byTooltip('3 changes waiting to sync'), findsOneWidget);
      expect(find.descendant(of: find.byType(Badge), matching: find.text('3')), findsOneWidget);
      await tester.tap(find.byTooltip('3 changes waiting to sync'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('offline: cloud-off', (tester) async {
      await _launch(tester, account: 'ownerOffline');
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(find.byTooltip("Offline. Changes will sync when you're back online."), findsOneWidget);
    });

    testWidgets('syncing: a spinning icon', (tester) async {
      useScreen(tester, const Size(390, 1000));
      await tester.pumpWidget(
        buildTestApp(
          MockSessionRepository(scenario: 'returning'),
          overrides: [
            garageRepositoryProvider.overrideWithValue(MockGarageRepository.forScenario('returning', now: _now)),
            accountRepositoryProvider.overrideWithValue(MockAccountRepository.fromConfig('ownerSyncing', now: _now)),
            clockProvider.overrideWithValue(() => _now),
          ],
        ),
      );
      // The spinner never settles: pump time instead.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byTooltip('Syncing'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(SyncIndicator), matching: find.byType(RotationTransition)),
        findsOneWidget,
      );
    });

    testWidgets('a mileage reading to review adds the amber dot (BR-SYN-03)', (tester) async {
      await _launch(tester, account: 'owner', mileageReview: true);
      expect(find.byTooltip('A mileage reading needs review'), findsOneWidget);
    });
  });

  group('update required (API 426)', () {
    testWidgets('blocks the app; "Update" opens the store; back does nothing', (tester) async {
      final store = StoreLauncher();
      useScreen(tester, const Size(390, 1000));
      await tester.pumpWidget(
        buildTestApp(
          MockSessionRepository(scenario: 'returning'),
          overrides: [
            appVersionRepositoryProvider.overrideWithValue(const MockAppVersionRepository(supported: false)),
            storeLauncherProvider.overrideWithValue(store),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(UpdateRequiredScreen), findsOneWidget);
      expect(find.text('Update required'), findsOneWidget);
      expect(find.text('This version is no longer supported.'), findsOneWidget);
      expect(find.text('Your data on this phone is safe.'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(UpdateRequiredScreen), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Update'));
      await tester.pump();
      expect(store.opened, 1);
    });

    testWidgets('a 426 during use switches to the blocking screen', (tester) async {
      await _launch(tester);
      expect(find.byType(UpdateRequiredScreen), findsNothing);
      ProviderScope.containerOf(tester.element(find.byType(DashboardScreen)))
          .read(updateRequiredProvider.notifier)
          .require();
      await tester.pumpAndSettle();
      expect(find.byType(UpdateRequiredScreen), findsOneWidget);
    });

    testWidgets('meets tap-target and contrast guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await _launch(tester, updateRequired: true);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
