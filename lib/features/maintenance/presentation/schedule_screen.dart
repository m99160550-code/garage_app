import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_choice_chip.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/navigation/floating_nav_bar.dart';
import '../../garage/application/current_vehicle_controller.dart';
import '../../garage/application/dashboard_data.dart';
import '../../vehicles/presentation/vehicle_labels.dart';
import '../application/template_update_controller.dart';
import '../domain/item_due.dart';
import 'item_visuals.dart';
import 'schedule_item_detail.dart';
import 'template_update_sheet.dart';
import 'widgets/schedule_item_row.dart';

/// The filter chips on S-14 (spec S-14 item 4).
enum ScheduleFilter {
  all,
  overdue,
  dueSoon,
  unknown,
  notApplicable;

  static ScheduleFilter fromQuery(String? value) => switch (value) {
    'overdue' => overdue,
    'dueSoon' => dueSoon,
    'unknown' => unknown,
    'notApplicable' => notApplicable,
    _ => all,
  };
}

/// S-14 Maintenance schedule (UI/UX spec S-14): every item with its
/// status, filterable, in sections from Overdue to Not applicable. A row
/// opens the item (S-15). On iPad landscape, the list and the item sit
/// side by side.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key, this.initialFilter = ScheduleFilter.all, this.highlightCode});

  final ScheduleFilter initialFilter;

  /// An item opened from a deep link: its row pulses (spec S-14).
  final String? highlightCode;

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late ScheduleFilter _filter = widget.initialFilter;

  /// The item shown in the iPad detail pane.
  String? _selected;

  static const _sectionOrder = [
    ItemStatus.overdue,
    ItemStatus.dueSoon,
    ItemStatus.ok,
    ItemStatus.unknown,
    ItemStatus.notApplicable,
  ];

  bool _matches(ItemDue due) => switch (_filter) {
    ScheduleFilter.all => true,
    ScheduleFilter.overdue => due.status == ItemStatus.overdue,
    ScheduleFilter.dueSoon => due.status == ItemStatus.dueSoon,
    ScheduleFilter.unknown => due.status == ItemStatus.unknown,
    ScheduleFilter.notApplicable => due.status == ItemStatus.notApplicable,
  };

  /// Sections in spec order, each sorted most urgent first.
  List<(ItemStatus, List<ItemDue>)> _sections(DashboardData data) {
    int urgency(ItemDue d) => switch (d.status) {
      ItemStatus.overdue => -d.daysOverdue,
      _ => d.daysUntil(data.today) ?? (d.kmRemaining ?? 1 << 20),
    };
    return [
      for (final status in _sectionOrder)
        (
          status,
          data.dues.where((d) => d.status == status && _matches(d)).toList()..sort(
            (a, b) => status == ItemStatus.unknown || status == ItemStatus.notApplicable
                ? 0
                : urgency(a).compareTo(urgency(b)),
          ),
        ),
    ].where((s) => s.$2.isNotEmpty).toList();
  }

  void _showTemplateInfo() {
    final l10n = AppLocalizations.of(context);
    showAppSheet<void>(
      context: context,
      fitContent: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(l10n.scheduleTemplateTitle, style: context.text.titleL)),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.scheduleTemplateBody, style: context.text.body.copyWith(color: context.colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vehicleId = ref.watch(currentVehicleProvider).value;
    final data = vehicleId == null ? null : ref.watch(dashboardDataProvider(vehicleId)).value;
    final windowClass = WindowClass.of(context);
    final masterDetail = windowClass == WindowClass.expanded;

    final addButton = IconButton(
      tooltip: l10n.scheduleAddCustom,
      icon: const Icon(Icons.add),
      onPressed: () => context.push(AppRoutes.garageCustomItem),
    );

    if (data == null) return Scaffold(appBar: AppBar(title: Text(l10n.scheduleTitle)));
    final sections = _sections(data);
    final allItems = [for (final s in sections) ...s.$2];
    if (masterDetail && (_selected == null || !allItems.any((d) => d.item.code == _selected))) {
      _selected = widget.highlightCode ?? allItems.firstOrNull?.item.code;
    }

    final list = CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(l10n.scheduleTitle),
          backgroundColor: context.colors.bgBase,
          surfaceTintColor: Colors.transparent,
          actions: [addButton],
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            0,
            AppSpacing.screenMargin,
            windowClass.isCompact
                ? FloatingNavBar.contentClearance + MediaQuery.paddingOf(context).bottom
                : AppSpacing.xl,
          ),
          sliver: SliverList.list(children: _listChildren(data, sections, masterDetail)),
        ),
      ],
    );

    if (!masterDetail) return Scaffold(body: list);

    // iPad landscape: list (40%) and the item (60%).
    final selected = allItems.where((d) => d.item.code == _selected).firstOrNull;
    return Scaffold(
      body: Row(
        children: [
          Expanded(flex: 4, child: list),
          VerticalDivider(width: 1, color: context.colors.borderSubtle),
          Expanded(
            flex: 6,
            child: SafeArea(
              child: selected == null
                  ? Center(child: Text(l10n.scheduleSelectItem, style: context.text.body))
                  : ScheduleItemDetail(code: selected.item.code, embedded: true),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _listChildren(DashboardData data, List<(ItemStatus, List<ItemDue>)> sections, bool masterDetail) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final allOk = !data.dues.any(
      (d) => d.status == ItemStatus.overdue || d.status == ItemStatus.dueSoon || d.status == ItemStatus.unknown,
    );
    int count(ItemStatus status) => data.dues.where((d) => d.status == status).length;
    final update = ref.watch(templateUpdateProvider(data.vehicle.id)).value;

    String sectionTitle(ItemStatus status) => switch (status) {
      ItemStatus.overdue => l10n.statusOverdue,
      ItemStatus.dueSoon => l10n.statusDueSoon,
      ItemStatus.ok => l10n.scheduleUpcoming,
      ItemStatus.unknown => l10n.baselineUnknownBadge,
      ItemStatus.notApplicable => l10n.scheduleNotApplicable,
    };

    final chips = [
      (ScheduleFilter.all, l10n.scheduleFilterAll),
      (ScheduleFilter.overdue, l10n.scheduleFilterCount(l10n.statusOverdue, count(ItemStatus.overdue))),
      (ScheduleFilter.dueSoon, l10n.scheduleFilterCount(l10n.statusDueSoon, count(ItemStatus.dueSoon))),
      (ScheduleFilter.unknown, l10n.scheduleFilterCount(l10n.baselineUnknownBadge, count(ItemStatus.unknown))),
      (
        ScheduleFilter.notApplicable,
        l10n.scheduleFilterCount(l10n.scheduleNotApplicable, count(ItemStatus.notApplicable)),
      ),
    ];

    return [
      // Vehicle subline and template line (spec S-14 items 1–2).
      Text(
        data.vehicle.nickname ?? '${data.brandName(language)} ${data.modelName(language)}'.trim(),
        style: text.bodyS.copyWith(color: colors.textSecondary),
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: InkWell(
          onTap: _showTemplateInfo,
          borderRadius: BorderRadius.circular(AppRadii.input),
          child: ConstrainedBox(
            // 48 pt: Android's minimum for a full-width target.
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 14, color: colors.textTertiary),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    l10n.healthTemplateLine(fuelTypeLabel(l10n, data.vehicle.fuelType), data.vehicle.templateVersion),
                    style: text.caption.copyWith(color: colors.textTertiary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Template update banner (spec S-14 item 3, FR-REF-06).
      if (update != null) ...[
        const SizedBox(height: AppSpacing.xs),
        AppBanner(
          message: l10n.templateUpdateBanner,
          action: AppButton.text(
            label: l10n.templateUpdateReview,
            onPressed: () => reviewTemplateUpdate(context, ref, update: update, unit: data.unit),
          ),
        ),
      ],
      if (allOk) ...[
        const SizedBox(height: AppSpacing.xs),
        AppBanner(message: l10n.scheduleAllGood, tone: BannerTone.success),
      ],
      const SizedBox(height: AppSpacing.sm),
      // Filter chips, single choice, scrolling sideways.
      SizedBox(
        height: AppSpacing.minTouchTarget + 4,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
          itemBuilder: (context, i) => AppChoiceChip(
            label: chips[i].$2,
            selected: _filter == chips[i].$1,
            onTap: () => setState(() => _filter = chips[i].$1),
          ),
        ),
      ),
      if (sections.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Text(l10n.scheduleNothingHere, style: text.body, textAlign: TextAlign.center),
        ),
      for (final (status, items) in sections) ...[
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
          child: Semantics(
            header: true,
            label: l10n.scheduleSectionSemantic(sectionTitle(status), items.length),
            excludeSemantics: true,
            child: Text(
              '${sectionTitle(status).toUpperCase()} · ${items.length}',
              style: text.overline.copyWith(color: colors.textTertiary),
            ),
          ),
        ),
        for (final due in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: ScheduleItemRow(
              key: ValueKey(due.item.code),
              due: due,
              name: due.item.name(language),
              dueText: scheduleDueText(l10n, due, unit: data.unit, languageCode: language),
              progress: due.status == ItemStatus.unknown || due.status == ItemStatus.notApplicable
                  ? null
                  : due.progress(today: data.today, currentKm: data.vehicle.odometerKm),
              highlight: due.item.code == widget.highlightCode,
              selected: masterDetail && due.item.code == _selected,
              onTap: () => masterDetail
                  ? setState(() => _selected = due.item.code)
                  : context.push(AppRoutes.garageItem(due.item.code, setLastDone: due.status == ItemStatus.unknown)),
            ),
          ),
      ],
      const SizedBox(height: AppSpacing.lg),
      AppButton.secondary(label: l10n.scheduleAddCustom, onPressed: () => context.push(AppRoutes.garageCustomItem)),
    ];
  }
}
