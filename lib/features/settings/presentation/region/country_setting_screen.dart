import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/text/search_normalizer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_list_row.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/navigation/floating_nav_bar.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../onboarding/presentation/country/country_labels.dart';
import '../../../reference/domain/country.dart';
import '../../application/region_settings.dart';
import '../widgets/settings_page.dart';

/// S-25 Country (UI/UX spec S-25, FR-SET-14, FR-SET-16): a searchable
/// list like the S-03 sheet. A new country offers to switch only the
/// values the user hasn't set by hand (BR-SET-09); the Popular brands
/// always follow it.
class CountrySettingScreen extends ConsumerStatefulWidget {
  const CountrySettingScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<CountrySettingScreen> createState() => _CountrySettingScreenState();
}

class _CountrySettingScreenState extends ConsumerState<CountrySettingScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _choose(RegionData data, Country? country) async {
    if (country?.code == data.preferences.countryCode) {
      if (!widget.embedded) context.pop();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final switches = data.preferences.switchesFor(country);
    var switchValues = false;

    // Ask only when something would change (FR-SET-16).
    if (switches.currency != null || switches.unit != null) {
      final unit = switches.unit == null ? null : distanceUnitLabel(l10n, switches.unit!);
      final (title, body) = switch ((switches.currency, unit)) {
        (final String currency, final String unit) => (
          l10n.regionSwitchBothTitle,
          l10n.regionSwitchBoth(currency, unit),
        ),
        (final String currency, null) => (l10n.regionSwitchCurrencyTitle, l10n.regionSwitchCurrency(currency)),
        (null, final String unit) => (l10n.regionSwitchUnitTitle, l10n.regionSwitchUnit(unit)),
        _ => ('', ''),
      };
      final answer = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            AppButton.text(label: l10n.regionKeep, onPressed: () => Navigator.pop(context, false)),
            AppButton.text(label: l10n.regionSwitch, onPressed: () => Navigator.pop(context, true)),
          ],
        ),
      );
      if (answer == null || !mounted) return;
      switchValues = answer;
    }

    await ref.read(regionActionsProvider).setCountry(data.preferences, country, switchValues: switchValues);
    if (!mounted) return;
    showAppToast(
      context,
      country == null ? l10n.regionPopularDefault : l10n.regionPopularUpdated(country.name(language)),
    );
    if (!widget.embedded) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final data = ref.watch(regionDataProvider).value;

    Widget check(bool on) => on
        ? Icon(Icons.check, color: colors.accentPrimary, semanticLabel: l10n.stateSelected)
        : const SizedBox(width: 24);

    return SettingsPage(
      title: l10n.profileCountry,
      embedded: widget.embedded,
      body: data == null
          ? const DelayedSkeleton()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin,
                    AppSpacing.xs,
                    AppSpacing.screenMargin,
                    AppSpacing.sm,
                  ),
                  child: AppSearchField(
                    controller: _search,
                    hint: l10n.countrySearchHint,
                    clearLabel: l10n.actionClearSearch,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                Expanded(
                  child: ListView(
                    // Clear of the floating tab bar on phones.
                    padding: EdgeInsets.only(bottom: FloatingNavBarInset.of(context) + AppSpacing.xxl),
                    children: [
                      AppListRow(
                        card: false,
                        title: l10n.countryOther,
                        subtitle: l10n.countryOtherHint,
                        selected: data.country == null,
                        trailing: check(data.country == null),
                        onTap: () => _choose(data, null),
                      ),
                      Divider(
                        indent: AppSpacing.screenMargin,
                        endIndent: AppSpacing.screenMargin,
                        color: colors.borderSubtle,
                      ),
                      for (final country
                          in data.countries.where((c) => SearchNormalizer.matches(_query, c.searchTerms)).toList()
                            ..sort((a, b) => a.name(language).compareTo(b.name(language))))
                        AppListRow(
                          card: false,
                          minHeight: 56,
                          title: country.name(language),
                          selected: country.code == data.preferences.countryCode,
                          trailing: check(country.code == data.preferences.countryCode),
                          onTap: () => _choose(data, country),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
