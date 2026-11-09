import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../garage/application/current_vehicle_controller.dart';
import '../../garage/application/dashboard_data.dart';
import '../../garage/application/vehicle_dues.dart';
import '../../maintenance/domain/health_score.dart';
import '../../maintenance/domain/item_due.dart';
import '../../maintenance/domain/schedule_item.dart';
import '../../mileage/domain/mileage_rules.dart';
import '../../mileage/domain/odometer_reading.dart';
import '../../privacy/application/consent_providers.dart';
import '../../reference/application/reference_providers.dart';
import '../../settings/application/preferences_providers.dart';
import '../../settings/domain/distance_unit.dart';
import '../../vehicles/application/garage_providers.dart';
import '../../vehicles/application/vehicle_names.dart';
import '../domain/log_service_rules.dart';
import '../domain/service_record.dart';
import 'service_history_providers.dart';

/// What S-22 needs for one vehicle (and, when editing, the record).
@immutable
class LogServiceData {
  const LogServiceData({
    required this.vehicleId,
    required this.vehicles,
    required this.dues,
    required this.current,
    required this.unit,
    required this.currency,
    required this.currencies,
    required this.today,
    required this.shops,
    this.existing,
  });

  final String vehicleId;

  /// Every vehicle (id, name), for "For: … ▾".
  final List<(String, String)> vehicles;
  final List<ItemDue> dues;

  /// The current odometer reading (default and "Current: …").
  final OdometerReading? current;
  final DistanceUnit unit;

  /// The default currency (FR-SVC-02).
  final String currency;

  /// Currencies the currency button offers.
  final List<String> currencies;
  final DateTime today;

  /// Shop names used before (suggestions).
  final List<String> shops;

  /// The record being edited.
  final ServiceRecord? existing;
}

/// S-22 data. With a record id, the record's own vehicle; otherwise
/// [vehicleId], or the dashboard's vehicle.
final logServiceDataProvider = FutureProvider.autoDispose
    .family<LogServiceData?, ({String? vehicleId, String? recordId, String languageCode})>((ref, key) async {
      // Watch everything before the first await (Riverpod 3).
      final records = ref.watch(serviceRecordRepositoryProvider);
      final preferencesRepository = ref.watch(preferencesRepositoryProvider);
      final reference = ref.watch(referenceRepositoryProvider);
      final garage = ref.watch(garageRepositoryProvider);
      final currentFuture = ref.watch(currentVehicleProvider.future);
      final vehiclesFuture = ref.watch(garageVehiclesProvider.future);

      final existing = key.recordId == null ? null : await records.record(key.recordId!);
      final vehicleId = existing?.vehicleId ?? key.vehicleId ?? await currentFuture;
      if (vehicleId == null) return null;
      final data = await ref.watch(dashboardDataProvider(vehicleId).future);
      final preferences = await preferencesRepository.load();
      final countries = await reference.countries();
      final names = <(String, String)>[
        for (final v in await vehiclesFuture)
          (v.id, await ref.read(vehicleDisplayNameProvider((vehicleId: v.id, languageCode: key.languageCode)).future)),
      ];
      return LogServiceData(
        vehicleId: vehicleId,
        vehicles: names,
        dues: data.dues,
        current: currentReading(await garage.readings(vehicleId)),
        unit: data.unit,
        currency: preferences.currency,
        currencies: {preferences.currency, ?existing?.currency, for (final c in countries) c.defaultCurrency}.toList(),
        // Date only: the default service date and the date picker's limit.
        today: DateTime(data.today.year, data.today.month, data.today.day),
        shops: shopSuggestions(await records.all()),
        existing: existing,
      );
    });

/// The form's values, ready to save.
@immutable
class ServiceDraft {
  const ServiceDraft({
    required this.vehicleId,
    required this.date,
    required this.odometerKm,
    required this.itemCodes,
    required this.type,
    required this.currency,
    this.costMinor,
    this.shopName,
    this.notes,
    this.correction = false,
  });

  final String vehicleId;
  final DateTime date;
  final int odometerKm;
  final List<String> itemCodes;
  final ServiceType type;
  final int? costMinor;
  final String currency;
  final String? shopName;
  final String? notes;

  /// The odometer is lower than the current reading and the user
  /// confirmed it as a correction (BR-MIL-02).
  final bool correction;
}

/// What the confirmation says (spec S-22 "After save").
typedef SaveOutcome = ({int score, List<ScheduleItem> kept, bool firstService});

/// Saving S-22 (UC-03 steps 5–7).
class LogServiceActions {
  LogServiceActions(this._ref);

  final Ref _ref;

  /// The odometer reading a record adds (BR-MIL-04), by record.
  static String readingIdFor(String recordId) => 'svc-$recordId';

  Future<SaveOutcome> save(ServiceDraft draft, {ServiceRecord? existing}) async {
    final records = _ref.read(serviceRecordRepositoryProvider);
    final garage = _ref.read(garageRepositoryProvider);
    final now = _ref.read(clockProvider)();
    final firstService = existing == null && (await records.all()).isEmpty;

    final record = ServiceRecord(
      id: existing?.id ?? 'rec-${now.microsecondsSinceEpoch}',
      vehicleId: draft.vehicleId,
      date: draft.date,
      type: draft.type,
      odometerKm: draft.odometerKm,
      costMinor: draft.costMinor,
      currency: draft.costMinor == null ? null : draft.currency,
      shopName: (draft.shopName?.trim().isEmpty ?? true) ? null : draft.shopName!.trim(),
      notes: (draft.notes?.trim().isEmpty ?? true) ? null : draft.notes!.trim(),
      itemCodes: draft.itemCodes,
      createdAt: existing?.createdAt ?? now,
    );

    // 1. The schedule: covered items reset (FR-SVC-03, BR-SVC-02, BR-SVC-04).
    final schedule = await garage.schedule(draft.vehicleId);
    final changes = existing == null
        ? applyRecord(record, schedule)
        : applyEdit(
            existing,
            record,
            schedule: schedule,
            otherRecords: (await records.records(draft.vehicleId)).where((r) => r.id != existing.id).toList(),
          );
    await records.save(record);
    for (final item in changes.updated) {
      await garage.updateScheduleItem(item);
    }

    // 2. The odometer: the record's value is a reading (BR-MIL-04, BR-SVC-03).
    final readingId = readingIdFor(record.id);
    await garage.deleteReading(draft.vehicleId, readingId);
    final vehicle = await garage.addReading(
      OdometerReading(
        id: readingId,
        vehicleId: draft.vehicleId,
        date: record.date,
        km: draft.odometerKm,
        source: ReadingSource.service,
        isCorrection: draft.correction,
      ),
    );
    _ref.read(garageRevisionProvider.notifier).bump();

    // 3. The score now, for "Service saved · score now 94".
    final preferences = await _ref.read(preferencesRepositoryProvider).load();
    final dues = vehicleDues(
      vehicle,
      await garage.schedule(draft.vehicleId),
      readings: await garage.readings(draft.vehicleId),
      unit: preferences.distanceUnit,
      today: DateTime(now.year, now.month, now.day),
    );
    return (
      score: computeHealthScore(dues, unit: preferences.distanceUnit).score,
      kept: changes.kept,
      firstService: firstService,
    );
  }
}

final logServiceActionsProvider = Provider<LogServiceActions>(LogServiceActions.new);
