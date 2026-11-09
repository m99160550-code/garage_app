import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../application/locale_controller.dart';

/// Switches the app between Arabic and English. The label is the *other*
/// language, written in that language ("العربية" / "English"), so a user who
/// can't read the current language can still find it (UI/UX spec S-02).
class LanguageSwitchButton extends ConsumerWidget {
  const LanguageSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Semantics(
      label: l10n.languageSwitchSemantic,
      button: true,
      excludeSemantics: true,
      child: AppButton.text(
        label: l10n.languageSwitchLabel,
        icon: Icons.translate,
        onPressed: () => ref.read(localeControllerProvider.notifier).setLanguage(Locale(isArabic ? 'en' : 'ar')),
      ),
    );
  }
}
