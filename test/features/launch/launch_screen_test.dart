import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/garage/presentation/dashboard_screen.dart';
import 'package:tdc_garage/features/launch/presentation/launch_screen.dart';
import 'package:tdc_garage/features/onboarding/presentation/details/vehicle_details_screen.dart';
import 'package:tdc_garage/features/onboarding/presentation/intro/intro_screen.dart';
import 'package:tdc_garage/features/session/data/mock_session_repository.dart';
import 'package:tdc_garage/features/session/data/session_repository.dart';
import 'package:tdc_garage/features/session/domain/app_session.dart';

import '../../helpers/test_app.dart';

/// Fails on the first load, succeeds afterwards: exercises Retry.
class _FlakyRepository implements SessionRepository {
  int calls = 0;

  @override
  Future<AppSession> load() async {
    calls++;
    if (calls == 1) throw const SessionLoadException();
    return const AppSession(hasCompletedIntro: true, vehicleCount: 1);
  }

  @override
  Future<void> markIntroCompleted() async {}

  @override
  Future<void> saveSetupDraftStep(SetupStep? step) async {}

  @override
  Future<void> recordVehicleAdded(String vehicleId) async {}

  @override
  Future<void> saveLastVehicle(String vehicleId) async {}

  @override
  Future<void> recordVehicleDeleted(String vehicleId, {String? nextVehicleId}) async {}

  @override
  Future<void> reset() async {}
}

void main() {
  testWidgets('shows the app name and announces loading', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(buildTestApp(MockSessionRepository(scenario: 'firstRun')));
    await tester.pump();

    expect(find.byType(LaunchScreen), findsOneWidget);
    expect(find.bySemanticsLabel('TDC-mena Garage is loading'), findsOneWidget);

    await finishLaunch(tester);
    semantics.dispose();
  });

  testWidgets('stays visible for at least 300 ms even when data is instant', (tester) async {
    await tester.pumpWidget(buildTestApp(MockSessionRepository(scenario: 'returning')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(LaunchScreen), findsOneWidget);
    await finishLaunch(tester);
    expect(find.byType(LaunchScreen), findsNothing);
  });

  testWidgets('first run hands over to the intro', (tester) async {
    await tester.pumpWidget(buildTestApp(MockSessionRepository(scenario: 'firstRun')));
    await finishLaunch(tester);
    expect(find.byType(IntroScreen), findsOneWidget);
  });

  testWidgets('an unfinished setup resumes at its step', (tester) async {
    await tester.pumpWidget(buildTestApp(MockSessionRepository(scenario: 'setupDraft')));
    await finishLaunch(tester);
    expect(find.byType(VehicleDetailsScreen), findsOneWidget);
  });

  testWidgets('a returning user goes to the dashboard', (tester) async {
    await tester.pumpWidget(buildTestApp(MockSessionRepository(scenario: 'returning')));
    await finishLaunch(tester);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('a load failure shows the error and Try again recovers', (tester) async {
    final repository = _FlakyRepository();
    await tester.pumpWidget(buildTestApp(repository));
    await finishLaunch(tester);

    expect(find.text("We couldn't open your garage"), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await finishLaunch(tester);

    expect(repository.calls, 2);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('the error state meets tap-target and contrast guidelines', (tester) async {
    await tester.pumpWidget(buildTestApp(MockSessionRepository(scenario: 'loadError')));
    await finishLaunch(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
