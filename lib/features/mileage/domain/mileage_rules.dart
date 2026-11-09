import '../../settings/domain/distance_unit.dart';
import 'odometer_reading.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Readings that count: not waiting for review (BR-SYN-03).
List<OdometerReading> _settled(List<OdometerReading> readings) => [
  for (final r in readings)
    if (!r.needsReview) r,
];
int _days(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// The current reading: the latest date; on the same date the higher one,
/// unless a correction was saved, which always wins (BR-MIL-01, BR-MIL-02).
/// Readings waiting for review never count (BR-SYN-03).
OdometerReading? currentReading(List<OdometerReading> readings) {
  final usable = _settled(readings);
  if (usable.isEmpty) return null;
  final sorted = [...usable]
    ..sort((a, b) {
      final byDate = _day(a.date).compareTo(_day(b.date));
      if (byDate != 0) return byDate;
      if (a.isCorrection != b.isCorrection) return a.isCorrection ? 1 : -1;
      return a.km.compareTo(b.km);
    });
  return sorted.last;
}

/// A daily jump above this asks "Is this correct?" (BR-MIL-03):
/// 5,000 km, or 3,000 mi for mile users.
int bigJumpKmPerDay(DistanceUnit unit) => unit == DistanceUnit.km ? 5000 : 4828;

/// What a new reading needs before it's saved (spec S-12 "Validation").
sealed class ReadingCheck {
  const ReadingCheck();
}

/// Higher than or equal to the current reading, at a believable pace.
final class ReadingOk extends ReadingCheck {
  const ReadingOk();
}

/// Lower than the current reading: confirm it as a correction (BR-MIL-02).
final class ReadingLower extends ReadingCheck {
  const ReadingLower(this.current);

  final OdometerReading current;
}

/// More than the daily limit since the last reading (BR-MIL-03).
final class ReadingBigJump extends ReadingCheck {
  const ReadingBigJump({required this.km, required this.days});

  final int km;

  /// At least 1.
  final int days;
}

ReadingCheck checkNewReading({
  required int newKm,
  required OdometerReading? current,
  required DateTime today,
  required DistanceUnit unit,
}) {
  if (current == null) return const ReadingOk();
  if (newKm < current.km) return ReadingLower(current);
  final days = _days(current.date, today).clamp(1, 1 << 30);
  final km = newKm - current.km;
  if (km > bigJumpKmPerDay(unit) * days) return ReadingBigJump(km: km, days: days);
  return const ReadingOk();
}

/// Readings used for the average: the last 180 days (BR-MIL-05).
const averageWindowDays = 180;

/// The two readings must be at least this far apart (BR-MIL-05).
const averageMinSpanDays = 14;

/// Average distance per day for predictions (FR-MIL-04, BR-MIL-05), or
/// `null` when there aren't 2 readings at least 14 days apart in the last
/// 180 days since the latest correction.
double? averageDailyKm(List<OdometerReading> readings, {required DateTime today}) {
  final windowStart = _day(today).subtract(const Duration(days: averageWindowDays));
  final sorted = [..._settled(readings)]..sort((a, b) => a.date.compareTo(b.date));
  final lastCorrection = sorted.lastIndexWhere((r) => r.isCorrection);
  final usable = sorted
      .skip(lastCorrection < 0 ? 0 : lastCorrection)
      .where((r) => !_day(r.date).isBefore(windowStart))
      .toList();
  if (usable.length < 2) return null;
  final first = usable.first;
  final last = usable.last;
  final span = _days(first.date, last.date);
  if (span < averageMinSpanDays || last.km <= first.km) return null;
  return (last.km - first.km) / span;
}

/// Average days in a month, for "1,240 km / month".
const daysPerMonth = 30.44;

/// Days until a second reading would give an average (BR-MIL-05), for
/// "Add another reading in 14 days". 0 means the next reading will.
int daysUntilAverage(List<OdometerReading> readings, {required DateTime today}) {
  final windowStart = _day(today).subtract(const Duration(days: averageWindowDays));
  final sorted = [..._settled(readings)]..sort((a, b) => a.date.compareTo(b.date));
  final lastCorrection = sorted.lastIndexWhere((r) => r.isCorrection);
  final usable = sorted
      .skip(lastCorrection < 0 ? 0 : lastCorrection)
      .where((r) => !_day(r.date).isBefore(windowStart))
      .toList();
  if (usable.isEmpty) return averageMinSpanDays;
  final waited = _days(usable.first.date, today);
  return (averageMinSpanDays - waited).clamp(0, averageMinSpanDays);
}

/// A synced reading is flagged when it is lower than a reading with an
/// earlier date (BR-SYN-03, UC-02 5c).
bool needsReviewOnSync(List<OdometerReading> readings, OdometerReading incoming) =>
    _settled(readings).any((r) => _day(r.date).isBefore(_day(incoming.date)) && r.km > incoming.km);

/// A flagged reading and the earlier, higher reading it conflicts with,
/// for the two S-33 cards.
typedef ReadingConflict = ({OdometerReading earlier, OdometerReading flagged});

/// The conflicts to review, oldest first. The earlier reading is the
/// highest one dated before the flagged reading.
List<ReadingConflict> readingConflicts(List<OdometerReading> readings) {
  final settled = _settled(readings);
  final conflicts = <ReadingConflict>[];
  for (final flagged in readings.where((r) => r.needsReview)) {
    final earlier = settled.where((r) => _day(r.date).isBefore(_day(flagged.date)) && r.km > flagged.km).toList()
      ..sort((a, b) => a.km.compareTo(b.km));
    if (earlier.isNotEmpty) conflicts.add((earlier: earlier.last, flagged: flagged));
  }
  conflicts.sort((a, b) => a.flagged.date.compareTo(b.flagged.date));
  return conflicts;
}
