import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import 'baseline_fields.dart';

/// "My car is new" (spec S-07 item 3, FR-MNT-15): a toggle that expands
/// to ask for the delivery date and the starting mileage.
class NewCarCard extends StatelessWidget {
  const NewCarCard({
    super.key,
    required this.isNew,
    required this.onChanged,
    required this.deliveryDate,
    required this.onPickDeliveryDate,
    required this.startingMileage,
    required this.startingMileageFocus,
    required this.unitLabel,
    this.deliveryDateError,
    this.startingMileageError,
  });

  final bool isNew;
  final ValueChanged<bool> onChanged;
  final DateTime? deliveryDate;
  final VoidCallback onPickDeliveryDate;
  final String? deliveryDateError;
  final TextEditingController startingMileage;
  final FocusNode startingMileageFocus;
  final String unitLabel;
  final String? startingMileageError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: isNew ? colors.borderStrong : colors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The whole header row toggles, so the target is large.
          MergeSemantics(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => onChanged(!isNew),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 72),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.xs,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_outlined, color: isNew ? colors.accentPrimary : colors.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l10n.newCarTitle, style: text.titleM),
                              const SizedBox(height: 2),
                              Text(l10n.newCarSubtitle, style: text.bodyS.copyWith(color: colors.textSecondary)),
                            ],
                          ),
                        ),
                        Switch.adaptive(value: isNew, onChanged: onChanged, activeTrackColor: colors.accentPrimary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.standard,
            curve: AppMotion.standardCurve,
            alignment: Alignment.topCenter,
            child: !isNew
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                    child: DateAndMileageFields(
                      dateLabel: l10n.deliveryDateLabel,
                      dateText: formatFieldDate(context, deliveryDate),
                      onPickDate: onPickDeliveryDate,
                      dateError: deliveryDateError,
                      mileageLabel: l10n.startingMileageLabel,
                      mileageController: startingMileage,
                      mileageFocus: startingMileageFocus,
                      unitLabel: unitLabel,
                      mileageError: startingMileageError,
                      alwaysStacked: true,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
