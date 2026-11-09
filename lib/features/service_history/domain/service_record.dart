import 'package:flutter/foundation.dart';

/// The kind of service (architecture 2.9 `service_type`).
enum ServiceType { maintenance, repair, inspection, other }

/// One logged service (architecture 2.9 `service_records`). Money is a
/// whole number of the currency's smallest unit plus the currency code
/// (AD-07); cost and currency are both set or both empty.
@immutable
class ServiceRecord {
  const ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.type,
    required this.createdAt,
    this.odometerKm,
    this.costMinor,
    this.currency,
    this.shopName,
    this.notes,
    this.itemCodes = const [],
  }) : assert((costMinor == null) == (currency == null), 'Cost and currency go together');

  final String id;
  final String vehicleId;

  /// The service date (never in the future, BR-SVC-01).
  final DateTime date;
  final ServiceType type;
  final int? odometerKm;
  final int? costMinor;
  final String? currency;
  final String? shopName;
  final String? notes;

  /// The schedule items it covered (`service_record_items`), by code.
  final List<String> itemCodes;
  final DateTime createdAt;

  bool get hasCost => costMinor != null;
}
