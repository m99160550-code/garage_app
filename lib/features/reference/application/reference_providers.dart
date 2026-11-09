import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/preferences_providers.dart';
import '../data/mock_reference_repository.dart';
import '../data/reference_repository.dart';
import '../domain/brand.dart';
import '../domain/country.dart';

/// Swap this for the bundled-asset / API repository later.
final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) => const MockReferenceRepository());

final countriesProvider = FutureProvider<List<Country>>((ref) => ref.watch(referenceRepositoryProvider).countries());

final brandsProvider = FutureProvider<List<Brand>>((ref) => ref.watch(referenceRepositoryProvider).brands());

final popularListsProvider = FutureProvider<Map<PopularListCode, List<String>>>(
  (ref) => ref.watch(referenceRepositoryProvider).popularLists(),
);

/// The ranked Popular list for the user's country, or the default list
/// (FR-REF-11, A-17).
final activePopularRankingProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final preferences = await ref.watch(preferencesRepositoryProvider).load();
  final countries = await ref.watch(countriesProvider.future);
  final lists = await ref.watch(popularListsProvider.future);
  final country = countries.where((c) => c.code == preferences.countryCode).firstOrNull;
  final code = country?.popularList ?? PopularListCode.standard;
  return lists[code] ?? lists[PopularListCode.standard] ?? const [];
});
