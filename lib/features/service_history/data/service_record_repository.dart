import '../domain/service_record.dart';

/// Service records (Drift locally, synced for Owners). Screens only depend
/// on this interface.
abstract interface class ServiceRecordRepository {
  /// A vehicle's records, newest first.
  Future<List<ServiceRecord>> records(String vehicleId);

  /// One record, or `null` if it doesn't exist (any more).
  Future<ServiceRecord?> record(String id);

  Future<void> delete(String id);

  /// Puts a deleted record back ("Undo", spec S-21).
  Future<void> restore(ServiceRecord record);

  /// Adds a new record or replaces the one with the same id (S-22).
  Future<void> save(ServiceRecord record);

  /// Every record of every vehicle (shop suggestions, first service).
  Future<List<ServiceRecord>> all();
}

/// In-memory records. The `returning` scenario matches the sample garage:
///
/// * Family Camry: three services with a cost in this year (SAR 420) and
///   one last year.
/// * Nissan Patrol: two services in SAR this year (SAR 1,150) and one in
///   AED, which the SAR total leaves out (BR-EXP-03).
class MockServiceRecordRepository implements ServiceRecordRepository {
  MockServiceRecordRepository([List<ServiceRecord>? records]) : _records = [...?records];

  factory MockServiceRecordRepository.forScenario(String scenario, {DateTime? now}) =>
      MockServiceRecordRepository(scenario == 'returning' ? sampleRecordsAt(now ?? DateTime.now()) : null);

  static List<ServiceRecord> sampleRecordsAt(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    DateTime ago(int days) => today.subtract(Duration(days: days));
    ServiceRecord record(
      String id,
      String vehicle,
      int days, {
      required ServiceType type,
      int? km,
      int? sar,
      String currency = 'SAR',
      String? shop,
      String? notes,
      List<String> items = const [],
    }) => ServiceRecord(
      id: id,
      vehicleId: vehicle,
      date: ago(days),
      type: type,
      odometerKm: km,
      costMinor: sar == null ? null : sar * 100,
      currency: sar == null ? null : currency,
      shopName: shop,
      notes: notes,
      itemCodes: items,
      createdAt: ago(days).add(const Duration(hours: 18)),
    );

    return [
      // Family Camry.
      record(
        'rec-camry-1',
        'veh-camry',
        345,
        type: ServiceType.maintenance,
        km: 45000,
        sar: 350,
        shop: 'Al Futtaim Service',
        notes: 'Synthetic 0W-20',
        items: ['engine_oil', 'oil_filter'],
      ),
      record('rec-camry-2', 'veh-camry', 200, type: ServiceType.maintenance, km: 47900, sar: 50, items: ['wipers']),
      record(
        'rec-camry-3',
        'veh-camry',
        150,
        type: ServiceType.repair,
        km: 49800,
        sar: 250,
        shop: 'Al Futtaim Service',
        notes: 'AC recharge',
      ),
      record(
        'rec-camry-4',
        'veh-camry',
        60,
        type: ServiceType.maintenance,
        km: 52100,
        sar: 120,
        shop: 'Bridgestone Olaya',
        items: ['tire_rotation'],
      ),
      record('rec-camry-5', 'veh-camry', 20, type: ServiceType.inspection, km: 53900, shop: 'Fahas'),
      // Nissan Patrol.
      record(
        'rec-patrol-1',
        'veh-patrol',
        250,
        type: ServiceType.repair,
        km: 106500,
        sar: 600,
        currency: 'AED',
        shop: 'Dubai Auto Care',
        notes: 'Radiator hose, on a trip',
      ),
      record(
        'rec-patrol-2',
        'veh-patrol',
        200,
        type: ServiceType.maintenance,
        km: 109000,
        sar: 200,
        shop: 'Petromin Express',
        items: ['engine_oil', 'oil_filter'],
      ),
      record(
        'rec-patrol-3',
        'veh-patrol',
        30,
        type: ServiceType.maintenance,
        km: 118000,
        sar: 950,
        shop: 'Al Jomaih Tyres',
        items: ['tire_rotation'],
      ),
    ];
  }

  final List<ServiceRecord> _records;

  @override
  Future<ServiceRecord?> record(String id) async => _records.where((r) => r.id == id).firstOrNull;

  @override
  Future<void> save(ServiceRecord record) async {
    _records
      ..removeWhere((r) => r.id == record.id)
      ..add(record);
  }

  @override
  Future<List<ServiceRecord>> all() async => List.unmodifiable(_records);

  @override
  Future<void> delete(String id) async => _records.removeWhere((r) => r.id == id);

  @override
  Future<void> restore(ServiceRecord record) async {
    if (!_records.any((r) => r.id == record.id)) _records.add(record);
  }

  @override
  Future<List<ServiceRecord>> records(String vehicleId) async =>
      _records.where((r) => r.vehicleId == vehicleId).toList()..sort((a, b) => b.date.compareTo(a.date));
}
