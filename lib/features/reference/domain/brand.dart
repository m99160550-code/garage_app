import 'package:flutter/foundation.dart';

/// The regional tab a brand belongs to (FR-VEH-02, BR-REF-01).
enum RegionTab { european, japanese, korean, chinese, american }

/// A car brand from the in-house dataset (FR-REF-01, FR-REF-10).
@immutable
class Brand {
  const Brand({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.monogram,
    required this.originCountry,
    required this.regionTab,
    this.aliases = const [],
    this.modelsLoaded = false,
  });

  /// Stable slug, for example "toyota".
  final String id;
  final String nameEn;
  final String nameAr;

  /// 1–2 letters shown in the monogram tile, never a logo (FR-REF-02).
  final String monogram;
  final String originCountry;
  final RegionTab regionTab;

  /// Extra search terms, for example "VW", "مرسيدس".
  final List<String> aliases;

  /// Whether the brand's models are in the dataset yet (FR-REF-12 phases).
  /// Brands without models never appear in Popular (BR-REF-07).
  final bool modelsLoaded;

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  /// The name in the other language, shown when a search matched it.
  String otherName(String languageCode) => languageCode == 'ar' ? nameEn : nameAr;

  Iterable<String> get searchTerms => [nameEn, nameAr, ...aliases];

  @override
  bool operator ==(Object other) => other is Brand && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
