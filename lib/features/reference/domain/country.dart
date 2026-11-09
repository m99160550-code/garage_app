import 'package:flutter/foundation.dart';

import '../../settings/domain/distance_unit.dart';

/// Which ranked Popular-brands list a country uses (D32, FR-REF-11).
enum PopularListCode { standard, egypt, gulf }

/// A country from the reference catalogue (architecture 2.5 `countries`).
@immutable
class Country {
  const Country({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.defaultCurrency,
    required this.defaultDistanceUnit,
    this.popularList = PopularListCode.standard,
    this.aliases = const [],
  });

  /// ISO 3166-1 alpha-2, for example "SA".
  final String code;
  final String nameEn;
  final String nameAr;

  /// ISO 4217, for example "SAR".
  final String defaultCurrency;
  final DistanceUnit defaultDistanceUnit;
  final PopularListCode popularList;

  /// Extra search terms, for example "UAE", "KSA".
  final List<String> aliases;

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  Iterable<String> get searchTerms => [nameEn, nameAr, code, ...aliases];

  @override
  bool operator ==(Object other) => other is Country && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
