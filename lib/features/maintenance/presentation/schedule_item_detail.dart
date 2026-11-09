import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_date_picker.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/navigation/floating_nav_bar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../garage/application/current_vehicle_controller.dart';
import '../../garage/application/dashboard_data.dart';
import '../../onboarding/presentation/baseline/widgets/baseline_fields.dart';
import '../../onboarding/presentation/country/country_labels.dart';
import '../../vehicles/domain/vehicle_validation.dart';
import '../application/schedule_item_actions.dart';
import '../domain/baseline_validation.dart';
import '../domain/item_due.dart';
import '../domain/schedule_item.dart';
import '../domain/severity.dart';
import '../../service_history/application/record_detail.dart';
import '../../service_history/presentation/widgets/service_record_row.dart';
import 'item_visuals.dart';
import 'widgets/item_action_sheets.dart';
import 'widgets/schedule_item_row.dart';

/// S-15 as a page (phones; a side sheet on iPad portrait).
class ScheduleItemScreen extends StatelessWidget {
  const ScheduleItemScreen({super.key, required this.code, this.openSetLastDone = false, this.sideSheet = false});

  final String code;
  final bool openSetLastDone;
  final bool sideSheet;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: sideSheet ? context.colors.bgSheet : null,
    body: SafeArea(
      bottom: false,
      child: ScheduleItemDetail(code: code, openSetLastDone: openSetLastDone, closeButton: sideSheet),
    ),
  );
}

/// S-15 Schedule item detail (UI/UX spec S-15): one item's status, facts
/// and actions — Mark as done, Snooze, Reschedule, Edit interval, Not
/// applicable, Set last done — and its service history.
///
/// Used as a page and as the detail pane of S-14 on iPad landscape
/// ([embedded]: no back button).
class ScheduleItemDetail extends ConsumerStatefulWidget {
  const ScheduleItemDetail({
    super.key,
    required this.code,
    this.openSetLastDone = false,
    this.embedded = false,
    this.closeButton = false,
  });

  final String code;

  /// Opened from "Unknown: set last done": the form starts open.
  final bool openSetLastDone;
  final bool embedded;
  final bool closeButton;

  @override
  ConsumerState<ScheduleItemDetail> createState() => _ScheduleItemDetailState();
}

class _ScheduleItemDetailState extends ConsumerState<ScheduleItemDetail> {
  late bool _lastDoneOpen = widget.openSetLastDone;
  final _lastDoneKm = TextEditingController();
  final _lastDoneKmFocus = FocusNode();
  DateTime? _lastDoneDate;
  bool _lastDoneMissing = false;

  @override
  void initState() {
    super.initState();
    _lastDoneKm.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(ScheduleItemDetail old) {
    super.didUpdateWidget(old);
    // The iPad pane switches items: start the form afresh.
    if (old.code != widget.code) {
      _lastDoneOpen = widget.openSetLastDone;
      _lastDoneDate = null;
      _lastDoneKm.clear();
      _lastDoneMissing = false;
    }
  }

  @override
  void dispose() {
    _lastDoneKm.dispose();
    _lastDoneKmFocus.dispose();
    super.dispose();
  }

  ScheduleItemActions get _actions => ref.read(scheduleItemActionsProvider);
  DateTime _today(DashboardData data) => DateTime(data.today.year, data.today.month, data.today.day);

  String _distance(DashboardData data, int km) {
    final l10n = AppLocalizations.of(context);
    // A non-breaking space keeps "km" with its number when the value wraps.
    return '${const AppFormatters(languageCode: 'en').formatOdometer(fromKilometres(km, data.unit))}\u00A0'
        '${distanceUnitLabel(l10n, data.unit)}';
  }

  String _date(DateTime date) =>
      AppFormatters(languageCode: Localizations.localeOf(context).languageCode).mediumDate(date);

  Future<void> _snooze(ItemDue due, DashboardData data) async {
    final days = await showSnoozeSheet(context, overdue: due.status == ItemStatus.overdue);
    if (days == null || !mounted) return;
    final until = await _actions.snooze(due.item, days);
    if (mounted) showAppToast(context, AppLocalizations.of(context).healthSnoozedUntil(_date(until)));
  }

  Future<void> _reschedule(ItemDue due, DashboardData data) async {
    final today = _today(data);
    final date = await showRescheduleSheet(context, today: today, initial: due.nextDueDate ?? today);
    if (date == null || !mounted) return;
    await _actions.reschedule(due.item, date);
    if (mounted) showAppToast(context, AppLocalizations.of(context).itemRescheduledToast(_date(date)));
  }

  Future<void> _saveLastDone(ItemDue due, DashboardData data) async {
    final l10n = AppLocalizations.of(context);
    if (checkBaselineKm(_lastDoneKm.text, data.unit, data.vehicle.odometerKm) != null) {
      _lastDoneKmFocus.requestFocus();
      return;
    }
    final km = baselineKmFrom(_lastDoneKm.text, data.unit, data.vehicle.odometerKm);
    if (_lastDoneDate == null && km == null) {
      setState(() => _lastDoneMissing = true);
      return;
    }
    await _actions.setLastDone(due.item, date: _lastDoneDate, km: km);
    if (!mounted) return;
    setState(() => _lastDoneOpen = false);
    showAppToast(context, l10n.itemLastDoneSaved);
  }

  Future<void> _confirmDelete(ScheduleItem item) async {
    final l10n = AppLocalizations.of(context);
    final name = item.name(Localizations.localeOf(context).languageCode);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.itemDeleteTitle(name)),
        content: Text(l10n.itemDeleteBody),
        actions: [
          AppButton.text(label: l10n.actionCancel, onPressed: () => Navigator.pop(context, false)),
          AppButton.destructiveText(label: l10n.actionDelete, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final router = GoRouter.of(context);
    await _actions.delete(item);
    if (!widget.embedded && router.canPop()) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vehicleId = ref.watch(currentVehicleProvider).value;
    final data = vehicleId == null ? null : ref.watch(dashboardDataProvider(vehicleId)).value;
    if (data == null) return const SizedBox.shrink();
    final due = data.dues.where((d) => d.item.code == widget.code).firstOrNull;
    if (due == null) {
      return Column(
        children: [
          _topBar(null, data),
          Expanded(
            child: Center(child: Text(l10n.itemNotFound, style: context.text.body)),
          ),
        ],
      );
    }
    final notApplicable = due.status == ItemStatus.notApplicable;
    final bottom = !widget.embedded && WindowClass.of(context).isCompact && !widget.closeButton
        ? FloatingNavBar.contentClearance + MediaQuery.paddingOf(context).bottom
        : AppSpacing.xl;

    // Not applicable: everything except the toggle is greyed out.
    Widget dimmed(Widget child) => notApplicable ? IgnorePointer(child: Opacity(opacity: 0.4, child: child)) : child;

    return Column(
      children: [
        _topBar(due, data),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(AppSpacing.screenMargin, 0, AppSpacing.screenMargin, bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dimmed(_header(due)),
                if (due.snoozed) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppBanner(
                    message: l10n.healthSnoozedUntil(_date(due.item.snoozedUntil!)),
                    action: AppButton.text(label: l10n.actionUndo, onPressed: () => _actions.undoSnooze(due.item)),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                dimmed(_statusCard(due, data)),
                const SizedBox(height: AppSpacing.lg),
                dimmed(_actionButtons(due, data)),
                const SizedBox(height: AppSpacing.xl),
                _settings(due, data, dimmed),
                const SizedBox(height: AppSpacing.xl),
                dimmed(_history(due, data)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Back (or close), and the overflow menu (spec S-15 item 1).
  Widget _topBar(ItemDue? due, DashboardData data) {
    final l10n = AppLocalizations.of(context);
    final item = due?.item;
    final menu = <PopupMenuEntry<String>>[
      if (item != null && item.intervalEdited) PopupMenuItem(value: 'reset', child: Text(l10n.itemResetToTypical)),
      if (item != null && item.isCustom)
        PopupMenuItem(
          value: 'delete',
          child: Text(l10n.itemDelete, style: TextStyle(color: context.colors.destructiveText)),
        ),
    ];
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          if (!widget.embedded)
            widget.closeButton
                ? IconButton(tooltip: l10n.actionClose, icon: const Icon(Icons.close), onPressed: () => context.pop())
                : const BackButton()
          else
            const SizedBox(width: AppSpacing.md),
          const Spacer(),
          if (menu.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: l10n.actionMoreOptions,
              icon: const Icon(Icons.more_horiz),
              color: context.colors.surfaceRaised,
              itemBuilder: (_) => menu,
              onSelected: (value) => value == 'reset'
                  ? _actions.resetToTypical(item!, data.vehicle.fuelType, data.vehicle.templateVersion)
                  : _confirmDelete(item!),
            ),
        ],
      ),
    );
  }

  /// Icon, name, severity and status (spec S-15 item 2).
  Widget _header(ItemDue due) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final (badge, tone, icon) = scheduleStatusBadge(l10n, due);
    final language = Localizations.localeOf(context).languageCode;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: colors.surfaceRaised, borderRadius: BorderRadius.circular(16)),
          child: Icon(scheduleItemIcon(due.item.code), size: 28, color: colors.textPrimary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text(due.item.name(language), style: context.text.titleL)),
              const SizedBox(height: AppSpacing.xxs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: [
                  if (due.item.severity == Severity.critical)
                    StatusBadge(label: l10n.scheduleCritical, tone: BadgeTone.danger, icon: Icons.priority_high),
                  StatusBadge(label: badge, tone: tone, icon: icon),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// "Due in 12 days", the 8 pt bar and the facts (spec S-15 item 3).
  Widget _statusCard(ItemDue due, DashboardData data) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final item = due.item;
    final today = _today(data);

    final statusLine = switch (due.status) {
      ItemStatus.unknown => l10n.baselineUnknownBadge,
      ItemStatus.notApplicable => l10n.scheduleNotApplicable,
      ItemStatus.overdue => scheduleDueText(
        l10n,
        due,
        unit: data.unit,
        languageCode: Localizations.localeOf(context).languageCode,
      ),
      _ =>
        due.daysUntil(today) != null
            ? l10n.healthReasonDueInDays(due.daysUntil(today)!)
            : l10n.healthReasonDueInKm(_distance(data, due.kmRemaining ?? 0)),
    };

    final interval = [
      if (item.intervalMonths != null) l10n.itemMonths(item.intervalMonths!),
      if (item.intervalKm != null) _distance(data, item.intervalKm!),
    ];
    final lastDone = [
      if (item.lastDoneDate != null) _date(item.lastDoneDate!),
      if (item.lastDoneKm != null) _distance(data, item.lastDoneKm!),
    ];
    final source = switch (item.lastDoneSource) {
      LastDoneSource.baseline => l10n.itemSourceBaseline,
      LastDoneSource.newCar => l10n.itemSourceNewCar,
      LastDoneSource.service => l10n.itemSourceService,
      LastDoneSource.manual => l10n.itemSourceManual,
      null => null,
    };
    final next = [
      if (due.nextDueDate != null) _date(due.nextDueDate!),
      if (due.nextDueKm != null) _distance(data, due.nextDueKm!),
    ];
    final deduction = data.health.deductions.where((d) => d.due.item.id == item.id).firstOrNull;
    final progress = due.progress(today: today, currentKm: data.vehicle.odometerKm);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(statusLine, style: text.titleM),
          if (progress != null && due.status != ItemStatus.notApplicable) ...[
            const SizedBox(height: AppSpacing.sm),
            IntervalBar(progress: progress, status: due.status, snoozed: due.snoozed, height: 8),
          ],
          const SizedBox(height: AppSpacing.md),
          _Fact(
            label: l10n.itemFactInterval,
            value: l10n.itemEvery(interval.length == 2 ? l10n.itemOr(interval[0], interval[1]) : interval.join()),
            badge: item.intervalEdited ? l10n.itemEdited : null,
          ),
          _Fact(
            label: l10n.itemFactLastDone,
            value: lastDone.isEmpty ? l10n.itemNotYet : lastDone.join(' · '),
            detail: lastDone.isEmpty ? null : source,
          ),
          _Fact(
            label: l10n.itemFactNextDue,
            value: switch (next) {
              [] => '—',
              [final only] => only,
              [final first, final second, ...] => l10n.itemOr(first, second),
            },
          ),
          if (due.predictedDueDate != null)
            _Fact(label: l10n.itemFactPredicted, value: l10n.itemPredictedValue(_date(due.predictedDueDate!))),
          _Fact(
            label: l10n.itemFactScore,
            // "−2" stays left to right inside Arabic text (an LRI … PDI isolate).
            value: deduction == null ? l10n.itemNone : l10n.itemPoints(ltrValue('−${deduction.points.abs()}')),
            valueColor: deduction == null ? null : (due.status == ItemStatus.overdue ? colors.danger : colors.warning),
          ),
        ],
      ),
    );
  }

  /// "Mark as done", then "Snooze" and "Reschedule" (spec S-15 items 4–5).
  Widget _actionButtons(ItemDue due, DashboardData data) {
    final l10n = AppLocalizations.of(context);
    final active = due.status != ItemStatus.unknown && due.status != ItemStatus.notApplicable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: l10n.itemMarkDone,
          onPressed: () => context.push(AppRoutes.logService(itemCode: due.item.code)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppButton.secondary(label: l10n.itemSnooze, onPressed: active ? () => _snooze(due, data) : null),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton.secondary(
                label: l10n.itemReschedule,
                onPressed: active ? () => _reschedule(due, data) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Edit interval, Not applicable, and Set last done for Unknown items
  /// (spec S-15 item 6).
  Widget _settings(ItemDue due, DashboardData data, Widget Function(Widget) dimmed) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final unknown = due.status == ItemStatus.unknown;

    Widget row({required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) => InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: text.body),
                    if (subtitle != null) Text(subtitle, style: text.caption.copyWith(color: colors.textTertiary)),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );

    return Material(
      color: colors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: colors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          dimmed(
            row(
              title: l10n.itemEditInterval,
              trailing: Icon(Icons.chevron_right, color: colors.textTertiary),
              onTap: () => context.push(AppRoutes.garageItemInterval(due.item.code)),
            ),
          ),
          const Divider(height: 1),
          MergeSemantics(
            child: row(
              title: l10n.itemNotApplicableToggle,
              subtitle: l10n.itemNotApplicableHint,
              trailing: Switch.adaptive(
                value: due.item.notApplicable,
                activeTrackColor: colors.accentPrimary,
                onChanged: (value) => _actions.setNotApplicable(due.item, value),
              ),
              onTap: () => _actions.setNotApplicable(due.item, !due.item.notApplicable),
            ),
          ),
          if (unknown) ...[
            const Divider(height: 1),
            Semantics(
              button: true,
              expanded: _lastDoneOpen,
              child: row(
                title: l10n.itemSetLastDone,
                trailing: Icon(_lastDoneOpen ? Icons.expand_less : Icons.expand_more, color: colors.textTertiary),
                onTap: () => setState(() => _lastDoneOpen = !_lastDoneOpen),
              ),
            ),
            AnimatedSize(
              duration: AppMotion.standard,
              alignment: Alignment.topCenter,
              child: !_lastDoneOpen
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                      child: _lastDoneForm(due, data),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  /// Date and mileage, the same fields as S-07.
  Widget _lastDoneForm(ItemDue due, DashboardData data) {
    final l10n = AppLocalizations.of(context);
    final kmIssue = checkBaselineKm(_lastDoneKm.text, data.unit, data.vehicle.odometerKm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DateAndMileageFields(
          dateLabel: l10n.baselineDateLabel,
          dateText: formatFieldDate(context, _lastDoneDate),
          onPickDate: () async {
            final choice = await showAppDatePicker(
              context: context,
              title: l10n.baselineDateLabel,
              initial: _lastDoneDate,
              lastDate: _today(data),
              today: _today(data),
            );
            if (choice != null) setState(() => _lastDoneDate = choice.date);
          },
          dateError: _lastDoneMissing && _lastDoneDate == null && _lastDoneKm.text.isEmpty
              ? l10n.itemLastDoneNeedOne
              : null,
          mileageLabel: l10n.baselineMileageLabel,
          mileageController: _lastDoneKm,
          mileageFocus: _lastDoneKmFocus,
          unitLabel: distanceUnitLabel(l10n, data.unit),
          mileageError: switch (kmIssue) {
            null => null,
            BaselineKmIssue.notANumber => l10n.odometerNotNumber,
            BaselineKmIssue.aboveOdometer => l10n.baselineKmAboveOdometer(_distance(data, data.vehicle.odometerKm)),
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(label: l10n.actionSave, onPressed: () => _saveLastDone(due, data)),
      ],
    );
  }

  /// Services that covered this item, newest first (spec S-15 item 7).
  /// Each opens S-21, staying in the tab it was opened from.
  Widget _history(ItemDue due, DashboardData data) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final records = ref.watch(itemRecordsProvider((data.vehicle.id, due.item.code))).value ?? const [];
    final inHistory = GoRouterState.of(context).uri.path.startsWith(AppRoutes.history);
    final names = {for (final d in data.dues) d.item.code: (d.item.nameEn, d.item.nameAr)};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(l10n.itemHistoryTitle, style: context.text.titleM)),
        const SizedBox(height: AppSpacing.xs),
        if (records.isEmpty)
          Text(l10n.itemHistoryEmpty, style: context.text.bodyS.copyWith(color: context.colors.textSecondary))
        else
          for (final record in records) ...[
            ServiceRecordRow(
              record: record,
              title: serviceRecordTitle(l10n, record, itemNames: names, languageCode: language),
              unit: data.unit,
              onTap: () =>
                  context.push(inHistory ? AppRoutes.historyRecord(record.id) : AppRoutes.garageRecord(record.id)),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
      ],
    );
  }
}

/// One row of the facts table: label at the start, value at the end.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.detail, this.badge, this.valueColor});

  final String label;
  final String value;

  /// A smaller line under the value, for example the source.
  final String? detail;

  /// For example "Edited".
  final String? badge;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Semantics(
      label: [label, value, ?detail, ?badge].join(', '),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(label, style: text.bodyS.copyWith(color: colors.textTertiary)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: text.body.copyWith(color: valueColor ?? colors.textPrimary),
                    textAlign: TextAlign.end,
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      style: text.caption.copyWith(color: colors.textTertiary),
                      textAlign: TextAlign.end,
                    ),
                  if (badge != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    StatusBadge(label: badge!, tone: BadgeTone.info),
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
