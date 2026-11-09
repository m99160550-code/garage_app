import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/text/digits.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_toast.dart';
import '../../onboarding/presentation/country/country_labels.dart';
import '../../vehicles/domain/vehicle_validation.dart';
import '../application/mileage_controller.dart';
import '../domain/mileage_rules.dart';

/// Opens S-12 Update mileage (UI/UX spec S-12) for [vehicleId]. Shows the
/// "Mileage updated" toast after a save. Returns whether a reading was
/// saved.
Future<bool> showUpdateMileage(BuildContext context, {required String vehicleId}) async {
  final l10n = AppLocalizations.of(context);
  final saved = await showAppSheet<bool>(
    context: context,
    fitContent: true,
    tabletMaxWidth: 420,
    tabletMaxHeight: 480,
    builder: (_) => UpdateMileageSheet(vehicleId: vehicleId),
  );
  if (saved == true && context.mounted) showAppToast(context, l10n.mileageUpdatedToast);
  return saved == true;
}

/// The sheet's content: the vehicle, one big number field with the unit,
/// the last reading, "Save" and "View history". The keyboard opens
/// straight away, so an update takes two taps from the dashboard
/// (FR-MIL-01).
class UpdateMileageSheet extends ConsumerStatefulWidget {
  const UpdateMileageSheet({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<UpdateMileageSheet> createState() => _UpdateMileageSheetState();
}

class _UpdateMileageSheetState extends ConsumerState<UpdateMileageSheet> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  late String _vehicleId = widget.vehicleId;
  bool _saving = false;

  // Odometer values always use Western digits (BR-SET-05).
  static const _western = AppFormatters(languageCode: 'en');

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// The typed value in kilometres. The current value typed in miles maps
  /// back to the exact stored kilometres.
  int? _typedKm(MileageSheetData data) {
    final value = parseWholeNumber(_input.text);
    if (value == null) return null;
    final current = data.current;
    if (current != null && value == fromKilometres(current.km, data.unit)) return current.km;
    return toKilometres(value, data.unit);
  }

  String _distance(MileageSheetData data, int km) =>
      '${_western.formatOdometer(fromKilometres(km, data.unit))} ${distanceUnitLabel(AppLocalizations.of(context), data.unit)}';

  Future<void> _save(MileageSheetData data) async {
    final km = _typedKm(data);
    if (km == null || _saving) return;
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final controller = ref.read(mileageControllerProvider);
    var correction = false;

    switch (controller.check(data, km)) {
      case ReadingLower(:final current):
        correction = true;
        final confirmed = await _confirm(
          title: l10n.mileageLowerTitle,
          body: l10n.mileageLowerBody(
            _distance(data, current.km),
            AppFormatters(languageCode: language).shortDate(current.date),
            _distance(data, km),
          ),
          confirm: l10n.mileageSaveCorrection,
        );
        if (!confirmed) return;
      case ReadingBigJump(km: final jump, :final days):
        final confirmed = await _confirm(
          title: l10n.mileageJumpTitle,
          body: l10n.mileageJumpBody(_distance(data, jump), l10n.mileageDays(days)),
          confirm: l10n.mileageJumpConfirm,
        );
        if (!confirmed) return;
      case ReadingOk():
        break;
    }

    setState(() => _saving = true);
    try {
      await controller.save(_vehicleId, km, correction: correction);
      if (mounted) Navigator.of(context).pop(true);
    } on Exception {
      // Spec S-34: a plain message with Retry, never a technical code.
      if (mounted) showErrorToast(context, onRetry: () => _save(data));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// [Confirm] [Edit]. "Edit" returns to the field.
  Future<bool> _confirm({required String title, required String body, required String confirm}) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          AppButton.text(label: l10n.actionEdit, onPressed: () => Navigator.pop(context, false)),
          AppButton.text(label: confirm, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (result != true) _focus.requestFocus();
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final data = ref.watch(mileageSheetDataProvider((vehicleId: _vehicleId, languageCode: language))).value;
    return Padding(
      // Keeps "Save" above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: data == null ? const SizedBox(height: 200, child: DelayedSkeleton()) : _content(data),
    );
  }

  Widget _content(MileageSheetData data) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final unit = distanceUnitLabel(l10n, data.unit);
    final current = data.current;
    final placeholder = current == null ? '0' : _western.formatOdometer(fromKilometres(current.km, data.unit));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.mileageTitle, style: text.titleL)),
          _VehicleLine(
            name: data.vehicleName,
            vehicles: data.vehicles,
            onChanged: (id) => setState(() {
              _vehicleId = id;
              _input.clear();
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          // The big number with its unit (spec S-12 item 2).
          Semantics(
            label: l10n.mileageFieldLabel(unit),
            child: TextField(
              controller: _input,
              focusNode: _focus,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              inputFormatters: [GroupedNumberFormatter()],
              cursorColor: colors.accentPrimary,
              style: AppTextStyles.tabular(text.displayStat).copyWith(color: colors.textPrimary),
              // Hardware keyboard: Return saves.
              onSubmitted: (_) => _save(data),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: AppTextStyles.tabular(text.displayStat).copyWith(color: colors.textDisabled),
                // The unit at the end, and an invisible copy at the start of
                // the same width, so the number stays exactly centred.
                suffixIcon: _UnitLabel(unit),
                prefixIcon: ExcludeSemantics(child: Opacity(opacity: 0, child: _UnitLabel(unit))),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.borderStrong)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.accentPrimary, width: 2)),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (current != null)
            Text(
              l10n.mileageLast(
                _distance(data, current.km),
                AppFormatters(languageCode: language).shortDate(current.date),
              ),
              style: text.bodyS.copyWith(color: colors.textTertiary),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: AppSpacing.xl),
          // Disabled while empty (UC-02 4d).
          AppButton(
            label: l10n.actionSave,
            isLoading: _saving,
            onPressed: _typedKm(data) == null ? null : () => _save(data),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Center(
            child: AppButton.text(
              label: l10n.mileageViewHistory,
              onPressed: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop(false);
                router.push(AppRoutes.garageMileageHistory);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "Family Camry", a button that picks another vehicle when there are
/// several (spec S-12 item 1).
class _VehicleLine extends StatelessWidget {
  const _VehicleLine({required this.name, required this.vehicles, required this.onChanged});

  final String name;
  final List<(String, String)> vehicles;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final label = Text(name, style: context.text.bodyS.copyWith(color: colors.textSecondary));
    if (vehicles.length < 2) return Align(alignment: AlignmentDirectional.centerStart, child: label);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: PopupMenuButton<String>(
        tooltip: l10n.mileageChooseVehicle,
        color: colors.surfaceRaised,
        onSelected: onChanged,
        itemBuilder: (context) => [for (final (id, name) in vehicles) PopupMenuItem(value: id, child: Text(name))],
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              label,
              Icon(Icons.keyboard_arrow_down, size: 18, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// "km" after the big number, aligned with its baseline area.
class _UnitLabel extends StatelessWidget {
  const _UnitLabel(this.unit);

  final String unit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: Text(unit, style: context.text.titleM.copyWith(color: context.colors.textSecondary)),
  );
}
