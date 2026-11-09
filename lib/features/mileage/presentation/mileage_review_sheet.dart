import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/status_badge.dart';
import '../../settings/domain/distance_unit.dart';
import '../application/mileage_review.dart';
import '../domain/odometer_reading.dart';
import 'widgets/reading_row.dart';

/// Opens S-33 Mileage needs review for one flagged reading (UI/UX spec
/// S-33, BR-SYN-03, UC-02 5c). Entry points: the S-09 alert pill and the
/// S-13 "Needs review" badge.
Future<void> showMileageReview(BuildContext context, {required String vehicleId, required String readingId}) async {
  final l10n = AppLocalizations.of(context);
  final outcome = await showAppSheet<bool>(
    context: context,
    fitContent: true,
    builder: (_) => MileageReviewSheet(vehicleId: vehicleId, readingId: readingId),
  );
  if (outcome == null || !context.mounted) return;
  showAppToast(context, outcome ? l10n.reviewCorrected : l10n.mileageDeleted);
}

/// The sheet: why it's asking, the two readings side by side (stacked
/// with large text or on narrow screens), and the two choices. Pops `true`
/// for "use as a correction", `false` for "delete".
class MileageReviewSheet extends ConsumerStatefulWidget {
  const MileageReviewSheet({super.key, required this.vehicleId, required this.readingId});

  final String vehicleId;
  final String readingId;

  @override
  ConsumerState<MileageReviewSheet> createState() => _MileageReviewSheetState();
}

class _MileageReviewSheetState extends ConsumerState<MileageReviewSheet> {
  bool _busy = false;

  Future<void> _resolve({required bool useAsCorrection}) async {
    setState(() => _busy = true);
    await ref
        .read(mileageReviewActionsProvider)
        .resolve(widget.vehicleId, widget.readingId, useAsCorrection: useAsCorrection);
    if (mounted) Navigator.of(context).pop(useAsCorrection);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final data = ref.watch(mileageReviewProvider((vehicleId: widget.vehicleId, readingId: widget.readingId))).value;
    if (data == null) {
      return const Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: DelayedSkeleton());
    }
    final (:conflict, :unit) = data;
    final flaggedValue = readingDistance(l10n, conflict.flagged.km, unit);
    final stacked = MediaQuery.textScalerOf(context).scale(16) / 16 > 1.3 || MediaQuery.sizeOf(context).width < 360;

    final earlierCard = _ReadingCard(reading: conflict.earlier, unit: unit);
    final flaggedCard = _ReadingCard(reading: conflict.flagged, unit: unit, flagged: true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xs),
                Semantics(header: true, child: Text(l10n.reviewTitle, style: text.titleL)),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.reviewBody, style: text.body.copyWith(color: colors.textSecondary)),
                const SizedBox(height: AppSpacing.lg),
                if (stacked) ...[
                  earlierCard,
                  const SizedBox(height: AppSpacing.sm),
                  flaggedCard,
                ] else
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: earlierCard),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: flaggedCard),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                label: l10n.reviewUseCorrection(flaggedValue),
                isLoading: _busy,
                onPressed: () => _resolve(useAsCorrection: true),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.secondary(
                label: l10n.reviewDelete(flaggedValue),
                onPressed: _busy ? null : () => _resolve(useAsCorrection: false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One reading: the value, the date and where it came from. The flagged
/// one has an amber border and a "Needs review" badge.
class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.reading, required this.unit, this.flagged = false});

  final OdometerReading reading;
  final DistanceUnit unit;
  final bool flagged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final value = readingDistance(l10n, reading.km, unit);
    final date = AppFormatters(languageCode: language).mediumDate(reading.date);
    final device = reading.device ?? l10n.reviewThisDevice;

    return Semantics(
      container: true,
      label: [l10n.reviewCardSemantic(value, date, device), if (flagged) l10n.reviewNeedsReview].join(', '),
      excludeSemantics: true,
      child: Container(
        // The thicker border of the flagged card takes from its padding, so
        // both values line up.
        padding: EdgeInsets.all(AppSpacing.md - (flagged ? 1 : 0)),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadii.row),
          border: Border.all(color: flagged ? colors.warning : colors.borderSubtle, width: flagged ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.tabular(text.titleM)),
            const SizedBox(height: AppSpacing.xxs),
            Text(date, style: text.bodyS.copyWith(color: colors.textSecondary)),
            Row(
              children: [
                Icon(Icons.smartphone, size: 14, color: colors.textTertiary),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(device, style: text.bodyS.copyWith(color: colors.textSecondary)),
                ),
              ],
            ),
            if (flagged) ...[
              const SizedBox(height: AppSpacing.xs),
              StatusBadge(label: l10n.reviewNeedsReview, tone: BadgeTone.warning, icon: Icons.error_outline),
            ],
          ],
        ),
      ),
    );
  }
}
