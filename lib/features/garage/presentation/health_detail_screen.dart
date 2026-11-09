import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/chrome_text.dart';
import '../../../core/widgets/navigation/floating_nav_bar.dart';
import '../../maintenance/domain/health_score.dart';
import '../../maintenance/domain/item_due.dart';
import '../../onboarding/presentation/country/country_labels.dart';
import '../../settings/domain/distance_unit.dart';
import '../../vehicles/domain/vehicle_validation.dart';
import '../../vehicles/presentation/vehicle_labels.dart';
import '../application/current_vehicle_controller.dart';
import '../application/dashboard_data.dart';
import 'widgets/deduction_row.dart';
import 'widgets/health_score_block.dart';
import 'widgets/score_explainer_card.dart';

/// S-11 Health score detail (UI/UX spec S-11): what lowers the score and
/// how to fix it (FR-HLT-03, FR-HLT-06). Each row opens its item (S-15).
///
/// Phones: a full page. Tablets: a 420 pt side sheet (see the router).
class HealthDetailScreen extends ConsumerStatefulWidget {
  const HealthDetailScreen({super.key, this.sideSheet = false});

  /// Shown as a side sheet over the dashboard: a close button instead of
  /// back, and no room for the floating bar.
  final bool sideSheet;

  @override
  ConsumerState<HealthDetailScreen> createState() => _HealthDetailScreenState();
}

class _HealthDetailScreenState extends ConsumerState<HealthDetailScreen> {
  final _scroll = ScrollController();

  /// The bar title appears once the summary header has scrolled away.
  bool _showBarTitle = false;
  static const _headerHeight = 160.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final show = _scroll.offset > _headerHeight;
      if (show != _showBarTitle) setState(() => _showBarTitle = show);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vehicleId = ref.watch(currentVehicleProvider).value;
    final data = vehicleId == null ? null : ref.watch(dashboardDataProvider(vehicleId)).value;
    final bottom = widget.sideSheet || !WindowClass.of(context).isCompact
        ? AppSpacing.xl
        : FloatingNavBar.contentClearance + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: widget.sideSheet ? context.colors.bgSheet : null,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: widget.sideSheet ? context.colors.bgSheet : context.colors.bgBase,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leading: widget.sideSheet
                ? IconButton(tooltip: l10n.actionClose, icon: const Icon(Icons.close), onPressed: () => context.pop())
                : const BackButton(),
            centerTitle: true,
            title: AnimatedOpacity(
              opacity: _showBarTitle ? 1 : 0,
              duration: AppMotion.quick,
              child: Text(l10n.healthScoreLabel, style: context.text.titleM),
            ),
          ),
          if (data != null)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(AppSpacing.screenMargin, 0, AppSpacing.screenMargin, bottom),
              sliver: SliverList.list(children: _content(data)),
            ),
        ],
      ),
    );
  }

  List<Widget> _content(DashboardData data) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final health = data.health;
    final notCounted = data.dues
        .where((d) => d.status == ItemStatus.unknown || (d.status == ItemStatus.dueSoon && d.snoozed))
        .toList();

    Widget subheading(String value) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Semantics(
        header: true,
        child: Text(value.toUpperCase(), style: text.overline.copyWith(color: colors.textTertiary)),
      ),
    );
    Widget section(String value) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Semantics(header: true, child: Text(value, style: text.titleL)),
    );

    return [
      _SummaryHeader(health: health, sentence: _sentence(health)),
      if (health.deductions.isNotEmpty) ...[
        section(l10n.healthSectionLowering),
        if (health.overdue.isNotEmpty) ...[
          subheading(l10n.statusOverdue),
          for (final d in health.overdue) _deductionRow(d, data),
        ],
        if (health.dueSoon.isNotEmpty) ...[
          subheading(l10n.statusDueSoon),
          for (final d in health.dueSoon) _deductionRow(d, data),
        ],
      ],
      if (notCounted.isNotEmpty) ...[
        section(l10n.healthSectionNotCounted),
        const SizedBox(height: AppSpacing.xs),
        for (final due in notCounted)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: () {
              final name = due.item.name(language);
              final reason = due.status == ItemStatus.unknown
                  ? l10n.healthUnknownSetLastDone
                  : l10n.healthSnoozedUntil(AppFormatters(languageCode: language).shortDate(due.item.snoozedUntil!));
              return ScoreRow(
                tone: ScoreRowTone.info,
                title: name,
                reason: reason,
                semanticLabel: '$name, $reason',
                onTap: () =>
                    context.push(AppRoutes.garageItem(due.item.code, setLastDone: due.status == ItemStatus.unknown)),
              );
            }(),
          ),
      ],
      const SizedBox(height: AppSpacing.xl),
      ScoreExplainerCard(
        templateLine: l10n.healthTemplateLine(fuelTypeLabel(l10n, data.vehicle.fuelType), data.vehicle.templateVersion),
        onSeeSchedule: () => context.push(AppRoutes.garageSchedule),
      ),
    ];
  }

  /// "1 item is overdue and 3 items are due within 30 days."
  String _sentence(HealthScore health) {
    final l10n = AppLocalizations.of(context);
    final overdue = health.overdue.length;
    final soon = health.dueSoon.length;
    if (overdue == 0 && soon == 0) return l10n.healthNothingLowering;
    if (overdue > 0 && soon > 0) {
      return l10n.healthSummaryJoin(l10n.healthSummaryOverdue(overdue), l10n.healthSummarySoon(soon));
    }
    return l10n.healthSummarySentence(overdue > 0 ? l10n.healthSummaryOverdue(overdue) : l10n.healthSummarySoon(soon));
  }

  Widget _deductionRow(Deduction deduction, DashboardData data) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final due = deduction.due;
    final name = due.item.name(language);
    final reason = _reason(due, data.unit, data.today);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ScoreRow(
        tone: due.status == ItemStatus.overdue ? ScoreRowTone.danger : ScoreRowTone.warning,
        title: name,
        reason: reason,
        points: deduction.points,
        doubled: deduction.doubled,
        semanticLabel: [
          l10n.healthRowSemantic(name, reason, deduction.points.abs()),
          if (deduction.doubled) l10n.healthCountsDouble,
        ].join(', '),
        onTap: () => context.push(AppRoutes.garageItem(due.item.code)),
      ),
    );
  }

  /// "Overdue by 12 days", "Due in 12 days", "Due in about 800 km".
  String _reason(ItemDue due, DistanceUnit unit, DateTime today) {
    final l10n = AppLocalizations.of(context);
    String distance(int km) =>
        '${const AppFormatters(languageCode: 'en').formatOdometer(fromKilometres(km, unit))} ${distanceUnitLabel(l10n, unit)}';
    if (due.status == ItemStatus.overdue) {
      return due.overdueByDate || due.kmOverdue == 0
          ? l10n.upcomingOverdueDays(due.daysOverdue)
          : l10n.healthReasonOverdueKm(distance(due.kmOverdue));
    }
    final days = due.daysUntil(today);
    final km = due.kmRemaining;
    // A mileage that comes first is the more useful reason.
    if (km != null && (days == null || (days > 30 && km <= dueSoonFallbackKm(unit)))) {
      return l10n.healthReasonDueInKm(distance(km));
    }
    return l10n.healthReasonDueInDays(days ?? 0);
  }
}

/// The score, its band and the plain-language sentence (spec S-11 item 2).
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.health, required this.sentence});

  final HealthScore health;
  final String sentence;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final bandColor = switch (health.band) {
      HealthBand.excellent || HealthBand.good => colors.success,
      HealthBand.needsAttention => colors.warning,
      HealthBand.urgent => colors.danger,
    };
    final empty = health.deductions.isEmpty;

    return Semantics(
      container: true,
      label: '${l10n.healthSemantic(health.score, healthBandLabel(l10n, health.band))}. $sentence',
      excludeSemantics: true,
      child: Column(
        children: [
          if (empty) ...[
            const SizedBox(height: AppSpacing.md),
            Icon(Icons.verified_outlined, size: 56, color: colors.success),
          ],
          MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChromeText('${health.score}', style: AppTextStyles.tabular(text.displayScore), decorative: true),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: ChromeText('%', style: text.titleL, decorative: true),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: bandColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(healthBandLabel(l10n, health.band), style: text.label),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            sentence,
            style: (empty ? text.titleM : text.body).copyWith(color: empty ? colors.textPrimary : colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
