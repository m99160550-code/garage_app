import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_info.dart';
import '../../../../core/format/app_formatters.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/layout/window_class.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../application/help_providers.dart';
import '../../domain/help_article.dart';

/// The contact card (spec S-31 item 3): the support promise, the email
/// address and the language note. Tapping the address opens the mail
/// composer with a subject, the app version and the kind of device, never
/// personal data. Without a mail app the address is copied instead.
class ContactCard extends ConsumerWidget {
  const ContactCard({super.key});

  Future<void> _email(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.android => 'Android',
      final other => other.name,
    };
    final device = '$platform, ${WindowClass.of(context).isCompact ? 'phone' : 'tablet'}';
    final opened = await ref
        .read(supportMailerProvider)
        .compose(
          to: SupportInfo.email,
          subject: l10n.helpEmailSubject,
          body: supportEmailBody(appVersion: '${AppInfo.name} ${AppInfo.version} (${AppInfo.build})', device: device),
        );
    if (opened || !context.mounted) return;
    await Clipboard.setData(const ClipboardData(text: SupportInfo.email));
    if (context.mounted) showAppToast(context, l10n.helpEmailCopied);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: colors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.helpContactTitle, style: text.titleM)),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.profileSupportPromise, style: text.bodyS.copyWith(color: colors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            button: true,
            label: '${SupportInfo.email}, ${l10n.helpEmailHint}',
            excludeSemantics: true,
            child: Material(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadii.row),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _email(context, ref),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(Icons.mail_outline, color: colors.accentPrimary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ltrValue(SupportInfo.email), style: text.body.copyWith(color: colors.accentPrimary)),
                              Text(l10n.helpEmailHint, style: text.caption.copyWith(color: colors.textSecondary)),
                            ],
                          ),
                        ),
                        Icon(Icons.open_in_new, size: 18, color: colors.textTertiary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.helpContactLanguage, style: text.caption.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}
