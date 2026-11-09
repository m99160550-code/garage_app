import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/chrome_text.dart';
import '../../../core/widgets/navigation/floating_nav_bar.dart';
import '../../garage/application/current_vehicle_controller.dart';
import '../../privacy/application/consent_providers.dart';
import '../../service_history/presentation/widgets/service_record_row.dart';
import '../application/spend_view.dart';

/// S-19 This year spend (UI/UX spec S-19, FR-EXP-01, FR-EXP-02): the
/// year's total in the active currency and the records behind it, with a
/// year selector (no future years).
class SpendScreen extends ConsumerStatefulWidget {
  const SpendScreen({super.key});

  /// Content never gets wider than this on tablets (spec 2.3).
  static const maxContentWidth = 720.0;

  @override
  ConsumerState<SpendScreen> createState() => _SpendScreenState();
}

class _SpendScreenState extends ConsumerState<SpendScreen> {
  /// `null` until the first build: this year.
  int? _year;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vehicleId = ref.watch(currentVehicleProvider).value;
    final year = _year ?? ref.watch(clockProvider)().year;
    final view = vehicleId == null ? null : ref.watch(spendViewProvider((vehicleId, year)));
    // Keep the last data on screen while another year loads.
    final data = view?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.spendTitle, style: context.text.titleM),
        centerTitle: true,
        backgroundColor: context.colors.bgBase,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: context.colors.bgBase,
      body: data == null
          ? const DelayedSkeleton()
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: SpendScreen.maxContentWidth),
                child: _content(data, year),
              ),
            ),
    );
  }

  Widget _content(SpendView data, int year) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final format = AppFormatters(languageCode: language);
    final summary = data.summary;
    final yearText = '$year';
    final first = data.years.first;
    final total = format.money(summary.totalMinor, summary.currency);
    final count = l10n.spendServicesInYear(summary.serviceCount, yearText);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.xs,
        AppSpacing.screenMargin,
        FloatingNavBarInset.of(context) + AppSpacing.xl,
      ),
      children: [
        // 2. Year selector: "‹ 2026 ›".
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: l10n.spendPreviousYear,
              onPressed: year > first ? () => setState(() => _year = year - 1) : null,
              // Chevrons flip in Arabic by themselves (matchTextDirection).
              icon: const Icon(Icons.chevron_left),
            ),
            SizedBox(
              width: 88,
              child: Semantics(
                liveRegion: true,
                child: Text(yearText, style: text.titleM, textAlign: TextAlign.center),
              ),
            ),
            IconButton(
              tooltip: l10n.spendNextYear,
              onPressed: year < data.currentYear ? () => setState(() => _year = year + 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // 3. Total card.
        Semantics(
          container: true,
          label: l10n.spendTotalSemantic(yearText, total, count),
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: ChromeText(total, style: text.displayStat, maxLines: 1),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(count, style: text.bodyS.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
        ),
        // 4. Other currencies (BR-EXP-03).
        if (summary.hasOtherCurrencies) ...[
          const SizedBox(height: AppSpacing.sm),
          AppBanner(
            message: l10n.spendOtherCurrencies,
            action: AppButton.text(
              label: l10n.spendChangeCurrency,
              onPressed: () => context.push(AppRoutes.settingsCurrency),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        // 5. Records with a cost in that year, or the empty state.
        if (summary.records.isEmpty)
          _Empty(year: yearText)
        else ...[
          Text(l10n.spendRecords.toUpperCase(), style: text.overline.copyWith(color: colors.textTertiary)),
          const SizedBox(height: AppSpacing.xs),
          for (final record in summary.records) ...[
            ServiceRecordRow(
              record: record,
              title: serviceRecordTitle(l10n, record, itemNames: data.itemNames, languageCode: language),
              unit: data.unit,
              excluded: !summary.isIncluded(record),
              onTap: () => context.push(AppRoutes.garageRecord(record.id)),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ],
    );
  }
}

/// "No costs logged in 2026" with "Log service" (spec S-19 "Empty state").
class _Empty extends StatelessWidget {
  const _Empty({required this.year});

  final String year;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppEmptyState(
      icon: Icons.receipt_long_outlined,
      title: l10n.spendEmpty(year),
      action: AppButton(label: l10n.actionLogService, onPressed: () => context.push(AppRoutes.logService())),
    );
  }
}
