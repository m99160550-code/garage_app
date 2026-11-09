import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../vehicles/application/garage_providers.dart';
import '../domain/template_update.dart';
import 'maintenance_providers.dart';

/// The template update offered for a vehicle (FR-REF-06), or `null` when
/// it is on the latest version, chose "Keep current" for it, or the new
/// version only changed wording (BR-REF-08).
final templateUpdateProvider = FutureProvider.autoDispose.family<TemplateUpdate?, String>((ref, vehicleId) async {
  // Watch everything before the first await (Riverpod 3).
  ref.watch(garageRevisionProvider);
  final garage = ref.watch(garageRepositoryProvider);
  final templates = ref.watch(templateRepositoryProvider);

  final vehicle = (await garage.vehicles()).where((v) => v.id == vehicleId).firstOrNull;
  if (vehicle == null) return null;
  final latest = await templates.currentFor(vehicle.fuelType);
  if (latest.version <= vehicle.templateVersion) return null;
  final dismissed = await garage.dismissedTemplateVersion(vehicleId);
  if (dismissed != null && dismissed >= latest.version) return null;

  final from = await templates.versionFor(vehicle.fuelType, vehicle.templateVersion);
  final changes = templateChanges(schedule: await garage.schedule(vehicleId), from: from, to: latest);
  if (changes.isEmpty) return null;
  return TemplateUpdate(vehicleId: vehicleId, from: from, to: latest, changes: changes);
});

/// "Apply" and "Keep current" on S-17.
class TemplateUpdateActions {
  TemplateUpdateActions(this._ref);

  final Ref _ref;

  /// Updates the unedited items and moves the vehicle to the new version
  /// (BR-REF-02); the score and due dates recalculate.
  Future<void> apply(TemplateUpdate update) async {
    final garage = _ref.read(garageRepositoryProvider);
    final schedule = applyTemplateChanges(
      vehicleId: update.vehicleId,
      schedule: await garage.schedule(update.vehicleId),
      changes: update.changes,
    );
    await garage.applyTemplateUpdate(update.vehicleId, update.to.version, schedule);
    _ref.read(garageRevisionProvider.notifier).bump();
  }

  /// Hides the prompt for this version; a later version asks again.
  Future<void> keepCurrent(TemplateUpdate update) async {
    await _ref.read(garageRepositoryProvider).dismissTemplateUpdate(update.vehicleId, update.to.version);
    _ref.read(garageRevisionProvider.notifier).bump();
  }
}

final templateUpdateActionsProvider = Provider<TemplateUpdateActions>(TemplateUpdateActions.new);
