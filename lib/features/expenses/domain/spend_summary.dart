import 'package:flutter/foundation.dart';

import '../../service_history/domain/service_record.dart';

/// One calendar year's spend for a vehicle in the active currency
/// (FR-EXP-01, BR-EXP-01, BR-EXP-03). MVP: service costs only.
@immutable
class SpendSummary {
  const SpendSummary({
    required this.year,
    required this.currency,
    required this.totalMinor,
    required this.serviceCount,
    this.records = const [],
    this.hasOtherCurrencies = false,
  });

  final int year;
  final String currency;

  /// The sum of the included records, in the currency's smallest unit.
  final int totalMinor;

  /// Records in the active currency that make up [totalMinor].
  final int serviceCount;

  /// Every record with a cost in [year], newest first, including other
  /// currencies (each shown in its own currency, BR-EXP-05).
  final List<ServiceRecord> records;

  /// Some records in [year] use another currency and aren't in the total
  /// (no conversion, BR-EXP-03).
  final bool hasOtherCurrencies;

  bool isIncluded(ServiceRecord record) => record.currency == currency;
}

/// The spend for [year] (local calendar year, BR-EXP-01): the total adds
/// up only records in [currency] (BR-EXP-03).
SpendSummary summariseSpend(List<ServiceRecord> records, {required int year, required String currency}) {
  final inYear = records.where((r) => r.hasCost && r.date.year == year).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  final included = inYear.where((r) => r.currency == currency).toList();
  return SpendSummary(
    year: year,
    currency: currency,
    totalMinor: included.fold(0, (sum, r) => sum + r.costMinor!),
    serviceCount: included.length,
    records: List.unmodifiable(inYear),
    hasOtherCurrencies: included.length != inYear.length,
  );
}

/// The years the year selector offers (S-19 item 2): from the first year
/// with a cost up to [currentYear], never a future year.
List<int> spendYears(List<ServiceRecord> records, {required int currentYear}) {
  final years = records.where((r) => r.hasCost).map((r) => r.date.year).where((y) => y <= currentYear);
  final first = years.isEmpty ? currentYear : years.reduce((a, b) => a < b ? a : b);
  return [for (var y = first; y <= currentYear; y++) y];
}
