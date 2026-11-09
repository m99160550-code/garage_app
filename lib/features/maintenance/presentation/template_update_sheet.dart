import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/status_badge.dart';
import '../../settings/domain/distance_unit.dart';
import '../application/template_update_controller.dart';
import '../domain/template_update.dart';
import 'item_visuals.dart';

/// Opens S-17 for [update] and carries out the choice: "Apply" updates the
/// schedule and shows "Schedule updated"; "Keep current" hides the prompt
/// for this version. Dismissing the sheet changes nothing.
Future<void> reviewTemplateUpdate(
  BuildContext context,
  WidgetRef ref, {
  required TemplateUpdate update,
  required DistanceUnit unit,
}) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showAppSheet<_Choice>(
    context: context,
    heightFactor: 0.7,
    tabletMaxHeight: 680,
    builder: (_) => TemplateUpdateSheet(update: update, unit: unit),
  );
  final actions = ref.read(templateUpdateActionsProvider);
  switch (choice) {
    case _Choice.apply:
      await actions.apply(update);
      if (context.mounted) showAppToast(context, l10n.templateUpdateApplied);
    case _Choice.keep:
      await actions.keepCurrent(update);
    case null:
      break;
  }
}

enum _Choice { apply, keep }

/// S-17 Template update (UI/UX spec S-17, FR-REF-06, BR-REF-02): the
/// reviewer's summary, a row per changed item (edited items greyed out
/// with "Kept: you edited this"), the review note, then "Apply" and
/// "Keep current".
class TemplateUpdateSheet extends StatelessWidget {
  const TemplateUpdateSheet({super.key, required this.update, required this.unit});

  final TemplateUpdate update;
  final DistanceUnit unit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    // Changes Apply will make come first; kept ones follow.
    final changes = [...update.changes.where((c) => !c.kept), ...update.changes.where((c) => c.kept)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
            children: [
              // 1. Title and summary.
              Semantics(header: true, child: Text(l10n.templateUpdateTitle, style: text.titleL)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                update.to.changeSummary(language) ?? l10n.templateUpdateDefaultSummary,
                style: text.body.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              // 2. Changes list.
              for (final change in changes) ...[
                TemplateChangeRow(change: change, unit: unit),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (update.applicableCount == 0) ...[
                const SizedBox(height: AppSpacing.xs),
                AppBanner(message: l10n.templateUpdateNothingToApply),
              ],
              const SizedBox(height: AppSpacing.sm),
              // 3. Review note (BR-REF-03: typical intervals, not official).
              Row(
                children: [
                  Icon(Icons.verified_outlined, size: 16, color: colors.textTertiary),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      l10n.templateUpdateNote(update.to.version),
                      style: text.caption.copyWith(color: colors.textTertiary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 4. Actions, pinned under the list.
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(label: l10n.templateUpdateApply, onPressed: () => Navigator.of(context).pop(_Choice.apply)),
              const SizedBox(height: AppSpacing.xs),
              AppButton.secondary(
                label: l10n.templateUpdateKeep,
                onPressed: () => Navigator.of(context).pop(_Choice.keep),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One changed item: icon tile, name, and a line per change ("Every 24 →
/// 12 months", "30,000 → 20,000 km", "Importance: Major → Critical").
/// Kept items use tertiary text (still readable) and the "Kept" badge.
class TemplateChangeRow extends StatelessWidget {
  const TemplateChangeRow({super.key, required this.change, required this.unit});

  final TemplateItemChange change;
  final DistanceUnit unit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final before = change.before;
    final after = change.after;
    final muted = change.kept;
    final detailColor = muted ? colors.textTertiary : colors.textSecondary;

    final lines = [
      if (change.isNew)
        l10n.templateUpdateNewItem(
          scheduleIntervalText(l10n, months: after.intervalMonths, km: after.intervalKm, unit: unit),
        ),
      if (change.monthsChanged)
        before!.intervalMonths != null && after.intervalMonths != null
            ? l10n.templateUpdateMonths(before.intervalMonths!, after.intervalMonths!)
            : scheduleIntervalText(l10n, months: after.intervalMonths, unit: unit),
      if (change.kmChanged)
        before!.intervalKm != null && after.intervalKm != null
            ? l10n.templateUpdateDistance(
                scheduleDistance(l10n, before.intervalKm!, unit),
                scheduleDistance(l10n, after.intervalKm!, unit),
              )
            : scheduleIntervalText(l10n, km: after.intervalKm, unit: unit),
      if (change.severityChanged)
        l10n.templateUpdateSeverity(severityLabel(l10n, before!.severity), severityLabel(l10n, after.severity)),
    ];

    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: muted ? colors.bgSheet : colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadii.row),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadii.input),
              ),
              child: Icon(scheduleItemIcon(change.code), size: 22, color: detailColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    after.name(language),
                    style: text.titleM.copyWith(color: muted ? colors.textSecondary : colors.textPrimary),
                  ),
                  for (final line in lines) ...[
                    const SizedBox(height: 2),
                    Text(line, style: text.bodyS.copyWith(color: detailColor)),
                  ],
                  if (muted) ...[
                    const SizedBox(height: AppSpacing.xs),
                    StatusBadge(label: l10n.templateUpdateKept, icon: Icons.lock_outline),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
