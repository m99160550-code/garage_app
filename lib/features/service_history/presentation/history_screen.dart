import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_choice_chip.dart';
import '../../../core/widgets/app_dropdown_chip.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/monogram_tile.dart';
import '../../../core/widgets/navigation/floating_nav_bar.dart';
import '../../garage/presentation/vehicle_switcher_sheet.dart';
import '../application/history_view.dart';
import '../domain/history_filters.dart';
import '../domain/service_record.dart';
import 'service_record_screen.dart';
import 'widgets/service_record_row.dart';

/// S-20 Service history (UI/UX spec S-20, FR-SVC-04, FR-SVC-07, US-20):
/// the chosen vehicle's records grouped by month, with Year and Type
/// filters. Phones open a record full screen, iPad portrait in a side
/// sheet, iPad landscape in the detail pane (40/60).
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  /// The list never gets wider than this (spec S-20 "Responsive").
  static const maxListWidth = 720.0;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  HistoryFilters _filters = const HistoryFilters();

  /// The record in the iPad landscape detail pane.
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final vehicleId = ref.watch(historyVehicleIdProvider);
    final view = vehicleId == null ? null : ref.watch(historyViewProvider((vehicleId, language))).value;
    final windowClass = WindowClass.of(context);
    final masterDetail = windowClass == WindowClass.expanded;

    final records = view?.records.where(_filters.matches).toList() ?? const <ServiceRecord>[];
    if (masterDetail && (_selected == null || !records.any((r) => r.id == _selected))) {
      _selected = records.firstOrNull?.id;
    }

    final list = CustomScrollView(
      slivers: [
        // 1. Large title, collapses on scroll; "+" opens S-22.
        SliverAppBar.large(
          title: Text(l10n.historyTitle),
          backgroundColor: context.colors.bgBase,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: l10n.actionLogService,
              icon: const Icon(Icons.add),
              onPressed: () => context.push(AppRoutes.logService()),
            ),
          ],
        ),
        if (view == null)
          _skeleton()
        else ...[
          // 2. Vehicle chip.
          SliverToBoxAdapter(
            child: _padded(
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _VehicleChip(view: view, onTap: () => _pickVehicle(vehicleId)),
              ),
            ),
          ),
          // 3. Filters, pinned while the list scrolls.
          if (view.records.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterBar(child: _padded(_filterRow(view)), color: context.colors.bgBase),
            ),
          // 4. Records by month, or an empty state.
          ..._listSlivers(view, records, masterDetail),
        ],
        SliverToBoxAdapter(
          child: SizedBox(
            height: windowClass.isCompact
                ? FloatingNavBar.contentClearance + MediaQuery.paddingOf(context).bottom
                : AppSpacing.xl,
          ),
        ),
      ],
    );

    if (!masterDetail) {
      return Scaffold(
        backgroundColor: context.colors.bgBase,
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: HistoryScreen.maxListWidth),
            child: list,
          ),
        ),
      );
    }

    // iPad landscape: the list (40%) and the record (60%).
    return Scaffold(
      backgroundColor: context.colors.bgBase,
      body: Row(
        children: [
          Expanded(flex: 4, child: list),
          VerticalDivider(width: 1, color: context.colors.borderSubtle),
          Expanded(
            flex: 6,
            child: _selected == null
                ? Center(child: Text(l10n.historySelectRecord, style: context.text.body))
                : ServiceRecordScreen(key: ValueKey(_selected), recordId: _selected!, embedded: true),
          ),
        ],
      ),
    );
  }

  Widget _padded(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
    child: child,
  );

  Future<void> _pickVehicle(String? current) async {
    final choice = await showVehicleSwitcher(context, currentVehicleId: current, pickerOnly: true);
    if (choice is SwitchToVehicle && choice.vehicleId != current) {
      ref.read(historyVehicleChoiceProvider.notifier).select(choice.vehicleId);
      setState(() {
        _filters = const HistoryFilters();
        _selected = null;
      });
    }
  }

  Widget _filterRow(HistoryView view) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: _FilterBar.height,
      child: Row(
        children: [
          // The chips scroll sideways if they don't fit; "Clear" stays put.
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                AppDropdownChip(
                  label: l10n.historyYearChip(_filters.year?.toString() ?? l10n.historyAllYears),
                  active: _filters.year != null,
                  onTap: () => _chooseYear(view),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppDropdownChip(
                  label: l10n.historyTypeChip(
                    _filters.type == null ? l10n.historyAllTypes : serviceTypeLabel(l10n, _filters.type!),
                  ),
                  active: _filters.type != null,
                  onTap: _chooseType,
                ),
              ],
            ),
          ),
          if (_filters.isSet) ...[
            const SizedBox(width: AppSpacing.xxs),
            AppButton.text(
              label: l10n.historyClear,
              onPressed: () => setState(() => _filters = const HistoryFilters()),
            ),
          ],
        ],
      ),
    );
  }

  /// "Year" sheet: the years with records, plus "All years".
  Future<void> _chooseYear(HistoryView view) async {
    final l10n = AppLocalizations.of(context);
    final years = recordYears(view.records);
    final choice = await _chooseOne<int?>(
      title: l10n.historyChooseYear,
      options: [(null, l10n.historyAllYears), for (final y in years) (y, '$y')],
      selected: _filters.year,
    );
    if (choice != null) setState(() => _filters = _filters.withYear(choice.$1));
  }

  /// "Type" sheet: All, Maintenance, Repair, Inspection, Other.
  Future<void> _chooseType() async {
    final l10n = AppLocalizations.of(context);
    final choice = await _chooseOne<ServiceType?>(
      title: l10n.historyChooseType,
      options: [(null, l10n.historyAllTypes), for (final t in ServiceType.values) (t, serviceTypeLabel(l10n, t))],
      selected: _filters.type,
    );
    if (choice != null) setState(() => _filters = _filters.withType(choice.$1));
  }

  /// A small sheet of choice chips. Returns the picked value wrapped in a
  /// record, so "All" (`null`) differs from dismissing (`null` result).
  Future<(T,)?> _chooseOne<T>({required String title, required List<(T, String)> options, required T selected}) =>
      showAppSheet<(T,)>(
        context: context,
        fitContent: true,
        tabletMaxWidth: 420,
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text(title, style: context.text.titleL)),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: [
                  for (final (value, label) in options)
                    AppChoiceChip(
                      label: label,
                      selected: value == selected,
                      onTap: () => Navigator.of(context).pop((value,)),
                    ),
                ],
              ),
            ],
          ),
        ),
      );

  List<Widget> _listSlivers(HistoryView view, List<ServiceRecord> records, bool masterDetail) {
    final l10n = AppLocalizations.of(context);
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final format = AppFormatters(languageCode: language);

    if (view.records.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            icon: Icons.assignment_outlined,
            title: l10n.historyEmptyTitle,
            body: l10n.historyEmptyBody,
            action: AppButton(label: l10n.actionLogService, onPressed: () => context.push(AppRoutes.logService())),
          ),
        ),
      ];
    }
    if (records.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: l10n.historyNoMatch,
            action: AppButton.secondary(
              label: l10n.historyClearFilters,
              onPressed: () => setState(() => _filters = const HistoryFilters()),
            ),
          ),
        ),
      ];
    }

    return [
      for (final (month, group) in groupByMonth(records)) ...[
        SliverToBoxAdapter(
          child: _padded(
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
              child: Semantics(
                header: true,
                child: Text(
                  language == 'ar' ? format.monthYear(month) : format.monthYear(month).toUpperCase(),
                  style: text.overline.copyWith(color: context.colors.textTertiary),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
          sliver: SliverList.separated(
            itemCount: group.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) {
              final record = group[i];
              final row = ServiceRecordRow(
                record: record,
                title: serviceRecordTitle(l10n, record, itemNames: view.itemNames, languageCode: language),
                unit: view.unit,
                onTap: () => masterDetail
                    ? setState(() => _selected = record.id)
                    : context.push(AppRoutes.historyRecord(record.id)),
              );
              if (!masterDetail) return row;
              // The selected record gets a strong border in the master list.
              return DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.row),
                  border: record.id == _selected ? Border.all(color: context.colors.borderStrong, width: 2) : null,
                ),
                child: Semantics(selected: record.id == _selected, child: row),
              );
            },
          ),
        ),
      ],
    ];
  }

  /// Loading: 4 skeleton rows with the shared shimmer (spec S-20
  /// "States", S-34).
  Widget _skeleton() => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin, vertical: AppSpacing.md),
    sliver: SliverToBoxAdapter(
      child: SkeletonShimmer(
        label: AppLocalizations.of(context).historyLoading,
        child: Column(
          children: [
            for (var i = 0; i < 4; i++) ...[const SkeletonBox(height: 80), const SizedBox(height: AppSpacing.xs)],
          ],
        ),
      ),
    ),
  );
}

/// The vehicle chip under the title (spec S-20 item 2): monogram, name and
/// a chevron; opens the picker.
class _VehicleChip extends StatelessWidget {
  const _VehicleChip({required this.view, required this.onTap});

  final HistoryView view;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).historyVehicleChip(view.vehicleName),
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceCard,
        shape: StadiumBorder(side: BorderSide(color: colors.borderSubtle)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.xxs,
              AppSpacing.xxs,
              AppSpacing.sm,
              AppSpacing.xxs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MonogramTile(letters: view.monogram, size: 36),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(view.vehicleName, style: context.text.titleM, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Icon(Icons.keyboard_arrow_down, size: 20, color: colors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps the filter chips on screen while the records scroll under them.
class _FilterBar extends SliverPersistentHeaderDelegate {
  _FilterBar({required this.child, required this.color});

  static const height = 56.0;

  final Widget child;
  final Color color;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(color: color, child: child);

  @override
  bool shouldRebuild(_FilterBar oldDelegate) => true;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.action, this.body});

  final IconData icon;
  final String title;
  final String? body;
  final Widget action;

  @override
  Widget build(BuildContext context) => AppEmptyState(icon: icon, title: title, body: body, action: action);
}
