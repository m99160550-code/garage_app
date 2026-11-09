import 'package:flutter/foundation.dart';

import '../../settings/domain/distance_unit.dart';
import 'item_due.dart';
import 'severity.dart';

/// Score bands (BR-HLT-06).
enum HealthBand { excellent, good, needsAttention, urgent }

HealthBand bandFor(int score) => switch (score) {
  >= 90 => HealthBand.excellent,
  >= 70 => HealthBand.good,
  >= 50 => HealthBand.needsAttention,
  _ => HealthBand.urgent,
};

/// Deduction weights by severity (BR-HLT-01). Server-side configuration
/// later (BR-HLT-07); these are the v1 defaults.
@immutable
class ScoreWeights {
  const ScoreWeights({
    this.overdue = const {Severity.critical: 15, Severity.major: 10, Severity.minor: 5},
    this.dueSoon = 2,
  });

  final Map<Severity, int> overdue;
  final int dueSoon;
}

/// One line of the score breakdown (FR-HLT-03).
@immutable
class Deduction {
  const Deduction({required this.due, required this.points, this.doubled = false});

  final ItemDue due;

  /// Negative, for example −15.
  final int points;

  /// Overdue by more than 30 days or 1,000 km (BR-HLT-02): shown as "×2".
  final bool doubled;
}

@immutable
class HealthScore {
  const HealthScore({required this.score, required this.deductions, required this.unknownCount});

  /// 0–100 (BR-HLT-01).
  final int score;
  final List<Deduction> deductions;

  /// Unknown items don't count (BR-HLT-03), but are reported (FR-HLT-05).
  final int unknownCount;

  List<Deduction> get overdue => deductions.where((d) => d.due.status == ItemStatus.overdue).toList();
  List<Deduction> get dueSoon => deductions.where((d) => d.due.status == ItemStatus.dueSoon).toList();

  HealthBand get band => bandFor(score);

  /// "Based on typical intervals" while anything is Unknown (FR-HLT-05).
  bool get basedOnTypicalIntervals => unknownCount > 0;
}

/// Calculates the health score from the items' due points (BR-HLT-01 to
/// BR-HLT-03).
HealthScore computeHealthScore(
  List<ItemDue> dues, {
  required DistanceUnit unit,
  ScoreWeights weights = const ScoreWeights(),
}) {
  final deductions = <Deduction>[];
  for (final due in dues) {
    switch (due.status) {
      case ItemStatus.overdue:
        final base = weights.overdue[due.item.severity]!;
        final doubled = due.daysOverdue > doubleOverdueDays || due.kmOverdue > doubleOverdueKm(unit);
        deductions.add(Deduction(due: due, points: -(doubled ? base * 2 : base), doubled: doubled));
      case ItemStatus.dueSoon:
        // Snoozing pauses only the due-soon deduction (BR-HLT-05).
        if (!due.snoozed) deductions.add(Deduction(due: due, points: -weights.dueSoon));
      case ItemStatus.ok || ItemStatus.unknown || ItemStatus.notApplicable:
        break;
    }
  }
  final total = deductions.fold<int>(0, (sum, d) => sum + d.points);
  deductions.sort((a, b) => a.points.compareTo(b.points));
  return HealthScore(
    score: (100 + total).clamp(0, 100),
    deductions: List.unmodifiable(deductions),
    unknownCount: dues.where((d) => d.status == ItemStatus.unknown).length,
  );
}
