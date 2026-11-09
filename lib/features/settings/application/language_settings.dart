import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/app_formatters.dart';
import '../../vehicles/application/garage_providers.dart';
import 'locale_controller.dart';
import 'preferences_providers.dart';
import 'profile_data.dart';

/// The saved digit style (FR-SET-13), refreshed after a change.
final digitStyleProvider = FutureProvider<DigitStyle>((ref) async {
  ref.watch(profileRevisionProvider);
  return (await ref.watch(preferencesRepositoryProvider).load()).digitStyle;
});

/// S-26 choices.
class LanguageActions {
  LanguageActions(this._ref);

  final Ref _ref;

  /// `null` follows the device language (BR-SET-10). Takes effect at once,
  /// including the layout direction (BR-SET-04).
  void setLanguage(Locale? locale) => _ref.read(localeControllerProvider.notifier).setLanguage(locale);

  /// Saves the digit style and redraws every screen with numbers.
  Future<void> setDigits(DigitStyle style) async {
    final repository = _ref.read(preferencesRepositoryProvider);
    await repository.save((await repository.load()).withDigitStyle(style));
    AppFormatters.appDigits = style;
    _ref.read(profileRevisionProvider.notifier).bump();
    _ref.read(garageRevisionProvider.notifier).bump();
  }
}

final languageActionsProvider = Provider<LanguageActions>(LanguageActions.new);
