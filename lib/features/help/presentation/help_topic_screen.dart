import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_banner.dart';
import '../../settings/presentation/widgets/settings_list.dart';
import '../../settings/presentation/widgets/settings_page.dart';
import '../application/help_providers.dart';
import '../domain/help_article.dart';
import 'widgets/help_category_visuals.dart';

/// S-31: one FAQ topic's questions. Each opens its article.
class HelpTopicScreen extends ConsumerWidget {
  const HelpTopicScreen({super.key, required this.category});

  final HelpCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final content = ref.watch(helpContentProvider).value;
    final articles = content?.inCategory(category) ?? const <HelpArticle>[];
    return SettingsPage(
      title: helpCategoryLabel(l10n, category),
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
                SettingsGroup(
                  title: l10n.helpQuestionCount(articles.length),
                  children: [
                    for (final article in articles)
                      SettingsRow(
                        title: article.question(language),
                        onTap: () => context.push(AppRoutes.helpArticle(article.id)),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
