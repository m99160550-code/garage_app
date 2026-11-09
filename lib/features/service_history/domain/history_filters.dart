import 'package:flutter/foundation.dart';

import 'service_record.dart';

/// The S-20 filters: a year and a type, `null` meaning "all".
@immutable
class HistoryFilters {
  const HistoryFilters({this.year, this.type});

  final int? year;
  final ServiceType? type;

  bool get isSet => year != null || type != null;

  bool matches(ServiceRecord record) =>
      (year == null || record.date.year == year) && (type == null || record.type == type);

  HistoryFilters withYear(int? value) => HistoryFilters(year: value, type: type);
  HistoryFilters withType(ServiceType? value) => HistoryFilters(year: year, type: value);
}

/// The years that have records, newest first (the "Year" sheet).
List<int> recordYears(List<ServiceRecord> records) =>
    records.map((r) => r.date.year).toSet().toList()..sort((a, b) => b.compareTo(a));

/// Records grouped by calendar month, newest month first and newest record
/// first within a month (spec S-20 item 4).
List<(DateTime month, List<ServiceRecord> records)> groupByMonth(List<ServiceRecord> records) {
  final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
  final groups = <(DateTime, List<ServiceRecord>)>[];
  for (final record in sorted) {
    final month = DateTime(record.date.year, record.date.month);
    if (groups.isEmpty || groups.last.$1 != month) groups.add((month, []));
    groups.last.$2.add(record);
  }
  return groups;
}
