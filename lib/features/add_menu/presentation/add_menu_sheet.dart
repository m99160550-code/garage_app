import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/monogram_tile.dart';
import '../../../core/widgets/navigation/app_nav_rail.dart';
import '../../maintenance/presentation/item_visuals.dart';
import '../../mileage/presentation/update_mileage_sheet.dart';
import '../application/add_menu_data.dart';

/// What the user picked in the Add menu.
sealed class AddMenuChoice {
  const AddMenuChoice();
}

final class LogServiceChoice extends AddMenuChoice {
  const LogServiceChoice(this.vehicleId);

  final String vehicleId;
}

final class UpdateMileageChoice extends AddMenuChoice {
  const UpdateMileageChoice(this.vehicleId);

  final String vehicleId;
}

final class AddVehicleMenuChoice extends AddMenuChoice {
  const AddVehicleMenuChoice();
}

/// Opens S-23 and carries out the choice once it has closed: S-22 for the
/// chosen vehicle, S-12 for it, or the add-vehicle flow (S-04). Phones: a
/// bottom sheet. Tablets: a 360 pt popover by the rail's Add button.
Future<void> openAddMenu(BuildContext context) async {
  final choice = WindowClass.of(context).isCompact
      ? await showAppSheet<AddMenuChoice>(context: context, fitContent: true, builder: (_) => const AddMenuSheet())
      : await showDialog<AddMenuChoice>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.3),
          builder: (context) => const _Popover(child: AddMenuSheet()),
        );
  if (choice == null || !context.mounted) return;
  switch (choice) {
    case LogServiceChoice(:final vehicleId):
      await context.push(Uri(path: '/log-service', queryParameters: {'vehicle': vehicleId}).toString());
    case UpdateMileageChoice(:final vehicleId):
      await showUpdateMileage(context, vehicleId: vehicleId);
    case AddVehicleMenuChoice():
      await context.push('${AppRoutes.setupBrand}?add=1');
  }
}

/// S-23 Add menu (UI/UX spec S-23, FR-ADD-01, FR-ADD-02): one place to
/// add anything, for the vehicle chosen at the top.
class AddMenuSheet extends ConsumerStatefulWidget {
  const AddMenuSheet({super.key});

  @override
  ConsumerState<AddMenuSheet> createState() => _AddMenuSheetState();
}

class _AddMenuSheetState extends ConsumerState<AddMenuSheet> {
  /// Picked in "For: … ▾"; `null` uses the dashboard's vehicle.
  String? _vehicleId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final data = ref.watch(addMenuDataProvider(language)).value;
    if (data == null) {
      return const SizedBox(height: 240, child: DelayedSkeleton());
    }
    final vehicle =
        data.vehicles.where((v) => v.id == (_vehicleId ?? data.defaultVehicleId)).firstOrNull ??
        data.vehicles.firstOrNull;
    void choose(AddMenuChoice choice) => Navigator.of(context).pop(choice);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, 0, AppSpacing.screenMargin, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.navAdd, style: context.text.titleL)),
          const SizedBox(height: AppSpacing.xs),
          // 1. Vehicle context (only with several vehicles).
          if (vehicle != null && data.vehicles.length > 1) ...[
            _VehicleRow(vehicle: vehicle, vehicles: data.vehicles, onChanged: (id) => setState(() => _vehicleId = id)),
            const SizedBox(height: AppSpacing.xs),
          ],
          // 2. Actions, most frequent first. Without vehicles only "Add vehicle".
          if (vehicle != null) ...[
            _ActionRow(
              icon: Icons.build_outlined,
              title: l10n.actionLogService,
              subline: l10n.addLogServiceSub,
              onTap: () => choose(LogServiceChoice(vehicle.id)),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ActionRow(
              icon: Icons.speed,
              title: l10n.mileageTitle,
              subline: l10n.logOdometerCurrent(scheduleDistance(l10n, vehicle.odometerKm, data.unit)),
              onTap: () => choose(UpdateMileageChoice(vehicle.id)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          _ActionRow(
            icon: Icons.directions_car_outlined,
            badgeIcon: Icons.add,
            title: l10n.switcherAddVehicle,
            subline: data.atLimit ? l10n.switcherLimitReached : l10n.addAddVehicleSub,
            onTap: data.atLimit ? null : () => choose(const AddVehicleMenuChoice()),
          ),
        ],
      ),
    );
  }
}

/// Monogram + "For: Family Camry ▾" (spec S-23 item 1).
class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.vehicle, required this.vehicles, required this.onChanged});

  final AddMenuVehicle vehicle;
  final List<AddMenuVehicle> vehicles;
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
        itemBuilder: (context) => [
          for (final v in vehicles)
            PopupMenuItem(
              value: v.id,
              child: Row(
                children: [
                  MonogramTile(letters: v.monogram, size: 28),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(child: Text(v.name)),
                ],
              ),
            ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MonogramTile(letters: vehicle.monogram, size: 32),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(l10n.logFor(vehicle.name), style: context.text.body.copyWith(color: colors.textSecondary)),
              ),
              Icon(Icons.keyboard_arrow_down, size: 20, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// An action (spec S-23 item 2): 72 pt, a 48 pt icon tile, title,
/// subline and chevron. `onTap == null` shows it disabled.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subline,
    required this.onTap,
    this.badgeIcon,
  });

  final IconData icon;

  /// A small extra icon on the tile, for example "+" on the car.
  final IconData? badgeIcon;
  final String title;
  final String subline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final enabled = onTap != null;
    final foreground = enabled ? colors.textPrimary : colors.textDisabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '$title, $subline',
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.row),
          side: BorderSide(color: colors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.sm, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadii.input),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(icon, color: foreground),
                        if (badgeIcon != null)
                          PositionedDirectional(end: 6, top: 6, child: Icon(badgeIcon, size: 14, color: foreground)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: text.titleM.copyWith(color: foreground)),
                        Text(
                          subline,
                          style: text.bodyS.copyWith(color: enabled ? colors.textSecondary : colors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: enabled ? colors.textTertiary : colors.textDisabled),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tablets: the menu as a 360 pt card next to the rail's Add button.
class _Popover extends StatelessWidget {
  const _Popover({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppNavRail.width + AppSpacing.xs,
          top: MediaQuery.paddingOf(context).top + AppSpacing.md,
        ),
        child: Material(
          color: colors.bgSheet,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
            side: BorderSide(color: colors.borderSubtle),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 360,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
