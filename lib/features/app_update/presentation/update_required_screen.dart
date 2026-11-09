import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_mark.dart';
import '../application/update_gate.dart';

/// S-34 "Update required" (API 426): full screen and blocking, over the
/// whole app. The app mark, the reason, a reassurance that local data is
/// safe, and "Update", which opens the store page.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.bgBase,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppMark()),
                    const SizedBox(height: AppSpacing.xl),
                    Semantics(
                      header: true,
                      child: Text(l10n.updateTitle, style: text.headline, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.updateBody,
                      style: text.body.copyWith(color: colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.updateSafe,
                      style: text.bodyS.copyWith(color: colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppButton(
                      label: l10n.updateAction,
                      onPressed: () => ref.read(storeLauncherProvider).openStorePage(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
