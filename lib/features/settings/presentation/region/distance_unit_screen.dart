import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../application/region_settings.dart';
import '../../domain/distance_unit.dart';
import '../widgets/settings_page.dart';

/// S-25 Distance unit (FR-SET-02): two radio rows and the reassurance
/// that nothing is lost (BR-MIL-06). Choosing one marks it as set by
/// hand, so a country change won't switch it (BR-SET-09).
class DistanceUnitScreen extends ConsumerWidget {
  const DistanceUnitScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final data = ref.watch(regionDataProvider).value;

    return SettingsPage(
      title: l10n.profileDistanceUnit,
      embedded: embedded,
      body: data == null
          ? const DelayedSkeleton()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              children: [
                // A Material surface, so the rows' tap ripple shows.
                Material(
                  color: colors.surfaceCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.row),
                    side: BorderSide(color: colors.borderSubtle),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: RadioGroup<DistanceUnit>(
                    groupValue: data.preferences.distanceUnit,
                    onChanged: (unit) {
                      if (unit != null && unit != data.preferences.distanceUnit) {
                        ref.read(regionActionsProvider).setDistanceUnit(data.preferences, unit);
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<DistanceUnit>(
                          value: DistanceUnit.km,
                          title: Text(l10n.unitKmOption, style: context.text.body),
                        ),
                        Divider(height: 1, indent: AppSpacing.md, color: colors.borderSubtle),
                        RadioListTile<DistanceUnit>(
                          value: DistanceUnit.mi,
                          title: Text(l10n.unitMiOption, style: context.text.body),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(l10n.unitCaption, style: context.text.caption.copyWith(color: colors.textTertiary)),
                ),
              ],
            ),
    );
  }
}
