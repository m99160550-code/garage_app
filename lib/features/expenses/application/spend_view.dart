import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../privacy/application/consent_providers.dart';
import '../../settings/application/preferences_providers.dart';
import '../../settings/domain/distance_unit.dart';
import '../../vehicles/application/garage_providers.dart';
import '../domain/spend_summary.dart';
import 'expense_providers.dart';

/// Everything S-19 shows for one vehicle and year.
@immutable
class SpendView {
  const SpendView({
    required this.summary,
    required this.years,
    required this.currentYear,
    required this.itemNames,
    required this.unit,
  });

  final SpendSummary summary;

  /// Years the selector offers, oldest first (never a future year).
  final List<int> years;
  final int currentYear;

  /// Schedule item names by code, for record titles: (English, Arabic).
  final Map<String, (String, String)> itemNames;
  final DistanceUnit unit;
}

/// S-19 data for (vehicle id, year).
final spendViewProvider = FutureProvider.autoDispose.family<SpendView, (String, int)>((ref, key) async {
  final (vehicleId, year) = key;
  // Watch everything before the first await (Riverpod 3).
  ref.watch(garageRevisionProvider);
  final expenses = ref.watch(expenseRepositoryProvider);
  final garage = ref.watch(garageRepositoryProvider);
  final preferencesRepository = ref.watch(preferencesRepositoryProvider);
  final today = ref.watch(clockProvider)();

  final preferences = await preferencesRepository.load();
  final schedule = await garage.schedule(vehicleId);
  return SpendView(
    summary: await expenses.spend(vehicleId, year: year, currency: preferences.currency),
    years: await expenses.years(vehicleId, currentYear: today.year),
    currentYear: today.year,
    itemNames: {for (final item in schedule) item.code: (item.nameEn, item.nameAr)},
    unit: preferences.distanceUnit,
  );
});
