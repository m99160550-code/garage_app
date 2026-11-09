import '../../../core/routing/app_routes.dart';
import '../../session/domain/app_session.dart';

/// Where the launch screen goes next (UI/UX spec S-01 "Behaviour"):
///
/// 1. First run → Intro (S-02).
/// 2. Setup not finished → the step the draft stopped at, or Brand
///    selection (S-04) when there is no draft.
/// 3. Otherwise → Dashboard (S-09) for the last vehicle viewed.
String resolveLaunchRoute(AppSession session) {
  if (!session.hasCompletedIntro && !session.hasVehicles) {
    return AppRoutes.intro;
  }
  if (!session.hasVehicles) {
    final step = session.setupDraftStep;
    return step == null ? AppRoutes.setupBrand : AppRoutes.forSetupStep(step);
  }
  return AppRoutes.garage;
}
