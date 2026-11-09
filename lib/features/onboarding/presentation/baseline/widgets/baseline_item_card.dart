import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/widgets/app_choice_chip.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../maintenance/domain/baseline_group.dart';
import '../../../../maintenance/presentation/baseline_group_visuals.dart';
import 'baseline_fields.dart';

/// One baseline question (spec S-07 item 4): icon and item name, date and
/// mileage fields, and an "I don't know" chip that disables the fields and
/// shows the "Unknown" badge.
class BaselineItemCard extends StatelessWidget {
  const BaselineItemCard({
    super.key,
    required this.group,
    required this.date,
    required this.onPickDate,
    required this.mileageController,
    required this.mileageFocus,
    required this.unitLabel,
    required this.unknown,
    required this.onUnknownChanged,
    this.mileageError,
  });

  final BaselineGroup group;
  final DateTime? date;
  final VoidCallback onPickDate;
  final TextEditingController mileageController;
  final FocusNode mileageFocus;
  final String unitLabel;
  final String? mileageError;
  final bool unknown;
  final ValueChanged<bool> onUnknownChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final name = baselineGroupLabel(l10n, group);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.baselineCardSemantic(name),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: colors.surfaceRaised, borderRadius: BorderRadius.circular(12)),
                  child: ExcludeSemantics(
                    child: Icon(
                      baselineGroupIcon(group),
                      size: 22,
                      color: unknown ? colors.textTertiary : colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(name, style: context.text.titleM)),
                if (unknown) ...[
                  const SizedBox(width: AppSpacing.xs),
                  StatusBadge(label: l10n.baselineUnknownBadge, icon: Icons.help_outline),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DateAndMileageFields(
              dateLabel: l10n.baselineDateLabel,
              dateText: formatFieldDate(context, date),
              onPickDate: onPickDate,
              mileageLabel: l10n.baselineMileageLabel,
              mileageController: mileageController,
              mileageFocus: mileageFocus,
              unitLabel: unitLabel,
              mileageError: unknown ? null : mileageError,
              enabled: !unknown,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppChoiceChip(
                label: l10n.baselineDontKnow,
                selected: unknown,
                onTap: () {
                  final next = !unknown;
                  onUnknownChanged(next);
                  SemanticsService.sendAnnouncement(
                    View.of(context),
                    next ? l10n.baselineUnknownAnnounce(name) : l10n.baselineKnownAnnounce(name),
                    Directionality.of(context),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
