import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/mock_config.dart';

/// The app language chosen in the app (FR-SET-12).
///
/// `null` means "follow the device language" (BR-SET-10). Changing it
/// switches the app straight away, including layout direction (BR-SET-04).
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    const forced = MockConfig.localeOverride;
    return forced.isEmpty ? null : Locale(forced);
  }

  void setLanguage(Locale? locale) => state = locale;
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(LocaleController.new);
