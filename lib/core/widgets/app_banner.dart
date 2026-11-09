import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_button.dart';

enum BannerTone { info, success, warning, danger }

/// Banner (UI/UX spec 1.7): full width inside the margins, radius 18,
/// status container colour, icon and text, optional action. Meaning never
/// relies on colour alone: there is always an icon and words.
class AppBanner extends StatelessWidget {
  const AppBanner({super.key, required this.message, this.tone = BannerTone.info, this.action, this.title});

  final String message;

  /// A bold first line, for example "You're offline".
  final String? title;
  final BannerTone tone;

  /// Optional button at the end, for example "Review".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground, icon) = switch (tone) {
      BannerTone.info => (colors.infoContainer, colors.onInfoContainer, Icons.info_outline),
      BannerTone.success => (colors.successContainer, colors.onSuccessContainer, Icons.check_circle_outline),
      BannerTone.warning => (colors.warningContainer, colors.onWarningContainer, Icons.warning_amber_rounded),
      BannerTone.danger => (colors.dangerContainer, colors.onDangerContainer, Icons.error_outline),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.row)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            // With a button, centre it against the text so they line up.
            crossAxisAlignment: action == null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: title == null
                    ? Text(message, style: context.text.bodyS.copyWith(color: foreground))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title!, style: context.text.label.copyWith(color: foreground)),
                          Text(message, style: context.text.bodyS.copyWith(color: foreground)),
                        ],
                      ),
              ),
              if (action != null) ...[
                const SizedBox(width: AppSpacing.xs),
                // On coloured banners the action uses the banner's own text
                // colour, which is chosen to contrast with it.
                tone == BannerTone.info ? action! : ButtonForeground(color: foreground, child: action!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Offline banner (spec S-34): "You're offline" and why the action needs a
/// connection. Only for network actions (sign-in, backup, account
/// deletion); local actions never show it.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) => AppBanner(title: AppLocalizations.of(context).offlineTitle, message: reason);
}
