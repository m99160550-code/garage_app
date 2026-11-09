import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/preferences_providers.dart';
import '../../settings/domain/distance_unit.dart';
import '../../vehicles/application/garage_providers.dart';
import '../domain/mileage_rules.dart';

/// The conflict S-33 shows for one flagged reading, in the user's unit.
/// `null` once it's resolved.
final mileageReviewProvider = FutureProvider.autoDispose
    .family<({ReadingConflict conflict, DistanceUnit unit})?, ({String vehicleId, String readingId})>((ref, key) async {
      ref.watch(garageRevisionProvider);
      final garage = ref.watch(garageRepositoryProvider);
      final preferences = ref.watch(preferencesRepositoryProvider);
      final readings = await garage.readings(key.vehicleId);
      final conflict = readingConflicts(readings).where((c) => c.flagged.id == key.readingId).firstOrNull;
      if (conflict == null) return null;
      return (conflict: conflict, unit: (await preferences.load()).distanceUnit);
    });

/// Resolves the flagged reading (BR-SYN-03): keep it as a correction
/// (BR-MIL-02), or delete it.
class MileageReviewActions {
  MileageReviewActions(this._ref);

  final Ref _ref;

  Future<void> resolve(String vehicleId, String readingId, {required bool useAsCorrection}) async {
    await _ref.read(garageRepositoryProvider).resolveReview(vehicleId, readingId, useAsCorrection: useAsCorrection);
    _ref.read(garageRevisionProvider.notifier).bump();
  }
}

final mileageReviewActionsProvider = Provider<MileageReviewActions>(MileageReviewActions.new);
