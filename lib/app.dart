import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/format/app_formatters.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/language_fade.dart';
import 'features/app_update/application/update_gate.dart';
import 'features/app_update/presentation/update_required_screen.dart';
import 'features/notifications/application/reminder_scheduler.dart';
import 'features/settings/application/language_settings.dart';
import 'features/settings/application/locale_controller.dart';

/// Root widget: theme, localisation (Arabic and English) and routing.
class GarageApp extends ConsumerWidget {
  const GarageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);
    // Keeps this phone's reminders in step with the garage (spec S-35).
    ref.watch(reminderSyncProvider);
    // Formatters follow the saved digit style (FR-SET-13).
    AppFormatters.appDigits = ref.watch(digitStyleProvider).value ?? DigitStyle.western;

    return MaterialApp.router(
      title: 'TDC-mena Garage',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark(arabic: false),
      theme: AppTheme.dark(arabic: false),
      // Swap in the Arabic type scale once the resolved locale is known.
      // and fade briefly when the language changes (spec S-26).
      builder: (context, child) {
        final language = Localizations.localeOf(context).languageCode;
        // An unsupported version blocks everything (spec S-34, API 426).
        final blocked = ref.watch(updateRequiredProvider).value ?? false;
        final screen = blocked ? const UpdateRequiredScreen() : child!;
        final content = language == 'ar' ? Theme(data: AppTheme.dark(arabic: true), child: screen) : screen;
        return LanguageFade(language: language, child: content);
      },
    );
  }
}
