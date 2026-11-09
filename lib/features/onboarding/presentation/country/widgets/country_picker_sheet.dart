import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/text/search_normalizer.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_list_row.dart';
import '../../../../../core/widgets/app_search_field.dart';
import '../../../../../core/widgets/app_sheet.dart';
import '../../../../reference/domain/country.dart';

/// What the picker returns. `country == null` means "Other / not set".
/// A dismissed sheet returns no choice at all.
class CountryChoice {
  const CountryChoice(this.country);

  final Country? country;
}

/// Opens the country picker (spec S-03): a 92% sheet on phones, a centred
/// 560 × 640 modal on tablets.
Future<CountryChoice?> showCountryPicker({
  required BuildContext context,
  required List<Country> countries,
  required Country? selected,
}) {
  return showAppSheet<CountryChoice>(
    context: context,
    builder: (_) => CountryPickerSheet(countries: countries, selected: selected),
  );
}

class CountryPickerSheet extends StatefulWidget {
  const CountryPickerSheet({super.key, required this.countries, required this.selected});

  final List<Country> countries;
  final Country? selected;

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _choose(Country? country) => Navigator.of(context).pop(CountryChoice(country));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;

    final matches = widget.countries.where((c) => SearchNormalizer.matches(_query, c.searchTerms)).toList()
      ..sort((a, b) => a.name(language).compareTo(b.name(language)));

    Widget check(bool selected) => selected
        ? Icon(Icons.check, color: colors.accentPrimary, semanticLabel: l10n.stateSelected)
        : const SizedBox(width: 24);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.screenMargin, end: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Semantics(header: true, child: Text(l10n.countryPickerTitle, style: text.titleL)),
              ),
              IconButton(
                tooltip: l10n.actionClose,
                icon: Icon(Icons.close, color: colors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.xs,
            AppSpacing.screenMargin,
            AppSpacing.sm,
          ),
          child: AppSearchField(
            controller: _searchController,
            hint: l10n.countrySearchHint,
            clearLabel: l10n.actionClearSearch,
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              // Pinned first row (spec S-03): defaults USD, km, Popular.
              AppListRow(
                card: false,
                title: l10n.countryOther,
                subtitle: l10n.countryOtherHint,
                selected: widget.selected == null,
                trailing: check(widget.selected == null),
                onTap: () => _choose(null),
              ),
              Divider(indent: AppSpacing.screenMargin, endIndent: AppSpacing.screenMargin, color: colors.borderSubtle),
              if (matches.isEmpty)
                _NoResults(
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              else
                for (final country in matches)
                  AppListRow(
                    card: false,
                    minHeight: 56,
                    title: country.name(language),
                    selected: country == widget.selected,
                    trailing: check(country == widget.selected),
                    onTap: () => _choose(country),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.travel_explore, size: 48, color: colors.textTertiary),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(l10n.countryNoResults, style: context.text.titleM, textAlign: TextAlign.center),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.countryNoResultsHint,
            style: context.text.bodyS.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton.text(label: l10n.actionClearSearch, onPressed: onClear),
        ],
      ),
    );
  }
}
