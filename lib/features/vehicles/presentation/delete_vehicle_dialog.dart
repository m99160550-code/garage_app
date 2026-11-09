import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/app_button.dart';

/// "Delete Family Camry?" (spec S-32, FR-VEH-12): what goes with it, then
/// [Cancel] [Delete]. `true` when confirmed.
Future<bool> confirmDeleteVehicle(BuildContext context, {required String name, required int recordCount}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deleteVehicleTitle(name)),
      content: Text(l10n.deleteVehicleBodyCount(recordCount)),
      actions: [
        AppButton.text(label: l10n.actionCancel, onPressed: () => Navigator.pop(context, false)),
        AppButton.destructiveText(label: l10n.actionDelete, onPressed: () => Navigator.pop(context, true)),
      ],
    ),
  );
  return confirmed ?? false;
}
