import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../settings/presentation/widgets/settings_list.dart';
import '../../settings/presentation/widgets/settings_page.dart';
import '../application/help_providers.dart';
import '../domain/help_article.dart';
import 'widgets/contact_card.dart';
import 'widgets/help_category_visuals.dart';

/// S-31 Help, FAQ & Legal (UI/UX spec S-31, FR-SET-05, BR-SET-03,
/// NFR-SUP-01 to NFR-SUP-07): search, the five FAQ topics, the contact
/// card and the legal pages. Works without an account and offline (the
/// saved short FAQ, with a banner).
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key, this.embedded = false});

  /// In the iPad Profile detail pane: no back button.
  final bool embedded;

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = ref.watch(helpContentProvider).value;
    return SettingsPage(
      title: l10n.helpTitle,
      embedded: widget.embedded,
      body: content == null
          ? const DelayedSkeleton()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.xs,
                AppSpacing.screenMargin,
                AppSpacing.xxxl * 3,
              ),
              children: [
                if (!content.online) ...[AppBanner(message: l10n.helpOffline), const SizedBox(height: AppSpacing.md)],
                AppSearchField(
                  hint: l10n.helpSearch,
                  clearLabel: l10n.actionClearSearch,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_query.trim().isNotEmpty)
                  _Results(content: content, query: _query)
                else ...[
                  SettingsGroup(
                    title: l10n.helpTopics,
                    children: [
                      for (final category in HelpCategory.values)
                        if (content.inCategory(category).isNotEmpty)
                          SettingsRow(
                            title: helpCategoryLabel(l10n, category),
                            icon: helpCategoryIcon(category),
                            value: l10n.helpQuestionCount(content.inCategory(category).length),
                            onTap: () => context.push(AppRoutes.helpTopic(category.name)),
                          ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const ContactCard(),
                  const SizedBox(height: AppSpacing.xl),
                  SettingsGroup(
                    title: l10n.helpLegal,
                    children: [
                      SettingsRow(
                        title: l10n.profilePrivacyPolicy,
                        icon: Icons.privacy_tip_outlined,
                        external: true,
                        onTap: () => context.push(AppRoutes.privacyPolicy),
                      ),
                      SettingsRow(
                        title: l10n.profileTerms,
                        icon: Icons.description_outlined,
                        external: true,
                        onTap: () => context.push(AppRoutes.terms),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

/// Search results: matching questions, or "No answers" with a pointer to
/// the contact card below.
class _Results extends StatelessWidget {
  const _Results({required this.content, required this.query});

  final HelpContent content;
  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final results = searchHelp(content.articles, query, language);

    if (results.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(l10n.helpNoResults(query.trim()), style: text.titleM, textAlign: TextAlign.center),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.helpNoResultsHint,
            style: text.bodyS.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          const ContactCard(),
        ],
      );
    }
    return Semantics(
      liveRegion: true,
      container: true,
      child: SettingsGroup(
        title: l10n.helpResults(results.length),
        children: [
          for (final article in results)
            SettingsRow(
              title: article.question(language),
              onTap: () => context.push(AppRoutes.helpArticle(article.id)),
            ),
        ],
      ),
    );
  }
}
