import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/chrome_text.dart';
import '../../../../core/widgets/monogram_tile.dart';

/// What the overflow menu (⋯) offers (spec S-09).
enum DashboardMenuAction { templateUpdate, schedule, mileageHistory, editVehicle, deleteVehicle }

/// Dashboard header (spec S-09 item 2): the monogram, the brand name in
/// chrome with a chevron, and the subline, as one button that opens the
/// vehicle switcher; the overflow menu at the end.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.monogram,
    required this.brandName,
    required this.subline,
    required this.onSwitchVehicle,
    required this.onMenu,
    this.templateUpdate = false,
    this.syncIndicator,
  });

  static const height = 56.0;

  final String monogram;
  final String brandName;

  /// Nickname, or "Camry · 2022".
  final String subline;
  final VoidCallback onSwitchVehicle;
  final ValueChanged<DashboardMenuAction> onMenu;

  /// Newer typical intervals are available (FR-REF-06): the overflow
  /// button gets an info dot and the menu leads with "Review updated
  /// intervals" (spec S-09 "Template update available").
  final bool templateUpdate;

  /// The sync indicator (spec S-34), before the overflow menu.
  final Widget? syncIndicator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: height),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: l10n.dashboardSwitchVehicle('$brandName, $subline'),
              excludeSemantics: true,
              child: InkWell(
                onTap: onSwitchVehicle,
                borderRadius: BorderRadius.circular(AppRadii.row),
                child: Row(
                  children: [
                    MonogramTile(letters: monogram, size: 44),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(child: ChromeText(brandName, style: text.headline, maxLines: 1)),
                              const SizedBox(width: AppSpacing.xxs),
                              Icon(Icons.keyboard_arrow_down, size: 20, color: colors.textSecondary),
                            ],
                          ),
                          Text(
                            subline,
                            style: text.bodyS.copyWith(color: colors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ?syncIndicator,
          PopupMenuButton<DashboardMenuAction>(
            tooltip: templateUpdate ? '${l10n.actionMoreOptions}, ${l10n.templateUpdateBadge}' : l10n.actionMoreOptions,
            icon: Badge(
              isLabelVisible: templateUpdate,
              smallSize: 10,
              // Above the dots rather than over the last one.
              offset: const Offset(2, -8),
              backgroundColor: colors.info,
              child: Icon(Icons.more_horiz, color: colors.textPrimary),
            ),
            color: colors.surfaceRaised,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.row)),
            onSelected: onMenu,
            itemBuilder: (context) => [
              if (templateUpdate) ...[
                PopupMenuItem(
                  value: DashboardMenuAction.templateUpdate,
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: colors.info),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(child: Text(l10n.templateUpdateMenu)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
              ],
              PopupMenuItem(value: DashboardMenuAction.schedule, child: Text(l10n.menuSchedule)),
              PopupMenuItem(value: DashboardMenuAction.mileageHistory, child: Text(l10n.menuMileageHistory)),
              PopupMenuItem(value: DashboardMenuAction.editVehicle, child: Text(l10n.menuEditVehicle)),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: DashboardMenuAction.deleteVehicle,
                child: Text(l10n.menuDeleteVehicle, style: TextStyle(color: colors.destructiveText)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
