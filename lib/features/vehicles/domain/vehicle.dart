import 'package:flutter/foundation.dart';

import 'body_type.dart';
import 'fuel_type.dart';
import 'paint_color.dart';

/// How the schedule got its starting point (architecture `setup_mode`).
enum SetupMode { baseline, newCar }

/// A vehicle in the user's garage (architecture 2.6 `vehicles`).
@immutable
class Vehicle {
  const Vehicle({
    required this.id,
    required this.fuelType,
    required this.bodyType,
    required this.odometerKm,
    this.brandId,
    this.brandOtherName,
    this.modelId,
    this.modelOtherName,
    this.nickname,
    this.year,
    this.paint = PaintColor.fallback,
    this.vin,
    this.licencePlate,
    this.purchaseDate,
    this.odometerUpdatedAt,
    this.setupMode = SetupMode.baseline,
    this.templateVersion = 1,
  });

  final String id;
  final String? brandId;
  final String? brandOtherName;
  final String? modelId;
  final String? modelOtherName;
  final String? nickname;
  final int? year;
  final FuelType fuelType;
  final BodyType bodyType;
  final PaintColor paint;
  final String? vin;
  final String? licencePlate;
  final DateTime? purchaseDate;

  /// Latest odometer reading, in kilometres.
  final int odometerKm;

  /// When [odometerKm] was read ("Updated 4 days ago", stale after 30 days).
  final DateTime? odometerUpdatedAt;

  final SetupMode setupMode;

  /// The template version the schedule was generated from (FR-REF-05).
  final int templateVersion;
}
