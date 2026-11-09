import '../domain/help_article.dart';
import 'help_content.dart';

/// The FAQ (the help centre on the website later, NFR-SUP-07). Screens
/// only depend on this interface.
abstract interface class HelpRepository {
  /// The full help centre, or the short saved copy without a connection
  /// (BR-SET-03).
  Future<HelpContent> load();
}

/// Development stand-in: [online] `false` returns only the bundled copy.
class MockHelpRepository implements HelpRepository {
  MockHelpRepository({this.online = true, this.articles = helpArticles});

  bool online;
  final List<HelpArticle> articles;

  @override
  Future<HelpContent> load() async => HelpContent(
    articles: online
        ? articles
        : [
            for (final a in articles)
              if (a.bundled) a,
          ],
    online: online,
  );
}
