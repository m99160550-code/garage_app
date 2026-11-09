import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/text/digits.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_date_picker.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_toast.dart';
import '../../garage/application/current_vehicle_controller.dart';
import '../../garage/application/dashboard_data.dart';
import '../../onboarding/presentation/baseline/widgets/baseline_fields.dart';
import '../../onboarding/presentation/country/country_labels.dart';
import '../../vehicles/application/garage_providers.dart';
import '../../vehicles/domain/vehicle_validation.dart';
import '../application/maintenance_providers.dart';
import '../domain/baseline_validation.dart';
import '../domain/health_score.dart';
import '../domain/maintenance_template.dart';
import '../domain/schedule_item.dart';
import '../domain/severity.dart';
import 'item_visuals.dart';

/// The template item matching [code] for the current vehicle, for the
/// "Typical: …" line and "Reset to typical".
final _typicalItemProvider = FutureProvider.autoDispose.family<TemplateItem?, (String, DashboardData)>((
  ref,
  key,
) async {
  final vehicle = key.$2.vehicle;
  final template = await ref.watch(templateRepositoryProvider).versionFor(vehicle.fuelType, vehicle.templateVersion);
  return template.items.where((t) => t.code == key.$1).firstOrNull;
});

/// S-16 Edit interval / Add custom item (UI/UX spec S-16). [code] is the
/// item to edit; `null` adds a custom item. A full-screen form with
/// "Cancel" and "Save" in the top bar (a 560 pt modal on tablets).
class ItemIntervalScreen extends ConsumerStatefulWidget {
  const ItemIntervalScreen({super.key, this.code});

  final String? code;

  @override
  ConsumerState<ItemIntervalScreen> createState() => _ItemIntervalScreenState();
}

class _ItemIntervalScreenState extends ConsumerState<ItemIntervalScreen> {
  final _name = TextEditingController();
  final _months = TextEditingController();
  final _distance = TextEditingController();
  final _lastDoneKm = TextEditingController();
  Severity _severity = Severity.minor; // BR-HLT-04: custom items default to Minor.
  DateTime? _lastDoneDate;
  bool _initialised = false;
  bool _dirty = false;
  bool _showErrors = false;
  bool _saving = false;

  bool get _adding => widget.code == null;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _months, _distance, _lastDoneKm]) {
      c.addListener(() => setState(() => _dirty = true));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _months, _distance, _lastDoneKm]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _grouped(int value) =>
      GroupedNumberFormatter().formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: '$value')).text;

  /// Fills the form from the item once (and not from later rebuilds).
  void _initialise(ScheduleItem? item, DashboardData data) {
    if (_initialised) return;
    _initialised = true;
    if (item == null) return;
    _name.text = item.nameEn;
    if (item.intervalMonths != null) _months.text = '${item.intervalMonths}';
    if (item.intervalKm != null) _distance.text = _grouped(fromKilometres(item.intervalKm!, data.unit));
    _severity = item.severity;
    _dirty = false;
  }

  void _resetToTypical(TemplateItem typical, DashboardData data) => setState(() {
    _months.text = typical.intervalMonths?.toString() ?? '';
    _distance.text = typical.intervalKm == null ? '' : _grouped(fromKilometres(typical.intervalKm!, data.unit));
    _severity = typical.severity;
  });

  /// Field errors (spec S-16 "Validation").
  ({String? name, String? months, String? distance, String? both, String? lastDoneKm}) _errors(
    ScheduleItem? item,
    DashboardData data,
  ) {
    final l10n = AppLocalizations.of(context);
    final months = parseWholeNumber(_months.text);
    final distance = parseWholeNumber(_distance.text);
    final custom = _adding || (item?.isCustom ?? false);
    final kmIssue = checkBaselineKm(_lastDoneKm.text, data.unit, data.vehicle.odometerKm);
    return (
      name: custom && _name.text.trim().isEmpty ? l10n.customNameRequired : null,
      months: _months.text.isNotEmpty && (months == null || months <= 0) ? l10n.intervalAboveZero : null,
      distance: _distance.text.isNotEmpty && (distance == null || distance <= 0) ? l10n.intervalAboveZero : null,
      both: _months.text.trim().isEmpty && _distance.text.trim().isEmpty ? l10n.intervalNeedOne : null,
      lastDoneKm: kmIssue == BaselineKmIssue.aboveOdometer
          ? l10n.baselineKmAboveOdometer(
              '${const AppFormatters(languageCode: 'en').formatOdometer(fromKilometres(data.vehicle.odometerKm, data.unit))}\u00A0'
              '${distanceUnitLabel(l10n, data.unit)}',
            )
          : null,
    );
  }

  Future<void> _save(ScheduleItem? item, TemplateItem? typical, DashboardData data) async {
    final l10n = AppLocalizations.of(context);
    final errors = _errors(item, data);
    if ([errors.name, errors.months, errors.distance, errors.both, errors.lastDoneKm].any((e) => e != null)) {
      setState(() => _showErrors = true);
      return;
    }
    final months = parseWholeNumber(_months.text);
    final distance = parseWholeNumber(_distance.text);
    final km = distance == null ? null : toKilometres(distance, data.unit);
    final repository = ref.read(garageRepositoryProvider);
    final name = _name.text.trim();
    String? addedCode;

    setState(() => _saving = true);
    if (item == null) {
      // A new custom item (FR-MNT-05).
      final lastKm = baselineKmFrom(_lastDoneKm.text, data.unit, data.vehicle.odometerKm);
      final id = 'custom-${DateTime.now().microsecondsSinceEpoch}';
      addedCode = id;
      await repository.addScheduleItem(
        ScheduleItem(
          id: id,
          vehicleId: data.vehicle.id,
          code: id,
          nameEn: name,
          nameAr: name,
          severity: _severity,
          intervalMonths: months,
          intervalKm: km,
          lastDoneDate: _lastDoneDate,
          lastDoneKm: lastKm,
          lastDoneSource: _lastDoneDate != null || lastKm != null ? LastDoneSource.manual : null,
          isCustom: true,
        ),
      );
    } else {
      final edited =
          typical == null ||
          months != typical.intervalMonths ||
          km != typical.intervalKm ||
          _severity != typical.severity;
      var updated = item.copyWith(
        severity: _severity,
        intervalMonths: months,
        clearIntervalMonths: months == null,
        intervalKm: km,
        clearIntervalKm: km == null,
        intervalEdited: !item.isCustom && edited,
      );
      if (item.isCustom && name != item.nameEn) {
        updated = updated.copyWith(nameEn: name, nameAr: name);
      }
      await repository.updateScheduleItem(updated);
    }
    ref.read(garageRevisionProvider.notifier).bump();
    if (!mounted) return;
    showAppToast(context, item == null ? l10n.customItemAdded(name) : l10n.intervalUpdated);
    // A new custom item returns its code (S-22 then marks it covered).
    context.pop(item == null ? addedCode : null);
  }

  Future<void> _cancel() async {
    if (!_dirty) {
      context.pop();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.discardChangesTitle),
        actions: [
          AppButton.text(label: l10n.actionKeepEditing, onPressed: () => Navigator.pop(context, false)),
          AppButton.destructiveText(label: l10n.actionDiscard, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (discard == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vehicleId = ref.watch(currentVehicleProvider).value;
    final data = vehicleId == null ? null : ref.watch(dashboardDataProvider(vehicleId)).value;
    final item = data == null || _adding ? null : data.dues.where((d) => d.item.code == widget.code).firstOrNull?.item;
    final typical = data == null || item == null || item.isCustom
        ? null
        : ref.watch(_typicalItemProvider((item.code, data))).value;
    if (data != null) _initialise(item, data);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 100,
          leading: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton.text(label: l10n.actionCancel, onPressed: _cancel),
          ),
          centerTitle: true,
          title: Text(_adding ? l10n.scheduleAddCustom : l10n.intervalEditTitle, style: context.text.titleM),
          actions: [
            if (data != null)
              AppButton.text(label: l10n.actionSave, onPressed: _saving ? null : () => _save(item, typical, data)),
          ],
          backgroundColor: context.colors.bgSheet,
          surfaceTintColor: Colors.transparent,
        ),
        backgroundColor: context.colors.bgSheet,
        body: data == null ? const SizedBox.shrink() : _form(item, typical, data),
      ),
    );
  }

  Widget _form(ScheduleItem? item, TemplateItem? typical, DashboardData data) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final errors = _errors(item, data);
    final custom = _adding || (item?.isCustom ?? false);
    final unit = distanceUnitLabel(l10n, data.unit);
    String? shown(String? error) => _showErrors ? error : null;

    final weights = const ScoreWeights().overdue;
    // Each value is its own left-to-right piece so the minus stays in front
    // of the number. In Arabic the slashes get RLM marks so the list reads
    // right to left, critical first, like the segmented control above it.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final points = [
      Severity.critical,
      Severity.major,
      Severity.minor,
    ].map((s) => ltrValue('−${weights[s]}')).join(rtl ? ' \u200F/\u200F ' : ' / ');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.md,
        AppSpacing.screenMargin,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!custom && item != null) ...[
            Semantics(header: true, child: Text(item.name(language), style: text.titleL)),
            const SizedBox(height: AppSpacing.lg),
          ],
          // 1. Name (custom items only).
          if (custom) ...[
            AppTextField(
              controller: _name,
              label: l10n.customNameLabel,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              error: shown(errors.name),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          // 2. Interval.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _months,
                  label: l10n.intervalMonthsLabel,
                  suffixText: l10n.intervalMonthsUnit,
                  keyboardType: TextInputType.number,
                  inputFormatters: [GroupedNumberFormatter(maxDigits: 3)],
                  error: shown(errors.months),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  controller: _distance,
                  label: l10n.intervalDistanceLabel(unit),
                  suffixText: unit,
                  keyboardType: TextInputType.number,
                  inputFormatters: [GroupedNumberFormatter(maxDigits: 7)],
                  error: shown(errors.distance),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_showErrors && errors.both != null)
            Text(errors.both!, style: text.caption.copyWith(color: colors.danger))
          else
            Text(l10n.intervalNote, style: text.caption.copyWith(color: colors.textTertiary)),
          // 5. Typical values (template items).
          if (typical != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.intervalTypical(
                      scheduleIntervalText(
                        l10n,
                        months: typical.intervalMonths,
                        km: typical.intervalKm,
                        unit: data.unit,
                      ),
                    ),
                    style: text.caption.copyWith(color: colors.textSecondary),
                  ),
                ),
                AppButton.text(label: l10n.itemResetToTypical, onPressed: () => _resetToTypical(typical, data)),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          // 3. Importance.
          Semantics(header: true, child: Text(l10n.importanceLabel, style: text.label)),
          const SizedBox(height: AppSpacing.xs),
          AppSegmentedControl<Severity>(
            semanticPrefix: l10n.importanceLabel,
            selected: _severity,
            onChanged: (value) => setState(() {
              _severity = value;
              _dirty = true;
            }),
            segments: [for (final s in Severity.values) (s, severityLabel(l10n, s))],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.importanceHelper(points), style: text.caption.copyWith(color: colors.textTertiary)),
          // 4. Last done (new custom items).
          if (_adding) ...[
            const SizedBox(height: AppSpacing.xl),
            Semantics(header: true, child: Text(l10n.customLastDoneTitle, style: text.label)),
            const SizedBox(height: AppSpacing.xs),
            DateAndMileageFields(
              dateLabel: l10n.baselineDateLabel,
              dateText: formatFieldDate(context, _lastDoneDate),
              onPickDate: () async {
                final today = DateTime(data.today.year, data.today.month, data.today.day);
                final choice = await showAppDatePicker(
                  context: context,
                  title: l10n.baselineDateLabel,
                  initial: _lastDoneDate,
                  lastDate: today,
                  today: today,
                );
                if (choice != null) {
                  setState(() {
                    _lastDoneDate = choice.date;
                    _dirty = true;
                  });
                }
              },
              mileageLabel: l10n.baselineMileageLabel,
              mileageController: _lastDoneKm,
              unitLabel: unit,
              mileageError: errors.lastDoneKm,
            ),
          ],
        ],
      ),
    );
  }
}
