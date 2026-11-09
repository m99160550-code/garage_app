import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../application/backup_controller.dart';
import 'widgets/backup_illustration.dart';

/// Opens S-29 step 1, the backup offer (UI/UX spec S-29, FR-USR-12).
/// "Back up now" goes to S-28 with the backup title; "Not now" or a swipe
/// closes it. Profile opens it any time; after the first service it is
/// shown through [offerBackupAutomatically].
Future<void> showBackupOffer(BuildContext context) async {
  final router = GoRouter.of(context);
  final backUp = await showAppSheet<bool>(context: context, fitContent: true, builder: (_) => const BackupOfferSheet());
  if (backUp ?? false) router.push(AppRoutes.signInFromBackup);
}

/// The automatic offer: Guests only, at most 3 times, 30 days apart
/// (BR-USR-06). [actions] is read before the calling screen closes.
Future<void> offerBackupAutomatically(BuildContext context, BackupActions actions) async {
  if (!await actions.takeAutomaticOffer()) return;
  if (context.mounted) await showBackupOffer(context);
}

/// The offer's content: illustration, title, three benefits, the
/// "only on this phone" warning and the two buttons. About 460 pt.
class BackupOfferSheet extends StatelessWidget {
  const BackupOfferSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xs),
                const BackupIllustration(),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(l10n.authBackupTitle, style: text.titleL, textAlign: TextAlign.center),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final (icon, label) in [
                  (Icons.history, l10n.backupBenefitHistory),
                  (Icons.devices_outlined, l10n.backupBenefitDevices),
                  (Icons.lock_outline, l10n.backupBenefitPrivate),
                ])
                  _Benefit(icon: icon, label: label),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: colors.warning),
                    const SizedBox(width: AppSpacing.xxs),
                    Flexible(
                      child: Text(
                        l10n.backupWarning,
                        style: text.caption.copyWith(color: colors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(label: l10n.backupNow, onPressed: () => Navigator.of(context).pop(true)),
              const SizedBox(height: AppSpacing.xxs),
              AppButton.text(label: l10n.backupNotNow, onPressed: () => Navigator.of(context).pop(false)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: colors.surfaceRaised, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: colors.textPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: context.text.body)),
        ],
      ),
    );
  }
}
