import '../../maintenance/data/template_repository.dart';
import '../../mileage/domain/mileage_rules.dart';
import '../../mileage/domain/odometer_reading.dart';
import '../../maintenance/domain/baseline_group.dart';
import '../../maintenance/domain/schedule_item.dart';
import '../../maintenance/domain/schedule_rules.dart';
import '../../maintenance/domain/vehicle_setup.dart';
import '../domain/body_type.dart';
import '../domain/fuel_type.dart';
import '../domain/paint_color.dart';
import '../domain/vehicle.dart';

/// The user's vehicles (Drift locally, synced for Owners).
abstract interface class GarageRepository {
  Future<List<Vehicle>> vehicles();

  /// Saves a new vehicle with its generated schedule, as one unit
  /// (BR-VEH-08).
  Future<void> addVehicle(Vehicle vehicle, List<ScheduleItem> schedule);

  Future<List<ScheduleItem>> schedule(String vehicleId);

  /// Saves edited details (S-32). The odometer changes through readings.
  Future<void> updateVehicle(Vehicle vehicle);

  /// Deletes a vehicle with everything that belongs to it (FR-VEH-12).
  Future<void> deleteVehicle(String vehicleId);

  /// Every odometer reading of a vehicle, oldest first (FR-MIL-03).
  Future<List<OdometerReading>> readings(String vehicleId);

  /// Records a reading and updates the vehicle's current odometer
  /// (BR-MIL-01, BR-MIL-02). Returns the updated vehicle.
  Future<Vehicle> addReading(OdometerReading reading);

  /// Removes a manual reading (spec S-13 item 5); the current odometer
  /// falls back to the remaining readings (BR-MIL-01).
  Future<Vehicle> deleteReading(String vehicleId, String readingId);

  /// Resolves a reading flagged Needs review (S-33, BR-SYN-03): it becomes
  /// a correction (BR-MIL-02), or it is deleted.
  Future<Vehicle> resolveReview(String vehicleId, String readingId, {required bool useAsCorrection});

  /// Replaces one schedule item (snooze, reschedule, not applicable,
  /// last done, intervals).
  Future<void> updateScheduleItem(ScheduleItem item);

  /// Removes a custom item (FR-MNT-05).
  Future<void> deleteScheduleItem(String vehicleId, String itemId);

  /// Adds a custom item (FR-MNT-05).
  Future<void> addScheduleItem(ScheduleItem item);

  /// Saves the schedule after "Apply" and moves the vehicle to template
  /// [version] (FR-REF-06, BR-REF-02), as one unit.
  Future<void> applyTemplateUpdate(String vehicleId, int version, List<ScheduleItem> schedule);

  /// The latest template version the user chose to keep ("Keep current"),
  /// so the prompt doesn't come back for it. `null` if none.
  Future<int?> dismissedTemplateVersion(String vehicleId);

  Future<void> dismissTemplateUpdate(String vehicleId, int version);
}

/// In-memory garage. The `returning` scenario starts with two cars whose
/// schedules are dated relative to [now], so the dashboard always shows
/// the same situation:
///
/// * Family Camry: oil change due soon, 7 items Unknown, mileage read
///   4 days ago.
/// * Nissan Patrol: engine oil overdue, mileage last read 40 days ago.
class MockGarageRepository implements GarageRepository {
  MockGarageRepository([
    List<Vehicle>? vehicles,
    Map<String, List<ScheduleItem>>? schedules,
    Map<String, List<OdometerReading>>? readings,
  ]) : _vehicles = [...?vehicles],
       _schedules = {...?schedules},
       _readings = {
         for (final entry in (readings ?? const <String, List<OdometerReading>>{}).entries) entry.key: [...entry.value],
       };

  /// [mileageReview] adds a sync conflict to the Camry (S-33): 54,900 km
  /// from an iPhone 3 days ago, then 54,800 km from an iPad 2 days ago,
  /// flagged Needs review (BR-SYN-03).
  factory MockGarageRepository.forScenario(String scenario, {DateTime? now, bool mileageReview = false}) {
    if (scenario != 'returning') return MockGarageRepository();
    final today = now ?? DateTime.now();
    final readings = sampleReadingsAt(today);
    if (mileageReview) {
      final day = DateTime(today.year, today.month, today.day);
      readings['veh-camry'] = [
        ...readings['veh-camry']!,
        OdometerReading(
          id: 'veh-camry-r5',
          vehicleId: 'veh-camry',
          date: day.subtract(const Duration(days: 3)),
          km: 54900,
          device: 'iPhone',
        ),
        OdometerReading(
          id: 'veh-camry-r6',
          vehicleId: 'veh-camry',
          date: day.subtract(const Duration(days: 2)),
          km: 54800,
          device: 'iPad',
          needsReview: true,
        ),
      ];
    }
    return MockGarageRepository(sampleVehiclesAt(today), sampleSchedulesAt(today), readings)
      .._syncOdometer('veh-camry');
  }

  /// The two sample cars, without dates (for tests that only need names
  /// and VINs).
  static const sampleVehicles = [
    Vehicle(
      id: 'veh-camry',
      brandId: 'toyota',
      modelId: 'toyota-camry',
      nickname: 'Family Camry',
      year: 2022,
      fuelType: FuelType.hybrid,
      bodyType: BodyType.sedan,
      paint: PaintColor.midnightBlue,
      vin: '4T1C11AK5NU123456',
      odometerKm: 54320,
    ),
    Vehicle(
      id: 'veh-patrol',
      brandId: 'nissan',
      modelId: 'nissan-patrol',
      year: 2019,
      fuelType: FuelType.petrol,
      bodyType: BodyType.suv,
      paint: PaintColor.polarWhite,
      odometerKm: 121400,
    ),
  ];

  static List<Vehicle> sampleVehiclesAt(DateTime today) {
    DateTime ago(int days) => today.subtract(Duration(days: days));
    final [camry, patrol] = sampleVehicles;
    return [_withOdometerDate(camry, ago(4)), _withOdometerDate(patrol, ago(40))];
  }

  static Map<String, List<ScheduleItem>> sampleSchedulesAt(DateTime today) {
    DateTime ago(int days) => DateTime(today.year, today.month, today.day).subtract(Duration(days: days));
    final templates = MockTemplateRepository.templates;
    return {
      'veh-camry': generateSchedule(
        vehicleId: 'veh-camry',
        template: templates[FuelType.hybrid]!,
        setup: BaselineSetup({
          // Oil: 12 months, so due in about 3 weeks.
          BaselineGroup.oilService: BaselineAnswer(date: ago(345), km: 45000),
          BaselineGroup.brakes: BaselineAnswer(date: ago(300), km: 44000),
          // Tires: 6 months, done 2 months ago.
          BaselineGroup.tires: BaselineAnswer(date: ago(60)),
          BaselineGroup.battery: const BaselineAnswer.unknown(),
        }),
      ),
      'veh-patrol': [
        for (final item in generateSchedule(
          vehicleId: 'veh-patrol',
          template: templates[FuelType.petrol]!,
          setup: BaselineSetup({
            // Oil: 10,000 km interval, 2,400 km past it.
            BaselineGroup.oilService: BaselineAnswer(date: ago(200), km: 109000),
            BaselineGroup.brakes: BaselineAnswer(km: 100000),
            BaselineGroup.tires: BaselineAnswer(date: ago(30), km: 118000),
            BaselineGroup.battery: BaselineAnswer(date: ago(400)),
          }),
        ))
          switch (item.code) {
            // The owner set the battery to 30 months, so the template update
            // (petrol v2) keeps it (BR-REF-02).
            'battery' => item.copyWith(intervalMonths: 30, intervalEdited: true),
            // The oil service was logged as a record (sample record
            // rec-patrol-2); deleting it makes these Unknown (BR-SVC-04).
            'engine_oil' || 'oil_filter' => item.copyWith(
              lastDoneSource: LastDoneSource.service,
              lastDoneRecordId: 'rec-patrol-2',
              clearBaseline: true,
            ),
            _ => item,
          },
      ],
    };
  }

  /// The Camry has a mileage history (so predictions work, BR-MIL-05);
  /// the Patrol has a single reading from 40 days ago.
  static Map<String, List<OdometerReading>> sampleReadingsAt(DateTime today) {
    DateTime ago(int days) => DateTime(today.year, today.month, today.day).subtract(Duration(days: days));
    OdometerReading reading(String vehicle, int n, int days, int km, [ReadingSource source = ReadingSource.manual]) =>
        OdometerReading(id: '$vehicle-r$n', vehicleId: vehicle, date: ago(days), km: km, source: source);
    return {
      'veh-camry': [
        reading('veh-camry', 1, 345, 45000, ReadingSource.service),
        reading('veh-camry', 2, 150, 49800),
        reading('veh-camry', 3, 60, 52100),
        reading('veh-camry', 4, 4, 54320),
      ],
      'veh-patrol': [reading('veh-patrol', 1, 40, 121400, ReadingSource.setup)],
    };
  }

  static Vehicle _withOdometerDate(Vehicle v, DateTime date) => _withOdometer(v, v.odometerKm, date);

  static Vehicle _withOdometer(Vehicle v, int km, DateTime? date, {int? templateVersion}) => Vehicle(
    id: v.id,
    brandId: v.brandId,
    brandOtherName: v.brandOtherName,
    modelId: v.modelId,
    modelOtherName: v.modelOtherName,
    nickname: v.nickname,
    year: v.year,
    fuelType: v.fuelType,
    bodyType: v.bodyType,
    paint: v.paint,
    vin: v.vin,
    licencePlate: v.licencePlate,
    purchaseDate: v.purchaseDate,
    odometerKm: km,
    odometerUpdatedAt: date,
    setupMode: v.setupMode,
    templateVersion: templateVersion ?? v.templateVersion,
  );

  final List<Vehicle> _vehicles;
  final Map<String, List<ScheduleItem>> _schedules;
  final Map<String, List<OdometerReading>> _readings;
  final Map<String, int> _dismissedTemplates = {};
  int _nextReading = 0;

  @override
  Future<List<Vehicle>> vehicles() async => List.unmodifiable(_vehicles);

  @override
  Future<void> addVehicle(Vehicle vehicle, List<ScheduleItem> schedule) async {
    _vehicles.add(vehicle);
    _schedules[vehicle.id] = List.unmodifiable(schedule);
    // The odometer entered at setup is the first reading.
    _readings[vehicle.id] = [
      OdometerReading(
        id: '${vehicle.id}-setup',
        vehicleId: vehicle.id,
        date: vehicle.odometerUpdatedAt ?? DateTime.now(),
        km: vehicle.odometerKm,
        source: ReadingSource.setup,
      ),
    ];
  }

  @override
  Future<List<ScheduleItem>> schedule(String vehicleId) async => _schedules[vehicleId] ?? const [];

  @override
  Future<void> updateVehicle(Vehicle vehicle) async {
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index >= 0) _vehicles[index] = vehicle;
  }

  @override
  Future<void> deleteVehicle(String vehicleId) async {
    _vehicles.removeWhere((v) => v.id == vehicleId);
    _schedules.remove(vehicleId);
    _readings.remove(vehicleId);
  }

  @override
  Future<void> updateScheduleItem(ScheduleItem item) async {
    final list = [...?_schedules[item.vehicleId]];
    final index = list.indexWhere((i) => i.id == item.id);
    if (index < 0) return;
    list[index] = item;
    _schedules[item.vehicleId] = List.unmodifiable(list);
  }

  @override
  Future<void> addScheduleItem(ScheduleItem item) async {
    _schedules[item.vehicleId] = List.unmodifiable([...?_schedules[item.vehicleId], item]);
  }

  @override
  Future<void> applyTemplateUpdate(String vehicleId, int version, List<ScheduleItem> schedule) async {
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (index < 0) return;
    final v = _vehicles[index];
    _vehicles[index] = _withOdometer(v, v.odometerKm, v.odometerUpdatedAt, templateVersion: version);
    _schedules[vehicleId] = List.unmodifiable(schedule);
  }

  @override
  Future<int?> dismissedTemplateVersion(String vehicleId) async => _dismissedTemplates[vehicleId];

  @override
  Future<void> dismissTemplateUpdate(String vehicleId, int version) async => _dismissedTemplates[vehicleId] = version;

  @override
  Future<void> deleteScheduleItem(String vehicleId, String itemId) async {
    _schedules[vehicleId] = List.unmodifiable([...?_schedules[vehicleId]]..removeWhere((i) => i.id == itemId));
  }

  @override
  Future<List<OdometerReading>> readings(String vehicleId) async {
    final list = [...?_readings[vehicleId]]..sort((a, b) => a.date.compareTo(b.date));
    return List.unmodifiable(list);
  }

  @override
  Future<Vehicle> addReading(OdometerReading reading) async {
    final list = _readings.putIfAbsent(reading.vehicleId, () => []);
    list.add(
      reading.id.isEmpty
          ? OdometerReading(
              id: '${reading.vehicleId}-m${_nextReading++}',
              vehicleId: reading.vehicleId,
              date: reading.date,
              km: reading.km,
              source: reading.source,
              isCorrection: reading.isCorrection,
              needsReview: reading.needsReview,
              device: reading.device,
            )
          : reading,
    );
    return _syncOdometer(reading.vehicleId);
  }

  @override
  Future<Vehicle> deleteReading(String vehicleId, String readingId) async {
    _readings[vehicleId]?.removeWhere((r) => r.id == readingId);
    return _syncOdometer(vehicleId);
  }

  @override
  Future<Vehicle> resolveReview(String vehicleId, String readingId, {required bool useAsCorrection}) async {
    final list = _readings[vehicleId];
    final index = list?.indexWhere((r) => r.id == readingId) ?? -1;
    if (index >= 0) {
      if (useAsCorrection) {
        list![index] = list[index].copyWith(needsReview: false, isCorrection: true);
      } else {
        list!.removeAt(index);
      }
    }
    return _syncOdometer(vehicleId);
  }

  /// Makes the vehicle's odometer match its current reading.
  Vehicle _syncOdometer(String vehicleId) {
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    final current = currentReading(_readings[vehicleId] ?? const []);
    if (current == null) return _vehicles[index];
    final updated = _withOdometer(_vehicles[index], current.km, current.date);
    _vehicles[index] = updated;
    return updated;
  }
}
