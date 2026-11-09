import 'package:flutter/foundation.dart';

import '../../vehicles/domain/body_type.dart';
import '../../vehicles/domain/fuel_type.dart';

/// A model from the in-house dataset (FR-REF-01): 3–4 popular models per
/// brand, each with one body type that picks the illustration.
@immutable
class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.brandId,
    required this.nameEn,
    required this.nameAr,
    required this.bodyType,
    this.defaultFuelType,
  });

  /// Stable slug, for example "toyota-camry".
  final String id;
  final String brandId;
  final String nameEn;
  final String nameAr;
  final BodyType bodyType;

  /// The usual fuel type, prefilled on S-06 (BR-REF-05). Never a limit.
  final FuelType? defaultFuelType;

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  @override
  bool operator ==(Object other) => other is VehicleModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
