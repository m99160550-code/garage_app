import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/core/routing/app_routes.dart';
import 'package:tdc_garage/features/launch/application/launch_route.dart';
import 'package:tdc_garage/features/session/domain/app_session.dart';

void main() {
  group('resolveLaunchRoute', () {
    test('first run goes to the intro', () {
      const session = AppSession(hasCompletedIntro: false, vehicleCount: 0);
      expect(resolveLaunchRoute(session), AppRoutes.intro);
    });

    test('intro done, no vehicle and no draft goes to brand selection', () {
      const session = AppSession(hasCompletedIntro: true, vehicleCount: 0);
      expect(resolveLaunchRoute(session), AppRoutes.setupBrand);
    });

    test('unfinished setup resumes at the saved step', () {
      const session = AppSession(hasCompletedIntro: true, vehicleCount: 0, setupDraftStep: SetupStep.baseline);
      expect(resolveLaunchRoute(session), AppRoutes.setupBaseline);
    });

    test('a saved vehicle goes to the dashboard', () {
      const session = AppSession(hasCompletedIntro: true, vehicleCount: 1);
      expect(resolveLaunchRoute(session), AppRoutes.garage);
    });

    test('a vehicle synced from an account skips the intro even on a new device', () {
      const session = AppSession(hasCompletedIntro: false, vehicleCount: 2);
      expect(resolveLaunchRoute(session), AppRoutes.garage);
    });
  });
}
