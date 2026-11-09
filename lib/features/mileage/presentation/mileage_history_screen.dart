import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/navigation/floating_nav_bar.dart';
import '../../garage/application/current_vehicle_controller.dart';
import '../application/mileage_history.dart';
import '../domain/mileage_rules.dart';
import '../domain/odometer_reading.dart';
import 'mileage_review_sheet.dart';
import 'update_mileage_sheet.dart';
import 'widgets/reading_row.dart';

/// S-13 Mileage history (UI/UX spec S-13): the monthly average and every
/// reading, newest first, grouped by month.
class MileageHistoryScreen extends ConsumerWidget {
  const MileageHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vehicleId = ref.watch(currentVehicleProvider).value;
    final history = vehicleId == null ? null : ref.watch(mileageHistoryProvider(vehicleId)).value;
    final windowClass = WindowClass.of(context);
    final bottom = windowClass.isCompact
        ? FloatingNavBar.contentClearance + MediaQuery.paddingOf(context).bottom
        : AppSpacing.xl;

    Widget body() {
      if (history == null || vehicleId == null) return const SizedBox.shrink();
      final summary = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AverageCard(history: history),
          if (history.onlyStartingReading) ...[
            const SizedBox(height: AppSpacing.md),
            _EmptyState(onUpdate: () => showUpdateMileage(context, vehicleId: vehicleId)),
          ],
        ],
      );
      final list = _ReadingList(history: history);

      // iPad landscape: the list at the start, the summary at the end.
      if (windowClass == WindowClass.expanded) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: SingleChildScrollView(child: list)),
              const SizedBox(width: AppSpacing.xl),
              Expanded(flex: 4, child: summary),
            ],
          ),
        );
      }
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(AppSpacing.screenMargin, AppSpacing.xs, AppSpacing.screenMargin, bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                summary,
                const SizedBox(height: AppSpacing.lg),
                list,
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statMileage),
        backgroundColor: context.colors.bgBase,
        surfaceTintColor: Colors.transparent,
      ),
      body: body(),
    );
  }
}

/// "Average · 1,240 km / month · Based on the last 180 days", or how long
/// until there is one (spec S-13 item 2, BR-MIL-05).
class _AverageCard extends StatelessWidget {
  const _AverageCard({required this.history});

  final MileageHistory history;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final daily = history.dailyKm;

    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(Icons.speed, color: colors.textSecondary, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.mileageAverageLabel, style: text.caption.copyWith(color: colors.textTertiary)),
                  if (daily != null) ...[
                    Text(
                      l10n.mileageAveragePerMonth(readingDistance(l10n, (daily * daysPerMonth).round(), history.unit)),
                      style: text.titleL,
                    ),
                    Text(l10n.mileageAverageBasis, style: text.caption.copyWith(color: colors.textTertiary)),
                  ] else
                    Text(
                      l10n.mileageAverageNeedMore(history.daysUntilAverage),
                      style: text.bodyS.copyWith(color: colors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Only your starting reading so far" with "Update mileage".
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onUpdate});

  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppEmptyState(
      icon: Icons.timeline,
      title: l10n.mileageEmptyTitle,
      action: AppButton(label: l10n.mileageTitle, expand: false, onPressed: onUpdate),
    );
  }
}

/// Readings newest first, with a heading per month (spec S-13 item 4).
class _ReadingList extends ConsumerWidget {
  const _ReadingList({required this.history});

  final MileageHistory history;

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref, OdometerReading reading) async {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.mileageDeleteTitle),
        content: Text(
          l10n.mileageDeleteBody(
            readingDistance(l10n, reading.km, history.unit),
            AppFormatters(languageCode: language).mediumDate(reading.date),
          ),
        ),
        actions: [
          AppButton.text(label: l10n.actionCancel, onPressed: () => Navigator.pop(context, false)),
          AppButton.destructiveText(label: l10n.actionDelete, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (confirmed != true) return false;
    await deleteReading(ref, reading);
    if (context.mounted) showAppToast(context, l10n.mileageDeleted);
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final formatters = AppFormatters(languageCode: language);
    final children = <Widget>[];
    String? month;
    for (final reading in history.readings) {
      final heading = formatters.monthYear(reading.date);
      if (heading != month) {
        month = heading;
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
            child: Semantics(
              header: true,
              child: Text(heading, style: context.text.label.copyWith(color: context.colors.textTertiary)),
            ),
          ),
        );
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: ReadingRow(
            reading: reading,
            unit: history.unit,
            onDelete: () => _confirmDelete(context, ref, reading),
            onServiceHint: () => showAppToast(context, l10n.mileageServiceHint),
            onReview: () => showMileageReview(context, vehicleId: reading.vehicleId, readingId: reading.id),
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}
