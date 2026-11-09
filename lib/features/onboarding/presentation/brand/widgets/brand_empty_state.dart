import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../application/brand_filter.dart';

/// "No brands found" (spec S-04 States): Clear search, links to the other
/// tabs that do match ("Chinese (1)"), and "Add … as other brand".
class BrandEmptyState extends StatelessWidget {
  const BrandEmptyState({
    super.key,
    required this.query,
    required this.otherTabMatches,
    required this.tabLabel,
    required this.onClearSearch,
    required this.onJumpToTab,
    required this.onAddAsOther,
  });

  final String query;
  final Map<BrandTab, int> otherTabMatches;
  final String Function(BrandTab tab) tabLabel;
  final VoidCallback onClearSearch;
  final ValueChanged<BrandTab> onJumpToTab;
  final VoidCallback onAddAsOther;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(Icons.manage_search, size: 48, color: colors.textTertiary),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(l10n.brandNoResults, style: text.titleM, textAlign: TextAlign.center),
          ),
          const SizedBox(height: AppSpacing.xxs),
          AppButton.text(label: l10n.actionClearSearch, onPressed: onClearSearch),
          if (otherTabMatches.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.brandFoundInTabs, style: text.bodyS.copyWith(color: colors.textSecondary)),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final entry in otherTabMatches.entries)
                  AppButton.text(
                    label: '${tabLabel(entry.key)} (${entry.value})',
                    onPressed: () => onJumpToTab(entry.key),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(label: l10n.brandAddAsOther(query.trim()), onPressed: onAddAsOther, expand: false),
        ],
      ),
    );
  }
}
