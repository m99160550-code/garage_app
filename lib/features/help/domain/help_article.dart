import 'package:flutter/foundation.dart';

import '../../../core/text/search_normalizer.dart';

/// The FAQ categories, in the order S-31 lists them.
enum HelpCategory { gettingStarted, healthScore, reminders, backupSync, privacy }

/// One FAQ entry, in both languages (NFR-LOC-01).
@immutable
class HelpArticle {
  const HelpArticle({
    required this.id,
    required this.category,
    required this.questionEn,
    required this.questionAr,
    required this.answerEn,
    required this.answerAr,
    this.bundled = false,
  });

  final String id;
  final HelpCategory category;
  final String questionEn;
  final String questionAr;

  /// Paragraphs separated by a blank line.
  final String answerEn;
  final String answerAr;

  /// Part of the short copy shipped with the app, shown offline
  /// (BR-SET-03).
  final bool bundled;

  String question(String languageCode) => languageCode == 'ar' ? questionAr : questionEn;
  String answer(String languageCode) => languageCode == 'ar' ? answerAr : answerEn;
}

/// What the help screens show: the full help centre online, or the saved
/// copy offline.
@immutable
class HelpContent {
  const HelpContent({required this.articles, required this.online});

  final List<HelpArticle> articles;
  final bool online;

  List<HelpArticle> inCategory(HelpCategory category) => [
    for (final a in articles)
      if (a.category == category) a,
  ];

  HelpArticle? byId(String id) => articles.where((a) => a.id == id).firstOrNull;
}

/// Articles where every word of [query] starts a word in the question or
/// the answer, in the UI language. Questions that match come first. Uses
/// the shared matching rules (BR-VEH-10: case, Arabic letter variants,
/// diacritics).
List<HelpArticle> searchHelp(List<HelpArticle> articles, String query, String languageCode) {
  final words = SearchNormalizer.normalize(query).split(' ').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const [];
  bool hasAll(String text) => words.every((w) => SearchNormalizer.matches(w, [text]));
  final inQuestion = <HelpArticle>[];
  final inAnswer = <HelpArticle>[];
  for (final article in articles) {
    if (hasAll(article.question(languageCode))) {
      inQuestion.add(article);
    } else if (hasAll('${article.question(languageCode)} ${article.answer(languageCode)}')) {
      inAnswer.add(article);
    }
  }
  return [...inQuestion, ...inAnswer];
}

/// The support email's prefilled body (spec S-31 item 3): space to write,
/// then the app version and the kind of device. Never personal data.
String supportEmailBody({required String appVersion, required String device}) =>
    '\n\n\n—\nApp: $appVersion\nDevice: $device';
