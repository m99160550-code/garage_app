import 'package:flutter/foundation.dart';

/// Where a reading came from (FR-MIL-03, architecture `reading_source`).
enum ReadingSource { manual, service, fuel, setup }

/// One odometer reading (architecture 2.8 `odometer_readings`).
@immutable
class OdometerReading {
  const OdometerReading({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.km,
    this.source = ReadingSource.manual,
    this.isCorrection = false,
    this.needsReview = false,
    this.device,
  });

  final String id;
  final String vehicleId;
  final DateTime date;

  /// Always kilometres (BR-MIL-06).
  final int km;
  final ReadingSource source;

  /// A lower value the user confirmed (BR-MIL-02). It replaces the current
  /// value and restarts the average (BR-MIL-05).
  final bool isCorrection;

  /// Synced from another device and lower than an earlier reading
  /// (BR-SYN-03): kept in history, never the current value, until the user
  /// resolves it in S-33.
  final bool needsReview;

  /// The device that entered it ("iPad"), when it came through sync.
  final String? device;

  OdometerReading copyWith({bool? isCorrection, bool? needsReview}) => OdometerReading(
    id: id,
    vehicleId: vehicleId,
    date: date,
    km: km,
    source: source,
    isCorrection: isCorrection ?? this.isCorrection,
    needsReview: needsReview ?? this.needsReview,
    device: device,
  );
}
