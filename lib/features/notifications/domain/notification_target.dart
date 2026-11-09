import 'package:flutter/foundation.dart';

/// Where tapping a reminder lands (FR-NOT-04, spec S-35 "Deep link"). The
/// link is `/garage?vehicle=…` plus the target, so the dashboard first
/// shows the right vehicle.
sealed class NotificationTarget {
  const NotificationTarget(this.vehicleId);

  final String vehicleId;

  /// The deep link; [stamp] makes each delivery's link unique, so tapping
  /// the same reminder twice opens it twice.
  String link({String? stamp}) {
    final query = {'vehicle': vehicleId, ..._query, 'n': ?stamp};
    return Uri(path: '/garage', queryParameters: query).toString();
  }

  Map<String, String> get _query;

  /// Reads a deep link's query; `null` for an ordinary dashboard visit.
  static NotificationTarget? fromQuery(Map<String, String> query) {
    final vehicle = query['vehicle'];
    if (vehicle == null || vehicle.isEmpty) return null;
    if (query['item'] case final code? when code.isNotEmpty) return OpenItem(vehicle, code);
    if (query['items'] case final codes? when codes.isNotEmpty) return OpenBundle(vehicle, codes.split(','));
    if (query['mileage'] == '1') return OpenMileage(vehicle);
    return null;
  }
}

/// A single item: S-15.
final class OpenItem extends NotificationTarget {
  const OpenItem(super.vehicleId, this.code);

  final String code;

  @override
  Map<String, String> get _query => {'item': code};

  @override
  bool operator ==(Object other) => other is OpenItem && other.vehicleId == vehicleId && other.code == code;

  @override
  int get hashCode => Object.hash(vehicleId, code);
}

/// Several items: the bundle sheet.
final class OpenBundle extends NotificationTarget {
  const OpenBundle(super.vehicleId, this.codes);

  final List<String> codes;

  @override
  Map<String, String> get _query => {'items': codes.join(',')};

  @override
  bool operator ==(Object other) =>
      other is OpenBundle && other.vehicleId == vehicleId && listEquals(other.codes, codes);

  @override
  int get hashCode => Object.hash(vehicleId, Object.hashAll(codes));
}

/// The mileage nudge: S-12 Update mileage.
final class OpenMileage extends NotificationTarget {
  const OpenMileage(super.vehicleId);

  @override
  Map<String, String> get _query => {'mileage': '1'};

  @override
  bool operator ==(Object other) => other is OpenMileage && other.vehicleId == vehicleId;

  @override
  int get hashCode => vehicleId.hashCode;
}
