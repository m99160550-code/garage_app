import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/category_tabs.dart';
import '../../../../reference/domain/brand.dart';
import '../../../application/brand_filter.dart';
import '../../../application/brand_selection_controller.dart';
import 'brand_empty_state.dart';
import 'brand_row.dart';
import 'brand_search_bar.dart';
import 'other_brand_row.dart';

/// Callbacks from the brand panel to the screen's controller.
class BrandPanelActions {
  const BrandPanelActions({
    required this.onQuery,
    required this.onTab,
    required this.onToggleBrand,
    required this.onToggleOther,
    required this.onAddAsOther,
    required this.onOtherName,
    required this.onContinue,
    this.onSearchExpanded,
  });

  final ValueChanged<String> onQuery;
  final ValueChanged<BrandTab> onTab;
  final ValueChanged<Brand> onToggleBrand;
  final VoidCallback onToggleOther;
  final ValueChanged<String> onAddAsOther;
  final ValueChanged<String> onOtherName;
  final VoidCallback onContinue;
  final VoidCallback? onSearchExpanded;
}

/// Search, brand list, Continue and category tabs (spec S-04 items 5a–5d).
///
/// Phones: tabs pinned at the bottom (as in the reference), one column, and
/// the list scrolls with the draggable sheet's [scrollController].
/// Tablets in landscape: search always open, tabs under the search so they
/// stay visible, and a two-column grid.
class BrandPanel extends StatelessWidget {
  const BrandPanel({
    super.key,
    required this.state,
    required this.actions,
    required this.saving,
    this.scrollController,
    this.dragHandle,
    this.tabsOnTop = false,
    this.columns = 1,
  });

  final BrandSelectionState state;
  final BrandPanelActions actions;
  final bool saving;
  final ScrollController? scrollController;
  final Widget? dragHandle;
  final bool tabsOnTop;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;

    String tabLabel(BrandTab tab) => switch (tab) {
      BrandTab.popular => l10n.tabPopular,
      BrandTab.european => l10n.tabEuropean,
      BrandTab.japanese => l10n.tabJapanese,
      BrandTab.korean => l10n.tabKorean,
      BrandTab.chinese => l10n.tabChinese,
      BrandTab.american => l10n.tabAmerican,
    };

    final visible = brandsForTab(
      brands: state.brands,
      popularRanking: state.popularRanking,
      tab: state.tab,
      query: state.query,
      languageCode: language,
    );

    final tabs = CategoryTabs(
      labels: [for (final tab in BrandTab.values) tabLabel(tab)],
      selectedIndex: state.tab.index,
      onSelected: (i) => actions.onTab(BrandTab.values[i]),
      semanticLabelBuilder: (i) => l10n.tabSemantic(tabLabel(BrandTab.values[i]), i + 1, BrandTab.values.length),
    );

    final rows = <Widget>[
      for (final brand in visible)
        BrandRow(
          brand: brand,
          query: state.query,
          selected: state.selectedBrand == brand,
          onTap: () => actions.onToggleBrand(brand),
        ),
    ];

    final items = <Widget>[
      if (visible.isEmpty && state.query.trim().isNotEmpty)
        BrandEmptyState(
          query: state.query,
          otherTabMatches: matchesInOtherTabs(
            brands: state.brands,
            popularRanking: state.popularRanking,
            currentTab: state.tab,
            query: state.query,
            languageCode: language,
          ),
          tabLabel: tabLabel,
          onClearSearch: () => actions.onQuery(''),
          onJumpToTab: actions.onTab,
          onAddAsOther: () => actions.onAddAsOther(state.query.trim()),
        ),
      ..._inColumns(rows, columns),
      OtherBrandRow(
        selected: state.otherSelected,
        name: state.otherName,
        onTap: actions.onToggleOther,
        onNameChanged: actions.onOtherName,
      ),
    ];

    final list = AnimatedSwitcher(
      duration: AppMotion.quick,
      child: ListView.separated(
        key: ValueKey(state.tab),
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin, vertical: AppSpacing.sm),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, i) => items[i],
      ),
    );

    final continueLabel = state.selectedBrand != null
        ? l10n.brandContinueWith(state.selectedBrand!.name(language))
        : l10n.brandContinueWith(state.otherName.trim());

    return Column(
      children: [
        ?dragHandle,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.xs,
            AppSpacing.screenMargin,
            AppSpacing.xs,
          ),
          child: BrandSearchBar(
            query: state.query,
            onChanged: actions.onQuery,
            onExpanded: actions.onSearchExpanded,
            alwaysExpanded: tabsOnTop,
          ),
        ),
        if (tabsOnTop) tabs,
        Expanded(child: _EdgeFade(child: list)),
        // Continue slides up once something is chosen (spec S-04 item 5c).
        AnimatedSize(
          duration: AppMotion.standard,
          curve: AppMotion.standardCurve,
          child: state.canContinue
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin,
                    AppSpacing.xs,
                    AppSpacing.screenMargin,
                    AppSpacing.sm,
                  ),
                  child: AppButton(label: continueLabel, isLoading: saving, onPressed: actions.onContinue),
                )
              : const SizedBox(width: double.infinity),
        ),
        if (!tabsOnTop) tabs,
      ],
    );
  }

  static List<Widget> _inColumns(List<Widget> rows, int columns) {
    if (columns <= 1) return rows;
    return [
      for (var i = 0; i < rows.length; i += columns)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(child: i + c < rows.length ? rows[i + c] : const SizedBox()),
              ],
            ],
          ),
        ),
    ];
  }
}

/// Fades the top and bottom 32 pt of the list, giving the depth seen in the
/// reference design.
class _EdgeFade extends StatelessWidget {
  const _EdgeFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final fade = bounds.height == 0 ? 0.0 : (32 / bounds.height).clamp(0.0, 0.4);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
          stops: [0, fade, 1 - fade, 1],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

/// The panel's sheet background: frosted `bg.sheet`, radius 32 (spec 1.4).
class BrandPanelSurface extends StatelessWidget {
  const BrandPanelSurface({super.key, required this.child, required this.borderRadius});

  final Widget child;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: ColoredBox(color: colors.bgSheet.withValues(alpha: 0.88), child: child),
      ),
    );
  }
}
