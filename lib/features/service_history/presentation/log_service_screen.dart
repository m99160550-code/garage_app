import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/text/digits.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_choice_chip.dart';
import '../../../core/widgets/app_date_picker.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_toast.dart';
import '../../account/application/backup_controller.dart';
import '../../account/presentation/backup_offer_sheet.dart';
import '../../maintenance/domain/item_due.dart';
import '../../maintenance/presentation/item_visuals.dart';
import '../../onboarding/presentation/country/country_labels.dart';
import '../../vehicles/domain/vehicle_validation.dart';
import '../application/log_service_controller.dart';
import '../domain/log_service_rules.dart';
import '../domain/service_record.dart';
import 'service_record_screen.dart';
import 'widgets/service_record_row.dart';

/// S-22 Log service, create and edit (UI/UX spec S-22, FR-SVC-01 to
/// FR-SVC-03, UC-03). A full-screen form ("Cancel", title, "Save"), a
/// 600 pt modal on tablets.
///
/// [initialItems] are preselected (S-15 "Mark as done", S-18). With
/// [recordId] it edits that record (S-21 "Edit").
class LogServiceScreen extends ConsumerStatefulWidget {
  const LogServiceScreen({super.key, this.initialItems = const [], this.recordId, this.vehicleId});

  final List<String> initialItems;
  final String? recordId;
  final String? vehicleId;

  /// The form never gets wider than this on a phone in landscape.
  static const maxContentWidth = 600.0;

  @override
  ConsumerState<LogServiceScreen> createState() => _LogServiceScreenState();
}

class _LogServiceScreenState extends ConsumerState<LogServiceScreen> {
  final _dateText = TextEditingController();
  final _km = TextEditingController();
  final _kmFocus = FocusNode();
  final _cost = TextEditingController();
  final _shop = TextEditingController();
  final _shopFocus = FocusNode();
  final _notes = TextEditingController();

  /// Picked in "For: … ▾"; `null` uses the default vehicle.
  String? _vehicleId;

  /// The vehicle the form was last filled for.
  String? _filledFor;
  bool _initialising = false;
  DateTime? _date;
  final List<String> _selected = [];

  /// Fixed when the form opens, so chips don't jump around when tapped.
  final Set<String> _preselected = {};
  ServiceType _type = ServiceType.maintenance;
  bool _typeTouched = false;
  String? _currency;
  bool _dirty = false;
  bool _kmEdited = false;
  bool _showErrors = false;
  bool _saving = false;

  bool get _editing => widget.recordId != null;

  @override
  void initState() {
    super.initState();
    for (final c in [_km, _cost, _shop, _notes]) {
      c.addListener(() {
        if (_initialising) return;
        setState(() {
          _dirty = true;
          if (identical(c, _km)) _kmEdited = true;
        });
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_dateText, _km, _cost, _shop, _notes]) {
      c.dispose();
    }
    _kmFocus.dispose();
    _shopFocus.dispose();
    super.dispose();
  }

  static String _grouped(int value) =>
      GroupedNumberFormatter().formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: '$value')).text;

  /// The type follows the items until the user picks one: Maintenance, or
  /// Repair when nothing is selected (spec S-22 item 5).
  ServiceType get _effectiveType =>
      _typeTouched ? _type : (_selected.isEmpty ? ServiceType.repair : ServiceType.maintenance);

  /// Fills the form once per vehicle: everything on first open, then only
  /// the odometer and items when the vehicle changes.
  void _fill(LogServiceData data) {
    if (_filledFor == data.vehicleId) return;
    final first = _filledFor == null;
    _filledFor = data.vehicleId;
    _initialising = true;
    final existing = data.existing;
    final km = existing?.odometerKm ?? data.current?.km;
    _km.text = km == null ? '' : _grouped(fromKilometres(km, data.unit));
    _kmEdited = false;
    final codes = {for (final d in data.dues) d.item.code};
    _selected
      ..clear()
      ..addAll((existing?.itemCodes ?? (first ? widget.initialItems : const <String>[])).where(codes.contains));
    _preselected
      ..clear()
      ..addAll(_selected);
    if (first) {
      _date = existing?.date ?? data.today;
      _type = existing?.type ?? ServiceType.maintenance;
      _typeTouched = existing != null;
      _currency = existing?.currency ?? data.currency;
      _cost.text = existing?.costMinor == null ? '' : costText(existing!.costMinor!, existing.currency!);
      _shop.text = existing?.shopName ?? '';
      _notes.text = existing?.notes ?? '';
    }
    _initialising = false;
  }

  // Validation (spec S-22 "Validation and dialogs").

  String? _kmError(AppLocalizations l10n) {
    if (_km.text.trim().isEmpty) return l10n.logOdometerRequired;
    return parseWholeNumber(_km.text) == null ? l10n.odometerNotNumber : null;
  }

  String? _costError(AppLocalizations l10n) {
    final currency = _currency!;
    return switch (parseCost(_cost.text, currency).issue) {
      null => null,
      CostIssue.negative => l10n.logCostNegative,
      CostIssue.notANumber => l10n.logCostInvalid,
      CostIssue.tooManyDecimals => l10n.logCostDecimals(currency, AppFormatters.minorUnitsOf(currency)),
    };
  }

  bool _valid(AppLocalizations l10n) => _kmError(l10n) == null && _costError(l10n) == null && _date != null;

  Future<void> _save(LogServiceData data) async {
    final l10n = AppLocalizations.of(context);
    if (_saving) return;
    if (!_valid(l10n)) {
      setState(() => _showErrors = true);
      return;
    }
    final km = toKilometres(parseWholeNumber(_km.text)!, data.unit);

    // Lower than the current reading on or after its date: a correction
    // (UC-03 5d, BR-MIL-02). An older, backdated value is just history.
    var correction = false;
    final current = data.current;
    if (current != null && km < current.km && !_date!.isBefore(current.date)) {
      final confirmed = await _confirmCorrection(data, km);
      if (!confirmed || !mounted) return;
      correction = true;
    }

    setState(() => _saving = true);
    final language = Localizations.localeOf(context).languageCode;
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    try {
      final outcome = await ref
          .read(logServiceActionsProvider)
          .save(
            ServiceDraft(
              vehicleId: data.vehicleId,
              date: _date!,
              odometerKm: km,
              itemCodes: List.of(_selected),
              type: _effectiveType,
              costMinor: parseCost(_cost.text, _currency!).minor,
              currency: _currency!,
              shopName: _shop.text,
              notes: _notes.text,
              correction: correction,
            ),
            existing: data.existing,
          );
      if (!mounted) return;
      // A light success haptic; not awaited, it never blocks closing.
      unawaited(HapticFeedback.lightImpact());
      final kept = [for (final item in outcome.kept) item.name(language)];
      showAppToast(
        context,
        kept.isEmpty ? l10n.logSaved(outcome.score) : l10n.logSavedKept(kept.length, joinWithAnd(l10n, kept, language)),
      );
      context.pop(true);
      // Guests are offered a backup after their first service (FR-USR-12,
      // at most 3 times, BR-USR-06).
      if (outcome.firstService) {
        final backup = ref.read(backupActionsProvider);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (rootContext.mounted) offerBackupAutomatically(rootContext, backup);
        });
      }
    } on Exception {
      // Spec S-34: a plain message with Retry, never a technical code.
      if (mounted) showErrorToast(context, onRetry: () => _save(data));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmCorrection(LogServiceData data, int km) async {
    final l10n = AppLocalizations.of(context);
    final format = AppFormatters(languageCode: Localizations.localeOf(context).languageCode);
    final current = data.current!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.mileageLowerTitle),
        content: Text(
          l10n.mileageLowerBody(
            scheduleDistance(l10n, current.km, data.unit),
            format.shortDate(current.date),
            scheduleDistance(l10n, km, data.unit),
          ),
        ),
        actions: [
          AppButton.text(label: l10n.actionEdit, onPressed: () => Navigator.pop(context, false)),
          AppButton.text(label: l10n.mileageSaveCorrection, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (result != true) _kmFocus.requestFocus();
    return result == true;
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
        title: Text(l10n.logDiscardTitle),
        actions: [
          AppButton.text(label: l10n.actionKeepEditing, onPressed: () => Navigator.pop(context, false)),
          AppButton.destructiveText(label: l10n.actionDiscard, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (discard == true && mounted) context.pop();
  }

  Future<void> _pickDate(LogServiceData data) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showAppDatePicker(
      context: context,
      title: l10n.logDate,
      initial: _date,
      // Never in the future (BR-SVC-01).
      lastDate: data.today,
      today: data.today,
    );
    if (choice != null) {
      setState(() {
        _date = choice.date;
        _dirty = true;
      });
    }
  }

  Future<void> _pickCurrency(LogServiceData data) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showAppSheet<String>(
      context: context,
      fitContent: true,
      tabletMaxWidth: 420,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(l10n.logCurrency, style: context.text.titleL)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                for (final code in data.currencies)
                  AppChoiceChip(label: code, selected: code == _currency, onTap: () => Navigator.of(context).pop(code)),
              ],
            ),
          ],
        ),
      ),
    );
    if (picked != null && picked != _currency) {
      setState(() {
        _currency = picked;
        _dirty = true;
      });
    }
  }

  /// "+ Add custom item": S-16, then the new item is selected (UC-03 3b).
  Future<void> _addCustomItem() async {
    final code = await context.push<String>(AppRoutes.garageCustomItem);
    if (code != null && mounted) {
      setState(() {
        _selected.add(code);
        _preselected.add(code);
        _dirty = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final data = ref
        .watch(
          logServiceDataProvider((
            vehicleId: _vehicleId ?? widget.vehicleId,
            recordId: widget.recordId,
            languageCode: language,
          )),
        )
        .value;
    if (data != null) _fill(data);
    final ready = data != null && _filledFor == data.vehicleId;
    if (ready) _dateText.text = AppFormatters(languageCode: language).mediumDate(_date!);
    final canSave = ready && _valid(l10n) && !_saving;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: colors.bgSheet,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 100,
          leading: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton.text(label: l10n.actionCancel, onPressed: _cancel),
          ),
          centerTitle: true,
          title: Text(_editing ? l10n.logEditTitle : l10n.logTitle, style: context.text.titleM),
          actions: [AppButton.text(label: l10n.actionSave, onPressed: canSave ? () => _save(data) : null)],
          backgroundColor: colors.bgSheet,
          surfaceTintColor: Colors.transparent,
        ),
        body: !ready
            ? const DelayedSkeleton()
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: LogServiceScreen.maxContentWidth),
                  child: _form(data, canSave),
                ),
              ),
      ),
    );
  }

  Widget _form(LogServiceData data, bool canSave) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final unit = distanceUnitLabel(l10n, data.unit);
    final kmError = (_showErrors || _kmEdited) ? _kmError(l10n) : null;
    final costError = (_showErrors || _cost.text.isNotEmpty) ? _costError(l10n) : null;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.xs,
        AppSpacing.screenMargin,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Vehicle (only with several, and not when editing).
          if (!_editing && data.vehicles.length > 1) ...[
            _VehicleLine(
              name: data.vehicles.firstWhere((v) => v.$1 == data.vehicleId).$2,
              vehicles: data.vehicles,
              onChanged: (id) => setState(() {
                _vehicleId = id;
                _dirty = true;
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          // 2. Date and 3. Odometer.
          AppTextField(
            controller: _dateText,
            label: l10n.logDate,
            readOnly: true,
            trailingIcon: Icons.calendar_today_outlined,
            onTap: () => _pickDate(data),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _km,
            focusNode: _kmFocus,
            label: l10n.logOdometer,
            suffixText: unit,
            keyboardType: TextInputType.number,
            inputFormatters: [GroupedNumberFormatter(maxDigits: 7)],
            helper: data.current == null
                ? null
                : l10n.logOdometerCurrent(scheduleDistance(l10n, data.current!.km, data.unit)),
            error: kmError,
          ),
          const SizedBox(height: AppSpacing.xl),
          // 4. What was done?
          Semantics(header: true, child: Text(l10n.logWhatDone, style: text.titleM)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              for (final due in chipOrder(data.dues, _preselected))
                AppChoiceChip(
                  multiSelect: true,
                  label: due.item.name(language),
                  semanticLabel: l10n.logChipSemantic(due.item.name(language), _statusLabel(l10n, due)),
                  leading: _StatusDot(due: due),
                  selected: _selected.contains(due.item.code),
                  onTap: () => setState(() {
                    _selected.contains(due.item.code) ? _selected.remove(due.item.code) : _selected.add(due.item.code);
                    _dirty = true;
                  }),
                ),
              AppChoiceChip(
                label: l10n.logAddCustom,
                leading: Icon(Icons.add, size: 16, color: colors.textPrimary),
                selected: false,
                onTap: _addCustomItem,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // 5. Type.
          Semantics(header: true, child: Text(l10n.logType, style: text.label)),
          const SizedBox(height: AppSpacing.xs),
          AppSegmentedControl<ServiceType>(
            semanticPrefix: l10n.logType,
            selected: _effectiveType,
            onChanged: (value) => setState(() {
              _type = value;
              _typeTouched = true;
              _dirty = true;
            }),
            segments: [for (final t in ServiceType.values) (t, serviceTypeLabel(l10n, t))],
          ),
          const SizedBox(height: AppSpacing.xl),
          // 6. Cost, with the currency button.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _cost,
                  label: l10n.logCost,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,٫-]'))],
                  error: costError,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _CurrencyButton(code: _currency!, onTap: () => _pickCurrency(data)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // 7. Shop, with names used before.
          RawAutocomplete<String>(
            textEditingController: _shop,
            focusNode: _shopFocus,
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              if (query.isEmpty) return const [];
              return data.shops.where((s) => s.toLowerCase().contains(query) && s.toLowerCase() != query);
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) => AppTextField(
              controller: controller,
              focusNode: focusNode,
              label: l10n.logShop,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => onSubmitted(),
            ),
            optionsViewBuilder: (context, onSelected, options) =>
                _ShopOptions(options: options, onSelected: onSelected),
          ),
          const SizedBox(height: AppSpacing.md),
          // 8. Notes.
          AppTextField(
            controller: _notes,
            label: l10n.logNotes,
            minLines: 2,
            maxLines: 6,
            maxLength: 2000,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: l10n.logSave, onPressed: canSave ? () => _save(data) : null),
        ],
      ),
    );
  }

  static String _statusLabel(AppLocalizations l10n, ItemDue due) => switch (due.status) {
    ItemStatus.overdue => l10n.statusOverdue,
    ItemStatus.dueSoon => l10n.statusDueSoon,
    ItemStatus.ok => l10n.statusOk,
    ItemStatus.unknown => l10n.baselineUnknownBadge,
    ItemStatus.notApplicable => l10n.scheduleNotApplicable,
  };
}

/// The small status dot on an item chip (spec S-22 item 4). The status is
/// also spoken, so colour isn't the only signal.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.due});

  final ItemDue due;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = switch (due.status) {
      ItemStatus.overdue => colors.danger,
      ItemStatus.dueSoon when !due.snoozed => colors.warning,
      ItemStatus.ok => colors.success,
      _ => colors.textTertiary,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// "For: Family Camry ▾" (spec S-22 item 1).
class _VehicleLine extends StatelessWidget {
  const _VehicleLine({required this.name, required this.vehicles, required this.onChanged});

  final String name;
  final List<(String, String)> vehicles;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: PopupMenuButton<String>(
        tooltip: l10n.logChooseVehicle,
        color: colors.surfaceRaised,
        onSelected: onChanged,
        itemBuilder: (context) => [for (final (id, name) in vehicles) PopupMenuItem(value: id, child: Text(name))],
        child: ConstrainedBox(
          // 48 pt: Android's minimum for a full-width target.
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.logFor(name), style: context.text.body.copyWith(color: colors.textSecondary)),
              Icon(Icons.keyboard_arrow_down, size: 20, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// The currency button at the end of the cost field ("SAR ▾").
class _CurrencyButton extends StatelessWidget {
  const _CurrencyButton({required this.code, required this.onTap});

  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).logCurrencyButton(code),
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          side: BorderSide(color: colors.borderSubtle),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.input),
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(code, style: context.text.body),
                  Icon(Icons.keyboard_arrow_down, size: 20, color: colors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The shop suggestions under the field.
class _ShopOptions extends StatelessWidget {
  const _ShopOptions({required this.options, required this.onSelected});

  final Iterable<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Material(
        color: colors.surfaceRaised,
        elevation: 4,
        borderRadius: BorderRadius.circular(AppRadii.row),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 360),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            shrinkWrap: true,
            children: [
              for (final option in options)
                InkWell(
                  onTap: () => onSelected(option),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(option, style: context.text.body),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
