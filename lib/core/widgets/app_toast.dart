import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'navigation/floating_nav_bar.dart';

/// Toast (UI/UX spec 1.7): floats 16 pt above the bottom (or the bottom
/// navigation), radius 16, `surface.raised`, `body.s` text and an optional
/// text-button action. Disappears after 4 s, or 8 s with an action.
/// Screen readers announce it.
void showAppToast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final colors = context.colors;
  final messenger = ScaffoldMessenger.of(context);
  final navBar = FloatingNavBarInset.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message, style: context.text.bodyS.copyWith(color: colors.textPrimary)),
      backgroundColor: colors.surfaceRaised,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      margin: EdgeInsets.fromLTRB(AppSpacing.screenMargin, 0, AppSpacing.screenMargin, AppSpacing.md + navBar),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
        side: BorderSide(color: colors.borderStrong),
      ),
      duration: Duration(seconds: actionLabel == null ? 4 : 8),
      action: actionLabel == null
          ? null
          : SnackBarAction(label: actionLabel, textColor: colors.accentPrimary, onPressed: onAction ?? () {}),
    ),
  );
}

/// Generic error (spec S-34): "Something went wrong. Try again." with
/// Retry when the action can be repeated. Never shows technical codes.
void showErrorToast(BuildContext context, {VoidCallback? onRetry}) {
  final l10n = AppLocalizations.of(context);
  showAppToast(
    context,
    l10n.errorGeneric,
    actionLabel: onRetry == null ? null : l10n.actionRetryShort,
    onAction: onRetry,
  );
}
