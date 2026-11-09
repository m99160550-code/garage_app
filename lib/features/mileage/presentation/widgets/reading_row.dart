import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/format/app_formatters.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../onboarding/presentation/country/country_labels.dart';
import '../../../settings/domain/distance_unit.dart';
import '../../../vehicles/domain/vehicle_validation.dart';
import '../../domain/odometer_reading.dart';

(String, IconData) readingSourceLabel(AppLocalizations l10n, ReadingSource source) => switch (source) {
  ReadingSource.manual => (l10n.mileageSourceManual, Icons.edit_outlined),
  ReadingSource.service => (l10n.mileageSourceService, Icons.build_outlined),
  ReadingSource.fuel => (l10n.mileageSourceFuel, Icons.local_gas_station_outlined),
  ReadingSource.setup => (l10n.mileageSourceSetup, Icons.flag_outlined),
};

/// "54,900 km" in the user's unit, Western digits (BR-SET-05).
String readingDistance(AppLocalizations l10n, int km, DistanceUnit unit) =>
    '${const AppFormatters(languageCode: 'en').formatOdometer(fromKilometres(km, unit))} ${distanceUnitLabel(l10n, unit)}';

/// One reading (spec S-13 item 4): the value, the date, the source and a
/// "Correction" badge. Manual readings swipe towards the start edge to
/// delete; service readings explain how to remove them instead (item 5).
/// Screen readers get the same as a "Delete" action.
class ReadingRow extends StatelessWidget {
  const ReadingRow({
    super.key,
    required this.reading,
    required this.unit,
    required this.onDelete,
    required this.onServiceHint,
    this.onReview,
  });

  final OdometerReading reading;
  final DistanceUnit unit;

  /// Confirms and deletes; returns whether it was deleted.
  final Future<bool> Function() onDelete;

  /// Explains that a service reading is removed with its record.
  final VoidCallback onServiceHint;

  /// Opens S-33 for a reading flagged Needs review (BR-SYN-03).
  final VoidCallback? onReview;

  bool get _deletable => reading.source == ReadingSource.manual;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final (sourceLabel, sourceIcon) = readingSourceLabel(l10n, reading.source);
    final value = readingDistance(l10n, reading.km, unit);
    final date = AppFormatters(languageCode: language).mediumDate(reading.date);

    final row = Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadii.row),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: AppTextStyles.tabular(text.titleM)),
                Wrap(
                  spacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(date, style: text.bodyS.copyWith(color: colors.textSecondary)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(sourceIcon, size: 14, color: colors.textTertiary),
                        const SizedBox(width: AppSpacing.xxs),
                        Flexible(
                          child: Text(sourceLabel, style: text.bodyS.copyWith(color: colors.textTertiary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (reading.needsReview)
            Flexible(
              child: InkWell(
                onTap: onReview,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
                  child: Center(
                    child: StatusBadge(
                      label: l10n.reviewNeedsReview,
                      tone: BadgeTone.warning,
                      icon: Icons.error_outline,
                    ),
                  ),
                ),
              ),
            )
          else if (reading.isCorrection)
            Flexible(
              child: StatusBadge(label: l10n.mileageCorrection, tone: BadgeTone.info, icon: Icons.edit_note),
            ),
        ],
      ),
    );

    final semantic = [
      l10n.mileageRowSemantic(value, date, sourceLabel),
      if (reading.needsReview) l10n.reviewNeedsReview else if (reading.isCorrection) l10n.mileageCorrection,
    ].join(', ');

    return Semantics(
      label: semantic,
      button: reading.needsReview,
      onTap: reading.needsReview ? onReview : null,
      excludeSemantics: true,
      customSemanticsActions: {if (_deletable) CustomSemanticsAction(label: l10n.actionDelete): onDelete},
      child: Dismissible(
        key: ValueKey(reading.id),
        // Towards the start edge (right to left in English).
        direction: reading.source == ReadingSource.manual || reading.source == ReadingSource.service
            ? DismissDirection.endToStart
            : DismissDirection.none,
        confirmDismiss: (_) async {
          if (!_deletable) {
            onServiceHint();
            return false;
          }
          return onDelete();
        },
        background: Container(
          alignment: AlignmentDirectional.centerEnd,
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.lg),
          decoration: BoxDecoration(
            color: _deletable ? colors.dangerContainer : colors.infoContainer,
            borderRadius: BorderRadius.circular(AppRadii.row),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _deletable ? Icons.delete_outline : Icons.info_outline,
                color: _deletable ? colors.onDangerContainer : colors.onInfoContainer,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  _deletable ? l10n.actionDelete : l10n.mileageSourceService,
                  style: text.label.copyWith(color: _deletable ? colors.onDangerContainer : colors.onInfoContainer),
                ),
              ),
            ],
          ),
        ),
        child: row,
      ),
    );
  }
}
