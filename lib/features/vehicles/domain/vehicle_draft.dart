import 'package:flutter/foundation.dart';

import 'body_type.dart';
import 'vehicle_details.dart';

/// The vehicle being set up across S-04 to S-07, before it's saved.
/// Each step adds its part.
@immutable
class VehicleDraft {
  const VehicleDraft({
    this.brandId,
    this.brandOtherName,
    this.modelId,
    this.modelOtherName,
    this.bodyType,
    this.details,
  });

  /// A brand from the dataset, or…
  final String? brandId;

  /// …a brand typed under "Other brand" (BR-VEH-07). Only one is set.
  final String? brandOtherName;

  /// A model from the dataset, or…
  final String? modelId;

  /// …a model typed under "Other model". Only one is set.
  final String? modelOtherName;

  /// From the chosen model, or picked for "Other model" (FR-VEH-06).
  final BodyType? bodyType;

  /// The answers from S-06, once given.
  final VehicleDetails? details;

  bool get hasBrand => brandId != null || (brandOtherName?.trim().isNotEmpty ?? false);

  bool get hasModel => (modelId != null || (modelOtherName?.trim().isNotEmpty ?? false)) && bodyType != null;
}
