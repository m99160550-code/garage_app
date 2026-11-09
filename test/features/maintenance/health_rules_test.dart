import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/maintenance/domain/dashboard_summary.dart';
import 'package:tdc_garage/features/maintenance/domain/health_score.dart';
import 'package:tdc_garage/features/maintenance/domain/item_due.dart';
import 'package:tdc_garage/features/maintenance/domain/schedule_item.dart';
import 'package:tdc_garage/features/maintenance/domain/severity.dart';
import 'package:tdc_garage/features/settings/domain/distance_unit.dart';

final _today = DateTime(2026, 11, 7);

ScheduleItem _item(
  String code, {
  Severity severity = Severity.major,
  int? months,
  int? km,
  DateTime? doneDate,
  int? doneKm,
  DateTime? snoozedUntil,
  bool notApplicable = false,
}) => ScheduleItem(
  id: code,
  vehicleId: 'v',
  code: code,
  nameEn: code,
  nameAr: code,
  severity: severity,
  intervalMonths: months,
  intervalKm: km,
  lastDoneDate: doneDate,
  lastDoneKm: doneKm,
  snoozedUntil: snoozedUntil,
  notApplicable: notApplicable,
);

ItemDue _due(ScheduleItem item, {int currentKm = 50000, double? dailyKm, DateTime? odometerDate}) => computeItemDue(
  item,
  currentKm: currentKm,
  today: _today,
  unit: DistanceUnit.km,
  dailyKm: dailyKm,
  odometerDate: odometerDate,
);

void main() {
  group('due point (BR-MNT-01 to BR-MNT-05)', () {
    test('no baseline, or a baseline without a matching interval, is Unknown', () {
      expect(_due(_item('a', months: 12)).status, ItemStatus.unknown);
      expect(_due(_item('b', months: 12, doneKm: 40000)).status, ItemStatus.unknown);
    });

    test('whichever comes first: date or mileage (BR-MNT-01)', () {
      final due = _due(_item('oil', months: 12, km: 10000, doneDate: DateTime(2026, 6, 1), doneKm: 45000));
      expect(due.nextDueDate, DateTime(2027, 6, 1));
      expect(due.nextDueKm, 55000);
      expect(due.status, ItemStatus.ok);
    });

    test('overdue by date: past the due date, counted from it (BR-MNT-02)', () {
      final due = _due(_item('oil', months: 12, doneDate: DateTime(2025, 10, 28)));
      expect(due.status, ItemStatus.overdue);
      expect(due.overdueSince, DateTime(2026, 10, 28));
      expect(due.daysOverdue, 10);
    });

    test('overdue by mileage: from the reading that crossed it (BR-MNT-02)', () {
      final due = _due(_item('oil', km: 10000, doneKm: 39000), currentKm: 50000, odometerDate: DateTime(2026, 11, 1));
      expect(due.status, ItemStatus.overdue);
      expect(due.kmOverdue, 1000);
      expect(due.daysOverdue, 6);
    });

    test('due today is due soon, not overdue', () {
      final due = _due(_item('oil', months: 12, doneDate: DateTime(2025, 11, 7)));
      expect(due.status, ItemStatus.dueSoon);
      expect(due.daysUntil(_today), 0);
    });

    test('due soon within 30 days by date (BR-MNT-03)', () {
      expect(_due(_item('a', months: 12, doneDate: DateTime(2025, 12, 7))).status, ItemStatus.dueSoon);
      expect(_due(_item('b', months: 12, doneDate: DateTime(2025, 12, 8))).status, ItemStatus.ok);
    });

    test('due soon by predicted date when there is a daily distance (BR-MNT-04)', () {
      final due = _due(_item('oil', km: 10000, doneKm: 42000), currentKm: 50000, dailyKm: 100);
      expect(due.predictedDueDate, DateTime(2026, 11, 27));
      expect(due.status, ItemStatus.dueSoon);
    });

    test('without a prediction, 1,000 km or less left is due soon (BR-MNT-05)', () {
      expect(_due(_item('a', km: 10000, doneKm: 41000), currentKm: 50000).status, ItemStatus.dueSoon);
      expect(_due(_item('b', km: 10000, doneKm: 41001), currentKm: 50000).status, ItemStatus.ok);
    });
  });

  group('not applicable and progress (FR-MNT-05, S-14)', () {
    test('a not-applicable item is ignored by the score, the pill and next service', () {
      final na = _due(_item('wipers', months: 12, doneDate: DateTime(2025, 1, 1), notApplicable: true));
      expect(na.status, ItemStatus.notApplicable);
      expect(computeHealthScore([na], unit: DistanceUnit.km).score, 100);
      expect(computeHealthScore([na], unit: DistanceUnit.km).unknownCount, 0);
      expect(computeNextService([na], today: _today), isA<NoScheduleYet>());
      expect(pickAlert([na], today: _today), isA<AllGoodAlert>());
    });

    test('progress is the larger of time and distance used', () {
      final due = _due(
        _item('oil', months: 12, km: 10000, doneDate: DateTime(2026, 5, 7), doneKm: 40000),
        currentKm: 48000,
      );
      expect(due.progress(today: _today, currentKm: 48000), closeTo(0.8, 0.001));
      final byTime = _due(_item('battery', months: 12, doneDate: DateTime(2026, 5, 7)));
      expect(byTime.progress(today: _today, currentKm: 0), closeTo(184 / 365, 0.001));
      expect(_due(_item('x', months: 12)).progress(today: _today, currentKm: 0), isNull);
    });
  });

  group('health score (BR-HLT-01 to BR-HLT-06)', () {
    test('starts at 100 and ignores Unknown items', () {
      final health = computeHealthScore([_due(_item('a', months: 12))], unit: DistanceUnit.km);
      expect(health.score, 100);
      expect(health.band, HealthBand.excellent);
      expect(health.unknownCount, 1);
      expect(health.basedOnTypicalIntervals, isTrue);
    });

    test('overdue costs 15 / 10 / 5 by severity; due soon costs 2', () {
      final dues = [
        _due(_item('brakes', severity: Severity.critical, months: 12, doneDate: DateTime(2025, 10, 28))),
        _due(_item('oil', severity: Severity.major, months: 12, doneDate: DateTime(2025, 10, 28))),
        _due(_item('wipers', severity: Severity.minor, months: 12, doneDate: DateTime(2025, 10, 28))),
        _due(_item('coolant', months: 12, doneDate: DateTime(2025, 11, 20))),
      ];
      final health = computeHealthScore(dues, unit: DistanceUnit.km);
      expect(health.score, 100 - 15 - 10 - 5 - 2);
      expect(health.deductions.first.points, -15, reason: 'largest first');
      expect(health.band, HealthBand.needsAttention);
    });

    test('more than 30 days or 1,000 km overdue counts double (BR-HLT-02)', () {
      final byDays = _due(_item('oil', months: 12, doneDate: DateTime(2025, 9, 1)));
      final byKm = _due(_item('oil2', km: 10000, doneKm: 38000), currentKm: 50000);
      final health = computeHealthScore([byDays, byKm], unit: DistanceUnit.km);
      expect(health.score, 100 - 20 - 20);
    });

    test('doubled deductions are flagged for the "×2" badge', () {
      final health = computeHealthScore([
        _due(_item('oil', months: 12, doneDate: DateTime(2025, 9, 1))),
      ], unit: DistanceUnit.km);
      expect(health.deductions.single.doubled, isTrue);
      expect(health.overdue, hasLength(1));
    });

    test('snoozing pauses a due-soon deduction, never an overdue one (BR-HLT-05)', () {
      final snoozedSoon = _due(
        _item('a', months: 12, doneDate: DateTime(2025, 11, 20), snoozedUntil: DateTime(2026, 11, 20)),
      );
      final snoozedOverdue = _due(
        _item('b', months: 12, doneDate: DateTime(2025, 10, 30), snoozedUntil: DateTime(2026, 11, 20)),
      );
      final ended = _due(_item('c', months: 12, doneDate: DateTime(2025, 11, 20), snoozedUntil: DateTime(2026, 11, 7)));
      expect(snoozedSoon.snoozed, isTrue);
      expect(ended.snoozed, isFalse, reason: 'the snooze ends on its date');
      final health = computeHealthScore([snoozedSoon, snoozedOverdue, ended], unit: DistanceUnit.km);
      expect(health.score, 100 - 10 - 2);
      expect(pickAlert([snoozedSoon], today: _today), isNot(isA<DueSoonAlert>()));
    });

    test('never below zero, and the bands', () {
      final dues = [
        for (var i = 0; i < 5; i++)
          _due(_item('x$i', severity: Severity.critical, months: 1, doneDate: DateTime(2025, 1, 1))),
      ];
      expect(computeHealthScore(dues, unit: DistanceUnit.km).score, 0);
      expect(
        [bandFor(90), bandFor(89), bandFor(70), bandFor(69), bandFor(50), bandFor(49)],
        [
          HealthBand.excellent,
          HealthBand.good,
          HealthBand.good,
          HealthBand.needsAttention,
          HealthBand.needsAttention,
          HealthBand.urgent,
        ],
      );
    });
  });

  group('alert pill priority (BR-MNT-09)', () {
    final overdueMinor = _due(_item('wipers', severity: Severity.minor, months: 12, doneDate: DateTime(2025, 9, 1)));
    final overdueCritical = _due(
      _item('brakes', severity: Severity.critical, months: 12, doneDate: DateTime(2025, 10, 30)),
    );
    final soonLater = _due(_item('oil', months: 12, doneDate: DateTime(2025, 12, 1)));
    final soonFirst = _due(_item('battery', months: 12, doneDate: DateTime(2025, 11, 20)));
    final unknown = _due(_item('coolant', months: 12));

    test('overdue first, most severe first', () {
      final alert = pickAlert([soonFirst, overdueMinor, overdueCritical, unknown], today: _today) as OverdueAlert;
      expect(alert.items.map((d) => d.item.code), ['brakes', 'wipers']);
    });

    test('then the soonest due-soon item', () {
      final alert = pickAlert([soonLater, soonFirst, unknown], today: _today) as DueSoonAlert;
      expect(alert.item.item.code, 'battery');
    });

    test('then Unknown items, then stale mileage, then All good', () {
      expect(pickAlert([unknown], today: _today), isA<UnknownItemsAlert>());
      final ok = _due(_item('oil', months: 12, doneDate: DateTime(2026, 6, 1)));
      final stale = pickAlert([ok], today: _today, odometerDate: DateTime(2026, 10, 1));
      expect((stale as StaleMileageAlert).days, 37);
      expect(pickAlert([ok], today: _today, odometerDate: DateTime(2026, 10, 20)), isA<AllGoodAlert>());
    });
  });

  group('next service card', () {
    test('nothing known: set up your schedule (BR-MNT-11)', () {
      expect(computeNextService([_due(_item('a', months: 12))], today: _today), isA<NoScheduleYet>());
    });

    test('overdue shows the most overdue days and the overdue count', () {
      final next = computeNextService([
        _due(_item('a', months: 12, doneDate: DateTime(2025, 11, 1))),
        _due(_item('b', months: 12, doneDate: DateTime(2025, 10, 1))),
      ], today: _today) as NextServiceOverdue;
      expect(next.days, 37);
      expect(next.itemCount, 2);
    });

    test('otherwise the soonest date and how many items share it', () {
      final next = computeNextService([
        _due(_item('a', months: 12, doneDate: DateTime(2025, 12, 15))),
        _due(_item('b', months: 6, doneDate: DateTime(2026, 6, 15))),
        _due(_item('c', months: 12, doneDate: DateTime(2026, 3, 1))),
      ], today: _today) as NextServiceOn;
      expect(next.date, DateTime(2026, 12, 15));
      expect(next.days, 38);
      expect(next.itemCount, 2);
    });

    test('mileage-only items without a prediction show the distance', () {
      final next = computeNextService([_due(_item('a', km: 10000, doneKm: 44680))], today: _today) as NextServiceInKm;
      expect(next.km, 4680);
    });
  });
}
