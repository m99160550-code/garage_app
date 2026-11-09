import 'package:flutter/foundation.dart';

import 'body_type.dart';
import 'fuel_type.dart';
import 'paint_color.dart';

/// The answers from S-06 Vehicle details (FR-VEH-06, FR-VEH-07).
@immutable
class VehicleDetails {
  const VehicleDetails({
    required this.fuelType,
    required this.odometerKm,
    required this.paint,
    required this.bodyType,
    this.nickname,
    this.year,
    this.licencePlate,
    this.vin,
    this.purchaseDate,
  });

  // Required.
  final FuelType fuelType;

  /// Always kilometres, whatever unit the user typed in (BR-MIL-06).
  final int odometerKm;

  // Appearance.
  final PaintColor paint;
  final BodyType bodyType;

  // Optional.
  final String? nickname;
  final int? year;
  final String? licencePlate;
  final String? vin;
  final DateTime? purchaseDate;

  VehicleDetails withBodyType(BodyType type) => VehicleDetails(
    fuelType: fuelType,
    odometerKm: odometerKm,
    paint: paint,
    bodyType: type,
    nickname: nickname,
    year: year,
    licencePlate: licencePlate,
    vin: vin,
    purchaseDate: purchaseDate,
  );
}
