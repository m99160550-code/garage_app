import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/vehicle/car_illustration.dart';
import '../../application/vehicle_switcher_data.dart';

/// The badge text and tone for a vehicle's worst state.
(String, BadgeTone, IconData) vehicleStatusBadge(AppLocalizations l10n, VehicleStatus status) => switch (status) {
  VehicleOverdue(:final count) => (l10n.switcherOverdue(count), BadgeTone.danger, Icons.error_outline),
  VehicleDueSoon() => (l10n.statusDueSoon, BadgeTone.warning, Icons.schedule),
  VehicleAllGood() => (l10n.alertAllGood, BadgeTone.success, Icons.check),
  VehicleNotSetUp() => (l10n.switcherNotSetUp, BadgeTone.neutral, Icons.help_outline),
};

/// One vehicle in the switcher (spec S-10 item 2): an 80 pt row with a
/// 96 × 56 thumbnail in the car's paint, the name and subline, its status
/// badge, and a check on the current vehicle (raised, with a strong border).
class VehicleSwitcherRow extends StatelessWidget {
  const VehicleSwitcherRow({super.key, required this.vehicle, required this.current, required this.onTap});

  final VehicleSummary vehicle;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final (badge, tone, icon) = vehicleStatusBadge(l10n, vehicle.status);

    return Semantics(
      button: true,
      selected: current,
      label: [
        l10n.switcherRowSemantic(vehicle.name, vehicle.subline, badge),
        if (current) l10n.switcherCurrent,
      ].join(', '),
      excludeSemantics: true,
      child: Material(
        color: current ? colors.surfaceRaised : colors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.row),
          side: BorderSide(color: current ? colors.borderStrong : colors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.sm, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    height: 56,
                    child: Center(
                      child: CarIllustration(
                        bodyType: vehicle.bodyType,
                        paint: vehicle.paint.color,
                        showReflection: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(vehicle.name, style: text.titleM, maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (vehicle.subline.isNotEmpty)
                          Text(vehicle.subline, style: text.bodyS.copyWith(color: colors.textSecondary)),
                        const SizedBox(height: AppSpacing.xxs),
                        StatusBadge(label: badge, tone: tone, icon: icon),
                      ],
                    ),
                  ),
                  if (current) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.check_circle, color: colors.accentPrimary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
