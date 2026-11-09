/// Search matching shared by every searchable list (countries, brands,
/// models, currencies). Implements BR-VEH-10:
///
/// * Ignores case, Arabic diacritics (tashkeel) and the tatweel stretch.
/// * Treats letter variants as equal: أ إ آ ٱ → ا, ة → ه, ى → ي.
/// * Ignores Latin accents ("turkiye" finds "Türkiye").
/// * Matches from the start of any word, in either name. An Arabic word's
///   leading "ال" is optional, so "امارات" finds "الإمارات".
abstract final class SearchNormalizer {
  static final _arabicMarks = RegExp('[ً-ْٰـ]');
  static final _alefVariants = RegExp('[أإآٱ]');
  static final _separators = RegExp(r'[-_.,·/()]');
  static final _spaces = RegExp(r'\s+');

  static const _accented = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
  static const _plain = 'aaaaaaceeeeiiiinooooouuuuyy';

  static String normalize(String input) {
    var s = input.toLowerCase().trim();
    s = s.replaceAll(_arabicMarks, '').replaceAll(_alefVariants, 'ا').replaceAll('ة', 'ه').replaceAll('ى', 'ي');
    final buffer = StringBuffer();
    for (final rune in s.runes) {
      final char = String.fromCharCode(rune);
      final index = _accented.indexOf(char);
      buffer.write(index == -1 ? char : _plain[index]);
    }
    return buffer.toString().replaceAll(_separators, ' ').replaceAll(_spaces, ' ').trim();
  }

  /// True when [query] matches any of [candidates] (names and aliases).
  /// An empty query matches everything.
  static bool matches(String query, Iterable<String> candidates) {
    final q = normalize(query);
    if (q.isEmpty) return true;
    for (final candidate in candidates) {
      final text = normalize(candidate);
      // Multi-word queries: match from the start of any word in the text.
      if (' $text'.contains(' $q')) return true;
      for (final word in text.split(' ')) {
        if (word.startsWith(q)) return true;
        if (word.startsWith('ال') && word.substring(2).startsWith(q)) return true;
      }
    }
    return false;
  }
}
