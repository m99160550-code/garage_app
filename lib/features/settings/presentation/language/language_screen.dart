import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/app_formatters.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../application/language_settings.dart';
import '../../application/locale_controller.dart';
import '../widgets/settings_page.dart';

/// The language names, each in its own language (spec S-26).
String _nativeName(String languageCode) => languageCode == 'ar' ? 'العربية' : 'English';

/// The app's languages: the device's when supported, otherwise English
/// (BR-SET-10).
String deviceLanguageCode() {
  final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return AppLocalizations.supportedLocales.any((l) => l.languageCode == device) ? device : 'en';
}

/// S-26 Language & Digits (UI/UX spec S-26, FR-SET-12, FR-SET-13): the
/// language switches the app at once and mirrors the layout (BR-SET-04);
/// digits apply to dates, money and counts, never to VINs, plates or
/// mileage (BR-SET-05).
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final chosen = ref.watch(localeControllerProvider);
    final digits = ref.watch(digitStyleProvider).value ?? DigitStyle.western;
    final actions = ref.read(languageActionsProvider);

    Widget header(String title) => Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.md, bottom: AppSpacing.xs),
      child: Semantics(
        header: true,
        child: Text(
          Localizations.localeOf(context).languageCode == 'ar' ? title : title.toUpperCase(),
          style: text.overline.copyWith(color: colors.textTertiary),
        ),
      ),
    );

    Widget card(Widget child) => Material(
      color: colors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.row),
        side: BorderSide(color: colors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    Widget divider() => Divider(height: 1, indent: AppSpacing.md, color: colors.borderSubtle);

    // "Same as device" is the empty code.
    final languageValue = chosen?.languageCode ?? '';

    return SettingsPage(
      title: l10n.languageTitle,
      embedded: embedded,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        children: [
          header(l10n.profileLanguage),
          card(
            RadioGroup<String>(
              groupValue: languageValue,
              onChanged: (code) {
                if (code == null || code == languageValue) return;
                actions.setLanguage(code.isEmpty ? null : Locale(code));
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: '',
                    title: Text(l10n.languageDevice(_nativeName(deviceLanguageCode())), style: text.body),
                  ),
                  divider(),
                  // Each language is written in itself.
                  RadioListTile<String>(
                    value: 'ar',
                    title: _OwnDirection('العربية', direction: TextDirection.rtl, style: text.body),
                  ),
                  divider(),
                  RadioListTile<String>(
                    value: 'en',
                    title: _OwnDirection('English', direction: TextDirection.ltr, style: text.body),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          header(l10n.profileDigits),
          card(
            RadioGroup<DigitStyle>(
              groupValue: digits,
              onChanged: (style) {
                if (style != null && style != digits) actions.setDigits(style);
              },
              child: Column(
                children: [
                  RadioListTile<DigitStyle>(
                    value: DigitStyle.western,
                    title: Text(l10n.digitsWesternOption, style: text.body),
                  ),
                  divider(),
                  RadioListTile<DigitStyle>(
                    value: DigitStyle.arabicIndic,
                    title: Text(l10n.digitsArabicOption(_arabicIndicSample(context)), style: text.body),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(l10n.digitsCaption, style: text.caption.copyWith(color: colors.textTertiary)),
          ),
        ],
      ),
    );
  }
}

/// "٠ ١ ٢ ٣" in reading order: in a left-to-right layout each digit gets
/// an LRM after it, or the spaced run would be shown reversed ("٣ ٢ ١ ٠").
String _arabicIndicSample(BuildContext context) {
  const digits = ['٠', '١', '٢', '٣'];
  return Directionality.of(context) == TextDirection.rtl ? digits.join(' ') : digits.join('\u200E ');
}

/// A language name written in its own direction, but placed at the start
/// of the row like the other options.
class _OwnDirection extends StatelessWidget {
  const _OwnDirection(this.label, {required this.direction, required this.style});

  final String label;
  final TextDirection direction;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Text(label, style: style, textDirection: direction),
  );
}
