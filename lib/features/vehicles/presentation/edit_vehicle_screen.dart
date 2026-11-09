import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/format/app_formatters.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/text/digits.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_toast.dart';
import '../../garage/application/current_vehicle_controller.dart';
import '../../onboarding/presentation/country/country_labels.dart';
import '../../onboarding/presentation/details/widgets/vehicle_preview.dart';
import '../../privacy/application/consent_providers.dart';
import '../../settings/presentation/widgets/settings_list.dart';
import '../application/edit_vehicle_controller.dart';
import '../application/vehicle_draft_controller.dart';
import '../domain/fuel_type.dart';
import '../domain/vehicle_draft.dart';
import '../domain/vehicle_edit.dart';
import '../domain/vehicle_validation.dart';
import 'delete_vehicle_dialog.dart';
import 'vehicle_form.dart';
import 'vehicle_labels.dart';

/// S-32 Edit vehicle (UI/UX spec S-32, FR-VEH-11, FR-VEH-12): the S-06
/// form, prefilled, with brand and model as rows at the top (they open
/// S-04 and S-05 in edit mode) and "Delete vehicle" at the bottom.
///
/// * A new fuel type asks whether to update the schedule (BR-MNT-08).
/// * A higher odometer becomes a new reading; a lower one is refused here
///   (corrections live in Mileage history, BR-MIL-01).
/// * Leaving with changes asks "Discard changes?".
///
/// [vehicleId] `null` edits the dashboard's vehicle (S-09 overflow).
class EditVehicleScreen extends ConsumerStatefulWidget {
  const EditVehicleScreen({super.key, this.vehicleId});

  final String? vehicleId;

  @override
  ConsumerState<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends ConsumerState<EditVehicleScreen> {
  final _form = VehicleFormController();
  late final VehicleDraftController _draft = ref.read(vehicleDraftProvider.notifier);
  String? _loadedFor;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _form.addListener(() {
      if (_loadedFor != null) _dirty = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _form.dispose();
    // The draft is shared with "Add vehicle": leave it empty.
    final draft = _draft;
    scheduleMicrotask(draft.resetIfAlive);
    super.dispose();
  }

  void _load(EditVehicleData data) {
    _loadedFor = null;
    _form.fill(detailsOf(data.vehicle), data.unit);
    _draft.edit(draftOf(data.vehicle));
    _loadedFor = data.vehicle.id;
    _dirty = false;
  }

  /// The brand and model shown: a new pick from S-04/S-05, or the
  /// vehicle's own.
  VehicleDraft _identity(EditVehicleData data) {
    final draft = ref.read(vehicleDraftProvider);
    return draft.hasBrand && draft.hasModel ? draft : draftOf(data.vehicle);
  }

  String? _odometerLower(EditVehicleData data, AppLocalizations l10n, String language) {
    final value = parseWholeNumber(_form.odometer.text);
    if (value == null || toKilometres(value, data.unit) >= data.vehicle.odometerKm) return null;
    final last = AppFormatters(languageCode: language)
        .formatOdometer(fromKilometres(data.vehicle.odometerKm, data.unit));
    return l10n.editOdometerLower(ltrValue('$last ${distanceUnitLabel(l10n, data.unit)}'));
  }

  Future<FuelChangeChoice?> _askFuelChange(FuelType fuel) {
    final l10n = AppLocalizations.of(context);
    var keepIntervals = true;
    return showDialog<FuelChangeChoice>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.fuelChangeTitle(fuelTypeLabel(l10n, fuel))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.fuelChangeBody),
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                value: keepIntervals,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(l10n.fuelChangeKeepIntervals),
                onChanged: (value) => setDialogState(() => keepIntervals = value ?? true),
              ),
            ],
          ),
          actions: [
            AppButton.text(
              label: l10n.fuelChangeKeep,
              onPressed: () => Navigator.pop(context, (updateSchedule: false, keepEditedIntervals: keepIntervals)),
            ),
            AppButton.text(
              label: l10n.fuelChangeUpdate,
              onPressed: () => Navigator.pop(context, (updateSchedule: true, keepEditedIntervals: keepIntervals)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(EditVehicleData data) async {
    final l10n = AppLocalizations.of(context);
    final vin = _form.vin.text.trim();
    if (checkVin(vin) == VinIssue.invalidCharacters) {
      _form.focusVin();
      return;
    }
    // Duplicate VIN in this garage (BR-VEH-03): warn, let the user decide.
    final normalized = vin.toUpperCase();
    final duplicate = normalized.isEmpty
        ? null
        : data.others.where((v) => v.vin?.toUpperCase() == normalized).firstOrNull;
    if (duplicate != null) {
      final keep = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.duplicateVinTitle),
          content: Text(l10n.duplicateVinBody(duplicate.nickname ?? l10n.duplicateVinUnnamed)),
          actions: [
            AppButton.text(label: l10n.duplicateVinChange, onPressed: () => Navigator.pop(context, false)),
            AppButton.text(label: l10n.actionSave, onPressed: () => Navigator.pop(context, true)),
          ],
        ),
      );
      if (keep != true) {
        _form.focusVin();
        return;
      }
    }

    final details = _form.toDetails(data.unit);
    FuelChangeChoice? fuelChange;
    if (details.fuelType != data.vehicle.fuelType) {
      fuelChange = await _askFuelChange(details.fuelType);
      if (fuelChange == null) return;
    }
    if (!mounted) return;

    final router = GoRouter.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(vehicleEditorProvider)
          .save(data, details: details, identity: _identity(data), fuelChange: fuelChange);
      if (!mounted) return;
      _dirty = false;
      showAppToast(context, l10n.editSaved);
      router.pop();
    } on Exception {
      // Spec S-34: a plain message with Retry, never a technical code.
      if (mounted) showErrorToast(context, onRetry: () => _save(data));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(EditVehicleData data, String name) async {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    if (!await confirmDeleteVehicle(context, name: name, recordCount: data.recordCount)) return;
    final next = await ref.read(vehicleEditorProvider).delete(data.vehicle.id);
    if (!mounted) return;
    _dirty = false;
    if (next == null) {
      // The last vehicle: back to brand selection (BR-VEH-06).
      router.go(AppRoutes.setupBrand);
    } else {
      showAppToast(context, l10n.deleteVehicleDone(name));
      router.pop();
    }
  }

  Future<void> _confirmLeave() async {
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
    if (discard == true && mounted) {
      _dirty = false;
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final vehicleId = widget.vehicleId ?? ref.watch(currentVehicleProvider).value;
    final data = vehicleId == null ? null : ref.watch(editVehicleDataProvider(vehicleId)).value;

    if (data != null && _loadedFor != data.vehicle.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _loadedFor != data.vehicle.id) setState(() => _load(data));
      });
    }

    // A new model brings its body type (as in setup).
    ref.listen(vehicleDraftProvider, (previous, next) {
      if (_loadedFor == null || !next.hasModel || previous == null) return;
      final changed = next.modelId != previous.modelId || next.modelOtherName != previous.modelOtherName;
      if (changed) {
        _dirty = true;
        _form.update(() => _form.body = next.bodyType!);
      }
    });

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(
          title: Text(l10n.editVehicleTitle, style: context.text.titleM),
          centerTitle: true,
          backgroundColor: colors.bgBase,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          top: false,
          child: data == null || _loadedFor == null
              ? const DelayedSkeleton()
              : Column(
                  children: [
                    Expanded(child: _layout(data)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenMargin,
                        AppSpacing.xs,
                        AppSpacing.screenMargin,
                        AppSpacing.md,
                      ),
                      child: AppButton(
                        label: l10n.actionSave,
                        isLoading: _saving,
                        // Enabled once something changed and the answers are valid.
                        onPressed:
                            _dirty &&
                                _form.isValid(data.unit) &&
                                _odometerLower(data, l10n, Localizations.localeOf(context).languageCode) == null
                            ? () => _save(data)
                            : null,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _layout(EditVehicleData data) {
    final colors = context.colors;
    final windowClass = WindowClass.of(context);
    final form = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.md,
        AppSpacing.screenMargin,
        AppSpacing.xl,
      ),
      child: _fields(data),
    );
    if (windowClass == WindowClass.expanded) {
      return Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: VehiclePreview(bodyType: _form.body, paint: _form.paint),
            ),
          ),
          Expanded(flex: 6, child: SingleChildScrollView(child: form)),
        ],
      );
    }
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: VehiclePreviewHeader(
            bodyType: _form.body,
            paint: _form.paint,
            minExtent: 96,
            maxExtent: windowClass == WindowClass.medium ? 240 : 160,
            background: colors.bgBase,
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: form),
          ),
        ),
      ],
    );
  }

  Widget _fields(EditVehicleData data) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final identity = _identity(data);
    final names = ref.watch(vehicleIdentityNamesProvider(identityKey(identity, language))).value;
    final displayName = data.vehicle.nickname ?? (names == null ? '' : '${names.brand} ${names.model}'.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: null,
          children: [
            SettingsRow(
              title: l10n.editBrand,
              value: names?.brand,
              onTap: () => context.push('${AppRoutes.setupBrand}?edit=1'),
            ),
            SettingsRow(
              title: l10n.editModel,
              value: names?.model,
              onTap: () => context.push('${AppRoutes.setupModel}?edit=1'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        VehicleFormFields(
          controller: _form,
          unit: data.unit,
          today: ref.read(clockProvider)(),
          odometerError: _odometerLower(data, l10n, language),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: AppButton.destructiveText(
            label: l10n.editDeleteVehicle,
            icon: Icons.delete_outline,
            onPressed: _saving ? null : () => _delete(data, displayName),
          ),
        ),
      ],
    );
  }
}
