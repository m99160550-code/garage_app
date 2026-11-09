import 'package:flutter/material.dart';

import '../../../../core/format/app_formatters.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_list_row.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../maintenance/domain/item_due.dart';
import '../../../onboarding/presentation/country/country_labels.dart';
import '../../../settings/domain/distance_unit.dart';
import '../../../vehicles/domain/vehicle_validation.dart';

/// "Upcoming" on iPad landscape (spec S-09 "Responsive"): the next 4
/// schedule items, each opening its detail (S-15).
class UpcomingList extends StatelessWidget {
  const UpcomingList({super.key, required this.items, required this.today, required this.unit, required this.onItem});

  final List<ItemDue> items;
  final DateTime today;
  final DistanceUnit unit;
  final ValueChanged<ItemDue> onItem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    if (items.isEmpty) return const SizedBox.shrink();

    String subtitle(ItemDue due) {
      if (due.status == ItemStatus.overdue) return l10n.upcomingOverdueDays(due.daysOverdue);
      final days = due.daysUntil(today);
      if (days != null) return l10n.upcomingInDays(days);
      final km = const AppFormatters(languageCode: 'en').formatOdometer(fromKilometres(due.kmRemaining ?? 0, unit));
      return l10n.upcomingInDistance('$km ${distanceUnitLabel(l10n, unit)}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(l10n.upcomingTitle, style: context.text.titleM)),
        const SizedBox(height: AppSpacing.sm),
        for (final due in items) ...[
          AppListRow(
            title: due.item.name(language),
            subtitle: subtitle(due),
            trailing: switch (due.status) {
              ItemStatus.overdue => StatusBadge(
                label: l10n.statusOverdue,
                tone: BadgeTone.danger,
                icon: Icons.error_outline,
              ),
              ItemStatus.dueSoon => StatusBadge(
                label: l10n.statusDueSoon,
                tone: BadgeTone.warning,
                icon: Icons.schedule,
              ),
              _ => StatusBadge(label: l10n.statusOk, tone: BadgeTone.success, icon: Icons.check),
            },
            onTap: () => onItem(due),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}
