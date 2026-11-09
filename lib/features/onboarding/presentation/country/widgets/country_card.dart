import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_list_row.dart';

/// The selected country with the presets it gives, and a "Change" button
/// (spec S-03, item 3). No flags, by design. The whole row opens the
/// picker too, so the target is large.
class CountryCard extends StatelessWidget {
  const CountryCard({super.key, required this.countryName, required this.presetsLine, required this.onChange});

  /// The country name, or "Not set".
  final String countryName;
  final String presetsLine;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppListRow(
      title: countryName,
      subtitle: presetsLine,
      minHeight: 72,
      leading: Icon(Icons.public, color: context.colors.textSecondary),
      onTap: onChange,
      semanticLabel: '${l10n.countryCardLabel}, $countryName, $presetsLine. ${l10n.countryChange}',
      trailing: ExcludeSemantics(
        child: AppButton.text(label: l10n.countryChange, onPressed: onChange),
      ),
    );
  }
}
