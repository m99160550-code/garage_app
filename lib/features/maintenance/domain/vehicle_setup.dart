import 'package:flutter/foundation.dart';

import 'baseline_group.dart';

/// The answer to one baseline question (FR-MNT-03): a date, a mileage,
/// both, or "I don't know".
@immutable
class BaselineAnswer {
  const BaselineAnswer({this.date, this.km, this.unknown = false});

  const BaselineAnswer.unknown() : this(unknown: true);

  final DateTime? date;

  /// Always kilometres (BR-MIL-06).
  final int? km;

  /// The user tapped "I don't know".
  final bool unknown;

  /// Unknown when the user said so, or left both fields empty
  /// ("Skip anything you don't know").
  bool get isUnknown => unknown || (date == null && km == null);
}

/// How the schedule gets its starting point (architecture `setup_mode`).
sealed class VehicleSetup {
  const VehicleSetup();
}

/// Four baseline answers. Groups without an answer are Unknown.
final class BaselineSetup extends VehicleSetup {
  const BaselineSetup(this.answers);

  final Map<BaselineGroup, BaselineAnswer> answers;

  BaselineAnswer answerFor(BaselineGroup group) => answers[group] ?? const BaselineAnswer.unknown();
}

/// "My car is new" (FR-MNT-15): every item starts from the delivery.
final class NewCarSetup extends VehicleSetup {
  const NewCarSetup({required this.deliveryDate, required this.startingKm});

  final DateTime deliveryDate;

  /// Always kilometres.
  final int startingKm;
}
