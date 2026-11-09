import '../../../core/text/search_normalizer.dart';
import '../../reference/domain/brand.dart';

/// The six category tabs, in order (D26).
enum BrandTab { popular, european, japanese, korean, chinese, american }

extension on BrandTab {
  RegionTab? get region => switch (this) {
    BrandTab.popular => null,
    BrandTab.european => RegionTab.european,
    BrandTab.japanese => RegionTab.japanese,
    BrandTab.korean => RegionTab.korean,
    BrandTab.chinese => RegionTab.chinese,
    BrandTab.american => RegionTab.american,
  };
}

/// The brands shown for a tab and search (FR-VEH-02, BR-REF-01, BR-REF-07):
///
/// * Popular: the country's ranked list, in rank order, only brands whose
///   models are loaded.
/// * Regional tabs: every brand in that region, alphabetical in the UI
///   language.
/// * Tab and search combine with AND.
List<Brand> brandsForTab({
  required List<Brand> brands,
  required List<String> popularRanking,
  required BrandTab tab,
  required String query,
  required String languageCode,
}) {
  final List<Brand> base;
  if (tab == BrandTab.popular) {
    final byId = {for (final b in brands) b.id: b};
    base = [
      for (final id in popularRanking)
        if (byId[id] case final brand? when brand.modelsLoaded) brand,
    ];
  } else {
    base = brands.where((b) => b.regionTab == tab.region).toList()
      ..sort((a, b) => a.name(languageCode).compareTo(b.name(languageCode)));
  }
  return base.where((b) => SearchNormalizer.matches(query, b.searchTerms)).toList();
}

/// For the "No brands found" state: how many brands match the search in
/// each *other* tab, so the user can jump there (spec S-04 States).
Map<BrandTab, int> matchesInOtherTabs({
  required List<Brand> brands,
  required List<String> popularRanking,
  required BrandTab currentTab,
  required String query,
  required String languageCode,
}) {
  final result = <BrandTab, int>{};
  for (final tab in BrandTab.values) {
    if (tab == currentTab) continue;
    final count = brandsForTab(
      brands: brands,
      popularRanking: popularRanking,
      tab: tab,
      query: query,
      languageCode: languageCode,
    ).length;
    if (count > 0) result[tab] = count;
  }
  return result;
}

/// Whether a search matched only the name in the other language, so the
/// row can show that name as a hint (spec S-04 brand row).
bool matchedOnlyOtherLanguage(Brand brand, String query, String languageCode) {
  if (SearchNormalizer.normalize(query).isEmpty) return false;
  final matchesShown = SearchNormalizer.matches(query, [brand.name(languageCode)]);
  final matchesOther = SearchNormalizer.matches(query, [brand.otherName(languageCode)]);
  return !matchesShown && matchesOther;
}
