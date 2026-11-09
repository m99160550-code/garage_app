import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/features/onboarding/application/brand_filter.dart';
import 'package:tdc_garage/features/reference/data/mock_reference_repository.dart';
import 'package:tdc_garage/features/reference/domain/brand.dart';
import 'package:tdc_garage/features/reference/domain/country.dart';

void main() {
  late List<Brand> brands;
  late Map<PopularListCode, List<String>> lists;

  setUpAll(() async {
    const repository = MockReferenceRepository();
    brands = await repository.brands();
    lists = await repository.popularLists();
  });

  List<String> ids(List<Brand> list) => [for (final b in list) b.id];

  List<Brand> run({
    BrandTab tab = BrandTab.popular,
    String query = '',
    String language = 'en',
    PopularListCode list = PopularListCode.gulf,
  }) => brandsForTab(brands: brands, popularRanking: lists[list]!, tab: tab, query: query, languageCode: language);

  test('the dataset has the 35 brands across the five regional tabs (D26)', () {
    expect(brands, hasLength(35));
    final perTab = <RegionTab, int>{};
    for (final b in brands) {
      perTab[b.regionTab] = (perTab[b.regionTab] ?? 0) + 1;
    }
    expect(perTab, {
      RegionTab.european: 10,
      RegionTab.japanese: 7,
      RegionTab.korean: 3,
      RegionTab.chinese: 8,
      RegionTab.american: 7,
    });
  });

  test('every brand on a Popular list has its models loaded (BR-REF-07)', () {
    final byId = {for (final b in brands) b.id: b};
    for (final list in lists.values) {
      for (final id in list) {
        expect(byId[id]?.modelsLoaded, isTrue, reason: id);
      }
    }
  });

  test('Popular keeps the country ranking order', () {
    expect(ids(run(list: PopularListCode.gulf)).take(4), ['toyota', 'hyundai', 'kia', 'nissan']);
    expect(ids(run(list: PopularListCode.egypt)).take(4), ['nissan', 'mg', 'chery', 'jetour']);
    expect(ids(run(list: PopularListCode.standard)), hasLength(12));
  });

  test('Popular hides brands whose models are not loaded yet', () {
    final notLoaded = brands.firstWhere((b) => !b.modelsLoaded);
    final result = brandsForTab(
      brands: brands,
      popularRanking: [notLoaded.id, 'toyota'],
      tab: BrandTab.popular,
      query: '',
      languageCode: 'en',
    );
    expect(ids(result), ['toyota']);
  });

  test('regional tabs are alphabetical in the UI language', () {
    expect(ids(run(tab: BrandTab.korean)), ['genesis', 'hyundai', 'kia']);
    final arabic = run(tab: BrandTab.korean, language: 'ar').map((b) => b.nameAr).toList();
    expect(arabic, [...arabic]..sort());
  });

  test('search and tab combine with AND', () {
    expect(ids(run(tab: BrandTab.japanese, query: 'to')), ['toyota']);
    expect(run(tab: BrandTab.japanese, query: 'byd'), isEmpty);
  });

  test('search matches Arabic names and aliases from either UI language', () {
    expect(ids(run(tab: BrandTab.japanese, query: 'تويوتا')), ['toyota']);
    expect(ids(run(tab: BrandTab.european, query: 'vw')), ['volkswagen']);
    expect(ids(run(tab: BrandTab.european, query: 'مرس')), ['mercedes-benz']);
  });

  test('the empty state lists the other tabs that do match', () {
    final counts = matchesInOtherTabs(
      brands: brands,
      popularRanking: lists[PopularListCode.gulf]!,
      currentTab: BrandTab.popular,
      query: 'byd',
      languageCode: 'en',
    );
    expect(counts, {BrandTab.chinese: 1});
  });

  test('the other-language name is shown only when only it matched', () {
    final toyota = brands.firstWhere((b) => b.id == 'toyota');
    expect(matchedOnlyOtherLanguage(toyota, 'تويوتا', 'en'), isTrue);
    expect(matchedOnlyOtherLanguage(toyota, 'toy', 'en'), isFalse);
    expect(matchedOnlyOtherLanguage(toyota, '', 'en'), isFalse);
  });
}
