import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/text/search_normalizer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_list_row.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/navigation/floating_nav_bar.dart';
import '../../application/region_settings.dart';
import '../currency_names.dart';
import '../widgets/settings_page.dart';

/// S-25 Currency (FR-SET-03): the country's currency suggested at the top,
/// then every currency, searchable by code or name in either language.
/// Choosing one marks it as set by hand (BR-SET-09). Existing records keep
/// their own currency (BR-EXP-02).
class CurrencyScreen extends ConsumerStatefulWidget {
  const CurrencyScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends ConsumerState<CurrencyScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _choose(RegionData data, String code) async {
    if (code != data.preferences.currency) {
      await ref.read(regionActionsProvider).setCurrency(data.preferences, code);
    }
    if (mounted && !widget.embedded) context.pop();
  }

  bool _matches(String code) =>
      SearchNormalizer.matches(_query, [code, ?currencyName(code, 'en'), ?currencyName(code, 'ar')]);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final data = ref.watch(regionDataProvider).value;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.md,
        AppSpacing.screenMargin,
        AppSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          language == 'ar' ? title : title.toUpperCase(),
          style: text.overline.copyWith(color: colors.textTertiary),
        ),
      ),
    );

    Widget row(String code) {
      final selected = data!.preferences.currency == code;
      return AppListRow(
        card: false,
        minHeight: 56,
        title: code,
        subtitle: currencyName(code, language),
        selected: selected,
        trailing: selected
            ? Icon(Icons.check, color: colors.accentPrimary, semanticLabel: l10n.stateSelected)
            : const SizedBox(width: 24),
        onTap: () => _choose(data, code),
      );
    }

    if (data == null) {
      return SettingsPage(title: l10n.profileCurrency, embedded: widget.embedded, body: const DelayedSkeleton());
    }

    // Suggested: the country's currency and the current one.
    final suggested = {?data.country?.defaultCurrency, data.preferences.currency}.where(_matches).toList();
    final all = {
      ...namedCurrencyCodes,
      for (final c in data.countries) c.defaultCurrency,
    }.where((c) => !suggested.contains(c) && _matches(c)).toList()..sort();

    return SettingsPage(
      title: l10n.profileCurrency,
      embedded: widget.embedded,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              AppSpacing.xs,
              AppSpacing.screenMargin,
              AppSpacing.xs,
            ),
            child: AppSearchField(
              controller: _search,
              hint: l10n.currencySearchHint,
              clearLabel: l10n.actionClearSearch,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin + AppSpacing.xxs),
            child: Text(l10n.currencyCaption, style: text.caption.copyWith(color: colors.textTertiary)),
          ),
          Expanded(
            child: ListView(
              // Clear of the floating tab bar on phones.
              padding: EdgeInsets.only(bottom: FloatingNavBarInset.of(context) + AppSpacing.xxl),
              children: [
                if (suggested.isEmpty && all.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      l10n.currencyNoResults(_query.trim()),
                      style: text.body.copyWith(color: colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (suggested.isNotEmpty) ...[section(l10n.currencySuggested), for (final c in suggested) row(c)],
                if (all.isNotEmpty) ...[section(l10n.currencyAll), for (final c in all) row(c)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
