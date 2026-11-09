import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/navigation/floating_nav_bar.dart';
import '../../garage/application/current_vehicle_controller.dart';
import '../../garage/application/vehicle_switcher_data.dart';
import '../../garage/presentation/vehicle_switcher_sheet.dart';
import '../../garage/presentation/widgets/vehicle_switcher_row.dart';
import '../../settings/presentation/widgets/settings_page.dart';
import '../domain/garage_limits.dart';

/// S-32 Manage vehicles (UI/UX spec S-32): the S-10 rows on their own
/// screen, plus "Add vehicle". A row opens Edit vehicle. Opened from
/// Profile → Vehicles and from S-10 "Manage vehicles".
class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key, this.embedded = false});

  /// In the iPad Profile detail pane: no back button.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final vehicles = ref.watch(vehicleSummariesProvider(language)).value;
    final currentId = ref.watch(currentVehicleProvider).value;

    return SettingsPage(
      title: l10n.profileVehicles,
      embedded: embedded,
      body: vehicles == null
          ? const DelayedSkeleton()
          : ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.xs,
                AppSpacing.screenMargin,
                FloatingNavBarInset.of(context) + AppSpacing.xxl,
              ),
              children: [
                if (vehicles.length > showGarageCountAbove) ...[
                  Text(
                    l10n.switcherCount(vehicles.length, maxGarageVehicles),
                    style: context.text.bodyS.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                for (final vehicle in vehicles) ...[
                  VehicleSwitcherRow(
                    vehicle: vehicle,
                    current: vehicle.id == currentId,
                    onTap: () => context.push(AppRoutes.editVehicle(vehicle.id)),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                AddVehicleRow(
                  enabled: vehicles.length < maxGarageVehicles,
                  onTap: () => context.push('${AppRoutes.setupBrand}?add=1'),
                ),
              ],
            ),
    );
  }
}
