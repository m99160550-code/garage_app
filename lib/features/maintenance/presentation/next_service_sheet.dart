import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../garage/application/dashboard_data.dart';
import '../domain/dashboard_summary.dart';
import '../domain/item_due.dart';
import 'item_visuals.dart';
import 'widgets/schedule_item_row.dart';

/// Opens S-18 for [vehicleId]. The sheet closes before any navigation, so
/// the next screen opens from the dashboard (S-15, S-22 or S-14).
Future<void> showNextServiceSheet(BuildContext context, {required String vehicleId}) async {
  final location = await showAppSheet<String>(
    context: context,
    fitContent: true,
    tabletMaxWidth: 480,
    builder: (_) => NextServiceSheet(vehicleId: vehicleId),
  );
  if (location != null && context.mounted) context.push(location);
}

/// S-18 Next service (UI/UX spec S-18, US-13): when the next service is,
/// everything due around then, and "Log service" with those items
/// preselected. When something is overdue the title turns red and the
/// overdue items come first.
class NextServiceSheet extends ConsumerWidget {
  const NextServiceSheet({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardDataProvider(vehicleId)).value;
    if (data == null) return const SizedBox(height: 240, child: DelayedSkeleton());
    return _Content(
      data: data,
      group: nextServiceGroup(data.dues, today: data.today),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data, required this.group});

  final DashboardData data;
  final NextServiceGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final dates = AppFormatters(languageCode: language);
    void close([String? location]) => Navigator.of(context).pop(location);

    // 1. Title, the large value and the line under it.
    final title = group.overdue ? l10n.statusOverdue : l10n.statNextService;
    final (String value, String detail) = switch (group) {
      NextServiceGroup(:final overdueDays?) => (
        l10n.nextServiceOverdueDays(overdueDays),
        l10n.statItems(group.items.where((d) => d.status == ItemStatus.overdue).length),
      ),
      NextServiceGroup(:final date?, :final daysAway?) => (dates.weekdayDate(date), l10n.nextServiceInDays(daysAway)),
      NextServiceGroup(:final kmAway?) => (
        l10n.nextServiceInKm(scheduleDistance(l10n, kmAway, data.unit)),
        l10n.nextServiceKmNote,
      ),
      _ => ('—', l10n.nextServiceNothing),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Semantics(
            header: true,
            label: l10n.nextServiceSemantic(title, value, detail),
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.label.copyWith(color: group.overdue ? colors.danger : colors.textSecondary)),
                const SizedBox(height: AppSpacing.xxs),
                Text(value, style: text.titleL.copyWith(color: group.overdue ? colors.danger : colors.textPrimary)),
                const SizedBox(height: 2),
                Text(detail, style: text.bodyS.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
        ),
        // 2. The items due around then (compact S-14 rows, 64 pt).
        if (group.items.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              (group.overdue ? l10n.nextServiceDoNow : l10n.nextServiceDueAround).toUpperCase(),
              style: text.overline.copyWith(color: colors.textTertiary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: group.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, i) {
                final due = group.items[i];
                return ScheduleItemRow(
                  compact: true,
                  due: due,
                  name: due.item.name(language),
                  dueText: scheduleDueText(l10n, due, unit: data.unit, languageCode: language),
                  progress: null,
                  onTap: () => close(AppRoutes.garageItem(due.item.code)),
                );
              },
            ),
          ),
        ],
        // 3. Actions.
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (group.items.isNotEmpty) ...[
                AppButton(
                  label: l10n.nextServiceLog,
                  onPressed: () => close(AppRoutes.logService(itemCodes: [for (final d in group.items) d.item.code])),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              AppButton.secondary(label: l10n.nextServiceSeeSchedule, onPressed: () => close(AppRoutes.garageSchedule)),
            ],
          ),
        ),
      ],
    );
  }
}
