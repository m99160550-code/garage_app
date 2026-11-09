import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/mock_config.dart';
import '../data/garage_repository.dart';

/// Swap for the Drift-backed repository later.
final garageRepositoryProvider = Provider<GarageRepository>(
  (ref) => MockGarageRepository.forScenario(MockConfig.scenario, mileageReview: MockConfig.mileageReview),
);

/// Bumped whenever garage data changes (a vehicle, a reading, a service),
/// so every screen that shows it recalculates. Providers that read the
/// garage watch it.
class GarageRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final garageRevisionProvider = NotifierProvider<GarageRevision, int>(GarageRevision.new);
