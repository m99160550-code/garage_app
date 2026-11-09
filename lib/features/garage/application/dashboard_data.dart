import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mileage/domain/mileage_rules.dart';

import '../../expenses/application/expense_providers.dart';
import '../../expenses/domain/spend_summary.dart';
import '../../maintenance/domain/dashboard_summary.dart';
import '../../maintenance/domain/health_score.dart';
import '../../maintenance/domain/item_due.dart';
import '../../mileage/domain/odometer_reading.dart';
import '../../privacy/application/consent_providers.dart';
import '../../reference/application/reference_providers.dart';
import '../../reference/domain/brand.dart';
import '../../reference/domain/vehicle_model.dart';
import '../../settings/application/preferences_providers.dart';
import '../../settings/domain/distance_unit.dart';
import '../../vehicles/application/garage_providers.dart';
import '../../vehicles/domain/vehicle.dart';
import 'vehicle_dues.dart';

/// Everything S-09 shows for one vehicle, calculated on the device
/// (architecture AD-03: the Dart rules engine).
@immutable
class DashboardData {
  const DashboardData({
    required this.vehicle,
    required this.brand,
    required this.model,
    required this.dues,
    required this.health,
    required this.alert,
    required this.nextService,
    required this.upcoming,
    required this.spend,
    required this.unit,
    required this.today,
    required this.readings,
  });

  final Vehicle vehicle;
  final Brand? brand;
  final VehicleModel? model;
  final List<ItemDue> dues;
  final HealthScore health;
  final DashboardAlert alert;
  final NextService nextService;
  final List<ItemDue> upcoming;
  final SpendSummary spend;
  final DistanceUnit unit;
  final DateTime today;

  /// Mileage history, oldest first.
  final List<OdometerReading> readings;

  /// "Toyota", or the typed "Other" brand (BR-VEH-07).
  String brandName(String languageCode) => brand?.name(languageCode) ?? vehicle.brandOtherName ?? '';

  String modelName(String languageCode) => model?.name(languageCode) ?? vehicle.modelOtherName ?? '';

  /// The monogram letters: the dataset's, or made from the typed name.
  String get monogram {
    if (brand != null) return brand!.monogram;
    final name = (vehicle.brandOtherName ?? '?').trim();
    return name.isEmpty ? '?' : name.substring(0, name.length < 2 ? name.length : 2).toUpperCase();
  }

  /// Days since the last odometer reading.
  int? get daysSinceReading {
    final read = vehicle.odometerUpdatedAt;
    if (read == null) return null;
    return DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(read.year, read.month, read.day)).inDays;
  }
}

final dashboardDataProvider = FutureProvider.autoDispose.family<DashboardData, String>((ref, vehicleId) async {
  // Every dependency is watched before the first await.
  ref.watch(garageRevisionProvider);
  final garage = ref.watch(garageRepositoryProvider);
  final preferencesRepository = ref.watch(preferencesRepositoryProvider);
  final expenses = ref.watch(expenseRepositoryProvider);
  final reference = ref.watch(referenceRepositoryProvider);
  final brandsFuture = ref.watch(brandsProvider.future);
  final today = ref.watch(clockProvider)();

  final vehicle = (await garage.vehicles()).firstWhere((v) => v.id == vehicleId);
  final schedule = await garage.schedule(vehicleId);
  final preferences = await preferencesRepository.load();

  final brand = (await brandsFuture).where((b) => b.id == vehicle.brandId).firstOrNull;
  final model = brand == null || vehicle.modelId == null
      ? null
      : (await reference.models(brand.id)).where((m) => m.id == vehicle.modelId).firstOrNull;

  final readings = await garage.readings(vehicleId);
  final dues = vehicleDues(vehicle, schedule, readings: readings, unit: preferences.distanceUnit, today: today);

  return DashboardData(
    vehicle: vehicle,
    brand: brand,
    model: model,
    dues: dues,
    health: computeHealthScore(dues, unit: preferences.distanceUnit),
    alert: pickAlert(
      dues,
      today: today,
      odometerDate: vehicle.odometerUpdatedAt,
      reviewReadingId: readingConflicts(readings).firstOrNull?.flagged.id,
    ),
    nextService: computeNextService(dues, today: today),
    upcoming: upcomingItems(dues, today: today),
    spend: await expenses.spend(vehicleId, year: today.year, currency: preferences.currency),
    unit: preferences.distanceUnit,
    today: today,
    readings: readings,
  );
});
