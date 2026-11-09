import 'package:flutter/foundation.dart';

import '../../vehicles/domain/fuel_type.dart';
import 'baseline_group.dart';
import 'severity.dart';

/// One item of a maintenance template (architecture 2.7 `template_items`).
@immutable
class TemplateItem {
  const TemplateItem({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.severity,
    this.intervalMonths,
    this.intervalKm,
    this.baselineGroup,
  }) : assert(intervalMonths != null || intervalKm != null, 'An item needs at least one interval');

  /// Stable across template versions, for example `engine_oil`.
  final String code;
  final String nameEn;
  final String nameAr;
  final Severity severity;
  final int? intervalMonths;
  final int? intervalKm;

  /// The onboarding question that sets this item, if any.
  final BaselineGroup? baselineGroup;

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;
}

/// The current published template for one fuel type (FR-REF-04, FR-REF-05).
@immutable
class MaintenanceTemplate {
  const MaintenanceTemplate({
    required this.fuelType,
    required this.version,
    required this.items,
    this.changeSummaryEn,
    this.changeSummaryAr,
  });

  final FuelType fuelType;
  final int version;
  final List<TemplateItem> items;

  /// What changed since the previous version, written by the reviewer
  /// (architecture 2.7 `change_summary_*`, shown in S-17).
  final String? changeSummaryEn;
  final String? changeSummaryAr;

  String? changeSummary(String languageCode) => languageCode == 'ar' ? changeSummaryAr : changeSummaryEn;

  TemplateItem? item(String code) => items.where((i) => i.code == code).firstOrNull;
}
