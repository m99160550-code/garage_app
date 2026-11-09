import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/alert_pill.dart';
import '../../../maintenance/domain/dashboard_summary.dart';

/// The dashboard's one alert pill (spec S-09 item 6, BR-MNT-09).
class DashboardAlertPill extends StatelessWidget {
  const DashboardAlertPill({super.key, required this.alert, required this.onTap});

  final DashboardAlert alert;
  final ValueChanged<DashboardAlert> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final (label, tone, icon) = switch (alert) {
      OverdueAlert(:final items) when items.length == 1 => (
        l10n.alertOverdueOne(items.single.item.name(language)),
        AlertPillTone.danger,
        Icons.warning_amber_rounded,
      ),
      OverdueAlert(:final items) => (
        l10n.alertOverdueMany(items.length),
        AlertPillTone.danger,
        Icons.warning_amber_rounded,
      ),
      MileageReviewAlert() => (l10n.alertMileageReview, AlertPillTone.warning, Icons.speed),
      DueSoonAlert(:final item) => (l10n.alertDueSoon(item.item.name(language)), AlertPillTone.warning, Icons.schedule),
      UnknownItemsAlert(:final count) => (l10n.alertUnknown(count), AlertPillTone.info, Icons.help_outline),
      StaleMileageAlert(:final days) => (l10n.alertStaleMileage(days), AlertPillTone.info, Icons.speed),
      AllGoodAlert() => (l10n.alertAllGood, AlertPillTone.success, Icons.check_circle_outline),
    };
    return AlertPill(label: label, tone: tone, icon: icon, onTap: () => onTap(alert));
  }
}
