import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../settings/presentation/widgets/settings_page.dart';
import 'widgets/contact_card.dart';

/// S-31 contact, opened from Profile's "Contact support" and from articles:
/// the contact card on its own.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) => SettingsPage(
    title: AppLocalizations.of(context).profileContact,
    embedded: embedded,
    body: ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.xs,
        AppSpacing.screenMargin,
        AppSpacing.xxl,
      ),
      children: const [ContactCard()],
    ),
  );
}
