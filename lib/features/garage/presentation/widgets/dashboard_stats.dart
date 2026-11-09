import 'package:flutter/material.dart';

import '../../../../core/format/app_formatters.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../maintenance/domain/dashboard_summary.dart';
import '../../../onboarding/presentation/country/country_labels.dart';
import '../../../settings/domain/distance_unit.dart';
import '../../../vehicles/domain/vehicle_validation.dart';
import '../../application/dashboard_data.dart';

/// What one stat card shows (spec S-09 "Stat card anatomy").
class DashboardStat {
  const DashboardStat({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.footer,
    required this.semanticLabel,
    required this.onTap,
    this.unit,
    this.valueColor,
    this.sublabelIcon,
  });

  final String label;
  final String sublabel;
  final String value;
  final String? unit;
  final String footer;
  final Color? valueColor;
  final IconData? sublabelIcon;
  final String semanticLabel;
  final VoidCallback onTap;
}

/// Where each card leads.
class DashboardStatActions {
  const DashboardStatActions({
    required this.updateMileage,
    required this.nextService,
    required this.setUpSchedule,
    required this.spend,
  });

  final VoidCallback updateMileage;
  final VoidCallback nextService;
  final VoidCallback setUpSchedule;
  final VoidCallback spend;
}

/// Mileage · Next service · This year, in that order.
List<DashboardStat> buildDashboardStats({
  required AppLocalizations l10n,
  required AppColors colors,
  required String languageCode,
  required DashboardData data,
  required DashboardStatActions actions,
  int? displayedOdometerKm,
}) {
  final unitLabel = distanceUnitLabel(l10n, data.unit);
  final unitWord = data.unit == DistanceUnit.km ? l10n.unitKmWord : l10n.unitMiWord;
  // Odometer values always use Western digits (BR-SET-05).
  const western = AppFormatters(languageCode: 'en');
  String semantic(String label, String value, String sublabel, String footer) =>
      l10n.statCardSemantic(label, value, sublabel, footer);

  // Mileage.
  // During the count-up after an update, the value in between.
  final mileage = western.formatOdometer(fromKilometres(displayedOdometerKm ?? data.vehicle.odometerKm, data.unit));
  final mileageFooter = data.daysSinceReading == null ? '' : l10n.statUpdated(data.daysSinceReading!);

  // Next service (spec S-09 "Next service value variants").
  final next = data.nextService;
  final (String value, String sublabel, String footer, Color? color, IconData? icon, VoidCallback tap) = switch (next) {
    NoScheduleYet() => ('—', l10n.statSetUpSchedule, '', colors.textSecondary, null, actions.setUpSchedule),
    NextServiceOverdue(:final days, :final itemCount) => (
      AppFormatters(languageCode: languageCode).integer(days),
      l10n.statDaysOverdue,
      l10n.statItems(itemCount),
      colors.danger,
      Icons.error_outline,
      actions.nextService,
    ),
    NextServiceOn(:final date, :final days, :final itemCount) => (
      days == 0 ? l10n.statToday : AppFormatters(languageCode: languageCode).integer(days),
      days == 0 ? l10n.statDue : l10n.statDaysAway,
      l10n.statDateItems(AppFormatters(languageCode: languageCode).shortDate(date), l10n.statItems(itemCount)),
      days == 0 ? colors.warning : null,
      null,
      actions.nextService,
    ),
    NextServiceInKm(:final km, :final itemCount) => (
      western.formatOdometer(fromKilometres(km, data.unit)),
      l10n.statDistanceToGo(unitLabel),
      l10n.statItems(itemCount),
      null,
      null,
      actions.nextService,
    ),
  };

  // This year.
  final spend = data.spend;
  final money = AppFormatters(languageCode: languageCode).money(spend.totalMinor, spend.currency);
  final spendFooter = spend.hasOtherCurrencies ? l10n.statSomeNotIncluded : l10n.statServices(spend.serviceCount);

  return [
    DashboardStat(
      label: l10n.statMileage,
      sublabel: l10n.statMileageSub,
      value: mileage,
      unit: unitLabel,
      footer: mileageFooter,
      semanticLabel: semantic(l10n.statMileage, mileage, unitWord, mileageFooter),
      onTap: actions.updateMileage,
    ),
    DashboardStat(
      label: l10n.statNextService,
      sublabel: sublabel,
      value: value,
      footer: footer,
      valueColor: color,
      sublabelIcon: icon,
      semanticLabel: semantic(l10n.statNextService, value, sublabel, footer),
      onTap: tap,
    ),
    DashboardStat(
      label: l10n.statThisYear,
      sublabel: l10n.statSpent,
      value: money,
      footer: spendFooter,
      semanticLabel: semantic(l10n.statThisYear, money, l10n.statSpent, spendFooter),
      onTap: actions.spend,
    ),
  ];
}
