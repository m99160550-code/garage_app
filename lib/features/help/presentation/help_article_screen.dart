import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_skeleton.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_button.dart';
import '../../settings/presentation/widgets/settings_page.dart';
import '../application/help_providers.dart';
import 'widgets/help_category_visuals.dart';

/// S-31: one answer, in `body` text at most 560 pt wide, with a way to
/// contact support below it.
class HelpArticleScreen extends ConsumerWidget {
  const HelpArticleScreen({super.key, required this.articleId});

  final String articleId;

  static const maxTextWidth = 560.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final language = Localizations.localeOf(context).languageCode;
    final content = ref.watch(helpContentProvider).value;
    final article = content?.byId(articleId);

    return SettingsPage(
      title: article == null ? l10n.helpTitle : helpCategoryLabel(l10n, article.category),
      body: content == null
          ? const DelayedSkeleton()
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxTextWidth),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin,
                    AppSpacing.xs,
                    AppSpacing.screenMargin,
                    AppSpacing.xxxl * 3,
                  ),
                  children: [
                    // Not in the saved copy (offline).
                    if (article == null)
                      AppBanner(message: l10n.helpOffline)
                    else ...[
                      Semantics(header: true, child: Text(article.question(language), style: text.titleL)),
                      const SizedBox(height: AppSpacing.md),
                      for (final paragraph in article.answer(language).split('\n\n')) ...[
                        Text(paragraph, style: text.body.copyWith(height: 1.5)),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Divider(color: colors.borderSubtle),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.helpStillNeed, style: text.label.copyWith(color: colors.textSecondary)),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppButton.text(
                        label: l10n.profileContact,
                        icon: Icons.mail_outline,
                        onPressed: () => context.push(AppRoutes.profileContact),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
