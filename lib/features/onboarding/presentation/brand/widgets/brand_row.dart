import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/widgets/monogram_tile.dart';
import '../../../../reference/domain/brand.dart';
import '../../../application/brand_filter.dart';

/// One brand in the list (spec S-04 "Brand row"): monogram, name, and
/// "Select" or a white "Selected" badge. The selected row is raised and
/// slightly larger, as in the reference design.
class BrandRow extends StatelessWidget {
  const BrandRow({super.key, required this.brand, required this.query, required this.selected, required this.onTap});

  final Brand brand;
  final String query;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final name = brand.name(language);
    final otherName = matchedOnlyOtherLanguage(brand, query, language) ? brand.otherName(language) : null;
    final radius = BorderRadius.circular(AppRadii.row);

    return Semantics(
      button: true,
      selected: selected,
      label: otherName == null ? name : '$name, $otherName',
      excludeSemantics: true,
      child: AnimatedScale(
        scale: selected ? 1.03 : 1,
        duration: AppMotion.standard,
        curve: AppMotion.standardCurve,
        child: AnimatedContainer(
          duration: AppMotion.standard,
          decoration: BoxDecoration(
            color: selected ? colors.surfaceRaised : colors.surfaceCard,
            borderRadius: radius,
            border: Border.all(color: selected ? colors.borderStrong : colors.borderSubtle),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x73000000), blurRadius: 32, offset: Offset(0, 12))]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      MonogramTile(letters: brand.monogram),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HighlightedName(name: name, query: query),
                            if (otherName != null)
                              Text(otherName, style: text.caption.copyWith(color: colors.textTertiary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      selected
                          ? _SelectedBadge(label: l10n.stateSelected)
                          : Text(l10n.brandSelect, style: text.label.copyWith(color: colors.textTertiary)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bold `text.primary` for the part of the name that matches the search,
/// `text.secondary` for the rest (spec S-04 "Type in search").
class _HighlightedName extends StatelessWidget {
  const _HighlightedName({required this.name, required this.query});

  final String name;
  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.text.titleM;
    final q = query.trim().toLowerCase();
    final start = q.isEmpty ? -1 : name.toLowerCase().indexOf(q);
    if (start < 0) return Text(name, style: style);

    final end = start + q.length;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: name.substring(0, start),
            style: TextStyle(color: colors.textSecondary),
          ),
          TextSpan(
            text: name.substring(start, end),
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: name.substring(end),
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
      style: style,
    );
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: colors.buttonPrimaryBg, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(label, style: context.text.label.copyWith(fontSize: 12, color: colors.textOnLight)),
    );
  }
}
