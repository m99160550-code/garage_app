import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../garage/application/dashboard_data.dart';
import '../../maintenance/presentation/item_visuals.dart';
import '../../maintenance/presentation/widgets/schedule_item_row.dart';

/// Opens the bundle sheet for a "3 items need attention" reminder (spec
/// S-35, BR-NOT-03): the bundled items, in the order the reminder listed
/// them. Each opens S-15; "Log service" preselects them all.
Future<void> showReminderBundle(BuildContext context, {required String vehicleId, required List<String> codes}) async {
  final location = await showAppSheet<String>(
    context: context,
    fitContent: true,
    tabletMaxWidth: 480,
    builder: (_) => ReminderBundleSheet(vehicleId: vehicleId, codes: codes),
  );
  if (location != null && context.mounted) context.push(location);
}

class ReminderBundleSheet extends ConsumerWidget {
  const ReminderBundleSheet({super.key, required this.vehicleId, required this.codes});

  final String vehicleId;
  final List<String> codes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final data = ref.watch(dashboardDataProvider(vehicleId)).value;
    if (data == null) return const SizedBox(height: 240, child: DelayedSkeleton());

    final items = [for (final code in codes) ?data.dues.where((d) => d.item.code == code).firstOrNull];
    final name = data.vehicle.nickname ?? '${data.brandName(language)} ${data.modelName(language)}'.trim();
    void close([String? location]) => Navigator.of(context).pop(location);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: text.label.copyWith(color: colors.textSecondary)),
              const SizedBox(height: AppSpacing.xxs),
              Semantics(
                header: true,
                child: Text(
                  l10n.notifBundle(items.length, AppFormatters(languageCode: language).integer(items.length)),
                  style: text.titleL,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) {
              final due = items[i];
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
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                label: l10n.nextServiceLog,
                onPressed: () => close(AppRoutes.logService(itemCodes: [for (final d in items) d.item.code])),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton.secondary(label: l10n.nextServiceSeeSchedule, onPressed: () => close(AppRoutes.garageSchedule)),
            ],
          ),
        ),
      ],
    );
  }
}
