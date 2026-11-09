import '../../vehicles/domain/fuel_type.dart';
import '../domain/baseline_group.dart';
import '../domain/maintenance_template.dart';
import '../domain/severity.dart';

/// Published maintenance templates (FR-REF-04). The real implementation
/// reads the copy cached on the device, refreshed from `/reference`.
abstract interface class TemplateRepository {
  /// The latest published version (used for new vehicles).
  Future<MaintenanceTemplate> currentFor(FuelType fuelType);

  /// A specific version, for the vehicle's "Typical" values and for
  /// comparing with the latest one (FR-REF-06). Falls back to the latest
  /// when that version isn't cached.
  Future<MaintenanceTemplate> versionFor(FuelType fuelType, int version);
}

/// Mock templates with typical intervals. Severities follow BR-HLT-01:
/// critical = brakes, tires, brake fluid; major = engine oil, coolant,
/// battery, timing belt; minor = filters, wipers, inspection.
///
/// These numbers are placeholders for development only. The real intervals
/// come from the template signed off by the named mechanic (Q-03, FR-REF-04).
class MockTemplateRepository implements TemplateRepository {
  const MockTemplateRepository();

  @override
  Future<MaintenanceTemplate> currentFor(FuelType fuelType) async => updates[fuelType] ?? templates[fuelType]!;

  @override
  Future<MaintenanceTemplate> versionFor(FuelType fuelType, int version) async {
    for (final template in [templates[fuelType], updates[fuelType]]) {
      if (template?.version == version) return template!;
    }
    return currentFor(fuelType);
  }

  static const _oil = TemplateItem(
    code: 'engine_oil',
    nameEn: 'Engine oil',
    nameAr: 'زيت المحرك',
    severity: Severity.major,
    intervalMonths: 12,
    intervalKm: 10000,
    baselineGroup: BaselineGroup.oilService,
  );
  static const _oilFilter = TemplateItem(
    code: 'oil_filter',
    nameEn: 'Oil filter',
    nameAr: 'فلتر الزيت',
    severity: Severity.minor,
    intervalMonths: 12,
    intervalKm: 10000,
    baselineGroup: BaselineGroup.oilService,
  );
  static const _airFilter = TemplateItem(
    code: 'air_filter',
    nameEn: 'Air filter',
    nameAr: 'فلتر الهواء',
    severity: Severity.minor,
    intervalMonths: 24,
    intervalKm: 30000,
  );
  static const _cabinFilter = TemplateItem(
    code: 'cabin_filter',
    nameEn: 'Cabin filter',
    nameAr: 'فلتر المكيف',
    severity: Severity.minor,
    intervalMonths: 12,
    intervalKm: 15000,
  );
  static const _brakes = TemplateItem(
    code: 'brake_pads',
    nameEn: 'Brakes',
    nameAr: 'الفرامل',
    severity: Severity.critical,
    intervalMonths: 24,
    intervalKm: 40000,
    baselineGroup: BaselineGroup.brakes,
  );
  static const _brakeFluid = TemplateItem(
    code: 'brake_fluid',
    nameEn: 'Brake fluid',
    nameAr: 'زيت الفرامل',
    severity: Severity.critical,
    intervalMonths: 24,
  );
  static const _tires = TemplateItem(
    code: 'tire_rotation',
    nameEn: 'Tires and rotation',
    nameAr: 'الإطارات والتبديل',
    severity: Severity.critical,
    intervalMonths: 6,
    intervalKm: 10000,
    baselineGroup: BaselineGroup.tires,
  );
  static const _coolant = TemplateItem(
    code: 'coolant',
    nameEn: 'Coolant',
    nameAr: 'سائل التبريد',
    severity: Severity.major,
    intervalMonths: 48,
    intervalKm: 80000,
  );
  static const _battery = TemplateItem(
    code: 'battery',
    nameEn: 'Battery',
    nameAr: 'البطارية',
    severity: Severity.major,
    intervalMonths: 36,
    baselineGroup: BaselineGroup.battery,
  );
  static const _wipers = TemplateItem(
    code: 'wipers',
    nameEn: 'Wiper blades',
    nameAr: 'مساحات الزجاج',
    severity: Severity.minor,
    intervalMonths: 12,
  );
  static const _timingBelt = TemplateItem(
    code: 'timing_belt',
    nameEn: 'Timing belt',
    nameAr: 'سير التوقيت',
    severity: Severity.major,
    intervalMonths: 72,
    intervalKm: 100000,
  );
  static const _inspection = TemplateItem(
    code: 'inspection',
    nameEn: 'General inspection',
    nameAr: 'الفحص العام',
    severity: Severity.minor,
    intervalMonths: 12,
  );

  static const templates = <FuelType, MaintenanceTemplate>{
    FuelType.petrol: MaintenanceTemplate(
      fuelType: FuelType.petrol,
      version: 1,
      items: [
        _oil, _oilFilter, _airFilter, _cabinFilter, _brakes, _brakeFluid, //
        _tires, _coolant, _battery, _wipers, _timingBelt, _inspection,
      ],
    ),
    FuelType.diesel: MaintenanceTemplate(
      fuelType: FuelType.diesel,
      version: 1,
      items: [
        _oil, _oilFilter, _airFilter, _cabinFilter, _brakes, _brakeFluid, //
        _tires, _coolant, _battery, _wipers, _timingBelt, _inspection,
        TemplateItem(
          code: 'fuel_filter',
          nameEn: 'Fuel filter',
          nameAr: 'فلتر الوقود',
          severity: Severity.minor,
          intervalMonths: 24,
          intervalKm: 30000,
        ),
      ],
    ),
    // Hybrids: longer oil interval, timing chain instead of a belt.
    FuelType.hybrid: MaintenanceTemplate(
      fuelType: FuelType.hybrid,
      version: 1,
      items: [
        TemplateItem(
          code: 'engine_oil',
          nameEn: 'Engine oil',
          nameAr: 'زيت المحرك',
          severity: Severity.major,
          intervalMonths: 12,
          intervalKm: 15000,
          baselineGroup: BaselineGroup.oilService,
        ),
        _oilFilter, _airFilter, _cabinFilter, _brakes, _brakeFluid, //
        _tires, _coolant, _battery, _wipers, _inspection,
      ],
    ),
    // EVs: no engine items. "Oil or service" sets the general inspection.
    FuelType.ev: MaintenanceTemplate(
      fuelType: FuelType.ev,
      version: 1,
      items: [
        TemplateItem(
          code: 'inspection',
          nameEn: 'General inspection',
          nameAr: 'الفحص العام',
          severity: Severity.minor,
          intervalMonths: 12,
          intervalKm: 20000,
          baselineGroup: BaselineGroup.oilService,
        ),
        _cabinFilter,
        TemplateItem(
          code: 'brake_pads',
          nameEn: 'Brakes',
          nameAr: 'الفرامل',
          severity: Severity.critical,
          intervalMonths: 36,
          intervalKm: 60000,
          baselineGroup: BaselineGroup.brakes,
        ),
        _brakeFluid,
        _tires,
        TemplateItem(
          code: 'coolant',
          nameEn: 'Battery coolant',
          nameAr: 'سائل تبريد البطارية',
          severity: Severity.major,
          intervalMonths: 60,
          intervalKm: 100000,
        ),
        _battery,
        _wipers,
      ],
    ),
  };

  /// Newer published versions (FR-REF-06). Petrol v2 shortens the filter
  /// and battery intervals for hot, dusty conditions, so the sample Patrol
  /// (on v1) is offered "Typical intervals updated".
  static final updates = <FuelType, MaintenanceTemplate>{
    FuelType.petrol: MaintenanceTemplate(
      fuelType: FuelType.petrol,
      version: 2,
      changeSummaryEn: 'Shorter air filter, cabin filter and battery intervals for hot, dusty conditions.',
      changeSummaryAr: 'فترات أقصر لفلتر الهواء وفلتر المكيف والبطارية بسبب الحرارة والغبار.',
      items: [
        for (final item in templates[FuelType.petrol]!.items)
          switch (item.code) {
            'air_filter' => _with(item, months: 12, km: 20000),
            'cabin_filter' => _with(item, months: 12, km: 10000),
            'battery' => _with(item, months: 24),
            _ => item,
          },
      ],
    ),
  };

  static TemplateItem _with(TemplateItem item, {int? months, int? km}) => TemplateItem(
    code: item.code,
    nameEn: item.nameEn,
    nameAr: item.nameAr,
    severity: item.severity,
    intervalMonths: months ?? item.intervalMonths,
    intervalKm: km ?? item.intervalKm,
    baselineGroup: item.baselineGroup,
  );
}
