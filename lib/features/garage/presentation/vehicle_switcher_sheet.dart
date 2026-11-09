import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../vehicles/domain/garage_limits.dart';
import '../application/vehicle_switcher_data.dart';
import 'widgets/vehicle_switcher_row.dart';

/// What the user chose in the switcher.
sealed class SwitcherChoice {
  const SwitcherChoice();
}

final class SwitchToVehicle extends SwitcherChoice {
  const SwitchToVehicle(this.vehicleId);

  final String vehicleId;
}

final class AddVehicleChoice extends SwitcherChoice {
  const AddVehicleChoice();
}

final class ManageVehiclesChoice extends SwitcherChoice {
  const ManageVehiclesChoice();
}

/// Opens S-10 Vehicle switcher (UI/UX spec S-10): a sheet as tall as its
/// content (max 80%) on phones, a 400 pt panel on tablets. Returns what
/// the user picked, or `null` when dismissed.
///
/// With [pickerOnly] (the History tab, spec S-20 item 2) it only lists the
/// vehicles: no "Add vehicle" and no "Manage vehicles".
Future<SwitcherChoice?> showVehicleSwitcher(
  BuildContext context, {
  required String? currentVehicleId,
  bool pickerOnly = false,
}) {
  return showAppSheet<SwitcherChoice>(
    context: context,
    fitContent: true,
    heightFactor: 0.8,
    tabletMaxWidth: 400,
    tabletMaxHeight: 560,
    builder: (_) => VehicleSwitcherSheet(currentVehicleId: currentVehicleId, pickerOnly: pickerOnly),
  );
}

class VehicleSwitcherSheet extends ConsumerWidget {
  const VehicleSwitcherSheet({super.key, required this.currentVehicleId, this.pickerOnly = false});

  final String? currentVehicleId;
  final bool pickerOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final vehicles = ref.watch(vehicleSummariesProvider(language)).value;
    if (vehicles == null) {
      return const Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: DelayedSkeleton());
    }
    final atLimit = vehicles.length >= maxGarageVehicles;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Semantics(header: true, child: Text(l10n.switcherTitle, style: text.titleL)),
              ),
              if (vehicles.length > showGarageCountAbove)
                Text(
                  l10n.switcherCount(vehicles.length, maxGarageVehicles),
                  style: text.bodyS.copyWith(color: colors.textSecondary),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
            children: [
              for (final vehicle in vehicles) ...[
                VehicleSwitcherRow(
                  vehicle: vehicle,
                  current: vehicle.id == currentVehicleId,
                  onTap: () => Navigator.of(context).pop(SwitchToVehicle(vehicle.id)),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (!pickerOnly)
                AddVehicleRow(enabled: !atLimit, onTap: () => Navigator.of(context).pop(const AddVehicleChoice())),
            ],
          ),
        ),
        if (pickerOnly)
          const SizedBox(height: AppSpacing.md)
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              AppSpacing.xs,
              AppSpacing.screenMargin,
              AppSpacing.md,
            ),
            child: Center(
              child: AppButton.text(
                label: l10n.switcherManage,
                onPressed: () => Navigator.of(context).pop(const ManageVehiclesChoice()),
              ),
            ),
          ),
      ],
    );
  }
}

/// "Add vehicle" with a dashed border (spec S-10 item 3). Disabled at the
/// 25-vehicle limit, with "Limit reached. Contact support." (BR-VEH-01).
class AddVehicleRow extends StatelessWidget {
  const AddVehicleRow({super.key, required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final foreground = enabled ? colors.textPrimary : colors.textDisabled;

    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? l10n.switcherAddVehicle : '${l10n.switcherAddVehicle}, ${l10n.switcherLimitReached}',
      excludeSemantics: true,
      child: DashedBorder(
        color: colors.borderStrong,
        radius: AppRadii.row,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadii.row),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: foreground),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.switcherAddVehicle, style: context.text.titleM.copyWith(color: foreground)),
                          if (!enabled)
                            Text(
                              l10n.switcherLimitReached,
                              style: context.text.caption.copyWith(color: colors.textTertiary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
